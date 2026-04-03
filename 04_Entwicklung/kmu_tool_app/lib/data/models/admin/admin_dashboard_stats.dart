class AdminDashboardStats {
  final int totalKunden;
  final int aktiveKunden;
  final int inaktiveKunden;
  final int gesperrteKunden;
  final int testKunden;
  final int offeneRechnungenCount;
  final double offeneRechnungenBetrag;
  final int gemahnteRechnungenCount;
  final double bezahlteRechnungenMonat;
  final int migrationenGeplant;
  final int migrationenAktiv;
  final int planFree;
  final int planStandard;
  final int planPremium;

  const AdminDashboardStats({
    this.totalKunden = 0,
    this.aktiveKunden = 0,
    this.inaktiveKunden = 0,
    this.gesperrteKunden = 0,
    this.testKunden = 0,
    this.offeneRechnungenCount = 0,
    this.offeneRechnungenBetrag = 0,
    this.gemahnteRechnungenCount = 0,
    this.bezahlteRechnungenMonat = 0,
    this.migrationenGeplant = 0,
    this.migrationenAktiv = 0,
    this.planFree = 0,
    this.planStandard = 0,
    this.planPremium = 0,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    return AdminDashboardStats(
      totalKunden: json['total_kunden'] as int? ?? 0,
      aktiveKunden: json['aktive_kunden'] as int? ?? 0,
      inaktiveKunden: json['inaktive_kunden'] as int? ?? 0,
      gesperrteKunden: json['gesperrte_kunden'] as int? ?? 0,
      testKunden: json['test_kunden'] as int? ?? 0,
      offeneRechnungenCount: json['offene_rechnungen_count'] as int? ?? 0,
      offeneRechnungenBetrag:
          (json['offene_rechnungen_betrag'] as num?)?.toDouble() ?? 0,
      gemahnteRechnungenCount:
          json['gemahnete_rechnungen_count'] as int? ?? 0,
      bezahlteRechnungenMonat:
          (json['bezahlte_rechnungen_monat'] as num?)?.toDouble() ?? 0,
      migrationenGeplant: json['migrationen_geplant'] as int? ?? 0,
      migrationenAktiv: json['migrationen_aktiv'] as int? ?? 0,
      planFree: json['plan_free'] as int? ?? 0,
      planStandard: json['plan_standard'] as int? ?? 0,
      planPremium: json['plan_premium'] as int? ?? 0,
    );
  }
}

class AdminKundeStats {
  final int kundenCount;
  final int offertenCount;
  final int auftraegeCount;
  final int rechnungenCount;
  final int artikelCount;
  final int buchungenCount;
  final int offeneOfferten;
  final int aktiveAuftraege;
  final double offeneRechnungenBetrag;

  const AdminKundeStats({
    this.kundenCount = 0,
    this.offertenCount = 0,
    this.auftraegeCount = 0,
    this.rechnungenCount = 0,
    this.artikelCount = 0,
    this.buchungenCount = 0,
    this.offeneOfferten = 0,
    this.aktiveAuftraege = 0,
    this.offeneRechnungenBetrag = 0,
  });

  factory AdminKundeStats.fromJson(Map<String, dynamic> json) {
    return AdminKundeStats(
      kundenCount: json['kunden_count'] as int? ?? 0,
      offertenCount: json['offerten_count'] as int? ?? 0,
      auftraegeCount: json['auftraege_count'] as int? ?? 0,
      rechnungenCount: json['rechnungen_count'] as int? ?? 0,
      artikelCount: json['artikel_count'] as int? ?? 0,
      buchungenCount: json['buchungen_count'] as int? ?? 0,
      offeneOfferten: json['offene_offerten'] as int? ?? 0,
      aktiveAuftraege: json['aktive_auftraege'] as int? ?? 0,
      offeneRechnungenBetrag:
          (json['offene_rechnungen_betrag'] as num?)?.toDouble() ?? 0,
    );
  }
}
