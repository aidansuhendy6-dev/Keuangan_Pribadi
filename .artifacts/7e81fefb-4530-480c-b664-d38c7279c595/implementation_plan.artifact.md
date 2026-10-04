# Implementasi Legenda Detail Dana vs Tagihan

Menambahkan bagian detail breakdown sumber dana dan hutang di bawah chart, serta fitur pemilihan bulan proyeksi.

## Proposed Changes

### Dashboard Feature

#### [MODIFY] [dana_vs_tagihan_screen.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/dashboard/dana_vs_tagihan_screen.dart)
- Mengubah `DanaVsTagihanScreen` menjadi `StatefulWidget` untuk mengelola `selectedMonthIndex`.
- Menambahkan layout dua kolom di bagian bawah:
    - **Kolom Kiri**: Detail Breakdown (Dana & Tagihan) dengan pemilih bulan.
    - **Kolom Kanan**: Informasi Logika Perhitungan.
- Mengimplementasikan logika perhitungan detail per item (BCA, Shopeepay, Tagihan Koko, dll) berdasarkan bulan yang dipilih.
- Menambahkan interaksi klik pada teks bulan untuk memunculkan menu pilihan bulan (12 bulan proyeksi).

#### [MODIFY] [dana_vs_tagihan_chart.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/dashboard/widgets/dana_vs_tagihan_chart.dart)
- Memastikan chart selalu mulai dari bulan berjalan (`DateTime.now()`) agar otomatis "sliding" setiap bulan berganti.
- (Opsional) Sinkronisasi dengan `selectedMonthIndex` jika diinginkan highlight pada chart (tapi permintaan user fokus pada card detail).

## Verification Plan

### Automated Tests
- Menjalankan aplikasi dan memverifikasi angka pada card detail untuk bulan Agustus 2026.
- Memastikan saldo dompet (BCA, Cash, Shopeepay) hanya muncul jika memilih bulan berjalan (Index 0).
- Memastikan angka Piutang ([KOKO], [DEP]) muncul di bulan mendatang.

### Manual Verification
- Klik pada teks bulan (misal "Agustus 2026") dan pilih bulan lain (misal "September 2026").
- Pastikan data Dana dan Tagihan di card detail berubah sesuai bulan yang dipilih.
- Verifikasi visual layout agar sesuai dengan referensi gambar (2 kolom di bawah).
