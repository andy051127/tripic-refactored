import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/post_model.dart';
import 'login_screen.dart';

class MemberInfoScreen extends StatefulWidget {
  const MemberInfoScreen({super.key});

  @override
  State<MemberInfoScreen> createState() => _MemberInfoScreenState();
}

class _MemberInfoScreenState extends State<MemberInfoScreen> {
  bool _isEditing = false; // 수정 모드 여부
  bool _isSaving = false;

  // 컨트롤러
  late TextEditingController _userIdController;  // 고유 ID
  late TextEditingController _realNameController; // 실명
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // 현재 전역 변수 값으로 초기화
    _userIdController = TextEditingController(text: globalUserName.value);
    _realNameController = TextEditingController(text: globalUserRealName.value);
    _bioController = TextEditingController(text: globalUserBio.value);
    _emailController = TextEditingController(text: globalUserEmail.value);
    _phoneController = TextEditingController(text: globalUserPhone.value);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _realNameController.dispose();
    _bioController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 정보 저장 함수
  Future<void> _saveInfo() async {
    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Firestore 업데이트
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
              'userName': _userIdController.text,
              'realName': _realNameController.text,
              'bio': _bioController.text,
              'phoneNumber': _phoneController.text,
            });

        // 2. 전역 변수 업데이트 (앱 내 반영)
        globalUserName.value = _userIdController.text;
        globalUserRealName.value = _realNameController.text;
        globalUserBio.value = _bioController.text;
        globalUserPhone.value = _phoneController.text;

        if (!mounted) return;

        setState(() => _isEditing = false); // 수정 모드 종료
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("정보가 수정되었습니다.")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("수정 실패: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // 계정 삭제 확인 다이얼로그
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 삭제'),
        content: const Text('정말로 계정을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showPasswordConfirmDialog();
            },
            child: const Text('예', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 비밀번호 확인 다이얼로그
  void _showPasswordConfirmDialog() {
    final TextEditingController passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('본인 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('본인 확인을 위해 현재 비밀번호 입력'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: '비밀번호',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteAccount(passwordController.text);
            },
            child: const Text('확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 계정 삭제 처리
  Future<void> _deleteAccount(String password) async {
    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('비밀번호를 입력해주세요')),
      );
      return;
    }

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인 정보가 없습니다');

      // 1. 비밀번호 재인증
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final uid = user.uid;

      print('계정 삭제 시작 - UID: $uid');

      // 2. Firestore 데이터 삭제
      
      // 사용자 게시물 삭제 (댓글, 좋아요도 함께 삭제)
      print('게시물 검색 중...');
      final postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userName', isEqualTo: globalUserName.value)
          .get();
      
      print('찾은 게시물 수: ${postsSnapshot.docs.length}');
      
      for (var postDoc in postsSnapshot.docs) {
        print('게시물 삭제 중: ${postDoc.id}');
        final postData = postDoc.data();
        
        // 게시물의 댓글 삭제 (서브컬렉션)
        final commentsSnapshot = await postDoc.reference
            .collection('comments')
            .get();
        print('  댓글 수: ${commentsSnapshot.docs.length}');
        for (var commentDoc in commentsSnapshot.docs) {
          await commentDoc.reference.delete();
        }
        
        // 게시물의 좋아요 삭제 (서브컬렉션)
        final likesSnapshot = await postDoc.reference
            .collection('likes')
            .get();
        print('  좋아요 수: ${likesSnapshot.docs.length}');
        for (var likeDoc in likesSnapshot.docs) {
          await likeDoc.reference.delete();
        }
        
        // 게시물 삭제
        await postDoc.reference.delete();
        
        // Storage에서 게시물 이미지 삭제
        if (postData['imageUrls'] != null) {
          for (String imageUrl in List<String>.from(postData['imageUrls'])) {
            try {
              await FirebaseStorage.instance.refFromURL(imageUrl).delete();
            } catch (e) {
              print('이미지 삭제 실패: $e');
            }
          }
        }
      }

      // 다른 사람 게시물에 작성한 내 댓글 삭제
      print('다른 사람 게시물 확인 중...');
      final allPostsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();
      
      int deletedComments = 0;
      int deletedLikes = 0;
      
      for (var postDoc in allPostsSnapshot.docs) {
        // 내 댓글 삭제 (userName 필드 기준)
        final myCommentsSnapshot = await postDoc.reference
            .collection('comments')
            .where('userName', isEqualTo: globalUserName.value)
            .get();
        
        for (var commentDoc in myCommentsSnapshot.docs) {
          await commentDoc.reference.delete();
          deletedComments++;
        }
        
        // 내 좋아요 삭제 (uid를 문서 ID로 사용)
        try {
          final myLikeDoc = await postDoc.reference
              .collection('likes')
              .doc(uid)
              .get();
          
          if (myLikeDoc.exists) {
            await myLikeDoc.reference.delete();
            deletedLikes++;
          }
        } catch (e) {
          print('좋아요 삭제 실패: $e');
        }
      }
      
      print('삭제된 댓글: $deletedComments, 삭제된 좋아요: $deletedLikes');

      // 사용자 북마크(저장된 게시물) 삭제
      final savedPostsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savedPosts')
          .get();
      for (var doc in savedPostsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 사용자 여행 계획 삭제
      final travelPlansSnapshot = await FirebaseFirestore.instance
          .collection('travel_plans')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in travelPlansSnapshot.docs) {
        await doc.reference.delete();
      }

      // 사용자 채팅방 삭제
      final chatRoomsSnapshot = await FirebaseFirestore.instance
          .collection('chatrooms')
          .where('participants', arrayContains: uid)
          .get();
      for (var doc in chatRoomsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 사용자 알림 삭제
      final notificationsSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .get();
      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      // 팔로우/팔로워 관계 삭제
      final followsSnapshot = await FirebaseFirestore.instance
          .collection('follows')
          .where('followerId', isEqualTo: uid)
          .get();
      for (var doc in followsSnapshot.docs) {
        await doc.reference.delete();
      }
      final followedSnapshot = await FirebaseFirestore.instance
          .collection('follows')
          .where('followingId', isEqualTo: uid)
          .get();
      for (var doc in followedSnapshot.docs) {
        await doc.reference.delete();
      }

      // 사용자 프로필 이미지 삭제
      if (globalProfileImage.value.isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .refFromURL(globalProfileImage.value)
              .delete();
        } catch (e) {
          print('프로필 이미지 삭제 실패: $e');
        }
      }

      // 사용자 문서 삭제
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .delete();

      // 3. Firebase Auth 계정 삭제
      await user.delete();

      // 4. 전역 변수 초기화
      globalUserName.value = '';
      globalUserRealName.value = '';
      globalUserBio.value = '';
      globalUserEmail.value = '';
      globalUserPhone.value = '';
      globalProfileImage.value = '';

      if (!mounted) return;

      // 로딩 다이얼로그 닫기
      Navigator.pop(context);

      // 로그인 화면으로 이동
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('계정이 삭제되었습니다')),
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      String errorMessage = '계정 삭제 실패';
      if (e.code == 'wrong-password') {
        errorMessage = '비밀번호가 일치하지 않습니다';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = '보안을 위해 다시 로그인해주세요';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      Navigator.pop(context); // 로딩 다이얼로그 닫기
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "회원 정보",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 수정/저장 버튼
          TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    if (_isEditing) {
                      _saveInfo(); // 저장
                    } else {
                      setState(() => _isEditing = true); // 수정 모드 진입
                    }
                  },
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    _isEditing ? "완료" : "수정",
                    style: TextStyle(
                      color: _isEditing ? Colors.blue : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "기본 정보",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              Icons.person_outline,
              "고유 ID",
              _userIdController,
              isEditable: _isEditing,
            ),
            _buildInfoTile(
              Icons.badge_outlined,
              "이름",
              _realNameController,
              isEditable: _isEditing,
            ),
            _buildInfoTile(
              Icons.info_outline,
              "자기소개",
              _bioController,
              isEditable: _isEditing,
              maxLines: 3,
            ),

            const SizedBox(height: 30),
            const Text(
              "연락처 정보",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildInfoTile(
              Icons.phone_android,
              "전화번호",
              _phoneController,
              isEditable: _isEditing,
            ),
            _buildInfoTile(
              Icons.email_outlined,
              "이메일",
              _emailController,
              isEditable: false, // 이메일은 수정 불가
            ),

            const SizedBox(height: 50),
            
            // 계정 삭제 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showDeleteAccountDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '계정 삭제하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 수정 가능한 타일 (TextField or Text)
  Widget _buildInfoTile(
    IconData icon,
    String title,
    TextEditingController controller, {
    required bool isEditable,
    int maxLines = 1,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 패딩 조정
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEditable ? const Color(0xFF4CA1AF) : Colors.grey.shade200,
        ), // 수정 중이면 테두리 색상 변경
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 8 : 0),
            child: Icon(icon, color: Colors.grey[600], size: 22),
          ),
          const SizedBox(width: 16),
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 8 : 0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: isEditable
                ? TextField(
                    controller: controller,
                    textAlign: TextAlign.end,
                    maxLines: maxLines,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  )
                : Text(
                    controller.text,
                    textAlign: TextAlign.end,
                    maxLines: maxLines,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
