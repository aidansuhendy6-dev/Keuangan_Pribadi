import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

class WalletTransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(Transaction) onDelete;

  const WalletTransactionList({
    super.key,
    required this.transactions,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMMM yyyy HH:mm', 'id_ID');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final tx = transactions[index];
          final isIncome = tx.type == 'income';
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isIncome ? Colors.green : Colors.red).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                    size: 16,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${dateFmt.format(tx.date)} • ${tx.categoryType == 'wallet' ? 'Dompet' : 'Lainnya'}",
                        style: TextStyle(
                          color: Colors.black38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${isIncome ? '+' : '-'} ${fmt.format(tx.amount)}",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isIncome ? Colors.green : Colors.red,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => onDelete(tx),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.black26,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
