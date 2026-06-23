import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/enums.dart';

/// ניהול כל ההתראות המקומיות. אין שרת, אין push מרוחק.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const int morningReminderId = 999000;
  static const String _taskChannelId = 'task_reminders';
  static const String _morningChannelId = 'morning_reminder';

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final localName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localName));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Jerusalem'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings =
        InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _taskChannelId,
          'תזכורות משימות',
          description: 'תזכורות עבור משימות בודדות',
          importance: Importance.high,
        ),
      );
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          _morningChannelId,
          'תזכורת בוקר',
          description: 'סיכום משימות יומי בבוקר',
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    bool granted = true;
    if (androidPlugin != null) {
      final notif = await androidPlugin.requestNotificationsPermission();
      granted = notif ?? true;
      await androidPlugin.requestExactAlarmsPermission();
    }
    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    if (iosPlugin != null) {
      final r = await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      granted = r ?? true;
    }
    return granted;
  }

  static void Function(String? payload)? onNotificationTap;

  static void _onTap(NotificationResponse response) {
    onNotificationTap?.call(response.payload);
  }

  NotificationDetails get _taskDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _taskChannelId,
          'תזכורות משימות',
          channelDescription: 'תזכורות עבור משימות בודדות',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  NotificationDetails get _morningDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _morningChannelId,
          'תזכורת בוקר',
          channelDescription: 'סיכום משימות יומי בבוקר',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

  Future<void> scheduleTaskReminder(Task task) async {
    if (task.notificationId == null) return;
    await cancelTaskReminder(task.notificationId!);

    // isClosed בודק status.isClosed דרך extension על TaskStatus
    if (task.status == TaskStatus.completed ||
        task.status == TaskStatus.cancelled) return;
    final when = task.reminderDateTime;
    if (when == null) return;
    if (when.isBefore(DateTime.now())) return;

    final tzTime = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      task.notificationId!,
      'תזכורת: ${task.title}',
      task.description.isNotEmpty ? task.description : 'משימה ממתינה לטיפולך',
      tzTime,
      _taskDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'task:${task.id}',
    );
  }

  Future<void> cancelTaskReminder(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> scheduleMorningReminder({
    required int minutesFromMidnight,
    required int waitingOnMeCount,
    required int activeCount,
  }) async {
    await cancelMorningReminder();

    final hour = minutesFromMidnight ~/ 60;
    final minute = minutesFromMidnight % 60;
    final scheduled = _nextInstanceOfTime(hour, minute);

    final body =
        'בוקר טוב. יש לך $waitingOnMeCount משימות שמחכות לך ו־$activeCount משימות בטיפול פעיל.';

    await _plugin.zonedSchedule(
      morningReminderId,
      'רדאר התלויות הניהולי',
      body,
      scheduled,
      _morningDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning',
    );
  }

  Future<void> cancelMorningReminder() async {
    await _plugin.cancel(morningReminderId);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> showTestNotification() async {
    await _plugin.show(
      111111,
      'בדיקת התראה',
      'אם אתה רואה את זה — ההתראות עובדות.',
      _taskDetails,
    );
  }
}
