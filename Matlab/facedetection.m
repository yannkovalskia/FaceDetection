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

        % Button pushed function: CariGambarButton (edit bagian ini aja)
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

        % Button pushed function: DeteksiWajahButton (sama bagian ini buat tombol deteksi wajah)
        function DeteksiWajahButtonPushed(app, event)
                          % 1. Validasi jika gambar belum diunggah
        if isempty(app.GambarOri)
            uialert(app.UIFigure, 'Silakan cari dan unggah gambar terlebih dahulu!', 'Peringatan');
            return;  
        end
            
            % Ambil gambar dari properti global app
            img = app.GambarOri;
            
            % 2. Inisialisasi Detektor Wajah Viola-Jones
            faceDetector = vision.CascadeObjectDetector();
            
            % 3. Jalankan Proses Deteksi
            bboxes = step(faceDetector, img);
            
            % 4. Hitung Jumlah Wajah yang Berhasil Ditemukan dan update
            % label
            numFaces = size(bboxes, 1);
            app.JumlahWajahLabel.Text = sprintf('Ada %d wajah yang terdeteksi', numFaces);
            
            % 5. Jika Ada Wajah yang Terdeteksi
            if numFaces > 0
                % Gambar kotak bounding box berwarna cyan tepat di posisi wajah
                detectedImg = insertShape(img, 'Rectangle', bboxes, 'LineWidth', 3, 'Color', 'cyan');
                
                % Tampilkan gambar hasil deteksi di UIAxes kedua
                imshow(detectedImg, 'Parent', app.UIAxesHasilDeteksi);
                title(app.UIAxesHasilDeteksi, 'Hasil Deteksi (Viola-Jones)');
                
                % 6. Potong (Crop) Wajah Pertama yang Ditemukan
                faceCrop = imcrop(img, bboxes(1, :));
                
                % Tampilkan potongan wajah tersebut di UIAxes ketiga
                imshow(faceCrop, 'Parent', app.UIAxesPotonganWajah);
                title(app.UIAxesPotonganWajah, 'Potongan Wajah');
            else
                % Jika tidak ada wajah sama sekali yang terdeteksi
                imshow(img, 'Parent', app.UIAxesHasilDeteksi);
                title(app.UIAxesHasilDeteksi, 'Tidak Ada Wajah Terdeteksi');
                
                % Kosongkan panel potongan wajah
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
