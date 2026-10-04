# Implementasi Mobile Drawer (Menu Samping)

Tugas ini bertujuan untuk menambahkan menu samping (Drawer) pada versi mobile agar semua fitur (seperti Deposit, Tabungan, Dana vs Tagihan) dapat diakses dengan mudah, mirip dengan tampilan di website konstruksi Anda yang lain.

## Proposed Changes

### UI Components

#### [NEW] [mobile_drawer.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/dashboard/widgets/mobile_drawer.dart)
- Membuat widget Drawer khusus mobile dengan:
    - **Header**: Profil Aidan Suhendy dengan latar belakang gradasi biru (Apple Style).
    - **Menu List**: Daftar lengkap navigasi (Dashboard, Dompet, Tabungan, Deposit, Hutang, Riwayat, Dana vs Tagihan).
    - **Footer**: Tombol Logout yang terintegrasi dengan `AuthProvider`.

### Dashboard Integration

#### [MODIFY] [dashboard_screen.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/dashboard/dashboard_screen.dart)
- Menambahkan properti `drawer` pada `Scaffold` saat dalam mode mobile.
- Menambahkan tombol **Hamburger Menu** (3 garis) di header dashboard mobile untuk membuka drawer.
- Memberikan judul halaman yang dinamis di header mobile sesuai menu yang aktif.

### Refinement
- Menyelaraskan gaya visual Drawer dengan `Sidebar` desktop namun tetap mengacu pada referensi screenshot "Data Konstruksi" yang diberikan.

## Verification Plan

### Manual Verification
- Buka aplikasi dalam mode mobile (simulasi Chrome).
- Klik tombol 3 garis di pojok kiri atas.
- Pastikan Drawer muncul dengan lancar.
- Coba klik menu "Tabungan" atau "Deposit" dan pastikan halaman berpindah dengan benar.
- Coba tombol "Logout" di bagian bawah drawer.
