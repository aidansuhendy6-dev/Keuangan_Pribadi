import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import '../../../services/finance_provider.dart';
import '../../../models/monthly_history_model.dart';

import 'balance_vs_debt_chart.dart';
import 'income_expense_bar_chart.dart';
import '../../../core/responsive.dart';

class ChartsSection extends StatelessWidget {
  const ChartsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    
    if (isMobile) {
      return Column(
        children: [
          _buildChartContainer(
            context,
            title: "Saldo Bulanan",
            subtitle: "2026",
            child: const BalanceBarChart(),
          ),
          const SizedBox(height: 24),
          const IncomeExpenseBarChart(),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Balance Chart (Bar)
        Expanded(
          child: _buildChartContainer(
            context,
            title: "Jumlah Saldo Bulanan",
            subtitle: "2026",
            child: const BalanceBarChart(),
          ),
        ),
        const SizedBox(width: 24),
        // Income vs Expense Chart (Bar)
        const Expanded(
          child: IncomeExpenseBarChart(),
        ),
      ],
    );
  }

  Widget _buildChartContainer(BuildContext context, {required String title, String? subtitle, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      height: 350,
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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: -0.5),
              ),
              if (subtitle != null)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(subtitle, style: const TextStyle(fontSize: 12)),
                        const Icon(Icons.keyboard_arrow_down, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class BalanceBarChart extends StatelessWidget {
  const BalanceBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final currentBalanceMillions = finance.totalBalance / 1000000;
    final now = DateTime.now();
    final currentMonthIndex = now.month - 1; 
    final isMobile = Responsive.isMobile(context);
    
    // Ambil data dari riwayat bulanan di database
    final Map<int, double> displayData = {};
    for (var h in finance.monthlyHistory) {
      if (h.year == now.year) {
        displayData[h.month - 1] = h.balance / 1000000;
      }
    }

    // Selalu tampilkan data real-time untuk bulan berjalan
    displayData[currentMonthIndex] = currentBalanceMillions;

    // Hitung maxY agar ada ruang di atas (tidak melewati teks judul)
    final double maxVal = displayData.values.isEmpty 
        ? 20 
        : displayData.values.reduce((curr, next) => curr > next ? curr : next);
    final double maxY = maxVal * 1.5; 

    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.white,
            tooltipBorder: const BorderSide(color: Colors.black12),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String month = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'][group.x.toInt()];
              double value = displayData[group.x.toInt()] ?? 0;
              if (value == 0) return null;
              return BarTooltipItem(
                "$month ${now.year}\n${fmt.format(value * 1000000)}",
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              getTitlesWidget: (value, meta) {
                const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
                final int index = value.toInt();
                if (index >= 0 && index < months.length) {
                  final isFutureMonth = index > currentMonthIndex;
                  double currentVal = displayData[index] ?? 0;
                  
                  Widget trendWidget = const SizedBox.shrink();
                  
                  // Tampilkan trend hanya jika bukan bulan depan.
                  // Khusus mobile, hanya tampilkan untuk bulan saat ini saja.
                  bool shouldShowTrend = !isFutureMonth;
                  if (isMobile && index != currentMonthIndex) {
                    shouldShowTrend = false;
                  }

                  if (shouldShowTrend) {
                    double prevVal = 0;
                    if (index > 0) {
                      prevVal = displayData[index - 1] ?? 0;
                    } else {
                      final desLastYear = finance.monthlyHistory.firstWhere(
                        (h) => h.year == now.year - 1 && h.month == 12,
                        orElse: () => MonthlyHistory(month: 12, year: now.year - 1, balance: 0, debt: 0),
                      );
                      prevVal = desLastYear.balance / 1000000;
                    }

                    double? percentage;
                    if (prevVal != 0) {
                      percentage = ((currentVal - prevVal) / prevVal.abs()) * 100;
                    } else if (currentVal > 0) {
                      percentage = 100.0;
                    }
                    
                    if (percentage != null) {
                      final bool isIncrease = percentage >= 0;
                      final Color trendColor = isIncrease ? const Color(0xFF00B167) : const Color(0xFFFF5252);
                      trendWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isIncrease ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            size: 10,
                            color: trendColor,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            "${percentage.abs().toStringAsFixed(1).replaceAll('.', ',')}%",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: trendColor,
                            ),
                          ),
                        ],
                      );
                    }
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 4,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          months[index],
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        trendWidget,
                      ],
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(12, (index) {
          final isCurrentMonth = index == currentMonthIndex;
          final isFutureMonth = index > currentMonthIndex;
          
          double value = displayData[index] ?? 0;
          if (isFutureMonth) value = 0; 

          Color barColor;
          if (index < currentMonthIndex) {
            double opacity = 0.2 + (0.8 * (index / currentMonthIndex));
            barColor = const Color(0xFF00B167).withOpacity(opacity);
          } else if (isCurrentMonth) {
            barColor = const Color(0xFF00B167);
          } else {
            barColor = const Color(0xFF00B167).withOpacity(0.05);
          }

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: value,
                color: barColor,
                width: 16,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }),
      ),
    );
  }
}
