import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SystemLogService {
  // Firestore 인스턴스
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 로그인 로그 기록
  Future<void> logLogin(String uid) async {
    try {
      // system_log/{uid} 도큐먼트에 lastLogin 필드 업데이트
      await _firestore.collection('system_log').doc(uid).set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // 에러 로깅 (필요 시 콘솔 또는 다른 로깅 시스템 사용)
      debugPrint('로그인 로그 기록 실패: $e');
    }
  }
}
