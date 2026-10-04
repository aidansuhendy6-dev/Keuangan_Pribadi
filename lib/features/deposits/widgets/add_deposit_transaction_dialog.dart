import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/debt_model.dart';
import '../../../models/recurring_bill_model.dart';
import '../../../services/finance_provider.dart';
import '../../../core/widgets/apple_date_picker.dart';
import '../../../core/widgets/apple_menu_selector.dart';

class AddDepositTransactionDialog extends StatefulWidget {
  final dynamic initialItem;
  const AddDepositTransactionDialog({super.key, this.initialItem});

  @override
  State<AddDepositTransactionDialog> createState() => _AddDepositTransactionDialogState();
}

class _AddDepositTransactionDialogState extends State<AddDepositTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _tenorController = TextEditingController();
  final _paidTenorController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  String _selectedCardPrefix = '[KOKO]';
  String _mode = 'Paylater'; // 'Paylater' or 'Cicilan'

  @override
  void initState() {
    super.initState();
    if (widget.initialItem != null) {
      final item = widget.initialItem;
      if (item is Debt) {
        _mode = 'Paylater';
        _titleController.text = item.name.replaceAll(RegExp(r'\[.*?\] '), '');
        _amountController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(item.remainingAmount).trim();
        _dueDate = item.dueDate ?? DateTime.now();
        _selectedCardPrefix = RegExp(r'\[(.*?)\]').firstMatch(item.name)?.group(0) ?? '[KOKO]';
      } else if (item is RecurringBill) {
        _mode = 'Cicilan';
        _titleController.text = item.name.replaceAll(RegExp(r'\[.*?\] '), '');
        _amountController.text = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(item.amount).trim();
        _tenorController.text = item.totalTenor.toString();
        _paidTenorController.text = (item.currentPaidTenor ?? 0).toString();
        _dueDate = item.nextDueDate;
        _selectedCardPrefix = RegExp(r'\[(.*?)\]').firstMatch(item.name)?.group(0) ?? '[KOKO]';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        width: isMobile ? MediaQuery.of(context).size.width : 500,
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tambah Piutang Baru",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 24),
                
                // 1. Judul
                const Text("Keterangan Piutang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    hintText: "Contoh: Pinjaman Lukman, dll",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Masukkan keterangan" : null,
                ),
                const SizedBox(height: 20),

                // 2. Pilih Kartu & Mode
                if (isMobile) ...[
                  const Text("Pilih Kartu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  FormField<String>(
                    validator: (val) => _selectedCardPrefix.isEmpty ? "Pilih kartu" : null,
                    builder: (state) {
                      return AppleMenuSelector<String>(
                        selectedValue: _selectedCardPrefix,
                        placeholder: "Pilih kartu",
                        errorText: state.errorText,
                        items: [
                          AppleMenuItem(value: '[KOKO]', label: "Tagihan Koko"),
                          AppleMenuItem(value: '[DEP]', label: "Deposit"),
                          AppleMenuItem(value: '[BNS]', label: "Bonus"),
                        ],
                        onChanged: (val) {
                          setState(() => _selectedCardPrefix = val);
                          state.didChange(val);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Tipe Piutang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _buildModeButton('Paylater'),
                        _buildModeButton('Cicilan'),
                      ],
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Pilih Kartu", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            FormField<String>(
                              validator: (val) => _selectedCardPrefix.isEmpty ? "Pilih kartu" : null,
                              builder: (state) {
                                return AppleMenuSelector<String>(
                                  selectedValue: _selectedCardPrefix,
                                  placeholder: "Pilih kartu",
                                  errorText: state.errorText,
                                  items: [
                                    AppleMenuItem(value: '[KOKO]', label: "Tagihan Koko"),
                                    AppleMenuItem(value: '[DEP]', label: "Deposit"),
                                    AppleMenuItem(value: '[BNS]', label: "Bonus"),
                                  ],
                                  onChanged: (val) {
                                    setState(() => _selectedCardPrefix = val);
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
                            const Text("Tipe Piutang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  _buildModeButton('Paylater'),
                                  _buildModeButton('Cicilan'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // 3. Tanggal & Jatuh Tempo
                if (isMobile) ...[
                  const Text("Tgl Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildDatePicker(
                    value: _selectedDate,
                    onTap: () async {
                      final date = await showAppleDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (date != null) setState(() => _selectedDate = date);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text("Jatuh Tempo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  _buildDatePicker(
                    value: _dueDate,
                    onTap: () async {
                      final date = await showAppleDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                      if (date != null) setState(() => _dueDate = date);
                    },
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Tgl Transaksi", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            _buildDatePicker(
                              value: _selectedDate,
                              onTap: () async {
                                final date = await showAppleDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                if (date != null) setState(() => _selectedDate = date);
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
                            const Text("Jatuh Tempo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            _buildDatePicker(
                              value: _dueDate,
                              onTap: () async {
                                final date = await showAppleDatePicker(context: context, initialDate: _dueDate, firstDate: DateTime(2000), lastDate: DateTime(2100));
                                if (date != null) setState(() => _dueDate = date);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 20),

                // 4. Tenor (If Cicilan)
                if (_mode == 'Cicilan') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Total Tenor", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _tenorController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                                hintText: "Bulan",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Cicilan Ke", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _paidTenorController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey.withOpacity(0.05),
                                hintText: "N",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // 5. Nominal
                const Text("Nominal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    prefixText: "Rp ",
                    prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black54),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (val) => val == null || val.isEmpty ? "Masukkan nominal" : null,
                ),
                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context), 
                      child: const Text("Batal", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold))
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final amount = double.parse(_amountController.text.replaceAll('.', ''));
                          if (widget.initialItem == null) {
                            if (_mode == 'Paylater') {
                              await finance.addPiutangItem(
                                prefix: _selectedCardPrefix,
                                name: _titleController.text,
                                amount: amount,
                                dueDate: _dueDate,
                              );
                            } else {
                              await finance.addPiutangInstallmentItem(
                                prefix: _selectedCardPrefix,
                                name: _titleController.text,
                                amount: amount,
                                totalTenor: int.tryParse(_tenorController.text) ?? 1,
                                paidTenor: int.tryParse(_paidTenorController.text) ?? 1,
                                dueDate: _dueDate,
                              );
                            }
                          } else {
                            if (_mode == 'Paylater') {
                              await finance.updatePiutangItem(
                                id: (widget.initialItem as Debt).id,
                                prefix: _selectedCardPrefix,
                                name: _titleController.text,
                                amount: amount,
                                dueDate: _dueDate,
                              );
                            } else {
                              await finance.updatePiutangInstallment(
                                id: (widget.initialItem as RecurringBill).id,
                                prefix: _selectedCardPrefix,
                                name: _titleController.text,
                                amount: amount,
                                totalTenor: int.tryParse(_tenorController.text) ?? 1,
                                paidTenor: int.tryParse(_paidTenorController.text) ?? 1,
                                dueDate: _dueDate,
                              );
                            }
                          }
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34C759),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Simpan Piutang", style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildModeButton(String mode) {
    final isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            mode,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker({required DateTime value, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(DateFormat('dd/MM/yyyy').format(value), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const Icon(Icons.calendar_today, size: 14, color: Colors.black54),
          ],
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
