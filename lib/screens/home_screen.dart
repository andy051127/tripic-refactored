import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:firebase_auth/firebase_auth.dart';
import 'community_screen.dart';
import 'travel_plan_screen.dart';
import 'photo_picker_screen.dart';
import 'message_list_screen.dart';
import 'chat_detail_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';
import 'other_user_profile_screen.dart';
import 'search_screen.dart';
import '../models/post_model.dart';
import '../widgets/comment_modal.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';

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

class HomeFeedPage extends StatefulWidget {
  const HomeFeedPage({super.key});

  @override
  State<HomeFeedPage> createState() => _HomeFeedPageState();
}

class _HomeFeedPageState extends State<HomeFeedPage> {
  Position? _currentPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    } catch (e) {
      // 위치 권한이 없거나 실패한 경우 기본 위치 (서울) 사용
      if (mounted) {
        setState(() {
          _currentPosition = Position(
            latitude: 37.5665,
            longitude: 126.9780,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

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
                'assets/tripicLogo.png',
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
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("오류 발생"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          // 전체 데이터를 Post 객체로 변환
          final allPosts = docs
              .map(
                (doc) =>
                    Post.fromMap(doc.data() as Map<String, dynamic>, doc.id),
              )
              .toList();

          // [수정됨] 홈 화면에는 'feed' 카테고리만 보여주도록 필터링
          // (커뮤니티 글은 'general' 또는 'companion' 이므로 제외됨)
          final feedPosts = allPosts
              .where((post) => post.category == 'feed')
              .toList();

          return ListView.builder(
            itemCount: feedPosts.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                        ),
                        child: _currentPosition == null
                            ? const Center(
                                child: CircularProgressIndicator(),
                              )
                            : Stack(
                                children: [
                                  GoogleMap(
                                    initialCameraPosition: CameraPosition(
                                      target: LatLng(
                                        _currentPosition!.latitude,
                                        _currentPosition!.longitude,
                                      ),
                                      zoom: 14,
                                    ),
                                    onMapCreated: (controller) {
                                      _mapController = controller;
                                    },
                                    myLocationEnabled: true,
                                    myLocationButtonEnabled: false,
                                    zoomControlsEnabled: false,
                                    mapToolbarEnabled: false,
                                    compassEnabled: false,
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.3),
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.3),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
                                                blurRadius: 4,
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

              final post = feedPosts[index - 1]; // 필터링된 리스트 사용

              return PostItem(
                post: post,
                currentUserId: FirebaseAuth.instance.currentUser?.uid ?? '',
                onDelete: () {
                  // 삭제 로직 (로컬 state만 갱신하는 것이 아니라 Firestore 삭제가 필요하지만, 일단 UI 갱신용)
                },
                onBlock: () {
                  // 차단 로직
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
  final String currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onBlock;

  const PostItem({
    super.key,
    required this.post,
    required this.currentUserId,
    required this.onDelete,
    required this.onBlock,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _showMap = false;
  int _likeCount = 0;
  String? _profileImageUrl;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
    _loadProfileImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileImage() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _profileImageUrl = userDoc.data()?['profileImage'];
        });
      }
    } catch (e) {
      // 프로필 이미지 로드 실패 시 기본 아이콘 사용
    }
  }

  void _navigateToProfile() {
    final isOwnPost = widget.post.uid == widget.currentUserId;
    if (isOwnPost) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(
            userName: widget.post.userName,
            profileImage: _profileImageUrl ?? '',
          ),
        ),
      );
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
          top: 20,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            _buildOptionItem(
              Icons.person_add_outlined,
              "팔로우",
              onTap: () async {
                Navigator.pop(context);
                try {
                  final firestoreService = FirestoreService();
                  await firestoreService.followUser(widget.post.uid);
                  globalFollowingCount.value++;
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("팔로우 했습니다!")),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("팔로우 실패: $e")),
                    );
                  }
                }
              },
            ),
            const Divider(height: 1),
            _buildOptionItem(
              Icons.visibility_off_outlined,
              "숨기기",
              onTap: () {
                Navigator.pop(context);
                widget.onDelete();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("게시물을 숨겼습니다.")));
              },
            ),
            const Divider(height: 1),
            _buildOptionItem(
              Icons.block,
              "차단",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                widget.onBlock();
                widget.onDelete();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("${widget.post.userName}님을 차단했습니다.")),
                );
              },
            ),
            const Divider(height: 1),
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
      ),
    );
  }

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
        widget.onDelete();
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: _navigateToProfile,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey,
                      backgroundImage: _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                          ? const Icon(Icons.person, color: Colors.white, size: 20)
                          : null,
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
                        if (widget.post.location.isNotEmpty)
                          Text(
                            widget.post.location,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                  ],
                ),
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
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 400,
              color: Colors.grey[200],
              child: () {
                // imageUrls가 있으면 사용, 없으면 imageUrl 사용
                final images = widget.post.imageUrls.isNotEmpty 
                    ? widget.post.imageUrls 
                    : (widget.post.imageUrl.isNotEmpty ? [widget.post.imageUrl] : []);
                
                // 이미지가 없는 경우 처리
                if (images.isEmpty) {
                  return const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                }
                
                // 단일 이미지 처리
                if (images.length == 1) {
                  final imagePath = images[0];
                  // 로컬 파일인 경우
                  if (widget.post.isFile && File(imagePath).existsSync()) {
                    return Image.file(
                      File(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  // 네트워크 이미지인 경우
                  return Image.network(
                    imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, o, s) => const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  );
                }
                
                // 여러 이미지 처리
                return PageView.builder(
                  controller: _pageController,
                  itemCount: images.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final imagePath = images[index];
                    // 로컬 파일인 경우
                    if (widget.post.isFile && File(imagePath).existsSync()) {
                      return Image.file(
                        File(imagePath),
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    }
                    // 네트워크 이미지인 경우
                    return Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (c, o, s) => const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                    );
                  },
                );
              }(),
            ),
            // 이미지 인디케이터 (여러 이미지가 있을 때만 표시)
            if (widget.post.imageUrls.isNotEmpty && widget.post.imageUrls.length > 1)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1}/${widget.post.imageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (_showMap && widget.post.latitude != null && widget.post.longitude != null)
              Container(
                width: double.infinity,
                height: 400,
                color: Colors.black.withOpacity(0.8),
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          widget.post.latitude!,
                          widget.post.longitude!,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId(widget.post.id),
                          position: LatLng(
                            widget.post.latitude!,
                            widget.post.longitude!,
                          ),
                          infoWindow: InfoWindow(
                            title: widget.post.userName,
                            snippet: widget.post.title,
                          ),
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () {
                          setState(() {
                            _showMap = false;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isLiked = !_isLiked;
                    _isLiked ? _likeCount++ : _likeCount--;
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
                      builder: (context) => ChatDetailScreen(
                        chatPartnerName: widget.post.userName,
                      ),
                    ),
                  );
                },
                child: const Icon(Icons.near_me_outlined, size: 28),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (widget.post.latitude != null && widget.post.longitude != null) {
                    setState(() {
                      _showMap = !_showMap;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('위치가 선택되지 않았습니다')),
                    );
                  }
                },
                child: const Icon(Icons.map_outlined, size: 28),
              ),
              const SizedBox(width: 16),
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
                      widget.post.imageUrl,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("게시물이 보관함에 저장되었습니다.")),
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
