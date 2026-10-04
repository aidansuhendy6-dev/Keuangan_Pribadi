import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/finance_provider.dart';
import '../../models/debt_model.dart';
import '../../models/recurring_bill_model.dart';
import 'widgets/deposit_card.dart';
import 'widgets/deposit_transaction_list.dart';
import 'widgets/add_deposit_transaction_dialog.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/cupertino.dart';
import '../../core/responsive.dart';
import '../../services/export_service/export_service.dart';
import 'widgets/deposit_report_widget.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
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

      final success = await ExportService.saveImage(image, "Laporan_Piutang_$dateStr");
      
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

    // Filter Items by Prefix
    List<dynamic> getItemsForPrefix(String prefix) {
      final paylater = finance.debts.where((d) => d.name.startsWith(prefix)).toList();
      final installments = finance.recurringBills.where((b) => b.name.startsWith(prefix)).toList();
      return [...paylater, ...installments];
    }

    final kokoItems = getItemsForPrefix('[KOKO]');
    final depositItems = getItemsForPrefix('[DEP]');
    final bonusItems = getItemsForPrefix('[BNS]');

    void sortItems(List<dynamic> items) {
      items.sort((a, b) {
        DateTime dateA = a is Debt ? (a.dueDate ?? DateTime(2100)) : (a as RecurringBill).nextDueDate;
        DateTime dateB = b is Debt ? (b.dueDate ?? DateTime(2100)) : (b as RecurringBill).nextDueDate;
        return dateA.compareTo(dateB);
      });
    }

    sortItems(kokoItems);
    sortItems(depositItems);
    
    bonusItems.sort((a, b) {
      String nameA = a is Debt ? a.name : (a as RecurringBill).name;
      String nameB = b is Debt ? b.name : (b as RecurringBill).name;
      return _compareNatural(nameA, nameB);
    });

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

    final kokoMonthly = calculateMonthlyTotal(kokoItems) + (finance.isKokoPeriodDueThisMonth ? finance.roundedKokoBillTotal : 0);
    final depMonthly = calculateMonthlyTotal(depositItems);
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
              child: DepositReportWidget(
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
                        "Daftar Piutang",
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
                          builder: (context) => const AddDepositTransactionDialog(),
                        ),
                        isMobile: isMobile,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: isMobile ? 24 : 32),
              if (isMobile)
                Column(
                  children: [
                    _buildDepositColumn("Tagihan Koko", finance.kokoPiutangBalance, kokoMonthly, Icons.assignment, const Color(0xFFFF3B30), [Color(0xFFFF3B30), Color(0xFFC42D25)], kokoItems, finance),
                    const SizedBox(height: 24),
                    _buildDepositColumn("Deposit", finance.depPiutangBalance, depMonthly, Icons.account_balance, const Color(0xFF00C2FF), [Color(0xFF00C2FF), Color(0xFF009FD1)], depositItems, finance),
                    const SizedBox(height: 24),
                    _buildDepositColumn("Bonus", finance.bonusPiutangBalance, null, Icons.card_giftcard, const Color(0xFF27D17F), [Color(0xFF27D17F), Color(0xFF1E9B5E)], bonusItems, finance),
                  ],
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDepositColumn("Tagihan Koko", finance.kokoPiutangBalance, kokoMonthly, Icons.assignment, const Color(0xFFFF3B30), [Color(0xFFFF3B30), Color(0xFFC42D25)], kokoItems, finance),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _buildDepositColumn("Deposit", finance.depPiutangBalance, depMonthly, Icons.account_balance, const Color(0xFF00C2FF), [Color(0xFF00C2FF), Color(0xFF009FD1)], depositItems, finance),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: _buildDepositColumn("Bonus", finance.bonusPiutangBalance, null, Icons.card_giftcard, const Color(0xFF27D17F), [Color(0xFF27D17F), Color(0xFF1E9B5E)], bonusItems, finance),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDepositColumn(String name, double balance, double? monthly, IconData icon, Color color, List<Color> gradient, List<dynamic> items, FinanceProvider finance) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Column(
      children: [
        DepositCard(
          name: name,
          balance: fmt.format(balance),
          dueThisMonth: monthly != null ? fmt.format(monthly) : null,
          icon: icon,
          backgroundColor: color,
          gradientColors: gradient,
        ),
        const SizedBox(height: 24),
        DepositTransactionList(
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
      finance.removePiutangDebt(item.id);
    } else if (item is RecurringBill) {
      finance.removePiutangInstallment(item.id);
    }
  }

  void _handleSettle(FinanceProvider finance, dynamic item) {
    if (item is Debt) {
      finance.settlePiutangItem(item);
    } else if (item is RecurringBill) {
      finance.settlePiutangInstallment(item);
    }
  }

  void _handleEdit(BuildContext context, dynamic item) {
    showDialog(
      context: context,
      builder: (context) => AddDepositTransactionDialog(initialItem: item),
    );
  }

  int _compareNatural(String a, String b) {
    final aStr = a.toLowerCase();
    final bStr = b.toLowerCase();
    final aStartsDigit = aStr.isNotEmpty && RegExp(r'^\d').hasMatch(aStr);
    final bStartsDigit = bStr.isNotEmpty && RegExp(r'^\d').hasMatch(bStr);
    if (aStartsDigit != bStartsDigit) return aStartsDigit ? 1 : -1;
    final re = RegExp(r'(\d+)|(\D+)');
    final aMatches = re.allMatches(aStr).toList();
    final bMatches = re.allMatches(bStr).toList();
    for (int i = 0; i < aMatches.length && i < bMatches.length; i++) {
      final aPart = aMatches[i].group(0)!;
      final bPart = bMatches[i].group(0)!;
      if (aPart != bPart) {
        final aNum = int.tryParse(aPart);
        final bNum = int.tryParse(bPart);
        if (aNum != null && bNum != null) return aNum.compareTo(bNum);
        return aPart.compareTo(bPart);
      }
    }
    return aMatches.length.compareTo(bMatches.length);
  }
}
