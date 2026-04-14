# Access Resources Flutter App

Project Flutter untuk demonstrasi akses resource perangkat: kamera, GPS + Google Maps, file picker, dan gallery image picker.

## Fitur Utama

- Camera preview dan ambil foto, lalu simpan ke album gallery (`flutter_access_device_app`).
- Tracking lokasi real-time menggunakan package `location`.
- Menampilkan lokasi saat ini di `GoogleMap` dengan marker.
- Pilih file dengan ekstensi tertentu (`pdf`, `docx`, `txt`).
- Pilih direktori dari penyimpanan perangkat.
- Pilih gambar dari gallery.

## Teknologi dan Package

- Flutter (Material 3)
- `camera`
- `gal`
- `location`
- `google_maps_flutter`
- `file_picker`
- `image_picker`

## Struktur Layar

- Home menu resource
- Camera screen
- GPS + Google Maps screen
- File manager screen
- Gallery picker screen

## Cara Menjalankan

1. Pastikan Flutter SDK sudah terpasang.
2. Install dependency:

```bash
flutter pub get
```

3. Jalankan aplikasi:

```bash
flutter run
```

## Konfigurasi Penting

- Android: pastikan permission kamera dan lokasi sudah ada di `AndroidManifest.xml`.
- Google Maps: tambahkan API key Google Maps Android sesuai dokumentasi `google_maps_flutter`.
- iOS: tambahkan usage description untuk camera/gallery/location di `Info.plist`.

## Tujuan Project

Project ini dipakai untuk latihan praktikum PPB agar memahami cara integrasi beberapa native resources di Flutter dalam satu aplikasi.
