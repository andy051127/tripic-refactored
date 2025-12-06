import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart'; // 인증 서비스 import
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이메일과 비밀번호를 입력해주세요.")));
      return;
    }

    setState(() => _isLoading = true);

    // Firebase 로그인 시도
    String? error = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (error == null) {
      // 로그인 성공: "로그인 상태 유지" 체크박스 상태를 SharedPreferences에 저장
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('keepLoggedIn', _isChecked);
      
      // 성공: 홈 화면으로 이동 (뒤로가기 불가하도록 pushReplacement 사용)
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // 실패: 구체적인 에러 메시지 표시
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Image.asset(
                'assets/tripicLogo.png',
                width: 100,
                errorBuilder: (c, o, s) => const Icon(Icons.image, size: 100),
              ),
              const SizedBox(height: 10),
              const Text(
                "Tripic",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text(
                "세상을 걷고, 추억을 남기다",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // 컨트롤러 연결
              CustomTextField(hintText: "이메일 주소", controller: _emailController),
              CustomTextField(
                hintText: "비밀번호",
                isPassword: true,
                controller: _passwordController,
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (v) => setState(() => _isChecked = v!),
                        activeColor: Colors.grey,
                      ),
                      const Text("로그인 상태 유지", style: TextStyle(fontSize: 12)),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("해당 기능은 아직 준비 되지 않았습니다"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Text(
                      "비밀번호 찾기",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // 로그인 버튼 (로딩 처리)
              _isLoading
                  ? const CircularProgressIndicator()
                  : GradientButton(text: "로그인", onPressed: _handleLogin),

              const SizedBox(height: 30),

              // 회원가입 이동
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "아직 회원이 아니신가요? ",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "회원가입",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
