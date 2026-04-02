class AuftragZugriff {
  final String id;
  final String auftragId;
  final String userId;
  final String ownerUserId;
  final String rolle; // vollzugriff, standard, kunde
  final DateTime? createdAt;

  AuftragZugriff({
    required this.id,
    required this.auftragId,
    required this.userId,
    required this.ownerUserId,
    this.rolle = 'standard',
    this.createdAt,
  });

  factory AuftragZugriff.fromJson(Map<String, dynamic> json) {
    return AuftragZugriff(
      id: json['id'] as String,
      auftragId: json['auftrag_id'] as String,
      userId: json['user_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      rolle: json['rolle'] as String? ?? 'standard',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'auftrag_id': auftragId,
      'user_id': userId,
      'owner_user_id': ownerUserId,
      'rolle': rolle,
    };
  }

  String get rolleLabel {
    switch (rolle) {
      case 'vollzugriff':
        return 'Vollzugriff';
      case 'standard':
        return 'Standard';
      case 'kunde':
        return 'Kunde';
      default:
        return rolle;
    }
  }
}
