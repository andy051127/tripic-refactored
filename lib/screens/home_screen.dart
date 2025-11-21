import 'package:flutter/material.dart';
import 'dart:io';
import 'community_screen.dart';
import 'travel_plan_screen.dart';
import 'photo_picker_screen.dart';
import 'message_list_screen.dart';
import 'chat_detail_screen.dart';
import 'map_detail_screen.dart';
import 'map_search_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import '../models/post_model.dart';
import '../widgets/comment_modal.dart';
import '../models/activity_model.dart'; // 활동 모델 import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeFeedPage(),
    const TravelPlanScreen(),
    const SizedBox(),
    const CommunityScreen(),
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
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const MessageListScreen(),
              ),
            ),
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
              if (index == 0) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapDetailScreen(),
                        ),
                      ),
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

              final post = posts[index - 1];

              return PostItem(
                post: post,
                onDelete: () {
                  final currentPosts = List<Post>.from(
                    globalPostsNotifier.value,
                  );
                  currentPosts.remove(post);
                  globalPostsNotifier.value = currentPosts;
                },
                onBlock: () {
                  final currentBlocked = List<String>.from(
                    blockedUsersNotifier.value,
                  );
                  if (!currentBlocked.contains(post.userName)) {
                    currentBlocked.add(post.userName);
                    blockedUsersNotifier.value = currentBlocked;
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class PostItem extends StatefulWidget {
  final Post post;
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  const PostItem({
    super.key,
    required this.post,
    required this.onDelete,
    required this.onBlock,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 72;

  // [수정됨] 더보기 메뉴 (저장 버튼 제거됨)
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. 팔로우
            _buildOptionItem(
              Icons.person_add_outlined,
              "팔로우",
              onTap: () {
                Navigator.pop(context);
                globalFollowingCount.value++;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("팔로우 했습니다!")));
              },
            ),
            const Divider(height: 1),

            // [삭제됨] 저장 버튼 제거

            // 2. 숨기기
            _buildOptionItem(
              Icons.visibility_off_outlined,
              "숨기기",
              onTap: () {
                Navigator.pop(context);
                widget.onDelete(); // 게시물 삭제(숨김)
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("게시물을 숨겼습니다.")));
              },
            ),
            const Divider(height: 1),

            // 3. 차단
            _buildOptionItem(
              Icons.block,
              "차단",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                widget.onBlock(); // 차단 실행 (모델 업데이트)
                widget.onDelete(); // 게시물 숨김
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${widget.post.userName}님을 차단했습니다.")),
                );
              },
            ),
            const Divider(height: 1),

            // 4. 신고
            _buildOptionItem(
              Icons.campaign_outlined,
              "신고",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showReportDialog(); // 신고 팝업 띄우기
              },
            ),
          ],
        ),
      ),
    );
  }

  // 신고 사유 선택 팝업
  void _showReportDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 24),
                  const Text(
                    "신고하기",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                children: [
                  _buildReportItem("마음에 들지 않습니다"),
                  _buildReportItem("따돌림 또는 원치 않는 연락"),
                  _buildReportItem("자살, 자해 및 섭식 장애"),
                  _buildReportItem("폭력, 혐오 또는 학대"),
                  _buildReportItem("규제 품목의 판매 또는 홍보"),
                  _buildReportItem("나체 이미지 또는 성적 행위"),
                  _buildReportItem("스캠, 사기 또는 스팸"),
                  _buildReportItem("거짓 정보"),
                  _buildReportItem("지식 재산권 침해"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportItem(String reason) {
    return ListTile(
      title: Text(reason),
      onTap: () {
        Navigator.pop(context);
        widget.onDelete(); // 신고 후 게시물 삭제
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("신고가 완료되었습니다.")));
      },
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String text, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
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

        // 액션 버튼 영역
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              // 1. 좋아요
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    if (_isLiked) {
                      _likeCount++;
                      addActivity(
                        ActivityType.like,
                        widget.post.title,
                        "이 게시물을 좋아합니다.",
                        widget.post.imagePath,
                      );
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

              // 2. 댓글
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => CommentModal(
                      postTitle: widget.post.title,
                      postImage: widget.post.imagePath,
                    ),
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

              // 3. DM
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatDetailScreen(
                        chatPartnerName: widget.post.userName,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.near_me_outlined, size: 28),
              ),

              const Spacer(),

              // 4. 보관함 (스크랩)
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isSaved = !_isSaved;
                  });
                  if (_isSaved) {
                    addActivity(
                      ActivityType.save,
                      widget.post.title,
                      "보관함에 저장했습니다.",
                      widget.post.imagePath,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("게시물이 보관함에 저장되었습니다.")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("보관함 저장을 취소했습니다.")),
                    );
                  }
                },
                child: Icon(
                  _isSaved ? Icons.bookmark : Icons.bookmark_border,
                  size: 28,
                  color: Colors.black,
                ),
              ),
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
