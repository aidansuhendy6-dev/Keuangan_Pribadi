import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/responsive.dart';
import '../../services/navigation_provider.dart';
import '../../services/finance_provider.dart';
import 'widgets/ios_3d_pie_chart.dart';

enum ChartType { income, expense, net }

class IncomeExpenseDetailScreen extends StatefulWidget {
  const IncomeExpenseDetailScreen({super.key});

  @override
  State<IncomeExpenseDetailScreen> createState() => _IncomeExpenseDetailScreenState();
}

class _IncomeExpenseDetailScreenState extends State<IncomeExpenseDetailScreen> {
  int _selectedMonthIndex = 0;
  final List<String> _months = ['Sep 26', 'Okt 26', 'Nov 26', 'Des 26', 'Jan 27', 'Feb 27', 'Mar 27', 'Apr 27', 'Mei 27', 'Jun 27', 'Jul 27', 'Agu 27'];
  final List<String> _monthKeys = ['2026-09', '2026-10', '2026-11', '2026-12', '2027-01', '2027-02', '2027-03', '2027-04', '2027-05', '2027-06', '2027-07', '2027-08'];
  final List<String> _fullMonthNames = ['September 2026', 'Oktober 2026', 'November 2026', 'Desember 2026', 'Januari 2027', 'Februari 2027', 'Maret 2027', 'April 2027', 'Mei 2027', 'Juni 2027', 'Juli 2027', 'Agustus 2027'];

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    final currentKey = _monthKeys[_selectedMonthIndex];
    final details = finance.getCustomMonthlyDetails(currentKey);

    // Hitung indeks bulan yang tersedia (dari Sep 2026 sampai sekarang)
    final now = DateTime.now();
    final currentKeyStr = DateFormat('yyyy-MM').format(now);
    final List<int> availableIndices = [];
    for (int i = 0; i < _monthKeys.length; i++) {
      if (_monthKeys[i].compareTo(currentKeyStr) <= 0) {
        availableIndices.add(i);
      }
    }

