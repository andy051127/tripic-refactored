import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<Post>> _getSavedPosts() async {
    final savedPostIds = await _firestoreService.getSavedPostIds();
    List<Post> posts = [];

    for (String postId in savedPostIds) {
      try {
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          final data = postDoc.data()!;
          posts.add(
            Post(
              id: postDoc.id,
              uid: data['uid'] ?? '',
              userName: data['userName'] ?? '',
              imageUrl: data['imageUrl'] ?? '',
              imageUrls: data['imageUrls'] != null
                  ? List<String>.from(data['imageUrls'])
                  : (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                      ? [data['imageUrl'].toString()]
                      : []),
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              location: data['location'] ?? '',
              latitude: data['latitude']?.toDouble(),
              longitude: data['longitude']?.toDouble(),
              locationName: data['locationName'],
              category: data['category'] ?? 'feed',
              country: data['country'] as String?,
              taggedFriend: data['taggedFriend'] as String?,
              createdAt: data['createdAt'] as Timestamp?,
              likeCount: data['likeCount'] ?? 0,
            ),
          );
        }
      } catch (e) {
        print('게시물 정보 가져오기 실패: $e');
      }
    }

    return posts;
  }

  Future<void> _unsavePost(String postId) async {
    try {
      await _firestoreService.unsavePost(postId);
      if (mounted) {
        setState(() {}); // UI 새로고침
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("보관함에서 삭제되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
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
        centerTitle: true,
        title: const Text(
          "보관함",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Post>>(
          future: _getSavedPosts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      "보관된 게시물이 없습니다.",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            final savedPosts = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                final post = savedPosts[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(post: post),
                      ),
                    );
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 게시물 이미지
                      post.imageUrl.isNotEmpty
                          ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.image,
                                color: Colors.white,
                              ),
                            ),
                      // 삭제 버튼
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _unsavePost(post.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
