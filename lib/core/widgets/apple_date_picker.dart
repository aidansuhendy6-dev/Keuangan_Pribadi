import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<DateTime?> showAppleDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return await showDialog<DateTime>(
    context: context,
    builder: (context) => AppleDatePicker(
      initialDate: initialDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    ),
  );
}

class AppleDatePicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const AppleDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<AppleDatePicker> createState() => _AppleDatePickerState();
}

class _AppleDatePickerState extends State<AppleDatePicker> {
  late DateTime _selectedDate;
  late DateTime _viewDate;
  bool _isWheelMode = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _viewDate = DateTime(widget.initialDate.year, widget.initialDate.month);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = _selectedDate.day == now.day && 
                    _selectedDate.month == now.month && 
                    _selectedDate.year == now.year;
    
    final headerDateStr = isToday 
        ? "Hari ini" 
        : DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(_selectedDate);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        width: 340,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Header: Date Info
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.grey),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tanggal",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black),
                    ),
                    Text(
                      headerDateStr,
                      style: const TextStyle(color: Color(0xFF007AFF), fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Colors.black12),
            const SizedBox(height: 20),

            // Month/Year Selector Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _isWheelMode = !_isWheelMode),
                  child: Row(
                    children: [
                      Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(_viewDate),
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _isWheelMode ? Icons.expand_more : Icons.chevron_right,
                        color: const Color(0xFF007AFF),
                        size: 20,
                      ),
                    ],
                  ),
                ),
                if (!_isWheelMode)
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => _changeMonth(-1),
                        icon: const Icon(Icons.chevron_left, color: Color(0xFF007AFF), size: 28),
                      ),
                      IconButton(
                        onPressed: () => _changeMonth(1),
                        icon: const Icon(Icons.chevron_right, color: Color(0xFF007AFF), size: 28),
                      ),
                    ],
                  ),
              ],
            ),

            const SizedBox(height: 10),

            // Main Content Area (Calendar Grid or Wheel Picker)
            SizedBox(
              height: 250,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isWheelMode ? _buildWheelPicker() : _buildCalendarGrid(),
              ),
            ),

            const SizedBox(height: 10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 17)),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context, _selectedDate),
                  child: const Text("Ok", style: TextStyle(color: Color(0xFF34C759), fontWeight: FontWeight.bold, fontSize: 17)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _changeMonth(int offset) {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + offset);
    });
  }

  Widget _buildWheelPicker() {
    final months = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    
    return Row(
      children: [
        // Month Picker
        Expanded(
          flex: 3,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: _viewDate.month - 1),
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              setState(() {
                _viewDate = DateTime(_viewDate.year, index + 1);
              });
            },
            children: months.map((m) => Center(child: Text(m, style: const TextStyle(fontSize: 18)))).toList(),
          ),
        ),
        // Year Picker
        Expanded(
          flex: 2,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: _viewDate.year - 2000),
            itemExtent: 40,
            onSelectedItemChanged: (index) {
              setState(() {
                _viewDate = DateTime(2000 + index, _viewDate.month);
              });
            },
            children: List.generate(200, (i) => Center(child: Text("${2000 + i}", style: const TextStyle(fontSize: 18)))),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    final firstDayOffset = DateTime(_viewDate.year, _viewDate.month, 1).weekday % 7; // Sunday is 0 in our grid

    final weekLabels = ["MIN", "SEN", "SEL", "RAB", "KAM", "JUM", "SAB"];

    return Column(
      children: [
        // Week Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekLabels.map((l) => SizedBox(
            width: 32,
            child: Text(l, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          )).toList(),
        ),
        const SizedBox(height: 10),
        // Grid
        Expanded(
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayNum = index - firstDayOffset + 1;
              if (dayNum <= 0 || dayNum > daysInMonth) return const SizedBox.shrink();

              final date = DateTime(_viewDate.year, _viewDate.month, dayNum);
              final isSelected = date.day == _selectedDate.day && 
                                date.month == _selectedDate.month && 
                                date.year == _selectedDate.year;

              return GestureDetector(
                onTap: () => setState(() => _selectedDate = date),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? const Color(0xFF007AFF) : Colors.transparent,
                  ),
                  child: Text(
                    "$dayNum",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
