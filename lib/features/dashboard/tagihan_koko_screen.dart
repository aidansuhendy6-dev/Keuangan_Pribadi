import 'dart:html' as html;
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/koko_exporter.dart';
import '../../core/responsive.dart';

import '../../models/koko_bill_model.dart';
import '../../services/finance_provider.dart';
import '../../core/widgets/apple_date_picker.dart';

class TagihanKokoScreen extends StatefulWidget {
  const TagihanKokoScreen({super.key});

  @override
  State<TagihanKokoScreen> createState() => _TagihanKokoScreenState();
}

class _TagihanKokoScreenState extends State<TagihanKokoScreen> {
  bool _isUploading = false;
  bool _isDeletingReceipt = false;

  final Map<String, TextEditingController> _titleControllers = {};
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, FocusNode> _titleFocusNodes = {};
  final Map<String, FocusNode> _amountFocusNodes = {};
  final GlobalKey _exportKey = GlobalKey();

  @override
  void dispose() {
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    for (final node in _titleFocusNodes.values) {
      node.dispose();
    }
    for (final node in _amountFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? const EdgeInsets.fromLTRB(20, 16, 20, 32) : const EdgeInsets.all(40.0);

    return Consumer<FinanceProvider>(
      builder: (context, p, _) {
        final period = p.activeKokoPeriod;
        final start = period != null ? DateTime.parse(period.startDate) : DateTime.now();
        final end = period != null ? DateTime.parse(period.endDate) : DateTime.now().add(const Duration(days: 14));
        final diff = end.difference(start).inDays;

        final Map<String, int> notaMap = {};
        int currentNota = 1;
        for (final e in p.whiteKostEntries) {
          if (e.receiptUrl != null && e.receiptUrl!.isNotEmpty) notaMap[e.id ?? ''] = currentNota++;
        }
        for (final e in p.mykostEntries) {
          if (e.receiptUrl != null && e.receiptUrl!.isNotEmpty) notaMap[e.id ?? ''] = currentNota++;
        }

        return Stack(
          children: [
            SingleChildScrollView(
              padding: padding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header
                  _buildHeader(context, isMobile, start, end, diff, p),
                  const SizedBox(height: 24),
                  
                  // Date Header
                  _buildDateHeader(context: context, provider: p, start: start, end: end, diff: diff),
                  const SizedBox(height: 28),
                  
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 950;
                      if (isCompact) {
                        return Column(
                          children: [
                            _buildKostSection(context: context, provider: p, title: 'White Kost 35', entries: p.whiteKostEntries, kostType: 'white', startNo: 0),
                            const SizedBox(height: 28),
                            _buildKostSection(context: context, provider: p, title: 'Mykost 179', entries: p.mykostEntries, kostType: 'mykost', startNo: p.whiteKostEntries.length),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildKostSection(context: context, provider: p, title: 'White Kost 35', entries: p.whiteKostEntries, kostType: 'white', startNo: 0)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildKostSection(context: context, provider: p, title: 'Mykost 179', entries: p.mykostEntries, kostType: 'mykost', startNo: p.whiteKostEntries.length)),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  _buildGrandTotalCard(p.grandTotalKoko),
                ],
              ),
            ),
            
            // Hidden Export Boundary
            Positioned(
              left: -3000,
              child: RepaintBoundary(
                key: _exportKey,
                child: Container(
                  width: 1000,
                  color: Colors.white,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black, fontFamily: 'Inter'),
                            children: [
                              const TextSpan(text: 'Belanja '),
                              TextSpan(text: '${DateFormat('dd', 'id_ID').format(start)} – ${DateFormat('dd MMMM yyyy', 'id_ID').format(end)}', style: const TextStyle(color: Color(0xFF1B5E20))),
                              const TextSpan(text: ' ( '),
                              TextSpan(text: '$diff Hari', style: const TextStyle(color: Color(0xFF1B5E20))),
                              const TextSpan(text: ' )'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildExportTable(title: 'White Kost 35', entries: p.whiteKostEntries, total: p.totalWhiteKost, headerColor: const Color(0xFFE6F4D6), notaMap: notaMap),
                      const SizedBox(height: 12),
                      _buildExportTable(title: 'Mykost 179', entries: p.mykostEntries, total: p.totalMykost, headerColor: const Color(0xFFF5E7C7), notaMap: notaMap),
                      const SizedBox(height: 48),
                      const Divider(thickness: 4, color: Colors.black),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL KESELURUHAN', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                          SizedBox(
                            width: 350,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Rp', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFD32F2F))),
                                Text(formatRupiah(p.grandTotalKoko).replaceAll('Rp ', ''), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFD32F2F))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            if (_isUploading || _isDeletingReceipt)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)]),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF006D63), strokeWidth: 3),
                          const SizedBox(height: 16),
                          Text(_isDeletingReceipt ? 'Menghapus Nota...' : 'Mengunggah Nota...', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF006D63))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile, DateTime start, DateTime end, int diff, FinanceProvider p) {
    return Row(
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Belanja Kebutuhan Kost",
                  style: TextStyle(fontSize: isMobile ? 22 : 28, fontWeight: FontWeight.bold, letterSpacing: -1.0),
                ),
                Text(
                  "Kelola pengeluaran kost secara mendetail",
                  style: TextStyle(color: Colors.black54, fontSize: isMobile ? 11 : 13),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _exportHeaderBtn(
              label: 'List',
              iconPath: 'assets/icons/icon_eksport_tojpg.png',
              onTap: () {
                final filename = 'List_Belanja_${DateFormat('dd_MMM').format(start)}_to_${DateFormat('dd_MMM_yyyy').format(end)}.jpg';
                KokoExporter.exportToJpg(context: context, boundaryKey: _exportKey, filename: filename);
              },
            ),
            const SizedBox(width: 8),
            _exportHeaderBtn(
              label: 'Bukti',
              iconPath: 'assets/icons/icon_eksport_topdf.png',
              onTap: () {
                final filename = 'Bukti_Belanja_${DateFormat('dd_MMM').format(start)}_to_${DateFormat('dd_MMM_yyyy').format(end)}.pdf';
                KokoExporter.exportToPdf(
                  whiteEntries: p.whiteKostEntries,
                  mykostEntries: p.mykostEntries,
                  filename: filename,
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateHeader({required BuildContext context, required FinanceProvider provider, required DateTime start, required DateTime end, required int diff}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.black.withOpacity(0.05)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF006D63).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF006D63)),
              ),
              const SizedBox(width: 12),
              const Text('Rentang Belanja', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
            ],
          ),
          const SizedBox(width: 8),
          _dateSelector(context, provider, start, true),
          const Text('s/d', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black38)),
          _dateSelector(context, provider, end, false),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text('$diff Hari', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.blueAccent)),
          ),
          const SizedBox(width: 4),
          _actionBtn(Icons.check_circle_outline_rounded, Colors.green, () async {
            _showResetConfirmation(context, provider);
          }, label: 'Lunas', isWide: true),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Lunas', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin sudah lunas? Semua catatan tagihan Koko akan dihapus dan direset ke 0.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await provider.resetKokoBills();
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Ya', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _dateSelector(BuildContext context, FinanceProvider provider, DateTime current, bool isStart) {
    return InkWell(
      onTap: () async {
        final selected = await showAppleDatePicker(
          context: context,
          initialDate: current,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (selected == null) return;
        final period = provider.activeKokoPeriod;
        final otherDate = isStart ? (period != null ? DateTime.parse(period.endDate) : DateTime.now().add(const Duration(days: 14))) : (period != null ? DateTime.parse(period.startDate) : DateTime.now());
        if (isStart) {
          await provider.updateKokoPeriod(selected, otherDate);
        } else {
          await provider.updateKokoPeriod(otherDate, selected);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.08)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('d MMM yyyy', 'id_ID').format(current), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.black87)),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  Widget _exportHeaderBtn({required String label, required String iconPath, required VoidCallback onTap}) {
    final isMobile = Responsive.isMobile(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(iconPath, width: isMobile ? 22 : 28, height: isMobile ? 22 : 28, fit: BoxFit.contain),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  Widget _buildExportTable({required String title, required List<KokoBillEntry> entries, required double total, required Color headerColor, required Map<String, int> notaMap}) {
    return Column(
      children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 8), decoration: BoxDecoration(color: headerColor, border: Border.all(color: Colors.black)), child: Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Table(
                  border: TableBorder.all(color: Colors.black),
                  columnWidths: const {0: FixedColumnWidth(100), 1: FixedColumnWidth(150), 2: FlexColumnWidth(), 3: FixedColumnWidth(180)},
                  children: [
                    TableRow(decoration: const BoxDecoration(color: Color(0xFFF9F9F9)), children: [_exportTableHeader('Nota'), _exportTableHeader('Tanggal'), _exportTableHeader('Barang'), _exportTableHeader('Harga')]),
                    ...entries.map((e) {
                      final notaNo = notaMap[e.id ?? ''];
                      return TableRow(
                        children: [
                          TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child: Container(alignment: Alignment.center, padding: const EdgeInsets.symmetric(vertical: 8), child: notaNo != null ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFFFE082), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black26)), child: Text('Nota $notaNo', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))) : const Text('--', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)))),
                          _exportTableCell(e.date ?? '', align: TextAlign.center),
                          _exportTableCell(e.title, weight: FontWeight.w700),
                          _exportAccountingCell(e.amount, weight: FontWeight.w700),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              Container(
                width: 250,
                decoration: BoxDecoration(border: Border.all(color: Colors.black)),
                child: Column(
                  children: [
                    Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12), decoration: const BoxDecoration(color: Color(0xFFF9F9F9), border: Border(bottom: BorderSide(color: Colors.black))), child: const Text('Total', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
                    Expanded(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Rp', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)), Text(formatRupiah(total).replaceAll('Rp ', ''), textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))])))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _exportTableHeader(String text) => Container(padding: const EdgeInsets.all(12), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20)));
  Widget _exportAccountingCell(double amount, {FontWeight weight = FontWeight.w600}) {
    final formatted = formatRupiah(amount).replaceAll('Rp ', '');
    return TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Rp', style: TextStyle(fontSize: 18, fontWeight: weight)), Text(formatted, style: TextStyle(fontSize: 18, fontWeight: weight))])));
  }
  Widget _exportTableCell(String text, {TextAlign align = TextAlign.left, FontWeight weight = FontWeight.w600}) => TableCell(verticalAlignment: TableCellVerticalAlignment.middle, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(text, textAlign: align, style: TextStyle(fontSize: 18, fontWeight: weight))));

  Widget _buildKostSection({required BuildContext context, required FinanceProvider provider, required String title, required List<KokoBillEntry> entries, required String kostType, required int startNo}) {
    final isWhite = kostType == 'white';
    final headerColor = isWhite ? const Color(0xFFE6F4D6) : const Color(0xFFF5E7C7);
    final titleColor = isWhite ? const Color(0xFF252525) : const Color(0xFF966C1B);
    final total = entries.fold<double>(0, (sum, entry) => sum + entry.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: titleColor)),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = MediaQuery.of(context).size.width < 800;
            final content = IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile) SizedBox(width: 480, child: _buildTransactionTable(context: context, provider: provider, entries: entries, kostType: kostType, startNo: startNo, headerColor: headerColor))
                  else Expanded(child: _buildTransactionTable(context: context, provider: provider, entries: entries, kostType: kostType, startNo: startNo, headerColor: headerColor)),
                  SizedBox(width: 155, child: _buildTotalPanel(total: total, headerColor: headerColor)),
                ],
              ),
            );
            if (isMobile) return Scrollbar(thumbVisibility: true, child: SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.only(bottom: 12), child: content));
            return content;
          },
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _actionBtn(Icons.remove_rounded, Colors.redAccent, () async {
              if (entries.isNotEmpty && entries.last.id != null) {
                await provider.deleteKokoEntry(kostType, entries.last.id!);
              }
            }),
            const SizedBox(width: 8),
            _actionBtn(Icons.add_rounded, const Color(0xFF34A853), () async {
              await provider.addKokoEntry(kostType);
            }),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTable({required BuildContext context, required FinanceProvider provider, required List<KokoBillEntry> entries, required String kostType, required int startNo, required Color headerColor}) {
    return Table(
      border: TableBorder.all(color: Colors.black.withOpacity(0.1), width: 1),
      columnWidths: const {0: FixedColumnWidth(42), 1: FixedColumnWidth(52), 2: FixedColumnWidth(90), 3: FlexColumnWidth(3.4), 4: FlexColumnWidth(1.6)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(decoration: BoxDecoration(color: headerColor.withOpacity(0.5)), children: [_tableHeader('No'), _tableHeader('Nota'), _tableHeader('Tanggal'), _tableHeader('Transaksi'), _tableHeader('Harga')]),
        ...entries.asMap().entries.map((item) {
          final index = item.key;
          final entry = item.value;
          return TableRow(children: [_numberCell(startNo + index + 1), _receiptCell(context, provider, kostType, entry), _dateInputCell(provider, kostType, entry), _titleInputCell(provider, kostType, entry), _amountInputCell(provider, kostType, entry)]);
        }),
      ],
    );
  }

