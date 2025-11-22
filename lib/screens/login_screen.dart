import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // [추가됨] 1. 임포트
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import 'signup_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isChecked = false;

  // [추가됨] 2. 텍스트 필드 컨트롤러 생성
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // [추가됨] 3. 실제 로그인 함수
  Future<void> _login() async {
    // 빈칸인지 확인
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이메일과 비밀번호를 입력해주세요.")));
      return;
    }

    try {
      // 파이어베이스 로그인 시도
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 성공 시 홈 화면으로 이동
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // 실패 시 에러 메시지 표시
      String message = "로그인 실패";
      if (e.code == 'user-not-found') {
        message = "가입되지 않은 이메일입니다.";
      } else if (e.code == 'wrong-password') {
        message = "비밀번호가 틀렸습니다.";
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  // [추가됨] 4. 메모리 청소
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
                'assets/logo.png',
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

              // [수정됨] 5. 컨트롤러 연결
              // 주의: CustomTextField가 controller를 받을 수 있어야 합니다!
              CustomTextField(
                hintText: "휴대전화 번호 또는 이메일 주소",
                controller: _emailController, // 컨트롤러 전달
              ),
              const SizedBox(height: 10), // 간격 추가
              CustomTextField(
                hintText: "비밀번호",
                isPassword: true,
                controller: _passwordController, // 컨트롤러 전달
              ),

              // ... (중간 생략: 체크박스 등 기존 코드 유지) ...
              const SizedBox(height: 10),
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
                    onPressed: () {},
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

              // [수정됨] 6. 로그인 버튼에 함수 연결
              GradientButton(
                text: "로그인",
                onPressed: _login, // 위에서 만든 _login 함수 연결
              ),

              const SizedBox(height: 30),

              // ... (아래 소셜 로그인 부분은 그대로 두세요) ...
              // ... (맨 아래 회원가입 버튼 부분도 그대로 두세요) ...
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "간편 로그인",
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 20),
              // 소셜 버튼들...
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (c) => const HomeScreen()),
                    ),
                    child: _socialButton(Colors.yellow, "K", Colors.brown),
                  ),
                  const SizedBox(width: 15),
                  // 네이버
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (c) => const HomeScreen()),
                    ),
                    child: _socialButton(
                      const Color(0xFF03C75A),
                      "N",
                      Colors.white,
                    ),
                  ),
                  const SizedBox(width: 15),
                  // 구글
                  GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (c) => const HomeScreen()),
                    ),
                    child: _socialButton(
                      Colors.white,
                      "G",
                      Colors.black,
                      hasBorder: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 7. 회원가입 이동
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

  Widget _socialButton(
    Color bgColor,
    String letter,
    Color textColor, {
    bool hasBorder = false,
  }) {
    // ... 기존 코드 ...
    return Container(
      width: 50,
      height: 40,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: hasBorder ? Border.all(color: Colors.grey[300]!) : null,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
