class Artikel {
  final String id;
  final String userId;
  final String? artikelNr;
  final String bezeichnung;
  final String kategorie;
  final String? einheit;
  final double einkaufspreis;
  final double verkaufspreis;
  final double lagerbestand;
  final double? mindestbestand;
  final String? lieferant;
  final String? notizen;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Artikel({
    required this.id,
    required this.userId,
    this.artikelNr,
    required this.bezeichnung,
    this.kategorie = 'material',
    this.einheit = 'Stk',
    this.einkaufspreis = 0,
    this.verkaufspreis = 0,
    this.lagerbestand = 0,
    this.mindestbestand,
    this.lieferant,
    this.notizen,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Artikel.fromJson(Map<String, dynamic> json) {
    return Artikel(
      id: json['id'],
      userId: json['user_id'],
      artikelNr: json['artikel_nr'],
      bezeichnung: json['bezeichnung'] ?? '',
      kategorie: json['kategorie'] ?? 'material',
      einheit: json['einheit'],
      einkaufspreis: (json['einkaufspreis'] ?? 0).toDouble(),
      verkaufspreis: (json['verkaufspreis'] ?? 0).toDouble(),
      lagerbestand: (json['lagerbestand'] ?? 0).toDouble(),
      mindestbestand: json['mindestbestand']?.toDouble(),
      lieferant: json['lieferant'],
      notizen: json['notizen'],
      isDeleted: json['is_deleted'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'artikel_nr': artikelNr,
      'bezeichnung': bezeichnung,
      'kategorie': kategorie,
      'einheit': einheit,
      'einkaufspreis': einkaufspreis,
      'verkaufspreis': verkaufspreis,
      'lagerbestand': lagerbestand,
      'mindestbestand': mindestbestand,
      'lieferant': lieferant,
      'notizen': notizen,
      'is_deleted': isDeleted,
    };
  }

  String get kategorieLabel {
    switch (kategorie) {
      case 'material':
        return 'Material';
      case 'werkzeug':
        return 'Werkzeug';
      case 'verbrauch':
        return 'Verbrauchsmaterial';
      default:
        return kategorie;
    }
  }

  String get displayName {
    if (artikelNr != null && artikelNr!.isNotEmpty) {
      return '$artikelNr - $bezeichnung';
    }
    return bezeichnung;
  }
}
