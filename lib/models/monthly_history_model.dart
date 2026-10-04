class MonthlyHistory {
  final String? id;
  final int month;
  final int year;
  final double balance;
  final double debt;

  MonthlyHistory({
    this.id,
    required this.month,
    required this.year,
    required this.balance,
    required this.debt,
  });

  factory MonthlyHistory.fromJson(Map<String, dynamic> json) {
    return MonthlyHistory(
      id: json['id'],
      month: json['month'],
      year: json['year'],
      balance: (json['balance'] as num).toDouble(),
      debt: (json['debt'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month': month,
      'year': year,
      'balance': balance,
      'debt': debt,
    };
  }
}
