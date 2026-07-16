<p align="center">
  <img src="logo.png" alt="WishWash Logo" width="120" style="background: white; border-radius: 24px; padding: 10px;" />
</p>

<h3 align="center">WishWash Mobile Application</h3>
<p align="center">Flutter Cross-Platform App for WishWash Customers & Karyawan (Couriers)</p>

<p align="center">
  <a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" /></a>
  <a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.10-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" /></a>
  <a href="#"><img src="https://img.shields.io/badge/Android-Ready-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" /></a>
  <a href="#"><img src="https://img.shields.io/badge/iOS-Ready-000000?style=for-the-badge&logo=ios&logoColor=white" alt="iOS" /></a>
</p>

---

## 📋 Deskripsi

Repositori ini berisi kode sumber **Aplikasi Mobile WishWash** berbasis Flutter. Aplikasi ini mengimplementasikan arsitektur *dual-role UI* — satu kode sumber menghasilkan dua antarmuka dinamis yang secara otomatis menyesuaikan peran pengguna saat login: **Aplikasi Pelanggan (Customer)** untuk memesan laundry dan **Aplikasi Karyawan (Kurir)** untuk mengelola tugas penjemputan, pencucian, dan pengantaran.

---

## 📱 Fitur Utama

### 👦 Antarmuka Pelanggan (Customer App)
*   **Pemesanan Laundry** — Pilih jenis layanan (Kiloan/Satuan), paket durasi (Express/Reguler), serta preferensi parfum.
*   **Multi-Address & Primary Address** — Daftarkan beberapa alamat (rumah, kos, kantor) dan pilih satu sebagai alamat utama.
*   **Pelacakan Real-time (Live Tracking)** — Pantau posisi kurir secara langsung di peta saat penjemputan maupun pengantaran menggunakan OpenStreetMap.
*   **Chat Terintegrasi** — Kirim pesan langsung ke kurir yang bertugas menangani pesanan.
*   **Riwayat Pesanan Tertata** — Seluruh transaksi (selesai, dibatalkan, ditolak beserta alasan penolakan) diurutkan secara kronologis berdasarkan tanggal pembaruan terakhir.
*   **Voucher & Promo** — Gunakan kode promo saat pemesanan untuk mendapatkan potongan harga.
*   **Penilaian & Rating** — Berikan bintang dan komentar setelah pesanan selesai.

### 🛵 Antarmuka Karyawan / Kurir (Courier App)
*   **Manajemen Tugas Penjemputan & Pengantaran** — Terima tugas otomatis dari admin dan lihat detail pesanan.
*   **Navigasi Peta Rute** — Buka peta penunjuk arah rute penjemputan/pengantaran langsung dari halaman detail pesanan (OpenStreetMap via `flutter_map`).
*   **QR/Barcode Scanner** — Konfirmasi penyerahan laundry dengan memindai barcode nota pesanan menggunakan kamera smartphone.
*   **Proses Timbang Cucian** — Memulai penimbangan berat cucian pelanggan langsung dari aplikasi (khusus layanan kiloan).
*   **Update Status Pesanan** — Perbarui status pesanan secara bertahap (Jemput → Timbang → Cuci → Kering → Lipat → Antar → Selesai).
*   **Tandai Pembayaran Lunas** — Konfirmasi penerimaan pembayaran COD/Cash saat sampai di lokasi pelanggan.

---

## 📂 Struktur Folder

```text
WishWash-Mobile/
├── assets/
│   ├── images/
│   │   ├── brand/       # Logo aplikasi & adaptive icon
│   │   ├── backgrounds/ # Ilustrasi latar belakang onboarding
│   │   ├── icons/       # Ikon-ikon custom
│   │   ├── promos/      # Gambar banner promo
│   │   └── services/    # Gambar ilustrasi layanan
│   ├── lottie/          # Animasi Lottie JSON (loading, success, dsb.)
│   └── audio/           # Efek suara notifikasi
├── lib/
│   ├── screens/
│   │   ├── auth/        # Halaman login & pendaftaran akun
│   │   ├── pelanggan/   # Semua halaman peran Pelanggan
│   │   │   ├── home/          # Beranda, notifikasi, chat
│   │   │   ├── orders/        # Daftar pesanan, detail, riwayat
│   │   │   ├── create_order/  # Formulir pembuatan pesanan baru
│   │   │   ├── profile/       # Profil & pengaturan akun
│   │   │   └── address/       # Manajemen alamat
│   │   └── karyawan/    # Semua halaman peran Karyawan/Kurir
│   │       ├── home/          # Beranda kurir, notifikasi, scanner
│   │       ├── orders/        # Tugas pesanan, detail, pelacakan
│   │       └── profile/       # Profil karyawan
│   ├── services/        # Service layer (REST API client, WebSocket, Translation)
│   ├── utils/           # Konfigurasi konstan, deteksi otomatis alamat API server
│   └── widgets/         # Komponen UI reusable (Navbar, Background, Dialog)
├── android/             # Konfigurasi native Android (Gradle, Manifest)
├── ios/                 # Konfigurasi native iOS
├── pubspec.yaml         # Manajer dependensi Flutter
└── README.md            # Dokumentasi repositori ini
```

