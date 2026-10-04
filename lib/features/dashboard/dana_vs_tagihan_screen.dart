import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/finance_provider.dart';
import '../../models/debt_model.dart';
import '../../models/recurring_bill_model.dart';
import '../../core/responsive.dart';
import 'widgets/dana_vs_tagihan_chart.dart';
import 'widgets/tagihan_bulanan_iframe.dart';

class DanaVsTagihanScreen extends StatefulWidget {
  const DanaVsTagihanScreen({super.key});

  @override
  State<DanaVsTagihanScreen> createState() => _DanaVsTagihanScreenState();
}

class _DanaVsTagihanScreenState extends State<DanaVsTagihanScreen> {
  int _selectedMonthIndex = 0;
  final int _totalProjectionMonths = 12;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    final selectedDate = DateTime(startDate.year, startDate.month + _selectedMonthIndex, 1);
    
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? const EdgeInsets.fromLTRB(20, 16, 20, 32) : const EdgeInsets.fromLTRB(40, 24, 40, 48);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
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
                      "Dana vs Tagihan",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const Text(
                  "Analisis kesanggupan bayar hutang",
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _buildTopMonthSelector(startDate),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Dana vs Tagihan",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const Text(
                      "Analisis kesanggupan bayar hutang",
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ],
                ),
                _buildTopMonthSelector(startDate),
              ],
            ),
          SizedBox(height: isMobile ? 24 : 15),

          if (isMobile)
            Column(
              children: [
                SizedBox(
                  height: 450,
                  child: const DanaVsTagihanChart(),
                ),
                const SizedBox(height: 24),
                _buildBreakdownCard(context, finance, selectedDate),
                const SizedBox(height: 24),
                const TagihanBulananIframe(),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Chart (narrower/shorter width) & Breakdown Card
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 380,
                        child: const DanaVsTagihanChart(),
                      ),
                      const SizedBox(height: 24),
                      _buildBreakdownCard(context, finance, selectedDate),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column: Embedded Tagihan Bulanan App (WebView / Iframe)
                Expanded(
                  flex: 1,
                  child: const TagihanBulananIframe(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTopMonthSelector(DateTime startDate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Text(
            DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(BuildContext context, FinanceProvider finance, DateTime selectedDate) {
    final fmtDigits = NumberFormat("#,##0", "id_ID");
    final now = DateTime.now();
    final bool isCurrentMonth = selectedDate.year == now.year && selectedDate.month == now.month;
    final isMobile = Responsive.isMobile(context);

    // Calculate Dana Details
    double bca = 0, cash = 0, shopeepay = 0;
    if (isCurrentMonth) {
      for (var w in finance.wallets) {
        final name = w.name.toLowerCase();
        if (name == 'bca') bca = w.balance;
        else if (name == 'cash') cash = w.balance;
        else if (name == 'shopeepay') shopeepay = w.balance;
      }
    }

    double koko = _calculatePrefixTotal(finance, selectedDate, '[KOKO]');
    double deposit = _calculatePrefixTotal(finance, selectedDate, '[DEP]');

    // Calculate Tagihan Details
    double kkBca = _calculatePrefixTotal(finance, selectedDate, '[BCA]');
    double spaylater = _calculatePrefixTotal(finance, selectedDate, '[SP]');
    double other = _calculatePrefixTotal(finance, selectedDate, '[OT]');

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Dana", style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.w900, fontSize: 20)),
              SizedBox(
                width: isMobile ? 150 : 200,
                child: _buildMonthPickerTrigger(selectedDate),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildDetailRow("BCA", bca, fmtDigits),
          _buildDetailRow("Cash", cash, fmtDigits),
          _buildDetailRow("Shopeepay", shopeepay, fmtDigits),
          _buildDetailRow("Tagihan Koko", koko, fmtDigits),
          _buildDetailRow("Deposit", deposit, fmtDigits),
          
          const SizedBox(height: 20),
          const Text("Tagihan", style: TextStyle(color: Color(0xFFFF3B30), fontWeight: FontWeight.w900, fontSize: 20)),
          const SizedBox(height: 15),
          _buildDetailRow("Kartu kredit BCA", kkBca, fmtDigits),
          _buildDetailRow("Spaylater", spaylater, fmtDigits),
          _buildDetailRow("Hutang Lainnya", other, fmtDigits),
        ],
      ),
    );
  }

  Widget _buildMonthPickerTrigger(DateTime selectedDate) {
    final isMobile = Responsive.isMobile(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _showMonthPicker(context),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('MMM yyyy', 'id_ID').format(selectedDate),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16, color: Colors.black87),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: isMobile ? 18 : 20, color: Colors.black54),
            ],
          ),
        ),
      ),
    );
  }

  void _showMonthPicker(BuildContext context) {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, 1);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _totalProjectionMonths,
            itemBuilder: (context, index) {
              final date = DateTime(startDate.year, startDate.month + index, 1);
              final isSelected = index == _selectedMonthIndex;
              return ListTile(
                title: Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(date),
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                  ),
                ),
                trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).primaryColor) : null,
                onTap: () {
                  setState(() => _selectedMonthIndex = index);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, double amount, NumberFormat fmtDigits) {
    final isMobile = Responsive.isMobile(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Text("•", style: TextStyle(fontSize: 18, color: Colors.black38)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label, 
              style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w500, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: isMobile ? 120 : 200,
            child: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Row(
                children: [
                  Text("Rp", style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.black87)),
                  const Spacer(),
                  Text(
                    fmtDigits.format(amount), 
                    style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculatePrefixTotal(FinanceProvider finance, DateTime targetDate, String prefix) {
    double total = 0;
    final now = DateTime.now();
    final bool isCurrentMonth = targetDate.year == now.year && targetDate.month == now.month;

    // Tambahkan Tagihan Belanja Koko (dari sidebar) jika bulan jatuh tempo cocok
    if (prefix == '[KOKO]') {
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

    // Debts
    for (var debt in finance.debts) {
      if (debt.dueDate != null &&
          debt.dueDate!.year == targetDate.year &&
          debt.dueDate!.month == targetDate.month) {
        if (debt.name.startsWith(prefix)) {
          if (debt.remainingAmount > 0) {
            total += debt.remainingAmount;
          }
        } else if (prefix == '[OT]' &&
                   !debt.name.startsWith('[BCA]') &&
                   !debt.name.startsWith('[SP]') &&
                   !debt.name.startsWith('[DEP]') &&
                   !debt.name.startsWith('[KOKO]')) {
          if (debt.remainingAmount > 0) {
            total += debt.remainingAmount;
          }
        }
      }
    }

    // Recurring Bills
    for (var bill in finance.recurringBills) {
      if (bill.name.startsWith(prefix)) {
        if (bill.isInstallment && bill.startDate != null && bill.startTenor != null) {
          int monthsDiff = (targetDate.year - bill.startDate!.year) * 12 + (targetDate.month - bill.startDate!.month);
          int targetTenor = bill.startTenor! + monthsDiff;
          if (targetTenor >= 1 && targetTenor <= (bill.totalTenor ?? 0)) {
            if (isCurrentMonth) {
              if (bill.nextDueDate.month == now.month) {
                total += bill.amount;
              }
            } else {
              total += bill.amount;
            }
          }
        } else if (!bill.isInstallment) {
          if (isCurrentMonth) {
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
}
