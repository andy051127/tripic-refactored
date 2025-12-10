import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';

class AdminInquiryManagementScreen extends StatefulWidget {
  const AdminInquiryManagementScreen({super.key});

  @override
  State<AdminInquiryManagementScreen> createState() =>
      _AdminInquiryManagementScreenState();
}

class _AdminInquiryManagementScreenState
    extends State<AdminInquiryManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const Center(child: Text('로그인이 필요합니다'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('1:1 문의 관리'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chatRooms')
            .where('participants', arrayContains: currentUser.uid)
            // .orderBy('lastMessageTime', descending: true) // 인덱스 오류 방지를 위해 제거하고 클라이언트 정렬 사용
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 클라이언트 측 정렬 (최신 메시지 순)
          final docs = snapshot.data?.docs.toList() ?? [];
          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['lastMessageTime'] as Timestamp?;
            final bTime = bData['lastMessageTime'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime); // 내림차순
          });

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('진행 중인 문의가 없습니다'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final participants = List<String>.from(
                data['participants'] ?? [],
              );

              // 상대방 ID 찾기
              final otherUserId = participants.firstWhere(
                (uid) => uid != currentUser.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) return const SizedBox.shrink();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const SizedBox(
                      height: 72,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>?;
                  final userName = userData?['userName'] ?? '알 수 없음';
                  final userProfile = userData?['profileImage'] ?? '';

                  final lastMessage = data['lastMessage'] ?? '';
                  final lastMessageTime =
                      (data['lastMessageTime'] as Timestamp?)?.toDate();
                  final unreadCountMap =
                      data['unreadCount'] as Map<String, dynamic>?;
                  final unreadCount = unreadCountMap?[currentUser.uid] ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userProfile.isNotEmpty
                          ? NetworkImage(userProfile)
                          : null,
                      child: userProfile.isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (lastMessageTime != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(lastMessageTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            chatPartnerId: otherUserId,
                            chatPartnerName: userName,
                            chatRoomId: doc.id,
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
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays > 0) {
      return DateFormat('MM/dd').format(time);
    } else {
      return DateFormat('HH:mm').format(time);
    }
  }
}
