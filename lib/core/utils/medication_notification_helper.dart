import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:pim/data/model/medication_models.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_init;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

class MedicationNotificationHelper {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String MEDICATION_CHANNEL_ID = 'medication_alarm_channel';
  static const String MEDICATION_CHANNEL_NAME = 'Rappels de médicaments';
  static const String MEDICATION_CHANNEL_DESC =
      'Notifications sonores pour les rappels de médicaments';

  static Future<void> initialize() async {
    tz_init.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onNotificationTap,
    );

    if (Platform.isAndroid) {
      final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidPlugin?.requestNotificationsPermission();
      print("Android notification permissions granted: $granted");
    }

    await createNotificationChannel();
    await requestPermissions();
  }

  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      MEDICATION_CHANNEL_ID,
      MEDICATION_CHANNEL_NAME,
      description: MEDICATION_CHANNEL_DESC,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarme'),
      enableVibration: true,
      enableLights: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    print("Notification channel created with sound: alarme");
  }

  static Future<void> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final iosPlugin = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final result = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      print("iOS/macOS notification permissions granted: $result");
    }
  }

  static void onNotificationTap(NotificationResponse response) {
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> showMedicationNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      MEDICATION_CHANNEL_ID,
      MEDICATION_CHANNEL_NAME,
      channelDescription: MEDICATION_CHANNEL_DESC,
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarme'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: 'medication_$id',
    );

    print("Immediate notification shown: $title");
  }

  static Future<void> scheduleMedicationNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      MEDICATION_CHANNEL_ID,
      MEDICATION_CHANNEL_NAME,
      channelDescription: MEDICATION_CHANNEL_DESC,
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('alarme'),
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      additionalFlags: Int32List.fromList(<int>[4]),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'medication_$id',
      uiLocalNotificationDateInterpretation: 
          tz.TZDateTime.now(tz.local).isBefore(tzScheduledTime)
              ? UILocalNotificationDateInterpretation.absoluteTime
              : UILocalNotificationDateInterpretation.wallClockTime,
    );

    print("Notification scheduled: $title at $scheduledTime");
  }

  static Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
    print("Cancelled notification ID: $id");
  }

  static Future<void> cancelAllNotifications() async {
    await flutterLocalNotificationsPlugin.cancelAll();
    print("All notifications cancelled.");
  }

  static Future<void> scheduleAllReminders(List<MedicationReminder> reminders) async {
    print("Scheduling ${reminders.length} reminders...");

    for (final reminder in reminders) {
      if (!reminder.isCompleted && !reminder.isSkipped) {
        final localDate = reminder.scheduledDate.toLocal();
        final timeString = _extractTimeString(reminder.scheduledTime);
        final parts = timeString.split(':');

        if (parts.length != 2) {
          print("Invalid time format: $timeString");
          continue;
        }

        final hour = int.tryParse(parts[0]) ?? 0;
        final minute = int.tryParse(parts[1]) ?? 0;

        final scheduledDateTime = DateTime(
          localDate.year,
          localDate.month,
          localDate.day,
          hour,
          minute,
        );

        if (scheduledDateTime.isAfter(DateTime.now())) {
          await scheduleMedicationNotification(
            id: reminder.id.hashCode,
            title: "Rappel de médicament",
            body: "Il est temps de prendre votre ${reminder.medication.name}",
            scheduledTime: scheduledDateTime,
          );
        } else if (_isToday(scheduledDateTime)) {
          await showMedicationNotification(
            id: reminder.id.hashCode,
            title: "Rappel de médicament en retard",
            body: "Rappel: vous deviez prendre ${reminder.medication.name} à ${reminder.scheduledTime}",
          );
        }
      }
    }
  }

  static bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year && now.month == date.month && now.day == date.day;
  }

  static String _extractTimeString(dynamic rawTime) {
    if (rawTime is String) {
      final trimmed = rawTime.trim().replaceAll('"', '').replaceAll("'", '');
      if (trimmed.startsWith('[')) {
        try {
          final times = jsonDecode(trimmed);
          if (times.isNotEmpty) return times.first.toString();
        } catch (_) {
          return "00:00";
        }
      }
      return trimmed;
    }

    if (rawTime is List && rawTime.isNotEmpty) {
      return rawTime.first.toString();
    }

    return "00:00";
  }
}