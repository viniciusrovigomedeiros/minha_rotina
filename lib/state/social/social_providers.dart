import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/social/social_bootstrap_status.dart';
import '../../data/models/social/social_challenge.dart';
import '../../data/models/social/social_session.dart';
import '../../data/repositories/social/social_auth_repository.dart';
import '../../data/repositories/social/social_challenge_repository.dart';
import '../../data/services/social/social_backend_bootstrap_service.dart';

final socialBackendBootstrapServiceProvider =
    Provider<SocialBackendBootstrapService>((ref) {
      return SocialBackendBootstrapService();
    });

final socialAuthRepositoryProvider = Provider<SocialAuthRepository>((ref) {
  return SocialAuthRepository(
    bootstrapService: ref.read(socialBackendBootstrapServiceProvider),
  );
});

final socialChallengeRepositoryProvider = Provider<SocialChallengeRepository>((
  ref,
) {
  return SocialChallengeRepository(
    bootstrapService: ref.read(socialBackendBootstrapServiceProvider),
  );
});

final socialSessionControllerProvider =
    AsyncNotifierProvider<SocialSessionController, SocialSession>(
      SocialSessionController.new,
    );

class SocialSessionController extends AsyncNotifier<SocialSession> {
  @override
  Future<SocialSession> build() async {
    final repository = ref.read(socialAuthRepositoryProvider);
    final subscription = repository.sessionChanges.listen((session) {
      state = AsyncData(session);
    });
    ref.onDispose(subscription.cancel);
    return repository.getCurrentSession();
  }

  Future<void> signIn(SocialAuthProvider provider) async {
    await ref.read(socialAuthRepositoryProvider).signIn(provider);
  }

  Future<void> signOut() async {
    await ref.read(socialAuthRepositoryProvider).signOut();
    state = const AsyncData(SocialSession.signedOut);
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
  }) {
    return ref
        .read(socialAuthRepositoryProvider)
        .signUp(name: name, email: email, password: password);
  }

  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) {
    return ref
        .read(socialAuthRepositoryProvider)
        .signInWithPassword(email: email, password: password);
  }

  Future<void> uploadAvatar(String filePath) {
    return ref.read(socialAuthRepositoryProvider).uploadAvatar(filePath);
  }
}

final socialChallengeActionProvider =
    AsyncNotifierProvider<SocialChallengeActionController, void>(
      SocialChallengeActionController.new,
    );

class SocialChallengeActionController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(SocialChallengeDraft draft) async {
    state = const AsyncLoading();
    try {
      await ref.read(socialChallengeRepositoryProvider).createChallenge(draft);
      ref.invalidate(socialHighlightsProvider);
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      final code = error is PostgrestException ? error.code : null;
      developer.log(
        'Challenge creation failed: ${error.runtimeType}, code: $code',
        name: 'social.createChallenge',
        stackTrace: stackTrace,
      );
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<String> createInvite(String challengeId) {
    return ref
        .read(socialChallengeRepositoryProvider)
        .createInvite(challengeId);
  }

  Future<void> acceptInvite(String token) async {
    await ref.read(socialChallengeRepositoryProvider).acceptInvite(token);
    ref.invalidate(socialHighlightsProvider);
  }

  Future<void> createWeeklyCheckIn(SocialWeeklyCheckInDraft draft) {
    return ref
        .read(socialChallengeRepositoryProvider)
        .createWeeklyCheckIn(draft);
  }
}

final socialBootstrapStatusProvider = FutureProvider<SocialBootstrapStatus>((
  ref,
) async {
  final session = ref.watch(socialSessionControllerProvider).valueOrNull;
  return ref
      .read(socialBackendBootstrapServiceProvider)
      .inspect(hasSession: session?.isAuthenticated ?? false);
});

final socialHighlightsProvider = FutureProvider<List<SocialChallengeSummary>>((
  ref,
) async {
  final session = ref.watch(socialSessionControllerProvider).valueOrNull;
  if (session?.isAuthenticated != true) {
    return const [];
  }
  return ref.read(socialChallengeRepositoryProvider).getHighlights();
});

final socialTimelineProvider =
    FutureProvider.family<List<SocialTimelineEntry>, String>(
      (ref, challengeId) =>
          ref.read(socialChallengeRepositoryProvider).getTimeline(challengeId),
    );

final socialLeaderboardProvider =
    FutureProvider.family<List<SocialLeaderboardEntry>, String>(
      (ref, challengeId) => ref
          .read(socialChallengeRepositoryProvider)
          .getLeaderboard(challengeId),
    );
