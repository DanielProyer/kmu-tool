class MwstCode {
  final String id;
  final String code;
  final String bezeichnung;
  final double satz;
  final String typ; // umsatzsteuer, vorsteuer, bezugsteuer, ohne
  final int? formularZifferEffektiv;
  final int? formularZifferSss;
  final DateTime gueltigAb;
  final DateTime? gueltigBis;
  final bool istAktiv;

  MwstCode({
    required this.id,
    required this.code,
    required this.bezeichnung,
    required this.satz,
    required this.typ,
    this.formularZifferEffektiv,
    this.formularZifferSss,
    required this.gueltigAb,
    this.gueltigBis,
    this.istAktiv = true,
  });

  factory MwstCode.fromJson(Map<String, dynamic> json) {
    return MwstCode(
      id: json['id'],
      code: json['code'],
      bezeichnung: json['bezeichnung'],
      satz: (json['satz'] as num).toDouble(),
      typ: json['typ'],
      formularZifferEffektiv: json['formular_ziffer_effektiv'] as int?,
      formularZifferSss: json['formular_ziffer_sss'] as int?,
      gueltigAb: DateTime.parse(json['gueltig_ab']),
      gueltigBis: json['gueltig_bis'] != null
          ? DateTime.parse(json['gueltig_bis'])
          : null,
      istAktiv: json['ist_aktiv'] ?? true,
    );
  }

  bool get isUmsatzsteuer => typ == 'umsatzsteuer';
  bool get isVorsteuer => typ == 'vorsteuer';
  bool get isBezugsteuer => typ == 'bezugsteuer';
  bool get isOhne => typ == 'ohne';

  String get displayName => '$code - $bezeichnung (${satz.toStringAsFixed(1)}%)';
}
