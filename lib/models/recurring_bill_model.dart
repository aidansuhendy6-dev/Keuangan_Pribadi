class RecurringBill {
  final String id;
  final String name;
  final double amount;
  final int dueDay;
  final bool isInstallment;
  final int? totalTenor;
  final DateTime? startDate; // Anchor Date (Next Due Date when first created)
  final int? startTenor;   // Anchor Tenor (The tenor number at startDate)

  RecurringBill({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDay,
    this.isInstallment = false,
    this.totalTenor,
    this.startDate,
    this.startTenor,
  });

  // Calculate current paid tenor dynamically
  int? get currentPaidTenor {
    if (!isInstallment || startDate == null || startTenor == null) return null;
    
    final now = DateTime.now();
    // Calculate current installment index
    // If today is 27 Aug and start is 30 Sep (Tenor 33), current should be 33.
    // If today is 1 Oct and start is 30 Sep (Tenor 33), current should be 34.
    int monthsDiff = (now.year - startDate!.year) * 12 + (now.month - startDate!.month);
    
    // We increment the tenor ONLY if the day has passed the due day of the current month
    int dayAdjustment = now.day > dueDay ? 1 : 0;
    int current = startTenor! + monthsDiff + dayAdjustment;

    // Ensure it doesn't show a lower tenor than where we started
    return current < startTenor! ? startTenor! : current;
  }

  int get remainingTenor {
    if (totalTenor == null || currentPaidTenor == null) return 0;
    final remaining = totalTenor! - currentPaidTenor! + 1;
    return remaining > 0 ? remaining : 0;
  }
  
  double get remainingAmount => remainingTenor * amount;
  
  double get progress {
    if (totalTenor == null || totalTenor == 0 || currentPaidTenor == null) return 0;
    final completed = currentPaidTenor! - 1;
    return (completed / totalTenor!).clamp(0.0, 1.0);
  }

  // Get the specific due date for the CURRENT active tenor
  DateTime get nextDueDate {
    if (startDate != null && currentPaidTenor != null && startTenor != null) {
      if (currentPaidTenor! <= startTenor!) {
        return startDate!;
      }
    }

    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    
    // If we already passed the due day this month, the next one is next month
    if (now.day > dueDay) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
    
    // Safety check for days in month (e.g. Feb 30)
    int day = dueDay;
    int lastDay = DateTime(year, month + 1, 0).day;
    if (day > lastDay) day = lastDay;
    
    return DateTime(year, month, day);
  }

  factory RecurringBill.fromJson(Map<String, dynamic> json) {
    return RecurringBill(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      dueDay: json['due_day'] as int,
      isInstallment: json['is_installment'] ?? false,
      totalTenor: json['total_tenor'],
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      startTenor: json['start_tenor'],
    );
  }
}
