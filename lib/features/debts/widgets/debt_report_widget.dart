import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';

class DebtReportWidget extends StatelessWidget {
  final FinanceProvider finance;
  final String dateTimeString;

  const DebtReportWidget({
    super.key,
    required this.finance,
    required this.dateTimeString,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Data filtering (same as DebtScreen)
    final bcaItems = [
      ...finance.debts.where((d) => d.name.startsWith('[BCA]')),
      ...finance.recurringBills.where((b) => b.name.startsWith('[BCA]')),
    ];
    final spaylaterItems = [
      ...finance.debts.where((d) => d.name.startsWith('[SP]')),
      ...finance.recurringBills.where((b) => b.name.startsWith('[SP]')),
    ];
    final otherItems = [
      ...finance.debts.where((d) => d.name.startsWith('[OT]')),
      ...finance.recurringBills.where((b) => b.name.startsWith('[OT]')),
    ];

    // Sorting Logic
    DateTime getNextDueDate(dynamic item) {
      final now = DateTime.now();
      if (item is Debt) return item.dueDate ?? DateTime(2100);
      if (item is RecurringBill) return item.nextDueDate;
      return DateTime(2100);
    }

    void sortItems(List<dynamic> items) {
      items.sort((a, b) {
        if (a is Debt && b is RecurringBill) return -1;
        if (a is RecurringBill && b is Debt) return 1;
        if (a is RecurringBill && b is RecurringBill) {
          final remA = (a.totalTenor ?? 0) - (a.currentPaidTenor ?? 0);
          final remB = (b.totalTenor ?? 0) - (b.currentPaidTenor ?? 0);
          if (remA != remB) return remA.compareTo(remB);
          return (b.totalTenor ?? 0).compareTo(a.totalTenor ?? 0);
        }
        return getNextDueDate(a).compareTo(getNextDueDate(b));
      });
    }

    sortItems(bcaItems);
    sortItems(spaylaterItems);
    sortItems(otherItems);

    double calculateMonthlyTotal(List<dynamic> items) {
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
                      "LAPORAN DAFTAR HUTANG",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black, letterSpacing: -1.0),
                    ),
                    Text(
                      "Ringkasan cicilan dan kewajiban pembayaran",
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
                Expanded(child: _buildColumn("Kartu Kredit BCA", finance.bcaDebtBalance, calculateMonthlyTotal(bcaItems), bcaItems, const Color(0xFF0088FF), fmt)),
                const SizedBox(width: 30),
                Expanded(child: _buildColumn("SPayLater", finance.spaylaterDebtBalance, calculateMonthlyTotal(spaylaterItems), spaylaterItems, const Color(0xFFFF6633), fmt)),
                const SizedBox(width: 30),
                Expanded(child: _buildColumn("Hutang Lainnya", finance.otherDebtBalance, calculateMonthlyTotal(otherItems), otherItems, const Color(0xFFFF5C5C), fmt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumn(String title, double total, double monthly, List<dynamic> items, Color color, NumberFormat fmt) {
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
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Tagihan Bulan Ini: ", style: TextStyle(color: Colors.white60, fontSize: 11)),
                    Text(fmt.format(monthly), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
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
              ? const Padding(padding: EdgeInsets.all(32), child: Text("Tidak ada tagihan", style: TextStyle(color: Colors.grey, fontSize: 12)))
              : Column(
                  children: items.map((item) => _buildItem(item, fmt)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildItem(dynamic item, NumberFormat fmt) {
    final cleanName = (item is Debt ? item.name : (item as RecurringBill).name).replaceAll(RegExp(r'\[.*?\] '), '');
    final amount = item is Debt ? item.remainingAmount : (item as RecurringBill).amount;
    final isInstallment = item is RecurringBill;
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
                    fmt.format(amount),
                    maxLines: 1,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dueDate != null ? "Jatuh tempo: ${dateFmt.format(dueDate)}" : "N/A",
                style: const TextStyle(color: Colors.black38, fontSize: 10),
              ),
              if (isInstallment)
                Text(
                  "${item.currentPaidTenor}/${item.totalTenor}",
                  style: const TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
