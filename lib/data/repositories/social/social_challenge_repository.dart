import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/social/social_challenge.dart';
import '../../services/social/social_backend_bootstrap_service.dart';
import '../../services/social/social_supabase_service.dart';

class SocialChallengeRepository {
  SocialChallengeRepository({
    required SocialBackendBootstrapService bootstrapService,
  }) : _bootstrapService = bootstrapService;

  final SocialBackendBootstrapService _bootstrapService;

  Future<List<SocialChallengeSummary>> getHighlights() async {
    if (!_bootstrapService.config.isConfigured ||
        !SocialSupabaseService.isInitialized ||
        SocialSupabaseService.client.auth.currentUser == null) {
      return const [];
    }

    final response = await SocialSupabaseService.client
        .from('challenges')
        .select(
          'id, title, challenge_type, status, end_at, challenge_members(id)',
        )
        .order('end_at', ascending: true)
        .limit(6);

    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(SocialChallengeSummary.fromDatabase)
        .toList(growable: false);
  }

  Future<void> createChallenge(SocialChallengeDraft draft) async {
    await _authenticatedClient().rpc(
      'create_social_challenge',
      params: {
        'p_title': draft.title.trim(),
        'p_challenge_type': draft.type.databaseValue,
        'p_description': draft.description?.trim(),
      },
    );
  }

  Future<String> createInvite(String challengeId) async {
    final token = await _authenticatedClient().rpc(
      'create_challenge_invite',
      params: {'p_challenge_id': challengeId},
    );
    return token as String;
  }

  Future<void> acceptInvite(String token) async {
    await _authenticatedClient().rpc(
      'accept_challenge_invite',
      params: {'p_token': token},
    );
  }

  Future<void> createWeeklyCheckIn(SocialWeeklyCheckInDraft draft) async {
    final client = _authenticatedClient();
    final profileId = await _currentProfileId(
      client,
      client.auth.currentUser!.id,
    );
    await client.from('social_check_ins').insert({
      'challenge_id': draft.challengeId,
      'profile_id': profileId,
      'check_in_type': 'weekly_reflection',
      'advance_note': draft.advanceNote.trim(),
      'blocker_note': draft.blockerNote?.trim(),
      'next_focus_note': draft.nextFocusNote?.trim(),
    });
  }

  Future<List<SocialTimelineEntry>> getTimeline(String challengeId) async {
    final response = await _authenticatedClient()
        .from('social_check_ins')
        .select('advance_note, created_at, profiles!inner(display_name)')
        .eq('challenge_id', challengeId)
        .order('created_at', ascending: false)
        .limit(30);
    return (response as List<dynamic>)
        .map((item) {
          final row = item as Map<String, dynamic>;
          final profile = row['profiles'] as Map<String, dynamic>;
          return SocialTimelineEntry(
            author: profile['display_name'] as String? ?? 'Participante',
            advanceNote: row['advance_note'] as String? ?? '',
            createdAt: DateTime.parse(row['created_at'] as String).toLocal(),
          );
        })
        .toList(growable: false);
  }

  Future<List<SocialLeaderboardEntry>> getLeaderboard(
    String challengeId,
  ) async {
    final response = await _authenticatedClient()
        .from('challenge_scores')
        .select('score_total, current_streak, profiles!inner(display_name)')
        .eq('challenge_id', challengeId)
        .order('score_total', ascending: false);
    return (response as List<dynamic>)
        .map((item) {
          final row = item as Map<String, dynamic>;
          final profile = row['profiles'] as Map<String, dynamic>;
          return SocialLeaderboardEntry(
            name: profile['display_name'] as String? ?? 'Participante',
            score: row['score_total'] as num? ?? 0,
            streak: row['current_streak'] as int? ?? 0,
          );
        })
        .toList(growable: false);
  }

  SupabaseClient _authenticatedClient() {
    if (!_bootstrapService.config.isConfigured ||
        !SocialSupabaseService.isInitialized ||
        SocialSupabaseService.client.auth.currentUser == null) {
      throw StateError('Entre na sua conta para continuar.');
    }
    return SocialSupabaseService.client;
  }

  Future<String> _currentProfileId(SupabaseClient client, String userId) async {
    final profile =
        await client
            .from('profiles')
            .select('id')
            .eq('auth_user_id', userId)
            .single();
    return profile['id'] as String;
  }
}
