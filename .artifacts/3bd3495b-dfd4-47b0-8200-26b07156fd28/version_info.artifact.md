# Versi Terbaik 1 (4 September 2026)

Status: **Stabil & Terverifikasi**

## Fitur Utama & Perubahan

### 1. Navigasi & Sidebar (Desktop)
- Menampilkan total saldo untuk setiap kategori menu (Dompet, Tabungan, Deposit, Hutang).
- Indikator **Dana vs Tagihan** dengan nominal real-time dan pewarnaan dinamis (Merah jika minus, Hijau jika surplus).
- Kartu **Tagihan Koko** yang lebih ringkas (hanya Rentang Waktu & Total) untuk menghemat ruang.
- Penambahan fitur Logout tetap tersedia di Sidebar.

### 2. Mobile Drawer
- Area header hijau diperpendek agar menu lebih lega.
- Re-order menu: Dashboard -> Dompet -> Tabungan -> Deposit -> Hutang -> Tagihan Koko -> Dana vs Tagihan -> Riwayat.
- Setiap menu memiliki subtitle nominal saldo/tagihan.
- Tombol **Logout dihapus** (mengandalkan fitur auto-logout aplikasi).
- Indikator **Dana vs Tagihan** dengan pewarnaan dinamis.

### 3. Manajemen Dompet
- Fitur **Edit Nominal Manual** pada kartu BCA, Cash, dan ShopeePay.
- Icon pena di pojok kiri atas kartu untuk sinkronisasi saldo tanpa menambah catatan transaksi.

### 4. Logic & State (FinanceProvider)
- Implementasi getter untuk total saldo kategori.
- Logic proyeksi Dana vs Tagihan untuk bulan berjalan.
- Fungsi `manualUpdateWalletBalance` untuk pembaruan saldo langsung ke database.

## File Terkait
- [finance_provider.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/services/finance_provider.dart)
- [sidebar.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/dashboard/widgets/sidebar.dart)
- [mobile_drawer.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/dashboard/widgets/mobile_drawer.dart)
- [tagihan_koko_sidebar.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/dashboard/widgets/tagihan_koko_sidebar.dart)
- [wallet_screen.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/wallets/wallet_screen.dart)
- [wallet_card.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/wallets/widgets/wallet_card.dart)
