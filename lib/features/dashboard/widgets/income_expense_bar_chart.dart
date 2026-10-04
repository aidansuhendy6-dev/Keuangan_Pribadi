import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';
import '../../../services/navigation_provider.dart';

class IncomeExpenseBarChart extends StatelessWidget {
  const IncomeExpenseBarChart({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final shortFmt = NumberFormat.compact(locale: 'id_ID');

    final now = DateTime.now();
    // Tampilkan data mulai dari September 2026 sebagai titik awal
    final startDate = DateTime(2026, 9, 1); 
    // Proyeksikan/tampilkan slot kosong hingga 12 bulan ke depan agar layout grafik tidak kosong di depan
    final endDate = DateTime(now.year, now.month + 11, 1);
    
    // Hitung total bulan untuk ditampilkan
    final totalMonths = ((endDate.year - startDate.year) * 12) + endDate.month - startDate.month + 1;
    
    List<BarChartGroupData> barGroups = [];
    List<Map<String, double>> monthlyValues = [];
    
    for (int i = 0; i < totalMonths; i++) {
      final date = DateTime(startDate.year, startDate.month + i, 1);
      
      // Cek apakah bulan mendatang
      final isFuture = date.year > now.year || (date.year == now.year && date.month > now.month);

      double income = _getMonthlyAmount(finance, 'income', date);
      double expense = _getMonthlyAmount(finance, 'expense', date);
      
      if (isFuture) {
        income = 0;
        expense = 0;
      }

      monthlyValues.add({'income': income, 'expense': expense});

      barGroups.add(
        BarChartGroupData(
          x: i,
          barsSpace: 8,
          barRods: [
            BarChartRodData(
              toY: income,
              color: const Color(0xFF34C759), // Apple System Green (Mewah & Elegan)
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
            BarChartRodData(
              toY: expense,
              color: const Color(0xFFFF3A30), // Apple System Red (Mewah & Elegan)
              width: 16,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
          showingTooltipIndicators: (income > 0 || expense > 0) ? [0, 1] : [],
        ),
      );
    }

    // Hitung maxY dinamis untuk skala chart
    double maxVal = 5000000.0; 
    for (var val in monthlyValues) {
      if (val['income']! > maxVal) maxVal = val['income']!;
      if (val['expense']! > maxVal) maxVal = val['expense']!;
    }
    final double maxY = (maxVal / 5000000).ceil() * 5000000.0; 

    // Hitung lebar dinamis: tiap bulan butuh sekitar 80px
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
      height: 350, // Tetap 350
        child: GestureDetector(
          onTap: () => context.read<NavigationProvider>().setMenu(SidebarMenu.incomeExpenseDetail),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Pemasukan vs Pengeluaran",
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
                        Text("History 12 Bulan", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildLegend(const Color(0xFF34C759), "Pemasukan"),
                  const SizedBox(width: 16),
                  _buildLegend(const Color(0xFFFF3A30), "Pengeluaran"),
                ],
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: chartWidth < 900 ? 900 : chartWidth, // Tingkatkan lebar minimum agar ada ruang dan scroll aktif
                    child: Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 16.0), // Beri padding kiri kanan di dalam chart agar teks tidak terpotong
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.start,
                          groupsSpace: 40,
                          maxY: maxY,
                          barTouchData: BarTouchData(
                            enabled: true,
                            touchCallback: (FlTouchEvent event, barTouchResponse) {
                              if (!event.isInterestedForInteractions ||
                                  barTouchResponse == null ||
                                  barTouchResponse.spot == null) {
                                return;
                              }
                              
                              if (event is FlTapUpEvent) {
                                final groupIndex = barTouchResponse.spot!.touchedBarGroupIndex;
                                final rodIndex = barTouchResponse.spot!.touchedRodDataIndex;
                                final date = DateTime(startDate.year, startDate.month + groupIndex, 1);
                                final type = rodIndex == 0 ? 'income' : 'expense';
                                
                                _showTransactionDetails(context, finance, type, date);
                              }
                            },
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipColor: (_) => Colors.transparent,
                              tooltipPadding: EdgeInsets.zero,
                              tooltipMargin: 8,
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                if (rod.toY == 0) return null;
                                return BarTooltipItem(
                                  shortFmt.format(rod.toY).toLowerCase(),
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
                                  final diff = values['income']! - values['expense']!;
                                  final hasData = values['income']! > 0 || values['expense']! > 0;
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
                                              color: diff < 0 ? const Color(0xFFFF3A30) : const Color(0xFF34C759),
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
                            border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
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
        ),
      );
    }





  double _getMonthlyAmount(FinanceProvider finance, String type, DateTime date) {
    return _getMonthlyTransactions(finance, type, date).fold(0.0, (sum, t) => sum + t.amount);
  }

  List<dynamic> _getMonthlyTransactions(FinanceProvider finance, String type, DateTime date) {
    return finance.transactions.where((t) {
      if (t.type != type) return false;
      if (t.date.year != date.year || t.date.month != date.month) return false;
      
      if (type == 'income') {
        final wallet = finance.wallets.where((w) => w.id == t.categoryId).firstOrNull;
        return wallet != null && ['BCA', 'Shopeepay', 'Cash'].contains(wallet.name);
      } else {
        if (t.categoryType == 'wallet') {
          final wallet = finance.wallets.where((w) => w.id == t.categoryId).firstOrNull;
          return wallet != null && ['BCA', 'Shopeepay', 'Cash'].contains(wallet.name);
        } else if (t.categoryType == 'debt') {
          final debt = finance.debts.where((d) => d.id == t.categoryId).firstOrNull;
          return debt != null && debt.name == 'Kartu Kredit BCA';
        }
      }
      return false;
    }).toList();
  }

  void _showTransactionDetails(BuildContext context, FinanceProvider finance, String type, DateTime date) {
    final list = _getMonthlyTransactions(finance, type, date);
    final monthLabel = DateFormat('MMMM yyyy', 'id_ID').format(date);
    final title = type == 'income' ? "Rincian Pemasukan ($monthLabel)" : "Rincian Pengeluaran ($monthLabel)";
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: 400,
            height: 300,
            child: list.isEmpty
                ? const Center(child: Text("Tidak ada transaksi pada bulan ini.", style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final t = list[index];
                      String subtitle = DateFormat('dd MMM yyyy', 'id_ID').format(t.date);
                      
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.description.isEmpty ? (type == 'income' ? 'Pemasukan' : 'Pengeluaran') : t.description),
                        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: Text(
                          currencyFmt.format(t.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: type == 'income' ? const Color(0xFF34C759) : const Color(0xFFFF3A30),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            ),
          ],
        );
      },
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
