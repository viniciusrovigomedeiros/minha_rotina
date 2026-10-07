class SocialBackendConfig {
  const SocialBackendConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.projectRef,
  });

  static const current = SocialBackendConfig(
    supabaseUrl: String.fromEnvironment('SOCIAL_SUPABASE_URL'),
    supabasePublishableKey: String.fromEnvironment(
      'SOCIAL_SUPABASE_PUBLISHABLE_KEY',
    ),
    projectRef: String.fromEnvironment('SOCIAL_SUPABASE_PROJECT_REF'),
  );

  final String supabaseUrl;
  final String supabasePublishableKey;
  final String projectRef;

  bool get isConfigured =>
      supabaseUrl.trim().isNotEmpty && supabasePublishableKey.trim().isNotEmpty;

  List<String> get missingKeys {
    final items = <String>[];
    if (supabaseUrl.trim().isEmpty) {
      items.add('SOCIAL_SUPABASE_URL');
    }
    if (supabasePublishableKey.trim().isEmpty) {
      items.add('SOCIAL_SUPABASE_PUBLISHABLE_KEY');
    }
    return items;
  }
}
