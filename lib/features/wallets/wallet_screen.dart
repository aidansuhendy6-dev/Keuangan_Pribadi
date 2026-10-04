import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/finance_provider.dart';
import '../../models/wallet_model.dart';
import 'widgets/wallet_card.dart';
import 'widgets/wallet_transaction_list.dart';
import '../../core/responsive.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Get specific wallets or defaults
    final bcaWallet = finance.wallets.firstWhere((w) => w.name.contains('BCA'), orElse: () => Wallet(id: '1', name: 'BCA', balance: 0));
    final cashWallet = finance.wallets.firstWhere((w) => w.name.contains('Cash'), orElse: () => Wallet(id: '2', name: 'Cash', balance: 0));
    final shopeeWallet = finance.wallets.firstWhere((w) => w.name.contains('Shopee'), orElse: () => Wallet(id: '3', name: 'ShopeePay', balance: 0));

    // Filter transactions for each wallet
    final bcaTxs = finance.transactions.where((t) => t.categoryId == bcaWallet.id).toList();
    final cashTxs = finance.transactions.where((t) => t.categoryId == cashWallet.id).toList();
    final shopeeTxs = finance.transactions.where((t) => t.categoryId == shopeeWallet.id).toList();

    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? const EdgeInsets.fromLTRB(20, 16, 20, 32) : const EdgeInsets.fromLTRB(40, 24, 40, 48);

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                "Daftar Dompet",
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: isMobile ? 22 : 24,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 24 : 32),
          if (isMobile)
            Column(
              children: [
                _buildWalletColumn(finance, bcaWallet, bcaTxs, fmt, "assets/icons/logo_bca.png", const Color(0xFF005CAA), [Color(0xFF005CAA), Color(0xFF003D73)], context),
                const SizedBox(height: 24),
                _buildWalletColumn(finance, cashWallet, cashTxs, fmt, "assets/icons/logo_cash.png", const Color(0xFF27D17F), [Color(0xFF27D17F), Color(0xFF1E9B5E)], context),
                const SizedBox(height: 24),
                _buildWalletColumn(finance, shopeeWallet, shopeeTxs, fmt, "assets/icons/logo_shopeepay.png", const Color(0xFFEE4D2D), [Color(0xFFEE4D2D), Color(0xFFC43E25)], context, logoH: 40),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildWalletColumn(finance, bcaWallet, bcaTxs, fmt, "assets/icons/logo_bca.png", const Color(0xFF005CAA), [Color(0xFF005CAA), Color(0xFF003D73)], context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildWalletColumn(finance, cashWallet, cashTxs, fmt, "assets/icons/logo_cash.png", const Color(0xFF27D17F), [Color(0xFF27D17F), Color(0xFF1E9B5E)], context),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildWalletColumn(finance, shopeeWallet, shopeeTxs, fmt, "assets/icons/logo_shopeepay.png", const Color(0xFFEE4D2D), [Color(0xFFEE4D2D), Color(0xFFC43E25)], context, logoH: 40),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWalletColumn(FinanceProvider finance, Wallet wallet, List<dynamic> txs, NumberFormat fmt, String logo, Color color, List<Color> gradient, BuildContext context, {double logoH = 32}) {
    return Column(
      children: [
        WalletCard(
          name: wallet.name,
          balance: fmt.format(wallet.balance),
          logoAsset: logo,
          backgroundColor: color,
          gradientColors: gradient,
          logoHeight: logoH,
          onEdit: () => _showEditBalanceDialog(context, finance, wallet),
        ),
        const SizedBox(height: 24),
        WalletTransactionList(
          transactions: txs.cast(),
          onDelete: (tx) => finance.removeTransaction(tx),
        ),
      ],
    );
  }

  void _showEditBalanceDialog(BuildContext context, FinanceProvider finance, Wallet wallet) {
    final controller = TextEditingController(text: wallet.balance.toInt().toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Saldo ${wallet.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal Baru',
            border: OutlineInputBorder(),
            prefixText: 'Rp ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final newBalance = double.tryParse(controller.text) ?? wallet.balance;
              finance.manualUpdateWalletBalance(wallet.id, newBalance);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
