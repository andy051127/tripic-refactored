import 'package:flutter/material.dart';
import 'dart:ui'; // [추가] 이미지 블러 처리를 위해 필요
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart'; // [변경] 로그인 화면 대신 홈 화면으로 이동

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
      "title": "친구들의 여행 기록",
      "description": "지도 위에서 친구들의 여행을 확인하고\n피드에서 생생한 이야기를 만나보세요.",
      "image": "assets/onboarding/share.png",
    },
    {
      "title": "완벽한 여행 계획",
      "description": "항공권부터 숙소, 준비물 체크리스트까지\n여행의 모든 것을 한곳에서 관리하세요.",
      "image": "assets/onboarding/plan.png",
    },
    {
      "title": "함께하는 즐거움",
      "description": "여행 꿀팁을 나누고\n마음이 맞는 동행을 찾아보세요.",
      "image": "assets/onboarding/community.png",
    },
    {
      "title": "나만의 여행 여권",
      "description": "방문한 국가들의 국기를 수집하고\n나만의 여행 지도를 채워보세요.",
      "image": "assets/onboarding/write.png",
    },
    {
      "title": "발자취 기록",
      "description": "내가 이동한 경로와 추억이 담긴 장소를\n지도 위에 생생하게 남겨보세요.",
      "image": "assets/onboarding/map.png",
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);

    if (!mounted) return;
    // [변경] 회원가입 -> 프로필 생성 -> 온보딩 -> 홈 화면 순서이므로 홈으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 전체 화면 페이지 뷰 (배경 이미지 + 텍스트)
          PageView.builder(
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

          // 2. 상단 건너뛰기 버튼 (SafeArea 적용)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: TextButton(
              onPressed: _completeOnboarding,
              child: const Text(
                "건너뛰기",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // 3. 하단 인디케이터 및 버튼
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
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
                            : Colors.white.withOpacity(0.5),
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
                    _currentPage == _onboardingData.length - 1 ? "시작하기" : "다음",
                  ),
                ),
              ],
            ),
          ),
        ],
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
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 배경 이미지
        Image.asset(
          image,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(
                Icons.image_not_supported,
                size: 50,
                color: Colors.grey,
              ),
            ),
          ),
        ),

        // 2. 블러 및 어두운 오버레이 효과
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // 블러 강도 조절
            child: Container(
              color: Colors.black.withOpacity(0.4), // 어둡게 처리하여 텍스트 가독성 확보
            ),
          ),
        ),

        // 3. 중앙 텍스트
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 10.0,
                      color: Colors.black45,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.6,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black45,
                      offset: Offset(1.0, 1.0),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
