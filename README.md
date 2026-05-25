<div align="center">
  
# 🧺 WishWash
**Laundry Management System**

[![Go Version](https://img.shields.io/badge/Go-1.20+-00ADD8?style=flat&logo=go&logoColor=white)](https://golang.org/)
[![Flutter](https://img.shields.io/badge/Flutter-Mobile-02569B?style=flat&logo=flutter&logoColor=white)](https://flutter.dev/)
[![Next.js](https://img.shields.io/badge/Next.js-Web-000000?style=flat&logo=next.js&logoColor=white)](https://nextjs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-4169E1?style=flat&logo=postgresql&logoColor=white)](https://www.postgresql.org/)

WishWash adalah solusi manajemen laundry terintegrasi end-to-end yang dirancang untuk mendigitalisasi dan mengotomatisasi operasional laundry. Sistem ini mencakup pelacakan status cucian secara real-time, manajemen pesanan, manajemen operasional, dan komunikasi terpadu.

</div>

---

## ✨ Fitur Utama

Aplikasi ini dibagi menjadi 3 antarmuka utama yang disesuaikan untuk setiap peran pengguna:

### 👑 Admin Dashboard (Web)
*   **Manajemen Master Data**: Kelola pelanggan, karyawan/kurir, layanan, paket, parfum, dan metode pembayaran.
*   **Manajemen Promo**: Buat dan atur kode promo diskon untuk pelanggan.
*   **Pantauan Transaksi**: Lihat semua pesanan masuk, proses, hingga selesai secara real-time.
*   **Laporan & Analitik**: (Akan datang) Rekapitulasi pendapatan dan performa laundry.

### 📱 Customer App (Mobile)
*   **Pemesanan Mudah**: Pesan layanan laundry dengan pilihan paket durasi dan preferensi parfum.
*   **Manajemen Alamat**: Simpan berbagai alamat (rumah, kos, kantor) dengan satu alamat utama (Primary).
*   **Live Tracking**: Lacak status pesanan secara real-time (Mulai dari *Menunggu Penjemputan* hingga *Selesai*).
*   **Chat Real-time**: Komunikasi langsung dengan kurir yang bertugas menjemput/mengantar cucian.

### 🛵 Courier/Karyawan App (Mobile)
*   **Manajemen Tugas**: Terima tugas penjemputan dan pengantaran cucian.
*   **Update Status**: Perbarui status cucian ke database hanya dengan beberapa tap.
*   **Komunikasi Pelanggan**: Chat langsung dengan pelanggan untuk konfirmasi lokasi atau jadwal.

---

## 🚀 Tech Stack & Arsitektur Sistem

Proyek ini dibangun menggunakan arsitektur modern berbasis micro-services dan pemisahan *frontend-backend* yang bersih:

| Komponen | Teknologi | Deskripsi |
| :--- | :--- | :--- |
| **Backend API** | Go (Golang), Gin, GORM | RESTful API berkinerja tinggi, dilengkapi autentikasi JWT Role-based. |
| **Database** | PostgreSQL 18 | Sistem manajemen basis data relasional untuk integritas data. |
| **Web Frontend** | Next.js, React, Tailwind CSS | Dasbor admin yang responsif, cepat, dan modern. |
| **Mobile Frontend** | Flutter, Dart | Aplikasi lintas platform (Android/iOS) dengan UI/UX yang dinamis. |

---

## 📂 Struktur Folder Proyek

```text
WISHWASH-APP/
├── assets/              # Aset gambar/icon global
├── backend/             # Source code API (Golang)
│   ├── cmd/             # Entry point aplikasi (main.go)
│   ├── config/          # Konfigurasi Database & Environment
│   ├── controller/      # Handler & Logika bisnis API
│   ├── middleware/      # Keamanan (JWT Auth, Role checking)
│   ├── model/           # Definisi skema tabel (GORM Structs)
│   ├── repository/      # Fungsi query interaksi ke database
│   ├── route/           # Pengaturan endpoint REST API
│   └── seeder/          # Data awal (dummy data) database
├── mobile/              # Source code App Customer & Kurir (Flutter)
│   ├── lib/             # Kodingan utama antarmuka & logika Dart
│   │   ├── screens/     # Tampilan halaman per peran (admin/pelanggan/karyawan)
│   │   ├── services/    # Penghubung API ke backend
│   │   └── widgets/     # Komponen UI yang dapat digunakan ulang
│   └── pubspec.yaml     # Dependency Manager Flutter
├── web/                 # Source code Dashboard Admin (Next.js)
│   ├── src/app/         # Next.js App Router (Halaman & Layout)
│   ├── src/components/  # Komponen React (Sidebar, Header, dll)
│   ├── src/services/    # Penghubung API ke backend
│   └── package.json     # Dependency Manager Node.js
├── api_documentation.md # Dokumentasi Lengkap Endpoint API
└── README.md            # Dokumentasi utama proyek
```

---

## 🛠️ Panduan Memulai (Quick Start)

### 1. Persyaratan Sistem
Pastikan perangkat Anda sudah terinstal perangkat lunak berikut:
*   [Golang](https://golang.org/dl/) (v1.20+)
*   [PostgreSQL](https://www.postgresql.org/download/)
*   [Node.js & npm](https://nodejs.org/)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)

### 2. Setup Database
1. Buat database baru bernama `wishwash_db` di PostgreSQL Anda.
2. Pastikan database berjalan (default port `5433` atau sesuaikan dengan pengaturan Anda).

### 3. Konfigurasi Environment (`.env`)
Buat file bernama `.env` di **root folder** proyek (`WishWash-App/.env`) dan isi dengan konfigurasi berikut:
```env
# Database Configuration
DB_HOST=localhost
DB_PORT=5433
DB_USER=postgres
DB_PASSWORD=password_database_anda
DB_NAME=wishwash_db

# Backend API URL (Digunakan oleh Web & Mobile)
NEXT_PUBLIC_API_URL=http://localhost:8080
```
> ⚠️ **Penting**: Jangan pernah mem-push file `.env` yang berisi kredensial asli ke GitHub!

### 4. Menjalankan Backend (API)
```bash
cd backend
go mod tidy
go run cmd/main.go
```
*Server akan berjalan di `http://localhost:8080` dan otomatis melakukan migrasi tabel database.*

### 5. Menjalankan Web (Dashboard Admin)
```bash
cd web
npm install
npm run dev
```
*Buka browser dan akses `http://localhost:3000`.*

### 6. Menjalankan Mobile (Aplikasi)
```bash
cd mobile
flutter pub get
flutter run
```

---

## 📖 Dokumentasi API
Untuk melihat dokumentasi lengkap mengenai seluruh endpoint, metode request, dan contoh response dari sistem backend WishWash, silakan merujuk ke file:
👉 **[Dokumentasi API Lengkap (api_documentation.md)](api_documentation.md)**

---

## 🔄 Panduan Kerja Tim (Git Workflow)

Agar kolaborasi kode berjalan rapi dan tidak terjadi konflik, ikuti aturan dasar berikut:

1. **Selalu Tarik Pembaruan Terbaru**:
   ```bash
   git pull origin main
   ```
2. **Simpan dan Kirim Perubahan dengan Pesan yang Jelas**:
   Gunakan format standar untuk *commit message*, contohnya:
   *   `feat: [nama_fitur] deskripsi` (Untuk fitur baru)
   *   `fix: [nama_fitur] deskripsi` (Untuk perbaikan bug)
   *   `ui: update tampilan dashboard` (Untuk perubahan desain)
   
   ```bash
   git add .
   git commit -m "feat: menambah endpoint tracking status"
   git push origin main
   ```

---

<div align="center">
  <b>Dikembangkan dengan ❤️ oleh Tim PBL Kelompok 6</b><br>
  Program Studi Teknologi Rekayasa Komputer<br>
  Politeknik Negeri Semarang (POLINES)
</div>
