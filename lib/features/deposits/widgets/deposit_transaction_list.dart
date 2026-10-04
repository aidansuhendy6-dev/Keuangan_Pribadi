import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';

class DepositTransactionList extends StatelessWidget {
  final List<dynamic> items;
  final Function(dynamic) onDelete;
  final Function(dynamic) onSettle;
  final Function(dynamic) onEdit;

  const DepositTransactionList({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onSettle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMMM yyyy', 'id_ID');

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
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final item = items[index];
          
          if (item is Debt) {
            return _buildPaylaterItem(context, item, fmt, dateFmt);
          } else if (item is RecurringBill) {
            return _buildInstallmentItem(context, item, fmt, dateFmt);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPaylaterItem(BuildContext context, Debt item, NumberFormat fmt, DateFormat dateFmt) {
    // Clean name from prefix for display
    final cleanName = item.name.substring(item.name.indexOf(']') + 1).trim();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          _buildIcon(true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cleanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: -0.3)),
                const SizedBox(height: 4),
                Text(
                  "${item.dueDate != null ? dateFmt.format(item.dueDate!) : 'Tanpa jatuh tempo'} • Paylater",
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "+ ${fmt.format(item.totalAmount)}",
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.green, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              _buildActions(item),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(BuildContext context, RecurringBill item, NumberFormat fmt, DateFormat dateFmt) {
    final cleanName = item.name.substring(item.name.indexOf(']') + 1).trim();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIcon(true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cleanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: -0.3)),
                          const SizedBox(height: 4),
                          Text(
                            "Jatuh tempo: ${dateFmt.format(item.nextDueDate)}",
                            style: const TextStyle(color: Colors.black38, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmt.format(item.amount),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text("Cicilan", style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: Colors.black.withOpacity(0.05),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00C2FF)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        "${item.currentPaidTenor}/${item.totalTenor}",
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black54),
                      ),
                    ),
                    Text(
                      "Sisa ${fmt.format(item.remainingAmount)}",
                      style: const TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildActions(item),
        ],
      ),
    );
  }

  Widget _buildActions(dynamic item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: Icons.check_circle_outline,
          color: Colors.green,
          onTap: () => onSettle(item),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.edit_outlined,
          color: Colors.blue,
          onTap: () => onEdit(item),
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: Icons.delete_outline,
          color: Colors.red,
          onTap: () => onDelete(item),
        ),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color.withOpacity(0.8)),
      ),
    );
  }

  Widget _buildIcon(bool isIncome) {
    return Container(
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
    );
  }
}

