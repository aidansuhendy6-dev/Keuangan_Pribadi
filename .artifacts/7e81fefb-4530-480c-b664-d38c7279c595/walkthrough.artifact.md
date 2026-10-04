# Walkthrough - Detail Breakdown Dana vs Tagihan

Saya telah menambahkan fitur detail breakdown dan pemilih bulan pada halaman **Dana vs Tagihan** untuk memberikan transparansi penuh terhadap angka-angka yang muncul di chart.

## Perubahan Utama

1.  **Detail Card (Breakdown)**:
    *   Menampilkan rincian sumber **Dana**: BCA, Cash, ShopeePay, Tagihan Koko, dan Deposit.
    *   Menampilkan rincian sumber **Tagihan**: Kartu Kredit BCA, Spaylater, dan Hutang Lainnya.
    *   Data ini bersifat dinamis sesuai bulan yang dipilih.

2.  **Pemilih Bulan Interaktif**:
    *   Teks bulan di pojok kanan atas kartu detail (misal: "Agustus 2026") sekarang dapat diklik.
    *   Muncul pilihan 12 bulan proyeksi (sama dengan yang ada di chart).
    *   Memilih bulan akan memperbarui seluruh rincian angka di kartu tersebut secara real-time.

3.  **Logika Dana Dinamis**:
    *   Saldo dompet (BCA, Cash, ShopeePay) **hanya muncul** jika Anda melihat bulan berjalan (Agustus 2026).
    *   Untuk bulan-bulan proyeksi mendatang, Dana hanya akan menghitung proyeksi Piutang ([KOKO] & [DEP]).

4.  **Auto-Sliding Chart**:
    *   Chart akan selalu dimulai dari bulan saat ini (`DateTime.now()`). Ketika bulan berganti (misal ke September), September akan otomatis menjadi batang pertama, dan bulan masa depan akan muncul di ujung kanan.

## Cara Verifikasi
1.  Buka halaman **Dana vs Tagihan**.
2.  Lihat bagian bawah chart, sekarang ada dua kolom.
3.  Di kolom kiri, klik teks **"Agustus 2026"**.
4.  Pilih bulan **"September 2026"** dari daftar yang muncul.
5.  Perhatikan bahwa saldo BCA, Cash, dan Shopeepay akan menjadi Rp 0 (karena saldo dompet hanya dihitung di bulan berjalan), sementara Tagihan Koko/Deposit dan Hutang tetap muncul sesuai jadwal jatuh temponya.

> [!TIP]
> Logika ini memastikan Anda tahu persis "Uang saya di bulan X berasal dari mana saja dan untuk bayar apa saja".
