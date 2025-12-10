import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart'; // 인증 서비스 import
import 'signup_screen.dart';
import 'home_screen.dart';
import 'forgot_password_screen.dart';

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

  void _handleGoogleLogin() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("구글 로그인은 준비 중입니다.")));
  }

  void _handleAppleLogin() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("애플 로그인은 준비 중입니다.")));
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen(),
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

              // SNS 로그인 구분선
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "SNS 계정으로 로그인",
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
                ],
              ),
              const SizedBox(height: 20),

              // 소셜 로그인 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    onTap: _handleGoogleLogin,
                    iconPath: 'assets/icons/google.png',
                    backgroundColor: Colors.white,
                    borderColor: Colors.grey[300],
                    padding: 12,
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    onTap: _handleAppleLogin,
                    iconPath: 'assets/icons/apple.png',
                    backgroundColor: Colors.black,
                    iconColor: Colors.white,
                    padding: 12,
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("카카오 로그인은 준비 중입니다.")),
                      );
                    },
                    iconPath: 'assets/icons/kakao.png',
                    backgroundColor: const Color(0xFFFEE500),
                    padding: 4, // 이미지 크기 조금 줄임
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("네이버 로그인은 준비 중입니다.")),
                      );
                    },
                    iconPath: 'assets/icons/naver.png',
                    backgroundColor: const Color(0xFF03C75A),
                    iconColor: Colors.white,
                    padding: 14, // 이미지 크기 조금 줄임
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required VoidCallback onTap,
    required String iconPath,
    required Color backgroundColor,
    Color? borderColor,
    Color? iconColor,
    double padding = 12.0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: borderColor != null ? Border.all(color: borderColor) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipOval(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Image.asset(
              iconPath,
              color: iconColor,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                String text = '';
                Color textColor = Colors.black;

                if (iconPath.contains('google')) {
                  text = 'G';
                } else if (iconPath.contains('apple')) {
                  text = 'A';
                  textColor = Colors.white;
                } else if (iconPath.contains('kakao')) {
                  text = 'K';
                } else if (iconPath.contains('naver')) {
                  text = 'N';
                  textColor = Colors.white;
                }

                return Center(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: textColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
