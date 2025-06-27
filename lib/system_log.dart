// lib/system_log.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SystemLogService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 로그인 로그 기록
  Future<void> logLogin(String uid) async {
    try {
      // system_log/{uid} 도큐먼트에 lastLogin 필드 업데이트
      await _firestore.collection('system_log').doc(uid).set({
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('로그인 로그 기록 실패: $e');
    }
  }

  /// 지정된 사용자의 감정 유형 카운트를 증가시킵니다.
  Future<void> logSentiment(String uid, String sentimentType) async {
    try {
      final docRef = _firestore
          .collection('system_log')
          .doc(uid)
          .collection('sentiment_logs')
          .doc('sentimentCounts');

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        int currentCount = 0;
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data.containsKey(sentimentType)) {
            currentCount = data[sentimentType] as int;
          }
        }

        // 카운트 1 증가
        currentCount++;

        // 문서에 업데이트 (merge: true로 기존 필드 보존)
        transaction.set(docRef, {
          sentimentType: currentCount,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
      debugPrint(
        'User \$uid Sentiment log updated: $sentimentType count increased.',
      );
    } catch (e) {
      debugPrint('Error logging sentiment for user \$uid: $e');
    }
  }

  /// 지정된 사용자의 모든 감정 유형의 현재 카운트를 가져옵니다.
  Future<Map<String, dynamic>?> getSentimentCounts(String uid) async {
    try {
      final docSnapshot =
          await _firestore
              .collection('system_log')
              .doc(uid)
              .collection('sentiment_logs')
              .doc('sentimentCounts')
              .get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching sentiment counts for user \$uid: $e');
      return null;
    }
  }

  // 메시지 전송 count
  Future<void> logMessageSent(String uid) async {
    try {
      final docRef = _firestore.collection('system_log').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        int currentCount = 0;
        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null && data.containsKey('messageCount')) {
            currentCount = data['messageCount'] as int;
          }
        }

        // 카운트 1 증가
        currentCount++;

        // 문서에 업데이트 (merge: true로 기존 필드 보존)
        transaction.set(docRef, {
          'messageCount': currentCount,
        }, SetOptions(merge: true));
      });
      debugPrint('User $uid message count increased.');
    } catch (e) {
      debugPrint('Error logging message sent for user $uid: $e');
    }
  }
}
