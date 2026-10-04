import 'database_service.dart';
import '../models/monthly_history_model.dart';
import '../models/custom_monthly_finance_model.dart';

class SeedData {
  static Future<void> seedMonthlyHistory(DatabaseService db) async {
    try {
      final history = await db.getMonthlyHistory();
      if (history.any((h) => h.year == 2026 && h.month == 8)) return;

      // Seed Jan-Aug 2026 based on user provided data
      final initialData = [
        MonthlyHistory(month: 1, year: 2026, balance: 10000000, debt: 0),
        MonthlyHistory(month: 2, year: 2026, balance: 12000000, debt: 0),
        MonthlyHistory(month: 3, year: 2026, balance: 11000000, debt: 0),
        MonthlyHistory(month: 4, year: 2026, balance: 12000000, debt: 0),
        MonthlyHistory(month: 5, year: 2026, balance: 16000000, debt: 0),
        MonthlyHistory(month: 6, year: 2026, balance: 13500000, debt: 0),
        MonthlyHistory(month: 7, year: 2026, balance: 16000000, debt: 0),
        MonthlyHistory(month: 8, year: 2026, balance: 33300000, debt: 37400000),
      ];

      for (var h in initialData) {
        await db.upsertMonthlyHistory(h);
      }
    } catch (e) {
      print("Seeding Monthly History Error: $e");
    }
  }

  static Future<void> seedCustomMonthlyFinance(DatabaseService db) async {
    try {
      final existing = await db.getCustomMonthlyFinance();
      if (existing.isNotEmpty) return;

      // Seed for current month (Sept 2026) and previous months to populate the charts
      final months = [
        '2026-08', '2026-09'
      ];

      for (var monthKey in months) {
        await db.upsertCustomMonthlyFinance(CustomMonthlyFinance(
          monthKey: monthKey,
          gajiPokok: 4500000.0,
          tunjangan: 2500000.0,
          bonus: 0.0,
          lainLainSumber: 0.0,
          belanjaIstri: 3500000.0,
          sewaKost: 2500000.0,
          konsumtif: 0.0,
          lainLainDihabiskan: 0.0,
        ));
      }
    } catch (e) {
      print("Seeding Custom Monthly Finance Error: $e");
    }
  }

  static Future<void> seedMissingCards(DatabaseService db) async {
    try {
      // 1. Check & Seed Deposits (Bonus)
      final deposits = await db.getDeposits();
      final hasBonus = deposits.any((d) => d.name == "Bonus");
      if (!hasBonus) {
        await db.insertDeposit({
          'name': 'Bonus',
          'amount': 0.0,
        });
      }

      // 2. Check & Seed Debts (Master Cards)
      final debts = await db.getDebts();
      
      final masterCards = [
        "Hutang Lainnya",
        "Kartu Kredit BCA",
        "SPayLater",
      ];

      for (var cardName in masterCards) {
        final exists = debts.any((d) => d.name.toLowerCase() == cardName.toLowerCase());
        if (!exists) {
          await db.insertDebt({
            'name': cardName,
            'total_amount': 0.0,
            'remaining_amount': 0.0,
          });
        }
      }
    } catch (e) {
      print("Seeding Error: $e");
    }
  }
}
