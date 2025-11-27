import 'package:flutter/material.dart';
import 'other_user_profile_screen.dart'; // 타인 프로필 화면
import 'map_search_screen.dart'; // 지도 검색 화면

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // 가상의 사용자 데이터베이스
  final List<Map<String, String>> _allUsers = [
    {"username": "leeeee_kh", "name": "이경환", "image": ""},
    {"username": "chanhui_kk", "name": "김찬희", "image": ""},
    {"username": "happy_traveler", "name": "행복한 여행자", "image": ""},
    {"username": "world_walker", "name": "세계일주", "image": ""},
    {"username": "seoul_lover", "name": "서울사람", "image": ""},
  ];

  // 검색된 사용자 리스트
  List<Map<String, String>> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return []; // 검색어 없으면 빈 리스트 (또는 추천 사용자)
    }
    return _allUsers.where((user) {
      return user['username']!.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          user['name']!.contains(_searchQuery);
    }).toList();
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
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: "검색",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
          // 상단 탭 (계정 / 장소) - 간단히 버튼으로 구현
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabButton("계정", true), // 현재는 계정 검색이 메인
                const SizedBox(width: 20),
                GestureDetector(
                  onTap: () {
                    // 장소 탭을 누르면 지도 검색 화면으로 이동
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MapSearchScreen(),
                      ),
                    );
                  },
                  child: _buildTabButton("장소", false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 검색 결과 리스트
          Expanded(
            child: _searchQuery.isEmpty
                ? const Center(
                    child: Text(
                      "검색어를 입력하세요",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : _filteredUsers.isEmpty
                ? const Center(
                    child: Text(
                      "검색 결과가 없습니다.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          user['username']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(user['name']!),
                        onTap: () {
                          // 사용자 클릭 시 타인 프로필 화면으로 이동
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OtherUserProfileScreen(
                                userName: user['username']!,
                                profileImage: user['image']!,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? Colors.black : Colors.grey,
        ),
      ),
    );
  }
}