    return WillPopScope(
      onWillPop: () async {
        context.read<NavigationProvider>().setMenu(SidebarMenu.dashboard);
        return false;
      },
      child: Padding(
        padding: isMobile ? const EdgeInsets.all(16.0) : const EdgeInsets.all(40.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button and Title
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.read<NavigationProvider>().setMenu(SidebarMenu.dashboard),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Detail Pemasukan & Pengeluaran",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontSize: isMobile ? 20 : 28,
                          letterSpacing: -0.5,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Gaji Section
              if (isMobile) ...[
                _buildChartCard(finance: finance, title: "Gaji", type: ChartType.income, availableIndices: availableIndices),
                const SizedBox(height: 16),
                _buildSourceCard(finance: finance, details: details, fmt: fmt, monthName: _fullMonthNames[_selectedMonthIndex], monthKey: currentKey, availableIndices: availableIndices),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildChartCard(finance: finance, title: "Gaji", type: ChartType.income, availableIndices: availableIndices)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildSourceCard(finance: finance, details: details, fmt: fmt, monthName: _fullMonthNames[_selectedMonthIndex], monthKey: currentKey, availableIndices: availableIndices)),
                  ],
                ),

              const SizedBox(height: 24),

              // Biaya Hidup Section
              if (isMobile) ...[
                _buildChartCard(finance: finance, title: "Biaya Hidup", type: ChartType.expense, availableIndices: availableIndices),
                const SizedBox(height: 16),
                _buildSpentCard(finance: finance, details: details, fmt: fmt, monthName: _fullMonthNames[_selectedMonthIndex], monthKey: currentKey, availableIndices: availableIndices),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildChartCard(finance: finance, title: "Biaya Hidup", type: ChartType.expense, availableIndices: availableIndices)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildSpentCard(finance: finance, details: details, fmt: fmt, monthName: _fullMonthNames[_selectedMonthIndex], monthKey: currentKey, availableIndices: availableIndices)),
                  ],
                ),

              const SizedBox(height: 24),

              // Sisa Gaji Bersih Section
              if (isMobile) ...[
                _buildChartCard(finance: finance, title: "Sisa Gaji Bersih", type: ChartType.net, availableIndices: availableIndices, height: 220),
                const SizedBox(height: 16),
                _buildNetCashFlowCard(details: details, fmt: fmt, monthName: _fullMonthNames[_selectedMonthIndex], availableIndices: availableIndices),
              ] else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildChartCard(finance: finance, title: "Sisa Gaji Bersih", type: ChartType.net, availableIndices: availableIndices, height: 220)),
                    const SizedBox(width: 24),
                    Expanded(flex: 1, child: _buildNetCashFlowCard(details: details, fmt: fmt, monthName: _fullMonthNames[_selectedMonthIndex], availableIndices: availableIndices)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({required FinanceProvider finance, required String title, required ChartType type, required List<int> availableIndices, double height = 320}) {
    // Generate rods for all 12 months
    List<BarChartGroupData> barGroups = [];
    double maxVal = 0.5; // Start with small value for better auto-scaling
    double minVal = 0.0;
    
    final now = DateTime.now();
    final currentKeyStr = DateFormat('yyyy-MM').format(now);

    for (int i = 0; i < _monthKeys.length; i++) {
      final key = _monthKeys[i];
      final data = finance.getCustomMonthlyDetails(key);
      double val;
      
      // Sembunyikan batang untuk bulan mendatang
      final isFuture = key.compareTo(currentKeyStr) > 0;

      final income = data['gaji_pokok']! + data['tunjangan']! + data['bonus']! + data['lain_lain_sumber']!;
      final expense = data['belanja_istri']! + data['sewa_kost']! + data['konsumtif']! + data['lain_lain_dihabiskan']!;

      if (type == ChartType.income) {
        val = income;
      } else if (type == ChartType.expense) {
        val = expense;
      } else {
        val = income - expense;
      }
      
      if (isFuture) val = 0;

      double displayVal = val / 1000000.0; // In Millions for display
      if (displayVal.abs() > maxVal) maxVal = displayVal.abs();
      if (displayVal < minVal) minVal = displayVal;
      
      Color barColor;
      if (type == ChartType.income) {
        barColor = const Color(0xFF34C759); // Apple Green
      } else if (type == ChartType.expense) {
        barColor = const Color(0xFFFF3A30); // Apple Red
      } else {
        barColor = val < 0 ? const Color(0xFFFF3A30) : const Color(0xFF34C759); // Red if deficit, Green if surplus
      }

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: displayVal,
              color: i == _selectedMonthIndex 
                  ? barColor
                  : barColor.withOpacity(0.3),
              width: 28, // Disamakan ketebalannya menjadi 28 agar seragam di semua kartu diagram
              borderRadius: BorderRadius.circular(4), // Fully rounded corners
            ),
          ],
        ),
      );
    }

    final isMobile = Responsive.isMobile(context);

    return Container(
      height: height,
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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black, letterSpacing: -0.5),
              ),
              PopupMenuButton<int>(
                onSelected: (index) => setState(() => _selectedMonthIndex = index),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.98),
                elevation: 8,
                offset: const Offset(0, 45),
                itemBuilder: (context) => availableIndices.map((index) => PopupMenuItem(
                  value: index,
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined, 
                        size: 14, 
                        color: index == _selectedMonthIndex 
                            ? (type == ChartType.expense ? const Color(0xFFFF3A30) : const Color(0xFF34C759)) 
                            : Colors.grey
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _fullMonthNames[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: index == _selectedMonthIndex ? FontWeight.w600 : FontWeight.normal,
                          color: index == _selectedMonthIndex 
                              ? (type == ChartType.expense ? const Color(0xFFFF3A30) : const Color(0xFF34C759)) 
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text("History 12 Bulan", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black54)),
                      const SizedBox(width: 4),
                      const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: isMobile 
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: _monthKeys.length * 75.0, // Ditingkatkan ke 75.0 agar jarak antar bulan renggang, lega, dan nyaman di-scroll pada mobile
                    child: _buildBarChart(finance, type, barGroups, currentKeyStr, maxVal, minVal),
                  ),
                )
              : _buildBarChart(finance, type, barGroups, currentKeyStr, maxVal, minVal),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(FinanceProvider finance, ChartType type, List<BarChartGroupData> barGroups, String currentKeyStr, double maxVal, double minVal) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceEvenly,
        maxY: type == ChartType.net ? maxVal * 1.1 : (maxVal * 1.5).ceilToDouble(),
        minY: type == ChartType.net ? (minVal < 0 ? -maxVal * 1.1 : 0.0) : 0.0,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response != null && response.spot != null) {
              setState(() => _selectedMonthIndex = response.spot!.touchedBarGroupIndex);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final key = _monthKeys[groupIndex];
              
              if (key.compareTo(currentKeyStr) > 0) return null;

              final data = finance.getCustomMonthlyDetails(key);
              double rawVal;
              final income = data['gaji_pokok']! + data['tunjangan']! + data['bonus']! + data['lain_lain_sumber']!;
              final expense = data['belanja_istri']! + data['sewa_kost']! + data['konsumtif']! + data['lain_lain_dihabiskan']!;

              if (type == ChartType.income) {
                rawVal = income;
              } else if (type == ChartType.expense) {
                rawVal = expense;
              } else {
                rawVal = income - expense;
              }

              if (rawVal == 0) return null;

              Color tooltipColor;
              if (type == ChartType.income) {
                tooltipColor = const Color(0xFF34C759);
              } else if (type == ChartType.expense) {
                tooltipColor = const Color(0xFFFF3A30);
              } else {
                tooltipColor = rawVal < 0 ? const Color(0xFFFF3A30) : const Color(0xFF34C759);
              }

              return BarTooltipItem(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(rawVal),
                TextStyle(
                  color: tooltipColor,
                  fontWeight: FontWeight.bold,
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
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < _monthKeys.length) {
                  final currentKey = _monthKeys[index];
                  final isFuture = currentKey.compareTo(currentKeyStr) > 0;
                  
                  Widget diffWidget = const SizedBox();
                  
                  if (!isFuture && index > 0) {
                    final prevKey = _monthKeys[index - 1];
                    final currentData = finance.getCustomMonthlyDetails(currentKey);
                    final prevData = finance.getCustomMonthlyDetails(prevKey);
                    
                    double currentVal, prevVal;
                    final currentIncome = currentData['gaji_pokok']! + currentData['tunjangan']! + currentData['bonus']! + currentData['lain_lain_sumber']!;
                    final currentExpense = currentData['belanja_istri']! + currentData['sewa_kost']! + currentData['konsumtif']! + currentData['lain_lain_dihabiskan']!;
                    final prevIncome = prevData['gaji_pokok']! + prevData['tunjangan']! + prevData['bonus']! + prevData['lain_lain_sumber']!;
                    final prevExpense = prevData['belanja_istri']! + prevData['sewa_kost']! + prevData['konsumtif']! + prevData['lain_lain_dihabiskan']!;

                    if (type == ChartType.income) {
                      currentVal = currentIncome;
                      prevVal = prevIncome;
                    } else if (type == ChartType.expense) {
                      currentVal = currentExpense;
                      prevVal = prevExpense;
                    } else {
                      currentVal = currentIncome - currentExpense;
                      prevVal = prevIncome - prevExpense;
                    }

                    final diff = currentVal - prevVal;
                    
                    double percentChange = 0;
                    if (prevVal != 0) {
                      percentChange = (diff / prevVal.abs()) * 100;
                    } else if (currentVal != 0) {
                      percentChange = currentVal > 0 ? 100 : -100;
                    }
                    
                    final absPercent = percentChange.abs().toStringAsFixed(1).replaceAll('.', ',');
                    
                    if (percentChange != 0) {
                      bool isGood;
                      if (type == ChartType.income || type == ChartType.net) {
                        isGood = percentChange > 0;
                      } else {
                        isGood = percentChange < 0; // Penurunan pengeluaran itu bagus
                      }

                      diffWidget = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            percentChange > 0 ? Icons.trending_up : Icons.trending_down,
                            size: 10,
                            color: isGood ? const Color(0xFF34C759) : const Color(0xFFFF3A30),
                          ),
                          const SizedBox(width: 2),
                          Text(
                            "$absPercent%",
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isGood ? const Color(0xFF34C759) : const Color(0xFFFF3A30),
                            ),
                          ),
                        ],
                      );
                    }
                  }

                  return SideTitleWidget(
                    meta: meta,
                    space: 10, // Memberikan jarak nafas agar tidak mepet/sesak dengan batang
                    child: SizedBox(
                      height: 40,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            _fullMonthNames[index],
                            style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 10,
                            child: diffWidget,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: barGroups.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final key = _monthKeys[groupIndex];
          final isFuture = key.compareTo(currentKeyStr) > 0;
          
          return entry.value.copyWith(
            showingTooltipIndicators: isFuture ? [] : [0],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSourceCard({required FinanceProvider finance, required Map<String, double> details, required NumberFormat fmt, required String monthName, required String monthKey, required List<int> availableIndices}) {
    double total = details['gaji_pokok']! + details['tunjangan']! + details['bonus']! + details['lain_lain_sumber']!;
    
    return Container(
      height: 320,
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
              const Text("Sumber", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
              PopupMenuButton<int>(
                onSelected: (index) => setState(() => _selectedMonthIndex = index),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.98),
                elevation: 8,
                offset: const Offset(0, 25),
                itemBuilder: (context) => availableIndices.map((index) => PopupMenuItem(
                  value: index,
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined, 
                        size: 14, 
                        color: index == _selectedMonthIndex ? const Color(0xFF34C759) : Colors.grey
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _fullMonthNames[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: index == _selectedMonthIndex ? FontWeight.w600 : FontWeight.normal,
                          color: index == _selectedMonthIndex ? const Color(0xFF34C759) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(monthName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditableRow(context, finance, "Gaji Pokok", details['gaji_pokok']!, 'gaji_pokok', monthKey, fmt),
          _buildEditableRow(context, finance, "Tunjangan", details['tunjangan']!, 'tunjangan', monthKey, fmt),
          _buildEditableRow(context, finance, "Bonus", details['bonus']!, 'bonus', monthKey, fmt),
          _buildEditableRow(context, finance, "Lain-lain", details['lain_lain_sumber']!, 'lain_lain_sumber', monthKey, fmt),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              fmt.format(total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF34C759)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpentCard({required FinanceProvider finance, required Map<String, double> details, required NumberFormat fmt, required String monthName, required String monthKey, required List<int> availableIndices}) {
    double total = details['belanja_istri']! + details['sewa_kost']! + details['konsumtif']! + details['lain_lain_dihabiskan']!;

    return Container(
      height: 320,
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
              const Text("Dihabiskan", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
              PopupMenuButton<int>(
                onSelected: (index) => setState(() => _selectedMonthIndex = index),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                color: Colors.white.withOpacity(0.98),
                elevation: 8,
                offset: const Offset(0, 25),
                itemBuilder: (context) => availableIndices.map((index) => PopupMenuItem(
                  value: index,
                  height: 40,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined, 
                        size: 14, 
                        color: index == _selectedMonthIndex ? const Color(0xFFFF3A30) : Colors.grey
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _fullMonthNames[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: index == _selectedMonthIndex ? FontWeight.w600 : FontWeight.normal,
                          color: index == _selectedMonthIndex ? const Color(0xFFFF3A30) : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.black54),
                        const SizedBox(width: 6),
                        Text(monthName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildEditableRow(context, finance, "Belanja Istri", details['belanja_istri']!, 'belanja_istri', monthKey, fmt),
          _buildEditableRow(context, finance, "Sewa Kost", details['sewa_kost']!, 'sewa_kost', monthKey, fmt),
          _buildEditableRow(context, finance, "Konsumtif", details['konsumtif']!, 'konsumtif', monthKey, fmt),
          _buildEditableRow(context, finance, "Lain-lain", details['lain_lain_dihabiskan']!, 'lain_lain_dihabiskan', monthKey, fmt),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              fmt.format(total),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFFFF3A30)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetCashFlowCard({required Map<String, double> details, required NumberFormat fmt, required String monthName, required List<int> availableIndices}) {
    double income = details['gaji_pokok']! + details['tunjangan']! + details['bonus']! + details['lain_lain_sumber']!;
    double expense = details['belanja_istri']! + details['sewa_kost']! + details['konsumtif']! + details['lain_lain_dihabiskan']!;
    double net = income - expense;

    return Container(
      height: 220, // Ketinggian tetap sejajar dengan kartu diagram
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
          const Text("Sisa Gaji Bersih", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.5)),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 10), // Memberikan sedikit jarak dari tepi kanan agar sejajar dengan nominal
                child: Ios3dPieChart(
                  sisaBonus: net,
                  totalExpense: expense,
                  size: 120,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              fmt.format(net),
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                fontSize: 28, 
                color: net < 0 ? const Color(0xFFFF3A30) : const Color(0xFF34C759),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(BuildContext context, FinanceProvider finance, String label, double value, String field, String monthKey, NumberFormat fmt) {
    final bool isAutoSyncField = field == 'bonus' || field == 'konsumtif';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 14)),
          if (isAutoSyncField)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                fmt.format(value),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
              ),
            )
          else
            InkWell(
              onTap: () => _showEditDialog(context, finance, label, value, field, monthKey),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  fmt.format(value),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, FinanceProvider finance, String label, double currentValue, String field, String monthKey) {
    final controller = TextEditingController(text: currentValue.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit $label",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: -0.5,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Masukkan nominal baru untuk kategori ini.",
                  style: TextStyle(fontSize: 13, color: Colors.black.withOpacity(0.5)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                  decoration: InputDecoration(
                    prefixText: 'Rp ',
                    prefixStyle: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                    hintText: '0',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Batal", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final newValue = double.tryParse(controller.text) ?? 0.0;
                          finance.updateCustomMonthlyNominal(monthKey, field, newValue);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34C759),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
