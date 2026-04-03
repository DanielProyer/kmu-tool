class Inventur {
  final String id;
  final String userId;
  final String bezeichnung;
  final DateTime stichtag;
  final String? lagerortId;
  final String status; // geplant, aktiv, abgeschlossen
  final String? bemerkung;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Joined fields
  final String? lagerortBezeichnung;

  // Aggregated
  final int? positionenGesamt;
  final int? positionenGezaehlt;

  Inventur({
    required this.id,
    required this.userId,
    required this.bezeichnung,
    required this.stichtag,
    this.lagerortId,
    this.status = 'geplant',
    this.bemerkung,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
    this.lagerortBezeichnung,
    this.positionenGesamt,
    this.positionenGezaehlt,
  });

  factory Inventur.fromJson(Map<String, dynamic> json) {
    String? lagerortBez;
    if (json['lagerorte'] is Map) {
      lagerortBez = (json['lagerorte'] as Map)['bezeichnung'] as String?;
    }

    return Inventur(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bezeichnung: json['bezeichnung'] as String? ?? '',
      stichtag: DateTime.parse(json['stichtag'] as String),
      lagerortId: json['lagerort_id'] as String?,
      status: json['status'] as String? ?? 'geplant',
      bemerkung: json['bemerkung'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      lagerortBezeichnung: lagerortBez,
      positionenGesamt: json['positionen_gesamt'] as int?,
      positionenGezaehlt: json['positionen_gezaehlt'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bezeichnung': bezeichnung,
      'stichtag': stichtag.toIso8601String().split('T').first,
      'lagerort_id': lagerortId,
      'status': status,
      'bemerkung': bemerkung,
      'is_deleted': isDeleted,
    };
  }

  String get statusLabel {
    switch (status) {
      case 'geplant':
        return 'Geplant';
      case 'aktiv':
        return 'Aktiv';
      case 'abgeschlossen':
        return 'Abgeschlossen';
      default:
        return status;
    }
  }

  double get fortschritt {
    if (positionenGesamt == null || positionenGesamt == 0) return 0;
    return (positionenGezaehlt ?? 0) / positionenGesamt!;
  }
}
