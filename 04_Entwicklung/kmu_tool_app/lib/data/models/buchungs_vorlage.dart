class BuchungsVorlage {
  final String id;
  final String userId;
  final String geschaeftsfallId;
  final String bezeichnung;
  final int sollKonto;
  final int habenKonto;
  final String? autoTrigger; // rechnung_erstellt, rechnung_bezahlt, rechnung_storniert
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BuchungsVorlage({
    required this.id,
    required this.userId,
    required this.geschaeftsfallId,
    required this.bezeichnung,
    required this.sollKonto,
    required this.habenKonto,
    this.autoTrigger,
    this.createdAt,
    this.updatedAt,
  });

  factory BuchungsVorlage.fromJson(Map<String, dynamic> json) {
    return BuchungsVorlage(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      geschaeftsfallId: json['geschaeftsfall_id'] as String,
      bezeichnung: json['bezeichnung'] as String,
      sollKonto: json['soll_konto'] as int,
      habenKonto: json['haben_konto'] as int,
      autoTrigger: json['auto_trigger'] as String?,
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
      'geschaeftsfall_id': geschaeftsfallId,
      'bezeichnung': bezeichnung,
      'soll_konto': sollKonto,
      'haben_konto': habenKonto,
      'auto_trigger': autoTrigger,
    };
  }
}
