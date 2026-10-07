enum SocialChallengeType {
  cycleDuel,
  weeklyShort,
  sharedMission,
  sharedObjective,
  consistencyLeague,
}

extension SocialChallengeTypeValues on SocialChallengeType {
  String get databaseValue => switch (this) {
    SocialChallengeType.cycleDuel => 'cycle_duel',
    SocialChallengeType.weeklyShort => 'weekly_short',
    SocialChallengeType.sharedMission => 'shared_mission',
    SocialChallengeType.sharedObjective => 'shared_objective',
    SocialChallengeType.consistencyLeague => 'consistency_league',
  };

  String get scoringType => switch (this) {
    SocialChallengeType.cycleDuel => 'percentage_progress',
    SocialChallengeType.weeklyShort => 'completion_count',
    SocialChallengeType.sharedMission => 'completion_count',
    SocialChallengeType.sharedObjective => 'shared_okr_progress',
    SocialChallengeType.consistencyLeague => 'consistency_score',
  };

  int get defaultDurationDays => switch (this) {
    SocialChallengeType.weeklyShort => 7,
    SocialChallengeType.cycleDuel => 90,
    SocialChallengeType.sharedMission => 30,
    SocialChallengeType.sharedObjective => 90,
    SocialChallengeType.consistencyLeague => 30,
  };

  String get label => switch (this) {
    SocialChallengeType.cycleDuel => 'Desafio 1:1 por ciclo',
    SocialChallengeType.weeklyShort => 'Desafio semanal curto',
    SocialChallengeType.sharedMission => 'Missao em comum',
    SocialChallengeType.sharedObjective => 'Objetivo compartilhado',
    SocialChallengeType.consistencyLeague => 'Liga de consistencia',
  };

  static SocialChallengeType fromDatabaseValue(String value) {
    return switch (value) {
      'cycle_duel' => SocialChallengeType.cycleDuel,
      'weekly_short' => SocialChallengeType.weeklyShort,
      'shared_mission' => SocialChallengeType.sharedMission,
      'shared_objective' => SocialChallengeType.sharedObjective,
      'consistency_league' => SocialChallengeType.consistencyLeague,
      _ => SocialChallengeType.weeklyShort,
    };
  }
}

class SocialChallengeDraft {
  const SocialChallengeDraft({
    required this.title,
    required this.type,
    this.description,
  });

  final String title;
  final SocialChallengeType type;
  final String? description;
}

class SocialWeeklyCheckInDraft {
  const SocialWeeklyCheckInDraft({
    required this.challengeId,
    required this.advanceNote,
    this.blockerNote,
    this.nextFocusNote,
  });

  final String challengeId;
  final String advanceNote;
  final String? blockerNote;
  final String? nextFocusNote;
}

class SocialTimelineEntry {
  const SocialTimelineEntry({
    required this.author,
    required this.advanceNote,
    required this.createdAt,
  });

  final String author;
  final String advanceNote;
  final DateTime createdAt;
}

class SocialLeaderboardEntry {
  const SocialLeaderboardEntry({
    required this.name,
    required this.score,
    required this.streak,
  });

  final String name;
  final num score;
  final int streak;
}

class SocialChallengeSummary {
  const SocialChallengeSummary({
    required this.id,
    required this.title,
    required this.type,
    required this.memberCount,
    required this.statusLabel,
    required this.progressLabel,
  });

  final String id;
  final String title;
  final SocialChallengeType type;
  final int memberCount;
  final String statusLabel;
  final String progressLabel;

  factory SocialChallengeSummary.fromDatabase(Map<String, dynamic> row) {
    final rawMembers = row['challenge_members'];
    final memberCount = rawMembers is List ? rawMembers.length : 1;
    final endAt = DateTime.tryParse(row['end_at'] as String? ?? '');
    final remainingDays = endAt
        ?.difference(DateTime.now())
        .inDays
        .clamp(0, 999);

    return SocialChallengeSummary(
      id: row['id'] as String,
      title: row['title'] as String,
      type: SocialChallengeTypeValues.fromDatabaseValue(
        row['challenge_type'] as String,
      ),
      memberCount: memberCount,
      statusLabel: _statusLabel(row['status'] as String? ?? 'draft'),
      progressLabel:
          remainingDays == null
              ? 'Sem prazo'
              : remainingDays == 0
              ? 'Termina hoje'
              : '$remainingDays dias',
    );
  }

  static String _statusLabel(String value) {
    return switch (value) {
      'active' => 'Em andamento',
      'draft' => 'Rascunho',
      'completed' => 'Concluido',
      'cancelled' => 'Cancelado',
      _ => value,
    };
  }
}
