# Walkthrough - Pembaruan Grafik Saldo vs Hutang

Saya telah memperbarui grafik **Saldo vs Hutang** di Dashboard untuk memberikan informasi selisih dana dan keterbacaan yang lebih baik.

## Perubahan Utama

1.  **Pemberian Jarak Antar Batang**:
    *   Menambahkan jarak (space) antara batang **Saldo** (hijau) dan **Hutang** (merah) agar data lebih mudah dibedakan secara visual.

2.  **Informasi Selisih Dana**:
    *   Menambahkan baris baru di bawah label tahun pada sumbu X.
    *   **Rumus**: `Saldo - Hutang`.
    *   **Indikator Warna**:
        *   Teks berwarna **Merah** jika selisih negatif (Hutang > Saldo).
        *   Teks berwarna **Hijau** jika selisih nol atau positif (Saldo >= Hutang).
    *   Format nilai menggunakan singkatan ringkas (misal: `-4,1 jt`).

3.  **Perbaikan Label Nilai**:
    *   Label di atas batang sekarang menggunakan format ringkas (misal: `33,3 jt`) alih-alih angka penuh yang panjang, sesuai dengan permintaan visual pada screenshot.

4.  **Countdown Jatuh Tempo (Dashboard)**:
    *   Menambahkan teks "X Hari lagi" berwarna **Merah** di bawah keterangan tanggal jatuh tempo pada daftar tagihan.
    *   Informasi ini dihitung secara dinamis berdasarkan selisih hari dari tanggal hari ini.
    *   Membantu Anda melihat urgensi penagihan piutang atau pembayaran hutang secara langsung.

## File yang Diubah

*   [balance_vs_debt_chart.dart](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/features/dashboard/widgets/balance_vs_debt_chart.dart) [MODIFY]
*   [transaction_lists.dart](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/features/dashboard/widgets/transaction_lists.dart) [MODIFY]

## Hasil Implementasi

> [!TIP]
> Dengan informasi selisih di bawah grafik, Anda dapat langsung mengetahui kondisi kesehatan keuangan Anda setiap bulannya (apakah surplus atau defisit) tanpa perlu menghitung manual.

render_diffs(file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/features/dashboard/widgets/balance_vs_debt_chart.dart)
