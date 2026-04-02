import '../../services/supabase/supabase_service.dart';
import '../models/buchungs_vorlage.dart';

class BuchungsVorlageRepository {
  static const _table = 'buchungs_vorlagen';

  String get _userId => SupabaseService.currentUser!.id;

  Future<List<BuchungsVorlage>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('bezeichnung', ascending: true);
    return data.map((json) => BuchungsVorlage.fromJson(json)).toList();
  }

  Future<List<BuchungsVorlage>> getByTrigger(String trigger) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('auto_trigger', trigger);
    return data.map((json) => BuchungsVorlage.fromJson(json)).toList();
  }

  Future<void> save(BuchungsVorlage vorlage) async {
    await SupabaseService.client.from(_table).upsert(vorlage.toJson());
  }
}
