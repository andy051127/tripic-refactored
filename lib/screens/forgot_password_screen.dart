import 'package:flutter/material.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/gradient_button.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("이메일을 입력해주세요.")));
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    String? error = await _authService.sendPasswordResetEmail(
      _emailController.text.trim(),
    );

    setState(() {
      _isLoading = false;
      if (error == null) {
        _isSuccess = true;
        _message = "비밀번호 재설정 이메일이 발송되었습니다.\n이메일을 확인해주세요.";
      } else {
        _isSuccess = false;
        _message = error;
      }
    });
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
          "비밀번호 찾기",
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "비밀번호를 잊으셨나요?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                "가입하신 이메일 주소를 입력하시면\n비밀번호 재설정 링크를 보내드립니다.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              CustomTextField(hintText: "이메일 주소", controller: _emailController),
              const SizedBox(height: 20),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _isSuccess ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GradientButton(
                      text: "이메일 발송",
                      onPressed: _handleResetPassword,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
