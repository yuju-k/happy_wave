// lib/services/notification_service.dart
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

  bool _isInitialized = false;

  // 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 권한 요청
      await _requestPermissions();

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // FCM 토큰 설정
      await _setupFCMToken();

      // 메시지 리스너 설정
      _setupMessageListeners();

      _isInitialized = true;
      debugPrint('NotificationService 초기화 완료');
    } catch (e) {
      debugPrint('NotificationService 초기화 실패: $e');
    }
  }

  // 권한 요청
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM 권한 승인됨');
    } else {
      debugPrint('FCM 권한 거부됨');
    }
  }

  // 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Android 알림 채널 생성
    const androidChannel = AndroidNotificationChannel(
      'chat_messages',
      'Chat Messages',
      description: '채팅 메시지 알림',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  // FCM 토큰 설정
  Future<void> _setupFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMToken(token);
      }

      // 토큰 갱신 리스너
      _firebaseMessaging.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      debugPrint('FCM 토큰 설정 실패: $e');
    }
  }

  // FCM 토큰을 Firestore에 저장
  Future<void> _saveFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM 토큰 저장 완료: ${token.substring(0, 20)}...');
      }
    } catch (e) {
      debugPrint('FCM 토큰 저장 실패: $e');
    }
  }

  // 메시지 리스너 설정
  void _setupMessageListeners() {
    // 포그라운드 메시지
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 백그라운드 메시지 탭
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // 앱 종료 상태에서 메시지 탭 처리
    _handleTerminatedAppMessage();
  }

  // 포그라운드에서 메시지 수신 (알림 표시하지 않음)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('포그라운드 메시지 수신: ${message.messageId}');
    debugPrint('포그라운드에서는 알림을 표시하지 않습니다.');

    // 포그라운드에서는 알림을 표시하지 않음
    // 메시지는 이미 채팅 화면에서 실시간으로 표시되고 있음
  }

  // 백그라운드에서 알림 탭
  void _handleBackgroundMessageTap(RemoteMessage message) {
    debugPrint('백그라운드 알림 탭: ${message.messageId}');
    _navigateToChat(message);
  }

  // 앱 종료 상태에서 알림 탭 처리
  void _handleTerminatedAppMessage() {
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint('앱 종료 상태에서 알림 탭: ${message.messageId}');
        _navigateToChat(message);
      }
    });
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: '채팅 메시지 알림',
      importance: Importance.high,
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

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['chatRoomId'],
    );
  }

  // 알림 탭 처리
  void _onNotificationTapped(NotificationResponse response) {
    final chatRoomId = response.payload;
    if (chatRoomId != null) {
      debugPrint('알림 탭됨 - 채팅방: $chatRoomId');
      // TODO: 채팅 페이지로 이동하는 로직 구현
    }
  }

  // 채팅으로 이동
  void _navigateToChat(RemoteMessage message) {
    // TODO: Navigator를 사용해 채팅 페이지로 이동
    final chatRoomId = message.data['chatRoomId'];
    debugPrint('채팅방으로 이동: $chatRoomId');
  }

  // 상대방에게 메시지 알림 전송
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

      // Cloud Functions을 통해 알림 전송 요청
      await _firestore.collection('notifications').add({
        'to': receiverToken,
        'notification': {'title': senderName, 'body': messageText},
        'data': {
          'chatRoomId': chatRoomId,
          'senderUid': FirebaseAuth.instance.currentUser?.uid,
          'type': 'chat_message',
        },
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('알림 전송 요청 완료');
    } catch (e) {
      debugPrint('알림 전송 실패: $e');
    }
  }

  // 토큰 제거 (로그아웃 시)
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

// 백그라운드 메시지 핸들러 (main.dart 외부에서 정의)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('백그라운드 메시지 수신: ${message.messageId}');
}
