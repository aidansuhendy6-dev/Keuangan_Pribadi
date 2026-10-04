# Rencana Refaktor Deposit menjadi Piutang (Accounts Receivable)

User ingin merombak fitur **Deposit** agar berfungsi sebagai sistem **Piutang**. Uang di Deposit adalah uang orang lain yang dipinjam dari user dan harus ditagih (baik secara sekaligus/Paylater maupun Cicilan).

## User Review Required

> [!IMPORTANT]
> - **Logika Piutang**: Semua item di Deposit akan dianggap sebagai aset (piutang) yang memiliki tenor atau jatuh tempo.
> - **Skema Penyimpanan**: Saya akan menggunakan sistem prefix pada tabel `debts` dan `recurring_bills` untuk membedakan Hutang dan Piutang:
>     - `[KOKO]` untuk Tagihan Koko
>     - `[DEP]` untuk Deposit
>     - `[BNS]` untuk Bonus
> - **Perubahan Total Saldo**: Saldo Deposit di Dashboard akan dihitung secara dinamis dari total sisa piutang (Paylater + Sisa Cicilan) pada masing-masing kategori.
> - **Dialog Baru**: Dialog tambah data akan memiliki opsi Tipe (Paylater/Cicilan) dan Tenor, persis seperti menu Hutang.

## Proposed Changes

### Core Logic & Service

#### [MODIFY] [finance_provider.dart](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/services/finance_provider.dart)
- Mendefinisikan getter dinamis untuk saldo piutang: `kokoPiutangBalance`, `depPiutangBalance`, `bonusPiutangBalance`.
- Memperbarui `totalBalance` agar menggunakan saldo piutang dinamis ini alih-alih nilai statis di tabel `deposits`.
- Menambahkan metode `addPiutangItem` dan `addPiutangInstallmentItem` yang menyisipkan data dengan prefix yang sesuai.

### Features: Deposit

#### [MODIFY] [deposit_screen.dart](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/features/deposits/deposit_screen.dart)
- Mengubah cara pengambilan data untuk setiap kolom. Alih-alih `transactions`, sekarang akan mengambil `debts` dan `recurringBills` yang difilter berdasarkan prefix.
- Memastikan `bonusTxs` tetap menggunakan pengurutan natural (A-Z, 1-9) pada daftar piutangnya.

#### [MODIFY] [deposit_transaction_list.dart](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/features/deposits/widgets/deposit_transaction_list.dart)
- Mengubah tipe data yang diterima dari `List<Transaction>` menjadi `List<dynamic>` (bisa `Debt` atau `RecurringBill`).
- Menambahkan UI **Progress Bar** dan informasi **Tenor** untuk item tipe cicilan (mirip UI Hutang BCA).

#### [MODIFY] [add_deposit_transaction_dialog.dart](file:///C:/Users/aidan/StudioProjects/keuangan_pribadi/lib/features/deposits/widgets/add_deposit_transaction_dialog.dart)
- Merombak total UI agar mendukung input:
    - Keterangan Piutang
    - Dropdown Kartu (Koko, Deposit, Bonus)
    - Toggle Tipe (Paylater / Cicilan)
    - Input Tenor & Cicilan Ke (jika Cicilan)
    - Tanggal Transaksi & Jatuh Tempo
    - Nominal (Bulanan jika cicilan, Total jika paylater)

## Verification Plan

### Manual Verification
1. **Tambah Piutang Cicilan**: Buka menu Deposit, klik tambah, pilih "Tagihan Koko", tipe "Cicilan", tenor 12, cicilan ke 1. Cek apakah muncul progress bar `1/12`.
2. **Tambah Piutang Paylater**: Tambah ke "Deposit", tipe "Paylater". Cek apakah muncul sebagai list biasa tanpa progress bar.
3. **Cek Saldo Dashboard**: Pastikan saldo di kartu "Total Saldo" dashboard mencakup total piutang yang baru ditambahkan.
4. **Cek Pengurutan Bonus**: Tambah beberapa piutang ke "Bonus" (misal: "B2", "B10", "A1") dan pastikan urutannya benar (A1, B2, B10).
5. **Cek Sumbu Y Grafik**: Pastikan grafik di dashboard tetap bekerja normal dengan nilai-nilai saldo baru ini.
