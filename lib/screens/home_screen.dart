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
import 'map_screen.dart';
import 'profile_screen.dart';
import 'other_user_profile_screen.dart';
import 'search_screen.dart';
import 'share_post_screen.dart';
import 'notification_screen.dart';
import '../models/post_model.dart';
import '../models/notification_model.dart';
import '../widgets/comment_modal.dart';
import '../models/activity_model.dart';
import '../models/travel_plan_model.dart';
import '../services/firestore_service.dart';
import '../services/notification_service.dart';
import 'travel_plan_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Firestore에서 사용자 데이터 불러오기
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final data = userDoc.data();
          if (data != null) {
            // 전역 변수 업데이트
            globalUserName.value =
                data['userName'] ??
                data['username'] ??
                data['name'] ??
                'Unknown';
            globalUserRealName.value = data['realName'] ?? '';
            globalUserBio.value = data['bio'] ?? 'Traveler ✈️';
            globalUserEmail.value = data['email'] ?? user.email ?? '';
            globalUserPhone.value = data['phoneNumber'] ?? '';

            // 프로필 이미지가 있으면 업데이트
            if (data['profileImage'] != null &&
                data['profileImage'].toString().isNotEmpty) {
              globalProfileImage.value = data['profileImage'];
              isProfileImageFile.value = false; // 네트워크 이미지
            }
          }
        }
      } catch (e) {
        print('사용자 데이터 로드 실패: $e');
      }
    }
  }

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
  final ScrollController _scrollController = ScrollController();
  String? _selectedCountry; // 선택된 국가

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
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
          child: GestureDetector(
            onTap: () {
              // 페이지 새로고침 및 맨 위로 스크롤
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              }
            },
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
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            ),
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
          ),
          // 알림 아이콘 with badge
          Stack(
            children: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationScreen(),
                  ),
                ),
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.black,
                  size: 28,
                ),
              ),
              // 읽지 않은 알림 개수 배지
              StreamBuilder<int>(
                stream: NotificationService().getUnreadCountStream(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  if (unreadCount == 0) return const SizedBox.shrink();
                  
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
            ],
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
            var feedPosts = allPosts
                .where((post) => post.category == 'feed')
                .toList();

            // 차단/숨김 필터링 적용
            return FutureBuilder<List<Post>>(
              future: _filterBlockedAndHiddenPosts(feedPosts, firestoreService),
              builder: (context, filterSnapshot) {
                // 로딩 중이더라도 이전 데이터가 있으면 계속 표시
                final filteredPosts = filterSnapshot.data ?? feedPosts;

                return ListView.builder(
                  controller: _scrollController,
                  addAutomaticKeepAlives: true, // 자동으로 위젯 상태 유지
                  addRepaintBoundaries: true, // 리페인트 최적화
                  cacheExtent: 500, // 화면 밖 위젯도 캐시
                  itemCount: filteredPosts.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () async {
                              // 지도 화면으로 이동하여 국가 선택
                              final selectedCountry = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MapScreen(),
                                ),
                              );

                              // 선택된 국가가 있으면 상태 업데이트
                              if (selectedCountry != null &&
                                  selectedCountry is String) {
                                setState(() {
                                  _selectedCountry = selectedCountry;
                                });
                              }
                            },
                            child: Container(
                              width: double.infinity,
                              height: 120,
                              decoration: BoxDecoration(color: Colors.blue[50]),
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
                          // 선택된 국가 배너
                          if (_selectedCountry != null)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              color: Colors.blue[50],
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.filter_alt,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '$_selectedCountry 게시물만 보기',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _selectedCountry = null;
                                      });
                                    },
                                    child: const Text(
                                      '전체 보기',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    }

                    final post = filteredPosts[index - 1];
                    return PostItem(
                      key: ValueKey(post.id),
                      post: post,
                      currentUserId:
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                      onDelete: () {
                        // 삭제 로직
                      },
                      onBlock: () {
                        setState(() {
                          // UI 갱신을 위해 setState 호출
                        });
                      },
                    );
                  },
                );
              },
            );
          },
      ),
    );
  }

  Future<List<Post>> _filterBlockedAndHiddenPosts(
    List<Post> posts,
    FirestoreService firestoreService,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return posts;

      final hiddenPostIds = await firestoreService.getHiddenPostIds();
      final blockedUserIds = await firestoreService.getBlockedUserIds();

      // 프라이버시 설정 확인을 위한 게시물 필터링
      final List<Post> filteredPosts = [];

      for (final post in posts) {
        // 숨긴 게시물 제외
        if (hiddenPostIds.contains(post.id)) continue;

        // 차단한 사용자의 게시물 제외
        if (blockedUserIds.contains(post.uid)) continue;

        // 선택된 국가가 있으면 해당 국가 게시물만 표시
        if (_selectedCountry != null && post.country != _selectedCountry) {
          continue;
        }

        // 자신의 게시물은 항상 표시
        if (post.uid == currentUser.uid) {
          filteredPosts.add(post);
          continue;
        }

        // 게시물 작성자의 프라이버시 설정 확인
        final canView = await _checkPrivacySettings(post.uid, currentUser.uid);
        if (canView) {
          filteredPosts.add(post);
        }
      }

      return filteredPosts;
    } catch (e) {
      print('게시물 필터링 실패: $e');
      return posts;
    }
  }

  // 프라이버시 설정 확인 함수
  Future<bool> _checkPrivacySettings(
    String postAuthorUid,
    String currentUserId,
  ) async {
    try {
      // 게시물 작성자의 프라이버시 설정 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(postAuthorUid)
          .get();

      if (!userDoc.exists) return true; // 기본값: 공개

      final userData = userDoc.data();
      if (userData == null) return true;

      final privacySettings = userData['privacySettings'];
      if (privacySettings == null) return true; // 설정이 없으면 공개

      final isPublicToFollowers =
          privacySettings['isPublicToFollowers'] ?? true;
      final isPublicToMutuals = privacySettings['isPublicToMutuals'] ?? false;
      final selectedFriends = List<String>.from(
        privacySettings['selectedFollowingFriends'] ?? [],
      );

      // 1. 모든 팔로워에게 공개
      if (isPublicToFollowers) {
        // 현재 사용자가 작성자를 팔로우하고 있는지 확인
        final followDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(postAuthorUid)
            .get();
        return followDoc.exists;
      }

      // 2. 맞팔로우한 사람에게만 공개
      if (isPublicToMutuals) {
        // 현재 사용자가 작성자를 팔로우하는지 확인
        final iFollowAuthor = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .collection('following')
            .doc(postAuthorUid)
            .get()
            .then((doc) => doc.exists);

        // 작성자가 현재 사용자를 팔로우하는지 확인
        final authorFollowsMe = await FirebaseFirestore.instance
            .collection('users')
            .doc(postAuthorUid)
            .collection('following')
            .doc(currentUserId)
            .get()
            .then((doc) => doc.exists);

        return iFollowAuthor && authorFollowsMe;
      }

      // 3. 특정 사람에게만 공개
      if (selectedFriends.isNotEmpty) {
        return selectedFriends.contains(currentUserId);
      }

      // 아무 설정도 없으면 비공개 (false)
      return false;
    } catch (e) {
      print('프라이버시 설정 확인 실패: $e');
      return true; // 에러 발생 시 기본적으로 보이도록
    }
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

class _PostItemState extends State<PostItem>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 위젯 상태 유지

  bool _isLiked = false;
  bool _isSaved = false;
  bool _showMap = false;
  bool _isFollowing = false;
  String? _profileImageUrl;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();
  final FirestoreService _firestoreService = FirestoreService();

  // 국기 매핑
  final Map<String, String> _countryFlags = {
    '대한민국': '🇰🇷',
    '일본': '🇯🇵',
    '중국': '🇨🇳',
    '대만': '🇹🇼',
    '홍콩': '🇭🇰',
    '마카오': '🇲🇴',
    '싱가포르': '🇸🇬',
    '태국': '🇹🇭',
    '베트남': '🇻🇳',
    '필리핀': '🇵🇭',
    '말레이시아': '🇲🇾',
    '인도네시아': '🇮🇩',
    '미얀마': '🇲🇲',
    '캄보디아': '🇰🇭',
    '라오스': '🇱🇦',
    '인도': '🇮🇳',
    '네팔': '🇳🇵',
    '몰디브': '🇲🇻',
    '스리랑카': '🇱🇰',
    '미국': '🇺🇸',
    '캐나다': '🇨🇦',
    '멕시코': '🇲🇽',
    '쿠바': '🇨🇺',
    '브라질': '🇧🇷',
    '아르헨티나': '🇦🇷',
    '페루': '🇵🇪',
    '칠레': '🇨🇱',
    '영국': '🇬🇧',
    '프랑스': '🇫🇷',
    '이탈리아': '🇮🇹',
    '스페인': '🇪🇸',
    '독일': '🇩🇪',
    '네덜란드': '🇳🇱',
    '벨기에': '🇧🇪',
    '스위스': '🇨🇭',
    '오스트리아': '🇦🇹',
    '체코': '🇨🇿',
    '헝가리': '🇭🇺',
    '폴란드': '🇵🇱',
    '그리스': '🇬🇷',
    '터키': '🇹🇷',
    '포르투갈': '🇵🇹',
    '아일랜드': '🇮🇪',
    '노르웨이': '🇳🇴',
    '스웨덴': '🇸🇪',
    '덴마크': '🇩🇰',
    '핀란드': '🇫🇮',
    '아이슬란드': '🇮🇸',
    '러시아': '🇷🇺',
    '호주': '🇦🇺',
    '뉴질랜드': '🇳🇿',
    '이집트': '🇪🇬',
    '모로코': '🇲🇦',
    '남아프리카공화국': '🇿🇦',
    '케냐': '🇰🇪',
    '탄자니아': '🇹🇿',
    '아랍에미리트': '🇦🇪',
    '사우디아라비아': '🇸🇦',
    '카타르': '🇶🇦',
    '요르단': '🇯🇴',
    '이스라엘': '🇮🇱',
  };

  // 국가 코드 매핑
  final Map<String, String> _countryCodeMap = {
    '대한민국': 'KOR',
    '일본': 'JPN',
    '중국': 'CHN',
    '대만': 'TWN',
    '홍콩': 'HKG',
    '마카오': 'MAC',
    '싱가포르': 'SGP',
    '태국': 'THA',
    '베트남': 'VNM',
    '필리핀': 'PHL',
    '말레이시아': 'MYS',
    '인도네시아': 'IDN',
    '미얀마': 'MMR',
    '캄보디아': 'KHM',
    '라오스': 'LAO',
    '인도': 'IND',
    '네팔': 'NPL',
    '몰디브': 'MDV',
    '스리랑카': 'LKA',
    '미국': 'USA',
    '캐나다': 'CAN',
    '멕시코': 'MEX',
    '쿠바': 'CUB',
    '브라질': 'BRA',
    '아르헨티나': 'ARG',
    '페루': 'PER',
    '칠레': 'CHL',
    '영국': 'GBR',
    '프랑스': 'FRA',
    '이탈리아': 'ITA',
    '스페인': 'ESP',
    '독일': 'DEU',
    '네덜란드': 'NLD',
    '벨기에': 'BEL',
    '스위스': 'CHE',
    '오스트리아': 'AUT',
    '체코': 'CZE',
    '헝가리': 'HUN',
    '폴란드': 'POL',
    '그리스': 'GRC',
    '터키': 'TUR',
    '포르투갈': 'PRT',
    '아일랜드': 'IRL',
    '노르웨이': 'NOR',
    '스웨덴': 'SWE',
    '덴마크': 'DNK',
    '핀란드': 'FIN',
    '아이슬란드': 'ISL',
    '러시아': 'RUS',
    '호주': 'AUS',
    '뉴질랜드': 'NZL',
    '이집트': 'EGY',
    '모로코': 'MAR',
    '남아프리카공화국': 'ZAF',
    '케냐': 'KEN',
    '탄자니아': 'TZA',
    '아랍에미리트': 'ARE',
    '사우디아라비아': 'SAU',
    '카타르': 'QAT',
    '요르단': 'JOR',
    '이스라엘': 'ISR',
  };

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _checkIfLiked();
    _checkIfSaved();
    _checkIfFollowing();
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

  Future<void> _checkIfLiked() async {
    try {
      final isLiked = await _firestoreService.isPostLiked(widget.post.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('좋아요 확인 실패: $e');
    }
  }

  Future<void> _checkIfSaved() async {
    try {
      final isSaved = await _firestoreService.isPostSaved(widget.post.id);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      print('보관 상태 확인 실패: $e');
    }
  }

  Future<void> _checkIfFollowing() async {
    try {
      final isFollowing = await _firestoreService.isFollowing(widget.post.uid);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('팔로우 상태 확인 실패: $e');
    }
  }

  Future<void> _toggleLike() async {
    // UI 즉시 업데이트
    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.id);
        // 좋아요를 누른 경우 활동 내역에 저장
        addActivity(
          ActivityType.like,
          widget.post.title,
          "게시물에 좋아요를 눌렀습니다.",
          widget.post.imageUrl,
          postId: widget.post.id,
        );
        
        // 알림 생성 (게시물 작성자에게)
        await NotificationService().createNotification(
          userId: widget.post.uid,
          type: NotificationType.like,
          postId: widget.post.id,
          postImageUrl: widget.post.imageUrl,
        );
      } else {
        await _firestoreService.unlikePost(widget.post.id);
      }
    } catch (e) {
      // 오류 발생 시 상태 되돌리기
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  Future<void> _toggleSave() async {
    // UI 즉시 업데이트
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await _firestoreService.savePost(widget.post.id);
        addActivity(
          ActivityType.save,
          widget.post.title,
          "보관함에 저장했습니다.",
          widget.post.imageUrl,
          postId: widget.post.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("게시물이 보관함에 저장되었습니다.")));
        }
      } else {
        await _firestoreService.unsavePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("보관함에서 삭제되었습니다.")));
        }
      }
    } catch (e) {
      // 오류 발생 시 상태 되돌리기
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  void _navigateToProfile() {
    final isOwnPost = widget.post.uid == widget.currentUserId;
    if (isOwnPost) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
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

  Future<void> _navigateToTaggedProfile(String targetName) async {
    if (targetName.isEmpty) return;

    try {
      // Firestore에서 userName으로 사용자 정보 조회
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userName', isEqualTo: targetName)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final targetUid = userQuery.docs.first.id;

        // 본인 프로필인지 확인
        if (targetUid == widget.currentUserId) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                userName: userData['userName'] ?? targetName,
                profileImage: userData['profileImage'] ?? '',
              ),
            ),
          );
        }
      } else {
        // 사용자를 찾을 수 없는 경우
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('사용자를 찾을 수 없습니다.')));
      }
    } catch (e) {
      print('태그된 사용자 프로필 탐색 오류: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필을 불러올 수 없습니다.')));
    }
  }

  List<Widget> _buildTaggedFriendWidgets(String taggedFriends) {
    final names = taggedFriends.split(',').map((e) => e.trim()).toList();
    final List<Widget> widgets = [];

    for (int i = 0; i < names.length; i++) {
      final name = names[i];

      // 각 이름을 클릭 가능한 위젯으로 생성
      widgets.add(
        GestureDetector(
          onTap: () => _navigateToTaggedProfile(name),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      // 마지막 이름이 아니면 쉼표 추가
      if (i < names.length - 1) {
        widgets.add(
          const Text(", ", style: TextStyle(fontSize: 12, color: Colors.grey)),
        );
      }
    }

    return widgets;
  }

  // 여행 계획 배너 표시
  void _showTravelPlanBanner() async {
    if (widget.post.travelPlanId == null || widget.post.travelPlanId!.isEmpty) {
      return;
    }

    try {
      // Firestore에서 여행 계획 조회
      final planDoc = await FirebaseFirestore.instance
          .collection('travel_plans')
          .doc(widget.post.travelPlanId)
          .get();

      if (!planDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('여행 계획을 찾을 수 없습니다')));
        }
        return;
      }

      final plan = TravelPlan.fromMap(
        planDoc.data() as Map<String, dynamic>,
        planDoc.id,
      );

      if (!mounted) return;

      // 배너 모달 표시
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '여행 계획',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelPlanDetailScreen(plan: plan),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 메인 컨텐츠
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 여행 계획 아이콘 및 제목
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.flight_takeoff,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    plan.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // 여행 정보
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plan.country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plan.date,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // 하단 바 (자연스러운 마감)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[200]!.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '탭하여 여행 계획 보기',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  void _showMoreOptions() {
    final isOwnPost = widget.post.uid == widget.currentUserId;

    print('🔍 _showMoreOptions 호출됨');
    print('   현재 사용자 ID: ${widget.currentUserId}');
    print('   게시물 작성자 ID: ${widget.post.uid}');
    print('   내 게시물 여부: $isOwnPost');

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom:
              MediaQuery.of(context).viewInsets.bottom +
              MediaQuery.of(context).padding.bottom +
              20,
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
              // 내 게시물인 경우 삭제하기만 표시
              if (isOwnPost)
                _buildOptionItem(
                  Icons.delete_outline,
                  "삭제하기",
                  isDestructive: true,
                  onTap: () async {
                    print('🔘 삭제하기 버튼 클릭됨');

                    // context를 미리 저장
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);

                    navigator.pop(); // 모달 닫기

                    print('📋 삭제 확인 다이얼로그 표시 중...');
                    // 삭제 확인 다이얼로그
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('게시물 삭제'),
                        content: const Text('이 게시물을 삭제하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              print('❌ 취소 버튼 클릭됨');
                              Navigator.pop(dialogContext, false);
                            },
                            child: const Text('취소'),
                          ),
                          TextButton(
                            onPressed: () {
                              print('✅ 삭제 확인 버튼 클릭됨');
                              Navigator.pop(dialogContext, true);
                            },
                            child: const Text(
                              '삭제',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    print('📊 confirm 값: $confirm');

                    if (confirm == true) {
                      print('✅ 삭제 조건 충족 - 삭제 시작');
                      try {
                        print('🗑️ 게시물 삭제 시작: ${widget.post.id}');
                        print('현재 사용자 UID: ${widget.currentUserId}');
                        print('게시물 작성자 UID: ${widget.post.uid}');

                        await _firestoreService.deletePost(widget.post.id);

                        print('✅ 게시물 삭제 완료');

                        widget.onDelete(); // UI 갱신

                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('게시물이 삭제되었습니다.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e, stackTrace) {
                        print('❌ 게시물 삭제 실패: $e');
                        print('스택 트레이스: $stackTrace');
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('삭제 실패: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    } else {
                      print('⚠️ 삭제 취소됨');
                    }
                  },
                )
              // 다른 사람의 게시물인 경우 기존 옵션 표시
              else ...[
                _buildOptionItem(
                  _isFollowing
                      ? Icons.person_remove_outlined
                      : Icons.person_add_outlined,
                  _isFollowing ? "팔로우 취소" : "팔로우",
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      final firestoreService = FirestoreService();
                      if (_isFollowing) {
                        await firestoreService.unfollowUser(widget.post.uid);
                        setState(() {
                          _isFollowing = false;
                        });
                        globalFollowingCount.value--;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("팔로우를 취소했습니다.")),
                          );
                        }
                      } else {
                        await firestoreService.followUser(widget.post.uid);
                        setState(() {
                          _isFollowing = true;
                        });
                        globalFollowingCount.value++;
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("팔로우 했습니다!")),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("오류가 발생했습니다: $e")),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                _buildOptionItem(
                  Icons.visibility_off_outlined,
                  "숨기기",
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _firestoreService.hidePost(widget.post.id);
                      widget.onDelete();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("게시물을 숨겼습니다.")),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("오류가 발생했습니다: $e")),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                _buildOptionItem(
                  Icons.block,
                  "차단",
                  isDestructive: true,
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await _firestoreService.blockUser(widget.post.uid);
                      widget.onBlock();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("${widget.post.userName}님을 차단했습니다."),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("오류가 발생했습니다: $e")),
                        );
                      }
                    }
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
      onTap: () async {
        if (!mounted) return;
        Navigator.pop(context);

        try {
          // 신고 시 자동으로 차단 처리
          await _firestoreService.blockUser(widget.post.uid);
          widget.onBlock();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("신고가 완료되었으며, 해당 사용자를 차단했습니다.")),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("오류가 발생했습니다: $e")));
          }
        }
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
    super.build(context); // AutomaticKeepAliveClientMixin 필수 호출
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
                      backgroundImage:
                          _profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('assets/basic_profile.png')
                                as ImageProvider,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            if (widget.post.country != null &&
                                widget.post.country!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Row(
                                  children: [
                                    Text(
                                      _countryFlags[widget.post.country] ??
                                          '🌍',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      _countryCodeMap[widget.post.country] ??
                                          '',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (widget.post.location.isNotEmpty)
                          Text(
                            widget.post.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        if (widget.post.taggedFriend != null &&
                            widget.post.taggedFriend!.isNotEmpty)
                          Wrap(
                            spacing: 4,
                            children: [
                              const Text(
                                "함께: ",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              ..._buildTaggedFriendWidgets(
                                widget.post.taggedFriend!,
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // 여행 계획 보기 버튼
              IconButton(
                onPressed: () {
                  if (widget.post.travelPlanId != null &&
                      widget.post.travelPlanId!.isNotEmpty) {
                    _showTravelPlanBanner();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('이 게시물에는 여행 계획이 연결되어 있지 않습니다'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.edit_note, color: Colors.blue),
                iconSize: 28,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
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
                    : (widget.post.imageUrl.isNotEmpty
                          ? [widget.post.imageUrl]
                          : []);

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
            if (widget.post.imageUrls.isNotEmpty &&
                widget.post.imageUrls.length > 1)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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
            if (_showMap &&
                widget.post.latitude != null &&
                widget.post.longitude != null)
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
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
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
              // 좋아요 StreamBuilder
              StreamBuilder<int>(
                stream: _firestoreService.getLikeCountStream(widget.post.id),
                builder: (context, snapshot) {
                  final likeCount = snapshot.data ?? widget.post.likeCount;

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          size: 28,
                          color: _isLiked ? Colors.red : Colors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$likeCount",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              // 댓글 StreamBuilder
              StreamBuilder<int>(
                stream: _firestoreService.getCommentCountStream(widget.post.id),
                builder: (context, snapshot) {
                  final commentCount = snapshot.data ?? 0;

                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            useSafeArea: true,
                            builder: (context) => CommentModal(
                              postId: widget.post.id,
                              postTitle: widget.post.title,
                              postImage: widget.post.imageUrl,
                              postAuthorId: widget.post.uid,
                            ),
                          );
                        },
                        child: const Icon(Icons.chat_bubble_outline, size: 28),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "$commentCount",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SharePostScreen(post: widget.post),
                    ),
                  );
                },
                child: const Icon(Icons.near_me_outlined, size: 28),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  if (widget.post.latitude != null &&
                      widget.post.longitude != null) {
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
                onTap: _toggleSave,
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
