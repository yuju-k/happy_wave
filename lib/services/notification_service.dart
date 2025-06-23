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
  GlobalKey<NavigatorState>? _navigatorKey; // Navigator Key 추가

  // 초기화 메서드에 navigatorKey 인자 추가
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
    FirebaseMessaging.onMessage.listen((message) {
      handleForegroundNotification(message); // public 메서드를 호출하도록 변경
    });

    // 백그라운드 메시지 탭 (RemoteMessage에서 chatRoomId 추출하여 전달)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      //
      debugPrint('백그라운드 알림 탭: ${message.messageId}');
      final chatRoomId = message.data['chatRoomId'] as String?; //
      if (chatRoomId != null) {
        //
        _navigateToChat(chatRoomId); //
      }
    });
  }

  // 앱 종료 상태에서 알림 탭 처리 (별도의 public 메서드로 분리)
  Future<void> setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      final chatRoomId = initialMessage.data['chatRoomId'] as String?;
      if (chatRoomId != null) {
        _navigateToChat(chatRoomId);
      }
    }
  }

  // 포그라운드에서 메시지 수신 시 로컬 알림 표시 (Public 메서드)
  Future<void> handleForegroundNotification(RemoteMessage message) async {
    debugPrint('포그라운드 메시지 수신: ${message.messageId}');
    // 포그라운드에서도 로컬 알림을 띄우고 싶을 때만 이 함수를 호출
    await _showLocalNotification(message);
  }

  // 알림 탭 처리 (payload에서 chatRoomId 직접 받음)
  void _onNotificationTapped(NotificationResponse response) {
    final chatRoomId = response.payload;
    if (chatRoomId != null) {
      debugPrint('알림 탭됨 - 채팅방: $chatRoomId');
      _navigateToChat(chatRoomId); // chatRoomId를 직접 전달
    }
  }

  // 채팅으로 이동 (chatRoomId만 받도록 수정)
  void _navigateToChat(String chatRoomId) {
    debugPrint('채팅방으로 이동: $chatRoomId');
    if (_navigatorKey?.currentState != null) {
      _navigatorKey!.currentState!.pushNamed(
        '/chat',
        arguments: {'chatRoomId': chatRoomId},
      );
    } else {
      debugPrint('NavigatorState가 아직 준비되지 않았습니다.');
      // 대안: 앱이 완전히 종료된 상태에서 알림을 탭했을 경우,
      // getInitialMessage에서 처리되므로 여기서는 특별한 조치 없이 로그만 남겨도 됨.
    }
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

    // payload에 chatRoomId를 저장하여 알림 탭 시 사용
    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['chatRoomId'] as String?, // payload는 String만 가능
    );
  }

  // 백그라운드에서 수신된 메시지를 처리하고 로컬 알림을 띄움 (main.dart에서 호출)
  static Future<void> showBackgroundNotification(RemoteMessage message) async {
    final NotificationService notificationService = NotificationService();
    // 초기화가 안 되어 있을 경우를 대비 (새로운 VM 인스턴스에서 실행될 수 있음)
    if (!notificationService._isInitialized) {
      await notificationService.initialize();
    }
    await notificationService._showLocalNotification(message);
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

      // Cloud Functions을 통해 알림 전송 요청 (서버에서 직접 FCM API 호출)
      // 클라이언트에서 직접 FCM 메시지를 보내는 것은 보안상 권장되지 않습니다.
      // Firestore에 알림 요청 문서를 추가하고, Cloud Function이 이를 트리거하여 FCM으로 메시지를 보내는 방식이 안전합니다.
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
