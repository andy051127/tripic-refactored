import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart';
import '../models/message_model.dart';
import 'friend_list_screen.dart';
import 'chat_detail_screen.dart';

class MessageListScreen extends StatefulWidget {
  const MessageListScreen({super.key});

  @override
  State<MessageListScreen> createState() => _MessageListScreenState();
}

class _MessageListScreenState extends State<MessageListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

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
          "메시지",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FriendListScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestoreService.getMyChatRoomsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.message_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      "아직 대화 내역이 없습니다",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FriendListScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text("친구 목록으로 이동"),
                    ),
                  ],
                ),
              );
            }

            final chatRooms = snapshot.data!.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList();
            final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 채팅 리스트
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: chatRooms.length,
                    itemBuilder: (context, index) {
                      final chatRoom = chatRooms[index];
                      final otherUserId = chatRoom.participants.firstWhere(
                        (id) => id != currentUserId,
                        orElse: () => '',
                      );

                      if (otherUserId.isEmpty) return const SizedBox.shrink();

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _firestoreService.getUserInfo(otherUserId),
                        builder: (context, userSnapshot) {
                          final userName = userSnapshot.data?['userName'] ?? '알 수 없음';
                          final userProfileImage = userSnapshot.data?['profileImage'] ?? '';
                          final unreadCount = chatRoom.unreadCount[currentUserId] ?? 0;

                          String lastMessagePreview = chatRoom.lastMessage;
                          if (chatRoom.lastMessageType == 'image') {
                            lastMessagePreview = '📷 사진을 보냈습니다.';
                          } else if (chatRoom.lastMessageType == 'location') {
                            lastMessagePreview = '📍 위치를 보냈습니다.';
                          }

                          String timeString = '';
                          if (chatRoom.lastMessageTime != null) {
                            final now = DateTime.now();
                            final diff = now.difference(chatRoom.lastMessageTime!);

                            if (diff.inDays > 0) {
                              timeString = DateFormat('MM.dd').format(chatRoom.lastMessageTime!);
                            } else if (diff.inHours > 0) {
                              timeString = '${diff.inHours}시간 전';
                            } else if (diff.inMinutes > 0) {
                              timeString = '${diff.inMinutes}분 전';
                            } else {
                              timeString = '방금';
                            }
                          }

                          return _buildChatItem(
                            context,
                            chatRoom.id,
                            otherUserId,
                            userName,
                            lastMessagePreview,
                            timeString,
                            unreadCount,
                            userProfileImage: userProfileImage,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    String chatRoomId,
    String otherUserId,
    String name,
    String message,
    String time,
    int unread, {
    String? userProfileImage,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatDetailScreen(
              chatPartnerName: name,
              chatPartnerId: otherUserId,
              chatRoomId: chatRoomId,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  backgroundImage: userProfileImage != null && userProfileImage.isNotEmpty
                      ? NetworkImage(userProfileImage)
                      : null,
                  child: userProfileImage == null || userProfileImage.isEmpty
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        time,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: unread > 0 ? Colors.black87 : Colors.grey[700],
                            fontSize: 14,
                            fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (unread > 0)
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unread.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
