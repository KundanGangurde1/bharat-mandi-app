import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // =========================
  // LOGIN
  // =========================

  static Future<void> sendLoginLink(String email) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  // =========================
  // SESSION
  // =========================

  static bool isLoggedIn() {
    return _client.auth.currentSession != null;
  }

  static User? currentUser() {
    return _client.auth.currentUser;
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  // =========================
  // USER CREATE (FIRST LOGIN)
  // =========================

  static Future<void> createUserIfNotExists() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final existing = await _client
        .from('app_users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existing == null) {
      await _client.from('app_users').insert({
        'id': user.id,
        'email': user.email,
        'is_premium': false,
      });

      print('🆕 New app user created');
    }
  }

  // =========================
  // PREMIUM CHECK
  // =========================

  static Future<bool> isPremiumUser() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final data = await _client
        .from('app_users')
        .select('is_premium')
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) return false;

    return data['is_premium'] == true;
  }
}
