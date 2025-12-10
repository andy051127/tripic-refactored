import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      "title": "여행의 모든 순간을 기록하세요",
      "description": "사진, 위치, 그리고 그 순간의 감정까지.\nTripic이 당신의 여행을 완벽하게 기록해드립니다.",
      "image": "assets/tripicLogo.png", // 임시 이미지
    },
    {
      "title": "지도 위에 그려지는 나만의 발자취",
      "description": "이동 경로를 자동으로 추적하여\n지도 위에 당신만의 여행 지도를 그려보세요.",
      "image": "assets/tripicLogo.png", // 임시 이미지
    },
    {
      "title": "소중한 추억을 영원히",
      "description": "여행이 끝나도 추억은 영원합니다.\n언제든지 꺼내볼 수 있는 나만의 여행 앨범.",
      "image": "assets/tripicLogo.png", // 임시 이미지
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 상단 건너뛰기 버튼
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _completeOnboarding,
                child: const Text("건너뛰기", style: TextStyle(color: Colors.grey)),
              ),
            ),

            // 페이지 뷰 (이미지 및 텍스트)
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) {
                  setState(() {
                    _currentPage = value;
                  });
                },
                itemCount: _onboardingData.length,
                itemBuilder: (context, index) => OnboardingContent(
                  title: _onboardingData[index]["title"]!,
                  description: _onboardingData[index]["description"]!,
                  image: _onboardingData[index]["image"]!,
                ),
              ),
            ),

            // 하단 인디케이터 및 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 페이지 인디케이터
                  Row(
                    children: List.generate(
                      _onboardingData.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 5),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.blue
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),

                  // 다음 / 시작하기 버튼
                  ElevatedButton(
                    onPressed: () {
                      if (_currentPage == _onboardingData.length - 1) {
                        _completeOnboarding();
                      } else {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == _onboardingData.length - 1
                          ? "시작하기"
                          : "다음",
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  const OnboardingContent({
    super.key,
    required this.title,
    required this.description,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          Image.asset(
            image,
            height: 250,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.image, size: 100, color: Colors.grey),
          ),
          const Spacer(),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
