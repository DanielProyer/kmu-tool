import 'package:kmu_tool_app/core/config/features.dart';
import 'package:kmu_tool_app/data/models/subscription_plan.dart';
import 'package:kmu_tool_app/data/models/user_subscription.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/services/admin/admin_service.dart';

/// Singleton: Lädt Plan + Subscription, merged Features + Overrides.
class FeatureService {
  static FeatureService? _instance;
  static FeatureService get instance => _instance ??= FeatureService._();
  FeatureService._();

  SubscriptionPlan? _plan;
  UserSubscription? _subscription;
  // Default: alles frei bis Abo-System live ist
  Map<String, dynamic> _mergedFeatures = {
    'kunden': true,
    'offerten': true,
    'auftraege': true,
    'zeiterfassung': true,
    'rapporte': true,
    'rechnungen': true,
    'buchhaltung': true,
    'auftrag_dashboard': true,
    'auto_website': true,
    'artikel': true,
    'lagerorte': true,
    'lieferanten': true,
    'lagerverwaltung': true,
    'bestellwesen': true,
    'inventur': true,
    'max_kunden': -1,
    'max_offerten': -1,
  };

  SubscriptionPlan? get currentPlan => _plan;
  UserSubscription? get currentSubscription => _subscription;

  /// Lädt Plan + Subscription des aktuellen Users.
  /// Fallback: free-Plan wenn kein Abo vorhanden.
  Future<void> load() async {
    try {
      final userId = SupabaseService.client.auth.currentUser?.id;
      if (userId == null) {
        _setFreePlan();
        return;
      }

      // Subscription laden
      final subResponse = await SupabaseService.client
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (subResponse != null) {
        _subscription = UserSubscription.fromJson(subResponse);
      }

      // Plan laden (aus Subscription oder Fallback free)
      final planId = _subscription?.planId ?? 'free';
      final planResponse = await SupabaseService.client
          .from('subscription_plans')
          .select()
          .eq('id', planId)
          .maybeSingle();

      if (planResponse != null) {
        _plan = SubscriptionPlan.fromJson(planResponse);
      } else {
        _setFreePlan();
        return;
      }

      // Features mergen: Plan-Features + User-Overrides
      _mergedFeatures = Map<String, dynamic>.from(_plan!.features);
      if (_subscription != null) {
        for (final entry in _subscription!.featureOverrides.entries) {
          _mergedFeatures[entry.key] = entry.value;
        }
      }
    } catch (_) {
      _setFreePlan();
    }
  }

  void _setFreePlan() {
    _plan = null;
    _subscription = null;
    // Solange subscription_plans-Tabelle nicht existiert: alles freischalten
    // TODO: Auf Free-Plan zurücksetzen wenn Abo-System live ist
    _mergedFeatures = {
      'kunden': true,
      'offerten': true,
      'auftraege': true,
      'zeiterfassung': true,
      'rapporte': true,
      'rechnungen': true,
      'buchhaltung': true,
      'auftrag_dashboard': true,
      'auto_website': true,
      'artikel': true,
      'lagerorte': true,
      'lieferanten': true,
      'lagerverwaltung': true,
      'bestellwesen': true,
      'inventur': true,
      'max_kunden': -1,
      'max_offerten': -1,
    };
  }

  /// Prüft ob ein Feature aktiv ist.
  bool hasFeature(AppFeature feature) {
    final value = _mergedFeatures[feature.key];
    if (value is bool) return value;
    return false;
  }

  /// Gibt ein Limit zurück (-1 = unlimited).
  int getLimit(String key) {
    final value = _mergedFeatures[key];
    if (value is int) return value;
    return -1;
  }

  /// Prüft ob eine Route erlaubt ist.
  bool isRouteAllowed(String location) {
    // Admin-Routen: nur für Admins
    if (location.startsWith('/admin')) {
      return AdminService.isAdmin;
    }

    // Dashboard-Route separat prüfen
    if (location.contains('/dashboard')) {
      return hasFeature(AppFeature.auftragDashboard);
    }

    for (final feature in AppFeature.values) {
      for (final route in feature.routes) {
        if (location.startsWith(route)) {
          return hasFeature(feature);
        }
      }
    }
    return true; // Unbekannte Routen erlauben (login, home, etc.)
  }

  /// Reset bei Logout.
  void reset() {
    _plan = null;
    _subscription = null;
    _mergedFeatures = {};
    _instance = null; // Nächster Zugriff erstellt neue Instanz mit Free-Plan-Default
  }
}
