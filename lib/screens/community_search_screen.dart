import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_detail_screen.dart';
import 'profile_screen.dart';
import 'other_user_profile_screen.dart';

// 커뮤니티 게시글 데이터 모델
class CommunityPost {
  final String id;
  final String uid;
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final DateTime createdAt;
  final String category;
  final String? travelPlanId;
  final String? travelPlanTitle;
  final String? travelPlanDate;
  final String? travelPlanCountry;
  final String? userProfileImage;

  CommunityPost({
    required this.id,
    required this.uid,
    required this.name,
    required this.location,
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    required this.createdAt,
    required this.category,
    this.travelPlanId,
    this.travelPlanTitle,
    this.travelPlanDate,
    this.travelPlanCountry,
    this.userProfileImage,
  });
}

class CommunitySearchScreen extends StatefulWidget {
  const CommunitySearchScreen({Key? key}) : super(key: key);

  @override
  State<CommunitySearchScreen> createState() => _CommunitySearchScreenState();
}

class _CommunitySearchScreenState extends State<CommunitySearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CommunityPost> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    // 검색어 변경 리스너 추가 (실시간 검색)
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    try {
      final searchLower = query.toLowerCase().trim();
      final List<CommunityPost> allPosts = [];

      print('검색 시작: "$searchLower"');

      // posts 컬렉션에서 모든 커뮤니티 게시물 가져오기
      final querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      print('전체 게시물 수: ${querySnapshot.docs.length}');

      int generalCount = 0;
      int companionCount = 0;
      int matchCount = 0;

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final category = data['category'] ?? '';
        
        // general 또는 companion 카테고리만 검색
        if (category != 'general' && category != 'companion') {
          continue;
        }

        if (category == 'general') generalCount++;
        if (category == 'companion') companionCount++;

        final userName = (data['userName'] ?? '').toString().toLowerCase();
        final title = (data['title'] ?? '').toString().toLowerCase();
        final content = (data['content'] ?? '').toString().toLowerCase();
        
        // 검색어가 userName, title, content 중 하나에라도 포함되면 결과에 추가
        if (userName.contains(searchLower) || 
            title.contains(searchLower) || 
            content.contains(searchLower)) {
          
          matchCount++;
          
          final likesCount = data['likesCount'] ?? 0;
          final commentsCount = data['commentsCount'] ?? 0;
          final views = data['views'] ?? 0;
          final stats = '$likesCount · $commentsCount · $views';
          
          // 게시물에서 userProfileImage가 없으면 users 컬렉션에서 가져오기
          String? userProfileImage = data['userProfileImage'];
          final postUid = data['uid'] ?? '';
          
          if ((userProfileImage == null || userProfileImage.isEmpty) && postUid.isNotEmpty) {
            try {
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(postUid)
                  .get();
              
              if (userDoc.exists) {
                userProfileImage = userDoc.data()?['profileImage'] ?? '';
                print('사용자 $userName의 프로필 이미지: $userProfileImage');
              }
            } catch (e) {
              print('프로필 이미지 로드 실패: $e');
            }
          }
          
          allPosts.add(CommunityPost(
            id: doc.id,
            uid: postUid,
            name: data['userName'] ?? '알 수 없음',
            location: data['location'] ?? '',
            title: data['title'] ?? '',
            content: data['content'] ?? '',
            stats: stats,
            imageUrl: data['imageUrl'],
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            category: category,
            travelPlanId: data['travelPlanId'],
            travelPlanTitle: data['travelPlanTitle'],
            travelPlanDate: data['travelPlanDate'],
            travelPlanCountry: data['travelPlanCountry'],
            userProfileImage: userProfileImage,
          ));
        }
      }

      print('카테고리별 게시물 수 - general: $generalCount, companion: $companionCount');
      print('검색 결과: $matchCount개 매칭');

      // createdAt 기준 내림차순 정렬
      allPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _searchResults = allPosts;
        _isSearching = false;
      });

    } catch (e, stackTrace) {
      print('검색 오류: $e');
      print('스택 트레이스: $stackTrace');
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('커뮤니티 검색'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // 검색 입력 필드
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '사용자명, 제목, 내용으로 검색',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _performSearch('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                    onSubmitted: _performSearch,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      _performSearch(_searchController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('검색'),
                ),
              ],
            ),
          ),

          // 검색 결과
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator())
                : _hasSearched
                    ? _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  '검색 결과가 없습니다',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final post = _searchResults[index];
                              return _buildPostItem(post);
                            },
                          )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '사용자명 또는 게시물 제목으로 검색해보세요',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostItem(CommunityPost post) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              name: post.name,
              location: post.location,
              title: post.title,
              content: post.content,
              stats: post.stats,
              imageUrl: post.imageUrl,
              createdAt: post.createdAt,
              postUid: post.uid,
              postId: post.id,
              category: post.category,
              travelPlanId: post.travelPlanId,
              travelPlanTitle: post.travelPlanTitle,
              travelPlanDate: post.travelPlanDate,
              travelPlanCountry: post.travelPlanCountry,
              userProfileImage: post.userProfileImage,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // 프로필 이미지
                        GestureDetector(
                          onTap: () {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser != null && currentUser.uid == post.uid) {
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
                                    userId: post.uid,
                                    userName: post.name,
                                    profileImage: post.userProfileImage ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: post.userProfileImage != null &&
                                    post.userProfileImage!.isNotEmpty
                                ? NetworkImage(post.userProfileImage!) as ImageProvider
                                : null,
                            onBackgroundImageError: post.userProfileImage != null &&
                                    post.userProfileImage!.isNotEmpty
                                ? (exception, stackTrace) {
                                    print('프로필 이미지 로드 실패: ${post.userProfileImage}');
                                  }
                                : null,
                            child: post.userProfileImage == null ||
                                    post.userProfileImage!.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser != null && currentUser.uid == post.uid) {
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
                                    userId: post.uid,
                                    userName: post.name,
                                    profileImage: post.userProfileImage ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            post.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (post.location.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              post.location,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF424242),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.grey[200],
                      width: 80,
                      height: 80,
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Icon(Icons.image),
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
