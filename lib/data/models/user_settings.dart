class UserSettings {
  const UserSettings({
    required this.userName,
    required this.notificationsEnabled,
    required this.activityReminderNotificationsEnabled,
    required this.goalReminderNotificationsEnabled,
    required this.dailyClosureReminderEnabled,
    required this.goalReminderMinutes,
    required this.dailyClosureReminderMinutes,
    required this.themeKey,
    required this.updatedAt,
  });

  final String userName;
  final bool notificationsEnabled;
  final bool activityReminderNotificationsEnabled;
  final bool goalReminderNotificationsEnabled;
  final bool dailyClosureReminderEnabled;
  final int goalReminderMinutes;
  final int dailyClosureReminderMinutes;
  final String themeKey;
  final DateTime updatedAt;

  UserSettings copyWith({
    String? userName,
    bool? notificationsEnabled,
    bool? activityReminderNotificationsEnabled,
    bool? goalReminderNotificationsEnabled,
    bool? dailyClosureReminderEnabled,
    int? goalReminderMinutes,
    int? dailyClosureReminderMinutes,
    String? themeKey,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userName: userName ?? this.userName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      activityReminderNotificationsEnabled:
          activityReminderNotificationsEnabled ??
          this.activityReminderNotificationsEnabled,
      goalReminderNotificationsEnabled:
          goalReminderNotificationsEnabled ??
          this.goalReminderNotificationsEnabled,
      dailyClosureReminderEnabled:
          dailyClosureReminderEnabled ?? this.dailyClosureReminderEnabled,
      goalReminderMinutes: goalReminderMinutes ?? this.goalReminderMinutes,
      dailyClosureReminderMinutes:
          dailyClosureReminderMinutes ?? this.dailyClosureReminderMinutes,
      themeKey: themeKey ?? this.themeKey,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'notificationsEnabled': notificationsEnabled,
      'activityReminderNotificationsEnabled':
          activityReminderNotificationsEnabled,
      'goalReminderNotificationsEnabled': goalReminderNotificationsEnabled,
      'dailyClosureReminderEnabled': dailyClosureReminderEnabled,
      'goalReminderMinutes': goalReminderMinutes,
      'dailyClosureReminderMinutes': dailyClosureReminderMinutes,
      'themeKey': themeKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      userName: map['userName'] as String? ?? '',
      notificationsEnabled: (map['notificationsEnabled'] as bool?) ?? true,
      activityReminderNotificationsEnabled:
          (map['activityReminderNotificationsEnabled'] as bool?) ?? true,
      goalReminderNotificationsEnabled:
          (map['goalReminderNotificationsEnabled'] as bool?) ?? false,
      dailyClosureReminderEnabled:
          (map['dailyClosureReminderEnabled'] as bool?) ?? true,
      goalReminderMinutes:
          (map['goalReminderMinutes'] as int?) ?? ((19 * 60) + 30),
      dailyClosureReminderMinutes:
          (map['dailyClosureReminderMinutes'] as int?) ?? ((21 * 60) + 45),
      themeKey: map['themeKey'] as String? ?? 'blue',
      updatedAt: DateTime.parse(
        map['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  static UserSettings initial() {
    return UserSettings(
      userName: '',
      notificationsEnabled: true,
      activityReminderNotificationsEnabled: true,
      goalReminderNotificationsEnabled: false,
      dailyClosureReminderEnabled: true,
      goalReminderMinutes: (19 * 60) + 30,
      dailyClosureReminderMinutes: (21 * 60) + 45,
      themeKey: 'blue',
      updatedAt: DateTime.now(),
    );
  }
}
