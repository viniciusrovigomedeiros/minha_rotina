class UserSettings {
  const UserSettings({
    required this.userName,
    required this.showMotivationalMessage,
    required this.notificationsEnabled,
    required this.activityReminderNotificationsEnabled,
    required this.bedtimeMotivationEnabled,
    required this.bedtimeMotivationMinutes,
    required this.themeKey,
    required this.motivationPhraseMode,
    required this.fixedMotivationPhrase,
    required this.updatedAt,
  });

  final String userName;
  final bool showMotivationalMessage;
  final bool notificationsEnabled;
  final bool activityReminderNotificationsEnabled;
  final bool bedtimeMotivationEnabled;
  final int bedtimeMotivationMinutes;
  final String themeKey;
  final String motivationPhraseMode;
  final String? fixedMotivationPhrase;
  final DateTime updatedAt;

  UserSettings copyWith({
    String? userName,
    bool? showMotivationalMessage,
    bool? notificationsEnabled,
    bool? activityReminderNotificationsEnabled,
    bool? bedtimeMotivationEnabled,
    int? bedtimeMotivationMinutes,
    String? themeKey,
    String? motivationPhraseMode,
    String? fixedMotivationPhrase,
    bool clearFixedMotivationPhrase = false,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userName: userName ?? this.userName,
      showMotivationalMessage:
          showMotivationalMessage ?? this.showMotivationalMessage,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      activityReminderNotificationsEnabled:
          activityReminderNotificationsEnabled ??
          this.activityReminderNotificationsEnabled,
      bedtimeMotivationEnabled:
          bedtimeMotivationEnabled ?? this.bedtimeMotivationEnabled,
      bedtimeMotivationMinutes:
          bedtimeMotivationMinutes ?? this.bedtimeMotivationMinutes,
      themeKey: themeKey ?? this.themeKey,
      motivationPhraseMode: motivationPhraseMode ?? this.motivationPhraseMode,
      fixedMotivationPhrase:
          clearFixedMotivationPhrase
              ? null
              : fixedMotivationPhrase ?? this.fixedMotivationPhrase,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'showMotivationalMessage': showMotivationalMessage,
      'notificationsEnabled': notificationsEnabled,
      'activityReminderNotificationsEnabled':
          activityReminderNotificationsEnabled,
      'bedtimeMotivationEnabled': bedtimeMotivationEnabled,
      'bedtimeMotivationMinutes': bedtimeMotivationMinutes,
      'themeKey': themeKey,
      'motivationPhraseMode': motivationPhraseMode,
      'fixedMotivationPhrase': fixedMotivationPhrase,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userName: map['userName'] as String? ?? '',
      showMotivationalMessage:
          (map['showMotivationalMessage'] as bool?) ?? true,
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
      activityReminderNotificationsEnabled:
          (map['activityReminderNotificationsEnabled'] as bool?) ?? true,
      bedtimeMotivationEnabled:
          (map['bedtimeMotivationEnabled'] as bool?) ?? false,
      bedtimeMotivationMinutes:
          (map['bedtimeMotivationMinutes'] as int?) ?? ((21 * 60) + 30),
      themeKey: map['themeKey'] as String? ?? 'blue',
      motivationPhraseMode: map['motivationPhraseMode'] as String? ?? 'daily',
      fixedMotivationPhrase: map['fixedMotivationPhrase'] as String?,
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static UserSettings initial() {
    return UserSettings(
      userName: '',
      showMotivationalMessage: true,
      notificationsEnabled: true,
      activityReminderNotificationsEnabled: true,
      bedtimeMotivationEnabled: false,
      bedtimeMotivationMinutes: (21 * 60) + 30,
      themeKey: 'blue',
      motivationPhraseMode: 'daily',
      fixedMotivationPhrase: null,
      updatedAt: DateTime.now(),
    );
  }
}
