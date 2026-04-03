import 'package:uuid/uuid.dart';
import '../../data/models/lagerbewegung.dart';
import '../../data/repositories/lagerbewegung_repository.dart';
import '../../services/supabase/supabase_service.dart';

class LagerService {
  static String get _userId => SupabaseService.currentUser!.id;

  static Future<void> wareneingang({
    required String artikelId,
    required String lagerortId,
    required double menge,
    String? bemerkung,
    String? referenzTyp,
    String? referenzId,
  }) async {
    final bewegung = Lagerbewegung(
      id: const Uuid().v4(),
      userId: _userId,
      artikelId: artikelId,
      lagerortId: lagerortId,
      bewegungstyp: 'eingang',
      menge: menge,
      bemerkung: bemerkung,
      referenzTyp: referenzTyp,
      referenzId: referenzId,
    );
    await LagerbewegungRepository.create(bewegung);
  }

  static Future<void> warenausgang({
    required String artikelId,
    required String lagerortId,
    required double menge,
    String? bemerkung,
    String? referenzTyp,
    String? referenzId,
  }) async {
    final bewegung = Lagerbewegung(
      id: const Uuid().v4(),
      userId: _userId,
      artikelId: artikelId,
      lagerortId: lagerortId,
      bewegungstyp: 'ausgang',
      menge: menge,
      bemerkung: bemerkung,
      referenzTyp: referenzTyp,
      referenzId: referenzId,
    );
    await LagerbewegungRepository.create(bewegung);
  }

  static Future<void> umlagerung({
    required String artikelId,
    required String vonLagerortId,
    required String nachLagerortId,
    required double menge,
    String? bemerkung,
  }) async {
    final bewegung = Lagerbewegung(
      id: const Uuid().v4(),
      userId: _userId,
      artikelId: artikelId,
      lagerortId: vonLagerortId,
      zielLagerortId: nachLagerortId,
      bewegungstyp: 'umlagerung',
      menge: menge,
      bemerkung: bemerkung,
    );
    await LagerbewegungRepository.create(bewegung);
  }

  static Future<void> korrektur({
    required String artikelId,
    required String lagerortId,
    required double menge, // positive = Zugang, negative = Abgang
    String? bemerkung,
  }) async {
    final bewegung = Lagerbewegung(
      id: const Uuid().v4(),
      userId: _userId,
      artikelId: artikelId,
      lagerortId: lagerortId,
      bewegungstyp: 'korrektur',
      menge: menge,
      bemerkung: bemerkung,
    );
    await LagerbewegungRepository.create(bewegung);
  }
}
