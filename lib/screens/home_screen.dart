import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 패키지
import 'package:firebase_auth/firebase_auth.dart'; // 로그인 정보
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
import '../models/activity_model.dart';

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
    const SizedBox(), // Add 버튼 자리 (onItemTapped에서 처리)
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
      // ★ [수정됨] 기존 ValueListenableBuilder 대신 StreamBuilder 사용
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts') // 'posts' 컬렉션 구독
            .orderBy('timestamp', descending: true) // 최신순 정렬
            .snapshots(),
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. 게시글 없음
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context); // 빈 화면 표시
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length + 1, // 헤더(지도 배너) 포함
            itemBuilder: (context, index) {
              // 0번 인덱스는 지도 배너
              if (index == 0) {
                return _buildMapBanner(context);
              }

              // 실제 게시글 데이터 (index - 1)
              final doc = docs[index - 1];
              final data = doc.data() as Map<String, dynamic>;

              // Firestore 데이터를 기존 Post 모델로 변환
              final post = Post(
                userName: data['username'] ?? '익명',
                location: data['location'] ?? 'Seoul, Korea',
                imagePath: data['imageUrl'] ?? '', // URL이 들어갑니다
                title: data['title'] ?? '', // 제목이 없는 경우 대비
                content:
                    data['content'] ?? '', // 내용 필드 (기존 title, content 매핑 확인)
                isFile: false, // Firestore 이미지는 URL이므로 false
              );

              return PostItem(
                post: post,
                docId: doc.id, // 삭제를 위해 문서 ID 전달
                uid: data['uid'] ?? '', // 작성자 ID 전달
                onDelete: () {
                  // 여기에 로컬 삭제 로직이 있었으나, PostItem 내부에서 DB 삭제 처리하도록 변경
                },
                onBlock: () {
                  // 차단 로직 (기존 유지)
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

  // 게시글 없을 때 화면
  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        _buildMapBanner(context),
        const Expanded(
          child: Center(child: Text("아직 게시물이 없어요.\n첫 번째 여행을 기록해보세요!")),
        ),
      ],
    );
  }

  // 상단 지도 배너 위젯 분리
  Widget _buildMapBanner(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapDetailScreen()),
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
                      Icon(Icons.map, color: Colors.white, size: 30),
                      SizedBox(height: 8),
                      Text(
                        "내 주변 친구들의 여행 기록 보기",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: [Shadow(blurRadius: 2, color: Colors.black)],
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
}

class PostItem extends StatefulWidget {
  final Post post;
  final String docId; // [추가] DB 삭제용 문서 ID
  final String uid; // [추가] 작성자 본인 확인용
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  const PostItem({
    super.key,
    required this.post,
    required this.docId, // 필수
    required this.uid, // 필수
    required this.onDelete,
    required this.onBlock,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  bool _isSaved = false;
  int _likeCount = 72; // 실제로는 DB에서 가져와야 함

  // 게시글 삭제 함수 (DB 연동)
  Future<void> _deletePost() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.uid == widget.uid) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.docId)
            .delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("게시물이 삭제되었습니다.")));
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("삭제 실패")));
      }
    } else {
      // 내 글이 아님 -> 숨기기 처리 (로컬)
      widget.onDelete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시물이 숨겨졌습니다.")));
    }
  }

  void _showMoreOptions() {
    // 내 글인지 확인
    final isMyPost = FirebaseAuth.instance.currentUser?.uid == widget.uid;

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
            // 팔로우
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

            // 삭제 (내 글일 때만 표시) 또는 숨기기
            if (isMyPost)
              _buildOptionItem(
                Icons.delete_outline,
                "삭제하기",
                isDestructive: true,
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(); // DB 삭제 실행
                },
              )
            else
              _buildOptionItem(
                Icons.visibility_off_outlined,
                "숨기기",
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(); // 숨김 처리 실행
                },
              ),

            const Divider(height: 1),

            // 차단
            _buildOptionItem(
              Icons.block,
              "차단",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                widget.onBlock();
                _deletePost(); // 숨김 처리
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${widget.post.userName}님을 차단했습니다.")),
                );
              },
            ),
            const Divider(height: 1),

            // 신고
            _buildOptionItem(
              Icons.campaign_outlined,
              "신고",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showReportDialog();
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
        // 신고 로직 (실제로는 DB에 신고 기록)
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

        // 이미지 (★ 수정된 부분: URL 이미지와 로컬 이미지 구분)
        Container(
          width: double.infinity,
          height: 400,
          color: Colors.grey[200],
          child: _buildPostImage(),
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

              // 4. 보관함
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
              if (widget.post.title.isNotEmpty)
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

  // ★ [핵심] 이미지 처리 함수 (네트워크 URL vs 로컬 파일)
  Widget _buildPostImage() {
    final path = widget.post.imagePath;

    // 1. URL인 경우 (Firebase Storage)
    if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 50, color: Colors.grey),
      );
    }
    // 2. 로컬 파일인 경우
    else if (widget.post.isFile) {
      return Image.file(File(path), fit: BoxFit.cover);
    }
    // 3. 에셋 이미지인 경우 (기존 샘플 데이터)
    else {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        errorBuilder: (c, o, s) =>
            const Icon(Icons.image, size: 50, color: Colors.grey),
      );
    }
  }
}
