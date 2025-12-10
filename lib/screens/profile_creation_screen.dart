import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart'; // [추가] 날짜 선택기 사용을 위해 추가
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart'; // 전역 변수 업데이트용
import 'home_screen.dart';
import 'onboarding_screen.dart'; // [추가] 온보딩 화면

class ProfileCreationScreen extends StatefulWidget {
  final String realName; // 회원가입 시 입력한 이름

  const ProfileCreationScreen({super.key, required this.realName});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthController =
      TextEditingController(); // 가입일/생일 등
  final TextEditingController _bioController = TextEditingController();

  bool _isSaving = false;
  bool _isValidId = true; // 고유 ID 유효성 검사

  @override
  void initState() {
    super.initState();
    // 전화번호 초기값 설정 (010-)
    _phoneController.text = "010-";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  // 고유 ID 유효성 검사 (영어와 특수기호만 허용)
  void _validateId(String value) {
    // 영어 대소문자, 숫자, 특수기호만 허용 (한글, 일본어, 중국어 등 제외)
    final validPattern = RegExp(
      r'^[a-zA-Z0-9!@#$%^&*()_+=\[\]{};:,.<>?/\\|`~-]*$',
    );
    setState(() {
      _isValidId = validPattern.hasMatch(value);
    });
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("고유 ID를 입력해주세요.")));
      return;
    }

    if (!_isValidId) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("영어와 특수기호만 사용 가능합니다.")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // 1. Firestore에 사용자 정보 저장 (set with merge를 사용하여 기존 데이터 유지)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email ?? '',
          'realName': widget.realName,
          'userName': _nameController.text,
          'phoneNumber': _phoneController.text,
          'birthDate': _birthController.text, // 가입일 또는 생년월일
          'bio': _bioController.text,
          'profileImage': '',
          'isProfileSetup': true, // 설정 완료 표시
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // 2. 앱 내 전역 변수 업데이트 (즉시 반영)
        globalUserRealName.value = widget.realName;
        globalUserName.value = _nameController.text;
        globalUserPhone.value = _phoneController.text;
        globalUserBio.value = _bioController.text;
        globalUserEmail.value = user.email ?? '';

        if (!mounted) return;

        // 3. 온보딩 화면으로 이동 (회원가입 후 첫 진입이므로)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "프로필 설정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Tripic에서 사용할\n나의 정보를 입력해주세요!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // 고유 ID 입력 필드
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "고유 ID",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  onChanged: _validateId,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isValidId ? Colors.transparent : Colors.red,
                        width: 2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isValidId ? Colors.transparent : Colors.red,
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _isValidId
                            ? const Color(0xFF4CA1AF)
                            : Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                if (!_isValidId)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 4),
                    child: Text(
                      "영어와 특수기호만 사용 가능합니다",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "전화번호",
              _phoneController,
              "010-1234-5678",
              inputType: TextInputType.phone,
              inputFormatters: [PhoneNumberFormatter()],
            ),
            const SizedBox(height: 20),
            _buildTextField(
              "생년월일",
              _birthController,
              "2000.01.01",
              readOnly: true,
              onTap: () {
                FocusScope.of(context).unfocus();
                showCupertinoModalPopup(
                  context: context,
                  builder: (context) => Container(
                    height: 280,
                    color: Colors.white,
                    child: Column(
                      children: [
                        Container(
                          color: Colors.grey[100],
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerRight,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: const Text("확인"),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.date,
                            initialDateTime: DateTime(2000, 1, 1),
                            minimumYear: 1950,
                            maximumYear: DateTime.now().year,
                            onDateTimeChanged: (DateTime newDate) {
                              setState(() {
                                _birthController.text =
                                    "${newDate.year}.${newDate.month.toString().padLeft(2, '0')}.${newDate.day.toString().padLeft(2, '0')}";
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _buildTextField("자기소개", _bioController, "나를 표현하는 한마디", maxLines: 3),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CA1AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "시작하기",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType inputType = TextInputType.text,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: inputType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          readOnly: readOnly,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 2 && text.length > 3) {
        buffer.write('-');
      } else if (i == 6 && text.length > 7) {
        buffer.write('-');
      }
    }

    final formatted = buffer.toString();
    if (formatted.length > 13) {
      return oldValue;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class DateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if (i == 3 && text.length > 4) {
        buffer.write('.');
      } else if (i == 5 && text.length > 6) {
        buffer.write('.');
      }
    }

    final formatted = buffer.toString();
    if (formatted.length > 10) {
      return oldValue;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
