import 'package:supabase_flutter/supabase_flutter.dart';

class AccountService {
  AccountService._();
  static final instance = AccountService._();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  bool _initialized = false;

  bool get isConfigured => supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (!isConfigured || _initialized) return;
    await Supabase.initialize(url: supabaseUrl, publishableKey: supabasePublishableKey);
    _initialized = true;
  }

  User? get currentUser => _initialized ? Supabase.instance.client.auth.currentUser : null;
  Stream<AuthState>? get authChanges => _initialized ? Supabase.instance.client.auth.onAuthStateChange : null;

  Future<AuthResponse> signIn({required String email, required String password}) {
    _requireConfigured();
    return Supabase.instance.client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  Future<AuthResponse> signUp({required String email, required String password}) {
    _requireConfigured();
    return Supabase.instance.client.auth.signUp(email: email.trim(), password: password);
  }

  Future<void> sendMagicLink(String email) async {
    _requireConfigured();
    await Supabase.instance.client.auth.signInWithOtp(email: email.trim());
  }

  Future<void> signOut() async {
    if (!_initialized) return;
    await Supabase.instance.client.auth.signOut();
  }

  void _requireConfigured() {
    if (!_initialized) {
      throw StateError('Account service is not configured in this build.');
    }
  }
}
