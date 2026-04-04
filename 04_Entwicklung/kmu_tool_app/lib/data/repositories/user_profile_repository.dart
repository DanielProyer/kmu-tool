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

  /// Static: Get current user's profile.
  static Future<UserProfile?> getCurrentProfile() async {
    final userId = SupabaseService.currentUser?.id;
    if (userId == null) return null;
    final data = await SupabaseService.client
        .from(_table)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return data != null ? UserProfile.fromJson(data) : null;
  }

  /// Static: Update specific fields on current user's profile.
  static Future<void> updateFields(Map<String, dynamic> fields) async {
    final userId = SupabaseService.currentUser!.id;
    await SupabaseService.client
        .from(_table)
        .update(fields)
        .eq('id', userId);
  }
}
