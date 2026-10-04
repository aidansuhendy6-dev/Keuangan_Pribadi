import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_theme.dart';
import '../../core/responsive.dart';
import 'package:keuangan_pribadi/services/navigation_provider.dart';
import 'package:keuangan_pribadi/services/finance_provider.dart';
import 'widgets/sidebar.dart';
import 'widgets/mobile_drawer.dart';
import 'widgets/summary_card.dart';
import 'widgets/ios_3d_pie_chart.dart';
import 'widgets/charts_section.dart';
import 'widgets/transaction_lists.dart';
import '../transactions/transaction_screen.dart';
import '../transactions/widgets/add_transaction_dialog.dart';
import '../wallets/wallet_screen.dart';
import '../savings/saving_screen.dart';
import '../deposits/deposit_screen.dart';
import '../debts/debt_screen.dart';
import 'dana_vs_tagihan_screen.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/cupertino.dart';
import 'widgets/financial_report_widget.dart';
import '../../services/export_service/export_service.dart';

import 'tagihan_koko_screen.dart';
import 'income_expense_detail_screen.dart';
import 'net_worth_history_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _downloadReport(BuildContext context, FinanceProvider finance) async {
    try {
      final dateStr = DateFormat('d MMMM yyyy HH.mm', 'id_ID').format(DateTime.now());
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sedang menyiapkan gambar...")),
      );

      final image = await screenshotController.captureFromWidget(
        FinancialReportWidget(finance: finance, dateTimeString: dateStr),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      final success = await ExportService.saveImage(image, "Laporan_Keuangan_$dateStr");
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Laporan berhasil diunduh!")),
        );
      } else {
        throw Exception("Gagal mengunduh gambar. Pastikan izin diberikan.");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final financeProvider = context.watch<FinanceProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      drawer: isMobile ? const MobileDrawer() : null,
      bottomNavigationBar: isMobile 
        ? Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 8,
              top: 8,
              left: 12,
              right: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBottomNavItem(context, SidebarMenu.dashboard, CupertinoIcons.square_grid_2x2_fill, 'Dashboard'),
                _buildBottomNavItem(context, SidebarMenu.wallet, Icons.account_balance_wallet, 'Dompet'),
                _buildBottomNavItem(context, SidebarMenu.debt, CupertinoIcons.doc_text_fill, 'Hutang'),
                _buildBottomNavItem(context, SidebarMenu.deposit, CupertinoIcons.money_dollar_circle_fill, 'Deposit'),
              ],
            ),
          )
        : null,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8ECEF), Color(0xFFF8F9FA), Color(0xFFE3E6E8)],
              ),
            ),
          ),
          // Decorative Circle
          Positioned(
            top: isMobile ? -60 : -120,
            right: isMobile ? -60 : -120,
            child: Container(
              width: isMobile ? 260 : 520,
              height: isMobile ? 260 : 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.04),
              ),
            ),
          ),
          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!isMobile) const Sidebar(),
              Expanded(
                child: _buildBody(context, navProvider, financeProvider, currencyFormat),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(SidebarMenu menu) {
    switch (menu) {
      case SidebarMenu.dashboard: return 0;
      case SidebarMenu.wallet: return 1;
      case SidebarMenu.debt: return 2;
      case SidebarMenu.deposit: return 3;
      default: return 0;
    }
  }

  SidebarMenu _getMenuFromIndex(int index) {
    switch (index) {
      case 0: return SidebarMenu.dashboard;
      case 1: return SidebarMenu.wallet;
      case 2: return SidebarMenu.debt;
      case 3: return SidebarMenu.deposit;
      default: return SidebarMenu.dashboard;
    }
  }

  Widget _buildBody(BuildContext context, NavigationProvider nav, FinanceProvider finance, NumberFormat fmt) {
    if (finance.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (nav.currentMenu) {
      case SidebarMenu.dashboard:
        return _buildDashboard(context, nav, finance, fmt);
      case SidebarMenu.transaction:
        return const TransactionScreen();
      case SidebarMenu.wallet:
        return const WalletScreen();
      case SidebarMenu.saving:
        return const SavingScreen();
      case SidebarMenu.deposit:
        return const DepositScreen();
      case SidebarMenu.debt:
        return const DebtScreen();
      case SidebarMenu.danaVsTagihan:
        return const DanaVsTagihanScreen();
      case SidebarMenu.tagihanKoko:
        return const TagihanKokoScreen();
      case SidebarMenu.incomeExpenseDetail:
        return const IncomeExpenseDetailScreen();
      case SidebarMenu.netWorthHistory:
        return const NetWorthHistoryScreen();
    }
  }

  String _getPageTitle(SidebarMenu menu) {
    switch (menu) {
      case SidebarMenu.dashboard: return "Dashboard";
      case SidebarMenu.transaction: return "Riwayat";
      case SidebarMenu.wallet: return "Dompet";
      case SidebarMenu.saving: return "Tabungan";
      case SidebarMenu.deposit: return "Deposit";
      case SidebarMenu.debt: return "Hutang";
      case SidebarMenu.danaVsTagihan: return "Dana vs Tagihan";
      case SidebarMenu.tagihanKoko: return "Belanja Kost";
      case SidebarMenu.incomeExpenseDetail: return "Detail Keuangan";
      case SidebarMenu.netWorthHistory: return "Riwayat Kekayaan";
    }
  }

  String _getPageSubtitle(SidebarMenu menu) {
    switch (menu) {
      case SidebarMenu.dashboard: return "Info Saldo dan Transaksi";
      case SidebarMenu.transaction: return "Riwayat transaksi Anda";
      case SidebarMenu.wallet: return "Daftar dompet Anda";
      case SidebarMenu.saving: return "Target tabungan Anda";
      case SidebarMenu.deposit: return "Daftar piutang Anda";
      case SidebarMenu.debt: return "Daftar hutang Anda";
      case SidebarMenu.danaVsTagihan: return "Analisis kesanggupan bayar";
      case SidebarMenu.tagihanKoko: return "Kelola pengeluaran kost";
      case SidebarMenu.incomeExpenseDetail: return "Rincian pemasukan dan pengeluaran";
      case SidebarMenu.netWorthHistory: return "Perkembangan kekayaan bersih Anda";
    }
  }

  Widget _buildDashboard(BuildContext context, NavigationProvider nav, FinanceProvider finance, NumberFormat fmt) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? const EdgeInsets.fromLTRB(20, 16, 20, 32) : const EdgeInsets.fromLTRB(40, 24, 40, 48);

    return SingleChildScrollView(
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
                      padding: const EdgeInsets.only(right: 12),
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu, color: Colors.black87),
                        ),
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getPageTitle(nav.currentMenu),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                          fontSize: isMobile ? 24 : 34,
                          letterSpacing: -1.0,
                        ),
                      ),
                      Text(
                        _getPageSubtitle(nav.currentMenu),
                        style: TextStyle(color: Colors.black54, fontSize: isMobile ? 12 : 13),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _downloadReport(context, finance),
                    icon: Icon(CupertinoIcons.photo, color: Colors.black87, size: isMobile ? 22 : 24),
                    tooltip: "Download JPG",
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 8 : 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_today, size: isMobile ? 14 : 16, color: Colors.black54),
                        SizedBox(width: isMobile ? 6 : 8),
                        Text(
                          DateFormat('MMMM yyyy', 'id_ID').format(DateTime.now()),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 12 : 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Summary Cards
          if (isMobile)
            Column(
              children: [
                SummaryCard(
                  title: "Total Saldo",
                  amount: fmt.format(finance.totalBalance),
                  percentage: finance.formatPercentage(finance.balancePercentage),
                  isPositive: finance.balancePercentage >= 0,
                  icon: Icons.account_balance_wallet,
                  iconColor: const Color(0xFF34C759),
                  gradientColors: const [Color(0xFF1E3A24), Color(0xFF34C759)],
                  isActive: true,
                ),
                const SizedBox(height: 16),
                SummaryCard(
                  title: "Total Hutang",
                  amount: fmt.format(finance.totalDebt),
                  percentage: finance.formatPercentage(finance.debtPercentage),
                  isPositive: finance.debtPercentage <= 0,
                  icon: Icons.credit_card,
                  iconColor: const Color(0xFFFF3A30),
                  gradientColors: const [Color(0xFF8B1A1A), Color(0xFFFF3A30)],
                  isActive: true,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SummaryCard(
                        title: "Income",
                        amount: fmt.format(finance.totalIncome),
                        percentage: finance.formatPercentage(finance.incomePercentage),
                        isPositive: finance.incomePercentage >= 0,
                        icon: Icons.arrow_downward,
                        iconColor: const Color(0xFF34C759),
                        onTap: () => nav.setMenu(SidebarMenu.transaction),
                        onAddPressed: () => showDialog(
                          context: context,
                          builder: (context) => const AddTransactionDialog(type: 'income'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SummaryCard(
                        title: "Expense",
                        amount: fmt.format(finance.totalExpense),
                        percentage: finance.formatPercentage(finance.expensePercentage),
                        isPositive: finance.expensePercentage <= 0,
                        icon: Icons.arrow_upward,
                        iconColor: const Color(0xFFFF3A30),
                        onTap: () => nav.setMenu(SidebarMenu.transaction),
                        onAddPressed: () => showDialog(
                          context: context,
                          builder: (context) => const AddTransactionDialog(type: 'expense'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SummaryCard(
                  title: "Sisa Bonus Bersih",
                  amount: fmt.format(finance.totalIncome - finance.totalExpense),
                  percentage: finance.formatPercentage(finance.netCashFlowPercentage),
                  isPositive: finance.netCashFlowPercentage >= 0,
                  icon: CupertinoIcons.sparkles,
                  iconColor: const Color(0xFF34C759),
                  onTap: () => nav.setMenu(SidebarMenu.incomeExpenseDetail),
                  customRightWidget: Ios3dPieChart(
                    sisaBonus: finance.totalIncome - finance.totalExpense,
                    totalExpense: finance.totalExpense,
                    size: Responsive.isMobile(context) ? 54 : 68,
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: SummaryCard(
                    title: "Total Saldo",
                    amount: fmt.format(finance.totalBalance),
                    percentage: finance.formatPercentage(finance.balancePercentage),
                    isPositive: finance.balancePercentage >= 0,
                    icon: Icons.account_balance_wallet,
                    iconColor: const Color(0xFF34C759),
                    gradientColors: const [Color(0xFF1E3A24), Color(0xFF34C759)],
                    isActive: true,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SummaryCard(
                    title: "Total Hutang",
                    amount: fmt.format(finance.totalDebt),
                    percentage: finance.formatPercentage(finance.debtPercentage),
                    isPositive: finance.debtPercentage <= 0,
                    icon: Icons.credit_card,
                    iconColor: const Color(0xFFFF3A30),
                    gradientColors: const [Color(0xFF8B1A1A), Color(0xFFFF3A30)],
                    isActive: true,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SummaryCard(
                    title: "Total Pemasukan",
                    amount: fmt.format(finance.totalIncome),
                    percentage: finance.formatPercentage(finance.incomePercentage),
                    isPositive: finance.incomePercentage >= 0,
                    icon: Icons.arrow_downward,
                    iconColor: const Color(0xFF34C759),
                    onTap: () => nav.setMenu(SidebarMenu.transaction),
                    onAddPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddTransactionDialog(type: 'income'),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SummaryCard(
                    title: "Total Pengeluaran",
                    amount: fmt.format(finance.totalExpense),
                    percentage: finance.formatPercentage(finance.expensePercentage),
                    isPositive: finance.expensePercentage <= 0,
                    icon: Icons.arrow_upward,
                    iconColor: const Color(0xFFFF3A30),
                    onTap: () => nav.setMenu(SidebarMenu.transaction),
                    onAddPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddTransactionDialog(type: 'expense'),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: SummaryCard(
                    title: "Sisa Bonus Bersih",
                    amount: fmt.format(finance.totalIncome - finance.totalExpense),
                    percentage: finance.formatPercentage(finance.netCashFlowPercentage),
                    isPositive: finance.netCashFlowPercentage >= 0,
                    icon: CupertinoIcons.sparkles,
                    iconColor: const Color(0xFF34C759),
                    onTap: () => nav.setMenu(SidebarMenu.incomeExpenseDetail),
                    customRightWidget: Ios3dPieChart(
                      sisaBonus: finance.totalIncome - finance.totalExpense,
                      totalExpense: finance.totalExpense,
                      size: Responsive.isMobile(context) ? 54 : 68,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 24),
          // Charts Section
          const ChartsSection(),
          const SizedBox(height: 24),
          // Transaction Lists Section
          const TransactionLists(),
        ],
      ),
    );
  }

  Widget _buildListView<T>(BuildContext context, String title, List<T> items, String Function(T) getTitle, String Function(T) getSubtitle) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(getTitle(item), style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text(getSubtitle(item), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem(BuildContext context, SidebarMenu menu, IconData icon, String label) {
    final navProvider = context.watch<NavigationProvider>();
    final isActive = navProvider.currentMenu == menu;

    return Expanded(
      child: InkWell(
        onTap: () => navProvider.setMenu(menu),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.black.withOpacity(0.06) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? Colors.black : Colors.black45,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? Colors.black : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
