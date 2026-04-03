import 'package:uuid/uuid.dart';
import '../../data/models/inventur.dart';
import '../../data/models/inventur_position.dart';
import '../../data/models/lagerbewegung.dart';
import '../../data/repositories/inventur_repository.dart';
import '../../data/repositories/inventur_position_repository.dart';
import '../../data/repositories/lagerbewegung_repository.dart';
import '../supabase/supabase_service.dart';
import '../auth/betrieb_service.dart';

class InventurService {
  /// Erstellt eine Inventur und generiert Positionen aus aktuellen Lagerbestaenden.
  static Future<String> createInventur({
    required String bezeichnung,
    required DateTime stichtag,
    String? lagerortId,
    String? bemerkung,
  }) async {
    final userId = await BetriebService.getDataOwnerId();
    final inventurId = const Uuid().v4();
    final inventur = Inventur(
      id: inventurId,
      userId: userId,
      bezeichnung: bezeichnung,
      stichtag: stichtag,
      lagerortId: lagerortId,
      bemerkung: bemerkung,
      status: 'geplant',
    );
    await InventurRepository.save(inventur);

    // Positionen aus Lagerbestaenden generieren
    var query = SupabaseService.client
        .from('lagerbestaende')
        .select('artikel_id, lagerort_id, menge')
        .eq('user_id', userId);
    if (lagerortId != null) {
      query = query.eq('lagerort_id', lagerortId);
    }
    final bestaende = await query;

    // Bewertungspreise laden (Verkaufspreis als Bewertung)
    final positionen = <InventurPosition>[];
    for (final b in bestaende) {
      final artikelId = b['artikel_id'] as String;
      final menge = (b['menge'] as num?)?.toDouble() ?? 0;

      // Bewertungspreis: EK vom Hauptlieferant oder Verkaufspreis
      double bewertungspreis = 0;
      final artikelData = await SupabaseService.client
          .from('artikel')
          .select('verkaufspreis')
          .eq('id', artikelId)
          .limit(1);
      if (artikelData.isNotEmpty) {
        bewertungspreis =
            (artikelData.first['verkaufspreis'] as num?)?.toDouble() ?? 0;
      }

      positionen.add(InventurPosition(
        id: const Uuid().v4(),
        userId: userId,
        inventurId: inventurId,
        artikelId: artikelId,
        lagerortId: b['lagerort_id'] as String,
        sollBestand: menge,
        bewertungspreis: bewertungspreis,
      ));
    }

    if (positionen.isNotEmpty) {
      await InventurPositionRepository.bulkCreate(positionen);
    }

    return inventurId;
  }

  /// Startet die Zaehlung (Status: geplant -> aktiv).
  static Future<void> startZaehlung(String inventurId) async {
    // Pruefen ob Inventur existiert und im richtigen Status ist
    final inventur = await InventurRepository.getById(inventurId);
    if (inventur == null) {
      throw Exception('Inventur nicht gefunden (ID: $inventurId)');
    }
    if (inventur.status != 'geplant') {
      throw Exception(
          'Inventur kann nur aus Status "geplant" gestartet werden '
          '(aktuell: ${inventur.status})');
    }

    // Pruefen ob Positionen vorhanden sind
    final positionen =
        await InventurPositionRepository.getByInventur(inventurId);
    if (positionen.isEmpty) {
      throw Exception(
          'Keine Positionen vorhanden. Bitte zuerst Lagerbestaende anlegen.');
    }

    await InventurRepository.updateStatus(inventurId, 'aktiv');
  }

  /// Schliesst Inventur ab und erstellt Korrekturbewegungen fuer Differenzen.
  static Future<int> abschliessen(String inventurId) async {
    final userId = await BetriebService.getDataOwnerId();
    final positionen =
        await InventurPositionRepository.getByInventur(inventurId);

    int korrekturen = 0;
    for (final pos in positionen) {
      if (!pos.gezaehlt) continue;
      final diff = pos.differenz ?? 0;
      if (diff == 0) continue;

      // Inventur-Lagerbewegung erstellen
      final bewegung = Lagerbewegung(
        id: const Uuid().v4(),
        userId: userId,
        artikelId: pos.artikelId,
        lagerortId: pos.lagerortId,
        bewegungstyp: 'inventur',
        menge: diff, // positiv = Zugang, negativ = Abgang
        referenzTyp: 'inventur',
        referenzId: inventurId,
        bemerkung: 'Inventurkorrektur: Soll ${pos.sollBestand}, '
            'Ist ${pos.istBestand}',
      );
      await LagerbewegungRepository.create(bewegung);
      korrekturen++;
    }

    await InventurRepository.updateStatus(inventurId, 'abgeschlossen');
    return korrekturen;
  }
}
