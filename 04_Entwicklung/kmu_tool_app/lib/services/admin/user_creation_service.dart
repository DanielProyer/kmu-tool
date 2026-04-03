import 'package:kmu_tool_app/services/supabase/supabase_service.dart';

class UserCreationResult {
  final bool success;
  final String? userId;
  final String message;

  const UserCreationResult({
    required this.success,
    this.userId,
    required this.message,
  });
}

class UserCreationService {
  /// Erstellt einen neuen Auth-User via Edge Function.
  /// Kann von Admin (GF erstellen) oder GF (Mitarbeiter erstellen) aufgerufen werden.
  static Future<UserCreationResult> createUser({
    required String email,
    String? password,
    String? firmaName,
    String rolle = 'mitarbeiter',
    String? betriebOwnerId,
    String? adminProfilId,
    bool sendResetEmail = true,
  }) async {
    try {
      final response = await SupabaseService.client.functions.invoke(
        'create-user',
        body: {
          'email': email,
          'password': password,
          'firma_name': firmaName,
          'rolle': rolle,
          'betrieb_owner_id': betriebOwnerId,
          'admin_profil_id': adminProfilId,
          'send_reset_email': sendResetEmail,
        },
      );

      if (response.status != 200) {
        final data = response.data;
        final errorMsg = data is Map
            ? (data['error'] as String?) ?? 'Unbekannter Fehler'
            : 'Fehler (Status ${response.status})';
        return UserCreationResult(
          success: false,
          message: errorMsg,
        );
      }

      final data = response.data;
      if (data is Map && data['success'] == true) {
        return UserCreationResult(
          success: true,
          userId: data['user_id'] as String?,
          message: data['message'] as String? ?? 'Benutzer erstellt',
        );
      }

      return const UserCreationResult(
        success: false,
        message: 'Unerwartete Antwort vom Server',
      );
    } catch (e) {
      return UserCreationResult(
        success: false,
        message: 'Verbindungsfehler: $e',
      );
    }
  }

  /// Passwort-Reset-Mail senden (fuer bestehende User).
  static Future<void> sendPasswordReset(String email) async {
    await SupabaseService.resetPassword(email);
  }
}
