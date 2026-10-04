import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/app_theme.dart';
import 'package:keuangan_pribadi/services/navigation_provider.dart';
import 'package:keuangan_pribadi/services/finance_provider.dart';
import 'tagihan_koko_sidebar.dart';
import 'net_worth_card.dart';

class Sidebar extends StatefulWidget {
  const Sidebar({super.key});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        border: Border(right: BorderSide(color: Colors.black.withOpacity(0.06))),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 35, sigmaY: 35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Section
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 20, 24),
                child: Row(
                  children: [
                    Image.network(
                      'https://xbtdqjfmgthbnbgyujkv.supabase.co/storage/v1/object/public/Logo/logo_uang.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.monetization_on,
                        color: Colors.black,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Aidan Suhendy",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          "Keuangan Pribadi",
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildNavItem(context, SidebarMenu.dashboard, Icons.grid_view_rounded, "Dashboard"),
                    const SizedBox(height: 0),
                    _buildNavItem(
                      context, 
                      SidebarMenu.wallet, 
                      Icons.account_balance_wallet, 
                      "Dompet",
                      trailing: fmt.format(finance.totalWalletBalance),
                    ),
                    const SizedBox(height: 0),
                    _buildNavItem(
                      context, 
                      SidebarMenu.saving, 
                      CupertinoIcons.chart_bar_alt_fill, 
                      "Tabungan",
                      trailing: fmt.format(finance.totalSavingBalance),
                    ),
                    const SizedBox(height: 0),
                    _buildNavItem(
                      context, 
                      SidebarMenu.deposit, 
                      Icons.monetization_on_rounded, 
                      "Deposit",
                      trailing: fmt.format(finance.totalDepositBalance),
                    ),
                    const SizedBox(height: 0),
                    _buildNavItem(
                      context, 
                      SidebarMenu.debt, 
                      Icons.description_rounded, 
                      "Hutang",
                      trailing: fmt.format(finance.totalDebt),
                    ),
                    const SizedBox(height: 0),
                    _buildNavItem(
                      context, 
                      SidebarMenu.danaVsTagihan, 
                      Icons.swap_vert_circle_rounded, 
                      "Dana vs Tagihan",
                      trailing: (finance.currentMonthDanaVsTagihanDiff < 0 ? "-" : "") + fmt.format(finance.currentMonthDanaVsTagihanDiff.abs()),
                      trailingColor: finance.currentMonthDanaVsTagihanDiff < 0 ? Colors.redAccent : Colors.green[700],
                    ),
                  ],
                ),
              ),
              
              // Net Worth Card
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: NetWorthCard(
                  padding: 18,
                  fontSizeLabel: 11,
                  fontSizeAmount: 18,
                  fontSizePercent: 12,
                  borderRadius: 24,
                ),
              ),

              // Tagihan Koko Section (Bottom)
              const TagihanKokoSidebar(),
              const SizedBox(height: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, SidebarMenu menu, IconData icon, String title, {String? trailing, Color? trailingColor}) {
    final navProvider = context.read<NavigationProvider>();
    final isActive = navProvider.currentMenu == menu;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => navProvider.setMenu(menu),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.black.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: Colors.black,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (trailing != null)
                Padding(
                  padding: const EdgeInsets.only(left: 40, top: 2),
                  child: Text(
                    trailing,
                    style: TextStyle(
                      color: trailingColor ?? Colors.black.withOpacity(0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
