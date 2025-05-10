// auth_firebase.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 회원가입
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // 성공 시 에러 없음
    } on FirebaseAuthException catch (e) {
      return e.message;
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

  // 현재 사용자 반환
  User? get currentUser => _auth.currentUser;

  // 로그인 여부 확인
  bool get isSignedIn => _auth.currentUser != null;
}
