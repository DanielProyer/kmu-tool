import '../../services/supabase/supabase_service.dart';
import '../models/konto.dart';

class KontoRepository {
  static const _table = 'konten';

  String get _userId => SupabaseService.currentUser!.id;

  Future<List<Konto>> getAll() async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .order('kontonummer', ascending: true);
    return data.map((json) => Konto.fromJson(json)).toList();
  }

  Future<Konto?> getById(String id) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    return data != null ? Konto.fromJson(data) : null;
  }

  Future<List<Konto>> getByKlasse(int klasse) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('kontenklasse', klasse)
        .order('kontonummer', ascending: true);
    return data.map((json) => Konto.fromJson(json)).toList();
  }

  Future<List<Konto>> getByTyp(String typ) async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('user_id', _userId)
        .eq('typ', typ)
        .order('kontonummer', ascending: true);
    return data.map((json) => Konto.fromJson(json)).toList();
  }

  Future<void> save(Konto konto) async {
    await SupabaseService.client.from(_table).upsert(konto.toJson());
  }

  Future<void> updateSaldo(String id, double saldo) async {
    await SupabaseService.client
        .from(_table)
        .update({'saldo': saldo})
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
