import 'dart:convert';
import 'package:flutter/foundation.dart';
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

      debugPrint('[UserCreationService] status=${response.status}');
      debugPrint('[UserCreationService] data=${response.data} (${response.data.runtimeType})');

      // Response data parsen — kann String oder Map sein
      Map<String, dynamic>? data;
      if (response.data is Map<String, dynamic>) {
        data = response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        try {
          final parsed = jsonDecode(response.data as String);
          if (parsed is Map<String, dynamic>) {
            data = parsed;
          }
        } catch (_) {}
      }

      if (response.status != 200) {
        final errorMsg = data?['error'] as String? ??
            'Fehler (Status ${response.status})';
        return UserCreationResult(success: false, message: errorMsg);
      }

      if (data != null && data['success'] == true) {
        return UserCreationResult(
          success: true,
          userId: data['user_id'] as String?,
          message: data['message'] as String? ?? 'Benutzer erstellt',
        );
      }

      return UserCreationResult(
        success: false,
        message: 'Unerwartete Antwort: ${response.data}',
      );
    } catch (e) {
      debugPrint('[UserCreationService] ERROR: $e');
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
