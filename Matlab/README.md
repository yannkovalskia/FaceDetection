# Program Deteksi Wajah (Face Detection) - MATLAB

## Deskripsi Umum
Program ini adalah aplikasi **MATLAB App Designer** yang dirancang untuk mendeteksi wajah dalam sebuah gambar menggunakan algoritma segmentasi warna kulit (*Skin Color Segmentation*). Aplikasi ini menyediakan antarmuka grafis yang user-friendly untuk memudahkan pengguna dalam memilih gambar, mendeteksi wajah, dan melihat hasil deteksi secara real-time.

---

## Fitur Utama

### 1. **Pemilihan Gambar**
   - Tombol "Cari Gambar" memungkinkan pengguna memilih file gambar dari berbagai format
   - Format yang didukung: `*.jpg`, `*.png`, `*.jpeg`, `*.bmp`
   - Gambar yang dipilih akan ditampilkan di panel pertama (UIAxes Gambar Awal)

### 2. **Deteksi Wajah**
   - Menggunakan algoritma berbasis **Skin Color Segmentation** (pendeteksian warna kulit)
   - Mendeteksi area wajah dengan membuat bounding box otomatis
   - Hasil ditampilkan dengan kotak cyan di atas wajah yang terdeteksi

### 3. **Tampilan Hasil**
   - **Panel 1**: Gambar asli yang dipilih pengguna
   - **Panel 2**: Hasil deteksi dengan bounding box (kotak cyan)
   - **Panel 3**: Potongan wajah yang terdeteksi secara otomatis
   - **Label**: Menampilkan jumlah wajah yang berhasil dideteksi

---

## Struktur Program

### **Komponen Utama (Properties)**

```matlab
properties (Access = public)
    UIFigure             % Jendela utama aplikasi
    JumlahWajahLabel     % Label penampil jumlah wajah terdeteksi
    DeteksiWajahButton   % Tombol untuk memulai deteksi
    CariGambarButton     % Tombol untuk memilih gambar
    UIAxesPotonganWajah  % Panel display potongan wajah
    UIAxesHasilDeteksi   % Panel display hasil deteksi dengan bounding box
    UIAxesGambarAwal     % Panel display gambar asli
end

properties (Access = private)
    GambarOri            % Penyimpanan gambar asli yang dipilih
end
```

---

## Penjelasan Algoritma Deteksi

### **Langkah 1: Validasi Input**
Program terlebih dahulu memvalidasi apakah gambar telah dipilih. Jika belum, sistem akan menampilkan peringatan kepada pengguna.

```matlab
if isempty(app.GambarOri)
    uialert(app.UIFigure, 'Silakan cari dan unggah gambar terlebih dahulu!', 'Peringatan');
    return;
end
```

### **Langkah 2: Segmentasi Warna Kulit (Skin Color Segmentation)**

Program memisahkan komponen warna RGB dari gambar:
```matlab
R = img(:,:,1);  % Komponen Red
G = img(:,:,2);  % Komponen Green
B = img(:,:,3);  % Komponen Blue
```

Kemudian menerapkan **aturan ekstraksi warna kulit manusia** dengan kriteria berikut:
- **R > 95 dan G > 40 dan B > 20**: Nilai RGB minimal untuk warna kulit
- **(max - min) > 15**: Perbedaan kontras antar komponen warna harus signifikan
- **|R - G| > 15**: Perbedaan antara Red dan Green harus cukup besar
- **R > G dan R > B**: Komponen Red harus paling dominan

```matlab
skinMask = (R > 95 & G > 40 & B > 20) & ...
           ((max(img,[],3) - min(img,[],3)) > 15) & ...
           (abs(R - G) > 15) & (R > G) & (R > B);
```

**Hasil dari tahap ini adalah `skinMask`**, sebuah binary image (hitam-putih) yang menunjukkan area-area yang diduga sebagai wajah/kulit manusia.

### **Langkah 3: Pencarian Area Kulit**

Program mencari semua koordinat pixel yang memenuhi kriteria warna kulit:
```matlab
[rows, cols] = find(skinMask);
```

Koordinat ini akan digunakan untuk menentukan batas-batas wajah.

### **Langkah 4: Penentuan Bounding Box Dinamis**

Berdasarkan area kulit yang ditemukan, program menghitung:

**a) Batas Minimum dan Maksimum:**
```matlab
minRow = min(rows);  % Baris paling atas dari wajah
maxRow = max(rows);  % Baris paling bawah dari wajah
minCol = min(cols);  % Kolom paling kiri dari wajah
maxCol = max(cols);  % Kolom paling kanan dari wajah
```

**b) Estimasi Ukuran Kotak Wajah:**
```matlab
w_box = round((maxCol - minCol) * 0.4);  % Lebar kotak (40% dari lebar area kulit)
h_box = round(w_box * 1.2);              % Tinggi kotak (120% dari lebar)
```

**c) Penentuan Posisi Kotak:**
```matlab
x_box = minCol + round((maxCol - minCol)*0.1);  % Offset horizontal 10%
y_box = minRow + round((maxRow - minRow)*0.15); % Offset vertikal 15%
```

