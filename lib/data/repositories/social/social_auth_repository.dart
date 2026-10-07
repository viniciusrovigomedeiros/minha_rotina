import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/social/social_session.dart';
import '../../services/social/social_backend_bootstrap_service.dart';
import '../../services/social/social_supabase_service.dart';

class SocialAuthRepository {
  SocialAuthRepository({
    required SocialBackendBootstrapService bootstrapService,
  }) : _bootstrapService = bootstrapService;

  final SocialBackendBootstrapService _bootstrapService;

  Future<SocialSession> getCurrentSession() async {
    if (!_bootstrapService.config.isConfigured ||
        !SocialSupabaseService.isInitialized) {
      return SocialSession.unconfigured;
    }

    return _fromUser(SocialSupabaseService.client.auth.currentUser);
  }

  Stream<SocialSession> get sessionChanges {
    if (!_bootstrapService.config.isConfigured ||
        !SocialSupabaseService.isInitialized) {
      return Stream.value(SocialSession.unconfigured);
    }

    return SocialSupabaseService.client.auth.onAuthStateChange.map(
      (event) => _fromUser(event.session?.user),
    );
  }

  Future<void> signIn(SocialAuthProvider provider) async {
    if (!_bootstrapService.config.isConfigured ||
        !SocialSupabaseService.isInitialized) {
      throw StateError('O Social esta indisponivel agora.');
    }

    final oauthProvider = switch (provider) {
      SocialAuthProvider.apple => OAuthProvider.apple,
      SocialAuthProvider.google => OAuthProvider.google,
    };

    await SocialSupabaseService.client.auth.signInWithOAuth(
      oauthProvider,
      redirectTo: 'app.minharotina.mobile://login-callback',
    );
  }

  Future<void> signOut() async {
    if (!SocialSupabaseService.isInitialized) {
      return;
    }
    await SocialSupabaseService.client.auth.signOut();
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final client = _client();
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': name.trim()},
      emailRedirectTo: 'app.minharotina.mobile://login-callback',
    );
    return response.session != null;
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    await _client().auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> uploadAvatar(String filePath) async {
    final client = _client();
    final user = client.auth.currentUser;
    if (user == null) {
      throw StateError('Entre na conta antes de enviar a foto.');
    }

    final extension = filePath.split('.').last.toLowerCase();
    final path = '${user.id}/avatar.$extension';
    await client.storage
        .from('profile-avatars')
        .uploadBinary(
          path,
          await File(filePath).readAsBytes(),
          fileOptions: const FileOptions(upsert: true),
        );
    await client
        .from('profiles')
        .update({
          'avatar_url': client.storage
              .from('profile-avatars')
              .getPublicUrl(path),
        })
        .eq('auth_user_id', user.id);
  }

  SupabaseClient _client() {
    if (!_bootstrapService.config.isConfigured ||
        !SocialSupabaseService.isInitialized) {
      throw StateError('O Social esta indisponivel agora.');
    }
    return SocialSupabaseService.client;
  }

  SocialSession _fromUser(User? user) {
    if (user == null) {
      return SocialSession.signedOut;
    }

    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName = metadata['full_name'] ?? metadata['name'];
    return SocialSession(
      isConfigured: true,
      isAuthenticated: true,
      profileId: user.id,
      displayName: displayName is String ? displayName : null,
      email: user.email,
    );
  }
}
