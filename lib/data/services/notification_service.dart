import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/motivation_utils.dart';
import '../models/activity.dart';
import '../models/user_settings.dart';

class NotificationService {
  factory NotificationService() => _instance;

  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> syncNotifications({
    required List<Activity> activities,
    required UserSettings settings,
    required List<String> motivationPhrases,
  }) async {
    if (!_initialized) return;

    await _plugin.cancelAll();
    if (!settings.notificationsEnabled) return;

    if (settings.activityReminderNotificationsEnabled) {
      for (final activity in activities) {
        if (!activity.isActive ||
            !activity.remindersEnabled ||
            activity.startMinutes == null) {
          continue;
        }

        for (final weekday in activity.weekdays) {
          final when = _nextDateForWeekday(
            weekday: weekday,
            startMinutes: activity.startMinutes!,
          );

          final id = _notificationId(activity.id, weekday);

          await _plugin.zonedSchedule(
            id,
            'Minha Rotina',
            'Hora de: ${activity.name}',
            when,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'minha_rotina_daily',
                'Atividades diárias',
                channelDescription: 'Lembretes de atividades da rotina',
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }

    if (settings.bedtimeMotivationEnabled) {
      final bedtimePhrase = _buildBedtimePhrase(
        phrases: motivationPhrases,
        settings: settings,
      );
      final schedule = _nextDailyDate(settings.bedtimeMotivationMinutes);

      await _plugin.zonedSchedule(
        900000001,
        'Preparação para amanhã',
        bedtimePhrase,
        schedule,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'minha_rotina_motivation',
            'Motivação noturna',
            channelDescription: 'Lembrete motivacional para o próximo dia',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  tz.TZDateTime _nextDateForWeekday({
    required int weekday,
    required int startMinutes,
  }) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = startMinutes ~/ 60;
    final minute = startMinutes % 60;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  int _notificationId(String activityId, int weekday) {
    final raw = '$activityId-$weekday'.hashCode;
    return raw.abs() % 2147483646;
  }

  tz.TZDateTime _nextDailyDate(int minutes) {
    final now = tz.TZDateTime.now(tz.local);
    final hour = minutes ~/ 60;
    final minute = minutes % 60;

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  String _buildBedtimePhrase({
    required List<String> phrases,
    required UserSettings settings,
  }) {
    final source =
        phrases.isNotEmpty ? phrases : MotivationUtils.defaultPhrases;
    final fixedPhrase = settings.fixedMotivationPhrase;
    final useFixed =
        settings.motivationPhraseMode == 'fixed' &&
        fixedPhrase != null &&
        source.contains(fixedPhrase);
    final phrase =
        useFixed
            ? fixedPhrase
            : MotivationUtils.phraseForDay(
              DateTime.now().add(const Duration(days: 1)),
              phrases: source,
            );
    return 'Amanhã: $phrase';
  }
}
