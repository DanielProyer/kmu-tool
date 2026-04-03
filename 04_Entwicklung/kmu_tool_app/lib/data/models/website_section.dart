class WebsiteSection {
  final String id;
  final String configId;
  final String typ;
  final String? titel;
  final Map<String, dynamic> content;
  final int sortierung;
  final bool isVisible;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WebsiteSection({
    required this.id,
    required this.configId,
    required this.typ,
    this.titel,
    this.content = const {},
    this.sortierung = 0,
    this.isVisible = true,
    this.createdAt,
    this.updatedAt,
  });

  factory WebsiteSection.fromJson(Map<String, dynamic> json) {
    return WebsiteSection(
      id: json['id'],
      configId: json['config_id'],
      typ: json['typ'],
      titel: json['titel'],
      content: json['content'] is Map
          ? Map<String, dynamic>.from(json['content'])
          : {},
      sortierung: json['sortierung'] ?? 0,
      isVisible: json['is_visible'] ?? true,
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
      'config_id': configId,
      'typ': typ,
      'titel': titel,
      'content': content,
      'sortierung': sortierung,
      'is_visible': isVisible,
    };
  }

  WebsiteSection copyWith({
    String? titel,
    Map<String, dynamic>? content,
    int? sortierung,
    bool? isVisible,
  }) {
    return WebsiteSection(
      id: id,
      configId: configId,
      typ: typ,
      titel: titel ?? this.titel,
      content: content ?? this.content,
      sortierung: sortierung ?? this.sortierung,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get typLabel {
    switch (typ) {
      case 'hero':
        return 'Hero-Bereich';
      case 'beschreibung':
        return 'Beschreibung';
      case 'leistungen':
        return 'Leistungen';
      case 'ueber_uns':
        return 'Ueber uns';
      case 'team':
        return 'Team';
      case 'referenzen':
        return 'Referenzen';
      case 'kundenstimmen':
        return 'Kundenstimmen';
      case 'galerie':
        return 'Galerie';
      case 'faq':
        return 'FAQ';
      case 'kontakt':
        return 'Kontakt';
      case 'offertanfrage':
        return 'Offertanfrage';
      case 'notfalldienst':
        return 'Notfalldienst';
      default:
        return typ;
    }
  }

  IconLabel get typIcon {
    switch (typ) {
      case 'hero':
        return const IconLabel(0xe3AF, 'image');
      case 'beschreibung':
        return const IconLabel(0xe242, 'description');
      case 'leistungen':
        return const IconLabel(0xEF76, 'build');
      case 'ueber_uns':
        return const IconLabel(0xe491, 'info');
      case 'team':
        return const IconLabel(0xe7EF, 'group');
      case 'referenzen':
        return const IconLabel(0xF06F6, 'work_history');
      case 'kundenstimmen':
        return const IconLabel(0xe24B, 'format_quote');
      case 'galerie':
        return const IconLabel(0xe3B6, 'photo_library');
      case 'faq':
        return const IconLabel(0xe8AF, 'help');
      case 'kontakt':
        return const IconLabel(0xe0B0, 'phone');
      case 'offertanfrage':
        return const IconLabel(0xEF42, 'request_quote');
      case 'notfalldienst':
        return const IconLabel(0xe029, 'emergency');
      default:
        return const IconLabel(0xe8A4, 'widgets');
    }
  }
}

class IconLabel {
  final int codePoint;
  final String name;
  const IconLabel(this.codePoint, this.name);
}
