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
  void initState() {
    super.initState();
    _checkAuthAndData();
  }

  void _checkAuthAndData() async {
    final user = FirebaseAuth.instance.currentUser;
    print('👤 현재 로그인 사용자: ${user?.uid ?? "없음"}');
    print('👤 이메일: ${user?.email ?? "없음"}');

    if (user != null) {
      // 🔧 기존 채팅방 데이터 수정 (participants 필드 복구)
      print('🔧 채팅방 데이터 수정 시작...');
      try {
        final allSnapshot = await FirebaseFirestore.instance
            .collection('chatRooms')
            .get();

        for (var doc in allSnapshot.docs) {
          final chatRoomId = doc.id;
          final data = doc.data();

          // participants가 null이거나 비어있으면 복구
          if (data['participants'] == null ||
              (data['participants'] as List).isEmpty) {
            print('🔍 채팅방 $chatRoomId - participants 복구 필요');

            // chatRoomId에서 participants 추출 (uid1_uid2 형식)
            final parts = chatRoomId.split('_');
            if (parts.length == 2) {
              final uid1 = parts[0];
              final uid2 = parts[1];

              print('   → participants 복구: [$uid1, $uid2]');

              await FirebaseFirestore.instance
                  .collection('chatRooms')
                  .doc(chatRoomId)
                  .update({
                    'participants': [uid1, uid2],
                  });

              print('   ✅ 수정 완료');
            }
          }
        }
        print('🎉 채팅방 수정 완료!');
      } catch (e) {
        print('❌ 채팅방 수정 실패: $e');
      }

      // Firestore에 직접 쿼리해보기
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('chatRooms')
            .where('participants', arrayContains: user.uid)
            .get();
        print('🔍 직접 쿼리 결과: ${snapshot.docs.length}개 문서');
        for (var doc in snapshot.docs) {
          print('  - 문서 ID: ${doc.id}');
          print('  - 데이터: ${doc.data()}');
        }
      } catch (e) {
        print('❌ 직접 쿼리 실패: $e');
      }

      // 전체 chatRooms 컬렉션 확인
      try {
        final allSnapshot = await FirebaseFirestore.instance
            .collection('chatRooms')
            .get();
        print('📦 전체 chatRooms 문서: ${allSnapshot.docs.length}개');
        for (var doc in allSnapshot.docs) {
          print('  - ${doc.id}: ${doc.data()['participants']}');
        }
      } catch (e) {
        print('❌ 전체 쿼리 실패: $e');
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
            print('🔄 StreamBuilder 상태: ${snapshot.connectionState}');
            print('🔄 에러: ${snapshot.hasError ? snapshot.error : "없음"}');
            print('🔄 데이터: ${snapshot.hasData}');

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 80, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('에러: ${snapshot.error}'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              print('⚠️ 문서 개수: ${snapshot.data?.docs.length ?? "null"}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.message_outlined,
                      size: 80,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "아직 대화 내역이 없습니다",
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "문서 개수: ${snapshot.data?.docs.length ?? 0}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    Text(
                      "현재 사용자: ${FirebaseAuth.instance.currentUser?.uid ?? '없음'}",
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
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

            // 채팅방 목록을 가져와서 메시지가 있는 것만 필터링하고 정렬
            print('📊 전체 문서 개수: ${snapshot.data!.docs.length}');

            var allChatRooms = snapshot.data!.docs.map((doc) {
              print('📄 문서 ID: ${doc.id}');
              print('📄 데이터: ${doc.data()}');
              return ChatRoom.fromFirestore(doc);
            }).toList();

            print('📊 파싱된 채팅방 개수: ${allChatRooms.length}');
            for (var room in allChatRooms) {
              print(
                '💬 채팅방 ${room.id}: lastMessage="${room.lastMessage}", participants=${room.participants}',
              );
            }

            return FutureBuilder<List<String>>(
              future: _firestoreService.getBlockedUserIds(),
              builder: (context, blockedSnapshot) {
                if (blockedSnapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final blockedUserIds = blockedSnapshot.data ?? [];
                final currentUserId =
                    FirebaseAuth.instance.currentUser?.uid ?? '';

                var chatRooms = allChatRooms.where((chatRoom) {
                  // 메시지가 있는 채팅방만
                  if (chatRoom.lastMessage.isEmpty) return false;

                  // 차단된 사용자와의 채팅방 제외
                  final otherUserId = chatRoom.participants.firstWhere(
                    (id) => id != currentUserId,
                    orElse: () => '',
                  );
                  if (blockedUserIds.contains(otherUserId)) return false;

                  return true;
                }).toList();

                print('✅ 필터링 후 채팅방 개수: ${chatRooms.length}');

                // lastMessageTime으로 정렬 (최신순)
                chatRooms.sort((a, b) {
                  if (a.lastMessageTime == null && b.lastMessageTime == null)
                    return 0;
                  if (a.lastMessageTime == null) return 1;
                  if (b.lastMessageTime == null) return -1;
                  return b.lastMessageTime!.compareTo(a.lastMessageTime!);
                });

                // 필터링 후에도 채팅방이 없으면 빈 화면 표시
                if (chatRooms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.message_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "아직 대화 내역이 없습니다",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
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

                          if (otherUserId.isEmpty)
                            return const SizedBox.shrink();

                          return FutureBuilder<Map<String, dynamic>?>(
                            future: _firestoreService.getUserInfo(otherUserId),
                            builder: (context, userSnapshot) {
                              final userName =
                                  userSnapshot.data?['userName'] ?? '알 수 없음';
                              final userProfileImage =
                                  userSnapshot.data?['profileImage'] ?? '';
                              final unreadCount =
                                  chatRoom.unreadCount[currentUserId] ?? 0;

                              String lastMessagePreview = chatRoom.lastMessage;
                              if (chatRoom.lastMessageType == 'image') {
                                lastMessagePreview = '📷 사진을 보냈습니다.';
                              } else if (chatRoom.lastMessageType ==
                                  'location') {
                                lastMessagePreview = '📍 위치를 보냈습니다.';
                              } else if (chatRoom.lastMessageType == 'post') {
                                lastMessagePreview = '📄 게시물을 공유했습니다.';
                              }

                              String timeString = '';
                              if (chatRoom.lastMessageTime != null) {
                                final now = DateTime.now();
                                final diff = now.difference(
                                  chatRoom.lastMessageTime!,
                                );

                                if (diff.inDays > 0) {
                                  timeString = DateFormat(
                                    'MM.dd',
                                  ).format(chatRoom.lastMessageTime!);
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
                  backgroundImage:
                      userProfileImage != null && userProfileImage.isNotEmpty
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
                            color: unread > 0
                                ? Colors.black87
                                : Colors.grey[700],
                            fontSize: 14,
                            fontWeight: unread > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
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
