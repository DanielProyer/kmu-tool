class Bankverbindung {
  final String id;
  final String userId;
  final String bezeichnung;
  final String iban;
  final String? bankName;
  final String? bic;
  final bool istHauptkonto;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Bankverbindung({
    required this.id,
    required this.userId,
    required this.bezeichnung,
    required this.iban,
    this.bankName,
    this.bic,
    this.istHauptkonto = false,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Bankverbindung.fromJson(Map<String, dynamic> json) {
    return Bankverbindung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bezeichnung: json['bezeichnung'] as String? ?? '',
      iban: json['iban'] as String? ?? '',
      bankName: json['bank_name'] as String?,
      bic: json['bic'] as String?,
      istHauptkonto: json['ist_hauptkonto'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bezeichnung': bezeichnung,
      'iban': iban,
      'bank_name': bankName,
      'bic': bic,
      'ist_hauptkonto': istHauptkonto,
      'is_deleted': isDeleted,
    };
  }
}
