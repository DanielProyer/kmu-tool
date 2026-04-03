class Fahrzeug {
  final String id;
  final String userId;
  final String bezeichnung;
  final String? kennzeichen;
  final String? marke;
  final String? modell;
  final int? jahrgang;
  final DateTime? naechsteService;
  final DateTime? naechsteMfk;
  final int? kmStand;
  final String? versicherung;
  final String? notizen;
  final bool aktiv;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Fahrzeug({
    required this.id,
    required this.userId,
    required this.bezeichnung,
    this.kennzeichen,
    this.marke,
    this.modell,
    this.jahrgang,
    this.naechsteService,
    this.naechsteMfk,
    this.kmStand,
    this.versicherung,
    this.notizen,
    this.aktiv = true,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Fahrzeug.fromJson(Map<String, dynamic> json) {
    return Fahrzeug(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bezeichnung: json['bezeichnung'] as String? ?? '',
      kennzeichen: json['kennzeichen'] as String?,
      marke: json['marke'] as String?,
      modell: json['modell'] as String?,
      jahrgang: json['jahrgang'] as int?,
      naechsteService: json['naechste_service'] != null
          ? DateTime.parse(json['naechste_service'] as String)
          : null,
      naechsteMfk: json['naechste_mfk'] != null
          ? DateTime.parse(json['naechste_mfk'] as String)
          : null,
      kmStand: json['km_stand'] as int?,
      versicherung: json['versicherung'] as String?,
      notizen: json['notizen'] as String?,
      aktiv: json['aktiv'] as bool? ?? true,
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
      'kennzeichen': kennzeichen,
      'marke': marke,
      'modell': modell,
      'jahrgang': jahrgang,
      'naechste_service': naechsteService?.toIso8601String().split('T')[0],
      'naechste_mfk': naechsteMfk?.toIso8601String().split('T')[0],
      'km_stand': kmStand,
      'versicherung': versicherung,
      'notizen': notizen,
      'aktiv': aktiv,
      'is_deleted': isDeleted,
    };
  }

  String get displayName {
    if (kennzeichen != null && kennzeichen!.isNotEmpty) {
      return '$bezeichnung ($kennzeichen)';
    }
    return bezeichnung;
  }

  String get fahrzeugInfo {
    final parts = <String>[];
    if (marke != null && marke!.isNotEmpty) parts.add(marke!);
    if (modell != null && modell!.isNotEmpty) parts.add(modell!);
    if (jahrgang != null) parts.add('$jahrgang');
    return parts.join(' ');
  }
}
