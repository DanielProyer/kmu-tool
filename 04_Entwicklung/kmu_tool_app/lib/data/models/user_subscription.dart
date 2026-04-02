class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final String status;
  final Map<String, dynamic> featureOverrides;
  final DateTime gueltigAb;
  final DateTime? gueltigBis;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    this.status = 'active',
    this.featureOverrides = const {},
    required this.gueltigAb,
    this.gueltigBis,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: json['status'] as String? ?? 'active',
      featureOverrides:
          json['feature_overrides'] as Map<String, dynamic>? ?? {},
      gueltigAb: DateTime.parse(json['gueltig_ab'] as String),
      gueltigBis: json['gueltig_bis'] != null
          ? DateTime.parse(json['gueltig_bis'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'status': status,
      'feature_overrides': featureOverrides,
      'gueltig_ab': gueltigAb.toIso8601String().split('T').first,
      if (gueltigBis != null)
        'gueltig_bis': gueltigBis!.toIso8601String().split('T').first,
    };
  }

  bool get isActive => status == 'active' || status == 'trial';
}
