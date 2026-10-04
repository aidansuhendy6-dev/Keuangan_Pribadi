import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/finance_provider.dart';
import '../../models/debt_model.dart';
import '../../models/recurring_bill_model.dart';
import 'widgets/debt_card.dart';
import 'widgets/debt_bill_list.dart';
import 'widgets/add_debt_dialog.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/cupertino.dart';
import '../../core/responsive.dart';
import '../../services/export_service/export_service.dart';
import 'widgets/debt_report_widget.dart';
import 'widgets/debt_projection_chart.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _downloadReport(BuildContext context, FinanceProvider finance) async {
    try {
      final dateStr = DateFormat('d MMMM yyyy HH.mm', 'id_ID').format(DateTime.now());
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sedang menyiapkan gambar...")),
      );

      final image = await screenshotController.capture(
        pixelRatio: 2.0,
        delay: const Duration(milliseconds: 100),
      );

      if (image == null) throw Exception("Gagal mengambil screenshot.");

      final success = await ExportService.saveImage(image, "Laporan_Hutang_$dateStr");
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan berhasil diunduh!")),
        );
      } else {
        throw Exception("Gagal mengunduh gambar.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Get child items for each card
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

    // Sorting Logic: Nearest due date first
    DateTime getNextDueDate(dynamic item) {
      if (item is Debt) {
        return item.dueDate ?? DateTime(2100);
      } else if (item is RecurringBill) {
        return item.nextDueDate;
      }
      return DateTime(2100);
    }

    void sortItems(List<dynamic> items) {
      items.sort((a, b) {
        if (a is Debt && b is RecurringBill) return -1;
        if (a is RecurringBill && b is Debt) return 1;
        if (a is RecurringBill && b is RecurringBill) {
          final remainingA = (a.totalTenor ?? 0) - (a.currentPaidTenor ?? 0);
          final remainingB = (b.totalTenor ?? 0) - (b.currentPaidTenor ?? 0);
          if (remainingA != remainingB) return remainingA.compareTo(remainingB);
          if (a.totalTenor != b.totalTenor) return (b.totalTenor ?? 0).compareTo(a.totalTenor ?? 0);
        }
        return getNextDueDate(a).compareTo(getNextDueDate(b));
      });
    }
    
    sortItems(bcaItems);
    sortItems(spaylaterItems);
    sortItems(otherItems);

    double calculateMonthlyTotal(List<dynamic> items) {
      final now = DateTime.now();
      double total = 0;
      for (var item in items) {
        if (item is Debt) {
          if (item.dueDate != null && item.dueDate!.year == now.year && item.dueDate!.month == now.month) {
            total += item.remainingAmount;
          }
        } else if (item is RecurringBill) {
          final dueDate = item.nextDueDate;
          if (dueDate.year == now.year && dueDate.month == now.month) {
            total += item.amount;
          }
        }
      }
      return total;
    }

    final bcaMonthly = calculateMonthlyTotal(bcaItems);
    final spMonthly = calculateMonthlyTotal(spaylaterItems);
    final otherMonthly = calculateMonthlyTotal(otherItems);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? const EdgeInsets.fromLTRB(20, 16, 20, 32) : const EdgeInsets.fromLTRB(40, 24, 40, 48);
    final dateStr = DateFormat('d MMMM yyyy HH.mm', 'id_ID').format(DateTime.now());

    return Stack(
      children: [
        // Hidden Report Widget for Screenshot
        Positioned(
          top: -20000,
          left: 0,
          child: UnconstrainedBox(
            alignment: Alignment.topLeft,
            child: Screenshot(
              controller: screenshotController,
              child: DebtReportWidget(
                finance: finance,
                dateTimeString: dateStr,
              ),
            ),
          ),
        ),
        // Main UI
        SingleChildScrollView(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (isMobile)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Builder(
                            builder: (context) => IconButton(
                              onPressed: () => Scaffold.of(context).openDrawer(),
                              icon: const Icon(Icons.menu, color: Colors.black87),
                            ),
                          ),
                        ),
                      Text(
                        "Daftar Hutang",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 22 : 24,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildHeaderButton(
                        context, 
                        icon: CupertinoIcons.photo, 
                        color: Colors.black87, 
                        onTap: () => _downloadReport(context, finance),
                        tooltip: "Download JPG",
                        isMobile: isMobile,
                      ),
                      const SizedBox(width: 12),
                      _buildHeaderButton(
                        context, 
                        icon: Icons.add, 
                        color: Colors.green, 
                        onTap: () => showDialog(
                          context: context, 
                          builder: (context) => const AddDebtDialog(),
                        ),
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // New Projection Chart Card
              DebtProjectionChart(
                debts: finance.debts,
                recurringBills: finance.recurringBills,
              ),
              SizedBox(height: isMobile ? 24 : 32),
              if (isMobile)
                Column(
                  children: [
                    _buildDebtColumn("BCA", finance.bcaDebtBalance, bcaMonthly, "assets/icons/icon_kartukreditbca.png", const Color(0xFF0088FF), [Color(0xFF0088FF), Color(0xFF0066CC)], bcaItems, fmt, 32, finance),
                    const SizedBox(height: 24),
                    _buildDebtColumn("SPayLater", finance.spaylaterDebtBalance, spMonthly, "assets/icons/iconspaylater.png", const Color(0xFFFF6633), [Color(0xFFFF6633), Color(0xFFE64A19)], spaylaterItems, fmt, 40, finance),
                    const SizedBox(height: 24),
                    _buildDebtColumn("Lainnya", finance.otherDebtBalance, otherMonthly, null, const Color(0xFFFF5C5C), [Color(0xFFFF5C5C), Color(0xFFD32F2F)], otherItems, fmt, 0, finance, icon: Icons.account_balance_wallet_outlined),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDebtColumn("BCA", finance.bcaDebtBalance, bcaMonthly, "assets/icons/icon_kartukreditbca.png", const Color(0xFF0088FF), [Color(0xFF0088FF), Color(0xFF0066CC)], bcaItems, fmt, 32, finance),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _buildDebtColumn("SPayLater", finance.spaylaterDebtBalance, spMonthly, "assets/icons/iconspaylater.png", const Color(0xFFFF6633), [Color(0xFFFF6633), Color(0xFFE64A19)], spaylaterItems, fmt, 40, finance),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _buildDebtColumn("Lainnya", finance.otherDebtBalance, otherMonthly, null, const Color(0xFFFF5C5C), [Color(0xFFFF5C5C), Color(0xFFD32F2F)], otherItems, fmt, 0, finance, icon: Icons.account_balance_wallet_outlined),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDebtColumn(String name, double balance, double monthly, String? asset, Color color, List<Color> gradient, List<dynamic> items, NumberFormat fmt, double logoH, FinanceProvider finance, {IconData? icon}) {
    return Column(
      children: [
        DebtCard(
          name: name,
          balance: fmt.format(balance),
          monthlyBill: fmt.format(monthly),
          imageAsset: asset,
          icon: icon,
          backgroundColor: color,
          gradientColors: gradient,
          logoHeight: logoH,
          showName: asset == null,
        ),
        const SizedBox(height: 24),
        DebtBillList(
          items: items,
          onDelete: (item) => _handleDelete(finance, item),
          onSettle: (item) => _handleSettle(finance, item),
          onEdit: (item) => _handleEdit(context, item),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(BuildContext context, {required IconData icon, required Color color, required VoidCallback onTap, String? tooltip, bool isMobile = false}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip ?? "",
          child: Container(
            width: isMobile ? 40 : 48,
            height: isMobile ? 40 : 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: isMobile ? 20 : 24),
          ),
        ),
      ),
    );
  }

  void _handleDelete(FinanceProvider finance, dynamic item) {
    if (item is Debt) {
      finance.removeDebt(item.id);
    } else if (item is RecurringBill) {
      finance.removeRecurringBill(item.id);
    }
  }

  void _handleSettle(FinanceProvider finance, dynamic item) {
    if (item is Debt) {
      finance.settleDebtItem(item);
    } else if (item is RecurringBill) {
      finance.settleInstallmentItem(item);
    }
  }

  void _handleEdit(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AddDebtDialog(initialItem: item),
    );
  }
}
