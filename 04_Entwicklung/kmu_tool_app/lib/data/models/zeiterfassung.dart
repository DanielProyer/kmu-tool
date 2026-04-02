class Zeiterfassung {
  final String id;
  final String userId;
  final String auftragId;
  final DateTime datum;
  final String? startZeit;
  final String? endZeit;
  final int pauseMinuten;
  final int? dauerMinuten;
  final String? beschreibung;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Zeiterfassung({
    required this.id,
    required this.userId,
    required this.auftragId,
    required this.datum,
    this.startZeit,
    this.endZeit,
    this.pauseMinuten = 0,
    this.dauerMinuten,
    this.beschreibung,
    this.createdAt,
    this.updatedAt,
  });

  factory Zeiterfassung.fromJson(Map<String, dynamic> json) {
    return Zeiterfassung(
      id: json['id'],
      userId: json['user_id'],
      auftragId: json['auftrag_id'],
      datum: DateTime.parse(json['datum']),
      startZeit: json['start_zeit'],
      endZeit: json['end_zeit'],
      pauseMinuten: json['pause_minuten'] ?? 0,
      dauerMinuten: json['dauer_minuten'],
      beschreibung: json['beschreibung'],
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
      'auftrag_id': auftragId,
      'datum': datum.toIso8601String().split('T').first,
      'start_zeit': startZeit,
      'end_zeit': endZeit,
      'pause_minuten': pauseMinuten,
      'dauer_minuten': dauerMinuten,
      'beschreibung': beschreibung,
    };
  }
}
