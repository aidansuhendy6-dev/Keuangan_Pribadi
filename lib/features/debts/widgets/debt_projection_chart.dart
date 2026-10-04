import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';

class DebtProjectionChart extends StatelessWidget {
  final List<Debt> debts;
  final List<RecurringBill> recurringBills;

  const DebtProjectionChart({
    super.key,
    required this.debts,
    required this.recurringBills,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Generate 13 months (termasuk bulan lalu untuk perhitungan tren)
    final now = DateTime.now();
    final months = List.generate(13, (index) {
      // Index 0 adalah bulan lalu, Index 1 adalah bulan sekarang, dst.
      return DateTime(now.year, now.month + index - 1, 1);
    });

    // 2. Prepare data for Spaylater [SP] and BCA [BCA]
    final List<double> spData = List.filled(13, 0.0);
    final List<double> bcaData = List.filled(13, 0.0);

    // Process Debts (One-time)
    for (var debt in debts) {
      if (debt.dueDate == null) continue;
      final category = _getCategory(debt.name);
      if (category == null) continue;

      for (int i = 0; i < 13; i++) {
        if (debt.dueDate!.year == months[i].year && debt.dueDate!.month == months[i].month) {
          if (category == 'SP') {
            spData[i] += debt.remainingAmount;
          } else {
            bcaData[i] += debt.remainingAmount;
          }
        }
      }
    }

    // Process Recurring Bills (Installments)
    for (var bill in recurringBills) {
      final category = _getCategory(bill.name);
      if (category == null) continue;

      if (bill.isInstallment) {
        int remaining = bill.remainingTenor;
        DateTime nextDue = bill.nextDueDate;
        
        for (int t = 0; t < remaining; t++) {
          int targetMonth = nextDue.month + t;
          int targetYear = nextDue.year + (targetMonth - 1) ~/ 12;
          targetMonth = (targetMonth - 1) % 12 + 1;
          
          for (int i = 0; i < 13; i++) {
            if (targetYear == months[i].year && targetMonth == months[i].month) {
              if (category == 'SP') {
                spData[i] += bill.amount;
              } else {
                bcaData[i] += bill.amount;
              }
            }
          }
        }
      } else {
        // Simple monthly bill - show for all 13 months if it's active
        for (int i = 0; i < 13; i++) {
          if (category == 'SP') {
            spData[i] += bill.amount;
          } else {
            bcaData[i] += bill.amount;
          }
        }
      }
    }

    // 3. Find Max for Y-axis (Hanya hitung indeks 1 sampai 12 untuk batas grafik yang terlihat)
    double maxVal = 0;
    for (int i = 1; i < 13; i++) {
      if (spData[i] > maxVal) maxVal = spData[i];
      if (bcaData[i] > maxVal) maxVal = bcaData[i];
    }
    maxVal = maxVal == 0 ? 1000000 : maxVal * 1.2;

    // Deteksi jika ukuran layar sempit (mobile)
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          // Header yang adaptif terhadap mobile/desktop
          if (!isMobile) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bar_chart, color: Color(0xFFFF5C5C), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Proyeksi Pelunasan Hutang",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        "Perbandingan Hutang Spaylater (Shopee) dan Kartu Kredit (BCA)",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.4),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Legend versi Desktop (Samping)
                _buildLegend(isVertical: false),
              ],
            ),
          ] else ...[
            // Header versi Mobile (Hanya menampilkan legend atas bawah, menyembunyikan judul)
            Center(
              child: _buildLegend(isVertical: true),
            ),
          ],
          SizedBox(height: isMobile ? 16 : 32),
          // Chart
          LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = math.max(constraints.maxWidth, 800.0);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  height: 350,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxVal,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => Colors.transparent,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: EdgeInsets.zero,
                          tooltipMargin: 4,
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            if (rod.toY == 0) return null;
                            return BarTooltipItem(
                              _formatCurrency(rod.toY),
                              TextStyle(
                                color: rod.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
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
                            reservedSize: 85,
                            getTitlesWidget: (value, meta) {
                              // Sesuaikan index: value dari grafik (0..11) dipetakan ke months[1..12]
                              final visibleIndex = value.toInt() + 1;
                              if (visibleIndex < 1 || visibleIndex >= 13) return const SizedBox();
                              
                              // Hitung persentase tren (Bulan ini vs Bulan sebelumnya)
                              final currentTotal = spData[visibleIndex] + bcaData[visibleIndex];
                              Widget trendWidget = const SizedBox.shrink();
                              
                              // Data bulan sebelumnya tersedia di visibleIndex - 1
                              final prevTotal = spData[visibleIndex - 1] + bcaData[visibleIndex - 1];
                              if (prevTotal > 0) {
                                final percentage = ((currentTotal - prevTotal) / prevTotal) * 100;
                                final bool isIncrease = percentage >= 0;
                                final Color trendColor = isIncrease ? const Color(0xFFFF5252) : const Color(0xFF00B167);
                                
                                trendWidget = Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
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
                                  ),
                                );
                              }

                              return SideTitleWidget(
                                meta: meta,
                                space: 10,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      DateFormat('MMMM\nyyyy', 'id_ID').format(months[visibleIndex]),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Colors.black.withOpacity(0.4),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trendWidget,
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
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(12, (index) {
                        final dataIndex = index + 1; // Mengambil data dari bulan sekarang (1) ke depan
                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: spData[dataIndex],
                              color: const Color(0xFFFF6633),
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            BarChartRodData(
                              toY: bcaData[dataIndex],
                              color: const Color(0xFF0088FF),
                              width: 22,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                          showingTooltipIndicators: spData[dataIndex] > 0 || bcaData[dataIndex] > 0 
                              ? [if (spData[dataIndex] > 0) 0, if (bcaData[dataIndex] > 0) 1] 
                              : [],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String? _getCategory(String name) {
    if (name.startsWith('[SP]')) return 'SP';
    if (name.startsWith('[BCA]')) return 'BCA';
    return null;
  }

  Widget _buildLegend({required bool isVertical}) {
    if (isVertical) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLegendItem("Spaylater (Shopee)", const Color(0xFFFF6633)),
          const SizedBox(height: 8),
          _buildLegendItem("Kartu Kredit (BCA)", const Color(0xFF0088FF)),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildLegendItem("Spaylater (Shopee)", const Color(0xFFFF6633)),
        const SizedBox(width: 16),
        _buildLegendItem("Kartu Kredit (BCA)", const Color(0xFF0088FF)),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double value) {
    if (value == 0) return "0";
    if (value >= 1000000) {
      double millionValue = value / 1000000;
      // Gunakan toStringAsFixed(1) untuk mendapatkan maksimal 1 angka di belakang koma
      String formatted = millionValue.toStringAsFixed(1);
      
      // Jika diakhiri dengan .0 atau ,0, hapus bagian komanya agar menjadi bilangan bulat
      if (formatted.endsWith('.0')) {
        formatted = formatted.substring(0, formatted.length - 2);
      }
      
      // Ubah titik desimal menjadi koma sesuai standar Indonesia
      formatted = formatted.replaceAll('.', ',');
      return "$formatted jt";
    } else if (value >= 1000) {
      return "${(value / 1000).toStringAsFixed(0)}K";
    }
    return value.toStringAsFixed(0);
  }
}
