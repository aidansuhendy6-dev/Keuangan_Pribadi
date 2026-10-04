import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';

class DanaVsTagihanChart extends StatelessWidget {
  const DanaVsTagihanChart({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmtJt = NumberFormat("#,##0.#", "id_ID");
    
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final totalMonths = 12;

    List<BarChartGroupData> barGroups = [];
    double maxVal = 0;

    for (int i = 0; i < totalMonths; i++) {
      final targetDate = DateTime(startDate.year, startDate.month + i, 1);
      final bool isCurrentMonth = i == 0;

      double dana = 0;
      double tagihan = 0;

      // 1. Hitung Dana (Hijau)
      if (isCurrentMonth) {
        // Saldo Dompet (BCA, Cash, Shopeepay) - Case Insensitive
        for (var wallet in finance.wallets) {
          final wName = wallet.name.toLowerCase();
          if (['bca', 'cash', 'shopeepay'].contains(wName)) {
            dana += wallet.balance;
          }
        }
      }

      // Piutang ([KOKO], [DEP])
      dana += _calculateMonthlyAmount(finance, targetDate, ['[KOKO]', '[DEP]']);

      // 2. Hitung Tagihan (Merah)
      // Hutang ([BCA], [SP], [OT])
      tagihan += _calculateMonthlyAmount(finance, targetDate, ['[BCA]', '[SP]', '[OT]']);

      if (dana > maxVal) maxVal = dana;
      if (tagihan > maxVal) maxVal = tagihan;

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 12,
          barRods: [
            BarChartRodData(
              toY: dana,
              gradient: const LinearGradient(
                colors: [Color(0xFF0F593E), Color(0xFF00B167)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            BarChartRodData(
              toY: tagihan,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1A1A), Color(0xFFFF3B30)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 24,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
          showingTooltipIndicators: [0, 1],
        ),
      );
    }

    final double maxY = (maxVal / 5000000).ceil() * 5000000.0 + 5000000;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dana vs Tagihan",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text("Proyeksi 12 Bulan", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildLegend(const Color(0xFF00B167), "Dana"),
              const SizedBox(width: 20),
              _buildLegend(const Color(0xFFFF3B30), "Tagihan"),
            ],
          ),
          const SizedBox(height: 60),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 12 * 120.0,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY,
                    barTouchData: BarTouchData(
                      enabled: false,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (_) => Colors.transparent,
                        tooltipPadding: EdgeInsets.zero,
                        tooltipMargin: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          if (rod.toY == 0) return null;
                          return BarTooltipItem(
                            "${fmtJt.format(rod.toY / 1000000)} jt",
                            TextStyle(
                              color: rod.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 80,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= 12) return const SizedBox();
                            final date = DateTime(startDate.year, startDate.month + index, 1);
                            final monthName = DateFormat('MMMM', 'id_ID').format(date);
                            final year = date.year.toString();
                            
                            // Calculate diff for this month
                            double dana = (index == 0) ? finance.wallets.where((w) => ['BCA', 'Cash', 'Shopeepay'].contains(w.name)).fold(0.0, (s, w) => s + w.balance) : 0;
                            dana += _calculateMonthlyAmount(finance, date, ['[KOKO]', '[DEP]']);
                            double tagihan = _calculateMonthlyAmount(finance, date, ['[BCA]', '[SP]', '[OT]']);
                            double diff = dana - tagihan;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Column(
                                children: [
                                  Text(monthName, style: const TextStyle(fontSize: 11, color: Colors.black54)),
                                  Text(year, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${fmtJt.format(diff / 1000000)} jt",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: diff >= 0 ? const Color(0xFF00B167) : const Color(0xFFFF3B30),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(
                      show: true,
                      border: Border(
                        bottom: BorderSide(color: Colors.black.withOpacity(0.05)),
                      ),
                    ),
                    barGroups: barGroups,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMonthlyAmount(FinanceProvider finance, DateTime targetDate, List<String> prefixes) {
    double total = 0;
    final now = DateTime.now();
    final bool isCurrentMonth = targetDate.year == now.year && targetDate.month == now.month;

    // Tambahkan Tagihan Belanja Koko (dari sidebar) jika bulan jatuh tempo cocok
    if (prefixes.contains('[KOKO]')) {
      final period = finance.activeKokoPeriod;
      if (period != null) {
        try {
          final endDate = DateTime.parse(period.endDate);
          if (targetDate.year == endDate.year && targetDate.month == endDate.month) {
            total += finance.roundedKokoBillTotal;
          }
        } catch (_) {}
      }
    }

    // 1. Check Debts (One time payment)
    for (var debt in finance.debts) {
      if (debt.dueDate != null &&
          debt.dueDate!.year == targetDate.year &&
          debt.dueDate!.month == targetDate.month) {
        if (prefixes.any((p) => debt.name.startsWith(p))) {
          // Hanya hitung yang masih ada sisa (belum lunas)
          if (debt.remainingAmount > 0) {
            total += debt.remainingAmount;
          }
        }
      }
    }

    // 2. Check Recurring Bills
    for (var bill in finance.recurringBills) {
      if (prefixes.any((p) => bill.name.startsWith(p))) {
        if (bill.isInstallment && bill.startDate != null && bill.startTenor != null) {
          // Calculate which tenor corresponds to targetDate
          int monthsDiff = (targetDate.year - bill.startDate!.year) * 12 + (targetDate.month - bill.startDate!.month);
          int targetTenor = bill.startTenor! + monthsDiff;

          // Check if targetTenor is within the installment range
          if (targetTenor >= 1 && targetTenor <= (bill.totalTenor ?? 0)) {
            // Untuk bulan berjalan, pastikan belum terbayar (cek nextDueDate)
            if (isCurrentMonth) {
              if (bill.nextDueDate.month == now.month) {
                total += bill.amount;
              }
            } else {
              total += bill.amount;
            }
          }
        } else if (!bill.isInstallment) {
          // Non-installment recurring bills
          if (isCurrentMonth) {
            // Hanya hitung jika jatuh tempo masih di bulan ini (belum lewat)
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

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
