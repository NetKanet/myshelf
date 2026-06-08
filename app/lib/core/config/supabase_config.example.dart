/// Template for `supabase_config.dart` (which is GITIGNORED).
///
/// Copy this file to `supabase_config.dart` and fill in your own values:
///   Supabase: dashboard → Project Settings → API (url + anon/publishable key).
///   Google:   the **Web** OAuth client ID from Google Cloud Console
///             (used as serverClientId for native Google sign-in).
class SupabaseConfig {
  static const String url = 'https://YOUR-PROJECT-REF.supabase.co';
  static const String publishableKey = 'sb_publishable_YOUR_PUBLISHABLE_KEY';

  /// Web OAuth client ID (…apps.googleusercontent.com) used by google_sign_in
  /// as `serverClientId` so the returned ID token is accepted by Supabase.
  static const String googleServerClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
}
