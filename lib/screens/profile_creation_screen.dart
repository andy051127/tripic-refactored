import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart'; // 전역 상태 변수 업데이트용
import '../widgets/custom_textfield.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'dart:async';

class ProfileCreationScreen extends StatefulWidget {
  final String email;
  final String name;
  final String username;

  const ProfileCreationScreen({
    super.key,
    required this.email,
    required this.name,
    required this.username,
  });

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  final AuthService _authService = AuthService();
  
  String _selectedGender = '남성'; // 기본값
  bool _isSaving = false;
  
  // 닉네임 검증 상태
  ValidationState _nicknameValidation = ValidationState.none;
  String _nicknameMessage = '';
  Timer? _nicknameDebounce;

  @override
  void dispose() {
    _nicknameController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _nicknameDebounce?.cancel();
    super.dispose();
  }

  // 닉네임 중복 체크
  void _checkNicknameAvailability(String nickname) {
    if (_nicknameDebounce?.isActive ?? false) _nicknameDebounce!.cancel();
    
    if (nickname.isEmpty) {
      setState(() {
        _nicknameValidation = ValidationState.none;
        _nicknameMessage = '';
      });
      return;
    }

    // 500ms 후에 체크
    _nicknameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await _authService.isNicknameAvailable(nickname);
      if (mounted) {
        setState(() {
          if (isAvailable) {
            _nicknameValidation = ValidationState.success;
            _nicknameMessage = '멋진 이름이네요!';
          } else {
            _nicknameValidation = ValidationState.error;
            _nicknameMessage = '이미 존재하는 닉네임입니다';
          }
        });
      }
    });
  }

  Future<void> _saveProfile() async {
    if (_nicknameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("닉네임을 입력해주세요.")));
      return;
    }

    // 닉네임 중복 체크 확인
    if (_nicknameValidation != ValidationState.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("닉네임 중복을 확인해주세요.")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Firestore에 사용자 정보 완전히 저장 (set 사용)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'uid': user.uid,
              'email': widget.email,
              'name': widget.name,
              'username': widget.username,
              'userName': _nicknameController.text, // 닉네임
              'age': _ageController.text,
              'gender': _selectedGender,
              'bio': _bioController.text,
              'profileImage': '', // 초기 프로필 이미지는 비움
              'followers': [], // 팔로워 리스트
              'following': [], // 팔로잉 리스트
              'isProfileSetup': true, // 프로필 설정 완료 플래그
              'createdAt': FieldValue.serverTimestamp(),
            });

        // 2. 전역 상태 변수 업데이트 (앱 내 즉시 반영)
        globalUserName.value = _nicknameController.text;
        globalUserBio.value = _bioController.text;

        if (!mounted) return;

        // 3. 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
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
        centerTitle: true,
        title: const Text(
          "프로필 설정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tripic에서 사용할\n멋진 프로필을 만들어보세요!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 1. 닉네임
            const Text(
              "닉네임",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            CustomTextField(
              hintText: "예: 여행러_김철수",
              controller: _nicknameController,
              validationState: _nicknameValidation,
              validationMessage: _nicknameMessage,
              onChanged: _checkNicknameAvailability,
            ),
            const SizedBox(height: 20),

            // 2. 성별 (라디오 버튼)
            const Text(
              "성별",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile(
                    title: const Text("남성"),
                    value: "남성",
                    groupValue: _selectedGender,
                    onChanged: (val) =>
                        setState(() => _selectedGender = val.toString()),
                    activeColor: const Color(0xFF4CA1AF),
                  ),
                ),
                Expanded(
                  child: RadioListTile(
                    title: const Text("여성"),
                    value: "여성",
                    groupValue: _selectedGender,
                    onChanged: (val) =>
                        setState(() => _selectedGender = val.toString()),
                    activeColor: const Color(0xFF4CA1AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 3. 나이
            const Text(
              "나이",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "예: 25",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 4. 자기소개
            const Text(
              "자기소개 (선택)",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "나를 표현하는 한마디를 적어주세요.",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 40),

            // 저장 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CA1AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "시작하기",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
