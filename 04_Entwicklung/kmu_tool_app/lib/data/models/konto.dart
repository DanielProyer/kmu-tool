class Konto {
  final String id;
  final String userId;
  final int kontonummer;
  final String bezeichnung;
  final int kontenklasse; // generated from kontonummer/1000
  final String typ; // aktiv, passiv, aufwand, ertrag
  final double saldo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Konto({
    required this.id,
    required this.userId,
    required this.kontonummer,
    required this.bezeichnung,
    this.kontenklasse = 0,
    required this.typ,
    this.saldo = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory Konto.fromJson(Map<String, dynamic> json) {
    return Konto(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      kontonummer: json['kontonummer'] as int,
      bezeichnung: json['bezeichnung'] as String,
      kontenklasse: json['kontenklasse'] as int? ?? 0,
      typ: json['typ'] as String,
      saldo: (json['saldo'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// toJson does NOT include kontenklasse - it is GENERATED in the database.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kontonummer': kontonummer,
      'bezeichnung': bezeichnung,
      'typ': typ,
      'saldo': saldo,
    };
  }
}
