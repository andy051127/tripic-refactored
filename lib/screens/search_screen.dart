import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'other_user_profile_screen.dart'; // 타인 프로필 화면
import 'map_screen.dart'; // 지도 검색 화면

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _searchQuery = "";
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Firestore에서 사용자 검색
      final snapshot = await _firestore.collection('users').get();
      
      final results = <Map<String, dynamic>>[];
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final userName = (data['userName'] ?? '').toString().toLowerCase();
        final email = (data['email'] ?? '').toString().toLowerCase();
        final searchLower = query.toLowerCase();
        
        // 사용자 이름이나 이메일에 검색어가 포함되면 결과에 추가
        if (userName.contains(searchLower) || email.contains(searchLower)) {
          results.add({
            'userId': doc.id,
            'userName': data['userName'] ?? '알 수 없음',
            'email': data['email'] ?? '',
            'profileImage': data['profileImage'] ?? '',
            'bio': data['bio'] ?? '',
          });
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      print('검색 오류: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
        );
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
              hintText: "사용자 이름 검색",
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
              _performSearch(val);
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
                          builder: (context) => const MapScreen(),
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
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator())
                  : _searchQuery.isEmpty
                      ? const Center(
                          child: Text(
                            "사용자 이름을 입력하세요",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : _searchResults.isEmpty
                          ? const Center(
                              child: Text(
                                "검색 결과가 없습니다.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _searchResults.length,
                              itemBuilder: (context, index) {
                                final user = _searchResults[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.grey,
                                    backgroundImage: user['profileImage'] != null &&
                                            user['profileImage'].isNotEmpty
                                        ? NetworkImage(user['profileImage'])
                                        : null,
                                    child: user['profileImage'] == null ||
                                            user['profileImage'].isEmpty
                                        ? const Icon(Icons.person,
                                            color: Colors.white)
                                        : null,
                                  ),
                                  title: Text(
                                    user['userName'] ?? '알 수 없음',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    user['bio'] ?? user['email'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () {
                                    // 사용자 클릭 시 타인 프로필 화면으로 이동
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            OtherUserProfileScreen(
                                          userName: user['userName'] ?? '알 수 없음',
                                          profileImage: user['profileImage'] ?? '',
                                          userId: user['userId'],
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
