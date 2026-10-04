import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';
import '../../../services/navigation_provider.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';
import '../../../core/responsive.dart';
import 'balance_vs_debt_chart.dart';
import 'net_worth_card.dart';

class TransactionLists extends StatelessWidget {
  const TransactionLists({super.key});

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
    
    // Gabungkan dan Urutkan Hutang & Tagihan Rutin berdasarkan Tanggal Jatuh Tempo
    final now = DateTime.now();
    
    // Helper function untuk menghitung tanggal jatuh tempo terdekat
    DateTime getNextDueDate(dynamic item) {
      if (item is Debt) {
        return item.dueDate ?? DateTime(2100); // Jika null, taruh di paling bawah
      } else if (item is RecurringBill) {
        // Jika tanggal jatuh tempo sudah lewat di bulan ini, pindah ke bulan depan
        int year = now.year;
        int month = now.month;
        if (item.dueDay < now.day) {
          month++;
          if (month > 12) {
            month = 1;
            year++;
          }
        }
        return DateTime(year, month, item.dueDay);
      }
      return DateTime(2100);
    }

    final List<dynamic> allBills = [...financeProvider.debts, ...financeProvider.recurringBills];

    // Injeksi Virtual Item Koko dari Sidebar
    if (financeProvider.grandTotalKoko > 0 && financeProvider.isKokoPeriodDueThisMonth && financeProvider.activeKokoPeriod != null) {
      final kokoDueDate = DateTime.parse(financeProvider.activeKokoPeriod!.endDate);
      allBills.add(Debt(
        id: 'koko_virtual_id',
        name: '[KOKO] Belanja Kost',
        totalAmount: financeProvider.roundedKokoBillTotal,
        remainingAmount: financeProvider.roundedKokoBillTotal,
        dueDate: kokoDueDate,
      ));
    }
    
    // Filter: Hanya bulan ini dan yang belum lunas (nominal > 0)
    final activeBills = allBills.where((item) {
      if (item is Debt) {
        // Harus nominal > 0
        if (item.remainingAmount <= 0) return false;
        // Harus jatuh tempo bulan ini
        if (item.dueDate == null) return false;
        return item.dueDate!.year == now.year && item.dueDate!.month == now.month;
      }
      if (item is RecurringBill) {
        // Harus belum lunas
        if (item.remainingTenor <= 0) return false;
        // Harus jatuh tempo bulan ini untuk list "Bulan Ini"
        final dueDate = item.nextDueDate;
        return dueDate.year == now.year && dueDate.month == now.month;
      }
      return true;
    }).toList();

    int getPriority(dynamic item) {
      final name = item.name.toLowerCase();
      
      // Urutan 1: Tagihan Khusus
      if (name.contains('listrik mamah') || 
          name.contains('bpjs endi') || 
          name.contains('bpjs mamah')) {
        return 0;
      }
      
      // Urutan 2: Paylater BCA
      if (item is Debt && name.contains('[bca]')) return 1;
      
      // Urutan 3: Paylater Spaylater
      if (item is Debt && name.contains('[sp]')) return 2;
      
      // Urutan 4: Cicilan Kartu Kredit BCA
      if (item is RecurringBill && item.isInstallment && name.contains('[bca]')) return 3;
      
      return 4; // Lainnya
    }

    activeBills.sort((a, b) {
      final pA = getPriority(a);
      final pB = getPriority(b);
      
      if (pA != pB) return pA.compareTo(pB);
      
      // Jika sama-sama Cicilan BCA (Urutan 4), urutkan sisa tenor tersingkat
      if (pA == 3 && a is RecurringBill && b is RecurringBill) {
        final remA = (a.totalTenor ?? 0) - (a.currentPaidTenor ?? 0);
        final remB = (b.totalTenor ?? 0) - (b.currentPaidTenor ?? 0);
        if (remA != remB) return remA.compareTo(remB);
        // Jika sisa tenor sama, yang total tenor lebih besar (progres tinggi) di atas
        return (b.totalTenor ?? 0).compareTo(a.totalTenor ?? 0);
      }
      
      // Default: Jatuh tempo terdekat
      return getNextDueDate(a).compareTo(getNextDueDate(b));
    });

    final List<Widget> combinedBills = activeBills.map((item) {
      final String name = item is Debt ? item.name : (item as RecurringBill).name;
      final bool isPiutang = name.startsWith('[KOKO]') || name.startsWith('[DEP]') || name.startsWith('[BNS]');
      
      IconData displayIcon = Icons.credit_card;
      Color iconColor = Colors.blue.shade900;
      Color bgColor = Colors.blue.withOpacity(0.05);
      Color amountColor = Colors.black;
      String? tagLabel;
      Color? tagColor;

      if (isPiutang) {
        displayIcon = Icons.arrow_downward;
        iconColor = Colors.green.shade700;
        bgColor = Colors.green.withOpacity(0.08);
        amountColor = Colors.green.shade800;
        tagLabel = "Piutang";
        tagColor = Colors.green;
      } else {
        displayIcon = Icons.arrow_upward;
        iconColor = Colors.red.shade700;
        bgColor = Colors.red.withOpacity(0.08);
        amountColor = Colors.red.shade800;
        tagLabel = "Hutang";
        tagColor = Colors.red;
      }

      final DateTime dueDate = getNextDueDate(item);
      final int daysLeft = dueDate.difference(DateTime(now.year, now.month, now.day)).inDays;
      final String daysLeftText = daysLeft > 0 ? "$daysLeft Hari lagi" : (daysLeft == 0 ? "Hari ini" : "Lewat ${daysLeft.abs()} hari");

      if (item is Debt) {
        // override tag if it's near due date for debts
        if (!isPiutang && item.dueDate != null && item.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7)))) {
          tagLabel = "Segera";
          tagColor = Colors.orange;
        }

