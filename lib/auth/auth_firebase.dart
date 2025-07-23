import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:happy_wave/auth/domain/entities/member.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _usersCollection = 'users';

  // 회원가입
  Future<String?> signUp(String email, String password) async {
    try {
      var credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (credential.user == null)
        throw FirebaseAuthException(
          code: "code",
          message: "회원가입 중 오류가 발생했습니다.",
        );
      var member = Member.of(uid: credential.user!.uid, email: email);
      await _firestore
          .collection(_usersCollection)
          .doc(_auth.currentUser?.uid)
          .set(member.toJson());

      return null; // 성공 시 에러 없음
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return '회원가입 중 오류가 발생했습니다.';
    }
  }

  // 로그인
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 비밀번호 재설정 메일 보내기
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Member?> findByCurrentUser() async {
    var memberInstance =
        await _firestore
            .collection(_usersCollection)
            .doc(_auth.currentUser?.uid)
            .get();
    print(
      "memberInstance : ${memberInstance.data()}, currentUser.id : ${_auth.currentUser?.uid}",
    );
    if (memberInstance.data() == null) {
      return null;
    }
    var member = Member.fromJson(memberInstance.data() as Map<String, dynamic>);
    return member;
  }

  // 현재 사용자 반환
  User? get currentUser => _auth.currentUser;

  // 로그인 여부 확인
  bool get isSignedIn => _auth.currentUser != null;
}
