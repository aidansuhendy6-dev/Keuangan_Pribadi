import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction_model.dart';

class TransactionExportWidget extends StatelessWidget {
  final List<Transaction> transactions;
  final String title;
  final String dateRange;

  const TransactionExportWidget({
    super.key,
    required this.transactions,
    required this.title,
    required this.dateRange,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    double totalModal = 0;
    double totalJual = 0;
    double totalLaba = 0;

    for (var t in transactions) {
      totalModal += t.modal ?? 0;
      totalJual += t.jual ?? 0;
      totalLaba += t.amount;
    }

    return Container(
      width: 800,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.bold, 
              color: Colors.black,
              fontFamily: 'Roboto', // Pastikan font standar
            ),
          ),
          const SizedBox(height: 12),
          Text(
            dateRange,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          Table(
            border: TableBorder(
              horizontalInside: BorderSide(color: Colors.grey.shade200, width: 0.5),
              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
              top: BorderSide(color: Colors.grey.shade300, width: 1),
              left: BorderSide(color: Colors.grey.shade300, width: 1),
              right: BorderSide(color: Colors.grey.shade300, width: 1),
            ),
            columnWidths: const {
              0: FlexColumnWidth(3.5), // Belanja
              1: FlexColumnWidth(1.2), // Jenis
              2: FlexColumnWidth(2), // Modal
              3: FlexColumnWidth(2), // Jual
              4: FlexColumnWidth(2), // Laba
            },
            children: [
              // Header
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFF34C759)),
                children: [
                  _buildHeaderCell("Belanja"),
                  _buildHeaderCell("Jenis"),
                  _buildHeaderCell("Modal"),
                  _buildHeaderCell("Jual"),
                  _buildHeaderCell("Laba", color: Colors.orange),
                ],
              ),
              // Data
              ...transactions.map((t) {
                final isJastip = t.incomeType == 'Jastip';
                final isBonus = t.incomeType == 'Bonus';
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.description,
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFmt.format(t.date),
                            style: const TextStyle(color: Colors.grey, fontSize: 9),
                          ),
                        ],
                      ),
                    ),
                    _buildDataCell(
                      t.incomeType ?? (t.type == 'income' ? 'Normal' : '-'),
                      color: isBonus ? Colors.orange : (isJastip ? Colors.black : Colors.grey),
                    ),
                    _buildCurrencyCell(t.modal ?? 0),
                    _buildCurrencyCell(t.jual ?? 0),
                    _buildCurrencyCell(t.amount, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                  ],
                );
              }).toList(),
              // Total
              TableRow(
                decoration: BoxDecoration(color: Colors.grey.shade100),
                children: [
                  _buildDataCell("Total", fontWeight: FontWeight.bold, align: TextAlign.left),
                  const SizedBox(),
                  _buildCurrencyCell(totalModal, fontWeight: FontWeight.bold),
                  _buildCurrencyCell(totalJual, fontWeight: FontWeight.bold),
                  _buildCurrencyCell(totalLaba, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                ],
              ),
            ],
          ),
          const SizedBox(height: 40),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "Dicetak pada: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}",
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {Color? color}) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {Color? color, FontWeight? fontWeight, TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: fontWeight, fontSize: 12),
        textAlign: align,
      ),
    );
  }

  Widget _buildCurrencyCell(double amount, {Color? color, FontWeight? fontWeight}) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Row(
        children: [
          const Text("Rp", style: TextStyle(fontSize: 10, color: Colors.grey)),
          const Spacer(),
          Text(
            formatter.format(amount).trim(),
            style: TextStyle(color: color, fontWeight: fontWeight, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
