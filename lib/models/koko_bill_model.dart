class KokoBillingPeriod {
  final String? id;
  final String startDate;
  final String endDate;

  KokoBillingPeriod({
    this.id,
    required this.startDate,
    required this.endDate,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'start_date': startDate,
      'enddate': endDate,
    };
    if (id != null && id!.length > 10) map['id'] = id;
    return map;
  }

  factory KokoBillingPeriod.fromMap(Map<String, dynamic> map) {
    return KokoBillingPeriod(
      id: map['id']?.toString(),
      startDate: map['start_date'] ?? '',
      endDate: map['enddate'] ?? '',
    );
  }
}

class KokoBillEntry {
  final String? id;
  final String periodId;
  final String title;
  final double amount;
  final String? receiptUrl;
  final String? date;

  KokoBillEntry({
    this.id,
    required this.periodId,
    required this.title,
    required this.amount,
    this.receiptUrl,
    this.date,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'period_id': periodId,
      'title': title,
      'amount': amount,
      'receipt_url': receiptUrl,
      'date': date,
    };
    if (id != null && id!.length > 10) map['id'] = id;
    return map;
  }

  factory KokoBillEntry.fromMap(Map<String, dynamic> map) {
    return KokoBillEntry(
      id: map['id']?.toString(),
      periodId: map['period_id']?.toString() ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      receiptUrl: map['receipt_url'],
      date: map['date'],
    );
  }
}
