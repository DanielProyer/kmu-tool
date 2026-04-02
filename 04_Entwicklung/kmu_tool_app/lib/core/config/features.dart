/// Alle Feature-Keys die geprüft werden können.
enum AppFeature {
  kunden('kunden'),
  offerten('offerten'),
  auftraege('auftraege'),
  zeiterfassung('zeiterfassung'),
  rapporte('rapporte'),
  rechnungen('rechnungen'),
  buchhaltung('buchhaltung'),
  auftragDashboard('auftrag_dashboard'),
  autoWebsite('auto_website');

  final String key;
  const AppFeature(this.key);

  /// Zugehörige Route(n) für Route-Guard.
  List<String> get routes {
    switch (this) {
      case AppFeature.kunden:
        return ['/kunden'];
      case AppFeature.offerten:
        return ['/offerten'];
      case AppFeature.auftraege:
        return ['/auftraege'];
      case AppFeature.rechnungen:
        return ['/rechnungen'];
      case AppFeature.buchhaltung:
        return ['/buchhaltung'];
      case AppFeature.auftragDashboard:
        return []; // Dynamic route: /auftraege/:id/dashboard
      default:
        return [];
    }
  }
}
