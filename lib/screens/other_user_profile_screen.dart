import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userName;
  final String profileImage;
  final String? userId; // 추가: Firebase UID

  const OtherUserProfileScreen({
    super.key,
    required this.userName,
    required this.profileImage,
    this.userId,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFollowing = false;
  bool _isLoading = true;
  int _followerCount = 0;
  int _followingCount = 0;
  int _postCount = 0;
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // userId를 이용하여 팔로우 상태 확인
      String targetId = widget.userId ?? '';
      
      // userId가 없으면 userName으로 검색
      if (targetId.isEmpty) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userName', isEqualTo: widget.userName)
            .limit(1)
            .get();
        
        if (usersSnapshot.docs.isNotEmpty) {
          targetId = usersSnapshot.docs.first.id;
        }
      }

      if (targetId.isNotEmpty) {
        _targetUserId = targetId;
        
        // 팔로우 상태 확인
        final isFollowing = await _firestoreService.isFollowing(targetId);
        
        // 팔로워/팔로잉 수 가져오기
        final counts = await _firestoreService.getFollowCounts(targetId);
        
        // 게시물 수 가져오기
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: targetId)
            .get();

        if (mounted) {
          setState(() {
            _isFollowing = isFollowing;
            _followerCount = counts['followers'] ?? 0;
            _followingCount = counts['following'] ?? 0;
            _postCount = postsSnapshot.docs.length;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('사용자 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_targetUserId == null) return;

    try {
      if (_isFollowing) {
        await _firestoreService.unfollowUser(_targetUserId!);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followerCount--;
            globalFollowingCount.value--;
          });
        }
      } else {
        await _firestoreService.followUser(_targetUserId!);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followerCount++;
            globalFollowingCount.value++;
          });
        }
      }
    } catch (e) {
      print('팔로우 토글 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
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
        centerTitle: false,
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey,
                            backgroundImage: widget.profileImage.isNotEmpty
                                ? NetworkImage(widget.profileImage)
                                : null,
                            child: widget.profileImage.isEmpty
                                ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem("$_postCount", "게시물"),
                                _buildStatItem("$_followerCount", "팔로워"),
                                _buildStatItem("$_followingCount", "팔로잉"),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleFollow,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      _isFollowing ? Colors.white : Colors.blue,
                                  border: Border.all(
                                    color: _isFollowing
                                        ? Colors.grey.shade300
                                        : Colors.transparent,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    _isFollowing ? "팔로잉" : "팔로우",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isFollowing
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text(
                                  "메시지",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(child: _buildUserPostsGrid()),
              ],
            ),
    );
  }

  Widget _buildUserPostsGrid() {
    if (_targetUserId == null) {
      return const Center(child: Text("사용자 정보를 찾을 수 없습니다."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: _targetUserId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("오류가 발생했습니다."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];

        if (posts.isEmpty) {
          return const Center(child: Text("게시물이 없습니다."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final imageUrl = postData['imageUrl'] ?? '';

            return GestureDetector(
              onTap: () {
                // TODO: 게시물 상세 화면으로 이동
              },
              child: Container(
                color: Colors.grey[300],
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.grey),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
