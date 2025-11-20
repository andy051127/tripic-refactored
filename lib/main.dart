import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart'; // 날짜 로케일 데이터
import 'screens/splash_screen.dart';

void main() async {
  // async 추가
  WidgetsFlutterBinding.ensureInitialized(); // 플러터 엔진 초기화
  await initializeDateFormatting(); // 날짜 데이터 초기화 (필수!)

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
      ),
      home: const SplashScreen(),
    );
  }
}
