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
      // system_log/{uid} 문서에 직접 저장하도록 변경
      final docRef = _firestore.collection('system_log').doc(uid);

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
          'lastSentimentUpdateAt':
              FieldValue.serverTimestamp(), // 필드명 변경: lastUpdated -> lastSentimentUpdateAt
        }, SetOptions(merge: true));
      });
      debugPrint(
        'User $uid Sentiment log updated: $sentimentType count increased.',
      );
    } catch (e) {
      debugPrint('Error logging sentiment for user $uid: $e');
    }
  }

  /// 지정된 사용자의 모든 감정 유형의 현재 카운트를 가져옵니다.
  Future<Map<String, dynamic>?> getSentimentCounts(String uid) async {
    try {
      // system_log/{uid} 문서에서 직접 가져오도록 변경
      final docSnapshot =
          await _firestore.collection('system_log').doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching sentiment counts for user $uid: $e');
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

  Future<void> logMessageConversionStatus(String uid, bool converted) async {
    try {
      final docRef = _firestore.collection('system_log').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        int convertedCount = 0;

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            convertedCount = data['convertedMessageCount'] as int? ?? 0;
          }
        }

        if (converted) {
          convertedCount++;
        }

        transaction.set(docRef, {
          'convertedMessageCount': convertedCount,
        }, SetOptions(merge: true));
      });
      debugPrint(
        'User $uid message conversion status logged: Converted: $converted',
      );
    } catch (e) {
      debugPrint('Error logging message conversion status for user $uid: $e');
    }
  }

  /// 지정된 사용자가 원본 또는 변환된 메시지를 선택하고 전송한 횟수를 기록합니다.
  /// 'converted'가 true이면 selectedAndSentConvertedCount를, false이면 selectedAndSentOriginalCount를 증가시킵니다.
  Future<void> logMessageSelectedAndSent(String uid, bool converted) async {
    try {
      final docRef = _firestore.collection('system_log').doc(uid);

      await _firestore.runTransaction((transaction) async {
        final docSnapshot = await transaction.get(docRef);

        int selectedAndSentConvertedCount = 0;
        int selectedAndSentOriginalCount = 0;

        if (docSnapshot.exists) {
          final data = docSnapshot.data();
          if (data != null) {
            selectedAndSentConvertedCount =
                data['selectedAndSentConvertedCount'] as int? ?? 0;
            selectedAndSentOriginalCount =
                data['selectedAndSentOriginalCount'] as int? ?? 0;
          }
        }

        if (converted) {
          selectedAndSentConvertedCount++;
        } else {
          selectedAndSentOriginalCount++;
        }

        transaction.set(docRef, {
          'selectedAndSentConvertedCount': selectedAndSentConvertedCount,
          'selectedAndSentOriginalCount': selectedAndSentOriginalCount,
        }, SetOptions(merge: true));
      });
      debugPrint(
        'User $uid message selected and sent logged: Converted: $converted',
      );
    } catch (e) {
      debugPrint(
        'Error logging message selected and sent status for user $uid: $e',
      );
    }
  }
}
