import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // DB 패키지
import 'community_detail_screen.dart';
import 'community_write_screen.dart';

// 커뮤니티 게시글 데이터 모델
class CommunityPost {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats; // "좋아요 · 댓글 · 조회수" 형태
  final String? imageUrl;
  final bool isFileImage;
  final String category;

  CommunityPost({
    required this.name,
    required this.location,
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    this.isFileImage = false,
    required this.category,
  });

  // ★ [추가] Firestore 문서(Document)를 객체로 변환하는 함수
  factory CommunityPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // 이미지 리스트에서 첫 번째 사진 가져오기 (없으면 null)
    List<dynamic> images = data['imageUrls'] ?? [];
    String? firstImage = images.isNotEmpty ? images[0] : null;

    // 통계 문자열 만들기 (좋아요 · 댓글 · 조회수)
    int likes = data['likeCount'] ?? 0;
    int comments = data['commentCount'] ?? 0;
    int views = data['viewCount'] ?? 0;

    return CommunityPost(
      name: data['writerName'] ?? '익명',
      location: data['location'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      stats: "$likes · $comments · $views",
      imageUrl: firstImage,
      category: data['category'] ?? 'general',
      isFileImage: false, // DB 이미지는 항상 URL(네트워크)입니다.
    );
  }
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _viewMode = 'split'; // split, post, companion
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 화면 보기 모드 변경
  void _toggleView(String mode) {
    setState(() {
      if (_viewMode == mode) {
        _viewMode = 'split';
      } else {
        _viewMode = mode;
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "게시글, 동행 찾기...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text(
                "커뮤니티",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
        actions: [
          // 글쓰기 버튼
          if (!_isSearching)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityWriteScreen(),
                  ),
                );
                // StreamBuilder가 알아서 업데이트하므로 별도 처리가 필요 없습니다.
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            ),

          // 검색 버튼
          IconButton(
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = "";
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: Colors.black,
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // ★ [핵심] DB 데이터를 실시간으로 받아오는 StreamBuilder
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts') // 'community_posts' 컬렉션 구독
            .orderBy('createdAt', descending: true) // 최신순 정렬
            .snapshots(),
        builder: (context, snapshot) {
          // 1. 로딩 중
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. 데이터 없음
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("등록된 게시글이 없습니다."));
          }

          // 3. 데이터 변환 (Snapshot -> List<CommunityPost>)
          final allDocs = snapshot.data!.docs;
          final allPosts = allDocs
              .map((doc) => CommunityPost.fromFirestore(doc))
              .toList();

          // 4. 검색어 필터링
          final filteredPosts = _searchQuery.isEmpty
              ? allPosts
              : allPosts.where((post) {
                  return post.title.contains(_searchQuery) ||
                      post.content.contains(_searchQuery) ||
                      post.name.contains(_searchQuery) ||
                      post.location.contains(_searchQuery);
                }).toList();

          // 5. 카테고리별 분류
          final generalPosts = filteredPosts
              .where((p) => p.category == 'general')
              .toList();
          final companionPosts = filteredPosts
              .where((p) => p.category == 'companion')
              .toList();

          // 6. 화면 구성 (기존 로직 유지)
          return Column(
            children: [
              // [섹션 1] 게시글 (General)
              if (_viewMode == 'split' || _viewMode == 'post')
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleView('post'),
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          child: _sectionHeader(
                            "게시글",
                            isExpanded: _viewMode == 'post',
                          ),
                        ),
                      ),
                      Expanded(
                        child: generalPosts.isEmpty
                            ? const Center(
                                child: Text(
                                  "게시글이 없습니다.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: generalPosts.length,
                                itemBuilder: (context, index) {
                                  return _postItem(
                                    context,
                                    post: generalPosts[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),

              if (_viewMode == 'split')
                const Divider(
                  thickness: 8,
                  height: 8,
                  color: Color(0xFFF5F5F5),
                ),

              // [섹션 2] 동행 (Companion)
              if (_viewMode == 'split' || _viewMode == 'companion')
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleView('companion'),
                        behavior: HitTestBehavior.translucent,
                        child: Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.only(top: 10.0, bottom: 5),
                          child: _sectionHeader(
                            "동행",
                            isExpanded: _viewMode == 'companion',
                            showArrow: true,
                          ),
                        ),
                      ),
                      Expanded(
                        child: companionPosts.isEmpty
                            ? const Center(
                                child: Text(
                                  "동행 글이 없습니다.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: companionPosts.length,
                                itemBuilder: (context, index) {
                                  return _postItem(
                                    context,
                                    post: companionPosts[index],
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    bool showViewAll = true,
    bool isExpanded = false,
    bool showArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (isExpanded || showArrow)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up : null,
                size: 20,
                color: Colors.grey,
              ),
            ),
          const Spacer(),
          if (showViewAll)
            const Text(
              "전체보기",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _postItem(BuildContext context, {required CommunityPost post}) {
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
                        const CircleAvatar(
                          radius: 12,
                          backgroundImage: AssetImage('assets/logo.png'),
                          backgroundColor: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          post.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite_border,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.stats.split(" · ")[0],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.stats.split(" · ")[1],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.near_me_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          post.stats.split(" · ")[2],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 이미지가 있을 때만 표시 (네트워크 이미지)
              if (post.imageUrl != null)
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
                        errorBuilder: (c, o, s) =>
                            const Icon(Icons.image, color: Colors.grey),
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
