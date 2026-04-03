import 'package:uuid/uuid.dart';
import '../../data/models/bestellvorschlag.dart';
import '../../data/models/bestellung.dart';
import '../../data/models/bestellposition.dart';
import '../../data/repositories/bestellvorschlag_repository.dart';
import '../../data/repositories/bestellung_repository.dart';
import '../../data/repositories/bestellposition_repository.dart';
import '../../services/supabase/supabase_service.dart';

class BestellvorschlagService {
  static String get _userId => SupabaseService.currentUser!.id;

  /// Generiert Bestellvorschläge für alle Artikel unter Mindestbestand.
  static Future<int> generateVorschlaege() async {
    // Alle Artikel mit mindestbestand > 0 laden
    final artikel = await SupabaseService.client
        .from('artikel')
        .select('id, bezeichnung, mindestbestand, lagerbestand')
        .eq('user_id', _userId)
        .eq('is_deleted', false)
        .gt('mindestbestand', 0);

    int created = 0;
    for (final a in artikel) {
      final artikelId = a['id'] as String;
      final mindestbestand = (a['mindestbestand'] as num?)?.toDouble() ?? 0;
      final aktuellerBestand = (a['lagerbestand'] as num?)?.toDouble() ?? 0;

      if (aktuellerBestand >= mindestbestand) continue;

      // Skip wenn offener Vorschlag existiert
      final hasOpen = await BestellvorschlagRepository.hasOpenForArtikel(artikelId);
      if (hasOpen) continue;

      // Hauptlieferant ermitteln
      final lieferantData = await SupabaseService.client
          .from('artikel_lieferanten')
          .select('lieferant_id, mindestbestellmenge')
          .eq('artikel_id', artikelId)
          .eq('ist_hauptlieferant', true)
          .limit(1);

      String? lieferantId;
      double mindestbestellmenge = 0;
      if (lieferantData.isNotEmpty) {
        lieferantId = lieferantData.first['lieferant_id'] as String?;
        mindestbestellmenge =
            (lieferantData.first['mindestbestellmenge'] as num?)?.toDouble() ?? 0;
      }

      // Vorschlagsmenge: 2x Mindestbestand - aktueller Bestand
      double vorschlagsMenge = 2 * mindestbestand - aktuellerBestand;
      if (vorschlagsMenge < mindestbestellmenge) {
        vorschlagsMenge = mindestbestellmenge;
      }

      final vorschlag = Bestellvorschlag(
        id: const Uuid().v4(),
        userId: _userId,
        artikelId: artikelId,
        lieferantId: lieferantId,
        vorgeschlageneMenge: vorschlagsMenge,
        aktuellerBestand: aktuellerBestand,
        mindestbestand: mindestbestand,
      );
      await BestellvorschlagRepository.save(vorschlag);
      created++;
    }
    return created;
  }

  /// Erstellt Bestellung aus Vorschlägen (gruppiert nach Lieferant).
  static Future<String?> createBestellungFromVorschlaege(
      List<Bestellvorschlag> vorschlaege) async {
    if (vorschlaege.isEmpty) return null;

    final lieferantId = vorschlaege.first.lieferantId;
    if (lieferantId == null) return null;

    final bestellNr = await BestellungRepository.nextBestellNr();
    final bestellungId = const Uuid().v4();

    double total = 0;

    // EK-Preise für Positionen laden
    final positionen = <Bestellposition>[];
    for (final v in vorschlaege) {
      double ekPreis = 0;
      if (v.lieferantId != null) {
        final preis = await SupabaseService.client
            .from('artikel_lieferanten')
            .select('einkaufspreis')
            .eq('artikel_id', v.artikelId)
            .eq('lieferant_id', v.lieferantId!)
            .limit(1);
        if (preis.isNotEmpty) {
          ekPreis = (preis.first['einkaufspreis'] as num?)?.toDouble() ?? 0;
        }
      }

      total += v.vorgeschlageneMenge * ekPreis;
      positionen.add(Bestellposition(
        id: const Uuid().v4(),
        userId: _userId,
        bestellungId: bestellungId,
        artikelId: v.artikelId,
        menge: v.vorgeschlageneMenge,
        einzelpreis: ekPreis,
      ));
    }

    // Bestellung erstellen
    final bestellung = Bestellung(
      id: bestellungId,
      userId: _userId,
      lieferantId: lieferantId,
      bestellNr: bestellNr,
      status: 'entwurf',
      bestellDatum: DateTime.now(),
      totalBetrag: total,
    );
    await BestellungRepository.save(bestellung);

    // Positionen erstellen
    for (final p in positionen) {
      await BestellpositionRepository.save(p);
    }

    // Vorschläge als bestellt markieren
    for (final v in vorschlaege) {
      await BestellvorschlagRepository.updateStatus(v.id, 'bestellt');
    }

    return bestellungId;
  }

  /// Registriert Wareneingang für eine Bestellposition.
  static Future<void> registerWareneingang({
    required String bestellungId,
    required String positionId,
    required double gelieferteMenge,
    required String lagerortId,
  }) async {
    // Position aktualisieren
    await BestellpositionRepository.updateGelieferteMenge(
        positionId, gelieferteMenge);

    // Alle Positionen prüfen für Status-Update
    final positionen =
        await BestellpositionRepository.getByBestellung(bestellungId);

    bool alleGeliefert = true;
    bool teilweiseGeliefert = false;
    for (final p in positionen) {
      final geliefert =
          p.id == positionId ? gelieferteMenge : p.gelieferteMenge;
      if (geliefert < p.menge) {
        alleGeliefert = false;
      }
      if (geliefert > 0) {
        teilweiseGeliefert = true;
      }
    }

    if (alleGeliefert) {
      await BestellungRepository.updateStatus(bestellungId, 'geliefert');
    } else if (teilweiseGeliefert) {
      await BestellungRepository.updateStatus(bestellungId, 'teilgeliefert');
    }
  }
}
