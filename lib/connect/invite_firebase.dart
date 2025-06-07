import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 이메일로 사용자 UID 찾기
  Future<String?> getUidByEmail(String email) async {
    final query =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first.id;
  }

  /// UID로 이메일 찾기
  Future<String> getEmailByUid(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['email'] ?? '알 수 없음';
  }

  /// 현재 사용자가 보낸 pending 초대가 있는지 확인
  Future<Map<String, dynamic>?> getPendingInviteFromCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final query =
          await _firestore
              .collection('invites')
              .where('from', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (query.docs.isNotEmpty) {
        final inviteData = query.docs.first.data();
        final toUid = inviteData['to'] as String;
        final email = await getEmailByUid(toUid);

        return {
          'inviteId': query.docs.first.id,
          'toUid': toUid,
          'toEmail': email,
          'createdAt': inviteData['createdAt'],
        };
      }
      return null;
    } catch (e) {
      print('Error getting pending invite: $e');
      return null;
    }
  }

  /// 기존 연결 관계가 있는지 확인 (연결 해제된 상태 포함)
  Future<String?> getExistingHomeId(String uid1, String uid2) async {
    try {
      // 두 가지 가능한 homeId 패턴 확인
      final homeId1 = '${uid1}_$uid2';
      final homeId2 = '${uid2}_$uid1';

      // 첫 번째 패턴 확인
      final doc1 =
          await _firestore.collection('shared_homes').doc(homeId1).get();
      if (doc1.exists) {
        return homeId1;
      }

      // 두 번째 패턴 확인
      final doc2 =
          await _firestore.collection('shared_homes').doc(homeId2).get();
      if (doc2.exists) {
        return homeId2;
      }

      return null;
    } catch (e) {
      print('Error checking existing home: $e');
      return null;
    }
  }

  /// 초대 전송: invites 문서 생성 + 상대방 pendingInvites 업데이트
  Future<String?> sendInvite(String targetEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.';

    final fromUid = currentUser.uid;
    final toUid = await getUidByEmail(targetEmail);

    if (toUid == null) {
      return '해당 이메일을 가진 사용자를 찾을 수 없습니다.';
    }
    if (fromUid == toUid) {
      return '자기 자신에게는 초대할 수 없습니다.';
    }

    // 이미 pending 상태인 초대가 있는지 확인
    final existingPendingInvite = await getPendingInviteFromCurrentUser();
    if (existingPendingInvite != null) {
      return '이미 초대가 진행 중입니다.';
    }

    final inviteId = '${fromUid}_$toUid';
    final inviteRef = _firestore.collection('invites').doc(inviteId);

    // 기존 초대 상태 확인
    final existingInvite = await inviteRef.get();
    if (existingInvite.exists) {
      final status = existingInvite.data()?['status'];
      if (status == 'pending') {
        return '이미 초대가 진행 중입니다.';
      }
    }

    try {
      // invites 문서 생성 또는 업데이트
      await inviteRef.set({
        'from': fromUid,
        'to': toUid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 상대방 문서에 pendingInvites 배열에 추가
      final targetUserRef = _firestore.collection('users').doc(toUid);
      await targetUserRef.set({
        'pendingInvites': FieldValue.arrayUnion([fromUid]),
      }, SetOptions(merge: true));

      return null; // 성공 시 null 반환
    } catch (e) {
      return '초대 전송 중 오류가 발생했습니다: $e';
    }
  }

  /// 초대 취소
  Future<String?> cancelInvite(String toUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.';

    final fromUid = currentUser.uid;
    final inviteId = '${fromUid}_$toUid';

    try {
      final inviteRef = _firestore.collection('invites').doc(inviteId);

      // 초대 상태를 cancelled로 변경
      await inviteRef.update({'status': 'cancelled'});

      // 상대방의 pendingInvites에서 제거
      await _firestore.collection('users').doc(toUid).update({
        'pendingInvites': FieldValue.arrayRemove([fromUid]),
      });

      return null; // 성공
    } catch (e) {
      return '초대 취소 중 오류가 발생했습니다: $e';
    }
  }

  /// 초대 수락 (기존 관계 확인 후 재연결 또는 신규 생성)
  Future<String?> acceptInvite(String fromUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.';

    final toUid = currentUser.uid;
    final inviteId = '${fromUid}_$toUid';

    try {
      final inviteRef = _firestore.collection('invites').doc(inviteId);

      // 기존 연결 관계 확인
      final existingHomeId = await getExistingHomeId(fromUid, toUid);
      final homeId = existingHomeId ?? '${fromUid}_$toUid'; // 기존이 없으면 새로 생성

      // 1. 초대 상태 변경
      await inviteRef.update({'status': 'accepted'});

      if (existingHomeId != null) {
        // 재연결의 경우: 기존 문서들의 상태만 업데이트
        await _firestore.runTransaction((transaction) async {
          // shared_home 상태 복원
          final sharedHomeRef = _firestore
              .collection('shared_homes')
              .doc(homeId);
          transaction.update(sharedHomeRef, {
            'status': 'connected',
            'reconnectedAt': FieldValue.serverTimestamp(),
          });

          // 채팅방 상태 복원
          final chatroomRef = _firestore.collection('chatrooms').doc(homeId);
          transaction.update(chatroomRef, {
            'status': 'connected',
            'reconnectedAt': FieldValue.serverTimestamp(),
          });

          // 양쪽 사용자 문서 업데이트
          final fromRef = _firestore.collection('users').doc(fromUid);
          final toRef = _firestore.collection('users').doc(toUid);

          transaction.update(fromRef, {'connect_status': true});

          transaction.update(toRef, {
            'connect_status': true,
            'pendingInvites': FieldValue.arrayRemove([fromUid]),
          });
        });
      } else {
        // 신규 연결의 경우: 새로운 문서들 생성
        await _firestore.runTransaction((transaction) async {
          // shared_home 생성
          final sharedHomeRef = _firestore
              .collection('shared_homes')
              .doc(homeId);
          transaction.set(sharedHomeRef, {
            'users': [fromUid, toUid],
            'status': 'connected',
            'createdAt': FieldValue.serverTimestamp(),
          });

          // 채팅방 생성
          final chatroomRef = _firestore.collection('chatrooms').doc(homeId);
          transaction.set(chatroomRef, {
            'users': [fromUid, toUid],
            'status': 'connected',
            'createdAt': FieldValue.serverTimestamp(),
            'lastMessage': null,
          });

          // 양쪽 사용자 문서 업데이트
          final fromRef = _firestore.collection('users').doc(fromUid);
          final toRef = _firestore.collection('users').doc(toUid);

          transaction.update(fromRef, {
            'homeId': homeId,
            'chatroomId': homeId,
            'connect_status': true,
          });

          transaction.update(toRef, {
            'homeId': homeId,
            'chatroomId': homeId,
            'connect_status': true,
            'pendingInvites': FieldValue.arrayRemove([fromUid]),
          });
        });
      }

      return null;
    } catch (e) {
      return '초대 수락 중 오류가 발생했습니다: $e';
    }
  }

  /// 초대 거절
  Future<String?> declineInvite(String fromUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.';

    final toUid = currentUser.uid;
    final inviteId = '${fromUid}_$toUid';

    try {
      final inviteRef = _firestore.collection('invites').doc(inviteId);
      final toRef = _firestore.collection('users').doc(toUid);

      // 1. 초대 상태 변경
      await inviteRef.update({'status': 'declined'});

      // 2. 유저 문서에서 pendingInvites 제거
      await toRef.update({
        'pendingInvites': FieldValue.arrayRemove([fromUid]),
      });

      return null;
    } catch (e) {
      return '초대 거절 중 오류가 발생했습니다: $e';
    }
  }
}
