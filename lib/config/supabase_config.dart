class SupabaseConfig {
  const SupabaseConfig._();

  static const String url =
  String.fromEnvironment('https://zyvjpejazhxtpazprixh.supabase.co');

  static const String publishableKey =
  String.fromEnvironment('sb_publishable_-amRhajxjn1XdeH-DkvG5w_Xce-1Xdy');

  static bool get isConfigured =>
      url.trim().isNotEmpty &&
          publishableKey.trim().isNotEmpty;

  static void debug() {
    print('SUPABASE URL = "$url"');
    print('SUPABASE KEY LENGTH = ${publishableKey.length}');
    print('SUPABASE CONFIGURED = $isConfigured');
  }
}