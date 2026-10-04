import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/finance_provider.dart';
import '../../../core/widgets/apple_date_picker.dart';
import '../../../core/widgets/apple_menu_selector.dart';

import '../../../models/transaction_model.dart';

class AddTransactionDialog extends StatefulWidget {
  final String type; // 'income' or 'expense'
  final Transaction? transaction; // Optional for editing

  const AddTransactionDialog({super.key, required this.type, this.transaction});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _modalController = TextEditingController();
  final _jualController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  String? _selectedCategoryType;
  String _incomeType = 'Normal'; // 'Normal', 'Jastip', 'Bonus'

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
      
      _titleController.text = t.description;
      _amountController.text = formatter.format(t.amount).trim();
      _selectedDate = t.date;
      _selectedCategoryId = t.categoryId;
      _selectedCategoryType = t.categoryType;
      
      if (t.type == 'income') {
        _incomeType = t.incomeType ?? 'Normal';
        if (t.modal != null && t.modal! > 0) {
          _modalController.text = formatter.format(t.modal).trim();
        }
        if (t.jual != null && t.jual! > 0) {
          _jualController.text = formatter.format(t.jual).trim();
        }
      }
    }
  }

  void _calculateLaba() {
    if (_incomeType == 'Jastip') {
      final modalText = _modalController.text.replaceAll('.', '');
      final jualText = _jualController.text.replaceAll('.', '');
      final modal = double.tryParse(modalText) ?? 0;
      final jual = double.tryParse(jualText) ?? 0;
      final laba = jual - modal;
      
      final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
      _amountController.text = formatter.format(laba).trim();
    }
  }

  InputDecoration _inputDecoration(String? prefix) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.grey.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      prefixText: prefix,
      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildTypeChoice(String type) {
    final isSelected = _incomeType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _incomeType = type;
            if (type == 'Jastip') {
              _calculateLaba();
            } else if (type == 'Bonus') {
              _modalController.clear();
              _jualController.clear();
            }
          });
        }
      },
      selectedColor: Colors.black,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = context.read<FinanceProvider>();
    final isIncome = widget.type == 'income';
    
    // Filter categories based on type
    final List<Map<String, dynamic>> categories = [];
    
    for (var w in finance.wallets) {
      if (['BCA', 'Shopeepay', 'Cash'].contains(w.name)) {
        categories.add({'id': w.id, 'name': w.name, 'type': 'wallet'});
      }
    }
    
    if (!isIncome) {
      for (var d in finance.debts) {
        if (d.name == 'Kartu Kredit BCA') {
          categories.add({'id': d.id, 'name': d.name, 'type': 'debt'});
        }
      }
    }

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      backgroundColor: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(32),
        width: isMobile ? MediaQuery.of(context).size.width * 0.95 : 420,
        constraints: const BoxConstraints(maxWidth: 420),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.transaction == null 
                      ? (isIncome ? "Tambah Pemasukan" : "Tambah Pengeluaran")
                      : (isIncome ? "Edit Pemasukan" : "Edit Pengeluaran"),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                ),
                const SizedBox(height: 24),
                
                // 1. Judul
                const Text("Judul", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.05),
                    hintText: isIncome ? "Sumber pemasukan" : "Beli apa / bayar apa",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
                const SizedBox(height: 20),
                
                // 2. Tanggal
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
                
                // Jenis Pemasukan
                if (isIncome) ...[
                  const Text("Jenis Pemasukan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeChoice("Normal"),
                      const SizedBox(width: 8),
                      _buildTypeChoice("Jastip"),
                      const SizedBox(width: 8),
                      _buildTypeChoice("Bonus"),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                
                // 3. Sumber / Tujuan Dana
                Text(isIncome ? "Dompet Tujuan" : "Sumber Dana", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                FormField<String>(
                  validator: (val) => _selectedCategoryId == null ? "Pilih sumber dana" : null,
                  builder: (state) {
                    return AppleMenuSelector<String>(
                      selectedValue: _selectedCategoryId,
                      placeholder: isIncome ? "Pilih dompet tujuan" : "Pilih sumber dana",
                      errorText: state.errorText,
                      items: categories.map((c) => AppleMenuItem<String>(
                        value: c['id'] as String,
                        label: c['name'] as String,
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedCategoryId = val;
                          _selectedCategoryType = categories.firstWhere((c) => c['id'] == val)['type'];
                        });
                        state.didChange(val);
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
                
                // Modal & Jual (Jika Jastip)
                if (isIncome && _incomeType == 'Jastip') ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Modal", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _modalController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                              onChanged: (_) => _calculateLaba(),
                              decoration: _inputDecoration("Rp "),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Jual", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _jualController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly, CurrencyInputFormatter()],
                              onChanged: (_) => _calculateLaba(),
                              decoration: _inputDecoration("Rp "),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // 4. Nominal
                Text(isIncome ? (_incomeType == 'Jastip' ? "Laba" : "Nominal") : "Nominal", 
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  readOnly: isIncome && _incomeType == 'Jastip',
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    CurrencyInputFormatter(),
                  ],
                  decoration: _inputDecoration("Rp "),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
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
                          final amount = double.tryParse(_amountController.text.replaceAll('.', '')) ?? 0;
                          final modal = double.tryParse(_modalController.text.replaceAll('.', '')) ?? 0;
                          final jual = double.tryParse(_jualController.text.replaceAll('.', '')) ?? 0;

                          if (widget.transaction == null) {
                            await finance.addTransaction(
                              type: widget.type,
                              amount: amount,
                              description: _titleController.text,
                              categoryType: _selectedCategoryType!,
                              categoryId: _selectedCategoryId!,
                              date: _selectedDate,
                              incomeType: isIncome ? _incomeType : null,
                              modal: isIncome && _incomeType == 'Jastip' ? modal : 0,
                              jual: isIncome && _incomeType == 'Jastip' ? jual : 0,
                            );
                          } else {
                            // Logic for Edit Transaction
                            await finance.updateTransaction(
                              id: widget.transaction!.id,
                              oldTransaction: widget.transaction!,
                              type: widget.type,
                              amount: amount,
                              description: _titleController.text,
                              categoryType: _selectedCategoryType!,
                              categoryId: _selectedCategoryId!,
                              date: _selectedDate,
                              incomeType: isIncome ? _incomeType : null,
                              modal: isIncome && _incomeType == 'Jastip' ? modal : 0,
                              jual: isIncome && _incomeType == 'Jastip' ? jual : 0,
                            );
                          }
                          if (mounted) Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isIncome ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
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
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    String newText = formatter.format(value).trim();

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}
