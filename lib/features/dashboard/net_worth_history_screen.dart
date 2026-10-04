import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/responsive.dart';
import '../../services/navigation_provider.dart';
import '../../services/finance_provider.dart';
import '../../models/monthly_history_model.dart';

class NetWorthHistoryScreen extends StatefulWidget {
  const NetWorthHistoryScreen({super.key});

  @override
  State<NetWorthHistoryScreen> createState() => _NetWorthHistoryScreenState();
}

class _NetWorthHistoryScreenState extends State<NetWorthHistoryScreen> {
  static const Color _green = Color(0xFF34C759);
  static const Color _red = Color(0xFFFF3B30);
  static const Color _textPrimary = Color(0xFF171717);
  static const Color _textSecondary = Color(0xFF8A8A8A);

  late ScrollController _chartScrollController;

  @override
  void initState() {
    super.initState();
    _chartScrollController = ScrollController();
    
    // Auto-scroll ke data terbaru (kanan) setelah widget dibangun
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScrollController.hasClients) {
        _chartScrollController.animateTo(
          _chartScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutQuad,
        );
      }
    });
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  final NumberFormat _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final finance = context.watch<FinanceProvider>();
    final now = DateTime.now();

    // ================================================================
    // PERIODE CHART
    // Dinamis: Dimulai dari Agustus 2026.
    // Menampilkan minimal 12 bulan atau sampai bulan berjalan + 1 buffer.
    // ================================================================
    final DateTime start = DateTime(2026, 8, 1);
    int monthsPassed = ((now.year - start.year) * 12) + now.month - start.month;
    
    // Tampilkan minimal 12 bulan (Ags 2026 - Jul 2027) 
    // Jika waktu berjalan melewati Jul 2027, maka chart akan bertambah otomatis.
    int displayCount = (monthsPassed < 11) ? 12 : monthsPassed + 2;

    final List<DateTime> months = List<DateTime>.generate(
      displayCount,
      (index) => DateTime(start.year, start.month + index, 1),
    );

    final String startLabel = DateFormat('MMMM yyyy', 'id_ID').format(months.first);
    final String endLabel = DateFormat('MMMM yyyy', 'id_ID').format(months.last);
    
    // Hitung durasi bulan dan tahun untuk teks tanda kurung
    int totalMonths = months.length;
    String durationLabel = '';
    if (totalMonths < 12) {
      durationLabel = ' ($totalMonths Bulan)';
    } else {
      int years = totalMonths ~/ 12;
      int remMonths = totalMonths % 12;
      if (remMonths == 0) {
        durationLabel = ' ($years Tahun)';
      } else {
        durationLabel = ' ($years Tahun $remMonths Bulan)';
      }
    }
    
    final String rangeLabel = '$startLabel — $endLabel$durationLabel';

    // ================================================================
    // AMBIL NET WORTH
    //
    // null = belum ada data.
    // Bulan tanpa data tidak akan dibuatkan batang.
    // ================================================================
    double? getNetWorth(DateTime date) {
      // Bulan berjalan menggunakan data aktual.
      if (date.year == now.year && date.month == now.month) {
        return finance.totalBalance - finance.totalDebt;
      }

      final MonthlyHistory history = finance.monthlyHistory.firstWhere(
            (h) => h.month == date.month && h.year == date.year,
        orElse: () => MonthlyHistory(
          month: 0,
          year: 0,
          balance: -1,
          debt: -1,
        ),
      );

      if (history.balance != -1 && history.debt != -1) {
        return history.balance - history.debt;
      }

      return null;
    }

    // ================================================================
    // DATA CHART
    // Satuan juta rupiah.
    // ================================================================
    final List<double?> values = months.map((month) {
      final double? netWorth = getNetWorth(month);

      if (netWorth == null) {
        return null;
      }

      return netWorth / 1000000.0;
    }).toList();

    final List<double> existingValues =
    values.whereType<double>().toList();

    double maxValue;

    double minValue;

    if (existingValues.isEmpty) {
      maxValue = 1.0;
      minValue = -1.0;
    } else {
      maxValue = existingValues.reduce(
            (a, b) => a > b ? a : b,
      );

      minValue = existingValues.reduce(
            (a, b) => a < b ? a : b,
      );
    }

    // ================================================================
    // PADDING CHART
    // Memberi ruang supaya batang dan label tidak terlalu mepet.
    // ================================================================
    final double range = (maxValue - minValue).abs();

    final double padding = range == 0
        ? 2.0
        : range * 0.28;

    double maxY = maxValue + padding;
    
    // Berikan padding yang lebih lega di bawah jika ada nilai negatif untuk menampung label nominal
    final bool hasNegative = existingValues.any((v) => v < 0);
    double bottomPadding = range == 0 
        ? 0.1 
        : (hasNegative ? range * 0.18 : range * 0.05);
    double minY = minValue - bottomPadding;

    // Garis 0 selalu masuk ke area chart.
    if (maxY <= 0) {
      maxY = padding;
    }

    if (minY >= 0) {
      // Jika semua grafik positif, pasang nilai tepat di 0 
      // agar tidak ada jarak kosong di bawah garis 0
      minY = 0; 
    }

    // ================================================================
    // BAR GROUPS
    // ================================================================
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < months.length; i++) {
      final double? value = values[i];

      // Belum ada data.
      if (value == null) {
        barGroups.add(
          BarChartGroupData(
            x: i,
            barRods: const [],
          ),
        );

        continue;
      }

      final double netWorth = value * 1000000;

      final bool isNegative = netWorth < 0;

      barGroups.add(
        BarChartGroupData(
          x: i,
          showingTooltipIndicators: const [0],
          barRods: [
            BarChartRodData(
              // Selalu gambar dari 0 ke value agar label (tooltip) muncul di ujung batang.
              // Jika minus, toY akan berada di bawah 0 (label di bawah).
              // Jika surplus, toY akan berada di atas 0 (label di atas).
              fromY: 0,
              toY: value,
              width: isMobile ? 24 : 30,
              color: isNegative ? _red : _green,
              borderRadius: isNegative
                  ? const BorderRadius.vertical(bottom: Radius.circular(7))
                  : const BorderRadius.vertical(top: Radius.circular(7)),
            ),
          ],
        ),
      );
    }

    // ================================================================
    // UKURAN CHART
    // ================================================================
    // Lebar chart minimal per bulan agar tidak terlalu rapat.
    final double minWidthPerMonth = isMobile ? 90.0 : 120.0;
    final double minTotalWidth = months.length * minWidthPerMonth;

    final double chartHeight = isMobile ? 390.0 : 410.0;

    // ======================================================
    // HEADER
    // ======================================================
    final header = Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            tooltip: 'Kembali',
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: _textPrimary,
            ),
            onPressed: () {
              context.read<NavigationProvider>().setMenu(SidebarMenu.dashboard);
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Riwayat Kekayaan Bersih',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                  fontSize: isMobile ? 21 : 28,
                  letterSpacing: -0.7,
                ),
          ),
        ),
      ],
    );

    // ==================================================
    // CHART WIDGET
    // ==================================================
    final chartWidget = LayoutBuilder(
      builder: (context, constraints) {
        // Jika di desktop, kita ingin minimal 12 bulan tampil memenuhi lebar card.
        // Jadi kita ambil yang mana yang lebih besar antara lebar kontainer 
        // atau lebar minimal berdasarkan jumlah bulan.
        final double chartWidth = minTotalWidth > constraints.maxWidth 
            ? minTotalWidth 
            : constraints.maxWidth;

        return SizedBox(
          height: isMobile ? chartHeight : constraints.maxHeight,
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceEvenly,
                  maxY: maxY,
                  minY: minY,
                  baselineY: 0,
                  // ==================================================
                  // GRID
                  // ==================================================
                  gridData: const FlGridData(show: false),
                  // ==================================================
                  // BORDER
                  // ==================================================
                  borderData: FlBorderData(
                    show: false,
                  ),
                  // ==================================================
                  // TITLES
                  // ==================================================
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: false,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 85,
                        getTitlesWidget: (value, meta) {
                          final int index = value.round();
                          if (index < 0 || index >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final DateTime month = months[index];
                          final double? netWorth = getNetWorth(month);
                          final String monthName = DateFormat(
                            'MMMM',
                            'id_ID',
                          ).format(month);
                          final String year = month.year.toString();

                          // ==========================================
                          // DATA BULAN SEBELUMNYA
                          // ==========================================
                          double? previousNetWorth;
                          if (index == 0) {
                            // Karena sekarang index 0 adalah Agustus 2026, pembanding sebelumnya 
                            // adalah Juli 2026 (Juli diseed balance: 16000000, debt: 0)
                            final juliHistory = finance.monthlyHistory.firstWhere(
                              (h) => h.month == 7 && h.year == 2026,
                              orElse: () => MonthlyHistory(month: 7, year: 2026, balance: 16000000, debt: 0),
                            );
                            previousNetWorth = juliHistory.balance.toDouble() - juliHistory.debt.toDouble();
                          } else {
                            previousNetWorth = getNetWorth(
                              months[index - 1],
                            );
                          }

                          // ==========================================
                          // PERSENTASE
                          // ==========================================
                          double? percentage;
                          if (netWorth != null && previousNetWorth != null) {
                            if (previousNetWorth != 0) {
                              percentage = ((netWorth - previousNetWorth) / previousNetWorth.abs()) * 100;
                            } else {
                              percentage = netWorth > 0 ? 100.0 : 0.0;
                            }
                          }

                          final bool isIncrease = (percentage ?? 0) >= 0;

                          // ==========================================
                          // LABEL BULAN
                          // ==========================================
                          return SideTitleWidget(
                            meta: meta,
                            space: 2,
                            child: SizedBox(
                              width: isMobile ? 86 : 110,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    monthName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: _textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    year,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: _textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  // ==================================
                                  // LOGIK TREN
                                  // ==================================
                                  if (netWorth == null)
                                    const Text(
                                      'Belum ada data',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 8.5,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else if (percentage != null)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isIncrease
                                              ? Icons.trending_up_rounded
                                              : Icons.trending_down_rounded,
                                          size: 11,
                                          color: isIncrease ? _green : _red,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${percentage.abs().toStringAsFixed(1).replaceAll('.', ',')}%',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            color: isIncrease ? _green : _red,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  else
                                    const Text(
                                      '—',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        color: _textSecondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // ==================================================
                  // TOUCH / TOOLTIP
                  //
                  // PENTING:
                  // fl_chart versi baru menggunakan getTooltipColor,
                  // bukan tooltipBgColor.
                  // ==================================================
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => Colors.transparent,
                      tooltipPadding: EdgeInsets.zero,
                      tooltipMargin: 7,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItem: (
                        group,
                        groupIndex,
                        rod,
                        rodIndex,
                      ) {
                        if (groupIndex < 0 || groupIndex >= months.length) {
                          return null;
                        }
                        final double? netWorth = getNetWorth(
                          months[groupIndex],
                        );
                        if (netWorth == null) {
                          return null;
                        }
                        final bool isNegative = netWorth < 0;
                        return BarTooltipItem(
                          _formatRupiah(netWorth),
                          TextStyle(
                            color: isNegative ? _red : _green,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  // ==================================================
                  // BAR GROUPS
                  // ==================================================
                  barGroups: barGroups,
                ),
              ),
            ),
          ),
        );
      },
    );

    // ======================================================
    // CARD CHART
    // ======================================================
    final cardChart = Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 24,
        isMobile ? 20 : 24,
        isMobile ? 18 : 24,
        isMobile ? 18 : 22,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.045),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==================================================
          // JUDUL CHART
          // ==================================================
          Text(
            'Tren Perkembangan Net Worth',
            style: TextStyle(
              fontSize: isMobile ? 14 : 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rangeLabel,
            style: TextStyle(
              fontSize: 12,
              color: _textSecondary,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 24),
          // ==================================================
          // LEGEND
          // ==================================================
          Row(
            children: [
              _buildLegendDot(_green),
              const SizedBox(width: 8),
              const Text(
                'Net Worth positif',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(width: 22),
              _buildLegendDot(_red),
              const SizedBox(width: 8),
              const Text(
                'Net Worth negatif',
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // ==================================================
          // CHART
          // ==================================================
          isMobile ? chartWidget : Expanded(child: chartWidget),
          const SizedBox(height: 4),
          // ==================================================
          // FOOTNOTE
          // ==================================================
          Text(
            ' Ayo, Semangat!!! Menuju Finansial Freedom.',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    // ================================================================
    // UI
    // ================================================================
    final rootColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 22),
        isMobile ? cardChart : Expanded(child: cardChart),
      ],
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.read<NavigationProvider>().setMenu(SidebarMenu.dashboard);
      },
      child: Padding(
        padding: EdgeInsets.all(
          isMobile ? 16.0 : 40.0,
        ),
        child: isMobile ? SingleChildScrollView(child: rootColumn) : rootColumn,
      ),
    );
  }

  // ==================================================================
  // LEGEND DOT
  // ==================================================================
  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  // ==================================================================
  // FORMAT RUPIAH
  // ==================================================================
  String _formatRupiah(double value) {
    final String formatted =
    _currency.format(value.abs());

    if (value < 0) {
      return '-$formatted';
    }

    return formatted;
  }
}