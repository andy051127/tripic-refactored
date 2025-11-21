import 'package:flutter/material.dart';
import 'dart:io'; // 파일 이미지 표시용
import 'community_screen.dart';
import 'travel_plan_screen.dart';
import 'photo_picker_screen.dart';
import 'message_list_screen.dart';
import 'chat_detail_screen.dart'; // DM 이동용
import 'map_detail_screen.dart'; // 지도 상세 화면 import
import '../models/post_model.dart'; // 데이터 모델 import
import '../widgets/comment_modal.dart'; // 댓글 모달 import
import 'profile_screen.dart';
import 'search_screen.dart'; // [추가] 통합 검색 화면 import
import 'map_search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeFeedPage(), // 0: 홈 (피드)
    const TravelPlanScreen(), // 1: 여행 계획
    const SizedBox(), // 2: (사용 안 함)
    const CommunityScreen(), // 3: 커뮤니티
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PhotoPickerScreen()),
      );
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: 'Plan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// 홈 피드 페이지
class HomeFeedPage extends StatelessWidget {
  const HomeFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Row(
            children: [
              Image.asset(
                'assets/logo.png',
                height: 30,
                errorBuilder: (c, o, s) =>
                    const Icon(Icons.waves, color: Color(0xFF4CA1AF)),
              ),
              const SizedBox(width: 8),
              const Text(
                "Tripic",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MessageListScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.chat_bubble_outline,
              color: Colors.black,
              size: 26,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ValueListenableBuilder<List<Post>>(
        valueListenable: globalPostsNotifier,
        builder: (context, posts, child) {
          return ListView.builder(
            itemCount: posts.length + 1,
            itemBuilder: (context, index) {
              // 1. 상단 지도 배너
              if (index == 0) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MapDetailScreen(),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          image: const DecorationImage(
                            image: NetworkImage(
                              "https://via.placeholder.com/600x200.png?text=Map+View",
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Container(color: Colors.black12),
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.map,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "내 주변 친구들의 여행 기록 보기",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }
              // 2. 게시물 리스트
              final post = posts[index - 1];
              return PostItem(post: post);
            },
          );
        },
      ),
    );
  }
}

// 개별 게시물 위젯
class PostItem extends StatefulWidget {
  final Post post;
  const PostItem({super.key, required this.post});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  int _likeCount = 72;

  // [추가] 더보기 메뉴 바텀 시트
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // 배경 투명 (둥근 모서리 효과 위해)
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOptionItem(Icons.person_add_outlined, "팔로우"),
              const Divider(height: 1),
              _buildOptionItem(Icons.bookmark_border, "저장"),
              const Divider(height: 1),
              _buildOptionItem(Icons.visibility_off_outlined, "숨기기"),
              const Divider(height: 1),
              _buildOptionItem(
                Icons.campaign_outlined,
                "신고",
                isDestructive: true,
              ), // 빨간색 아이콘 등 강조 가능
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String text, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      onTap: () {
        Navigator.pop(context); // 메뉴 닫기
        // 여기에 각 기능 구현 (예: 팔로우 API 호출 등)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("$text 기능이 선택되었습니다.")));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 헤더 (프로필 + 더보기 버튼)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    widget.post.location,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Spacer(),
              // [수정] 더보기 버튼 클릭 연결
              GestureDetector(
                onTap: _showMoreOptions,
                child: const Icon(
                  Icons.more_horiz,
                  size: 24,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),

        // 이미지
        Container(
          width: double.infinity,
          height: 400,
          color: Colors.grey[200],
          child: widget.post.isFile
              ? Image.file(File(widget.post.imagePath), fit: BoxFit.cover)
              : Image.asset(
                  widget.post.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) =>
                      const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
        ),

        // 액션 버튼들 (좋아요, 댓글, DM)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    if (_isLiked) {
                      _likeCount++;
                    } else {
                      _likeCount--;
                    }
                  });
                },
                child: Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  size: 28,
                  color: _isLiked ? Colors.red : Colors.black,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                "$_likeCount",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const CommentModal(),
                  );
                },
                child: const Icon(Icons.chat_bubble_outline, size: 28),
              ),
              const SizedBox(width: 6),
              const Text(
                "21",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ChatDetailScreen(),
                    ),
                  );
                },
                child: const Icon(Icons.near_me_outlined, size: 28),
              ),
              const Spacer(),
              const Icon(Icons.bookmark_border, size: 28),
            ],
          ),
        ),

        // 본문 내용
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(widget.post.content, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
