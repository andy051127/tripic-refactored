import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. 회원가입 (이메일, 비번, 추가 정보)
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      // 1-1. Authentication에 계정 생성
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 1-2. Firestore에 사용자 정보 저장
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'username': username,
          'profileImage': '', // 초기 프로필 이미지는 비움
          'followers': [], // 팔로워 리스트
          'following': [], // 팔로잉 리스트
          'createdAt': FieldValue.serverTimestamp(),
        });
        return null; // 성공 (에러 없음)
      }
      return "계정 생성 실패";
    } on FirebaseAuthException catch (e) {
      return e.message; // 에러 메시지 반환 (예: 이미 있는 이메일입니다)
    } catch (e) {
      return e.toString();
    }
  }

  // 2. 로그인
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // 성공
    } on FirebaseAuthException catch (e) {
      return e.message; // 에러 메시지 반환 (예: 비밀번호가 틀렸습니다)
    } catch (e) {
      return e.toString();
    }
  }

  // 3. 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 4. 현재 로그인된 사용자 확인
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
