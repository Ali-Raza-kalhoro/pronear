// lib/core/services/email_otp_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Sends and verifies Supabase email OTPs.
///
/// For passwordless signup/sign-in, use signInWithOtp + OtpType.email.
/// For password recovery, use resetPasswordForEmail + OtpType.recovery.
class EmailOtpService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> sendOtp({
    required String email,
    bool shouldCreateUser = false,
    bool isRecovery = false,
  }) async {
    final normalizedEmail = email.trim();

    if (isRecovery) {
      await _client.auth.resetPasswordForEmail(normalizedEmail);
      return;
    }

    await _client.auth.signInWithOtp(
      email: normalizedEmail,
      shouldCreateUser: shouldCreateUser,
    );
  }

  Future<AuthResponse> verifyRecoveryOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.recovery,
    );
  }

  /// Matches signInWithOtp() used by the registration screen.
  Future<AuthResponse> verifySignupOtp({
    required String email,
    required String token,
  }) {
    return _client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  /// This checks the app's public profiles table, not Supabase Auth directly.
  /// It returns false if the table/query is unavailable.
  Future<bool> userExists(String email) async {
    try {
      final result = await _client
          .from('profiles')
          .select('id')
          .eq('email', email.trim())
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }
}
