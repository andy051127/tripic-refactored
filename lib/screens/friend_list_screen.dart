import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart'; // 채팅방 이동용

class FriendListScreen extends StatefulWidget {
  // 선택 모드인지(인원 추가용), 아니면 그냥 목록인지(채팅용) 구분
  final bool isSelectionMode;

  const FriendListScreen({super.key, this.isSelectionMode = false});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  
  // 선택된 친구들을 저장할 리스트 (다중 선택용)
  final Set<String> _selectedFriends = {};

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
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
            "친구 목록",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: Text("로그인이 필요합니다."),
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
          "친구 목록",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 선택 모드일 때만 '완료' 버튼 표시
          if (widget.isSelectionMode)
            TextButton(
              onPressed: () {
                // 선택된 친구 리스트 반환 (List<String>)
                Navigator.pop(context, _selectedFriends.toList());
              },
              child: const Text(
                "완료",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.search, color: Colors.black),
              onPressed: () {},
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getFollowingStream(currentUser.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "팔로잉하는 친구가 없습니다",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "다른 사용자를 팔로우해보세요!",
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              );
            }

            final followingDocs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: followingDocs.length,
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemBuilder: (context, index) {
                final followingUserId = followingDocs[index].id;

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _firestoreService.getUserInfo(followingUserId),
                  builder: (context, userSnapshot) {
                    if (!userSnapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final userData = userSnapshot.data!;
                    final userName = userData['userName'] ?? '알 수 없음';
                    final userProfileImage = userData['profileImage'] ?? '';
                    final isSelected = _selectedFriends.contains(userName);

                    return FutureBuilder<Map<String, int>>(
                      future: _firestoreService.getFollowCounts(followingUserId),
                      builder: (context, countsSnapshot) {
                        final followerCount = countsSnapshot.data?['followers'] ?? 0;
                        final followingCount = countsSnapshot.data?['following'] ?? 0;

                        return FutureBuilder<QuerySnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('posts')
                              .where('uid', isEqualTo: followingUserId)
                              .get(),
                          builder: (context, postsSnapshot) {
                            final postCount = postsSnapshot.data?.docs.length ?? 0;

                            return ListTile(
                              onTap: () {
                                if (widget.isSelectionMode) {
                                  // [1] 선택 모드: 리스트에 추가/제거 (다중 선택)
                                  setState(() {
                                    if (isSelected) {
                                      _selectedFriends.remove(userName);
                                    } else {
                                      _selectedFriends.add(userName);
                                    }
                                  });
                                } else {
                                  // [2] 채팅 모드: 해당 친구와의 채팅방으로 이동
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatDetailScreen(
                                        chatPartnerName: userName,
                                        chatPartnerId: followingUserId,
                                      ),
                                    ),
                                  );
                                }
                              },
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.grey,
                                backgroundImage: userProfileImage.isNotEmpty
                                    ? NetworkImage(userProfileImage)
                                    : null,
                                child: userProfileImage.isEmpty
                                    ? const Icon(Icons.person, color: Colors.white)
                                    : null,
                              ),
                              title: Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                "게시물 $postCount   팔로잉 $followingCount   팔로워 $followerCount",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              // 선택 모드일 때는 체크박스 아이콘 표시
                              trailing: widget.isSelectionMode
                                  ? Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected ? Colors.blue : Colors.grey,
                                      size: 24,
                                    )
                                  : const Icon(
                                      Icons.message_outlined,
                                      color: Colors.grey,
                                      size: 20,
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
          },
        ),
      ),
    );
  }
}
