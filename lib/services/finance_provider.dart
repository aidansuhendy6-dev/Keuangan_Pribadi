import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'database_service.dart';
import '../models/wallet_model.dart';
import '../models/saving_model.dart';
import '../models/deposit_model.dart';
import '../models/debt_model.dart';
import '../models/transaction_model.dart';
import '../models/recurring_bill_model.dart';
import '../models/koko_bill_model.dart';
import '../models/monthly_history_model.dart';
import '../models/custom_monthly_finance_model.dart';
import 'seed_data.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseService _dbService = DatabaseService();

  List<Wallet> _wallets = [];
  List<Saving> _savings = [];
  List<Deposit> _deposits = [];
  List<Debt> _debts = [];
  List<RecurringBill> _recurringBills = [];
  List<Transaction> _transactions = [];
  List<MonthlyHistory> _monthlyHistory = [];
  List<CustomMonthlyFinance> _customFinanceList = [];
  bool _isLoading = false;

  // Koko Billing State
  KokoBillingPeriod? _activeKokoPeriod;
  List<KokoBillEntry> _whiteKostEntries = [];
  List<KokoBillEntry> _mykostEntries = [];

  List<Wallet> get wallets => _wallets;
  List<Saving> get savings => _savings;
  List<Deposit> get deposits => _deposits;
  List<Debt> get debts => _debts;
  List<RecurringBill> get recurringBills => _recurringBills;
  List<Transaction> get transactions => _transactions;
  List<MonthlyHistory> get monthlyHistory => _monthlyHistory;
  bool get isLoading => _isLoading;

  // Koko Getters
  KokoBillingPeriod? get activeKokoPeriod => _activeKokoPeriod;
  List<KokoBillEntry> get whiteKostEntries => _whiteKostEntries;
  List<KokoBillEntry> get mykostEntries => _mykostEntries;

  double get totalWhiteKost => _whiteKostEntries.fold(0, (s, e) => s + e.amount);
  double get totalMykost => _mykostEntries.fold(0, (s, e) => s + e.amount);
  double get grandTotalKoko => totalWhiteKost + totalMykost;
  
  double get roundedKokoBillTotal => (grandTotalKoko / 50000).ceil() * 50000.0;

  bool get isKokoPeriodDueThisMonth {
    if (_activeKokoPeriod == null) return false;
    try {
      final endDate = DateTime.parse(_activeKokoPeriod!.endDate);
      final now = DateTime.now();
      return endDate.year == now.year && endDate.month == now.month;
    } catch (_) {
      return false;
    }
  }

  double get totalBalance {
    return totalWalletBalance + totalSavingBalance + totalDepositBalance;
  }
  
  double get totalWalletBalance => _wallets.fold(0, (sum, item) => sum + item.balance);
  double get totalSavingBalance => _savings.fold(0, (sum, item) => sum + item.currentAmount);
  double get totalDepositBalance => kokoPiutangBalance + depPiutangBalance + bonusPiutangBalance;
  
  // Dynamic Piutang (Accounts Receivable) Calculations
  double get kokoPiutangBalance => _calculatePiutangByPrefix('[KOKO]') + roundedKokoBillTotal;
  double get depPiutangBalance => _calculatePiutangByPrefix('[DEP]');
  double get bonusPiutangBalance => _calculatePiutangByPrefix('[BNS]');

  double _calculatePiutangByPrefix(String prefix) {
    double paylater = _debts.where((d) => d.name.startsWith(prefix)).fold(0, (sum, d) => sum + d.remainingAmount);
    double installments = _recurringBills.where((b) => b.name.startsWith(prefix)).fold(0, (sum, b) => sum + b.remainingAmount);
    return paylater + installments;
  }

  // Dynamic Debt Calculations per Category
  double get bcaDebtBalance {
    double paylater = _debts.where((d) => d.name.startsWith('[BCA]')).fold(0, (sum, d) => sum + d.remainingAmount);
    double installments = _recurringBills.where((b) => b.name.startsWith('[BCA]')).fold(0, (sum, b) => sum + b.remainingAmount);
    return paylater + installments;
  }

  double get spaylaterDebtBalance {
    double paylater = _debts.where((d) => d.name.startsWith('[SP]')).fold(0, (sum, d) => sum + d.remainingAmount);
    double installments = _recurringBills.where((b) => b.name.startsWith('[SP]')).fold(0, (sum, b) => sum + b.remainingAmount);
    return paylater + installments;
  }

  double get otherDebtBalance {
    double paylater = _debts.where((d) => d.name.startsWith('[OT]')).fold(0, (sum, d) => sum + d.remainingAmount);
    double installments = _recurringBills.where((b) => b.name.startsWith('[OT]')).fold(0, (sum, b) => sum + b.remainingAmount);
    return paylater + installments;
  }

  double get totalDebt => bcaDebtBalance + spaylaterDebtBalance + otherDebtBalance;
  
  double get netWorth => totalBalance - totalDebt;

  // Dana vs Tagihan Logic (Current Month)
  double get currentMonthDana {
    double total = 0;
    // 1. Wallets (BCA, Cash, Shopeepay)
    for (var wallet in _wallets) {
      final name = wallet.name.toLowerCase();
      if (['bca', 'cash', 'shopeepay'].contains(name)) {
        total += wallet.balance;
      }
    }
    // 2. Piutang ([KOKO], [DEP])
    total += _calculateMonthlyAmount(DateTime.now(), ['[KOKO]', '[DEP]']);
    return total;
  }

  double get currentMonthTagihan {
    return _calculateMonthlyAmount(DateTime.now(), ['[BCA]', '[SP]', '[OT]']);
  }

  double get currentMonthDanaVsTagihanDiff => currentMonthDana - currentMonthTagihan;

  double _calculateMonthlyAmount(DateTime targetDate, List<String> prefixes) {
    double total = 0;
    final now = DateTime.now();
    final bool isCurrentMonth = targetDate.year == now.year && targetDate.month == now.month;

    if (prefixes.contains('[KOKO]')) {
      if (isKokoPeriodDueThisMonth) {
        total += roundedKokoBillTotal;
      }
    }

    for (var debt in _debts) {
      if (debt.dueDate != null &&
          debt.dueDate!.year == targetDate.year &&
          debt.dueDate!.month == targetDate.month) {
        if (prefixes.any((p) => debt.name.startsWith(p))) {
          if (debt.remainingAmount > 0) {
            total += debt.remainingAmount;
          }
        }
      }
    }

    for (var bill in _recurringBills) {
      if (prefixes.any((p) => bill.name.startsWith(p))) {
        if (bill.isInstallment && bill.startDate != null && bill.startTenor != null) {
          int monthsDiff = (targetDate.year - bill.startDate!.year) * 12 + (targetDate.month - bill.startDate!.month);
          int targetTenor = bill.startTenor! + monthsDiff;
          if (targetTenor >= 1 && targetTenor <= (bill.totalTenor ?? 0)) {
            if (isCurrentMonth) {
              if (bill.nextDueDate.month == now.month) {
                total += bill.amount;
              }
            } else {
              total += bill.amount;
            }
          }
        } else if (!bill.isInstallment) {
          if (isCurrentMonth) {
            if (bill.nextDueDate.month == now.month) {
              total += bill.amount;
            }
          } else {
            total += bill.amount;
          }
        }
      }
    }
    return total;
  }

  // Real-time Percentage Calculations
  double get incomePercentage => _calculatePercentageChange(
        _getFilteredAmountForMonth('income', DateTime.now()),
        _getFilteredAmountForMonth('income', DateTime.now().subtract(const Duration(days: 30))),
      );

  double get expensePercentage => _calculatePercentageChange(
        _getFilteredAmountForMonth('expense', DateTime.now()),
        _getFilteredAmountForMonth('expense', DateTime.now().subtract(const Duration(days: 30))),
      );

  double get netCashFlowPercentage {
    double currentNet = totalIncome - totalExpense;
    double prevIncome = _getFilteredAmountForMonth('income', DateTime.now().subtract(const Duration(days: 30)));
    double prevExpense = _getFilteredAmountForMonth('expense', DateTime.now().subtract(const Duration(days: 30)));
    double prevNet = prevIncome - prevExpense;
    return _calculatePercentageChange(currentNet, prevNet);
  }

  double get balancePercentage {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevHistory = _monthlyHistory.firstWhere(
      (h) => h.month == lastMonthDate.month && h.year == lastMonthDate.year,
      orElse: () => MonthlyHistory(month: 0, year: 0, balance: -1, debt: -1),
    );

    double lastMonthValue;
    if (prevHistory.balance != -1) {
      lastMonthValue = prevHistory.balance.toDouble();
    } else {
      double current = totalBalance;
      double thisMonthChange = _getNetChangeForMonth(_transactions, now);
      lastMonthValue = current - thisMonthChange;
    }
    return _calculatePercentageChange(totalBalance, lastMonthValue);
  }

  double get debtPercentage {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevHistory = _monthlyHistory.firstWhere(
      (h) => h.month == lastMonthDate.month && h.year == lastMonthDate.year,
      orElse: () => MonthlyHistory(month: 0, year: 0, balance: -1, debt: -1),
    );

    double lastMonthValue;
    if (prevHistory.debt != -1) {
      lastMonthValue = prevHistory.debt.toDouble();
    } else {
      double current = totalDebt;
      double thisMonthChange = _getDebtChangeForMonth(_transactions, now);
      lastMonthValue = current - thisMonthChange;
    }
    return _calculatePercentageChange(totalDebt, lastMonthValue);
  }

  double get netWorthPercentage {
    final now = DateTime.now();
    final lastMonthDate = DateTime(now.year, now.month - 1, 1);
    final prevHistory = _monthlyHistory.firstWhere(
      (h) => h.month == lastMonthDate.month && h.year == lastMonthDate.year,
      orElse: () => MonthlyHistory(month: 0, year: 0, balance: -1, debt: -1),
    );

    double lastMonthValue;
    if (prevHistory.balance != -1 && prevHistory.debt != -1) {
      lastMonthValue = prevHistory.balance.toDouble() - prevHistory.debt.toDouble();
    } else {
      double current = netWorth;
      double thisMonthChange = _getNetChangeForMonth(_transactions, now) - _getDebtChangeForMonth(_transactions, now);
      lastMonthValue = current - thisMonthChange;
    }
    return _calculatePercentageChange(netWorth, lastMonthValue);
  }

  double _getAmountForMonth(List<Transaction> txs, DateTime date) {
    return txs
        .where((t) => t.date.year == date.year && t.date.month == date.month)
        .fold(0, (sum, item) => sum + item.amount);
  }

  double _getNetChangeForMonth(List<Transaction> txs, DateTime date) {
    return txs.where((t) => t.date.year == date.year && t.date.month == date.month).fold(0, (sum, item) {
      if (item.type == 'income') return sum + item.amount;
      if (item.type == 'expense' && item.categoryType == 'wallet') return sum - item.amount;
      return sum;
    });
  }

  double _getDebtChangeForMonth(List<Transaction> txs, DateTime date) {
    return txs
        .where((t) => t.date.year == date.year && t.date.month == date.month && t.categoryType == 'debt')
        .fold(0, (sum, item) => sum + item.amount);
  }

  double _calculatePercentageChange(double current, double previous) {
    if (previous == 0) return current > 0 ? 100.0 : 0.0;
    return ((current - previous) / previous.abs()) * 100;
  }

  String formatPercentage(double value) {
    return "${value.abs().toStringAsFixed(1).replaceAll('.', ',')}%";
  }

  double _getFilteredAmountForMonth(String type, DateTime date) {
    return _transactions.where((t) {
      if (t.type != type) return false;
      if (t.date.year != date.year || t.date.month != date.month) return false;
      
      if (type == 'income') {
        // Hanya Pemasukan ke BCA, Shopeepay, Cash
        final wallet = _wallets.where((w) => w.id == t.categoryId).firstOrNull;
        return wallet != null && ['BCA', 'Shopeepay', 'Cash'].contains(wallet.name);
      } else {
        // Hanya Pengeluaran dari BCA, Shopeepay, Cash, atau Kartu Kredit BCA
        if (t.categoryType == 'wallet') {
          final wallet = _wallets.where((w) => w.id == t.categoryId).firstOrNull;
          return wallet != null && ['BCA', 'Shopeepay', 'Cash'].contains(wallet.name);
        } else if (t.categoryType == 'debt') {
          final debt = _debts.where((d) => d.id == t.categoryId).firstOrNull;
          return debt != null && debt.name == 'Kartu Kredit BCA';
        }
      }
      return false;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  double get totalIncome => _getFilteredAmountForMonth('income', DateTime.now());
  double get totalExpense => _getFilteredAmountForMonth('expense', DateTime.now());

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Ensure master data exists
      await SeedData.seedMissingCards(_dbService);
      await SeedData.seedMonthlyHistory(_dbService);
      await SeedData.seedCustomMonthlyFinance(_dbService);

      final results = await Future.wait([
        _dbService.getWallets(),
        _dbService.getSavings(),
        _dbService.getDeposits(),
        _dbService.getDebts(),
        _dbService.getRecurringBills(),
        _dbService.getTransactions(),
        _dbService.getLatestKokoPeriod(), 
        _dbService.getMonthlyHistory(),
        _dbService.getCustomMonthlyFinance(),
      ]);

      _wallets = results[0] as List<Wallet>;
      _savings = results[1] as List<Saving>;
      _deposits = results[2] as List<Deposit>;
      _debts = results[3] as List<Debt>;
      _recurringBills = results[4] as List<RecurringBill>;
      _transactions = results[5] as List<Transaction>;
      _activeKokoPeriod = results[6] as KokoBillingPeriod?;
      _monthlyHistory = results[7] as List<MonthlyHistory>;
      _customFinanceList = results[8] as List<CustomMonthlyFinance>;

      // Map loaded data into the internal cache
      _customMonthlyDetails.clear();
      for (var cf in _customFinanceList) {
        _customMonthlyDetails[cf.monthKey] = {
          'gaji_pokok': cf.gajiPokok,
          'tunjangan': cf.tunjangan,
          'bonus': cf.bonus,
          'lain_lain_sumber': cf.lainLainSumber,
          'belanja_istri': cf.belanjaIstri,
          'sewa_kost': cf.sewaKost,
          'konsumtif': cf.konsumtif,
          'lain_lain_dihabiskan': cf.lainLainDihabiskan,
        };
      }

      // Auto-archive monthly data if date >= 28
      await _checkAndArchiveMonthlyData();

      // Auto-Cleanup Finished Installments
      final finishedInstallments = _recurringBills.where((b) => b.isInstallment && b.remainingTenor == 0).toList();
      for (var bill in finishedInstallments) {
        await _dbService.deleteRecurringBill(bill.id);
      }
      if (finishedInstallments.isNotEmpty) {
        _recurringBills = await _dbService.getRecurringBills();
      }

      // Fetch Koko Entries if period exists
      if (_activeKokoPeriod != null && _activeKokoPeriod!.id != null) {
        final entries = await Future.wait([
          _dbService.getKokoEntries('koko_white_kost_35', _activeKokoPeriod!.id!),
          _dbService.getKokoEntries('koko_mykost_179', _activeKokoPeriod!.id!),
        ]);
        _whiteKostEntries = entries[0];
        _mykostEntries = entries[1];
        _sortKokoLists();
      } else {
        _whiteKostEntries = [];
        _mykostEntries = [];
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _checkAndArchiveMonthlyData() async {
    final now = DateTime.now();
    if (now.day >= 28) {
      final history = MonthlyHistory(
        month: now.month,
        year: now.year,
        balance: totalBalance,
        debt: totalDebt,
      );
      
      // Only archive if not already archived this month or values changed significantly
      final existing = _monthlyHistory.firstWhere(
        (h) => h.month == now.month && h.year == now.year,
        orElse: () => MonthlyHistory(month: 0, year: 0, balance: -1, debt: -1),
      );

      if (existing.balance != history.balance || existing.debt != history.debt) {
        await _dbService.upsertMonthlyHistory(history);
        _monthlyHistory = await _dbService.getMonthlyHistory();
        notifyListeners();
      }
    }
  }

  Future<void> addTransaction({
    required String type,
    required double amount,
    required String description,
    required String categoryType,
    required String categoryId,
    required DateTime date,
    String? incomeType,
    double? modal,
    double? jual,
  }) async {
    try {
      await _dbService.insertTransaction({
        'type': type,
        'amount': amount,
        'description': description,
        'category_type': categoryType,
        'category_id': categoryId,
        'date': date.toIso8601String(),
        'income_type': incomeType,
        'modal': modal,
        'jual': jual,
      });

      if (type == 'income') {
        // Pemasukan selalu ke Dompet
        final wallet = _wallets.firstWhere((w) => w.id == categoryId);
        await _dbService.updateWalletBalance(wallet.id, wallet.balance + amount);
      } else {
        // Pengeluaran bisa dari Dompet atau Hutang
        if (categoryType == 'wallet') {
          final wallet = _wallets.firstWhere((w) => w.id == categoryId);
          await _dbService.updateWalletBalance(wallet.id, wallet.balance - amount);
        } else if (categoryType == 'debt') {
          final debt = _debts.firstWhere((d) => d.id == categoryId);
          await _dbService.updateDebtRemainingAmount(debt.id, debt.remainingAmount + amount);
        }
      }

      await fetchData();
    } catch (e) {
      debugPrint('Error adding transaction: $e');
    }
  }

  Future<void> addSavingTransfer({
    required String type, // 'plus' (menabung) or 'minus' (mencairkan)
    required double amount,
    required String walletId,
    required String savingId,
    required DateTime date,
  }) async {
    try {
      final wallet = _wallets.firstWhere((w) => w.id == walletId);
      final saving = _savings.firstWhere((s) => s.id == savingId);

      if (type == 'plus') {
        // Menabung: Dompet berkurang, Tabungan bertambah
        await _dbService.updateWalletBalance(walletId, wallet.balance - amount);
        await _dbService.updateSavingBalance(savingId, saving.currentAmount + amount);
        
        await _dbService.insertTransaction({
          'type': 'expense',
          'amount': amount,
          'description': 'Menabung ke ${saving.name}',
          'category_type': 'wallet',
          'category_id': walletId,
          'date': date.toIso8601String(),
        });
        
        // Catat juga di sisi tabungan (sebagai info/income tabungan)
        await _dbService.insertTransaction({
          'type': 'income',
          'amount': amount,
          'description': 'Menabung dari ${wallet.name}',
          'category_type': 'saving',
          'category_id': savingId,
          'date': date.toIso8601String(),
        });
      } else {
        // Mencairkan: Tabungan berkurang, Dompet bertambah
        await _dbService.updateSavingBalance(savingId, saving.currentAmount - amount);
        await _dbService.updateWalletBalance(walletId, wallet.balance + amount);

        await _dbService.insertTransaction({
          'type': 'expense',
          'amount': amount,
          'description': 'Mencairkan dari ${saving.name}',
          'category_type': 'saving',
          'category_id': savingId,
          'date': date.toIso8601String(),
        });

        await _dbService.insertTransaction({
          'type': 'income',
          'amount': amount,
          'description': 'Pencairan ke ${wallet.name}',
          'category_type': 'wallet',
          'category_id': walletId,
          'date': date.toIso8601String(),
        });
      }

      await fetchData();
    } catch (e) {
      debugPrint('Error during saving transfer: $e');
    }
  }

  Future<void> addDepositTransaction({
    required String name,
    required double amount,
    required String depositId,
    required DateTime date,
  }) async {
    try {
      final deposit = _deposits.firstWhere((d) => d.id == depositId);
      
      await _dbService.updateDepositBalance(depositId, deposit.amount + amount);
      
      await _dbService.insertTransaction({
        'type': 'income',
        'amount': amount,
        'description': name,
        'category_type': 'deposit',
        'category_id': depositId,
        'date': date.toIso8601String(),
      });

      await fetchData();
    } catch (e) {
      debugPrint('Error adding deposit transaction: $e');
    }
  }

  Future<void> addPiutangItem({
    required String prefix,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      await _dbService.insertDebt({
        'name': '$prefix $name',
        'total_amount': amount,
        'remaining_amount': amount,
        'due_date': dueDate.toIso8601String(),
      });
      await fetchData();
    } catch (e) {
      debugPrint('Error adding piutang item: $e');
    }
  }

  Future<void> addPiutangInstallmentItem({
    required String prefix,
    required String name,
    required double amount,
    required int totalTenor,
    required int paidTenor,
    required DateTime dueDate,
  }) async {
    try {
      await _dbService.insertRecurringBill({
        'name': '$prefix $name',
        'amount': amount,
        'due_day': dueDate.day,
        'is_installment': true,
        'total_tenor': totalTenor,
        'start_tenor': paidTenor,
        'start_date': dueDate.toIso8601String(),
      });
      await fetchData();
    } catch (e) {
      debugPrint('Error adding piutang installment: $e');
    }
  }

  Future<void> addDebtItem({
    required String masterDebtId,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      final masterDebt = _debts.firstWhere((d) => d.id == masterDebtId);
      
      // Insert specific debt item with prefix for filtering
      final masterName = masterDebt.name.toLowerCase();
      final prefix = masterName.contains('bca') ? '[BCA]' : (masterName.contains('spaylater') ? '[SP]' : '[OT]');
      await _dbService.insertDebt({
        'name': '$prefix $name',
        'total_amount': amount,
        'remaining_amount': amount,
        'due_date': dueDate.toIso8601String(),
      });

      await fetchData();
    } catch (e) {
      debugPrint('Error adding debt item: $e');
    }
  }

  Future<void> addInstallmentItem({
    required String masterDebtId,
    required String name,
    required double amount,
    required int totalTenor,
    required int paidTenor,
    required DateTime dueDate,
  }) async {
    try {
      final masterDebt = _debts.firstWhere((d) => d.id == masterDebtId);
      
      // Insert recurring bill for installment
      final masterName = masterDebt.name.toLowerCase();
      final prefix = masterName.contains('bca') ? '[BCA]' : (masterName.contains('spaylater') ? '[SP]' : '[OT]');
      
      await _dbService.insertRecurringBill({
        'name': '$prefix $name',
        'amount': amount,
        'due_day': dueDate.day,
        'is_installment': true,
        'total_tenor': totalTenor,
        'start_tenor': paidTenor,
        'start_date': dueDate.toIso8601String(),
      });

      await fetchData();
    } catch (e) {
      debugPrint('Error adding installment item: $e');
    }
  }

  Future<void> updatePiutangItem({
    required String id,
    required String prefix,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      await _dbService.updateDebt(id, {
        'name': '$prefix $name',
        'total_amount': amount,
        'remaining_amount': amount,
        'due_date': dueDate.toIso8601String(),
      });
      await fetchData();
    } catch (e) {
      debugPrint('Error updating piutang item: $e');
    }
  }

  Future<void> updatePiutangInstallment({
    required String id,
    required String prefix,
    required String name,
    required double amount,
    required int totalTenor,
    required int paidTenor,
    required DateTime dueDate,
  }) async {
    try {
      await _dbService.updateRecurringBill(id, {
        'name': '$prefix $name',
        'amount': amount,
        'due_day': dueDate.day,
        'is_installment': true,
        'total_tenor': totalTenor,
        'start_tenor': paidTenor,
        'start_date': dueDate.toIso8601String(),
      });
      await fetchData();
    } catch (e) {
      debugPrint('Error updating piutang installment: $e');
    }
  }

  Future<void> updateDebtItem({
    required String id,
    required String masterDebtId,
    required String name,
    required double amount,
    required DateTime dueDate,
  }) async {
    try {
      final masterDebt = _debts.firstWhere((d) => d.id == masterDebtId);
      final masterName = masterDebt.name.toLowerCase();
      final prefix = masterName.contains('bca') ? '[BCA]' : (masterName.contains('spaylater') ? '[SP]' : '[OT]');
      await _dbService.updateDebt(id, {
        'name': '$prefix $name',
        'total_amount': amount,
        'remaining_amount': amount,
        'due_date': dueDate.toIso8601String(),
      });
      await fetchData();
    } catch (e) {
      debugPrint('Error updating debt item: $e');
    }
  }

  Future<void> updateInstallmentItem({
    required String id,
    required String masterDebtId,
    required String name,
    required double amount,
    required int totalTenor,
    required int paidTenor,
    required DateTime dueDate,
  }) async {
    try {
      final masterDebt = _debts.firstWhere((d) => d.id == masterDebtId);
      final masterName = masterDebt.name.toLowerCase();
      final prefix = masterName.contains('bca') ? '[BCA]' : (masterName.contains('spaylater') ? '[SP]' : '[OT]');
      await _dbService.updateRecurringBill(id, {
        'name': '$prefix $name',
        'amount': amount,
        'due_day': dueDate.day,
        'is_installment': true,
        'total_tenor': totalTenor,
        'start_tenor': paidTenor,
        'start_date': dueDate.toIso8601String(),
      });
      await fetchData();
    } catch (e) {
      debugPrint('Error updating installment item: $e');
    }
  }

  Future<void> settlePiutangItem(Debt debt) async {
    try {
      final bcaWallet = _wallets.where((w) => w.name.toUpperCase() == 'BCA').firstOrNull;
      if (bcaWallet != null) {
        await _dbService.updateWalletBalance(bcaWallet.id, bcaWallet.balance + debt.remainingAmount);
        await _dbService.insertTransaction({
          'type': 'income',
          'amount': debt.remainingAmount,
          'description': 'Pelunasan Piutang: ${debt.name}',
          'category_type': 'wallet',
          'category_id': bcaWallet.id,
          'date': DateTime.now().toIso8601String(),
        });
        await _dbService.deleteDebt(debt.id);
        await fetchData();
      }
    } catch (e) {
      debugPrint('Error settling piutang item: $e');
    }
  }

  Future<void> settlePiutangInstallment(RecurringBill bill) async {
    try {
      final bcaWallet = _wallets.where((w) => w.name.toUpperCase() == 'BCA').firstOrNull;
      if (bcaWallet != null) {
        await _dbService.updateWalletBalance(bcaWallet.id, bcaWallet.balance + bill.amount);
        await _dbService.insertTransaction({
          'type': 'income',
          'amount': bill.amount,
          'description': 'Cicilan Piutang: ${bill.name}',
          'category_type': 'wallet',
          'category_id': bcaWallet.id,
          'date': DateTime.now().toIso8601String(),
        });
        
        if (bill.remainingTenor <= 1) {
          await _dbService.deleteRecurringBill(bill.id);
        } else {
          await _dbService.updateRecurringBill(bill.id, {
            'start_tenor': (bill.startTenor ?? 0) + 1,
          });
        }
        await fetchData();
      }
    } catch (e) {
      debugPrint('Error settling piutang installment: $e');
    }
  }

  Future<void> settleDebtItem(Debt debt) async {
    try {
      final bcaWallet = _wallets.where((w) => w.name.toUpperCase() == 'BCA').firstOrNull;
      if (bcaWallet != null) {
        await _dbService.updateWalletBalance(bcaWallet.id, bcaWallet.balance - debt.remainingAmount);
        await _dbService.insertTransaction({
          'type': 'expense',
          'amount': debt.remainingAmount,
          'description': 'Pelunasan Hutang: ${debt.name}',
          'category_type': 'wallet',
          'category_id': bcaWallet.id,
          'date': DateTime.now().toIso8601String(),
        });
        await _dbService.deleteDebt(debt.id);
        await fetchData();
      }
    } catch (e) {
      debugPrint('Error settling debt item: $e');
    }
  }

  Future<void> settleInstallmentItem(RecurringBill bill) async {
    try {
      final bcaWallet = _wallets.where((w) => w.name.toUpperCase() == 'BCA').firstOrNull;
      if (bcaWallet != null) {
        await _dbService.updateWalletBalance(bcaWallet.id, bcaWallet.balance - bill.amount);
        await _dbService.insertTransaction({
          'type': 'expense',
          'amount': bill.amount,
          'description': 'Cicilan Hutang: ${bill.name}',
          'category_type': 'wallet',
          'category_id': bcaWallet.id,
          'date': DateTime.now().toIso8601String(),
        });

        if (bill.remainingTenor <= 1) {
          await _dbService.deleteRecurringBill(bill.id);
        } else {
          await _dbService.updateRecurringBill(bill.id, {
            'start_tenor': (bill.startTenor ?? 0) + 1,
          });
        }
        await fetchData();
      }
    } catch (e) {
      debugPrint('Error settling installment item: $e');
    }
  }

  Future<void> removePiutangDebt(String id) async {
    try {
      await _dbService.deleteDebt(id);
      await fetchData();
    } catch (e) {
      debugPrint('Error removing piutang debt: $e');
    }
  }

  Future<void> removeDebt(String id) async {
    try {
      await _dbService.deleteDebt(id);
      await fetchData();
    } catch (e) {
      debugPrint('Error removing debt: $e');
    }
  }

  Future<void> removePiutangInstallment(String id) async {
    try {
      await _dbService.deleteRecurringBill(id);
      await fetchData();
    } catch (e) {
      debugPrint('Error removing piutang installment: $e');
    }
  }

  Future<void> removeRecurringBill(String id) async {
    try {
      await _dbService.deleteRecurringBill(id);
      await fetchData();
    } catch (e) {
      debugPrint('Error removing recurring bill: $e');
    }
  }

  Future<void> updateTransaction({
    required String id,
    required Transaction oldTransaction,
    required String type,
    required double amount,
    required String description,
    required String categoryType,
    required String categoryId,
    required DateTime date,
    String? incomeType,
    double? modal,
    double? jual,
  }) async {
    try {
      // 1. Revert Old Transaction Impact
      if (oldTransaction.type == 'income') {
        final wallet = _wallets.where((w) => w.id == oldTransaction.categoryId).firstOrNull;
        if (wallet != null) {
          await _dbService.updateWalletBalance(wallet.id, wallet.balance - oldTransaction.amount);
        }
      } else {
        if (oldTransaction.categoryType == 'wallet') {
          final wallet = _wallets.where((w) => w.id == oldTransaction.categoryId).firstOrNull;
          if (wallet != null) {
            await _dbService.updateWalletBalance(wallet.id, wallet.balance + oldTransaction.amount);
          }
        } else if (oldTransaction.categoryType == 'debt') {
          final debt = _debts.where((d) => d.id == oldTransaction.categoryId).firstOrNull;
          if (debt != null) {
            await _dbService.updateDebtRemainingAmount(debt.id, debt.remainingAmount - oldTransaction.amount);
          }
        }
      }

      // Refresh wallets/debts to get latest balance after revert
      await fetchData();

      // 2. Apply New Transaction Impact
      if (type == 'income') {
        final wallet = _wallets.firstWhere((w) => w.id == categoryId);
        await _dbService.updateWalletBalance(wallet.id, wallet.balance + amount);
      } else {
        if (categoryType == 'wallet') {
          final wallet = _wallets.firstWhere((w) => w.id == categoryId);
          await _dbService.updateWalletBalance(wallet.id, wallet.balance - amount);
        } else if (categoryType == 'debt') {
          final debt = _debts.firstWhere((d) => d.id == categoryId);
          await _dbService.updateDebtRemainingAmount(debt.id, debt.remainingAmount + amount);
        }
      }

      // 3. Update Transaction Data in DB
      await _dbService.updateTransaction(id, {
        'type': type,
        'amount': amount,
        'description': description,
        'category_type': categoryType,
        'category_id': categoryId,
        'date': date.toIso8601String(),
        'income_type': incomeType,
        'modal': modal,
        'jual': jual,
      });

      await fetchData();
    } catch (e) {
      debugPrint('Error updating transaction: $e');
    }
  }

  Future<void> removeTransaction(Transaction transaction) async {
    try {
      await _dbService.deleteTransaction(transaction.id);

      // Revert saldo
      if (transaction.type == 'income') {
        final wallet = _wallets.firstWhere((w) => w.id == transaction.categoryId);
        await _dbService.updateWalletBalance(wallet.id, wallet.balance - transaction.amount);
      } else {
        if (transaction.categoryType == 'wallet') {
          final wallet = _wallets.firstWhere((w) => w.id == transaction.categoryId);
          await _dbService.updateWalletBalance(wallet.id, wallet.balance + transaction.amount);
        } else if (transaction.categoryType == 'debt') {
          final debt = _debts.firstWhere((d) => d.id == transaction.categoryId);
          await _dbService.updateDebtRemainingAmount(debt.id, debt.remainingAmount - transaction.amount);
        }
      }

      await fetchData();
    } catch (e) {
      debugPrint('Error removing transaction: $e');
    }
  }

  Future<void> manualUpdateWalletBalance(String walletId, double newBalance) async {
    try {
      await _dbService.updateWalletBalance(walletId, newBalance);
      await fetchData();
    } catch (e) {
      debugPrint('Error manually updating wallet balance: $e');
    }
  }

  // =========================================================
  // KOKO BUSINESS LOGIC
  // =========================================================

  void _sortKokoLists() {
    int compare(KokoBillEntry a, KokoBillEntry b) {
      if (a.date == null && b.date == null) return _compareNatural(a.title, b.title);
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      try {
        final dateA = DateFormat('dd/MM/yyyy').parse(a.date!);
        final dateB = DateFormat('dd/MM/yyyy').parse(b.date!);
        final dateComp = dateA.compareTo(dateB);
        if (dateComp != 0) return dateComp;
      } catch (_) {
        // Fallback if date parsing fails
      }
      return _compareNatural(a.title, b.title);
    }
    _whiteKostEntries.sort(compare);
    _mykostEntries.sort(compare);
  }

  int _compareNatural(String a, String b) {
    final aStr = a.toLowerCase();
    final bStr = b.toLowerCase();
    final aStartsDigit = aStr.isNotEmpty && RegExp(r'^\d').hasMatch(aStr);
    final bStartsDigit = bStr.isNotEmpty && RegExp(r'^\d').hasMatch(bStr);
    if (aStartsDigit != bStartsDigit) return aStartsDigit ? 1 : -1;
    final re = RegExp(r'(\d+)|(\D+)');
    final aMatches = re.allMatches(aStr).toList();
    final bMatches = re.allMatches(bStr).toList();
    for (int i = 0; i < aMatches.length && i < bMatches.length; i++) {
      final aPart = aMatches[i].group(0)!;
      final bPart = bMatches[i].group(0)!;
      if (aPart != bPart) {
        final aNum = int.tryParse(aPart);
        final bNum = int.tryParse(bPart);
        if (aNum != null && bNum != null) return aNum.compareTo(bNum);
        return aPart.compareTo(bPart);
      }
    }
    return aMatches.length.compareTo(bMatches.length);
  }

  Future<void> updateKokoPeriod(DateTime start, DateTime end) async {
    final period = KokoBillingPeriod(
      id: _activeKokoPeriod?.id,
      startDate: DateFormat('yyyy-MM-dd').format(start),
      endDate: DateFormat('yyyy-MM-dd').format(end),
    );
    await _dbService.upsertKokoPeriod(period);
    await fetchData();
  }

  Future<void> addKokoEntry(String kostType) async {
    if (_activeKokoPeriod == null) {
      await updateKokoPeriod(DateTime.now(), DateTime.now().add(const Duration(days: 14)));
      // Period is fetched inside updateKokoPeriod -> fetchData
    }
    
    if (_activeKokoPeriod?.id == null) {
      debugPrint('Cannot add entry: No active period found');
      return;
    }

    final entry = KokoBillEntry(
      periodId: _activeKokoPeriod!.id!,
      title: '',
      amount: 0,
      date: DateFormat('dd/MM/yyyy').format(DateTime.now()),
    );
    final table = kostType == 'white' ? 'koko_white_kost_35' : 'koko_mykost_179';
    await _dbService.upsertKokoEntry(table, entry);
    await fetchData();
  }

  Future<void> updateKokoEntry(String kostType, KokoBillEntry entry) async {
    final table = kostType == 'white' ? 'koko_white_kost_35' : 'koko_mykost_179';
    await _dbService.upsertKokoEntry(table, entry);
    await fetchData();
  }

  Future<void> deleteKokoEntry(String kostType, String id) async {
    final table = kostType == 'white' ? 'koko_white_kost_35' : 'koko_mykost_179';
    await _dbService.deleteKokoEntry(table, id);
    await fetchData();
  }

  Future<void> resetKokoBills() async {
    if (_activeKokoPeriod?.id == null) return;

    try {
      final now = DateTime.now();
      
      // 1. Hitung total yang akan dilunasi (Pembulatan Belanja + Piutang Manual [KOKO] bulan ini)
      double totalToPay = 0;
      
      // Tambahkan pembulatan belanja jika jatuh tempo bulan ini
      if (isKokoPeriodDueThisMonth) {
        totalToPay += roundedKokoBillTotal;
      }

      // Cari piutang manual dengan prefix [KOKO] yang jatuh tempo bulan ini
      final kokoDebtsToClear = _debts.where((d) {
        return d.name.startsWith('[KOKO]') && 
               d.dueDate != null && 
               d.dueDate!.year == now.year && 
               d.dueDate!.month == now.month;
      }).toList();

      for (var d in kokoDebtsToClear) {
        totalToPay += d.remainingAmount;
      }

      // 2. Jika ada dana yang harus masuk, proses ke dompet BCA
      if (totalToPay > 0) {
        final bcaWallet = _wallets.where((w) => w.name.toUpperCase() == 'BCA').firstOrNull;
        if (bcaWallet != null) {
          // Update Saldo BCA
          await _dbService.updateWalletBalance(bcaWallet.id, bcaWallet.balance + totalToPay);
          
          // Catat Transaksi Pemasukan
          await _dbService.insertTransaction({
            'type': 'income',
            'amount': totalToPay,
            'description': 'Pelunasan Tagihan Koko',
            'category_type': 'wallet',
            'category_id': bcaWallet.id,
            'date': now.toIso8601String(),
          });

          // Hapus piutang manual yang sudah dilunasi
          for (var d in kokoDebtsToClear) {
            await _dbService.deleteDebt(d.id);
          }
        }
      }

      // 3. Hapus semua rincian belanja (Logika lama)
      await _dbService.clearKokoEntries('koko_white_kost_35', _activeKokoPeriod!.id!);
      await _dbService.clearKokoEntries('koko_mykost_179', _activeKokoPeriod!.id!);
      
      // Refresh data
      await fetchData();
    } catch (e) {
      debugPrint('Error during resetKokoBills: $e');
    }
  }

  Future<void> uploadKokoReceipt(String kostType, String entryId, Uint8List bytes) async {
    final bucket = kostType == 'white' ? 'koko-white-kost-receipts' : 'koko-mykost-receipts';
    try {
      final url = await _dbService.uploadKokoReceipt(bucket, bytes);
      if (url != null) {
        final list = kostType == 'white' ? _whiteKostEntries : _mykostEntries;
        final entry = list.firstWhere((e) => e.id == entryId);
        await updateKokoEntry(kostType, KokoBillEntry(
          id: entry.id,
          periodId: entry.periodId,
          title: entry.title,
          amount: entry.amount,
          receiptUrl: url,
          date: entry.date,
        ));
      }
    } catch (e) {
      rethrow; // Biarkan UI menangkap error ini
    }
  }

  // =========================================================
  // CUSTOM MONTHLY DETAILS (Detail Pemasukan & Pengeluaran)
  // =========================================================

  final Map<String, Map<String, double>> _customMonthlyDetails = {};

  Map<String, double> getCustomMonthlyDetails(String monthKey) {
    if (!_customMonthlyDetails.containsKey(monthKey)) {
      // 1. Try to find the latest available month's data to use as defaults
      Map<String, double>? lastAvailableData;
      if (_customMonthlyDetails.isNotEmpty) {
        final sortedKeys = _customMonthlyDetails.keys.toList()..sort();
        // Look for the most recent month key that is LESS than the current monthKey
        for (final key in sortedKeys.reversed) {
          if (key.compareTo(monthKey) < 0) {
            lastAvailableData = _customMonthlyDetails[key];
            break;
          }
        }
      }

      // 2. Initialize with defaults (either from last month or hardcoded base)
      _customMonthlyDetails[monthKey] = {
        'gaji_pokok': lastAvailableData?['gaji_pokok'] ?? 4500000.0,
        'tunjangan': lastAvailableData?['tunjangan'] ?? 2500000.0,
        'bonus': 0.0,
        'lain_lain_sumber': lastAvailableData?['lain_lain_sumber'] ?? 0.0,
        'belanja_istri': lastAvailableData?['belanja_istri'] ?? 3500000.0,
        'sewa_kost': lastAvailableData?['sewa_kost'] ?? 2500000.0,
        'konsumtif': 0.0,
        'lain_lain_dihabiskan': lastAvailableData?['lain_lain_dihabiskan'] ?? 0.0,
      };
    }
    
    final details = _customMonthlyDetails[monthKey]!;
    
    // Sinkronisasi otomatis dengan data transaksi nyata
    try {
      final date = DateTime.parse("$monthKey-01");
      details['bonus'] = _getFilteredAmountForMonth('income', date);
      details['konsumtif'] = _getFilteredAmountForMonth('expense', date);
    } catch (_) {}

    return details;
  }

  Future<void> updateCustomMonthlyNominal(String monthKey, String field, double value) async {
    final details = getCustomMonthlyDetails(monthKey);
    details[field] = value;
    
    // Save to database
    try {
      final cf = CustomMonthlyFinance(
        monthKey: monthKey,
        gajiPokok: details['gaji_pokok'] ?? 0,
        tunjangan: details['tunjangan'] ?? 0,
        bonus: details['bonus'] ?? 0,
        lainLainSumber: details['lain_lain_sumber'] ?? 0,
        belanjaIstri: details['belanja_istri'] ?? 0,
        sewaKost: details['sewa_kost'] ?? 0,
        konsumtif: details['konsumtif'] ?? 0,
        lainLainDihabiskan: details['lain_lain_dihabiskan'] ?? 0,
      );
      await _dbService.upsertCustomMonthlyFinance(cf);
    } catch (e) {
      debugPrint('Error saving custom monthly finance: $e');
    }
    
    notifyListeners();
  }
}
