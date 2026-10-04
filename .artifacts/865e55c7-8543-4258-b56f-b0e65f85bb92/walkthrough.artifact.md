# Walkthrough - Perbaikan Sinkronisasi Data Tagihan Koko

Perubahan ini memperbaiki masalah performa di mana aplikasi melakukan refresh setiap kali satu huruf diketik pada halaman Tagihan Koko.

## Perubahan Utama

### 1. Tagihan Koko Screen
- **Penundaan Update**: Data transaksi dan harga sekarang hanya akan dikirim ke Supabase saat pengguna menekan **Enter** atau saat pindah ke kolom lain (**Focus Loss**).
- **FocusNode Management**: Menambahkan sistem pelacakan fokus untuk setiap baris transaksi agar data tetap tersimpan meskipun pengguna tidak menekan Enter (misalnya langsung klik tombol Add atau klik di luar tabel).
- **Real-time Formatting**: Pemformatan ribuan pada kolom harga tetap berjalan saat mengetik, namun tidak lagi memicu proses sinkronisasi database yang berat di setiap karakter.

## Komponen yang Dimodifikasi

- [tagihan_koko_screen.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/dashboard/tagihan_koko_screen.dart):
    - Implementasi `_titleFocusNodes` dan `_amountFocusNodes`.
    - Perubahan event handler dari `onChanged` ke `onSubmitted` dan listener FocusNode.

## Cara Verifikasi

1. Buka menu **Tagihan Koko**.
2. Coba ketik di kolom **Transaksi** atau **Harga**.
3. Perhatikan bahwa aplikasi tidak lagi berkedip atau melakukan refresh di setiap huruf.
4. Tekan **Enter** atau klik di kolom lain untuk memastikan data tersimpan (Total akan terupdate jika harga berubah).

> [!TIP]
> Perubahan ini secara signifikan akan membuat pengalaman mengetik menjadi lebih mulus terutama pada koneksi internet yang lambat.
