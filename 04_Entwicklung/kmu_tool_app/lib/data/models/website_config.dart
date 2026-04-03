class WebsiteConfig {
  final String id;
  final String userId;
  final String slug;
  final String firmenName;
  final String? untertitel;
  final String? logoPath;
  final String primaerfarbe;
  final String sekundaerfarbe;
  final String schriftart;
  final String designTemplate;
  final bool isPublished;
  final String? kontaktEmail;
  final String? kontaktTelefon;
  final String? adresseStrasse;
  final String? adresseHausnummer;
  final String? adressePlz;
  final String? adresseOrt;
  final String? oeffnungszeiten;
  final Map<String, dynamic> socialLinks;
  final String? seoTitle;
  final String? seoDescription;
  final String? impressumUid;
  final String? datenschutzText;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WebsiteConfig({
    required this.id,
    required this.userId,
    required this.slug,
    required this.firmenName,
    this.untertitel,
    this.logoPath,
    this.primaerfarbe = '#2563EB',
    this.sekundaerfarbe = '#1E40AF',
    this.schriftart = 'Inter',
    this.designTemplate = 'modern',
    this.isPublished = false,
    this.kontaktEmail,
    this.kontaktTelefon,
    this.adresseStrasse,
    this.adresseHausnummer,
    this.adressePlz,
    this.adresseOrt,
    this.oeffnungszeiten,
    this.socialLinks = const {},
    this.seoTitle,
    this.seoDescription,
    this.impressumUid,
    this.datenschutzText,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  factory WebsiteConfig.fromJson(Map<String, dynamic> json) {
    return WebsiteConfig(
      id: json['id'],
      userId: json['user_id'],
      slug: json['slug'],
      firmenName: json['firmen_name'] ?? '',
      untertitel: json['untertitel'],
      logoPath: json['logo_path'],
      primaerfarbe: json['primaerfarbe'] ?? '#2563EB',
      sekundaerfarbe: json['sekundaerfarbe'] ?? '#1E40AF',
      schriftart: json['schriftart'] ?? 'Inter',
      designTemplate: json['design_template'] ?? 'modern',
      isPublished: json['is_published'] ?? false,
      kontaktEmail: json['kontakt_email'],
      kontaktTelefon: json['kontakt_telefon'],
      adresseStrasse: json['adresse_strasse'],
      adresseHausnummer: json['adresse_hausnummer'],
      adressePlz: json['adresse_plz'],
      adresseOrt: json['adresse_ort'],
      oeffnungszeiten: json['oeffnungszeiten'],
      socialLinks: json['social_links'] is Map
          ? Map<String, dynamic>.from(json['social_links'])
          : {},
      seoTitle: json['seo_title'],
      seoDescription: json['seo_description'],
      impressumUid: json['impressum_uid'],
      datenschutzText: json['datenschutz_text'],
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
      'slug': slug,
      'firmen_name': firmenName,
      'untertitel': untertitel,
      'logo_path': logoPath,
      'primaerfarbe': primaerfarbe,
      'sekundaerfarbe': sekundaerfarbe,
      'schriftart': schriftart,
      'design_template': designTemplate,
      'is_published': isPublished,
      'kontakt_email': kontaktEmail,
      'kontakt_telefon': kontaktTelefon,
      'adresse_strasse': adresseStrasse,
      'adresse_hausnummer': adresseHausnummer,
      'adresse_plz': adressePlz,
      'adresse_ort': adresseOrt,
      'oeffnungszeiten': oeffnungszeiten,
      'social_links': socialLinks,
      'seo_title': seoTitle,
      'seo_description': seoDescription,
      'impressum_uid': impressumUid,
      'datenschutz_text': datenschutzText,
      'is_deleted': isDeleted,
    };
  }

  WebsiteConfig copyWith({
    String? slug,
    String? firmenName,
    String? untertitel,
    String? logoPath,
    String? primaerfarbe,
    String? sekundaerfarbe,
    String? schriftart,
    String? designTemplate,
    bool? isPublished,
    String? kontaktEmail,
    String? kontaktTelefon,
    String? adresseStrasse,
    String? adresseHausnummer,
    String? adressePlz,
    String? adresseOrt,
    String? oeffnungszeiten,
    Map<String, dynamic>? socialLinks,
    String? seoTitle,
    String? seoDescription,
    String? impressumUid,
    String? datenschutzText,
  }) {
    return WebsiteConfig(
      id: id,
      userId: userId,
      slug: slug ?? this.slug,
      firmenName: firmenName ?? this.firmenName,
      untertitel: untertitel ?? this.untertitel,
      logoPath: logoPath ?? this.logoPath,
      primaerfarbe: primaerfarbe ?? this.primaerfarbe,
      sekundaerfarbe: sekundaerfarbe ?? this.sekundaerfarbe,
      schriftart: schriftart ?? this.schriftart,
      designTemplate: designTemplate ?? this.designTemplate,
      isPublished: isPublished ?? this.isPublished,
      kontaktEmail: kontaktEmail ?? this.kontaktEmail,
      kontaktTelefon: kontaktTelefon ?? this.kontaktTelefon,
      adresseStrasse: adresseStrasse ?? this.adresseStrasse,
      adresseHausnummer: adresseHausnummer ?? this.adresseHausnummer,
      adressePlz: adressePlz ?? this.adressePlz,
      adresseOrt: adresseOrt ?? this.adresseOrt,
      oeffnungszeiten: oeffnungszeiten ?? this.oeffnungszeiten,
      socialLinks: socialLinks ?? this.socialLinks,
      seoTitle: seoTitle ?? this.seoTitle,
      seoDescription: seoDescription ?? this.seoDescription,
      impressumUid: impressumUid ?? this.impressumUid,
      datenschutzText: datenschutzText ?? this.datenschutzText,
      isDeleted: isDeleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String get designTemplateLabel {
    switch (designTemplate) {
      case 'modern':
        return 'Modern';
      case 'klassisch':
        return 'Klassisch';
      case 'handwerk':
        return 'Handwerk';
      default:
        return designTemplate;
    }
  }
}
