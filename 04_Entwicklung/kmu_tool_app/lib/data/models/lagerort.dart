class Lagerort {
  final String id;
  final String userId;
  final String bezeichnung;
  final String typ; // lager, fahrzeug, baustelle
  final bool istStandard;
  final int sortierung;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Lagerort({
    required this.id,
    required this.userId,
    required this.bezeichnung,
    this.typ = 'lager',
    this.istStandard = false,
    this.sortierung = 0,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Lagerort.fromJson(Map<String, dynamic> json) {
    return Lagerort(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bezeichnung: json['bezeichnung'] as String,
      typ: json['typ'] as String? ?? 'lager',
      istStandard: json['ist_standard'] as bool? ?? false,
      sortierung: json['sortierung'] as int? ?? 0,
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
      'typ': typ,
      'ist_standard': istStandard,
      'sortierung': sortierung,
      'is_deleted': isDeleted,
    };
  }

  String get typLabel {
    switch (typ) {
      case 'lager':
        return 'Lager';
      case 'fahrzeug':
        return 'Fahrzeug';
      case 'baustelle':
        return 'Baustelle';
      default:
        return typ;
    }
  }
}
