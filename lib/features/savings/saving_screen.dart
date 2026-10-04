import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/finance_provider.dart';
import '../../models/saving_model.dart';
import 'widgets/saving_card.dart';
import 'widgets/saving_transaction_list.dart';
import 'widgets/saving_transfer_dialog.dart';
import '../../core/responsive.dart';

class SavingScreen extends StatelessWidget {
  const SavingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Get specific savings or defaults
    final tabunganArgand = finance.savings.firstWhere((s) => s.name.contains('Tabungan Argand'), orElse: () => Saving(id: 's1', name: 'Tabungan Argand', currentAmount: 0));
    final khitanArgand = finance.savings.firstWhere((s) => s.name.contains('Khitan Argand'), orElse: () => Saving(id: 's2', name: 'Khitan Argand', currentAmount: 0));
    final spaylater = finance.savings.firstWhere((s) => s.name.contains('Spaylater'), orElse: () => Saving(id: 's3', name: 'Bayar Spaylater', currentAmount: 0));

    // Filter transactions for each saving
    final argandTxs = finance.transactions.where((t) => t.categoryId == tabunganArgand.id).toList();
    final khitanTxs = finance.transactions.where((t) => t.categoryId == khitanArgand.id).toList();
    final spaylaterTxs = finance.transactions.where((t) => t.categoryId == spaylater.id).toList();

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
                      padding: const EdgeInsets.only(right: 8),
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu, color: Colors.black87),
                        ),
                      ),
                    ),
                  Text(
                    "Daftar Tabungan",
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
                  // Tombol Menabung (+)
                  _buildHeaderButton(
                    context, 
                    icon: Icons.add, 
                    color: Colors.green, 
                    onTap: () => showDialog(
                      context: context, 
                      builder: (context) => const SavingTransferDialog(mode: 'plus'),
                    ),
                    isMobile: isMobile,
                  ),
                  SizedBox(width: isMobile ? 8 : 16),
                  // Tombol Mencairkan (-)
                  _buildHeaderButton(
                    context, 
                    icon: Icons.remove, 
                    color: Colors.red, 
                    onTap: () => showDialog(
                      context: context, 
                      builder: (context) => const SavingTransferDialog(mode: 'minus'),
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
                _buildSavingColumn(finance, tabunganArgand, argandTxs, fmt, Icons.trending_up, const Color(0xFF00C2FF), [Color(0xFF00C2FF), Color(0xFF009FD1)]),
                const SizedBox(height: 24),
                _buildSavingColumn(finance, khitanArgand, khitanTxs, fmt, Icons.child_care, const Color(0xFF27D17F), [Color(0xFF27D17F), Color(0xFF1E9B5E)]),
                const SizedBox(height: 24),
                _buildSavingColumn(finance, spaylater, spaylaterTxs, fmt, Icons.receipt_long, const Color(0xFFEE4D2D), [Color(0xFFEE4D2D), Color(0xFFC43E25)]),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildSavingColumn(finance, tabunganArgand, argandTxs, fmt, Icons.trending_up, const Color(0xFF00C2FF), [Color(0xFF00C2FF), Color(0xFF009FD1)]),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildSavingColumn(finance, khitanArgand, khitanTxs, fmt, Icons.child_care, const Color(0xFF27D17F), [Color(0xFF27D17F), Color(0xFF1E9B5E)]),
                ),
                const SizedBox(width: 32),
                Expanded(
                  child: _buildSavingColumn(finance, spaylater, spaylaterTxs, fmt, Icons.receipt_long, const Color(0xFFEE4D2D), [Color(0xFFEE4D2D), Color(0xFFC43E25)]),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSavingColumn(FinanceProvider finance, Saving saving, List<dynamic> txs, NumberFormat fmt, IconData icon, Color color, List<Color> gradient) {
    return Column(
      children: [
        SavingCard(
          name: saving.name,
          balance: fmt.format(saving.currentAmount),
          icon: icon,
          backgroundColor: color,
          gradientColors: gradient,
        ),
        const SizedBox(height: 24),
        SavingTransactionList(
          transactions: txs.cast(),
          onDelete: (tx) => finance.removeTransaction(tx),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(BuildContext context, {required IconData icon, required Color color, required VoidCallback onTap, bool isMobile = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
    );
  }
}
