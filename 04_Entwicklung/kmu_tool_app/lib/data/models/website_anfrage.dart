class WebsiteAnfrage {
  final String id;
  final String configId;
  final String typ;
  final String name;
  final String email;
  final String? telefon;
  final String? nachricht;
  final Map<String, dynamic> details;
  final bool gelesen;
  final DateTime? createdAt;

  WebsiteAnfrage({
    required this.id,
    required this.configId,
    this.typ = 'kontakt',
    required this.name,
    required this.email,
    this.telefon,
    this.nachricht,
    this.details = const {},
    this.gelesen = false,
    this.createdAt,
  });

  factory WebsiteAnfrage.fromJson(Map<String, dynamic> json) {
    return WebsiteAnfrage(
      id: json['id'],
      configId: json['config_id'],
      typ: json['typ'] ?? 'kontakt',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      telefon: json['telefon'],
      nachricht: json['nachricht'],
      details: json['details'] is Map
          ? Map<String, dynamic>.from(json['details'])
          : {},
      gelesen: json['gelesen'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'config_id': configId,
      'typ': typ,
      'name': name,
      'email': email,
      'telefon': telefon,
      'nachricht': nachricht,
      'details': details,
      'gelesen': gelesen,
    };
  }

  String get typLabel {
    switch (typ) {
      case 'kontakt':
        return 'Kontaktanfrage';
      case 'offerte':
        return 'Offertanfrage';
      default:
        return typ;
    }
  }
}
