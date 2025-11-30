import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore import
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import '../models/post_model.dart'; // 전역 변수 업데이트용

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 2초 대기 (로고 보여주기)
    await Future.delayed(const Duration(seconds: 2));

    // SharedPreferences에서 "로그인 상태 유지" 확인
    final prefs = await SharedPreferences.getInstance();
    final keepLoggedIn = prefs.getBool('keepLoggedIn') ?? false;

    final user = FirebaseAuth.instance.currentUser;
    
    // 로그인 상태 유지가 체크되어 있고, Firebase에 사용자가 있는 경우에만 자동 로그인
    if (user != null && keepLoggedIn) {
      // [추가] 로그인 된 경우, Firestore에서 사용자 정보 가져오기
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          // 전역 변수에 사용자 정보 업데이트 (프로필 화면에 반영됨)
          globalUserName.value = data['userName'] ?? 'Unknown';
          globalUserBio.value = data['bio'] ?? '';
          // 필요하다면 나이, 성별 등도 가져올 수 있음
        }
      } catch (e) {
        print("사용자 정보 로드 실패: $e");
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // 로그인 상태 유지가 체크되지 않았거나 사용자가 없으면 로그인 화면으로
      if (user != null && !keepLoggedIn) {
        // 로그인 상태 유지가 체크되지 않은 경우 Firebase 로그아웃
        await FirebaseAuth.instance.signOut();
      }
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
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
            const SizedBox(height: 200),
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
