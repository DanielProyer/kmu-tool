class MwstEinstellung {
  final String id;
  final String userId;
  final String methode; // effektiv, saldosteuersatz
  final String abrechnungsperiode; // quartalsweise, halbjaehrlich, jaehrlich
  final double? saldosteuersatz1;
  final String? saldosteuersatz1Bez;
  final double? saldosteuersatz2;
  final String? saldosteuersatz2Bez;
  final String? mwstNummer;
  final DateTime? mwstPflichtigSeit;
  final bool vereinbartesEntgelt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MwstEinstellung({
    required this.id,
    required this.userId,
    this.methode = 'effektiv',
    this.abrechnungsperiode = 'halbjaehrlich',
    this.saldosteuersatz1,
    this.saldosteuersatz1Bez,
    this.saldosteuersatz2,
    this.saldosteuersatz2Bez,
    this.mwstNummer,
    this.mwstPflichtigSeit,
    this.vereinbartesEntgelt = true,
    this.createdAt,
    this.updatedAt,
  });

  factory MwstEinstellung.fromJson(Map<String, dynamic> json) {
    return MwstEinstellung(
      id: json['id'],
      userId: json['user_id'],
      methode: json['methode'] ?? 'effektiv',
      abrechnungsperiode: json['abrechnungsperiode'] ?? 'halbjaehrlich',
      saldosteuersatz1: json['saldosteuersatz_1']?.toDouble(),
      saldosteuersatz1Bez: json['saldosteuersatz_1_bez'],
      saldosteuersatz2: json['saldosteuersatz_2']?.toDouble(),
      saldosteuersatz2Bez: json['saldosteuersatz_2_bez'],
      mwstNummer: json['mwst_nummer'],
      mwstPflichtigSeit: json['mwst_pflichtig_seit'] != null
          ? DateTime.parse(json['mwst_pflichtig_seit'])
          : null,
      vereinbartesEntgelt: json['vereinbartes_entgelt'] ?? true,
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
      'methode': methode,
      'abrechnungsperiode': abrechnungsperiode,
      'saldosteuersatz_1': saldosteuersatz1,
      'saldosteuersatz_1_bez': saldosteuersatz1Bez,
      'saldosteuersatz_2': saldosteuersatz2,
      'saldosteuersatz_2_bez': saldosteuersatz2Bez,
      'mwst_nummer': mwstNummer,
      'mwst_pflichtig_seit': mwstPflichtigSeit?.toIso8601String().split('T').first,
      'vereinbartes_entgelt': vereinbartesEntgelt,
    };
  }

  bool get isEffektiv => methode == 'effektiv';
  bool get isSaldosteuersatz => methode == 'saldosteuersatz';
  bool get hatZweitenSss => saldosteuersatz2 != null && saldosteuersatz2! > 0;

  String get methodeLabel =>
      isEffektiv ? 'Effektive Methode' : 'Saldosteuersatz-Methode';

  String get periodeLabel {
    switch (abrechnungsperiode) {
      case 'quartalsweise':
        return 'Quartalsweise';
      case 'halbjaehrlich':
        return 'Halbjaehrlich';
      case 'jaehrlich':
        return 'Jaehrlich';
      default:
        return abrechnungsperiode;
    }
  }

  /// Branchenspezifische Saldosteuersaetze (ab 2025)
  static const Map<String, double> branchenSaetze = {
    'Sanitaerinstallation': 5.3,
    'Elektroinstallation': 5.3,
    'Malerarbeiten': 5.3,
    'Zimmerei/Holzbau': 5.3,
    'Schreinerei': 5.3,
    'Allg. Baugewerbe': 5.3,
    'Garten-/Landschaftsbau': 2.8,
    'Gebaeudereinigung': 4.6,
  };
}
