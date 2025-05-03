import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:pim/core/constants/api_constants.dart';

class FirebaseHistoriqueApi {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
        FirebaseMessaging get messaging => _firebaseMessaging;


  List<RemoteMessage> notifications = [];

  Future<String?> getFcmToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      print("📱 Retrieved FCM Token: $token");
      return token;
    } catch (e) {
      print("❌ Failed to get FCM token: $e");
      return null;
    }
  }

  Future<void> initNotifications(String historiqueId) async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final fcmToken = await getFcmToken();
    if (fcmToken != null) {
      await sendFcmTokenToBackend(historiqueId, fcmToken);
    } else {
      print("⚠️ No FCM Token available!");
    }

    await _initLocalNotifications();

    FirebaseMessaging.onMessage.listen((message) async {
      print("🔔 New Notification: ${message.notification?.title} - ${message.notification?.body}");
      print("📅 Received at: ${DateTime.now()}");

      bool isDuplicate = notifications.any((existing) =>
          existing.notification?.title == message.notification?.title &&
          existing.notification?.body == message.notification?.body);

      if (!isDuplicate) {
        notifications.add(message);
        await _showNotification(
          message.notification?.title,
          message.notification?.body,
        );
      }

      print("🔄 Notification count: ${notifications.length}");
    });
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@drawable/ms_logo');

    final iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS foreground notification if needed
      },
    );

    final initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _showNotification(String? title, String? body) async {
    const androidDetails = AndroidNotificationDetails(
      'pim-msaware',
      'PIM-MSAware',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ms_logo',
    );

    const iosDetails = DarwinNotificationDetails();

    const platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int uniqueId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _flutterLocalNotificationsPlugin.show(
      uniqueId,
      title ?? 'No Title',
      body ?? 'No Body',
      platformDetails,
      payload: 'notification_payload_$uniqueId',
    );
  }

  Future<void> sendFcmTokenToBackend(String historiqueId, String fcmToken) async {
    final url = Uri.parse(ApiConstants.updateHistoriqueFcmTokenEndpoint);

    try {
      final response = await http.put(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "historiqueId": historiqueId,
          "fcmToken": fcmToken,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ FCM token sent to backend");
      } else {
        print("❌ Backend rejected FCM token: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending FCM token to backend: $e");
    }
  }
}