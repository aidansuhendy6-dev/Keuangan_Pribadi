class Debt {
  final String id;
  final String name;
  final double totalAmount;
  final double remainingAmount;
  final DateTime? dueDate;

  Debt({
    required this.id,
    required this.name,
    required this.totalAmount,
    required this.remainingAmount,
    this.dueDate,
  });

  factory Debt.fromJson(Map<String, dynamic> json) {
    return Debt(
      id: json['id'],
      name: json['name'],
      totalAmount: (json['total_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
    );
  }
}
