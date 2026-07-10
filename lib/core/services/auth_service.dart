import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralizes all Supabase authentication operations.
/// All screens and interceptors obtain the current session via this service.
class AuthService {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // ── Session Accessors ──────────────────────────────────────────────────────

  Session? get currentSession => _supabase.auth.currentSession;

  User? get currentUser => _supabase.auth.currentUser;

  /// Returns the current access token or null if not authenticated.
  String? get accessToken => currentSession?.accessToken;

  bool get isSignedIn => currentSession != null;

  // ── Auth Operations ────────────────────────────────────────────────────────

  /// Sign in with email and password. Throws [AuthException] on failure.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password. Throws [AuthException] on failure.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  /// Send a password reset email. Throws [AuthException] on failure.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  /// Sign out and clear the session.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Stream of auth state changes (signed in, signed out, token refreshed).
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
