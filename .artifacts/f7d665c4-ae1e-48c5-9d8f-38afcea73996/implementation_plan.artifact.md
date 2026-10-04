# Implementation Plan: Settlement and Editing for Debts & Piutang

This plan introduces a more interactive way to manage debts and piutang (accounts receivable) by adding "Mark as Paid" (Lunas) and "Edit" functionalities directly in the lists.

## Proposed Changes

### [FinanceProvider](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/services/finance_provider.dart)
- [MODIFY] Add `settleDebt(Debt debt, {String? walletId})` to process payment for a paylater debt.
- [MODIFY] Add `settleDebtInstallment(RecurringBill bill, {String? walletId})` to process one installment payment.
- [MODIFY] Add `settlePiutang(Debt debt, {String? walletId})` to process receiving payment for a paylater piutang.
- [MODIFY] Add `settlePiutangInstallment(RecurringBill bill, {String? walletId})` to process receiving one installment payment.
- [MODIFY] Add update methods for `Debt` and `RecurringBill` to support editing.

### [Deposit & Debt Dialogs]
- [MODIFY] [AddDepositTransactionDialog](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/deposits/widgets/add_deposit_transaction_dialog.dart): Update to support editing an existing `Debt` or `RecurringBill`.
- [MODIFY] [AddDebtDialog](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/debts/widgets/add_debt_dialog.dart): Update to support editing an existing `Debt` or `RecurringBill`.

### [UI Components]
- [MODIFY] [DepositTransactionList](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/deposits/widgets/deposit_transaction_list.dart):
    - Replace the single delete icon with a row of three small circular icons:
        - **Green Checkmark**: Settle (Lunas).
        - **Blue Pen**: Edit.
        - **Red Trash**: Delete.
- [MODIFY] [DebtBillList](file:///C:/Users/aidan/StudioProjects/Keuangan_Pribadi/lib/features/debts/widgets/debt_bill_list.dart):
    - Add the same three icons as above.

## Logic Details

### Mark as Paid (Lunas)
- **Piutang (Income)**:
    - Default Wallet: BCA.
    - Action: `wallet.balance += amount`, `recordTransaction(type: 'income')`, then delete item (paylater) or `tenor++` (installment).
- **Hutang (Expense)**:
    - Default Wallet: BCA.
    - Action: `wallet.balance -= amount`, `recordTransaction(type: 'expense')`, then delete item (paylater) or `tenor++` (installment).

## Verification Plan

### Manual Verification
1. Open **Daftar Piutang**.
2. Tap the **Green Checkmark** on a piutang item. Verify that BCA balance increases and the item is either removed (paylater) or tenor increases (installment).
3. Tap the **Blue Pen** on a piutang item. Verify the dialog opens with pre-filled data, and saving updates the item.
4. Tap the **Red Trash** and verify the item is deleted.
5. Repeat the same steps for **Daftar Hutang**.
