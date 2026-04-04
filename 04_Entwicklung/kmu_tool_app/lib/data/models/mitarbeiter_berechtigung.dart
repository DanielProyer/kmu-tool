class MitarbeiterBerechtigung {
  final String id;
  final String userId;
  final String mitarbeiterId;
  final String modul;
  final bool lesen;
  final bool schreiben;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MitarbeiterBerechtigung({
    required this.id,
    required this.userId,
    required this.mitarbeiterId,
    required this.modul,
    this.lesen = false,
    this.schreiben = false,
    this.createdAt,
    this.updatedAt,
  });

  factory MitarbeiterBerechtigung.fromJson(Map<String, dynamic> json) {
    return MitarbeiterBerechtigung(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      mitarbeiterId: json['mitarbeiter_id'] as String,
      modul: json['modul'] as String,
      lesen: json['lesen'] as bool? ?? false,
      schreiben: json['schreiben'] as bool? ?? false,
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
      'mitarbeiter_id': mitarbeiterId,
      'modul': modul,
      'lesen': lesen,
      'schreiben': schreiben,
    };
  }

  static const allModule = [
    'kunden',
    'offerten',
    'auftraege',
    'rechnungen',
    'buchhaltung',
    'artikel',
    'bestellwesen',
    'kalender',
    'website',
  ];

  static String modulLabel(String modul) {
    switch (modul) {
      case 'kunden': return 'Kunden';
      case 'offerten': return 'Offerten';
      case 'auftraege': return 'Auftraege';
      case 'rechnungen': return 'Rechnungen';
      case 'buchhaltung': return 'Buchhaltung';
      case 'artikel': return 'Artikelstamm';
      case 'bestellwesen': return 'Bestellwesen';
      case 'kalender': return 'Kalender';
      case 'website': return 'Website';
      default: return modul;
    }
  }
}
