import 'package:flutter/material.dart';
import 'friend_list_screen.dart'; // 친구 목록 연결
import 'chat_detail_screen.dart'; // 채팅방 연결

class MessageListScreen extends StatelessWidget {
  const MessageListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context), // 뒤로가기
        ),
        centerTitle: true,
        title: const Text(
          "메시지",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 오른쪽 상단 메뉴 -> 친구 목록으로 이동 (새 친구 찾기)
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 즐겨찾기 영역
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "즐겨찾기",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  // 즐겨찾기 추가 버튼 역할 (누르면 친구 목록으로 이동)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendListScreen(),
                        ),
                      );
                    },
                    child: Text(
                      "추가 +",
                      style: TextStyle(
                        color: Colors.blue[600],
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFavoriteItem(context, "김찬희", true),
                  _buildFavoriteItem(context, "황종현", false),
                  _buildFavoriteItem(context, "이경환", false),
                  _buildFavoriteItem(context, "김성진", true),
                  _buildFavoriteItem(context, "김성우", false),
                ],
              ),
            ),
            const Divider(height: 1),

            // 2. 채팅 리스트
            _buildChatItem(
              context,
              "김찬희",
              "안녕하세요. 반가워요 혹시 ...",
              "04:04AM",
              3,
              isPhoto: false,
            ),
            _buildChatItem(
              context,
              "이경환",
              "사진을 보냈습니다.",
              "08:58PM",
              3,
              isPhoto: true,
            ),
            _buildChatItem(
              context,
              "문학철",
              "사진을 보냈습니다.",
              "11:33PM",
              0,
              isPhoto: true,
            ),
            _buildChatItem(
              context,
              "맹한수",
              "ㅎㅇㅋㅋ뭐함?",
              "06:58PM",
              1,
              isPhoto: false,
            ),
            _buildChatItem(
              context,
              "안해리",
              "사진을 보냈습니다.",
              "09:43PM",
              3,
              isPhoto: true,
            ),
            _buildChatItem(
              context,
              "강우준",
              "지도를 보냈습니다.",
              "09:43PM",
              0,
              isPhoto: false,
            ),
          ],
        ),
      ),
    );
  }

  // 즐겨찾기 아이템 (클릭 시 채팅방 이동)
  Widget _buildFavoriteItem(BuildContext context, String name, bool isOnline) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatDetailScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16.0),
        child: Column(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem(
    BuildContext context,
    String name,
    String message,
    String time,
    int unread, {
    required bool isPhoto,
  }) {
    return InkWell(
      // 리스트 클릭 -> 채팅방으로 이동
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatDetailScreen()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Stack(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
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
                            color: Colors.grey[700],
                            fontSize: 14,
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
