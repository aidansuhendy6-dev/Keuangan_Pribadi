import 'package:flutter/material.dart';

class AppleMenuSelector<T> extends StatelessWidget {
  final T? selectedValue;
  final List<AppleMenuItem<T>> items;
  final ValueChanged<T> onChanged;
  final String placeholder;
  final String? errorText;

  const AppleMenuSelector({
    super.key,
    required this.selectedValue,
    required this.items,
    required this.onChanged,
    required this.placeholder,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final selectedItem = items.where((i) => i.value == selectedValue).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => _showMenu(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: errorText != null 
                ? Border.all(color: Colors.red.shade300, width: 1)
                : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedItem?.label ?? placeholder,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selectedItem != null ? FontWeight.w600 : FontWeight.w500,
                      color: selectedItem != null ? Colors.black : Colors.black26,
                    ),
                  ),
                ),
                const Icon(Icons.unfold_more_rounded, size: 20, color: Colors.black26),
              ],
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText!,
              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
            ),
          ),
      ],
    );
  }

  void _showMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final T? result = await showMenu<T>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: Colors.white,
      elevation: 8,
      items: items.map((item) {
        final isSelected = item.value == selectedValue;
        return PopupMenuItem<T>(
          value: item.value,
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: isSelected 
                  ? const Icon(Icons.check, size: 18, color: Color(0xFF007AFF)) 
                  : null,
              ),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF007AFF) : Colors.black,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );

    if (result != null) {
      onChanged(result);
    }
  }
}

class AppleMenuItem<T> {
  final T value;
  final String label;

  AppleMenuItem({required this.value, required this.label});
}
