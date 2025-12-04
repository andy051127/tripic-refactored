import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'other_user_profile_screen.dart';

class FollowListScreen extends StatefulWidget {
  final String userName;
  final int initialIndex; // 0: 팔로워, 1: 팔로잉
  final String? userId; // 추가: Firebase UID

  const FollowListScreen({
    super.key,
    required this.userName,
    required this.initialIndex,
    this.userId,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  String? _targetUserId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    String targetId = widget.userId ?? '';

    // userId가 없으면 현재 로그인한 사용자 또는 userName으로 검색
    if (targetId.isEmpty) {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && widget.userName == currentUser.displayName) {
        targetId = currentUser.uid;
      } else {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userName', isEqualTo: widget.userName)
            .limit(1)
            .get();

        if (usersSnapshot.docs.isNotEmpty) {
          targetId = usersSnapshot.docs.first.id;
        }
      }
    }

    if (mounted) {
      setState(() {
        _targetUserId = targetId;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialIndex,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            widget.userName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: "팔로워"),
              Tab(text: "팔로잉"),
            ],
          ),
        ),
        body: _targetUserId == null
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildUserList(isFollower: true),
                  _buildUserList(isFollower: false),
                ],
              ),
      ),
    );
  }

  Widget _buildUserList({required bool isFollower}) {
    if (_targetUserId == null) {
      return const Center(child: Text("사용자 정보를 찾을 수 없습니다."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: isFollower
          ? _firestoreService.getFollowersStream(_targetUserId!)
          : _firestoreService.getFollowingStream(_targetUserId!),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text("오류가 발생했습니다."));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final userIds = snapshot.data?.docs.map((doc) => doc.id).toList() ?? [];

        if (userIds.isEmpty) {
          return Center(
            child: Text(isFollower ? "팔로워가 없습니다." : "팔로잉이 없습니다."),
          );
        }

        return ListView.builder(
          itemCount: userIds.length,
          itemBuilder: (context, index) {
            final userId = userIds[index];

            return FutureBuilder<Map<String, dynamic>?>(
              future: _firestoreService.getUserInfo(userId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    leading: CircleAvatar(backgroundColor: Colors.grey),
                    title: Text("로딩 중..."),
                  );
                }

                final userInfo = userSnapshot.data;
                final userName = userInfo?['userName'] ?? 
                                 userInfo?['username'] ?? 
                                 userInfo?['name'] ?? 
                                 '알 수 없음';
                final profileImage = userInfo?['profileImage'] ?? '';
                final bio = userInfo?['bio'] ?? '여행을 좋아하는 사람입니다.';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey,
                    backgroundImage: profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: profileImage.isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Text(
                    userName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    bio,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _buildFollowButton(userId, isFollower),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OtherUserProfileScreen(
                          userName: userName,
                          profileImage: profileImage,
                          userId: userId,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFollowButton(String userId, bool isFollower) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    // 자신의 프로필이면 버튼을 표시하지 않음
    if (currentUser?.uid == userId) {
      return const SizedBox.shrink();
    }

    // 본인 프로필에서 진입한 경우 (본인의 팔로워/팔로잉 목록)
    final isOwnProfile = _targetUserId == currentUser?.uid;

    if (isOwnProfile) {
      if (isFollower) {
        // 팔로워 탭: 삭제 버튼
        return GestureDetector(
          onTap: () async {
            // 확인 다이얼로그 표시
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('팔로워 삭제'),
                content: const Text('이 팔로워를 삭제하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      '삭제',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                await _firestoreService.removeFollower(userId);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('팔로워를 삭제했습니다')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류가 발생했습니다: $e')),
                  );
                }
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "삭제",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      } else {
        // 팔로잉 탭: 언팔로우 버튼
        return GestureDetector(
          onTap: () async {
            try {
              await _firestoreService.unfollowUser(userId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('언팔로우했습니다')),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('오류가 발생했습니다: $e')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              "언팔로우",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }
    }

    // 다른 사용자 프로필에서 진입한 경우: 기존 팔로우/언팔로우 버튼
    return FutureBuilder<bool>(
      future: _firestoreService.isFollowing(userId),
      builder: (context, snapshot) {
        final isFollowing = snapshot.data ?? false;

        return GestureDetector(
          onTap: () async {
            try {
              if (isFollowing) {
                await _firestoreService.unfollowUser(userId);
              } else {
                await _firestoreService.followUser(userId);
              }
              // UI 업데이트를 위해 setState 호출
              if (mounted) {
                setState(() {});
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('오류가 발생했습니다: $e')),
                );
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isFollowing ? Colors.grey[200] : Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isFollowing ? "팔로잉" : "팔로우",
              style: TextStyle(
                color: isFollowing ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      },
    );
  }
}
