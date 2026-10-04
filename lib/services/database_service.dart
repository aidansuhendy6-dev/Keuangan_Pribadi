import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../models/wallet_model.dart';
import '../models/saving_model.dart';
import '../models/deposit_model.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';
import '../models/recurring_bill_model.dart';
import '../models/koko_bill_model.dart';
import '../models/monthly_history_model.dart';
import '../models/custom_monthly_finance_model.dart';

class DatabaseService {
  final _supabase = Supabase.instance.client;

  Future<List<MonthlyHistory>> getMonthlyHistory() async {
    final response = await _supabase.from('monthly_history').select().order('year').order('month');
    return (response as List).map((json) => MonthlyHistory.fromJson(json)).toList();
  }

  Future<void> upsertMonthlyHistory(MonthlyHistory history) async {
    await _supabase.from('monthly_history').upsert(
      history.toJson(),
      onConflict: 'month, year',
    );
  }

  Future<List<Wallet>> getWallets() async {
    final response = await _supabase.from('wallets').select();
    return (response as List).map((json) => Wallet.fromJson(json)).toList();
  }

  Future<List<Saving>> getSavings() async {
    final response = await _supabase.from('savings').select();
    return (response as List).map((json) => Saving.fromJson(json)).toList();
  }

  Future<List<Deposit>> getDeposits() async {
    final response = await _supabase.from('deposits').select();
    return (response as List).map((json) => Deposit.fromJson(json)).toList();
  }

  Future<List<Debt>> getDebts() async {
    final response = await _supabase.from('debts').select();
    return (response as List).map((json) => Debt.fromJson(json)).toList();
  }

  Future<List<RecurringBill>> getRecurringBills() async {
    final response = await _supabase.from('recurring_bills').select();
    return (response as List).map((json) => RecurringBill.fromJson(json)).toList();
  }

  Future<List<Transaction>> getTransactions() async {
    final response = await _supabase.from('transactions').select().order('date', ascending: false);
    return (response as List).map((json) => Transaction.fromJson(json)).toList();
  }

  Future<void> insertTransaction(Map<String, dynamic> data) async {
    await _supabase.from('transactions').insert(data);
  }

  Future<void> insertDeposit(Map<String, dynamic> data) async {
    await _supabase.from('deposits').insert(data);
  }

  Future<void> insertDebt(Map<String, dynamic> data) async {
    await _supabase.from('debts').insert(data);
  }

  Future<void> insertRecurringBill(Map<String, dynamic> data) async {
    await _supabase.from('recurring_bills').insert(data);
  }

  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _supabase.from('transactions').update(data).eq('id', id);
  }

  Future<void> deleteTransaction(String id) async {
    await _supabase.from('transactions').delete().eq('id', id);
  }

  Future<void> deleteDebt(String id) async {
    await _supabase.from('debts').delete().eq('id', id);
  }

  Future<void> deleteRecurringBill(String id) async {
    await _supabase.from('recurring_bills').delete().eq('id', id);
  }

  Future<void> updateWalletBalance(String id, double balance) async {
    await _supabase.from('wallets').update({'balance': balance}).eq('id', id);
  }

  Future<void> updateSavingBalance(String id, double balance) async {
    await _supabase.from('savings').update({'current_amount': balance}).eq('id', id);
  }

  Future<void> updateDepositBalance(String id, double balance) async {
    await _supabase.from('deposits').update({'amount': balance}).eq('id', id);
  }

  Future<void> updateDebtRemainingAmount(String id, double remainingAmount) async {
    await _supabase.from('debts').update({'remaining_amount': remainingAmount}).eq('id', id);
  }

  Future<void> updateDebt(String id, Map<String, dynamic> data) async {
    await _supabase.from('debts').update(data).eq('id', id);
  }

  Future<void> updateRecurringBill(String id, Map<String, dynamic> data) async {
    await _supabase.from('recurring_bills').update(data).eq('id', id);
  }

  // =========================================================
  // KOKO BILLING METHODS
  // =========================================================

  Future<KokoBillingPeriod?> getLatestKokoPeriod() async {
    final rows = await _supabase.from('koko_billing_periods').select().order('created_at', ascending: false).limit(1);
    if (rows.isEmpty) return null;
    return KokoBillingPeriod.fromMap(Map<String, dynamic>.from(rows.first));
  }

  Future<void> upsertKokoPeriod(KokoBillingPeriod period) async {
    await _supabase.from('koko_billing_periods').upsert(period.toMap());
  }

  Future<List<KokoBillEntry>> getKokoEntries(String table, String periodId) async {
    final rows = await _supabase.from(table).select().eq('period_id', periodId);
    return (rows as List).map((e) => KokoBillEntry.fromMap(Map<String, dynamic>.from(e))).toList();
  }

  Future<void> upsertKokoEntry(String table, KokoBillEntry entry) async {
    if (entry.id != null && entry.id!.length > 10) {
      await _supabase.from(table).update(entry.toMap()).eq('id', entry.id!);
    } else {
      await _supabase.from(table).insert(entry.toMap());
    }
  }

  Future<void> deleteKokoEntry(String table, String id) => _supabase.from(table).delete().eq('id', id);

  Future<void> clearKokoEntries(String table, String periodId) async {
    await _supabase.from(table).delete().eq('period_id', periodId);
  }

  Future<String?> uploadKokoReceipt(String bucket, Uint8List bytes) async {
    final fileName = 'receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
          );
      return _supabase.storage.from(bucket).getPublicUrl(fileName);
    } catch (e) {
      rethrow;
    }
  }

  // =========================================================
  // CUSTOM MONTHLY FINANCE METHODS
  // =========================================================

  Future<List<CustomMonthlyFinance>> getCustomMonthlyFinance() async {
    final response = await _supabase.from('custom_monthly_finance').select();
    return (response as List).map((json) => CustomMonthlyFinance.fromJson(json)).toList();
  }

  Future<void> upsertCustomMonthlyFinance(CustomMonthlyFinance data) async {
    await _supabase.from('custom_monthly_finance').upsert(
      data.toJson(),
      onConflict: 'month_key',
    );
  }
}
