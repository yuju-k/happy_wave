import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    var initializationSettingsAndroid = AndroidInitializationSettings('app_icon');

    var initializationSettingsDarwin = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }
    if (Platform.isIOS) {
      await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  Future<void> _showNotification() async {
    var androidDetails = AndroidNotificationDetails(
      'happy_wave',
      'happy_wave',
      importance: Importance.max,
      priority: Priority.high,
      icon: 'app_icon',
    );

    var iosDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

    var notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _flutterLocalNotificationsPlugin.show(
      0, // 알림 ID
      'HappyWave', // 제목
      '메시지가 도착했습니다.', // 내용
      notificationDetails,
    );
  }

  Future<void> settingHandler() async {
    FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification();
    });

    FirebaseMessaging.onBackgroundMessage((message) async {
      _showNotification();
    });
  }
}
