# Rencana Implementasi Apple iOS Style Menu Selector

Rencana ini bertujuan untuk mengganti `DropdownButtonFormField` standar dengan custom UI yang menyerupai popup menu Apple iOS (clean, rounded, dengan indikator checkmark).

## Perubahan yang Diusulkan

### [Component] Core Widgets

Membuat widget reusable baru untuk menggantikan dropdown konvensional.

#### [NEW] [apple_menu_selector.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/core/widgets/apple_menu_selector.dart)
- Widget `AppleMenuSelector<T>` (Stateless):
  - **Trigger Field**: Menggunakan `InkWell` dengan desain field yang sudah ada (abu-abu muda, radius 16).
  - **Menu Popup**: Menggunakan `showMenu` dengan styling kustom:
    - `shape`: `RoundedRectangleBorder` dengan radius `20`.
    - `elevation`: Halus dengan bayangan minimal.
    - **Items**: Setiap item menampilkan teks dan ikon `Icons.check` di sebelah kiri jika item tersebut sedang dipilih (sesuai gambar referensi).
    - **Separator**: Garis pembatas halus antar item.

### [Component] Fitur & Dialog Terkait

Mengintegrasikan `AppleMenuSelector` ke semua dialog input.

#### [MODIFY] [add_transaction_dialog.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/transactions/widgets/add_transaction_dialog.dart)
- Ganti dropdown "Dompet Tujuan" / "Sumber Dana".

#### [MODIFY] [add_debt_dialog.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/debts/widgets/add_debt_dialog.dart)
- Ganti dropdown "Pilih Kartu".

#### [MODIFY] [add_deposit_transaction_dialog.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/deposits/widgets/add_deposit_transaction_dialog.dart)
- Ganti dropdown "Pilih Kartu".

#### [MODIFY] [saving_transfer_dialog.dart](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/savings/widgets/saving_transfer_dialog.dart)
- Ganti dropdown "Sumber Dana" dan "Tabungan Tujuan".

## Verifikasi Plan

### Visual & Interaksi
1. **Pengecekan Checkmark**: Saat menu dibuka, pastikan item yang sedang aktif memiliki tanda centang di sebelah kirinya.
2. **Posisi Menu**: Menu harus muncul tepat di bawah atau di atas field trigger (otomatis ditangani oleh `showMenu`).
3. **Corner Radius**: Pastikan menu memiliki sudut membulat yang konsisten dengan dialog.

### Fungsionalitas
1. Pastikan pemilihan item melalui menu baru tetap memperbarui state di dialog (misal: merubah `_selectedCategoryId`).
2. Pastikan validator (wajib pilih) tetap bekerja (akan menggunakan variabel state lokal sebagai pengganti `validator` bawaan dropdown).
