class Deposit {
  final String id;
  final String name;
  final double amount;
  final double? interestRate;

  Deposit({
    required this.id,
    required this.name,
    required this.amount,
    this.interestRate,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: json['id'],
      name: json['name'],
      amount: (json['amount'] as num).toDouble(),
      interestRate: json['interest_rate'] != null ? (json['interest_rate'] as num).toDouble() : null,
    );
  }
}
