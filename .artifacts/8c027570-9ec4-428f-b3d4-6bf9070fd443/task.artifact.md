# Daftar Tugas: Keuangan Pribadi (Apple Style)

- `[/]` **Fase 1: Inisialisasi & Setup**
    - `[ ]` Update `pubspec.yaml` dengan dependensi yang diperlukan.
    - `[ ]` Buat struktur folder proyek (`core`, `features`, `models`, `services`).
    - `[ ]` Inisialisasi Supabase di `lib/main.dart`.
    - `[ ]` Konfigurasi Tema Aplikasi (Apple Design System).

- `[ ]` **Fase 2: Layout Dasar Dashboard (Desktop)**
    - `[ ]` Implementasi Sidebar macOS style.
    - `[ ]` Implementasi Top Bar (Tanggal & User Profile).
    - `[ ]` Buat widget "Summary Card" (Total Saldo, dll).

- `[ ]` **Fase 3: Visualisasi Data (Charts)**
    - `[ ]` Implementasi Grafik Batang (Saldo Bulanan).
    - `[ ]` Implementasi Grafik Garis (Pemasukan vs Pengeluaran).

- `[ ]` **Fase 4: Manajemen Transaksi**
    - `[ ]` Implementasi Daftar Transaksi Terakhir.
    - `[ ]` Integrasi data dummy ke UI (sebelum koneksi DB penuh).

- `[/]` **Fase 5: Integrasi Supabase Backend**
    - `[x]` Siapkan Skema Database (SQL Script).
    - `[x]` Buat Dart Models (`Wallet`, `Saving`, `Deposit`, `Debt`, `Transaction`).
    - `[x]` Buat `DatabaseService` untuk CRUD data.
    - `[ ]` Implementasi State Management (Provider) untuk sinkronisasi data.

- `[x]` **Fase 6: Pembaruan Sidebar & Sub-menu**
    - `[x]` Refactor `Sidebar` widget untuk mendukung sub-item (Expandable).
    - `[x]` Tambahkan data dummy untuk sub-menu sesuai referensi gambar.

- `[x]` **Fase 7: Hosting ke Firebase**
    - `[x]` Logout akun lama & Login akun `aidansuhendy6@gmail.com`.
    - `[x]` Jalankan `flutter build web --release`.
    - `[x]` Inisialisasi Firebase Hosting (`firebase init`).
    - `[x]` Deploy ke Firebase Hosting (`firebase deploy`).
