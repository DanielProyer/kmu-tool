import '../../services/supabase/supabase_service.dart';
import '../models/user_profile.dart';

class UserProfileRepository {
  static const _table = 'user_profiles';

  String get _userId => SupabaseService.currentUser!.id;

  /// Get the current user's profile.
  Future<UserProfile?> get() async {
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', _userId)
        .maybeSingle();
    return data != null ? UserProfile.fromJson(data) : null;
  }

  /// Upsert the current user's profile.
  Future<void> save(UserProfile profile) async {
    await SupabaseService.client.from(_table).upsert(profile.toJson());
  }
}
