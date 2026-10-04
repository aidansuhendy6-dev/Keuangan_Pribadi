import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/finance_provider.dart';

class FinancialReportWidget extends StatelessWidget {
  final FinanceProvider finance;
  final String dateTimeString;

  const FinancialReportWidget({
    super.key,
    required this.finance,
    required this.dateTimeString,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    const double rowHeight = 32.0;
    const TextStyle headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black);
    const TextStyle labelStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black);
    const TextStyle amountStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);

    return Container(
      width: 600,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateTimeString,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 15),
          
          // SALDO SECTION
          _buildHeader("SALDO", const Color(0xFF96D27A)),
          
          // Row 1: Dompet
          _buildCategoryRow(
            number: "1",
            title: "Dompet",
            titleColor: const Color(0xFF6DA9C7),
            items: [
              _ReportItem("BCA", finance.wallets.firstWhere((w) => w.name == "BCA", orElse: () => finance.wallets.first).balance, const Color(0xFF2C7FB8)),
              _ReportItem("Cash", finance.wallets.firstWhere((w) => w.name == "Cash", orElse: () => finance.wallets.first).balance, const Color(0xFF3B9E3B)),
              _ReportItem("Shopeepay", finance.wallets.firstWhere((w) => w.name == "Shopeepay", orElse: () => finance.wallets.first).balance, const Color(0xFFD97706)),
            ],
            total: finance.wallets.fold(0.0, (sum, w) => sum + w.balance),
            totalColor: const Color(0xFF86B96F),
            fmt: fmt,
          ),

          // Row 2: Tabungan
          _buildCategoryRow(
            number: "2",
            title: "Tabungan",
            titleColor: const Color(0xFF86B96F),
            items: [
              _ReportItem("Tabungan Argand", finance.savings.where((s) => s.name.contains("Argand")).fold(0.0, (sum, s) => sum + s.currentAmount), const Color(0xFF2C7FB8)),
              _ReportItem("Khitan Argand", 0, const Color(0xFF3B9E3B)), // Mock if not found, or use real data
              _ReportItem("Bayar Spaylater", 0, const Color(0xFFD97706)),
            ],
            total: finance.savings.fold(0.0, (sum, s) => sum + s.currentAmount),
            totalColor: const Color(0xFF86B96F),
            fmt: fmt,
            customItems: [
              ...finance.savings.map((s) => _ReportItem(s.name, s.currentAmount, const Color(0xFF2C7FB8))).toList(),
            ],
          ),

          // Row 3: Deposit (Piutang)
          _buildCategoryRow(
            number: "3",
            title: "Deposit",
            titleColor: const Color(0xFF2C7FB8),
            items: [
              _ReportItem("Tagihan koko", finance.kokoPiutangBalance, const Color(0xFFB91C1C)),
              _ReportItem("Deposit", finance.depPiutangBalance, const Color(0xFF2C7FB8)),
              _ReportItem("Bonus", finance.bonusPiutangBalance, const Color(0xFF3B9E3B)),
            ],
            total: finance.kokoPiutangBalance + finance.depPiutangBalance + finance.bonusPiutangBalance,
            totalColor: const Color(0xFF2C7FB8),
            fmt: fmt,
          ),

          // Total Saldo
          _buildTotalFooter("Total Saldo", finance.totalBalance, fmt),

          const SizedBox(height: 25),

          // HUTANG SECTION
          _buildHeader("HUTANG", const Color(0xFFF7A399)),
          
          _buildCategoryRow(
            number: "",
            title: "Hutang",
            titleColor: const Color(0xFFB91C1C),
            items: [
              _ReportItem("Kartu Kredit BCA", finance.bcaDebtBalance, const Color(0xFF2C7FB8)),
              _ReportItem("Spaylater", finance.spaylaterDebtBalance, const Color(0xFFD97706)),
              _ReportItem("Hutang Lainnya", finance.otherDebtBalance, const Color(0xFFB91C1C)),
            ],
            total: finance.totalDebt,
            totalColor: const Color(0xFFB91C1C),
            fmt: fmt,
            showNumber: false,
          ),

          // Total Hutang
          _buildTotalFooter("Total Hutang", finance.totalDebt, fmt),

          const SizedBox(height: 25),

          // Net Worth
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 2),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Kekayaan Bersih",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
                ),
                Text(
                  (finance.netWorth < 0 ? "-" : "") + "Rp" + fmt.format(finance.netWorth.abs()),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: finance.netWorth < 0 ? const Color(0xFFB91C1C) : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String text, Color color) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      alignment: Alignment.center,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.black),
      ),
    );
  }

  Widget _buildCategoryRow({
    required String number,
    required String title,
    required Color titleColor,
    required List<_ReportItem> items,
    required double total,
    required Color totalColor,
    required NumberFormat fmt,
    bool showNumber = true,
    List<_ReportItem>? customItems,
  }) {
    final displayItems = customItems ?? items;
    
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showNumber)
            Container(
              width: 40,
              decoration: const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Colors.black, width: 2),
                  bottom: BorderSide(color: Colors.black, width: 2),
                  right: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              alignment: Alignment.center,
              child: Text(number, style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.black)),
            ),
          Container(
            width: 90,
            decoration: BoxDecoration(
              border: Border(
                left: showNumber ? BorderSide.none : const BorderSide(color: Colors.black, width: 2),
                bottom: const BorderSide(color: Colors.black, width: 2),
                right: const BorderSide(color: Colors.black, width: 2),
              ),
            ),
            alignment: Alignment.center,
            child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: titleColor, fontSize: 13)),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                ),
              ),
              child: Column(
                children: displayItems.map((item) => _buildItemRow(item, fmt)).toList(),
              ),
            ),
          ),
          Container(
            width: 110,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.black, width: 2),
                bottom: BorderSide(color: Colors.black, width: 2),
                right: BorderSide(color: Colors.black, width: 2),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Rp", style: TextStyle(fontWeight: FontWeight.w900, color: totalColor, fontSize: 12)),
                const SizedBox(width: 4),
                Text(fmt.format(total), style: TextStyle(fontWeight: FontWeight.w900, color: totalColor, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(_ReportItem item, NumberFormat fmt) {
    return Container(
      height: 28,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(item.name, style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          Text("Rp", style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              fmt.format(item.value),
              textAlign: TextAlign.right,
              style: TextStyle(color: item.color, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter(String label, double total, NumberFormat fmt) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Colors.black, width: 2),
          bottom: BorderSide(color: Colors.black, width: 2),
          right: BorderSide(color: Colors.black, width: 2),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          Row(
            children: [
              const Text("Rp", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              const SizedBox(width: 8),
              Text(fmt.format(total), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportItem {
  final String name;
  final double value;
  final Color color;

  _ReportItem(this.name, this.value, this.color);
}
