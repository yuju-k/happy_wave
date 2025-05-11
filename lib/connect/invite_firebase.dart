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

    final inviteId = '${fromUid}_$toUid';
    final inviteRef = _firestore.collection('invites').doc(inviteId);

    // 이미 pending 상태인지 확인
    final existingInvite = await inviteRef.get();
    if (existingInvite.exists) {
      final status = existingInvite.data()?['status'];
      if (status == 'pending') {
        return '이미 초대가 진행 중입니다.';
      }
    }

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
  }

  /// 초대 수락
  Future<String?> acceptInvite(String fromUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.';

    final toUid = currentUser.uid;
    final inviteId = '${fromUid}_$toUid';

    final inviteRef = _firestore.collection('invites').doc(inviteId);
    final homeId = '${fromUid}_$toUid'; // 홈 ID를 고정된 규칙으로 설정

    // 1. 초대 상태 변경
    await inviteRef.update({'status': 'accepted'});

    // 2. shared_home 생성
    await _firestore.collection('shared_homes').doc(homeId).set({
      'users': [fromUid, toUid],
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 3. 양쪽 사용자 문서 업데이트
    final fromRef = _firestore.collection('users').doc(fromUid);
    final toRef = _firestore.collection('users').doc(toUid);

    await fromRef.set({
      'homeId': homeId,
      'connect_status': true,
    }, SetOptions(merge: true));

    await toRef.set({
      'homeId': homeId,
      'connect_status': true,
      'pendingInvites': FieldValue.arrayRemove([fromUid]),
    }, SetOptions(merge: true));

    return null;
  }

  /// 초대 거절
  Future<String?> declineInvite(String fromUid) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return '로그인이 필요합니다.';

    final toUid = currentUser.uid;
    final inviteId = '${fromUid}_$toUid';

    final inviteRef = _firestore.collection('invites').doc(inviteId);
    final toRef = _firestore.collection('users').doc(toUid);

    // 1. 초대 상태 변경
    await inviteRef.update({'status': 'declined'});

    // 2. 유저 문서에서 pendingInvites 제거
    await toRef.update({
      'pendingInvites': FieldValue.arrayRemove([fromUid]),
    });

    return null;
  }
}
