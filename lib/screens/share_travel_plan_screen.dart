import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/travel_plan_model.dart';

class ShareTravelPlanScreen extends StatefulWidget {
  final TravelPlan plan;

  const ShareTravelPlanScreen({super.key, required this.plan});

  @override
  State<ShareTravelPlanScreen> createState() => _ShareTravelPlanScreenState();
}

class _ShareTravelPlanScreenState extends State<ShareTravelPlanScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Set<String> _selectedUserIds = {};
  bool _isSending = false;

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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '여행 계획 공유',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedUserIds.isNotEmpty)
            TextButton(
              onPressed: _isSending ? null : _shareTravelPlan,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      '전송 (${_selectedUserIds.length})',
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: '친구 검색',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // 친구 목록
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _getFollowingUsers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
                }

                final users = snapshot.data ?? [];

                // 검색 필터링
                final filteredUsers = users.where((user) {
                  final userName = (user['userName'] ?? '').toLowerCase();
                  return userName.contains(_searchQuery);
                }).toList();

                if (filteredUsers.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? '팔로잉 중인 친구가 없습니다'
                              : '검색 결과가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    final userId = user['uid'] as String;
                    final userName = user['userName'] ?? '알 수 없음';
                    final profileImage = user['profileImage'] ?? '';
                    final isSelected = _selectedUserIds.contains(userId);

                    return ListTile(
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImage.isNotEmpty
                            ? NetworkImage(profileImage)
                            : null,
                        child: profileImage.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      trailing: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey,
                            width: 2,
                          ),
                          color: isSelected ? Colors.blue : Colors.transparent,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedUserIds.remove(userId);
                          } else {
                            _selectedUserIds.add(userId);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getFollowingUsers() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      // 내가 팔로우하는 사용자 ID 목록 가져오기
      final followingDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('following')
          .get();

      final followingIds = followingDoc.docs.map((doc) => doc.id).toList();

      if (followingIds.isEmpty) return [];

      // 팔로우하는 사용자들의 정보 가져오기
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: followingIds)
          .get();

      return usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'uid': doc.id,
          'userName': data['userName'] ?? data['username'] ?? data['name'],
          'profileImage': data['profileImage'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('팔로잉 목록 가져오기 실패: $e');
      return [];
    }
  }

  Future<void> _shareTravelPlan() async {
    if (_selectedUserIds.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      int successCount = 0;

      for (String userId in _selectedUserIds) {
        try {
          // 채팅방 가져오기 또는 생성
          final chatRoomId = await _firestoreService.getOrCreateChatRoom(
            userId,
          );

          // 여행 계획 공유 메시지 전송
          await _firestoreService.sendTravelPlanMessage(
            chatRoomId: chatRoomId,
            receiverId: userId,
            travelPlanId: widget.plan.id,
            travelPlanTitle: widget.plan.title,
            travelPlanDate: widget.plan.date,
            travelPlanCountry: widget.plan.country,
          );

          successCount++;
        } catch (e) {
          print('$userId에게 전송 실패: $e');
        }
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$successCount명에게 여행 계획을 공유했습니다'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('여행 계획 공유 실패: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }
}

