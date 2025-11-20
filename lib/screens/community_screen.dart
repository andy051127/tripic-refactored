import 'package:flutter/material.dart';
import 'community_detail_screen.dart';
import 'community_write_screen.dart'; // 작성 화면 import

// 커뮤니티 게시글 데이터 모델
class CommunityPost {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final bool isFileImage; // 갤러리 사진인지 여부

  CommunityPost({
    required this.name,
    required this.location,
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    this.isFileImage = false,
  });
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _viewMode = 'split'; // split, post, companion

  // 게시글 데이터 리스트 (초기 샘플 데이터 포함)
  final List<CommunityPost> _posts = [
    CommunityPost(
      name: "leeeee_kh",
      location: "San Diego, USA",
      title: "씨월드 입장권 팝니다",
      content: "1월 31일 까지 사용 가능한 씨월드 입장권 팝니다!\n3장 있고 개당 30달러에 판매해요",
      stats: "72 · 21 · 47",
      imageUrl: "https://via.placeholder.com/300",
    ),
    CommunityPost(
      name: "maeng___gu",
      location: "Tokyo, Japan",
      title: "다이토구에 집 알아보는 중인데요",
      content: "혹시 다이토구 살아보신 분 계신가요?\n학군이랑 주변 인프라가 궁금하네요.....",
      stats: "13 · 25 · 1",
    ),
    CommunityPost(
      name: "civa_mom",
      location: "Kota Kinabalu, Malaysia",
      title: "코타키나발루에서 그랩 외 택시 타지마세요!",
      content: "사람을 호구로 아는지 가격을 몇 배로 부르네요..\n어이가 없어가지고 얘기하다 다툼으로 이어져 경찰서...",
      stats: "33 · 15 · 12",
      imageUrl: "https://via.placeholder.com/300",
    ),
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "커뮤니티",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // [+] 버튼: 글쓰기 화면으로 이동
          IconButton(
            onPressed: () async {
              // 작성 화면으로 이동하고 결과(새 게시글)를 기다림
              final newPost = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityWriteScreen(),
                ),
              );

              // 작성된 글이 있으면 리스트 맨 앞에 추가
              if (newPost != null && newPost is CommunityPost) {
                setState(() {
                  _posts.insert(0, newPost);
                });
              }
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Column(
        children: [
          // [1] 게시글 영역
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
                    child: ListView.builder(
                      // ListView.builder로 변경하여 동적 리스트 처리
                      padding: EdgeInsets.zero,
                      itemCount: _posts.length,
                      itemBuilder: (context, index) {
                        final post = _posts[index];
                        return _postItem(
                          context,
                          post: post, // post 객체 전체 전달
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          if (_viewMode == 'split')
            const Divider(thickness: 8, height: 8, color: Color(0xFFF5F5F5)),

          // [2] 동행 영역 (기존 더미 데이터 유지)
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
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 기존 동행 아이템 (CommunityPost 객체 생성해서 사용하거나 그대로 유지 가능)
                        // 여기선 편의상 기존 방식대로 호출하지만, 실제론 이것도 리스트로 관리하면 좋음
                        _postItemOld(
                          context,
                          name: "leeeee_kh",
                          title: "조슈아트리 로드트립 동행 구해요",
                          content: "11월 5일 부터 4일간 로드트립 동행 하실 분 구합니다!",
                          stats: "21 · 12 · 2",
                        ),
                        // ... 기타 동행 아이템들
                      ],
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

  // [수정된] 게시글 아이템 위젯 (CommunityPost 객체 사용)
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
              // 이미지 표시 (파일 이미지인 경우 처리 로직은 CommunityDetailScreen 등에서 추가 필요)
              // 여기선 간단히 네트워크 이미지만 있다고 가정하거나, 파일 이미지는 생략 (필요시 추가 가능)
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

  // (기존 방식 유지를 위한 헬퍼 - 동행 탭용)
  Widget _postItemOld(
    BuildContext context, {
    required String name,
    String? location,
    required String title,
    required String content,
    required String stats,
    String? imageUrl,
  }) {
    return _postItem(
      context,
      post: CommunityPost(
        name: name,
        location: location ?? "",
        title: title,
        content: content,
        stats: stats,
        imageUrl: imageUrl,
      ),
    );
  }
}
