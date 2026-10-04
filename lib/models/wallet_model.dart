class Wallet {
  final String id;
  final String name;
  final double balance;
  final String? iconName;

  Wallet({
    required this.id,
    required this.name,
    required this.balance,
    this.iconName,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'],
      name: json['name'],
      balance: (json['balance'] as num).toDouble(),
      iconName: json['icon_name'],
    );
  }
}
