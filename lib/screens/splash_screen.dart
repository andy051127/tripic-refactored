import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';
import 'home_screen.dart'; // [추가] 홈 화면 import
import '../services/auth_service.dart'; // [추가] 인증 서비스 import

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 2초 뒤에 로그인 상태를 확인하여 이동
    Timer(const Duration(seconds: 2), () {
      // 현재 로그인된 사용자가 있는지 확인
      final user = AuthService().getCurrentUser();

      if (user != null) {
        // 로그인 되어있으면 홈 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        // 로그인 안 되어있으면 로그인 화면으로 이동
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // 로고 이미지 (없으면 텍스트로 대체되도록 에러 처리)
            Image.asset(
              'assets/logo.png',
              width: 150,
              errorBuilder: (c, o, s) {
                return const Text(
                  "Tripic",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 200), // 로고와 하단 문구 사이 간격
            const Text(
              "세상을 걷고, 추억을 남기다.",
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
