import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/supabase_config.dart';
import '../../core/providers.dart';

/// Returns a Google ID token (or null if cancelled). Swappable in tests.
typedef GoogleIdTokenFetcher = Future<String?> Function();

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._client, {GoogleIdTokenFetcher? idTokenFetcher})
      : _fetchIdToken = idTokenFetcher ?? _defaultGoogleIdToken,
        super(const AsyncValue.data(null));

  final SupabaseClient _client;
  final GoogleIdTokenFetcher _fetchIdToken;

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final idToken = await _fetchIdToken();
      if (idToken == null) {
        // User cancelled — return to idle without an error banner.
        state = const AsyncValue.data(null);
        return;
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(_friendly(e), st);
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // ignore — Supabase sign-out below is what matters
    }
    await _client.auth.signOut();
  }

  String _friendly(Object e) {
    if (e is AuthException) return e.message;
    return 'Google sign-in failed. Please try again.';
  }
}

/// Default native Google sign-in (google_sign_in 7.x): initialize once, then
/// authenticate and return the ID token.
bool _googleInitialized = false;
Future<String?> _defaultGoogleIdToken() async {
  if (!_googleInitialized) {
    await GoogleSignIn.instance.initialize(
      serverClientId: SupabaseConfig.googleServerClientId,
    );
    _googleInitialized = true;
  }
  try {
    final account = await GoogleSignIn.instance.authenticate();
    return account.authentication.idToken;
  } on GoogleSignInException catch (e) {
    if (e.code == GoogleSignInExceptionCode.canceled) return null;
    rethrow;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>(
  (ref) => AuthController(ref.watch(supabaseClientProvider)),
);

/// Current signed-in user (rebuilds when auth state changes).
final currentUserProvider = Provider<User?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
});
