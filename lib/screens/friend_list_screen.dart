import 'package:flutter/material.dart';
import 'chat_detail_screen.dart'; // 채팅방 이동용

class FriendListScreen extends StatefulWidget {
  // 선택 모드인지(인원 추가용), 아니면 그냥 목록인지(채팅용) 구분
  final bool isSelectionMode;

  const FriendListScreen({super.key, this.isSelectionMode = false});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  // 가상의 팔로워(친구) 데이터
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
    "유재석",
    "강호동",
  ];

  // 선택된 친구들을 저장할 리스트 (다중 선택용)
  final Set<String> _selectedFriends = {};

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
        child: ListView.builder(
        itemCount: friends.length,
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemBuilder: (context, index) {
          final name = friends[index];
          final isSelected = _selectedFriends.contains(name);

          return ListTile(
            onTap: () {
              if (widget.isSelectionMode) {
                // [1] 선택 모드: 리스트에 추가/제거 (다중 선택)
                setState(() {
                  if (isSelected) {
                    _selectedFriends.remove(name);
                  } else {
                    _selectedFriends.add(name);
                  }
                });
              } else {
                // [2] 채팅 모드: 해당 친구와의 채팅방으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatDetailScreen(chatPartnerName: name),
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
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: const Text(
              "게시물 2   팔로잉 20   팔로워 30",
              style: TextStyle(color: Colors.grey, fontSize: 12),
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
        ),
      ),
    );
  }
}
