class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final String categoryType;
  final String? categoryId;
  final DateTime date;
  
  // New fields for Jastip/Bonus
  final String? incomeType; // 'Normal', 'Jastip', 'Bonus'
  final double? modal;
  final double? jual;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.categoryType,
    this.categoryId,
    required this.date,
    this.incomeType,
    this.modal,
    this.jual,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      type: json['type'],
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] ?? '',
      categoryType: json['category_type'] ?? '',
      categoryId: json['category_id'],
      date: DateTime.parse(json['date']),
      incomeType: json['income_type'],
      modal: json['modal'] != null ? (json['modal'] as num).toDouble() : null,
      jual: json['jual'] != null ? (json['jual'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'category_type': categoryType,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'income_type': incomeType,
      'modal': modal,
      'jual': jual,
    };
  }
}
