# Walkthrough: Settlement and Editing for Debts & Piutang

I have implemented the ability to settle, edit, and delete debt and piutang items directly from their respective lists. This includes automatic transaction recording and wallet balance updates.

## Changes Made

### 1. Finance Provider Logic
- Added `settlePiutangItem`, `settlePiutangInstallment`, `settleDebtItem`, and `settleInstallmentItem`.
- These methods automatically update the **BCA** wallet balance and record a transaction (income or expense) before deleting the item or incrementing the tenor.
- Added update methods for all item types to support the editing flow.
- Added generic `removeDebt` and `removeRecurringBill` methods.

### 2. Enhanced Dialogs
- Updated `AddDepositTransactionDialog` and `AddDebtDialog` to accept an `initialItem`.
- When an item is passed, the dialog pre-fills all fields and changes the "Simpan" button behavior to perform an update instead of a new insertion.

### 3. Interactive UI
- Updated `DepositTransactionList` and `DebtBillList` to display three action icons:
    - **Green Checkmark**: Triggers the settlement logic.
    - **Blue Pen**: Opens the edit dialog.
    - **Red Trash**: Deletes the item without recording a transaction.
- Icons are styled to be subtle and consistent with the app's design language.

## Verification Results

### Logic Verification
- [x] Pelunasan Piutang -> BCA Balance increases, Income Transaction recorded, Item removed/tenor increased.
- [x] Pelunasan Hutang -> BCA Balance decreases, Expense Transaction recorded, Item removed/tenor increased.
- [x] Update Item -> Database updated correctly, UI refreshes immediately.

### UI Verification
- [x] Three icons appear correctly on both Piutang and Hutang lists.
- [x] Dialogs pre-fill correctly when the Pen icon is tapped.
- [x] Delete button works as expected.
