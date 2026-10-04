import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';

class BalanceVsDebtChart extends StatelessWidget {
  const BalanceVsDebtChart({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final shortFmt = NumberFormat.compact(locale: 'id_ID');

    final now = DateTime.now();
    final startDate = DateTime(2026, 8, 1); // Start from August 2026
    final endDate = DateTime(now.year, now.month + 11, 1); // Projection: 12 months from now
    
    // Calculate total months to display
    final totalMonths = ((endDate.year - startDate.year) * 12) + endDate.month - startDate.month + 1;
    
    List<BarChartGroupData> barGroups = [];
    List<Map<String, double>> monthlyValues = [];
    
    for (int i = 0; i < totalMonths; i++) {
      final date = DateTime(startDate.year, startDate.month + i, 1);
      
      // Cek apakah bulan mendatang
      final isFuture = date.year > now.year || (date.year == now.year && date.month > now.month);

      double saldo = 0;
      double hutang = 0;

      // Ambil dari riwayat database jika ada
      final history = finance.monthlyHistory.where(
        (h) => h.month == date.month && h.year == date.year
      ).firstOrNull;

      if (history != null) {
        saldo = history.balance;
        hutang = history.debt;
      }

      // Selalu gunakan data real-time jika ini adalah bulan sekarang
      if (date.year == now.year && date.month == now.month) {
        saldo = finance.totalBalance;
        hutang = finance.totalDebt;
      }
      
      if (isFuture) {
        saldo = 0;
        hutang = 0;
      }
      
      monthlyValues.add({'saldo': saldo, 'hutang': hutang});

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 8, // Space between Saldo and Hutang rods
          barRods: [
            BarChartRodData(
              toY: saldo,
              gradient: const LinearGradient(
                colors: [Color(0xFF0F593E), Color(0xFF00B167)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: hutang,
              gradient: const LinearGradient(
                colors: [Color(0xFF8B1A1A), Color(0xFFFF3B30)],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          showingTooltipIndicators: (saldo > 0 || hutang > 0) ? [0, 1] : [],
        ),
      );
    }

    // Calculate dynamic maxY
    final double maxVal = [finance.totalBalance, finance.totalDebt, 50000000.0].reduce((curr, next) => curr > next ? curr : next);
    final double maxY = (maxVal / 10000000).ceil() * 10000000.0; // Round to nearest 10M

    // Calculate dynamic width: each month takes ~80px space
    final double chartWidth = totalMonths * 80.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Saldo vs Hutang",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text("Proyeksi 12 Bulan", style: TextStyle(fontSize: 12)),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildLegend(const Color(0xFF00B167), "Saldo"),
              const SizedBox(width: 16),
              _buildLegend(const Color(0xFFFF3B30), "Hutang"),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth < 900 ? 900 : chartWidth, // Standardized min width
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0),
                  child: BarChart(
                    BarChartData(
                    alignment: BarChartAlignment.start,
                    groupsSpace: 40,
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
                            NumberFormat.compact(locale: 'id_ID').format(rod.toY).toLowerCase(),
                            TextStyle(
                              color: rod.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
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
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= totalMonths) return const SizedBox();
                            final date = DateTime(startDate.year, startDate.month + index, 1);
                            final monthName = DateFormat('MMMM', 'id_ID').format(date);
                            final year = date.year.toString();
                            
                            final values = monthlyValues[index];
                            final diff = values['saldo']! - values['hutang']!;
                            final hasData = values['saldo']! > 0 || values['hutang']! > 0;
                            
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                children: [
                                  Text(monthName, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500)),
                                  Text(year, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                                  if (hasData) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      shortFmt.format(diff).toLowerCase(),
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: diff < 0 ? const Color(0xFFFF3B30) : const Color(0xFF00B167),
                                      ),
                                    ),
                                  ],
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
        ),
      ],
    ),
  );
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
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
