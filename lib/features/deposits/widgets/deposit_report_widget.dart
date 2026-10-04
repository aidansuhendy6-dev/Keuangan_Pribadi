import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';

class DepositReportWidget extends StatelessWidget {
  final FinanceProvider finance;
  final String dateTimeString;

  const DepositReportWidget({
    super.key,
    required this.finance,
    required this.dateTimeString,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Data filtering (same as DepositScreen)
    List<dynamic> getItems(String prefix) {
      final paylater = finance.debts.where((d) => d.name.startsWith(prefix)).toList();
      final installments = finance.recurringBills.where((b) => b.name.startsWith(prefix)).toList();
      return [...paylater, ...installments];
    }

    final kokoItems = getItems('[KOKO]');
    final depItems = getItems('[DEP]');
    final bonusItems = getItems('[BNS]');

    void sortItems(List<dynamic> items) {
      items.sort((a, b) {
        DateTime dateA = a is Debt ? (a.dueDate ?? DateTime(2100)) : (a as RecurringBill).nextDueDate;
        DateTime dateB = b is Debt ? (b.dueDate ?? DateTime(2100)) : (b as RecurringBill).nextDueDate;
        return dateA.compareTo(dateB);
      });
    }

    sortItems(kokoItems);
    sortItems(depItems);
    sortItems(bonusItems);

    double calculateMonthly(List<dynamic> items) {
      final now = DateTime.now();
      return items.fold(0.0, (sum, item) {
        if (item is Debt && item.dueDate?.month == now.month && item.dueDate?.year == now.year) return sum + item.remainingAmount;
        if (item is RecurringBill && item.nextDueDate.month == now.month && item.nextDueDate.year == now.year) return sum + item.amount;
        return sum;
      });
    }

    return Material(
      color: const Color(0xFFF8F9FA),
      child: Container(
        width: 1000,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "LAPORAN DAFTAR PIUTANG",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1.0),
                    ),
                    Text(
                      "Ringkasan deposit, piutang, dan bonus",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ],
                ),
                Text(
                  dateTimeString,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildColumn("Tagihan Koko", finance.kokoPiutangBalance, calculateMonthly(kokoItems), kokoItems, const Color(0xFFFF3B30), fmt)),
                const SizedBox(width: 30),
                Expanded(child: _buildColumn("Deposit", finance.depPiutangBalance, calculateMonthly(depItems), depItems, const Color(0xFF00C2FF), fmt)),
                const SizedBox(width: 30),
                Expanded(child: _buildColumn("Bonus", finance.bonusPiutangBalance, 0, bonusItems, const Color(0xFF27D17F), fmt, showMonthly: false)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(String title, double total, double monthly, List<dynamic> items, Color color, NumberFormat fmt, {bool showMonthly = true}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(fmt.format(total), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ),
              if (showMonthly) ...[
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Jatuh Tempo Bulan Ini: ", style: TextStyle(color: Colors.white60, fontSize: 11)),
                      Text(fmt.format(monthly), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: items.isEmpty
              ? const Padding(padding: EdgeInsets.all(32), child: Text("Tidak ada data", style: TextStyle(color: Colors.grey, fontSize: 12)))
              : Column(
                  children: items.map((item) => _buildItem(item, fmt)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildItem(dynamic item, NumberFormat fmt) {
    final cleanName = (item is Debt ? item.name : (item as RecurringBill).name).substring((item is Debt ? item.name : (item as RecurringBill).name).indexOf(']') + 1).trim();
    final amount = item is Debt ? item.totalAmount : (item as RecurringBill).amount;
    final dateFmt = DateFormat('dd MMM', 'id_ID');
    final dueDate = item is Debt ? item.dueDate : (item as RecurringBill).nextDueDate;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  cleanName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "+ ${fmt.format(amount)}",
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            dueDate != null ? dateFmt.format(dueDate) : "N/A",
            style: const TextStyle(color: Colors.black38, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
