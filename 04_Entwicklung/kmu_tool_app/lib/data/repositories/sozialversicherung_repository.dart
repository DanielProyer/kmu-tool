import 'package:uuid/uuid.dart';
import '../../services/auth/betrieb_service.dart';
import '../../services/supabase/supabase_service.dart';
import '../models/sozialversicherung.dart';

class SozialversicherungRepository {
  static const _table = 'sozialversicherungen';

  /// Gibt die SV-Einstellungen zurueck oder erstellt Standardwerte.
  static Future<Sozialversicherung> get() async {
    final userId = await BetriebService.getDataOwnerId();
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (data != null) {
      return Sozialversicherung.fromJson(data);
    }

    // Erstelle Standard-Eintrag
    final sv = Sozialversicherung(
      id: const Uuid().v4(),
      userId: userId,
    );
    await SupabaseService.client.from(_table).insert(sv.toJson());
    return sv;
  }

  static Future<void> save(Sozialversicherung sv) async {
    await SupabaseService.client.from(_table).upsert(sv.toJson());
  }
}
