# Rencana Implementasi: Rebranding UI Gaya "Data Konstruksi"

Rencana ini bertujuan untuk mengubah gaya visual aplikasi Keuangan Pribadi agar identik dengan proyek "Data Konstruksi", mencakup tema, sidebar, kartu, dan grafik.

## User Review Required

> [!IMPORTANT]
> **Font:** Saya akan menggunakan font `Plus Jakarta Sans` melalui Google Fonts untuk menyamai gaya tipografi di proyek Data Konstruksi.
>
> **Layout:** Struktur Dashboard akan dipertahankan (Dompet, Tabungan, dll), namun elemen visual seperti bayangan (shadow), sudut membulat (border radius), dan efek kaca (glassmorphism) akan diperbarui secara total.

## Proposed Changes

### 1. Global Theme & Typography
- Memperbarui `lib/core/app_theme.dart` dengan warna latar belakang `Color(0xFFF8F9FA)` dan font `Plus Jakarta Sans`.
- Mengatur `ThemeData` agar menggunakan `Material 3` dengan skema warna yang lebih bersih.

### 2. Sidebar & Tagihan Koko
- Merombak `lib/features/dashboard/widgets/sidebar.dart`:
    - **PENTING:** Menghapus sistem dropdown (expandable). Semua menu akan tampil flat.
    - Menambahkan `BackdropFilter` untuk efek blur/kaca pada sidebar.
    - Ikon menggunakan `CupertinoIcons` dengan warna hitam solid (`Colors.black`).
    - Menambahkan widget `Tagihan Koko` di bagian bawah sidebar dengan desain kartu putih bersih, indikator "Tanpa Nota/Dengan Nota", dan tombol "Lunas" berwarna hijau.

### 3. Dashboard Header & Search
- Memperbarui `lib/features/dashboard/dashboard_screen.dart`:
    - Menambahkan Search Bar yang lebih modern dengan bayangan halus.
    - Menambahkan Dropdown Profil di pojok kanan atas.
    - Memberikan efek gradien latar belakang pada `MainShell` (di `DashboardScreen` atau layout utama).

### 4. Kartu Ringkasan (Summary Cards)
- Memperbarui `lib/features/dashboard/widgets/summary_card.dart`:
    - Menambahkan efek hover (mengangkat saat kursor di atasnya).
    - Memperbarui sudut membulat menjadi `24`.
    - Menambahkan dukungan untuk gradien warna pada kartu yang aktif.

### 5. Visualisasi Grafik
- Memperbarui `lib/features/dashboard/widgets/charts_section.dart`:
    - Menggunakan implementasi `ModernBarChart` yang memiliki batang (bar) lebih halus dan berwarna sesuai kategori.

## Verification Plan

### Manual Verification
- Memastikan tampilan di web ([https://keuangan-pribadi-4d8ae.web.app](https://keuangan-pribadi-4d8ae.web.app)) berubah total mengikuti gaya Data Konstruksi.
- Memastikan efek hover dan expand pada sidebar berfungsi dengan lancar.
- Memverifikasi keterbacaan font `Plus Jakarta Sans`.
