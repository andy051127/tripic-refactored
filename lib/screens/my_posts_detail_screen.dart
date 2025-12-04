import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'home_screen.dart'; // PostItem 사용을 위해 import

class MyPostsDetailScreen extends StatefulWidget {
  final int initialIndex; // 시작할 게시물 인덱스

  const MyPostsDetailScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MyPostsDetailScreen> createState() => _MyPostsDetailScreenState();
}

class _MyPostsDetailScreenState extends State<MyPostsDetailScreen> {
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
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "내 게시물",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: currentUser.uid)
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

          var allPosts = snapshot.data?.docs ?? [];

          if (allPosts.isEmpty) {
            return const Center(
              child: Text("작성한 게시물이 없습니다.", style: TextStyle(color: Colors.grey)),
            );
          }

          // 클라이언트에서 정렬 (최신순)
          allPosts.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Post 객체로 변환
          final posts = allPosts
              .map((doc) => Post.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          // 인스타그램 피드처럼 일반 ListView로 변경
          return ListView.builder(
            controller: _pageController,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // 홈 화면과 동일한 PostItem 위젯 사용
              return PostItem(
                post: post,
                currentUserId: currentUser.uid,
                onDelete: () {
                  // 삭제 후 화면 닫기
                  if (posts.length <= 1) {
                    Navigator.pop(context);
                  }
                },
                onBlock: () {
                  // 차단 로직 (자기 자신은 차단 불가)
                },
              );
            },
          );
        },
      ),
    );
  }
}
