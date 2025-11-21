import 'package:flutter/material.dart';
import 'chat_detail_screen.dart'; // 채팅방 이동용

class FriendListScreen extends StatelessWidget {
  // 선택 모드인지(인원 추가용), 아니면 그냥 목록인지(채팅용) 구분
  // 기본값은 false (채팅용)
  final bool isSelectionMode;

  const FriendListScreen({super.key, this.isSelectionMode = false});

  @override
  Widget build(BuildContext context) {
    final List<String> friends = [
      "가나다",
      "김 군",
      "김찬희",
      "이경환",
      "이예진",
      "안해진",
      "야구오",
      "김지오",
      "김오디",
      "박명수",
    ];

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
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {},
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: ListView.builder(
        itemCount: friends.length,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          return ListTile(
            onTap: () {
              if (isSelectionMode) {
                // [1] 인원 추가 모드라면: 선택된 친구 이름을 돌려주고 닫음
                Navigator.pop(context, friends[index]);
              } else {
                // [2] 채팅 모드라면: 해당 친구와의 채팅방으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatDetailScreen(),
                  ),
                );
              }
            },
            leading: Stack(
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
                      color: Colors.blue, // 활동 중 표시
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            title: Text(
              friends[index],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              "게시물 2   팔로잉 20   팔로워 30",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            // 선택 모드가 아닐 때는 체크 표시 없앰 (메시지 아이콘 등으로 대체 가능)
            trailing: isSelectionMode
                ? null // 선택 모드일 때는 탭하면 선택되므로 별도 아이콘 X (필요하면 체크박스 추가)
                : const Icon(
                    Icons.message_outlined,
                    color: Colors.grey,
                    size: 20,
                  ),
          );
        },
      ),
    );
  }
}
