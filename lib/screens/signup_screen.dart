import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';
import 'profile_creation_screen.dart'; // [신규] 연결
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이메일과 비밀번호를 입력해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    // Firebase 회원가입 요청
    String? error = await _authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      name: _nameController.text.trim(),
      username: _usernameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error == null) {
      if (!mounted) return;

      // [수정] 회원가입 성공 -> 정보 입력 페이지(ProfileCreationScreen)로 이동
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileCreationScreen()),
      );
    } else {
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
              CustomTextField(hintText: "이메일 주소", controller: _emailController),
              CustomTextField(
                hintText: "비밀번호 (6자리 이상)",
                isPassword: true,
                controller: _passwordController,
              ),
              CustomTextField(hintText: "성명 (실명)", controller: _nameController),
              CustomTextField(
                hintText: "사용자 아이디 (ID)",
                controller: _usernameController,
              ),
              const SizedBox(height: 20),
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
