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
import 'package:kmu_tool_app/presentation/screens/zeiterfassung/zeiterfassung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/rapporte/rapport_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/rechnungen/rechnungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/rechnungen/rechnung_detail_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/buchhaltung_dashboard_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/kontenplan_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/buchungen_list_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/buchung_form_screen.dart';
import 'package:kmu_tool_app/presentation/screens/buchhaltung/berichte_screen.dart';
import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

final router = GoRouter(
  initialLocation: '/',
  refreshListenable: SupabaseService.authNotifier,
  redirect: (context, state) {
    final isLoggedIn = SupabaseService.isAuthenticated;
    final isLoginPage = state.matchedLocation == '/login';

    if (!isLoggedIn && !isLoginPage) return '/login';
    if (isLoggedIn && isLoginPage) return '/';

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
  ],
);
