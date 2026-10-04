import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';

class DebtBillList extends StatelessWidget {
  final List<dynamic> items;
  final Function(dynamic) onDelete;
  final Function(dynamic) onSettle;
  final Function(dynamic) onEdit;

  const DebtBillList({
    super.key,
    required this.items,
    required this.onDelete,
    required this.onSettle,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');

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
      child: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: Text("Belum ada tagihan aktif", style: TextStyle(color: Colors.grey, fontSize: 13))),
            )
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is Debt) {
                  return _buildPaylaterItem(item, fmt, dateFmt);
                } else if (item is RecurringBill) {
                  return _buildInstallmentItem(item, fmt);
                }
                return const SizedBox.shrink();
              },
            ),
    );
  }

  Widget _buildPaylaterItem(Debt debt, NumberFormat fmt, DateFormat dateFmt) {
    // Clean name from prefix
    final cleanName = debt.name.replaceAll(RegExp(r'\[.*?\] '), '');
    final isDueSoon = debt.dueDate != null && debt.dueDate!.isBefore(DateTime.now().add(const Duration(days: 7)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.credit_card, size: 20, color: Color(0xFF003366)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cleanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  debt.dueDate != null ? "Jatuh tempo: ${dateFmt.format(debt.dueDate!)}" : "Tanpa jatuh tempo",
                  style: const TextStyle(color: Colors.black38, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmt.format(debt.remainingAmount),
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isDueSoon)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Segera",
                        style: TextStyle(color: Colors.orange, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  _buildActions(debt),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(RecurringBill bill, NumberFormat fmt) {
    final cleanName = bill.name.replaceAll(RegExp(r'\[.*?\] '), '');
    final dateFmt = DateFormat('dd MMM yyyy', 'id_ID');
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, size: 20, color: Color(0xFF003366)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cleanName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          fmt.format(bill.amount),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Jatuh tempo: ${dateFmt.format(bill.nextDueDate)}",
                          style: const TextStyle(color: Colors.black38, fontSize: 11),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                "Cicilan",
                                style: TextStyle(color: Colors.blue, fontSize: 9, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildActions(bill),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: bill.progress,
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "${bill.currentPaidTenor ?? 0}/${bill.totalTenor}",
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black54),
                ),
              ),
              Text(
                "Sisa ${fmt.format(bill.remainingAmount)}",
                style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
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
        child: Icon(icon, size: 14, color: color.withOpacity(0.8)),
      ),
    );
  }
}
