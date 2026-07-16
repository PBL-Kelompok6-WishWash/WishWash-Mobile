<p align="center">
  <img src="assets/images/brand/logo.png" alt="WishWash Logo" width="120" />
</p>

# 📱 WishWash Mobile Application
**Flutter Cross-Platform Application for WishWash Customers & Karyawan (Couriers)**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-Ready-3DDC84?style=for-the-badge&logo=android&logoColor=white)](#)
[![iOS](https://img.shields.io/badge/iOS-Ready-000000?style=for-the-badge&logo=ios&logoColor=white)](#)

Repositori ini berisi kode sumber untuk **Aplikasi Mobile WishWash** berbasis Flutter. Aplikasi ini mencakup dua peran antarmuka (*dual-role UI*) dinamis yang menyesuaikan peran pengguna saat masuk (*login*): **Aplikasi Pelanggan (Customer)** dan **Aplikasi Karyawan (Kurir)**.

---

## 📱 Fitur Utama Aplikasi Mobile

### 👦 Antarmuka Pelanggan (Customer App)
*   **Pemesanan Laundry Mudah**: Pilih jenis layanan (Kiloan/Satuan), paket durasi (Express/Reguler), serta preferensi parfum langsung dari aplikasi.
*   **Multi-Address & Primary Address**: Daftarkan beberapa alamat pengambilan/penyerahan laundry dan pilih salah satu sebagai alamat utama.
*   **Pelacakan Real-time (Live Tracking)**: Pantau status perjalanan kurir dan proses pencucian di timeline status pesanan.
*   **Chat Terintegrasi**: Kirim pesan langsung ke kurir yang bertugas menangani pesanan Anda.
*   **Riwayat Pesanan Tertata**: Semua transaksi yang dibatalkan, ditolak (beserta alasan penolakannya), atau selesai diurutkan secara runtut berdasarkan tanggal pembaruan terakhir.

### 🛵 Antarmuka Karyawan / Kurir (Courier App)
*   **Manajemen Tugas**: Menerima tugas penjemputan (*pickup*) dan pengantaran (*delivery*) pakaian.
*   **Navigasi Peta Rute**: Buka peta penunjuk arah (*Google Maps integration*) langsung dari detail pesanan saat melakukan penjemputan atau pengantaran.
*   **QR Code Scanner**: Lakukan konfirmasi penerimaan laundry di lokasi pelanggan dengan memindai barcode/QR Code nota pesanan.
*   **Proses Timbang**: Memulai proses penimbangan berat cucian pelanggan langsung dari aplikasi kurir (khusus layanan kiloan).

---

## 📂 Struktur Folder Mobile

```text
WishWash-Mobile/
├── assets/              # Aset visual (logo, ilustrasi onboarding, ikon)
├── lib/
│   ├── screens/         # Halaman antarmuka terbagi atas:
│   │   ├── auth/        # Logika login & pendaftaran akun
│   │   ├── pelanggan/   # Fitur & halaman untuk peran Pelanggan
│   │   └── karyawan/    # Fitur & halaman untuk peran Kurir/Karyawan
│   ├── services/        # Service integrasi REST API, WebSockets, & Translate bahasa
│   ├── utils/           # Konfigurasi konstan, warna tema, & deteksi alamat API
│   └── widgets/         # Komponen UI dinamis (Card, Loader, Bottom Sheet)
├── pubspec.yaml         # File manajer paket pustaka/dependensi Flutter
└── README.md            # Dokumentasi utama repositori Mobile
```

---

## 🛠️ Panduan Memulai (Quick Start)

### 1. Prasyarat Sistem
*   **Flutter SDK** (Versi 3.22 ke atas)
*   **Dart SDK** (Versi 3.x)
*   Perangkat simulator (Android Emulator / iOS Simulator) atau perangkat HP fisik yang terhubung dengan kabel USB.

### 2. Konfigurasi Endpoint Backend API
Aplikasi mobile mendeteksi alamat server API secara dinamis berdasarkan prioritas koneksi Anda.
Untuk menyesuaikan IP lokal komputer Anda, buka file:
👉 **[lib/utils/constants.dart](lib/utils/constants.dart)**

Ubah nilai fallback IP Wi-Fi PC/Laptop Anda pada variabel `baseUrl`:
```dart
// Contoh pada lib/utils/constants.dart
baseUrl = 'http://IP_PC_LAPTOP_ANDA:8080/api/v1';
```
> 💡 **Tips Pengujian Dual-Device**: Jika menguji dengan HP Fisik, pastikan HP dan PC/Laptop terhubung ke jaringan Wi-Fi yang sama, atau jalankan perintah `adb reverse tcp:8080 tcp:8080` untuk memetakan localhost PC langsung ke perangkat Android Anda.

### 3. Instalasi Paket Dependensi
Jalankan perintah ini di dalam folder root `WishWash-Mobile/` untuk mengunduh semua pustaka:
```bash
flutter pub get
```

### 4. Menjalankan Aplikasi
Mulai jalankan aplikasi ke emulator atau perangkat fisik Anda:
```bash
flutter run
```

---

## 📦 Pustaka Pihak Ketiga Utama (Key Packages)
*   `google_maps_flutter`: Integrasi Google Maps untuk menampilkan rute penjemputan/pengantaran.
*   `location` & `geolocator`: Mengambil titik koordinat GPS real-time kurir.
*   `web_socket_channel`: Komunikasi dua arah dengan WebSocket Server Go untuk live tracking.
*   `qr_code_scanner`: Pemindai barcode nota order fisik menggunakan kamera smartphone.

---

<div align="center">
  <b>PBL Kelompok 6 - WishWash Laundry</b><br>
  Teknologi Rekayasa Komputer, Politeknik Negeri Semarang
</div>
