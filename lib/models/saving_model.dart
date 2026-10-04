class Saving {
  final String id;
  final String name;
  final double currentAmount;
  final double? targetAmount;

  Saving({
    required this.id,
    required this.name,
    required this.currentAmount,
    this.targetAmount,
  });

  factory Saving.fromJson(Map<String, dynamic> json) {
    return Saving(
      id: json['id'],
      name: json['name'],
      currentAmount: (json['current_amount'] as num).toDouble(),
      targetAmount: json['target_amount'] != null ? (json['target_amount'] as num).toDouble() : null,
    );
  }
}
