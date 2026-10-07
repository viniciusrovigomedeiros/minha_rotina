import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/social_backend_config.dart';

class SocialSupabaseService {
  SocialSupabaseService._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  static SupabaseClient get client {
    if (!_isInitialized) {
      throw StateError('Cliente Supabase social ainda nao foi inicializado.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize({
    SocialBackendConfig config = SocialBackendConfig.current,
  }) async {
    if (!config.isConfigured || _isInitialized) {
      return;
    }

    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabasePublishableKey,
    );
    _isInitialized = true;
  }
}
