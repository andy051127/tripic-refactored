import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'home_screen.dart'; // PostItem 사용을 위해 import

class OtherUserPostsDetailScreen extends StatefulWidget {
  final int initialIndex; // 시작할 게시물 인덱스
  final String userId; // 다른 사용자의 UID

  const OtherUserPostsDetailScreen({
    super.key,
    this.initialIndex = 0,
    required this.userId,
  });

  @override
  State<OtherUserPostsDetailScreen> createState() => _OtherUserPostsDetailScreenState();
}

class _OtherUserPostsDetailScreenState extends State<OtherUserPostsDetailScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "게시물",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("오류가 발생했습니다: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data?.docs ?? [];
          
          // 클라이언트 측에서 최신순 정렬
          posts.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // 내림차순 (최신순)
          });

          if (posts.isEmpty) {
            return const Center(
              child: Text("게시물이 없습니다.", style: TextStyle(color: Colors.grey)),
            );
          }

          // PostItem을 ListView로 표시 (인스타그램 피드 방식)
          return ListView.builder(
            controller: _pageController,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              
              // Post 모델로 변환
              final post = Post(
                id: posts[index].id,
                uid: postData['uid'] ?? '',
                userName: postData['userName'] ?? 'Unknown',
                location: postData['location'] ?? '',
                title: postData['title'] ?? '',
                content: postData['content'] ?? '',
                likeCount: postData['likeCount'] ?? 0,
                createdAt: postData['createdAt'] as Timestamp?,
                imageUrl: postData['imageUrl'] ?? '',
                imageUrls: postData['imageUrls'] != null
                    ? List<String>.from(postData['imageUrls'])
                    : (postData['imageUrl'] != null && postData['imageUrl'].toString().isNotEmpty
                        ? [postData['imageUrl'].toString()]
                        : []),
                latitude: postData['latitude']?.toDouble(),
                longitude: postData['longitude']?.toDouble(),
                locationName: postData['locationName'],
              );

              // home_screen.dart의 PostItem 위젯 재사용
              return PostItem(
                post: post,
                currentUserId: widget.userId,
                onDelete: () {},
                onBlock: () {},
              );
            },
          );
        },
      ),
    );
  }
}
