import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_detail_screen.dart';
import 'community_write_screen.dart';
import '../models/post_model.dart'; // 통합된 Post 모델 사용
import '../services/firestore_service.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용

// [수정됨] 커뮤니티 게시글 데이터 모델 (createdAt 추가)
class CommunityPost {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final bool isFileImage;
  final String category;
  final DateTime createdAt; // [추가] 작성 시간

  CommunityPost({
    required this.name,
    required this.location,
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    this.isFileImage = false,
    required this.category,
    DateTime? createdAt, // 선택적 매개변수
  }) : createdAt = createdAt ?? DateTime.now(); // 없으면 현재 시간
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _viewMode = 'split'; // split, post, companion
  final FirestoreService _firestoreService = FirestoreService();

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
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityWriteScreen(),
                ),
              );
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
      // StreamBuilder로 데이터 수신
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("오류 발생"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          // Firestore 데이터를 CommunityPost로 변환
          final allPosts = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return CommunityPost(
              name: data['userName'] ?? 'Unknown',
              location: data['location'] ?? '',
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              stats: "${data['likeCount'] ?? 0} · 0 · 0",
              imageUrl: data['imageUrl'],
              category: data['category'] ?? 'general',
              createdAt: (data['createdAt'] as Timestamp?)
                  ?.toDate(), // Firestore Timestamp -> DateTime 변환
            );
          }).toList();

          // 카테고리별 분류
          final generalPosts = allPosts
              .where((p) => p.category == 'general')
              .toList();
          final companionPosts = allPosts
              .where((p) => p.category == 'companion')
              .toList();

          return Column(
            children: [
              // [1] 게시글 영역
              if (_viewMode == 'split' || _viewMode == 'post')
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleView('post'),
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
                            ? const Center(child: Text("게시글이 없습니다."))
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: generalPosts.length,
                                itemBuilder: (context, index) => _postItem(
                                  context,
                                  post: generalPosts[index],
                                ),
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

              // [2] 동행 영역
              if (_viewMode == 'split' || _viewMode == 'companion')
                Expanded(
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleView('companion'),
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
                            ? const Center(child: Text("동행 글이 없습니다."))
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                itemCount: companionPosts.length,
                                itemBuilder: (context, index) => _postItem(
                                  context,
                                  post: companionPosts[index],
                                ),
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
              createdAt: post.createdAt, // [추가] 작성일 전달
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
                          backgroundColor: Colors.grey,
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.white,
                          ),
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
