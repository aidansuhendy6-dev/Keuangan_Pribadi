import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/finance_provider.dart';
import '../../../core/widgets/apple_date_picker.dart';
import '../../../core/widgets/apple_menu_selector.dart';

class SavingTransferDialog extends StatefulWidget {
  final String mode; // 'plus' for Menabung, 'minus' for Mencairkan

  const SavingTransferDialog({super.key, required this.mode});

  @override
  State<SavingTransferDialog> createState() => _SavingTransferDialogState();
}

class _SavingTransferDialogState extends State<SavingTransferDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _selectedWalletId;
  String? _selectedSavingId;

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final isPlus = widget.mode == 'plus';

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        width: isMobile ? MediaQuery.of(context).size.width : 450,
        constraints: const BoxConstraints(maxWidth: 450),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPlus ? "Menabung" : "Mencairkan Tabungan",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 8),
                Text(
                  isPlus 
                    ? "Pindahkan saldo dari dompet ke tabungan Anda."
                    : "Pindahkan saldo dari tabungan kembali ke dompet.",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 32),
                
                // 1. Tanggal
                const Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showAppleDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd MMMM yyyy', 'id_ID').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Icon(Icons.calendar_today, size: 18, color: Colors.black54),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 2. Dropdowns
                if (isMobile) ...[
                Text(isPlus ? "Sumber Dana" : "Dompet Tujuan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                FormField<String>(
                  validator: (val) => _selectedWalletId == null ? "Pilih dompet" : null,
                  builder: (state) {
                    return AppleMenuSelector<String>(
                      selectedValue: _selectedWalletId,
                      placeholder: "Pilih dompet",
                      errorText: state.errorText,
                      items: finance.wallets.map((w) => AppleMenuItem<String>(
                        value: w.id,
                        label: w.name,
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedWalletId = val);
                        state.didChange(val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(isPlus ? "Tabungan Tujuan" : "Sumber Tabungan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                FormField<String>(
                  validator: (val) => _selectedSavingId == null ? "Pilih tabungan" : null,
                  builder: (state) {
                    return AppleMenuSelector<String>(
                      selectedValue: _selectedSavingId,
                      placeholder: "Pilih tabungan",
                      errorText: state.errorText,
                      items: finance.savings.map((s) => AppleMenuItem<String>(
                        value: s.id,
                        label: s.name,
                      )).toList(),
                      onChanged: (val) {
                        setState(() => _selectedSavingId = val);
                        state.didChange(val);
                      },
                    );
                  },
                ),
              ] else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPlus ? "Sumber Dana" : "Dompet Tujuan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          FormField<String>(
                            validator: (val) => _selectedWalletId == null ? "Pilih dompet" : null,
                            builder: (state) {
                              return AppleMenuSelector<String>(
                                selectedValue: _selectedWalletId,
                                placeholder: "Pilih dompet",
                                errorText: state.errorText,
                                items: finance.wallets.map((w) => AppleMenuItem<String>(
                                  value: w.id,
                                  label: w.name,
                                )).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedWalletId = val);
                                  state.didChange(val);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isPlus ? "Tabungan Tujuan" : "Sumber Tabungan", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          FormField<String>(
                            validator: (val) => _selectedSavingId == null ? "Pilih tabungan" : null,
                            builder: (state) {
                              return AppleMenuSelector<String>(
                                selectedValue: _selectedSavingId,
                                placeholder: "Pilih tabungan",
                                errorText: state.errorText,
                                items: finance.savings.map((s) => AppleMenuItem<String>(
                                  value: s.id,
                                  label: s.name,
                                )).toList(),
                                onChanged: (val) {
                                  setState(() => _selectedSavingId = val);
                                  state.didChange(val);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // 3. Nominal
                const Text("Nominal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    prefixText: "Rp ",
                    prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black54),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Masukkan nominal" : null,
                ),
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Batal", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final cleanAmount = _amountController.text.replaceAll('.', '');
                          final amount = double.tryParse(cleanAmount) ?? 0;
                          await finance.addSavingTransfer(
                            type: widget.mode,
                            amount: amount,
                            walletId: _selectedWalletId!,
                            savingId: _selectedSavingId!,
                            date: _selectedDate,
                          );
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPlus ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(isPlus ? "Menabung Sekarang" : "Cairkan Sekarang", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    double value = double.parse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}