**d) Validasi Batas Gambar:**
Program memastikan kotak tidak keluar dari batas gambar:
```matlab
x_box = max(1, min(x_box, lebar - w_box));
y_box = max(1, min(y_box, tinggi - h_box));
```

**Hasil akhir adalah struktur bounding box:**
```matlab
bboxes = [x_box, y_box, w_box, h_box]
% Format: [koordinat_x, koordinat_y, lebar, tinggi]
```

### **Langkah 5: Perbaruan Label dan Tampilan**

Program memperbarui label dengan jumlah wajah terdeteksi:
```matlab
app.JumlahWajahLabel.Text = sprintf('Ada %d wajah yang terdeteksi', numFaces);
```

### **Langkah 6: Visualisasi Hasil**

**a) Menampilkan gambar asli dengan bounding box:**
```matlab
imshow(img, 'Parent', app.UIAxesHasilDeteksi);
rectangle(app.UIAxesHasilDeteksi, 'Position', bboxes, 'EdgeColor', 'cyan', 'LineWidth', 3);
```

**b) Melakukan cropping (pemotongan) pada area wajah:**
```matlab
faceCrop = imcrop(img, bboxes);
imshow(faceCrop, 'Parent', app.UIAxesPotonganWajah);
```

---

## Alur Kerja Program

```
┌─────────────────────────────┐
│   JALANKAN APLIKASI         │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   KLIK "CARI GAMBAR"        │
│   - Buka dialog file        │
│   - Pilih file gambar       │
│   - Tampilkan di UIAxes 1   │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│   KLIK "DETEKSI WAJAH"      │
└──────────────┬──────────────┘
               │
        ┌──────┴──────┐
        │ PROSES:     │
        │ 1. Validasi │
        │ 2. RGB Split│
        │ 3. Skin Mask│
        │ 4. Bounding │
        │    Box      │
        │ 5. Crop     │
        └──────┬──────┘
               │
               ▼
┌─────────────────────────────┐
│   TAMPILKAN HASIL:          │
│   - UIAxes 2: Gambar+Box    │
│   - UIAxes 3: Potongan Face │
│   - Label: Jumlah wajah     │
└─────────────────────────────┘
```

---

## Keuntungan dan Keterbatasan

### **Keuntungan:**
✅ Algoritma ringan dan cepat dieksekusi  
✅ Tidak memerlukan training data seperti deep learning  
✅ User interface intuitif dan mudah digunakan  
✅ Bounding box otomatis menyesuaikan ukuran wajah  

### **Keterbatasan:**
❌ Hanya mendeteksi 1 wajah (single face detection)  
❌ Akurasi berkurang pada gambar dengan pencahayaan buruk  
❌ Tidak efektif untuk wajah dengan warna kulit ekstrem  
❌ Dapat memberikan false positive pada obyek berwarna mirip kulit  
❌ Tidak bisa mendeteksi wajah yang tertutup sebagian  

---

## Persyaratan Sistem

- **MATLAB R2016a atau lebih baru** (untuk App Designer)
- **Image Processing Toolbox** (untuk fungsi `imread`, `imshow`, `imcrop`)
- **Resolusi layar minimum**: 640x480 piksel
- **Format gambar yang didukung**: JPG, PNG, JPEG, BMP

---

## Cara Penggunaan

1. **Jalankan Program:**
   ```matlab
   app1
   ```

2. **Pilih Gambar:**
   - Klik tombol "Cari Gambar"
   - Navigasi ke folder yang berisi gambar
   - Pilih file gambar (*.jpg, *.png, *.jpeg, *.bmp)
   - Klik "Open"

3. **Deteksi Wajah:**
   - Klik tombol "Deteksi Wajah"
   - Program akan memproses gambar dan menampilkan hasil

4. **Interpretasi Hasil:**
   - **Panel kiri atas**: Gambar asli yang Anda pilih
   - **Panel kiri bawah**: Hasil deteksi dengan bounding box cyan
   - **Panel kanan**: Potongan wajah yang terdeteksi
   - **Label**: Menampilkan jumlah wajah yang ditemukan

---

## Catatan Teknis

- Fungsi `skinMask` menggunakan **logical operators** untuk efisiensi maksimal
- Koordinat pixel menggunakan sistem **1-based indexing** (MATLAB standard)
- Bounding box dengan format `[x, y, width, height]` sesuai standar MATLAB
- Warna kotak deteksi menggunakan **cyan** untuk kontras yang jelas terhadap kebanyakan gambar

---

## Pengembangan Lebih Lanjut

Beberapa ide untuk meningkatkan program ini:

1. **Multi-face Detection**: Modifikasi algoritma untuk mendeteksi multiple wajah
2. **Histogram Equalization**: Perbaiki hasil pada gambar dengan kontras rendah
3. **Morphological Operations**: Tambahkan erode/dilate untuk menghilangkan noise
4. **Machine Learning**: Implementasi CNN untuk akurasi lebih tinggi
5. **Real-time Detection**: Integrasi dengan webcam untuk deteksi real-time
6. **Export Hasil**: Tambahkan fitur untuk menyimpan gambar hasil deteksi

---

## Lisensi dan Penulis

27 Mei 2026

---

**Dibuat: 2026**  
**Status: Active Development**
