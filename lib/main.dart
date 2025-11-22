import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 날짜 로케일 데이터
import 'package:firebase_core/firebase_core.dart'; // [추가] 파이어베이스 코어
import 'package:firebase_auth/firebase_auth.dart'; // [추가] 로그인 관리용
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart'; // [추가] 로그인 화면
import 'screens/home_screen.dart'; // [추가] 홈 화면

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 플러터 엔진 초기화

  // [추가] 파이어베이스 초기화 (비동기)
  await Firebase.initializeApp();

  await initializeDateFormatting(); // 날짜 데이터 초기화

  runApp(const TripicApp());
}

class TripicApp extends StatelessWidget {
  const TripicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tripic',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      // ★ [핵심] 로그인 상태에 따라 화면 분기 처리 (문지기)
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. 파이어베이스가 로그인 정보를 확인하는 동안 -> 스플래시 화면 보여주기
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashScreen();
          }

          // 2. 로그인 정보가 있음 (이미 로그인됨) -> 홈 화면으로
          if (snapshot.hasData) {
            return const HomeScreen();
          }

          // 3. 로그인 정보가 없음 (로그아웃됨) -> 로그인 화면으로
          return const LoginScreen();
        },
      ),
    );
  }
}
