import 'package:flutter/material.dart';
import 'package:translator/translator.dart';

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen> {
  final TextEditingController _inputController = TextEditingController();
  final GoogleTranslator _translator = GoogleTranslator();
  
  String _translatedText = '';
  bool _isLoading = false;
  bool _isKoreanToEnglish = true; // true: 한→영, false: 영→한

  Future<void> _translate() async {
    if (_inputController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final translation = await _translator.translate(
        _inputController.text,
        from: _isKoreanToEnglish ? 'ko' : 'en',
        to: _isKoreanToEnglish ? 'en' : 'ko',
      );

      setState(() {
        _translatedText = translation.text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _translatedText = '번역 중 오류가 발생했습니다: $e';
        _isLoading = false;
      });
    }
  }

  void _swapLanguages() {
    setState(() {
      _isKoreanToEnglish = !_isKoreanToEnglish;
      _translatedText = '';
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
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
          "번역기",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 언어 선택 및 교체 버튼
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isKoreanToEnglish ? '한국어' : 'English',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.swap_horiz, size: 28),
                    onPressed: _swapLanguages,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _isKoreanToEnglish ? 'English' : '한국어',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 입력 텍스트 필드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: _isKoreanToEnglish
                      ? '번역할 한국어를 입력하세요...'
                      : 'Enter English text to translate...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),

            // 번역 버튼
            ElevatedButton(
              onPressed: _isLoading ? null : _translate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      '번역하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 20),

            // 번역 결과
            if (_translatedText.isNotEmpty)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _translatedText,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
