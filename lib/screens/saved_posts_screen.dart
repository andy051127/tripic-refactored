import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart';
import 'post_detail_screen.dart';
import 'community_detail_screen.dart';
import 'package:intl/intl.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({super.key});

  @override
  State<SavedPostsScreen> createState() => _SavedPostsScreenState();
}

class SavedItem {
  final String id;
  final String type; // 'feed' or 'community'
  final String imageUrl;
  final String title;
  final String userName;
  final String location;
  final String content;
  final String stats;
  final DateTime createdAt;
  final String postUid;
  final String? category;
  final String? travelPlanId;
  final String? travelPlanTitle;
  final String? travelPlanDate;
  final String? travelPlanCountry;
  final String? userProfileImage;

  SavedItem({
    required this.id,
    required this.type,
    required this.imageUrl,
    required this.title,
    required this.userName,
    required this.location,
    required this.content,
    required this.stats,
    required this.createdAt,
    required this.postUid,
    this.category,
    this.travelPlanId,
    this.travelPlanTitle,
    this.travelPlanDate,
    this.travelPlanCountry,
    this.userProfileImage,
  });
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<List<SavedItem>> _getSavedPosts() async {
    final savedPostIds = await _firestoreService.getSavedPostIds();
    List<SavedItem> items = [];

    for (String postId in savedPostIds) {
      try {
        final postDoc = await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .get();

        if (postDoc.exists) {
          final data = postDoc.data()!;
          final category = data['category'] ?? 'feed';
          
          items.add(
            SavedItem(
              id: postDoc.id,
              type: category == 'feed' ? 'feed' : 'community',
              imageUrl: data['imageUrl'] ?? '',
              title: data['title'] ?? '',
              userName: data['userName'] ?? '',
              location: data['location'] ?? '',
              content: data['content'] ?? '',
              stats: '${data['likeCount'] ?? 0} · ${data['commentCount'] ?? 0}',
              createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              postUid: data['uid'] ?? '',
              category: category,
              travelPlanId: data['travelPlanId'],
              travelPlanTitle: data['travelPlanTitle'],
              travelPlanDate: data['travelPlanDate'],
              travelPlanCountry: data['travelPlanCountry'],
              userProfileImage: data['userProfileImage'],
            ),
          );
        }
      } catch (e) {
        print('게시물 정보 가져오기 실패: $e');
      }
    }

    return items;
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
        child: FutureBuilder<List<SavedItem>>(
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

            final savedItems = snapshot.data!;
            return GridView.builder(
              padding: const EdgeInsets.all(2),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: savedItems.length,
              itemBuilder: (context, index) {
                final item = savedItems[index];
                return GestureDetector(
                  onTap: () async {
                    if (item.type == 'feed') {
                      // 일반 게시물인 경우 Post 객체로 변환
                      final postDoc = await FirebaseFirestore.instance
                          .collection('posts')
                          .doc(item.id)
                          .get();
                      
                      if (postDoc.exists) {
                        final data = postDoc.data()!;
                        final post = Post(
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
                        );
                        
                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(post: post),
                            ),
                          );
                        }
                      }
                    } else {
                      // 커뮤니티 게시물인 경우
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CommunityDetailScreen(
                            name: item.userName,
                            location: item.location,
                            title: item.title,
                            content: item.content,
                            stats: item.stats,
                            imageUrl: item.imageUrl,
                            createdAt: item.createdAt,
                            postUid: item.postUid,
                            postId: item.id,
                            category: item.category,
                            travelPlanId: item.travelPlanId,
                            travelPlanTitle: item.travelPlanTitle,
                            travelPlanDate: item.travelPlanDate,
                            travelPlanCountry: item.travelPlanCountry,
                            userProfileImage: item.userProfileImage,
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 게시물 이미지
                      item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
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
                      // 타입 표시 배지
                      if (item.type == 'community')
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CA1AF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              '커뮤니티',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      // 삭제 버튼
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _unsavePost(item.id),
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
