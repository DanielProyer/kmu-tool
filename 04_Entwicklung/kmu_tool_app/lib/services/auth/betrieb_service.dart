import '../../services/supabase/supabase_service.dart';

/// Service für Betrieb-basierte Daten-Zuordnung.
/// Geschäftsführer: eigene ID als Data-Owner.
/// Mitarbeiter: ID des Geschäftsführers als Data-Owner.
class BetriebService {
  static String? _cachedOwnerId;
  static String? _cachedRolle;
  static String? _lastUserId;

  /// Gibt die user_id des Betrieb-Owners zurück.
  /// GF: eigene ID, Mitarbeiter: GF's ID.
  static Future<String> getDataOwnerId() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) {
      throw Exception('Nicht eingeloggt');
    }

    // Cache invalidieren wenn User gewechselt hat
    if (_lastUserId != currentUserId) {
      _cachedOwnerId = null;
      _cachedRolle = null;
      _lastUserId = currentUserId;
    }

    if (_cachedOwnerId != null) return _cachedOwnerId!;

    final data = await SupabaseService.client
        .from('user_profiles')
        .select('betrieb_owner_id')
        .eq('id', currentUserId)
        .maybeSingle();

    if (data != null && data['betrieb_owner_id'] != null) {
      _cachedOwnerId = data['betrieb_owner_id'] as String;
    } else {
      _cachedOwnerId = currentUserId;
    }

    return _cachedOwnerId!;
  }

  /// Aktuelle Rolle des eingeloggten Users.
  static Future<String> getCurrentRolle() async {
    final currentUserId = SupabaseService.currentUser?.id;
    if (currentUserId == null) return 'mitarbeiter';

    if (_lastUserId != currentUserId) {
      _cachedOwnerId = null;
      _cachedRolle = null;
      _lastUserId = currentUserId;
    }

    if (_cachedRolle != null) return _cachedRolle!;

    final data = await SupabaseService.client
        .from('user_profiles')
        .select('rolle')
        .eq('id', currentUserId)
        .maybeSingle();

    _cachedRolle = (data?['rolle'] as String?) ?? 'mitarbeiter';
    return _cachedRolle!;
  }

  /// Ist der aktuelle User Geschäftsführer?
  static Future<bool> isGeschaeftsfuehrer() async {
    return await getCurrentRolle() == 'geschaeftsfuehrer';
  }

  /// Ist der aktuelle User mindestens Vorarbeiter?
  static Future<bool> isVorarbeiterOrHigher() async {
    final rolle = await getCurrentRolle();
    return rolle == 'geschaeftsfuehrer' || rolle == 'vorarbeiter';
  }

  /// Cache leeren (z.B. nach Login/Logout).
  static void clearCache() {
    _cachedOwnerId = null;
    _cachedRolle = null;
    _lastUserId = null;
  }

  /// Synchroner Zugriff auf gecachte Rolle (nur nach erstem Laden verfügbar).
  static String? get cachedRolle => _cachedRolle;

  /// Synchroner Zugriff auf gecachten Owner-ID (nur nach erstem Laden verfügbar).
  static String? get cachedOwnerId => _cachedOwnerId;

  /// Prüft ob eine Route für die aktuelle Rolle erlaubt ist.
  static bool isRouteAllowed(String route) {
    final rolle = _cachedRolle ?? 'geschaeftsfuehrer';

    final allowedRoutes = _rollenRoutes[rolle];
    if (allowedRoutes == null) return false;
    if (allowedRoutes.contains('*')) return true;

    return allowedRoutes.any((r) => route.startsWith(r));
  }

  static const Map<String, List<String>> _rollenRoutes = {
    'geschaeftsfuehrer': ['*'],
    'vorarbeiter': [
      '/kunden', '/auftraege', '/offerten',
      '/zeiterfassung', '/rapporte',
      '/artikel', '/lagerorte', '/bestellungen',
      '/kalender', '/einstellungen',
    ],
    'mitarbeiter': [
      '/auftraege', '/zeiterfassung', '/rapporte',
      '/artikel', '/kalender', '/einstellungen',
    ],
    'kunde': ['/dashboard'],
  };
}
