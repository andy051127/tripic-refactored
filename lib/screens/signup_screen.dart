import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart'; // 인증 서비스 import

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // 입력값을 가져오기 위한 컨트롤러들
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final AuthService _authService = AuthService(); // 인증 서비스 인스턴스
  bool _isLoading = false; // 로딩 상태 표시용

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    // 1. 입력값 확인
    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 정보를 입력해주세요.")));
      return;
    }

    setState(() => _isLoading = true); // 로딩 시작

    // 2. Firebase 회원가입 요청
    String? error = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    setState(() => _isLoading = false); // 로딩 끝

    // 3. 결과 처리
    if (error == null) {
      // 성공: 로그인 화면으로 복귀 (또는 홈으로 바로 이동)
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("회원가입 성공! 로그인해주세요.")));
      Navigator.pop(context);
    } else {
      // 실패: 에러 메시지 표시
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류: $error")));
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

              // 입력 필드들에 컨트롤러 연결
              CustomTextField(hintText: "이메일 주소", controller: _emailController),
              CustomTextField(
                hintText: "비밀번호 (6자리 이상)",
                isPassword: true,
                controller: _passwordController,
              ),
              CustomTextField(hintText: "성명", controller: _nameController),
              CustomTextField(
                hintText: "사용자 이름 (ID)",
                controller: _usernameController,
              ),

              const SizedBox(height: 20),

              // 가입 버튼 (로딩 중일 땐 뺑뺑이 표시)
              _isLoading
                  ? const CircularProgressIndicator()
                  : GradientButton(text: "가입하기", onPressed: _handleSignUp),

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
