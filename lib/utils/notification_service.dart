import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Timers for web platform fallback
  final Map<int, Timer> _webTimers = {};

  // Callback for showing in-app dialog when notification triggers in foreground
  void Function(int goalId, String goalTitle)? onForegroundNotification;

  Future<void> initialize() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can be extended for navigation
    final goalId = response.id;
    if (goalId != null && onForegroundNotification != null) {
      onForegroundNotification!(goalId, '');
    }
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
  }

  Future<void> scheduleGoalReminder(
      int goalId, String goalTitle, DateTime endTime) async {
    if (kIsWeb) {
      _scheduleWebReminder(goalId, goalTitle, endTime);
      return;
    }

    final now = DateTime.now();
    if (endTime.isBefore(now)) {
      // Already overdue, trigger immediately
      _triggerImmediateNotification(goalId, goalTitle);
      return;
    }

    final scheduledDate = tz.TZDateTime.from(endTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'goal_reminder',
      '目标提醒',
      channelDescription: '目标超时提醒',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      goalId,
      '目标提醒 ⏰',
      '还有目标没完成，你睡得着觉吗？坚持就是胜利！兄弟姐妹们！\n📋 $goalTitle',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  Future<void> _triggerImmediateNotification(
      int goalId, String goalTitle) async {
    // Trigger foreground callback if available
    if (onForegroundNotification != null) {
      onForegroundNotification!(goalId, goalTitle);
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'goal_reminder',
      '目标提醒',
      channelDescription: '目标超时提醒',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      goalId,
      '目标提醒 ⏰',
      '还有目标没完成，你睡得着觉吗？坚持就是胜利！兄弟姐妹们！\n📋 $goalTitle',
      details,
    );
  }

  void _scheduleWebReminder(int goalId, String goalTitle, DateTime endTime) {
    // Cancel existing timer for this goal
    _webTimers[goalId]?.cancel();

    final now = DateTime.now();
    final duration = endTime.difference(now);

    if (duration.isNegative) {
      // Already overdue
      if (onForegroundNotification != null) {
        onForegroundNotification!(goalId, goalTitle);
      }
      return;
    }

    _webTimers[goalId] = Timer(duration, () {
      if (onForegroundNotification != null) {
        onForegroundNotification!(goalId, goalTitle);
      }
    });
  }

  Future<void> cancelGoalReminder(int goalId) async {
    if (kIsWeb) {
      _webTimers[goalId]?.cancel();
      _webTimers.remove(goalId);
      return;
    }
    await _notifications.cancel(goalId);
  }

  Future<void> cancelAllReminders() async {
    if (kIsWeb) {
      for (final timer in _webTimers.values) {
        timer.cancel();
      }
      _webTimers.clear();
      return;
    }
    await _notifications.cancelAll();
  }
}
