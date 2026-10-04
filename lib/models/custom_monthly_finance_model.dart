class CustomMonthlyFinance {
  final String? id;
  final String monthKey; // Format: YYYY-MM
  final double gajiPokok;
  final double tunjangan;
  final double bonus;
  final double lainLainSumber;
  final double belanjaIstri;
  final double sewaKost;
  final double konsumtif;
  final double lainLainDihabiskan;

  CustomMonthlyFinance({
    this.id,
    required this.monthKey,
    required this.gajiPokok,
    required this.tunjangan,
    required this.bonus,
    required this.lainLainSumber,
    required this.belanjaIstri,
    required this.sewaKost,
    required this.konsumtif,
    required this.lainLainDihabiskan,
  });

  factory CustomMonthlyFinance.fromJson(Map<String, dynamic> json) {
    return CustomMonthlyFinance(
      id: json['id'],
      monthKey: json['month_key'],
      gajiPokok: (json['gaji_pokok'] as num).toDouble(),
      tunjangan: (json['tunjangan'] as num).toDouble(),
      bonus: (json['bonus'] as num).toDouble(),
      lainLainSumber: (json['lain_lain_sumber'] as num).toDouble(),
      belanjaIstri: (json['belanja_istri'] as num).toDouble(),
      sewaKost: (json['sewa_kost'] as num).toDouble(),
      konsumtif: (json['konsumtif'] as num).toDouble(),
      lainLainDihabiskan: (json['lain_lain_dihabiskan'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'month_key': monthKey,
      'gaji_pokok': gajiPokok,
      'tunjangan': tunjangan,
      'bonus': bonus,
      'lain_lain_sumber': lainLainSumber,
      'belanja_istri': belanjaIstri,
      'sewa_kost': sewaKost,
      'konsumtif': konsumtif,
      'lain_lain_dihabiskan': lainLainDihabiskan,
    };
  }
}
