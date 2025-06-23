// lib/services/notification_service.dart - 개선된 버전
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FCM 서버 키 (실제 앱에서는 환경변수나 보안 저장소에서 가져와야 함)
  static const String _fcmServerKey = 'YOUR_FCM_SERVER_KEY_HERE';

  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  Future<void> initialize({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_isInitialized) return;

    if (navigatorKey != null) {
      _navigatorKey = navigatorKey;
    }

    try {
      await _requestPermissions();
      await _initializeLocalNotifications();
      await _setupFCMToken();
      _setupMessageListeners();
      _isInitialized = true;
      debugPrint('NotificationService 초기화 완료');
    } catch (e) {
      debugPrint('NotificationService 초기화 실패: $e');
    }
  }

  // 권한 요청 (개선됨)
  Future<void> _requestPermissions() async {
    // iOS에서 추가 권한 요청
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: false,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        debugPrint('FCM 권한 승인됨');
        break;
      case AuthorizationStatus.provisional:
        debugPrint('FCM 임시 권한 승인됨');
        break;
      case AuthorizationStatus.denied:
        debugPrint('FCM 권한 거부됨');
        break;
      case AuthorizationStatus.notDetermined:
        debugPrint('FCM 권한 미결정');
        break;
    }
  }

  // 로컬 알림 초기화 (개선됨)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: null,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성 (중요도별로 여러 채널)
    await _createNotificationChannels();
  }

  // 알림 채널 생성
  Future<void> _createNotificationChannels() async {
    final androidPlugin =
        _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    if (androidPlugin != null) {
      // 메시지 알림 채널
      const messageChannel = AndroidNotificationChannel(
        'chat_messages',
        '채팅 메시지',
        description: '새로운 채팅 메시지 알림',
        importance: Importance.high,
        enableVibration: true,
        playSound: true,
      );

      // 시스템 알림 채널
      const systemChannel = AndroidNotificationChannel(
        'system_notifications',
        '시스템 알림',
        description: '시스템 관련 알림',
        importance: Importance.defaultImportance,
      );

      await androidPlugin.createNotificationChannel(messageChannel);
      await androidPlugin.createNotificationChannel(systemChannel);
    }
  }

  Future<void> _setupFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      debugPrint('FCM 토큰 설정 실패: $e');
    }
  }

  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM 토큰 저장 완료');
      }
    } catch (e) {
      debugPrint('FCM 토큰 저장 실패: $e');
    }
  }

  void _setupMessageListeners() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('포그라운드 메시지 수신: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // 백그라운드/종료 상태에서 알림 탭
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('백그라운드 알림 탭: ${message.messageId}');
      _handleNotificationTap(message);
    });
  }

  // 포그라운드 메시지 처리
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // 포그라운드에서는 선택적으로 알림 표시
    final shouldShowNotification = await _shouldShowForegroundNotification();

    if (shouldShowNotification) {
      await _showLocalNotification(message);
    }
  }

  // 포그라운드 알림 표시 여부 결정
  Future<bool> _shouldShowForegroundNotification() async {
    // 현재 화면이 채팅 화면인지 확인하는 로직
    // 실제 구현에서는 더 정교한 로직 필요
    return true; // 기본적으로 표시
  }

  // 알림 탭 처리
  void _handleNotificationTap(RemoteMessage message) {
    final chatRoomId = message.data['chatRoomId'] as String?;
    if (chatRoomId != null) {
      _navigateToChat(chatRoomId);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    final chatRoomId = response.payload;
    if (chatRoomId != null) {
      debugPrint('로컬 알림 탭됨 - 채팅방: $chatRoomId');
      _navigateToChat(chatRoomId);
    }
  }

  void _navigateToChat(String chatRoomId) {
    debugPrint('채팅방으로 이동: $chatRoomId');
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed(
        '/chat',
        arguments: {'chatRoomId': chatRoomId},
      );
    }
  }

  // 로컬 알림 표시 (개선됨)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      '채팅 메시지',
      channelDescription: '새로운 채팅 메시지 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      autoCancel: true,
      // 알림 스타일 개선
      styleInformation: BigTextStyleInformation(
        notification.body ?? '',
        contentTitle: notification.title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['chatRoomId'] as String?,
    );
  }

  // 백그라운드에서 수신된 메시지 처리 (정적 메서드)
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    debugPrint('백그라운드 메시지 처리: ${message.messageId}');

    // 백그라운드에서 로컬 알림 표시
    final localNotifications = FlutterLocalNotificationsPlugin();

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      '채팅 메시지',
      channelDescription: '새로운 채팅 메시지 알림',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
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

    await localNotifications.show(
      message.notification?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      message.notification?.title ?? '새 메시지',
      message.notification?.body ?? '',
      details,
      payload: message.data['chatRoomId'] as String?,
    );
  }

  // 앱 종료 상태에서 알림 탭 처리
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('앱 종료 상태에서 알림 탭: ${initialMessage.messageId}');
      final chatRoomId = initialMessage.data['chatRoomId'] as String?;
      if (chatRoomId != null) {
        // 약간의 지연 후 네비게이션 (앱이 완전히 로드될 때까지)
        Future.delayed(const Duration(milliseconds: 1000), () {
          _navigateToChat(chatRoomId);
        });
      }
    }
  }

  // FCM을 통한 메시지 전송 (직접 HTTP 요청)
  Future<void> sendMessageNotification({
    required String receiverUid,
    required String senderName,
    required String messageText,
    required String chatRoomId,
  }) async {
    try {
      // 상대방의 FCM 토큰 가져오기
      final receiverDoc =
          await _firestore.collection('users').doc(receiverUid).get();
      final receiverToken = receiverDoc.data()?['fcmToken'] as String?;

      if (receiverToken == null) {
        debugPrint('상대방의 FCM 토큰이 없습니다');
        return;
      }

      // FCM 메시지 전송
      await _sendFCMMessage(
        token: receiverToken,
        title: senderName,
        body: messageText,
        data: {
          'chatRoomId': chatRoomId,
          'senderUid': FirebaseAuth.instance.currentUser?.uid ?? '',
          'type': 'chat_message',
        },
      );

      debugPrint('FCM 메시지 전송 완료');
    } catch (e) {
      debugPrint('FCM 메시지 전송 실패: $e');
    }
  }

  // FCM HTTP API를 통한 직접 메시지 전송
  Future<void> _sendFCMMessage({
    required String token,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_fcmServerKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
            'badge': '1',
          },
          'data': data,
          'priority': 'high',
          'content_available': true,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM 메시지 전송 성공');
      } else {
        debugPrint('FCM 메시지 전송 실패: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM HTTP 요청 실패: $e');
    }
  }

  // 포그라운드 알림 처리 (public 메서드)
  Future<void> handleForegroundNotification(RemoteMessage message) async {
    await _handleForegroundMessage(message);
  }

  Future<void> removeFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'fcmToken': FieldValue.delete(),
        });
        debugPrint('FCM 토큰 제거 완료');
      }
    } catch (e) {
      debugPrint('FCM 토큰 제거 실패: $e');
    }
  }
}
