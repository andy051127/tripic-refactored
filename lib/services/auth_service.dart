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

  // 1-2. Firebase Auth만 생성 (Firestore는 profile_creation_screen에서 처리)
  Future<String?> signUpAuthOnly({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // 성공
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return '이미 사용 중인 이메일입니다';
        case 'weak-password':
          return '비밀번호가 너무 약합니다 (6자리 이상 입력해주세요)';
        case 'invalid-email':
          return '유효하지 않은 이메일 형식입니다';
        default:
          return e.message ?? '회원가입에 실패했습니다';
      }
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
      // Firebase 에러 코드에 따른 한글 메시지 반환
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-email':
          return '잘못된 이메일입니다';
        case 'wrong-password':
        case 'invalid-credential':
          return '잘못된 비밀번호입니다';
        case 'user-disabled':
          return '비활성화된 계정입니다';
        case 'too-many-requests':
          return '너무 많은 시도가 있었습니다. 잠시 후 다시 시도해주세요';
        default:
          return e.message ?? '로그인에 실패했습니다';
      }
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

  // 5. 이메일 중복 체크
  Future<bool> isEmailAvailable(String email) async {
    try {
      // Firestore에서 이메일 확인
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isEmpty; // 비어있으면 사용 가능
    } catch (e) {
      return false; // 에러 발생 시 사용 불가로 처리
    }
  }

  // 6. 사용자명(ID) 중복 체크
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();
      return querySnapshot.docs.isEmpty; // 비어있으면 사용 가능
    } catch (e) {
      return false; // 에러 발생 시 사용 불가로 처리
    }
  }

  // 7. 닉네임 중복 체크
  Future<bool> isNicknameAvailable(String nickname) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('userName', isEqualTo: nickname)
          .limit(1)
          .get();
      return querySnapshot.docs.isEmpty; // 비어있으면 사용 가능
    } catch (e) {
      return false; // 에러 발생 시 사용 불가로 처리
    }
  }
}
