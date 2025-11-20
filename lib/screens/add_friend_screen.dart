import 'package:flutter/material.dart';

class AddFriendScreen extends StatelessWidget {
  const AddFriendScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 더미 친구 데이터
    final List<String> friends = [
      "김찬희",
      "가나다",
      "이경환",
      "이예진",
      "안해진",
      "야구오",
      "김지오",
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
        title: const Text(
          "친구 목록",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: friends.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            title: Text(
              friends[index],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text(
              "게시물 2  팔로잉 20  팔로워 30",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              // 친구 선택 시 이름 돌려주며 화면 닫기
              Navigator.pop(context, friends[index]);
            },
          );
        },
      ),
    );
  }
}
