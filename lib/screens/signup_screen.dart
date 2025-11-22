import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 패키지 임포트
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // 성명
  final _usernameController = TextEditingController(); // 사용자 이름

  // 실제 회원가입 및 DB 저장 함수
  Future<void> _signup() async {
    // 1. 빈칸 검사
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      // 사용자 이름도 검사 추가
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 정보를 입력해주세요.")));
      return;
    }

    try {
      // 2. [Auth] Firebase 인증 계정 생성
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      // 3. [Auth] 프로필 이름(displayName) 업데이트
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // 4. [Firestore] DB에 유저 정보 저장 (★ 여기가 추가된 핵심 코드입니다!)
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid, // 고유 ID
              'email': _emailController.text.trim(), // 이메일
              'name': _nameController.text.trim(), // 성명
              'username': _usernameController.text.trim(), // 사용자 이름
              'createdAt': DateTime.now(), // 가입 시간
              'profileImage': '', // 프로필 사진 (나중을 위해 비워둠)
              'bio': '', // 자기소개 (나중을 위해 비워둠)
            });
      }

      // 5. 성공 처리
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("회원가입 성공! 로그인해주세요.")));
      Navigator.pop(context); // 로그인 화면으로 복귀
    } on FirebaseAuthException catch (e) {
      // 에러 처리
      String message = "회원가입 실패";
      if (e.code == 'email-already-in-use') {
        message = "이미 사용 중인 이메일입니다.";
      } else if (e.code == 'weak-password') {
        message = "비밀번호는 6자리 이상이어야 합니다.";
      } else if (e.code == 'invalid-email') {
        message = "이메일 형식이 올바르지 않습니다.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      // 기타 에러 (DB 저장 실패 등)
      print("에러 발생: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "회원가입",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset(
                'assets/logo.png',
                width: 80,
                errorBuilder: (c, o, s) => const Icon(Icons.image, size: 80),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tripic",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Text(
                "세상을 걷고, 추억을 남기다",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              // 입력 필드들
              CustomTextField(
                hintText: "휴대전화 번호 또는 이메일 주소",
                controller: _emailController,
              ),

              CustomTextField(
                hintText: "비밀번호",
                isPassword: true,
                controller: _passwordController,
              ),

              CustomTextField(hintText: "성명", controller: _nameController),

              CustomTextField(
                hintText: "사용자 이름",
                controller: _usernameController,
              ),

              const SizedBox(height: 20),

              // 가입 버튼
              GradientButton(text: "가입하기", onPressed: _signup),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "계정이 있으신가요? ",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "로그인",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