---

## 🛠️ Panduan Memulai (Quick Start)

### 1. Prasyarat Sistem
| Software | Versi Minimum |
| :--- | :--- |
| [Flutter SDK](https://docs.flutter.dev/get-started/install) | v3.22+ |
| [Dart SDK](https://dart.dev/) | v3.10+ |
| Android Studio / VS Code | Terbaru |
| Perangkat fisik / Emulator | Android 5.0+ atau iOS 12+ |

### 2. Konfigurasi Endpoint Backend API
Aplikasi mobile mendeteksi alamat server API secara otomatis dengan urutan prioritas:
1. **Emulator** (`10.0.2.2:8080`) — Untuk Android Emulator
2. **ADB Reverse** (`127.0.0.1:8080`) — Untuk HP fisik via USB
3. **Fallback IP Wi-Fi** — Untuk HP fisik via jaringan lokal

Untuk menyesuaikan IP fallback, ubah file 👉 **[lib/utils/constants.dart](lib/utils/constants.dart)**:
```dart
baseUrl = 'http://IP_PC_ANDA:8080/api/v1';
```

> 💡 **Tips**: Jika menggunakan HP fisik via USB, cukup jalankan:
> ```bash
> adb reverse tcp:8080 tcp:8080
> ```

### 3. Instalasi Dependensi
```bash
flutter pub get
```

### 4. Menjalankan Aplikasi
```bash
flutter run
```

---

## 📚 Dependensi Utama

| Package | Fungsi |
| :--- | :--- |
| `http` | HTTP client untuk komunikasi REST API |
| `web_socket_channel` | Komunikasi WebSocket dua arah untuk live tracking |
| `flutter_map` + `latlong2` | Peta interaktif OpenStreetMap untuk navigasi rute kurir |
| `geolocator` + `geocoding` | Akses GPS & konversi koordinat ke alamat |
| `mobile_scanner` | Pemindai QR Code/Barcode via kamera |
| `barcode_widget` | Generate barcode pada nota pesanan |
| `shared_preferences` | Penyimpanan lokal ringan (token, preferensi) |
| `google_fonts` | Tipografi Poppins & font Google lainnya |
| `lottie` | Animasi Lottie JSON (loading, success, dsb.) |
| `audioplayers` | Efek suara notifikasi masuk |
| `image_picker` | Ambil foto dari kamera/galeri untuk upload profil |
| `pdf` + `share_plus` | Generate & bagikan nota pesanan dalam format PDF |
| `intl` | Formatting tanggal & mata uang Rupiah (id_ID) |
| `url_launcher` | Buka link eksternal (WhatsApp, telepon, dsb.) |

---

## 🔗 Repositori Terkait

| Repositori | Deskripsi |
| :--- | :--- |
| [WishWash-Backend](https://github.com/PBL-Kelompok6-WishWash/WishWash-Backend) | Backend API Server (Go / Gin / GORM) |
| [WishWash-Web](https://github.com/PBL-Kelompok6-WishWash/WishWash-Web) | Web Admin Dashboard (Next.js / React) |

---

## 👥 Tim Pengembang

| Nama | NIM | Peran |
| :--- | :--- | :--- |
| Muhammad Rafa Enrico | 4.33.24.2.15 | Full-Stack Developer |
| Annisa Naelil Izati | 4.33.24.2.03 | Full-Stack Developer |
| Devi Ibnu Nabila | 4.33.24.2.06 | Full-Stack Developer |
| Siti Miftahus Sa'diyah | 4.33.24.2.21 | Full-Stack Developer |

---

## 👨‍🏫 Dosen Pembimbing

*   **Suko Tyas Pernanda, S.ST., M.Cs** (Dosen Pembimbing Utama)
*   **Wiktasari, S.T., M.Kom** (Dosen Pembimbing Pendamping)

---

<div align="center">
  <b>PBL Kelompok 6 — WishWash Laundry</b><br>
  Program Studi D4 Teknologi Rekayasa Komputer<br>
  Jurusan Elektro<br>
  Politeknik Negeri Semarang<br>
  Semester Genap 2025/2026
</div>
