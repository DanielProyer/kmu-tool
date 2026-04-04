import 'package:go_router/go_router.dart';
import 'package:kmu_tool_app/presentation/screens/home_screen.dart';
import 'package:kmu_tool_app/presentation/screens/login_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kunden/kunden_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kunden/kunde_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kunden/kunde_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kunden/kunde_kontakt_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/offerten/offerten_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/offerten/offerte_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/offerten/offerte_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/auftraege/auftraege_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/auftraege/auftrag_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/auftraege/auftrag_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/auftraege/auftrag_dashboard/auftrag_dashboard_screen.dart';
import 'package:kmu_tool_app/presentation/screens/zeiterfassung/zeiterfassung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/rapporte/rapport_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/rechnungen/rechnungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/rechnungen/rechnung_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/buchhaltung_dashboard_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/kontenplan_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/buchungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/buchung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/berichte_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/mwst_overview_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/mwst_einstellungen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/mwst_abrechnung_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/artikel_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/artikel_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/artikel_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/lagerort_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/lagerort_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/lagerbewegung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/artikel/lagerbewegungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/lieferanten/lieferanten_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/lieferanten/lieferant_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/lieferanten/lieferant_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/bestellungen/bestellvorschlaege_screen.dart';
import 'package:kmu_tool_app/presentation/screens/bestellungen/bestellungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/bestellungen/bestellung_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/bestellungen/bestellung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/inventur/inventuren_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/inventur/inventur_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/inventur/inventur_zaehlung_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_dashboard_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_kunden_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_kunde_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_kunde_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_rechnungen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_rechnung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_migrationen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/admin/admin_migration_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/website/website_dashboard_screen.dart';
import 'package:kmu_tool_app/presentation/screens/website/website_setup_screen.dart';
import 'package:kmu_tool_app/presentation/screens/website/website_design_screen.dart';
import 'package:kmu_tool_app/presentation/screens/website/website_anfragen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/website/website_vorschau_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kalender/kalender_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kalender/termin_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/kalender/termin_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/betriebsverwaltung_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/firmenprofil_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/bankverbindungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/bankverbindung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/logo_upload_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/berechtigungen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/berechtigung_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/sozialversicherungen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/lohn/lohn_uebersicht_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/lohn/lohn_monat_screen.dart';
import 'package:kmu_tool_app/presentation/screens/betriebsverwaltung/lohn/lohn_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/einstellungen_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/theme_selection_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/abo_verwaltung_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/mitarbeiter/mitarbeiter_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/mitarbeiter/mitarbeiter_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/fahrzeuge/fahrzeuge_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/einstellungen/fahrzeuge/fahrzeug_form_screen.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';
import 'package:kmu_tool_app/services/feature/feature_service.dart';
import 'package:kmu_tool_app/services/auth/betrieb_service.dart';

