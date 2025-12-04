import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class MemberInfoScreen extends StatefulWidget {
  const MemberInfoScreen({super.key});

  @override
  State<MemberInfoScreen> createState() => _MemberInfoScreenState();
}

class _MemberInfoScreenState extends State<MemberInfoScreen> {
  bool _isEditing = false; // 수정 모드 여부
  bool _isSaving = false;

  // 컨트롤러
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    // 현재 전역 변수 값으로 초기화
    _nameController = TextEditingController(text: globalUserName.value);
    _bioController = TextEditingController(text: globalUserBio.value);
    _emailController = TextEditingController(text: globalUserEmail.value);
    _phoneController = TextEditingController(text: globalUserPhone.value);
  }

  @override
  void dispose() {
    _nameController.dispose();
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
              'userName': _nameController.text,
              'bio': _bioController.text,
              'email': _emailController.text,
              'phoneNumber': _phoneController.text,
            });

        // 2. 전역 변수 업데이트 (앱 내 반영)
        globalUserName.value = _nameController.text;
        globalUserBio.value = _bioController.text;
        globalUserEmail.value = _emailController.text;
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
              "이름",
              _nameController,
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
              Icons.email_outlined,
              "이메일",
              _emailController,
              isEditable: _isEditing,
            ),
            _buildInfoTile(
              Icons.phone_android,
              "전화번호",
              _phoneController,
              isEditable: _isEditing,
            ),

            const SizedBox(height: 30),
            const Text(
              "활동 정보",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            // 활동 정보는 수정 불가 (읽기 전용)
            _buildStaticTile(Icons.grade_outlined, "회원 등급", "일반 회원"),
            _buildStaticTile(Icons.location_on_outlined, "주 활동 지역", "서울, 대한민국"),
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

  // 수정 불가능한 고정 타일
  Widget _buildStaticTile(IconData icon, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
