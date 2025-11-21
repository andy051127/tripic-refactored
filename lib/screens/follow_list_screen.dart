import 'package:flutter/material.dart';

class FollowListScreen extends StatelessWidget {
  final String userName;
  final int initialIndex; // 0: 팔로워, 1: 팔로잉

  const FollowListScreen({
    super.key,
    required this.userName,
    required this.initialIndex,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: initialIndex,
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
            userName,
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
        body: TabBarView(
          children: [
            _buildUserList(isFollower: true),
            _buildUserList(isFollower: false),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({required bool isFollower}) {
    // 더미 데이터 생성
    final List<String> users = isFollower
        ? ["김찬희", "이경환", "박지성", "손흥민", "아이유", "유재석", "강호동"]
        : ["이경환", "안해진", "박지성", "손흥민"];

    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          title: Text(
            users[index],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text(
            "여행을 좋아하는 사람입니다.",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isFollower
                  ? Colors.blue
                  : Colors.grey[200], // 팔로워면 맞팔 버튼(파랑), 팔로잉이면 삭제 버튼(회색)
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isFollower ? "팔로우" : "삭제",
              style: TextStyle(
                color: isFollower ? Colors.white : Colors.black,
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
