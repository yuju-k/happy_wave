// lib/services/app_state_service.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AppStateService with WidgetsBindingObserver {
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isInitialized = false;
  AppLifecycleState? _currentState;

  // 앱 상태 변화 감지 시작
  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _isInitialized = true;
    _currentState = WidgetsBinding.instance.lifecycleState;
    debugPrint('AppStateService 초기화 완료');
  }

  // 앱 상태 변화 감지 종료
  void dispose() {
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
      _isInitialized = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    debugPrint('앱 상태 변화: ${_currentState?.name} -> ${state.name}');
    _currentState = state;

    // Firestore에 앱 상태 업데이트
    _updateAppStateInFirestore(state);
  }

  // Firestore에 앱 상태 저장
  Future<void> _updateAppStateInFirestore(AppLifecycleState state) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final isAppActive = state == AppLifecycleState.resumed;

      await _firestore.collection('users').doc(user.uid).set({
        'isAppActive': isAppActive,
        'lastStateUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('앱 상태 업데이트: isAppActive = $isAppActive');
    } catch (e) {
      debugPrint('앱 상태 업데이트 실패: $e');
    }
  }

  // 현재 앱이 포그라운드에 있는지 확인
  bool get isAppInForeground {
    return _currentState == AppLifecycleState.resumed;
  }

  // 특정 사용자가 앱을 사용 중인지 확인
  Future<bool> isUserAppActive(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final data = userDoc.data();
      return data?['isAppActive'] == true;
    } catch (e) {
      debugPrint('사용자 앱 상태 확인 실패: $e');
      return false;
    }
  }

  // 로그아웃 시 앱 상태 정리
  Future<void> clearAppState() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'isAppActive': false,
          'lastStateUpdate': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('앱 상태 정리 실패: $e');
    }
  }
}