  Widget _buildTotalPanel({required double total, required Color headerColor}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.black.withOpacity(0.1), width: 1)),
      child: Column(
        children: [
          Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11), decoration: BoxDecoration(color: headerColor.withOpacity(0.5), border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.1), width: 1))), child: const Text('Total', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800))),
          Expanded(child: Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text(formatRupiah(total), textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))))),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) => Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9), child: Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)));
  Widget _numberCell(int number) => SizedBox(height: 36, child: Center(child: Text(number.toString(), style: const TextStyle(fontSize: 13))));

  Widget _receiptCell(BuildContext context, FinanceProvider provider, String kostType, KokoBillEntry entry) {
    final hasReceipt = entry.receiptUrl != null && entry.receiptUrl!.trim().isNotEmpty;
    return SizedBox(
      height: 36,
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          tooltip: hasReceipt ? 'Lihat, Ganti atau Hapus Nota' : 'Upload Nota',
          onPressed: () {
            if (hasReceipt) _showReceiptActionDialog(context: context, provider: provider, kostType: kostType, entry: entry);
            else _pickAndUpload(context, provider, kostType, entry.id!);
          },
          icon: Icon(Icons.image_rounded, color: hasReceipt ? const Color(0xFF248B4A) : Colors.grey.shade500, size: 20),
        ),
      ),
    );
  }

  Widget _dateInputCell(FinanceProvider provider, String kostType, KokoBillEntry entry) {
    DateTime? currentDate;
    try { if (entry.date != null && entry.date!.isNotEmpty) currentDate = DateFormat('dd/MM/yyyy').parse(entry.date!); } catch (_) {}
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: InkWell(
          onTap: () async {
            final selected = await showAppleDatePicker(context: context, initialDate: currentDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2100));
            if (selected != null) {
              final formattedDate = DateFormat('dd/MM/yyyy').format(selected);
              provider.updateKokoEntry(kostType, KokoBillEntry(id: entry.id, periodId: entry.periodId, title: entry.title, amount: entry.amount, receiptUrl: entry.receiptUrl, date: formattedDate));
            }
          },
          child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(6)), child: Text(entry.date == null || entry.date!.isEmpty ? 'Tgl...' : entry.date!, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: entry.date == null || entry.date!.isEmpty ? Colors.black26 : Colors.black87))),
        ),
      ),
    );
  }

  Widget _titleInputCell(FinanceProvider provider, String kostType, KokoBillEntry entry) {
    final controller = _getTitleController(entry);
    final focusNode = _getTitleFocusNode(provider, kostType, entry);
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          maxLines: 1,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          decoration: InputDecoration(isDense: true, filled: true, fillColor: Colors.black.withOpacity(0.03), contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: BorderSide.none), hintText: 'Nama belanja...', hintStyle: const TextStyle(fontSize: 11, color: Colors.black26)),
          onSubmitted: (value) {
            provider.updateKokoEntry(kostType, KokoBillEntry(id: entry.id, periodId: entry.periodId, title: value, amount: entry.amount, receiptUrl: entry.receiptUrl, date: entry.date));
          },
        ),
      ),
    );
  }

  Widget _amountInputCell(FinanceProvider provider, String kostType, KokoBillEntry entry) {
    final controller = _getAmountController(entry);
    final focusNode = _getAmountFocusNode(provider, kostType, entry);
    return SizedBox(
      height: 40,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(6)),
          child: Row(
            children: [
              const Padding(padding: EdgeInsets.only(left: 8), child: Text('Rp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38))),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  onTap: () { if (controller.text == '0') controller.clear(); },
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.only(right: 8, top: 8, bottom: 8), border: InputBorder.none),
                  onChanged: (value) {
                    if (value.isEmpty) return;
                    final amount = _parseAmount(value);
                    final formatted = _formatNumberForInput(amount);
                    if (value != formatted) { controller.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length)); }
                  },
                  onSubmitted: (value) {
                    final amount = _parseAmount(value);
                    provider.updateKokoEntry(kostType, KokoBillEntry(id: entry.id, periodId: entry.periodId, title: entry.title, amount: amount, receiptUrl: entry.receiptUrl, date: entry.date));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController _getTitleController(KokoBillEntry entry) {
    final existing = _titleControllers[entry.id];
    if (existing != null) return existing;
    final controller = TextEditingController(text: entry.title);
    _titleControllers[entry.id!] = controller;
    return controller;
  }

  TextEditingController _getAmountController(KokoBillEntry entry) {
    final existing = _amountControllers[entry.id];
    if (existing != null) return existing;
    final controller = TextEditingController(text: _formatNumberForInput(entry.amount));
    _amountControllers[entry.id!] = controller;
    return controller;
  }

  FocusNode _getTitleFocusNode(FinanceProvider provider, String kostType, KokoBillEntry entry) {
    final existing = _titleFocusNodes[entry.id];
    if (existing != null) return existing;
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus) {
        final controller = _titleControllers[entry.id];
        if (controller != null) {
          provider.updateKokoEntry(kostType, KokoBillEntry(id: entry.id, periodId: entry.periodId, title: controller.text, amount: entry.amount, receiptUrl: entry.receiptUrl, date: entry.date));
        }
      }
    });
    _titleFocusNodes[entry.id!] = node;
    return node;
  }

  FocusNode _getAmountFocusNode(FinanceProvider provider, String kostType, KokoBillEntry entry) {
    final existing = _amountFocusNodes[entry.id];
    if (existing != null) return existing;
    final node = FocusNode();
    node.addListener(() {
      if (!node.hasFocus) {
        final controller = _amountControllers[entry.id];
        if (controller != null) {
          final amount = _parseAmount(controller.text);
          provider.updateKokoEntry(kostType, KokoBillEntry(id: entry.id, periodId: entry.periodId, title: entry.title, amount: amount, receiptUrl: entry.receiptUrl, date: entry.date));
        }
      }
    });
    _amountFocusNodes[entry.id!] = node;
    return node;
  }

  String _formatNumberForInput(double amount) { if (amount == 0) return '0'; return NumberFormat('#,###', 'id_ID').format(amount).replaceAll(',', '.'); }
  double _parseAmount(String value) { final clean = value.replaceAll('Rp', '').replaceAll('.', '').replaceAll(',', '').replaceAll(' ', '').trim(); return double.tryParse(clean) ?? 0; }

  Future<void> _showReceiptActionDialog({required BuildContext context, required FinanceProvider provider, required String kostType, required KokoBillEntry entry}) async {
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Nota Transaksi', style: TextStyle(fontWeight: FontWeight.w600)),
        content: const Text('Pilih tindakan untuk nota ini.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(dialogContext, 'view'); }, child: const Text('Lihat')),
          TextButton(onPressed: () { Navigator.pop(dialogContext, 'replace'); }, child: const Text('Ganti')),
          TextButton(onPressed: () { Navigator.pop(dialogContext, 'delete'); }, style: TextButton.styleFrom(foregroundColor: Colors.redAccent), child: const Text('Hapus')),
          TextButton(onPressed: () { Navigator.pop(dialogContext); }, child: const Text('Batal')),
        ],
      ),
    );
    if (action == null) return;
    if (action == 'view') { _viewReceipt(context, entry.receiptUrl!); return; }
    if (action == 'replace') { _pickAndUpload(context, provider, kostType, entry.id!); return; }
    if (action == 'delete') { await _deleteReceipt(provider: provider, kostType: kostType, entry: entry); }
  }

  Future<void> _viewReceipt(BuildContext context, String receiptUrl) async {
    await showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85, maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: double.infinity, padding: const EdgeInsets.all(14), child: Row(children: [const Expanded(child: Text('Nota Transaksi', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700))), IconButton(onPressed: () { Navigator.pop(dialogContext); }, icon: const Icon(Icons.close_rounded))])),
              const Divider(height: 1),
              Expanded(child: InteractiveViewer(minScale: 0.5, maxScale: 4, child: Image.network(receiptUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Center(child: Text('Gagal memuat gambar nota.'))))),
            ],
          ),
        ),
      ),
    );
  }

  void _pickAndUpload(BuildContext context, FinanceProvider provider, String kostType, String entryId) {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;
      setState(() { _isUploading = true; });
      final reader = html.FileReader();
      reader.readAsArrayBuffer(files.first);
      reader.onLoadEnd.listen((event) async {
        try {
          final result = reader.result;
          if (result is ByteBuffer) { await provider.uploadKokoReceipt(kostType, entryId, Uint8List.view(result)); }
          else if (result is Uint8List) { await provider.uploadKokoReceipt(kostType, entryId, result); }
        } catch (error) { if (mounted) { _showMessage('Gagal mengunggah nota: $error', isError: true); } }
        finally { if (mounted) { setState(() { _isUploading = false; }); } }
      });
    });
  }

  Future<void> _deleteReceipt({required FinanceProvider provider, required String kostType, required KokoBillEntry entry}) async {
    if (entry.receiptUrl == null || entry.receiptUrl!.isEmpty) return;
    setState(() { _isDeletingReceipt = true; });
    try {
      final bucket = kostType == 'white' ? 'koko-white-kost-receipts' : 'koko-mykost-receipts';
      final table = kostType == 'white' ? 'koko_white_kost_35' : 'koko_mykost_179';
      final filePath = _getStoragePathFromPublicUrl(entry.receiptUrl!, bucket);
      if (filePath != null && filePath.isNotEmpty) { await Supabase.instance.client.storage.from(bucket).remove([filePath]); }
      await Supabase.instance.client.from(table).update({'receipt_url': null}).eq('id', entry.id!);
      await provider.updateKokoEntry(kostType, KokoBillEntry(id: entry.id, periodId: entry.periodId, title: entry.title, amount: entry.amount, receiptUrl: null, date: entry.date));
      if (mounted) { _showMessage('Nota berhasil dihapus.'); }
    } catch (error) { if (mounted) { _showMessage('Gagal menghapus nota: $error', isError: true); } }
    finally { if (mounted) { setState(() { _isDeletingReceipt = false; }); } }
  }

  String? _getStoragePathFromPublicUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final publicMarker = '/object/public/$bucket/';
      final signMarker = '/object/sign/$bucket/';
      final path = uri.path;
      if (path.contains(publicMarker)) return Uri.decodeComponent(path.split(publicMarker).last);
      if (path.contains(signMarker)) return Uri.decodeComponent(path.split(signMarker).last);
      final bucketIndex = path.indexOf('/$bucket/');
      if (bucketIndex >= 0) return Uri.decodeComponent(path.substring(bucketIndex + bucket.length + 2));
      return null;
    } catch (_) { return null; }
  }

  Widget _actionBtn(IconData icon, Color color, Future<void> Function() onTap, {String? label, bool isWide = false}) {
    return InkWell(
      onTap: () async { await onTap(); }, 
      borderRadius: BorderRadius.circular(8), 
      child: Container(
        height: 32, 
        padding: EdgeInsets.symmetric(horizontal: isWide ? 12 : 0),
        alignment: Alignment.center, 
        decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)), 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGrandTotalCard(double total) {
    final isMobile = Responsive.isMobile(context);
    return Container(
      width: double.infinity, padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 16 : 20),
      decoration: BoxDecoration(color: const Color(0xFFE8F5F2), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF006D63).withOpacity(0.15))),
      child: Row(children: [
        Container(padding: EdgeInsets.all(isMobile ? 8 : 12), decoration: BoxDecoration(color: const Color(0xFF006D63).withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.credit_card_rounded, color: const Color(0xFF006D63), size: isMobile ? 20 : 28)),
        SizedBox(width: isMobile ? 12 : 18),
        Expanded(child: Text('Total Keseluruhan', style: TextStyle(fontSize: isMobile ? 14 : 18, fontWeight: FontWeight.w800, color: const Color(0xFF006D63)))),
        Text(formatRupiah(total), style: TextStyle(fontSize: isMobile ? 20 : 26, fontWeight: FontWeight.w900, color: const Color(0xFF006D63), letterSpacing: -0.5)),
      ]),
    );
  }

  void _showMessage(String message, {bool isError = false}) { if (!mounted) return; ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: isError ? Colors.redAccent : const Color(0xFF248B4A))); }
}
