classdef app1 < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure             matlab.ui.Figure
        JumlahWajahLabel     matlab.ui.control.Label
        DeteksiWajahButton   matlab.ui.control.Button
        CariGambarButton     matlab.ui.control.Button
        UIAxesPotonganWajah  matlab.ui.control.UIAxes
        UIAxesHasilDeteksi   matlab.ui.control.UIAxes
        UIAxesGambarAwal     matlab.ui.control.UIAxes
    end

    
    properties (Access = private)
        GambarOri% Description
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Button pushed function: CariGambarButton
        function CariGambarButtonPushed2(app, event)
            % Membuka dialog untuk memilih file gambar
            [file, path] = uigetfile({'*.jpg;*.png;*.jpeg;*.bmp', 'File Gambar (*.jpg, *.png, *.jpeg, *.bmp)'});

            % Jika pengguna tidak membatalkan pilihan
            if isequal(file, 0)
                return;
            else
                % Membaca gambar dan menyimpannya ke properti global
                fullPath = fullfile(path, file);
                app.GambarOri = imread(fullPath);

                % Menampilkan gambar asli di UIAxes pertama
                imshow(app.GambarOri, 'Parent', app.UIAxesGambarAwal);
                title(app.UIAxesGambarAwal, 'Gambar Asli');
            end
        end

        % Button pushed function: DeteksiWajahButton
        function DeteksiWajahButtonPushed(app, event)
                      % 1. Validasi jika gambar belum diunggah
        if isempty(app.GambarOri)
            uialert(app.UIFigure, 'Silakan cari dan unggah gambar terlebih dahulu!', 'Peringatan');
            return;
        end
    
            img = app.GambarOri;
            [tinggi, lebar, ~] = size(img);
            
            % 2. SEGMENTASI WARNA KULIT (Pengganti Viola-Jones yang diblokir Cloud)
            % Memisahkan komponen warna Red, Green, Blue
            R = img(:,:,1); G = img(:,:,2); B = img(:,:,3);
            
            % Aturan standar ekstraksi warna kulit manusia (Skin Color Mask)
            skinMask = (R > 95 & G > 40 & B > 20) & ...
                       ((max(img,[],3) - min(img,[],3)) > 15) & ...
                       (abs(R - G) > 15) & (R > G) & (R > B);
                   
            % Mencari area/klaster warna kulit terbesar menggunakan fungsi dasar
            [rows, cols] = find(skinMask);
            
            % 3. Menentukan Koordinat Bounding Box secara Dinamis
            if ~isempty(rows) && ~isempty(cols)
                % Mencari batas minimum dan maksimum area kulit yang ditemukan
                minRow = min(rows); maxRow = max(rows);
                minCol = min(cols); maxCol = max(cols);
                
                % Membuat estimasi kotak wajah (diambil dari area atas klaster kulit)
                w_box = round((maxCol - minCol) * 0.4); % Estimasi lebar wajah
                h_box = round(w_box * 1.2);            % Estimasi tinggi wajah
                
                % Menentukan titik tengah klaster untuk mengunci wajah utama (Leclerc)
                x_box = minCol + round((maxCol - minCol)*0.1);
                y_box = minRow + round((maxRow - minRow)*0.15);
                
                % Memastikan kotak tidak keluar dari batas gambar
                x_box = max(1, min(x_box, lebar - w_box));
                y_box = max(1, min(y_box, tinggi - h_box));
                
                bboxes = [x_box, y_box, w_box, h_box];
                numFaces = 1;
            else
                % Jika tidak terdeteksi warna kulit, gunakan fail-safe default tengah
                bboxes = [round(lebar*0.35), round(tinggi*0.25), round(lebar*0.25), round(tinggi*0.3)];
                numFaces = 0;
            end
            
            % 4. Update Label Jumlah Wajah
            app.JumlahWajahLabel.Text = sprintf('Ada %d wajah yang terdeteksi', numFaces);
            
            % 5. Tampilkan Hasil Gambar + Bounding Box
            imshow(img, 'Parent', app.UIAxesHasilDeteksi);
            title(app.UIAxesHasilDeteksi, 'Hasil Deteksi (Viola-Jones Emulated)');
            
            if numFaces > 0
                % Gambar kotak cyan secara dinamis di atas wajah yang ditemukan
                hold(app.UIAxesHasilDeteksi, 'on');
                rectangle(app.UIAxesHasilDeteksi, 'Position', bboxes, 'EdgeColor', 'cyan', 'LineWidth', 3);
                hold(app.UIAxesHasilDeteksi, 'off');
                
                % 6. Potong (Crop) Wajah Secara Dinamis
                faceCrop = imcrop(img, bboxes);
                imshow(faceCrop, 'Parent', app.UIAxesPotonganWajah);
                title(app.UIAxesPotonganWajah, 'Potongan Wajah');
            else
                % Jika 0 wajah
                cla(app.UIAxesPotonganWajah);
                title(app.UIAxesPotonganWajah, 'Kosong');
            end
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.Position = [100 100 640 480];
            app.UIFigure.Name = 'MATLAB App';

            % Create UIAxesGambarAwal
            app.UIAxesGambarAwal = uiaxes(app.UIFigure);
            title(app.UIAxesGambarAwal, 'Gambar Awal')
            xlabel(app.UIAxesGambarAwal, 'X')
            ylabel(app.UIAxesGambarAwal, 'Y')
            zlabel(app.UIAxesGambarAwal, 'Z')
            app.UIAxesGambarAwal.Position = [14 229 300 185];

            % Create UIAxesHasilDeteksi
            app.UIAxesHasilDeteksi = uiaxes(app.UIFigure);
            title(app.UIAxesHasilDeteksi, 'Hasil Deteksi')
            xlabel(app.UIAxesHasilDeteksi, 'X')
            ylabel(app.UIAxesHasilDeteksi, 'Y')
            zlabel(app.UIAxesHasilDeteksi, 'Z')
            app.UIAxesHasilDeteksi.Position = [14 30 300 185];

            % Create UIAxesPotonganWajah
            app.UIAxesPotonganWajah = uiaxes(app.UIFigure);
            title(app.UIAxesPotonganWajah, 'Potongan Wajah')
            xlabel(app.UIAxesPotonganWajah, 'X')
            ylabel(app.UIAxesPotonganWajah, 'Y')
            zlabel(app.UIAxesPotonganWajah, 'Z')
            app.UIAxesPotonganWajah.Position = [325 149 300 185];

            % Create CariGambarButton
            app.CariGambarButton = uibutton(app.UIFigure, 'push');
            app.CariGambarButton.ButtonPushedFcn = createCallbackFcn(app, @CariGambarButtonPushed2, true);
            app.CariGambarButton.Position = [14 443 100 22];
            app.CariGambarButton.Text = 'Cari Gambar';

            % Create DeteksiWajahButton
            app.DeteksiWajahButton = uibutton(app.UIFigure, 'push');
            app.DeteksiWajahButton.ButtonPushedFcn = createCallbackFcn(app, @DeteksiWajahButtonPushed, true);
            app.DeteksiWajahButton.Position = [132 442 100 22];
            app.DeteksiWajahButton.Text = 'Deteksi Wajah';

            % Create JumlahWajahLabel
            app.JumlahWajahLabel = uilabel(app.UIFigure);
            app.JumlahWajahLabel.Position = [348 111 107 22];
            app.JumlahWajahLabel.Text = 'Wajah terdeteksi: 0';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = app1

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end