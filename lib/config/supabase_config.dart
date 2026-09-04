class SupabaseConfig {
  const SupabaseConfig._();

  static const String url =
      'https://zyvjpejazhxtpazprixh.supabase.co';

  static const String publishableKey =
      'sb_publishable_-amRhajxjn1XdeH-DkvG5w_Xce-1Xdy';

  static bool get isConfigured =>
      url.trim().isNotEmpty && publishableKey.trim().isNotEmpty;
}
