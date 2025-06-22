// lib/chat/services/message_service.dart - 개선된 버전
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;

class MessageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 페이지네이션을 위한 상수
  static const int _messagesPerPage = 20;
  static const int _initialLoadCount = 30;

  /// 주어진 채팅방 ID에 대한 실시간 메시지 스트림을 제공합니다.
  Stream<types.Message> streamNewMessages(
    String roomId, {
    DateTime? afterTime,
  }) {
    try {
      Query query = _firestore
          .collection('chatrooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('createdAt');

      // 특정 시간 이후의 메시지만 스트리밍 (새 메시지만)
      if (afterTime != null) {
        query = query.where(
          'createdAt',
          isGreaterThan: Timestamp.fromDate(afterTime),
        );
      }

      return query
          .snapshots()
          .expand((snapshot) => snapshot.docChanges)
          .where((change) => change.type == DocumentChangeType.added)
          .map((change) {
            final data = change.doc.data();
            if (data == null) {
              throw Exception('Message data is null');
            }

            return _createMessageFromData(
              change.doc.id,
              data as Map<String, dynamic>,
            );
          });
    } catch (e) {
      debugPrint('Error streaming messages for room $roomId: $e');
      rethrow;
    }
  }

  /// 초기 메시지 로드 (최신 n개)
  Future<List<types.TextMessage>> loadInitialMessages({
    required String roomId,
    int limit = _initialLoadCount,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('chatrooms')
              .doc(roomId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return _createMessageFromData(doc.id, data);
          }).toList();

      return messages.reversed.toList(); // 시간순으로 정렬
    } catch (e) {
      debugPrint('초기 메시지 로드 오류: $e');
      rethrow;
    }
  }

  /// 더 오래된 메시지 로드 (페이지네이션)
  Future<List<types.TextMessage>> loadOlderMessages({
    required String roomId,
    required DateTime beforeTime,
    int limit = _messagesPerPage,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('chatrooms')
              .doc(roomId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .where('createdAt', isLessThan: Timestamp.fromDate(beforeTime))
              .limit(limit)
              .get();

      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return _createMessageFromData(doc.id, data);
          }).toList();

      return messages.reversed.toList();
    } catch (e) {
      debugPrint('이전 메시지 로드 오류: $e');
      rethrow;
    }
  }

  /// 최근 메시지들을 불러옵니다 (기존 API 호환성 유지)
  Future<List<types.TextMessage>> getRecentMessages({
    required String roomId,
    int limit = 10,
  }) async {
    try {
      final snapshot =
          await _firestore
              .collection('chatrooms')
              .doc(roomId)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(limit)
              .get();

      final messages =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return _createMessageFromData(doc.id, data);
          }).toList();

      return messages.reversed.toList(); // 오래된 순서로 변경 (context 순서 유지)
    } catch (e) {
      debugPrint('getRecentMessages 오류: $e');
      rethrow;
    }
  }

  /// 메시지 데이터로부터 TextMessage 객체 생성
  types.TextMessage _createMessageFromData(
    String id,
    Map<String, dynamic> data,
  ) {
    return types.TextMessage(
      id: id,
      author: types.User(id: data['authorId'] as String),
      createdAt:
          data['createdAt'] is Timestamp
              ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch
              : DateTime.now().millisecondsSinceEpoch,
      text: data['text'] as String,
      metadata: {
        'converted': data['converted'] as bool? ?? false,
        'originalMessage': data['originalMessage'] as String? ?? '',
        'sentimentResult': data['sentimentResult'] as String? ?? '',
        'suggestionResult': data['suggestionResult'] as String? ?? '',
      },
    );
  }

  /// 메시지 캐시 관리를 위한 오래된 메시지 정리
  void clearOldMessagesFromMemory(
    List<types.Message> messages, {
    int keepCount = 50,
  }) {
    if (messages.length > keepCount) {
      messages.removeRange(0, messages.length - keepCount);
    }
  }
}
