import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import 'package:keuangan_pribadi/services/navigation_provider.dart';
import 'package:intl/intl.dart';
import 'package:keuangan_pribadi/services/finance_provider.dart';

class MobileDrawer extends StatelessWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final navProvider = context.watch<NavigationProvider>();
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Elegant Green Header Profile
          Container(
            padding: const EdgeInsets.fromLTRB(24, 52, 24, 20),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F4D32), // Forest Green Dark
                  Color(0xFF1A744C), // Elegant Emerald
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Image.network(
                    'https://xbtdqjfmgthbnbgyujkv.supabase.co/storage/v1/object/public/Logo/logo_uang.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Aidan Suhendy",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const Text(
                  "Keuangan Pribadi",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildDrawerItem(context, SidebarMenu.dashboard, Icons.grid_view_rounded, "Dashboard"),
                _buildDrawerItem(
                  context, 
                  SidebarMenu.wallet, 
                  Icons.account_balance_wallet, 
                  "Dompet",
                  subtitle: fmt.format(finance.totalWalletBalance),
                ),
                _buildDrawerItem(
                  context, 
                  SidebarMenu.saving, 
                  CupertinoIcons.chart_bar_alt_fill, 
                  "Tabungan",
                  subtitle: fmt.format(finance.totalSavingBalance),
                ),
                _buildDrawerItem(
                  context, 
                  SidebarMenu.deposit, 
                  Icons.monetization_on_rounded, 
                  "Deposit",
                  subtitle: fmt.format(finance.totalDepositBalance),
                ),
                _buildDrawerItem(
                  context, 
                  SidebarMenu.debt, 
                  Icons.description_rounded, 
                  "Hutang",
                  subtitle: fmt.format(finance.totalDebt),
                ),
                _buildDrawerItem(
                  context, 
                  SidebarMenu.tagihanKoko, 
                  CupertinoIcons.square_list_fill, 
                  "Tagihan Koko",
                  subtitle: fmt.format(finance.roundedKokoBillTotal),
                ),
                _buildDrawerItem(
                  context, 
                  SidebarMenu.danaVsTagihan, 
                  Icons.swap_vert_circle_rounded, 
                  "Dana vs Tagihan",
                  subtitle: (finance.currentMonthDanaVsTagihanDiff < 0 ? "-" : "") + fmt.format(finance.currentMonthDanaVsTagihanDiff.abs()),
                  subtitleColor: finance.currentMonthDanaVsTagihanDiff < 0 ? Colors.redAccent : Colors.green[700],
                ),
                _buildDrawerItem(context, SidebarMenu.transaction, Icons.history_rounded, "Riwayat"),
              ],
            ),
          ),
          
          // Memberikan padding bawah agar list tidak terlalu mepet ke ujung layar
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, SidebarMenu menu, IconData icon, String title, {String? subtitle, Color? subtitleColor}) {
    final navProvider = context.read<NavigationProvider>();
    final isActive = navProvider.currentMenu == menu;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: ListTile(
        onTap: () {
          navProvider.setMenu(menu);
          Navigator.pop(context); // Close drawer
        },
        selected: isActive,
        selectedTileColor: Colors.black.withOpacity(0.06),
        leading: Icon(
          icon,
          color: Colors.black,
          size: 22,
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            letterSpacing: -0.5,
          ),
        ),
        subtitle: subtitle != null 
          ? Text(
              subtitle,
              style: TextStyle(
                color: subtitleColor ?? Colors.black.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            )
          : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
