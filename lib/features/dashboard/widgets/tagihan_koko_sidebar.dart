import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:keuangan_pribadi/services/finance_provider.dart';
import 'package:keuangan_pribadi/services/navigation_provider.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/koko_bill_model.dart';

class TagihanKokoSidebar extends StatelessWidget {
  const TagihanKokoSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, p, _) {
        final period = p.activeKokoPeriod;
        final dateRange = period != null 
            ? '${DateFormat('dd MMM', 'id_ID').format(DateTime.parse(period.startDate))} - ${DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(period.endDate))}'
            : 'Pilih Tanggal';
        
        final allEntries = [...p.whiteKostEntries, ...p.mykostEntries];
        final filledEntries = allEntries.where((e) => e.title.trim().isNotEmpty || e.amount > 0).toList();
        
        final withReceipt = filledEntries.where((e) => e.receiptUrl != null && e.receiptUrl!.isNotEmpty).length;
        final withoutReceipt = filledEntries.length - withReceipt;
        
        KokoBillEntry? latestEntry;
        if (filledEntries.isNotEmpty) {
          latestEntry = filledEntries.last;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tagihan Koko',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () => context.read<NavigationProvider>().setMenu(SidebarMenu.tagihanKoko),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _subLabel('Rentang Waktu'),
                      Text(dateRange, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 12),
                      _subLabel('Total tagihan'),
                      Text(
                        formatRupiah(p.grandTotalKoko),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _showResetConfirmation(context, p),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.green[50],
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lunas',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
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
            onPressed: () {
              provider.resetKokoBills();
              Navigator.pop(context);
            },
            child: Text('Ya', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _subLabel(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          text,
          style: const TextStyle(fontSize: 10, color: Colors.black26, fontWeight: FontWeight.w500),
        ),
      );

  Widget _countItem(String label, String value) => Column(
        children: [
          _subLabel(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
        ],
      );
}
