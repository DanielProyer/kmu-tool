class SubscriptionPlan {
  final String id;
  final String bezeichnung;
  final double preisMonatlich;
  final Map<String, dynamic> features;
  final int sortOrder;
  final bool aktiv;

  SubscriptionPlan({
    required this.id,
    required this.bezeichnung,
    required this.preisMonatlich,
    required this.features,
    this.sortOrder = 0,
    this.aktiv = true,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      bezeichnung: json['bezeichnung'] as String,
      preisMonatlich: (json['preis_monatlich'] as num).toDouble(),
      features: json['features'] as Map<String, dynamic>? ?? {},
      sortOrder: json['sort_order'] as int? ?? 0,
      aktiv: json['aktiv'] as bool? ?? true,
    );
  }

  bool hasFeature(String key) {
    final value = features[key];
    if (value is bool) return value;
    return false;
  }

  int getLimit(String key) {
    final value = features[key];
    if (value is int) return value;
    return -1; // unlimited
  }
}
