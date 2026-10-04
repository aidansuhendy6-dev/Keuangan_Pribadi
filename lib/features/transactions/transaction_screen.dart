import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/finance_provider.dart';
import '../../models/transaction_model.dart';
import 'widgets/add_transaction_dialog.dart';
import '../../core/responsive.dart';

import 'package:screenshot/screenshot.dart';
import '../../services/export_service/export_service.dart';
import 'widgets/transaction_export_widget.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _filter = 'all'; // 'all', 'income', 'expense'
  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _handleDownload(FinanceProvider finance, List<Transaction> filteredTransactions) async {
    try {
      final now = DateTime.now();
      final monthName = DateFormat('MMMM yyyy', 'id_ID').format(now);
      
      String title = "Riwayat Transaksi";
      if (_filter == 'income') title = "Data Pemasukan - $monthName";
      if (_filter == 'expense') title = "Data Pengeluaran - $monthName";
      if (_filter == 'all') title = "Semua Transaksi - $monthName";

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Menyiapkan file gambar...")),
      );

      // Hitung estimasi tinggi berdasarkan jumlah transaksi agar tidak overflow
      // Mengingat ada tambahan tanggal di bawah judul, kita tingkatkan buffer tinggi per baris
      final estimatedHeight = (filteredTransactions.length * 80.0) + 400.0;

      final image = await screenshotController.captureFromWidget(
        Material(
          child: TransactionExportWidget(
            transactions: filteredTransactions,
            title: title,
            dateRange: monthName,
          ),
        ),
        delay: const Duration(milliseconds: 200),
        targetSize: Size(800, estimatedHeight),
      );

      final fileName = "Riwayat_${_filter}_${DateFormat('yyyyMMdd_HHmm').format(now)}";
      final success = await ExportService.saveImage(image, fileName);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Berhasil disimpan ke galeri!")),
        );
      } else {
        throw Exception("Gagal menyimpan gambar");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd MMMM yyyy HH:mm', 'id_ID');

    final now = DateTime.now();
    final filteredTransactions = finance.transactions.where((t) {
      final isSameMonth = t.date.year == now.year && t.date.month == now.month;
      if (!isSameMonth) return false;
      
      if (_filter == 'all') return true;
      return t.type == _filter;
    }).toList();

    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? const EdgeInsets.fromLTRB(20, 16, 20, 32) : const EdgeInsets.all(40.0);

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Builder(
                        builder: (context) => IconButton(
                          onPressed: () => Scaffold.of(context).openDrawer(),
                          icon: const Icon(Icons.menu, color: Colors.black87),
                        ),
                      ),
                    ),
                    const Text(
                      "Riwayat Transaksi",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _handleDownload(finance, filteredTransactions),
                      icon: const Icon(Icons.download_for_offline, color: Colors.green, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Semua", 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip("Pemasukan", 'income'),
                      const SizedBox(width: 8),
                      _buildFilterChip("Pengeluaran", 'expense'),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Riwayat Transaksi",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -1.0),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _handleDownload(finance, filteredTransactions),
                      icon: const Icon(Icons.download_for_offline, color: Colors.green, size: 28),
                      tooltip: "Download JPG",
                    ),
                    const SizedBox(width: 16),
                    _buildFilterChip("Semua", 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip("Pemasukan", 'income'),
                    const SizedBox(width: 8),
                    _buildFilterChip("Pengeluaran", 'expense'),
                  ],
                ),
              ],
            ),
          SizedBox(height: isMobile ? 24 : 32),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: filteredTransactions.isEmpty
                    ? const Center(child: Text("Belum ada data transaksi"))
                    : _filter == 'income'
                        ? _buildIncomeTable(filteredTransactions, fmt, dateFmt, isMobile)
                        : ListView.separated(
                            itemCount: filteredTransactions.length,
                            separatorBuilder: (context, index) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final t = filteredTransactions[index];
                              final isIncome = t.type == 'income';
                              return ListTile(
                                onTap: () => _showEditTransactionDialog(context, t),
                                contentPadding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: (isIncome ? Colors.green : Colors.red).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isIncome ? Colors.green : Colors.red,
                                    size: isMobile ? 20 : 24,
                                  ),
                                ),
                                title: Text(
                                  t.description,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 16),
                                ),
                                subtitle: Text(
                                  "${dateFmt.format(t.date)} • ${t.categoryType == 'wallet' ? 'Dompet' : 'Hutang'}",
                                  style: TextStyle(color: Colors.grey, fontSize: isMobile ? 11 : 13),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "${isIncome ? '+' : '-'} ${fmt.format(t.amount)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: isMobile ? 14 : 16,
                                        color: isIncome ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    SizedBox(width: isMobile ? 8 : 16),
                                    IconButton(
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      icon: Icon(Icons.delete_outline, color: Colors.grey, size: isMobile ? 20 : 24),
                                      onPressed: () => _showDeleteConfirm(context, t),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomeTable(List<Transaction> transactions, NumberFormat fmt, DateFormat dateFmt, bool isMobile) {
    double totalModal = 0;
    double totalJual = 0;
    double totalLaba = 0;

    for (var t in transactions) {
      totalModal += t.modal ?? 0;
      totalJual += t.jual ?? 0;
      totalLaba += t.amount;
    }

    // Format khusus mobile tanpa "Rp " untuk menghemat ruang
    final mobileFmt = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final displayFmt = isMobile ? mobileFmt : fmt;

    return SingleChildScrollView(
      child: Table(
        columnWidths: isMobile 
          ? const {
              0: FlexColumnWidth(2.5), // Belanja
              1: FlexColumnWidth(1.2), // Jenis
              2: FlexColumnWidth(1.8), // Modal
              3: FlexColumnWidth(1.8), // Jual
              4: FlexColumnWidth(2.2), // Laba
              5: FixedColumnWidth(35), // Actions
            }
          : const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.5),
              2: FlexColumnWidth(2),
              3: FlexColumnWidth(2),
              4: FlexColumnWidth(2),
              5: FixedColumnWidth(50),
            },
        children: [
          // Header
          TableRow(
            decoration: const BoxDecoration(color: Colors.green),
            children: [
              _buildHeaderCell("Belanja", isMobile: isMobile),
              _buildHeaderCell("Jenis", isMobile: isMobile),
              _buildHeaderCell(isMobile ? "Mdl" : "Modal", isMobile: isMobile),
              _buildHeaderCell(isMobile ? "Jual" : "Jual", isMobile: isMobile),
              _buildHeaderCell(isMobile ? "Laba" : "Laba", color: Colors.orange, isMobile: isMobile),
              const SizedBox(),
            ],
          ),
          // Data
          ...transactions.map((t) {
            final isJastip = t.incomeType == 'Jastip';
            final isBonus = t.incomeType == 'Bonus';
            
            return TableRow(
              children: [
                GestureDetector(
                  onTap: () => _showEditTransactionDialog(context, t),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          t.description, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFmt.format(t.date),
                          style: TextStyle(color: Colors.grey, fontSize: isMobile ? 8 : 10),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditTransactionDialog(context, t),
                  child: _buildDataCell(
                    t.incomeType ?? 'Normal',
                    color: isBonus ? Colors.orange : (isJastip ? Colors.black : Colors.grey),
                    isMobile: isMobile,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showEditTransactionDialog(context, t),
                  child: _buildDataCell(displayFmt.format(t.modal ?? 0).trim(), isMobile: isMobile),
                ),
                GestureDetector(
                  onTap: () => _showEditTransactionDialog(context, t),
                  child: _buildDataCell(displayFmt.format(t.jual ?? 0).trim(), isMobile: isMobile),
                ),
                GestureDetector(
                  onTap: () => _showEditTransactionDialog(context, t),
                  child: _buildDataCell(
                    displayFmt.format(t.amount).trim(), 
                    fontWeight: FontWeight.bold, 
                    color: Colors.orange[800],
                    isMobile: isMobile,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: isMobile ? 4 : 8),
                  child: IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.grey, size: isMobile ? 18 : 20),
                    onPressed: () => _showDeleteConfirm(context, t),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            );
          }).toList(),
          // Total
          TableRow(
            decoration: BoxDecoration(color: Colors.grey[100]),
            children: [
              _buildDataCell("Total", fontWeight: FontWeight.bold, isMobile: isMobile),
              const SizedBox(),
              _buildDataCell(displayFmt.format(totalModal).trim(), fontWeight: FontWeight.bold, isMobile: isMobile),
              _buildDataCell(displayFmt.format(totalJual).trim(), fontWeight: FontWeight.bold, isMobile: isMobile),
              _buildDataCell(displayFmt.format(totalLaba).trim(), fontWeight: FontWeight.bold, color: Colors.green[700], isMobile: isMobile),
              const SizedBox(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {Color? color, bool isMobile = false}) {
    return Container(
      color: color,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 2),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white, 
          fontWeight: FontWeight.bold,
          fontSize: isMobile ? 11 : 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {Color? color, FontWeight? fontWeight, bool isMobile = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 12, horizontal: 2),
      child: Text(
        text,
        style: TextStyle(
          color: color, 
          fontWeight: fontWeight,
          fontSize: isMobile ? 10 : 13,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) setState(() => _filter = value);
      },
      selectedColor: Colors.black,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
    );
  }

  void _showDeleteConfirm(BuildContext context, Transaction t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Transaksi?"),
        content: const Text("Saldo akan dikembalikan secara otomatis sesuai nilai transaksi ini."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
          TextButton(
            onPressed: () async {
              await context.read<FinanceProvider>().removeTransaction(t);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Hapus", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AddTransactionDialog(
        type: transaction.type,
        transaction: transaction,
      ),
    );
  }
}