        return _buildTransactionItem(
          icon: displayIcon,
          iconColor: iconColor,
          iconBgColor: bgColor,
          title: item.name,
          subtitle: item.dueDate != null ? "Jatuh tempo: ${dateFmt.format(item.dueDate!)}" : "Tanpa jatuh tempo",
          daysLeft: daysLeftText,
          amount: fmt.format(item.totalAmount),
          amountColor: amountColor,
          tag: tagLabel,
          tagColor: tagColor,
        );
      } else if (item is RecurringBill) {
        if (item.isInstallment) {
          return _buildInstallmentItem(
            icon: displayIcon,
            iconColor: iconColor,
            iconBgColor: bgColor,
            title: item.name,
            subtitle: "Jatuh tempo: ${dateFmt.format(item.nextDueDate)}",
            daysLeft: daysLeftText,
            currentTenor: item.currentPaidTenor ?? 0,
            totalTenor: item.totalTenor ?? 0,
            monthlyAmount: fmt.format(item.amount),
            remainingAmount: fmt.format(item.remainingAmount),
            progress: item.progress,
            iconThemeColor: iconColor,
          );
        }
        return _buildTransactionItem(
          icon: displayIcon,
          iconColor: iconColor,
          iconBgColor: bgColor,
          title: item.name,
          subtitle: "Jatuh tempo: Tanggal ${item.dueDay} tiap bulan",
          daysLeft: daysLeftText,
          amount: fmt.format(item.amount),
          amountColor: amountColor,
          tag: isPiutang ? "Piutang" : "Rutin",
          tagColor: isPiutang ? Colors.green : Colors.blue,
        );
      }
      return const SizedBox.shrink();
    }).toList();

    final isMobile = Responsive.isMobile(context);

    if (isMobile) {
      return Column(
        children: [
          SizedBox(
            height: 400,
            child: _buildListContainer(
              context: context,
              title: "Tagihan Bulan Ini",
              items: combinedBills.isEmpty 
                ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada tagihan", style: TextStyle(fontSize: 12, color: Colors.grey))))]
                : combinedBills,
            ),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            height: 350,
            child: BalanceVsDebtChart(),
          ),
          const SizedBox(height: 24),
          const NetWorthCard(),
        ],
      );
    }

    return SizedBox(
      height: 350, 
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // List Tagihan Bulan Ini
          Expanded(
            flex: 1,
            child: _buildListContainer(
              context: context,
              title: "List Tagihan Bulan Ini",
              items: combinedBills.isEmpty 
                ? [const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada data tagihan", style: TextStyle(fontSize: 12, color: Colors.grey))))]
                : combinedBills,
            ),
          ),
          const SizedBox(width: 24),
          // Saldo vs Hutang Chart
          const Expanded(
            flex: 1,
            child: BalanceVsDebtChart(),
          ),
        ],
      ),
    );
  }


  Widget _buildListContainer({required BuildContext context, required String title, required List<Widget> items}) {
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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.read<NavigationProvider>().setMenu(SidebarMenu.danaVsTagihan),
                  child: const Text(
                    "Lihat semua",
                    style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Scrollbar(
              child: ListView(
                padding: EdgeInsets.zero,
                children: items,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    required String title,
    required String subtitle,
    required String daysLeft,
    required String amount,
    String? tag,
    Color? tagColor,
    Color amountColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor ?? Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? Colors.blue.shade900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(daysLeft, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: amountColor),
              ),
              if (tag != null)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tagColor!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(color: tagColor, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem({
    required IconData icon,
    Color? iconColor,
    Color? iconBgColor,
    required String title,
    required String subtitle,
    required String daysLeft,
    required int currentTenor,
    required int totalTenor,
    required String monthlyAmount,
    required String remainingAmount,
    required double progress,
    Color? iconThemeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBgColor ?? Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor ?? Colors.blue.shade900),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          const SizedBox(height: 2),
                          Text(daysLeft, style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          monthlyAmount,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: iconThemeColor ?? Colors.black),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (iconThemeColor ?? Colors.blue).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            title.toLowerCase().contains('bpjs mamah') ? "Rehab" : (title.startsWith('[BCA]') || title.startsWith('[SP]') ? "Cicilan" : "Piutang"),
                            style: TextStyle(color: iconThemeColor ?? Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(iconThemeColor ?? const Color(0xFF00C2FF)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "$currentTenor/$totalTenor",
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    Text(
                      "Sisa $remainingAmount",
                      style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
