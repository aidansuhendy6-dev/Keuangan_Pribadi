# Walkthrough: Dashboard Keuangan Pribadi (Apple Style)

Dashboard utama telah berhasil dibangun dengan fokus pada estetika Apple macOS yang elegan, modern, dan mewah.

## Fitur yang Diimplementasikan

### 1. Sidebar Navigasi (macOS Style)
Sidebar di sisi kiri menyediakan navigasi cepat dan ringkasan kekayaan bersih (Net Worth).
- **Profil User:** Menampilkan nama "Aidan Suhendy".
- **Menu Navigasi:** Dashboard, Dompet, Tabungan, Deposit, dan Hutang dengan ikon minimalis.
- **Net Worth Card:** Ringkasan saldo dikurangi hutang dengan indikator persentase dari bulan lalu.

### 2. Ringkasan Keuangan (Summary Cards)
Empat kartu utama di bagian atas untuk memantau angka-angka krusial:
- **Total Saldo:** (Biru Apple)
- **Total Hutang:** (Merah Aksen)
- **Total Pemasukan:** (Hijau)
- **Total Pengeluaran:** (Merah)

### 3. Visualisasi Grafik (Interactive Charts)
Menggunakan library `fl_chart` untuk tampilan data yang dinamis:
- **Bar Chart:** Visualisasi saldo bulanan dengan highlight pada bulan berjalan.
- **Line Chart:** Perbandingan trend Pemasukan (Hijau) vs Pengeluaran (Merah) dengan area gradien di bawah garis.

### 4. Daftar Transaksi Terakhir
Menampilkan data historis dalam format yang bersih:
- **Tagihan Rutin:** Dilengkapi dengan tag status (misal: "5 hari lagi", "Lunas").
- **Pemasukan & Pengeluaran:** Ringkasan 3 transaksi terakhir dengan pewarnaan angka yang jelas.

## Detail Teknis
- **UI Framework:** Flutter (Web Desktop prioritized).
- **Backend:** Supabase (Initialized).
- **Typography:** Google Fonts - Inter (San Francisco alternative).
- **Architecture:** Feature-based folder structure (`features/dashboard/widgets`).

> [!TIP]
> Semua data saat ini masih bersifat statis (dummy) untuk kebutuhan layouting. Langkah selanjutnya adalah menghubungkan widget-widget ini dengan Database Supabase agar data bersifat *real-time*.

## Progres Terbaru: Deployment Online

Aplikasi sekarang sudah bisa diakses secara publik melalui internet.
- **Hosting URL:** [https://keuangan-pribadi-4d8ae.web.app](https://keuangan-pribadi-4d8ae.web.app)
- **Firebase Project:** `keuangan-pribadi-4d8ae`
- **Akun:** `aidansuhendy6@gmail.com`

### Apa yang Bisa Dilihat Sekarang?
- Seluruh layout Dashboard yang elegan (Apple Style).
- Sidebar dengan sub-menu yang bisa di-expand (BCA, Cash, dll).
- Grafik interaktif untuk saldo dan arus kas.
- Daftar transaksi dan tagihan dengan desain modern.

### Perbaikan Teknis Selama Deployment
- Memperbaiki error `AppTheme` yang tidak terdefinisi di `main.dart`.
- Memperbaiki ketidakcocokan tipe data `CardTheme` menjadi `CardThemeData` agar sesuai dengan versi Flutter terbaru.
