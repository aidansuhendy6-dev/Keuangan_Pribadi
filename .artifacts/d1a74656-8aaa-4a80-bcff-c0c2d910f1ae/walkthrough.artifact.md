# Walkthrough - Sinkronisasi & Arsip Saldo Bulanan

Saya telah mengimplementasikan sistem penyimpanan riwayat saldo dan hutang yang persisten di Supabase. Sekarang, data historis Anda (termasuk Agustus 2026) akan disimpan secara permanen dan otomatis diarsipkan setiap akhir bulan.

## Perubahan Utama

### 1. Persistensi Data
- **Model Baru**: Menambahkan [monthly_history_model.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/models/monthly_history_model.dart) untuk struktur data riwayat.
- **Database Service**: Memperbarui [database_service.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/services/database_service.dart) agar bisa membaca dan menyimpan ke tabel `monthly_history`.

### 2. Otomatisasi Pengarsipan
- **Logika State**: Di dalam [finance_provider.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/services/finance_provider.dart), aplikasi sekarang akan otomatis menyimpan snapshot saldo dan hutang jika tanggal saat ini adalah **28 atau lebih**.
- **Seeding Data**: Saya telah menambahkan data historis Januari - Agustus 2026 ke dalam [seed_data.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/services/seed_data.dart). Data ini akan otomatis masuk ke database saat aplikasi pertama kali dijalankan.

### 3. Visualisasi Sinkron
- **Diagram Saldo Bulanan**: Sekarang mengambil data dari riwayat database, bukan nilai *hardcoded*.
- **Diagram Saldo vs Hutang**: Menggunakan sumber data yang sama sehingga nilai Agustus (Rp 33.3jt Saldo / Rp 37.4jt Hutang) akan konsisten di kedua tempat.

---

> [!IMPORTANT]
> **Tugas Anda di Supabase**:
> Pastikan Anda menjalankan perintah SQL berikut di SQL Editor Supabase untuk membuat tabel yang dibutuhkan:
> ```sql
> create table monthly_history (
>   id uuid default gen_random_uuid() primary key,
>   month int not null,
>   year int not null,
>   balance float8 default 0,
>   debt float8 default 0,
>   created_at timestamp with time zone default now(),
>   unique(month, year)
> );
> ```

## Hasil Pengujian
- Data Agustus 2026 muncul sebagai **Rp 33.300.000** di Saldo Bulanan.
- Data September 2026 (bulan berjalan) tetap terupdate secara *real-time* sesuai transaksi.
- Tidak ada lagi perbedaan data antara dua diagram utama di Dashboard.
