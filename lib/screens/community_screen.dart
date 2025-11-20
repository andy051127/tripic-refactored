import 'package:flutter/material.dart';
import 'community_detail_screen.dart';
import 'community_write_screen.dart'; // 작성 화면 import

// 커뮤니티 게시글 데이터 모델 (카테고리 추가됨)
class CommunityPost {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final bool isFileImage;
  final String category; // 'general' (게시글) 또는 'companion' (동행)

  CommunityPost({
    required this.name,
    required this.location,
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    this.isFileImage = false,
    required this.category, // 필수 항목
  });
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

  // 통합된 게시글 데이터 리스트
  final List<CommunityPost> _allPosts = [
    // [게시글] 데이터
    CommunityPost(
      category: 'general',
      name: "leeeee_kh",
      location: "San Diego, USA",
      title: "씨월드 입장권 팝니다",
      content: "1월 31일 까지 사용 가능한 씨월드 입장권 팝니다!\n3장 있고 개당 30달러에 판매해요",
      stats: "72 · 21 · 47",
      imageUrl: "https://via.placeholder.com/300",
    ),
    CommunityPost(
      category: 'general',
      name: "maeng___gu",
      location: "Tokyo, Japan",
      title: "다이토구에 집 알아보는 중인데요",
      content: "혹시 다이토구 살아보신 분 계신가요?\n학군이랑 주변 인프라가 궁금하네요.....",
      stats: "13 · 25 · 1",
    ),
    CommunityPost(
      category: 'general',
      name: "civa_mom",
      location: "Kota Kinabalu, Malaysia",
      title: "코타키나발루에서 그랩 외 택시 타지마세요!",
      content: "사람을 호구로 아는지 가격을 몇 배로 부르네요..\n어이가 없어가지고 얘기하다 다툼으로 이어져 경찰서...",
      stats: "33 · 15 · 12",
      imageUrl: "https://via.placeholder.com/300",
    ),
    // [동행] 데이터 (기존 더미 데이터 통합)
    CommunityPost(
      category: 'companion',
      name: "leeeee_kh",
      location: "California, USA",
      title: "조슈아트리 로드트립 동행 구해요",
      content: "11월 5일 부터 4일간 로드트립 동행 하실 분 구합니다!\n샌디 -> 조슈아 -> LA 순으로 이동 예정이에요",
      stats: "21 · 12 · 2",
    ),
    CommunityPost(
      category: 'companion',
      name: "maeng___gu",
      location: "Osaka, Japan",
      title: "오사카 동행 20대 초중반 남성 구함",
      content: "남성들끼리 편하게 가려고 합니다.\n도쿄에서 신칸센으로 이동 예정이에요.",
      stats: "72 · 21 · 47",
      imageUrl: "https://via.placeholder.com/300",
    ),
  ];

  // 검색어로 필터링된 전체 리스트
  List<CommunityPost> get _searchResults {
    if (_searchQuery.isEmpty) {
      return _allPosts;
    } else {
      return _allPosts.where((post) {
        return post.title.contains(_searchQuery) ||
            post.content.contains(_searchQuery) ||
            post.name.contains(_searchQuery) ||
            post.location.contains(_searchQuery);
      }).toList();
    }
  }

  // 화면에 보여줄 '게시글' 섹션 데이터
  List<CommunityPost> get _generalPosts =>
      _searchResults.where((p) => p.category == 'general').toList();

  // 화면에 보여줄 '동행' 섹션 데이터
  List<CommunityPost> get _companionPosts =>
      _searchResults.where((p) => p.category == 'companion').toList();

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
          if (!_isSearching)
            IconButton(
              onPressed: () async {
                final newPost = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CommunityWriteScreen(),
                  ),
                );
                if (newPost != null && newPost is CommunityPost) {
                  setState(() {
                    _allPosts.insert(0, newPost); // 전체 리스트 맨 앞에 추가
                  });
                }
              },
              icon: const Icon(Icons.add_circle_outline, color: Colors.black),
            ),

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
      body: Column(
        children: [
          // [1] 게시글 섹션
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
                    child: _generalPosts.isEmpty
                        ? const Center(
                            child: Text(
                              "검색 결과가 없습니다.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _generalPosts.length,
                            itemBuilder: (context, index) {
                              return _postItem(
                                context,
                                post: _generalPosts[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),

          if (_viewMode == 'split')
            const Divider(thickness: 8, height: 8, color: Color(0xFFF5F5F5)),

          // [2] 동행 섹션
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
                    child: _companionPosts.isEmpty
                        ? const Center(
                            child: Text(
                              "검색 결과가 없습니다.",
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _companionPosts.length,
                            itemBuilder: (context, index) {
                              return _postItem(
                                context,
                                post: _companionPosts[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
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
