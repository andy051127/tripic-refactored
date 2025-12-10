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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordConfirmController =
      TextEditingController();

  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // 검증 상태
  ValidationState _emailValidation = ValidationState.none;
  String _emailMessage = '';
  ValidationState _passwordValidation = ValidationState.none;
  String _passwordMessage = '';
  ValidationState _passwordConfirmValidation = ValidationState.none;
  String _passwordConfirmMessage = '';
  ValidationState _nameValidation = ValidationState.none;
  String _nameMessage = '';

  // 디바운스를 위한 타이머
  Timer? _emailDebounce;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nameController.dispose();
    _emailDebounce?.cancel();
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
    // 비밀번호가 변경되면 확인 필드도 다시 검사
    if (_passwordConfirmController.text.isNotEmpty) {
      _checkPasswordConfirm(_passwordConfirmController.text);
    }
  }

  // 비밀번호 확인 검증
  void _checkPasswordConfirm(String passwordConfirm) {
    if (passwordConfirm.isEmpty) {
      setState(() {
        _passwordConfirmValidation = ValidationState.none;
        _passwordConfirmMessage = '';
      });
      return;
    }

    if (passwordConfirm != _passwordController.text) {
      setState(() {
        _passwordConfirmValidation = ValidationState.error;
        _passwordConfirmMessage = '비밀번호가 일치하지 않습니다';
      });
    } else {
      setState(() {
        _passwordConfirmValidation = ValidationState.success;
        _passwordConfirmMessage = '비밀번호가 일치합니다';
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
        _nameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _passwordConfirmController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("모든 항목을 입력해주세요.")));
      return;
    }

    // 이메일 중복 체크 확인
    if (_emailValidation != ValidationState.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이메일을 확인해주세요.")));
      return;
    }

    // 비밀번호 길이 검증
    if (_passwordValidation != ValidationState.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("비밀번호를 6자리 이상 입력해주세요.")));
      return;
    }

    // 비밀번호 확인 검증
    if (_passwordConfirmValidation != ValidationState.success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("비밀번호가 일치하지 않습니다.")));
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
      // ProfileCreationScreen으로 이동 (이름 전달)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ProfileCreationScreen(realName: _nameController.text.trim()),
        ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      hintText: "이메일 주소",
                      controller: _emailController,
                      validationState: _emailValidation,
                      validationMessage: _emailMessage,
                      onChanged: _checkEmailAvailability,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 8.0,
                    ), // 텍스트 필드 높이와 맞추기 위해 조정
                    child: SizedBox(
                      height: 48, // CustomTextField의 대략적인 높이
                      child: ElevatedButton(
                        onPressed: () {
                          // 인증하기 기능 구현 (현재는 비워둠)
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "인증하기",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // 2. 이름
              CustomTextField(
                hintText: "이름",
                controller: _nameController,
                validationState: _nameValidation,
                validationMessage: _nameMessage,
                onChanged: _checkNameInput,
              ),
              // 3. 비밀번호
              CustomTextField(
                hintText: "비밀번호 (6자리 이상)",
                isPassword: true,
                controller: _passwordController,
                validationState: _passwordValidation,
                validationMessage: _passwordMessage,
                onChanged: _checkPasswordStrength,
              ),
              // 4. 비밀번호 확인
              CustomTextField(
                hintText: "비밀번호 확인",
                isPassword: true,
                controller: _passwordConfirmController,
                validationState: _passwordConfirmValidation,
                validationMessage: _passwordConfirmMessage,
                onChanged: _checkPasswordConfirm,
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