final router = GoRouter(
  initialLocation: '/',
  refreshListenable: SupabaseService.authNotifier,
  redirect: (context, state) {
    final isLoggedIn = SupabaseService.isAuthenticated;
    final isLoginPage = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginPage) return '/login';
    if (isLoggedIn && isLoginPage) return '/';

    // Feature-Gate: Prüfe ob Route erlaubt ist
    if (isLoggedIn && !isLoginPage) {
      final location = state.matchedLocation;
      if (!FeatureService.instance.isRouteAllowed(location)) {
        return '/';
      }
      // Rollen-Gate: Prüfe ob Route für aktuelle Rolle erlaubt ist
      if (!BetriebService.isRouteAllowed(location)) {
        return '/';
      }
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),

    // ─── Kunden ───
    GoRoute(
      path: '/kunden',
      builder: (context, state) => const KundenListScreen(),
    ),
    GoRoute(
      path: '/kunden/neu',
      builder: (context, state) => const KundeFormScreen(),
    ),
    GoRoute(
      path: '/kunden/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return KundeDetailScreen(kundeId: id);
      },
    ),
    GoRoute(
      path: '/kunden/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return KundeFormScreen(kundeId: id);
      },
    ),
    GoRoute(
      path: '/kunden/:id/kontakte/neu',
      builder: (context, state) {
        final kundeId = state.pathParameters['id']!;
        return KundeKontaktFormScreen(kundeId: kundeId);
      },
    ),
    GoRoute(
      path: '/kunden/:id/kontakte/:kid/bearbeiten',
      builder: (context, state) {
        final kundeId = state.pathParameters['id']!;
        final kontaktId = state.pathParameters['kid']!;
        return KundeKontaktFormScreen(
            kundeId: kundeId, kontaktId: kontaktId);
      },
    ),

    // ─── Offerten ───
    GoRoute(
      path: '/offerten',
      builder: (context, state) => const OffertenListScreen(),
    ),
    GoRoute(
      path: '/offerten/neu',
      builder: (context, state) {
        final kundeId = state.uri.queryParameters['kundeId'];
        return OfferteFormScreen(kundeId: kundeId);
      },
    ),
    GoRoute(
      path: '/offerten/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OfferteDetailScreen(offerteId: id);
      },
    ),
    GoRoute(
      path: '/offerten/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return OfferteFormScreen(offerteId: id);
      },
    ),

    // ─── Aufträge ───
    GoRoute(
      path: '/auftraege',
      builder: (context, state) => const AuftraegeListScreen(),
    ),
    GoRoute(
      path: '/auftraege/neu',
      builder: (context, state) {
        final offerteId = state.uri.queryParameters['offerteId'];
        return AuftragFormScreen(offerteId: offerteId);
      },
    ),
    GoRoute(
      path: '/auftraege/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AuftragDetailScreen(auftragId: id);
      },
    ),
    GoRoute(
      path: '/auftraege/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AuftragFormScreen(auftragId: id);
      },
    ),
    GoRoute(
      path: '/auftraege/:id/zeiterfassung/neu',
      builder: (context, state) {
        final auftragId = state.pathParameters['id']!;
        return ZeiterfassungFormScreen(auftragId: auftragId);
      },
    ),
    GoRoute(
      path: '/auftraege/:id/rapport/neu',
      builder: (context, state) {
        final auftragId = state.pathParameters['id']!;
        return RapportFormScreen(auftragId: auftragId);
      },
    ),
    GoRoute(
      path: '/auftraege/:id/dashboard',
      builder: (context, state) {
        final auftragId = state.pathParameters['id']!;
        return AuftragDashboardScreen(auftragId: auftragId);
      },
    ),

    // ─── Rechnungen ───
    GoRoute(
      path: '/rechnungen',
      builder: (context, state) => const RechnungenListScreen(),
    ),
    GoRoute(
      path: '/rechnungen/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return RechnungDetailScreen(rechnungId: id);
      },
    ),

    // ─── Buchhaltung ───
    GoRoute(
      path: '/buchhaltung',
      builder: (context, state) => const BuchhaltungDashboardScreen(),
    ),
    GoRoute(
      path: '/buchhaltung/konten',
      builder: (context, state) => const KontenplanScreen(),
    ),
    GoRoute(
      path: '/buchhaltung/buchungen',
      builder: (context, state) {
        final filterKonto = state.extra as int?;
        return BuchungenListScreen(filterKontonummer: filterKonto);
      },
    ),
    GoRoute(
      path: '/buchhaltung/buchungen/neu',
      builder: (context, state) => const BuchungFormScreen(),
    ),
    GoRoute(
      path: '/buchhaltung/berichte',
      builder: (context, state) => const BerichteScreen(),
    ),

    // ─── MWST ───
    GoRoute(
      path: '/buchhaltung/mwst',
      builder: (context, state) => const MwstOverviewScreen(),
    ),
    GoRoute(
      path: '/buchhaltung/mwst/einstellungen',
      builder: (context, state) => const MwstEinstellungenScreen(),
    ),
    GoRoute(
      path: '/buchhaltung/mwst/abrechnung/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MwstAbrechnungDetailScreen(abrechnungId: id);
      },
    ),

    // ─── Artikel ───
    GoRoute(
      path: '/artikel',
      builder: (context, state) => const ArtikelListScreen(),
    ),
    GoRoute(
      path: '/artikel/neu',
      builder: (context, state) => const ArtikelFormScreen(),
    ),
    GoRoute(
      path: '/artikel/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ArtikelDetailScreen(artikelId: id);
      },
    ),
    GoRoute(
      path: '/artikel/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return ArtikelFormScreen(artikelId: id);
      },
    ),
    GoRoute(
      path: '/artikel/:id/bewegungen',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LagerbewegungenListScreen(artikelId: id);
      },
    ),
    GoRoute(
      path: '/artikel/:id/bewegungen/neu',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LagerbewegungFormScreen(artikelId: id);
      },
    ),

    // ─── Lagerorte ───
    GoRoute(
      path: '/lagerorte',
      builder: (context, state) => const LagerortListScreen(),
    ),
    GoRoute(
      path: '/lagerorte/neu',
      builder: (context, state) => const LagerortFormScreen(),
    ),
    GoRoute(
      path: '/lagerorte/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LagerortFormScreen(lagerortId: id);
      },
    ),

    // ─── Lieferanten ───
    GoRoute(
      path: '/lieferanten',
      builder: (context, state) => const LieferantenListScreen(),
    ),
    GoRoute(
      path: '/lieferanten/neu',
      builder: (context, state) => const LieferantFormScreen(),
    ),
    GoRoute(
      path: '/lieferanten/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LieferantDetailScreen(lieferantId: id);
      },
    ),
    GoRoute(
      path: '/lieferanten/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LieferantFormScreen(lieferantId: id);
      },
    ),

    // ─── Bestellungen ───
    GoRoute(
      path: '/bestellungen',
      builder: (context, state) => const BestellungenListScreen(),
    ),
    GoRoute(
      path: '/bestellungen/vorschlaege',
      builder: (context, state) => const BestellvorschlaegeScreen(),
    ),
    GoRoute(
      path: '/bestellungen/neu',
      builder: (context, state) => const BestellungFormScreen(),
    ),
    GoRoute(
      path: '/bestellungen/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BestellungDetailScreen(bestellungId: id);
      },
    ),

    // ─── Inventur ───
    GoRoute(
      path: '/inventur',
      builder: (context, state) => const InventurenListScreen(),
    ),
    GoRoute(
      path: '/inventur/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return InventurDetailScreen(inventurId: id);
      },
    ),
    GoRoute(
      path: '/inventur/:id/zaehlung',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return InventurZaehlungScreen(inventurId: id);
      },
    ),

    // ─── Admin ───
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
    GoRoute(
      path: '/admin/kunden',
      builder: (context, state) => const AdminKundenListScreen(),
    ),
    GoRoute(
      path: '/admin/kunden/neu',
      builder: (context, state) => const AdminKundeFormScreen(),
    ),
    GoRoute(
      path: '/admin/kunden/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AdminKundeDetailScreen(kundeProfilId: id);
      },
    ),
    GoRoute(
      path: '/admin/kunden/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AdminKundeFormScreen(kundeProfilId: id);
      },
    ),
    GoRoute(
      path: '/admin/rechnungen',
      builder: (context, state) => const AdminRechnungenScreen(),
    ),
    GoRoute(
      path: '/admin/rechnungen/neu',
      builder: (context, state) {
        final kundeProfilId =
            state.uri.queryParameters['kundeProfilId'];
        return AdminRechnungFormScreen(
            kundeProfilId: kundeProfilId);
      },
    ),
    GoRoute(
      path: '/admin/rechnungen/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return AdminRechnungFormScreen(rechnungId: id);
      },
    ),
    GoRoute(
      path: '/admin/migrationen',
      builder: (context, state) => const AdminMigrationenScreen(),
    ),
    GoRoute(
      path: '/admin/migrationen/neu',
      builder: (context, state) {
        final kundeProfilId =
            state.uri.queryParameters['kundeProfilId'];
        return AdminMigrationFormScreen(
            kundeProfilId: kundeProfilId);
      },
    ),

    // ─── Auto-Website ───
    GoRoute(
      path: '/website',
      builder: (context, state) => const WebsiteDashboardScreen(),
    ),
    GoRoute(
      path: '/website/einrichten',
      builder: (context, state) => const WebsiteSetupScreen(),
    ),
    GoRoute(
      path: '/website/design',
      builder: (context, state) => const WebsiteDesignScreen(),
    ),
    GoRoute(
      path: '/website/anfragen',
      builder: (context, state) => const WebsiteAnfragenScreen(),
    ),
    GoRoute(
      path: '/website/vorschau',
      builder: (context, state) => const WebsiteVorschauScreen(),
    ),

    // ─── Kalender ───
    GoRoute(
      path: '/kalender',
      builder: (context, state) => const KalenderScreen(),
    ),
    GoRoute(
      path: '/kalender/neu',
      builder: (context, state) => const TerminFormScreen(),
    ),
    GoRoute(
      path: '/kalender/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TerminDetailScreen(terminId: id);
      },
    ),
    GoRoute(
      path: '/kalender/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TerminFormScreen(terminId: id);
      },
    ),

    // ─── Betriebsverwaltung ───
    GoRoute(
      path: '/betrieb',
      builder: (context, state) => const BetriebsverwaltungScreen(),
    ),
    GoRoute(
      path: '/betrieb/firmenprofil',
      builder: (context, state) => const FirmenprofilScreen(),
    ),
    GoRoute(
      path: '/betrieb/bankverbindungen',
      builder: (context, state) => const BankverbindungenListScreen(),
    ),
    GoRoute(
      path: '/betrieb/bankverbindungen/neu',
      builder: (context, state) => const BankverbindungFormScreen(),
    ),
    GoRoute(
      path: '/betrieb/bankverbindungen/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BankverbindungFormScreen(bankverbindungId: id);
      },
    ),
    GoRoute(
      path: '/betrieb/logo',
      builder: (context, state) => const LogoUploadScreen(),
    ),
    GoRoute(
      path: '/betrieb/berechtigungen',
      builder: (context, state) => const BerechtigungenScreen(),
    ),
    GoRoute(
      path: '/betrieb/berechtigungen/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return BerechtigungDetailScreen(mitarbeiterId: id);
      },
    ),
    GoRoute(
      path: '/betrieb/sozialversicherungen',
      builder: (context, state) => const SozialversicherungenScreen(),
    ),
    GoRoute(
      path: '/betrieb/lohn',
      builder: (context, state) => const LohnUebersichtScreen(),
    ),
    GoRoute(
      path: '/betrieb/lohn/:jahr/:monat',
      builder: (context, state) {
        final jahr = int.parse(state.pathParameters['jahr']!);
        final monat = int.parse(state.pathParameters['monat']!);
        return LohnMonatScreen(jahr: jahr, monat: monat);
      },
    ),
    GoRoute(
      path: '/betrieb/lohn/detail/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return LohnDetailScreen(lohnabrechnungId: id);
      },
    ),

    // ─── Einstellungen ───
    GoRoute(
      path: '/einstellungen',
      builder: (context, state) => const EinstellungenScreen(),
    ),
    GoRoute(
      path: '/einstellungen/theme',
      builder: (context, state) => const ThemeSelectionScreen(),
    ),
    GoRoute(
      path: '/einstellungen/abo',
      builder: (context, state) => const AboVerwaltungScreen(),
    ),

    // ─── Mitarbeiter (unter Einstellungen) ───
    GoRoute(
      path: '/einstellungen/mitarbeiter',
      builder: (context, state) => const MitarbeiterListScreen(),
    ),
    GoRoute(
      path: '/einstellungen/mitarbeiter/neu',
      builder: (context, state) => const MitarbeiterFormScreen(),
    ),
    GoRoute(
      path: '/einstellungen/mitarbeiter/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return MitarbeiterFormScreen(mitarbeiterId: id);
      },
    ),

    // ─── Fahrzeuge (unter Einstellungen) ───
    GoRoute(
      path: '/einstellungen/fahrzeuge',
      builder: (context, state) => const FahrzeugeListScreen(),
    ),
    GoRoute(
      path: '/einstellungen/fahrzeuge/neu',
      builder: (context, state) => const FahrzeugFormScreen(),
    ),
    GoRoute(
      path: '/einstellungen/fahrzeuge/:id/bearbeiten',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return FahrzeugFormScreen(fahrzeugId: id);
      },
    ),
  ],
);
