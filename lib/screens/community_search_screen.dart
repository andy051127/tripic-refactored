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
      // Firestore에서 general 또는 companion 카테고리의 게시물 가져오기
      final generalSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: 'general')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final companionSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('category', isEqualTo: 'companion')
          .orderBy('createdAt', descending: true)
          .limit(100)
          .get();

      final allDocs = [...generalSnapshot.docs, ...companionSnapshot.docs];
      
      // 검색어로 필터링 (userName 또는 title에 포함되면 결과에 추가)
      final searchLower = query.toLowerCase();
      final filteredPosts = allDocs.where((doc) {
        final data = doc.data();
        final userName = (data['userName'] ?? '').toString().toLowerCase();
        final title = (data['title'] ?? '').toString().toLowerCase();
        return userName.contains(searchLower) || title.contains(searchLower);
      }).map((doc) {
        final data = doc.data();
        final likesCount = data['likesCount'] ?? 0;
        final commentsCount = data['commentsCount'] ?? 0;
        final views = data['views'] ?? 0;
        final stats = '$likesCount · $commentsCount · $views';
        
        return CommunityPost(
          id: doc.id,
          uid: data['uid'] ?? '',
          name: data['userName'] ?? '',
          location: data['location'] ?? '',
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          stats: stats,
          imageUrl: data['imageUrl'],
          createdAt: data['createdAt'] != null
              ? (data['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          category: data['category'] ?? '',
          travelPlanId: data['travelPlanId'],
          travelPlanTitle: data['travelPlanTitle'],
          travelPlanDate: data['travelPlanDate'],
          travelPlanCountry: data['travelPlanCountry'],
          userProfileImage: data['userProfileImage'],
        );
      }).toList();

      // createdAt 기준 내림차순 정렬
      filteredPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _searchResults = filteredPosts;
        _isSearching = false;
      });
    } catch (e) {
      print('검색 오류: $e');
      setState(() {
        _isSearching = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('검색 중 오류가 발생했습니다')),
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
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '사용자명 또는 게시물 제목으로 검색',
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
                            backgroundColor: Colors.grey,
                            backgroundImage: post.userProfileImage != null &&
                                    post.userProfileImage!.isNotEmpty
                                ? NetworkImage(post.userProfileImage!)
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
