# Implement Delay for Supabase Updates in Tagihan Koko

Change the data synchronization behavior in the Tagihan Koko screen to only send updates to Supabase when the user finishes typing (e.g., by pressing Enter or when the input field loses focus), instead of updating on every character change. This will prevent frequent UI refreshes and improve performance.

## User Review Required

> [!IMPORTANT]
> The application will now only sync with the database when "Enter" is pressed or when you click outside the text field. Simply typing will not save the data until one of these actions occurs.

## Proposed Changes

### Tagihan Koko Screen

#### [MODIFY] [tagihan_koko_screen.dart](file:///C:/Users/aidan/Aplikasi/Keuangan_Pribadi/lib/features/dashboard/tagihan_koko_screen.dart)
- Update `_titleInputCell` to move `provider.updateKokoEntry` from `onChanged` to `onSubmitted`.
- Update `_amountInputCell` to move `provider.updateKokoEntry` from `onChanged` to `onSubmitted`.
- Add `FocusNode` management to both input cells to trigger the update when focus is lost (onBlur).
- Ensure amount formatting still happens in `onChanged` but without triggering the network update.
- Dispose of `FocusNode`s in the `dispose` method.

## Verification Plan

### Manual Verification
1. Navigate to "Tagihan Koko" page.
2. Type in the "Transaksi" (Transaction) column. Verify that the app does NOT refresh/flicker after every character.
3. Press "Enter". Verify that the data is saved (check console or verify total changes if any).
4. Click on another field or outside the field. Verify that the data is saved (check if total updates).
5. Repeat for the "Harga" (Price) column. Verify that formatting (dots) still works as you type, but saving only happens on Enter/Focus loss.
