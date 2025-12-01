import 'package:flutter/material.dart';

class LanguageTranslationScreen extends StatefulWidget {
  const LanguageTranslationScreen({super.key});

  @override
  State<LanguageTranslationScreen> createState() =>
      _LanguageTranslationScreenState();
}

class _LanguageTranslationScreenState extends State<LanguageTranslationScreen> {
  final TextEditingController _textController = TextEditingController();
  String _selectedLanguage = '영어'; // 기본 선택 언어
  String _translatedText = ""; // 번역 결과

  // 지원 언어 목록
  final List<String> _languages = ['영어', '일본어', '중국어', '스페인어', '프랑스어'];

  // 간단한 번역 시뮬레이션 함수
  void _translate() {
    String input = _textController.text;
    if (input.isEmpty) {
      setState(() {
        _translatedText = "번역할 내용을 입력해주세요.";
      });
      return;
    }

    // 실제 번역 API 연동 대신, 언어별로 다른 텍스트를 보여주는 예시 로직
    setState(() {
      switch (_selectedLanguage) {
        case '영어':
          _translatedText = "[English] Translated: $input";
          break;
        case '일본어':
          _translatedText = "[日本語] 翻訳結果: $input";
          break;
        case '중국어':
          _translatedText = "[中文] 翻译结果: $input";
          break;
        case '스페인어':
          _translatedText = "[Español] Traducido: $input";
          break;
        case '프랑스어':
          _translatedText = "[Français] Traduit: $input";
          break;
        default:
          _translatedText = input;
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "언어 및 번역",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // 1. 언어 선택 영역
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "한국어",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.grey),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      items: _languages.map((String lang) {
                        return DropdownMenuItem<String>(
                          value: lang,
                          child: Text(
                            lang,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedLanguage = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. 텍스트 입력창
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: null, // 여러 줄 입력 가능
                  decoration: const InputDecoration(
                    hintText: "번역할 내용을 입력하세요...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. 번역하기 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _translate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CA1AF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "번역하기",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. 번역 결과 표시 영역
            const Text(
              "번역 결과",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _translatedText,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
