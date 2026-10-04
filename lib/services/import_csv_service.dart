import 'dart:io';
import 'finance_provider.dart';

class ImportCsvService {
  static Future<void> importDepositTransactions(String csvPath, FinanceProvider finance) async {
    try {
      final file = File(csvPath);
      if (!await file.exists()) {
        print("CSV file not found at $csvPath");
        return;
      }

      final lines = await file.readAsLines();
      if (lines.isEmpty) return;

      // Skip header: amount,description,category_type,date
      final dataLines = lines.skip(1);

      // Find the "Deposit" card ID
      final depositCard = finance.deposits.firstWhere(
        (d) => d.name.toLowerCase().contains('deposit'),
        orElse: () => throw Exception("Deposit card not found in database"),
      );

      print("Importing ${dataLines.length} transactions to ${depositCard.name}...");

      for (var line in dataLines) {
        if (line.trim().isEmpty) continue;
        
        final parts = line.split(',');
        if (parts.length < 4) continue;

        final amount = double.tryParse(parts[0]) ?? 0.0;
        final description = parts[1];
        // parts[2] is category_type (deposit)
        final dateStr = parts[3];
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();

        if (amount > 0) {
          await finance.addDepositTransaction(
            name: description,
            amount: amount,
            depositId: depositCard.id,
            date: date,
          );
        }
      }

      print("Import completed successfully.");
    } catch (e) {
      print("Error importing CSV: $e");
    }
  }
}
