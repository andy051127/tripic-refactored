import 'package:flutter/material.dart';
import '../models/post_model.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userName;
  final String profileImage;

  const OtherUserProfileScreen({
    super.key,
    required this.userName,
    required this.profileImage, // 프로필 이미지 경로 (없으면 기본값 사용)
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  bool _isFollowing = false; // 팔로우 상태

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
        centerTitle: false,
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_horiz, color: Colors.black),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverList(
                delegate: SliverChildListDelegate([_buildProfileHeader()]),
              ),
            ];
          },
          body: Column(
            children: [
              const TabBar(
                indicatorColor: Colors.black,
                labelColor: Colors.black,
                unselectedLabelColor: Colors.grey,
                tabs: [
                  Tab(icon: Icon(Icons.grid_on)),
                  Tab(icon: Icon(Icons.person_pin_outlined)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // 1. 게시물 그리드 (더미 데이터)
                    _buildPostGrid(),
                    // 2. 태그된 게시물 (더미)
                    const Center(child: Text("태그된 게시물이 없습니다.")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.grey,
                // 이미지 경로가 에셋인지 네트워크인지 파일인지 확인 필요하지만 여기선 간단히 처리
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem("12", "게시물"),
                    _buildStatItem("1.2K", "팔로워"),
                    _buildStatItem("150", "팔로잉"),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.userName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const Text("여행을 좋아하는 사람입니다. ✈️", style: TextStyle(fontSize: 14)),
          const SizedBox(height: 16),

          // 팔로우 / 메시지 버튼
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isFollowing = !_isFollowing;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isFollowing ? Colors.white : Colors.blue,
                      border: Border.all(
                        color: _isFollowing
                            ? Colors.grey.shade300
                            : Colors.transparent,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(
                        _isFollowing ? "팔로잉" : "팔로우",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isFollowing ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Text(
                      "메시지",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPostGrid() {
    // 이 사용자의 게시물만 보여줘야 하지만, 지금은 예시로 9개 더미 박스 표시
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 9,
      itemBuilder: (context, index) {
        return Container(
          color: Colors.grey[300],
          child: const Icon(Icons.image, color: Colors.white),
        );
      },
    );
  }
}
