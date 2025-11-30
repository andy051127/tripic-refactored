import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';
import 'profile_creation_screen.dart';
import 'dart:async';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // 검증 상태
  ValidationState _emailValidation = ValidationState.none;
  String _emailMessage = '';
  ValidationState _usernameValidation = ValidationState.none;
  String _usernameMessage = '';
  ValidationState _passwordValidation = ValidationState.none;
  String _passwordMessage = '';
  ValidationState _nameValidation = ValidationState.none;
  String _nameMessage = '';

  // 디바운스를 위한 타이머
  Timer? _emailDebounce;
  Timer? _usernameDebounce;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailDebounce?.cancel();
    _usernameDebounce?.cancel();
    super.dispose();
  }

  // 이메일 중복 체크 및 형식 검증
  void _checkEmailAvailability(String email) {
    if (_emailDebounce?.isActive ?? false) _emailDebounce!.cancel();
    
    if (email.isEmpty) {
      setState(() {
        _emailValidation = ValidationState.none;
        _emailMessage = '';
      });
      return;
    }

    // 이메일 형식 검증 (정규식)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _emailValidation = ValidationState.error;
        _emailMessage = '올바른 주소를 입력하세요';
      });
      return;
    }

    // 500ms 후에 중복 체크 (사용자가 입력을 멈춘 후)
    _emailDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await _authService.isEmailAvailable(email);
      if (mounted) {
        setState(() {
          if (isAvailable) {
            _emailValidation = ValidationState.success;
            _emailMessage = '중복되지 않는 이메일입니다';
          } else {
            _emailValidation = ValidationState.error;
            _emailMessage = '이미 존재하는 이메일입니다';
          }
        });
      }
    });
  }

  // 사용자명 중복 체크
  void _checkUsernameAvailability(String username) {
    if (_usernameDebounce?.isActive ?? false) _usernameDebounce!.cancel();
    
    if (username.isEmpty) {
      setState(() {
        _usernameValidation = ValidationState.none;
        _usernameMessage = '';
      });
      return;
    }

    // 500ms 후에 체크
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      final isAvailable = await _authService.isUsernameAvailable(username);
      if (mounted) {
        setState(() {
          if (isAvailable) {
            _usernameValidation = ValidationState.success;
            _usernameMessage = '중복되지 않는 ID입니다';
          } else {
            _usernameValidation = ValidationState.error;
            _usernameMessage = '이미 존재하는 ID입니다';
          }
        });
      }
    });
  }

  // 비밀번호 길이 검증
  void _checkPasswordStrength(String password) {
    if (password.isEmpty) {
      setState(() {
        _passwordValidation = ValidationState.none;
        _passwordMessage = '';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _passwordValidation = ValidationState.error;
        _passwordMessage = '비밀번호를 6자리 이상 입력해주세요';
      });
    } else {
      setState(() {
        _passwordValidation = ValidationState.success;
        _passwordMessage = '';
      });
    }
  }

  // 이름 검증
  void _checkNameInput(String name) {
    if (name.isEmpty) {
      setState(() {
        _nameValidation = ValidationState.none;
        _nameMessage = '';
      });
      return;
    }

    setState(() {
      _nameValidation = ValidationState.success;
      _nameMessage = '멋진 이름이네요';
    });
  }

  void _handleSignUp() async {
    // 유효성 검사
    if (_emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _nameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("모든 항목을 입력해주세요.")),
      );
      return;
    }

    // 이메일 중복 체크 확인
    if (_emailValidation != ValidationState.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("이메일을 확인해주세요.")),
      );
      return;
    }

    // 사용자명 중복 체크 확인
    if (_usernameValidation != ValidationState.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("사용자 이름(ID) 중복을 확인해주세요.")),
      );
      return;
    }

    // 비밀번호 길이 검증
    if (_passwordValidation != ValidationState.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("비밀번호를 6자리 이상 입력해주세요.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Firebase Auth만 생성 (Firestore는 profile_creation_screen에서 처리)
    String? error = await _authService.signUpAuthOnly(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    setState(() => _isLoading = false);

    // 결과 처리
    if (error == null) {
      if (!mounted) return;
      // 사용자 입력 정보를 ProfileCreationScreen에 전달
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileCreationScreen(
            email: _emailController.text.trim(),
            name: _nameController.text.trim(),
            username: _usernameController.text.trim(),
          ),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("오류: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ... (기존 UI 코드 그대로 유지 - 너무 길어서 생략하지만 build 메서드 전체가 있어야 함) ...
    // 아래는 기존 코드의 핵심 부분인 build 메서드입니다.
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
                'assets/tripicLogo.png',
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
              // 1. 이메일 주소
              CustomTextField(
                hintText: "이메일 주소",
                controller: _emailController,
                validationState: _emailValidation,
                validationMessage: _emailMessage,
                onChanged: _checkEmailAvailability,
              ),
              // 2. 사용자 이름 (ID)
              CustomTextField(
                hintText: "사용자 이름 (ID)",
                controller: _usernameController,
                validationState: _usernameValidation,
                validationMessage: _usernameMessage,
                onChanged: _checkUsernameAvailability,
              ),
              // 3. 이름
              CustomTextField(
                hintText: "이름",
                controller: _nameController,
                validationState: _nameValidation,
                validationMessage: _nameMessage,
                onChanged: _checkNameInput,
              ),
              // 4. 비밀번호
              CustomTextField(
                hintText: "비밀번호 (6자리 이상)",
                isPassword: true,
                controller: _passwordController,
                validationState: _passwordValidation,
                validationMessage: _passwordMessage,
                onChanged: _checkPasswordStrength,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : GradientButton(text: "가입하기", onPressed: _handleSignUp),
              const SizedBox(height: 20),
              // ... (하단 링크 등)
            ],
          ),
        ),
      ),
    );
  }
}
