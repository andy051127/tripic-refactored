import 'package:flutter/material.dart';
import 'friend_list_screen.dart'; // 친구 선택을 위해 필요

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  // 설정 값 상태 관리
  bool _isPublicToFriendsOnly = false; // 친구에게만 공개
  bool _isPublicToEveryone = true; // 모든 사람에게 공개
  bool _isPublicToCloseFriends = false; // 친한 친구에게만 공개

  List<String> _selectedSpecificFriends = []; // [수정] 선택한 특정 친구 리스트 (여러 명)

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
          "계정 공개 범위",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "내 게시물을 볼 수 있는 사람을 설정하세요.",
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 20),

          // 1. 모든 사람에게 공개
          _buildSwitchTile(
            title: "모든 사람에게 공개",
            subtitle: "누구나 내 게시물을 볼 수 있습니다.",
            value: _isPublicToEveryone,
            onChanged: (val) {
              setState(() {
                _isPublicToEveryone = val;
                if (val) {
                  _isPublicToFriendsOnly = false;
                  _isPublicToCloseFriends = false;
                  _selectedSpecificFriends.clear(); // 특정 친구 선택 해제
                }
              });
            },
          ),

          const Divider(),

          // 2. 친구에게만 공개
          _buildSwitchTile(
            title: "친구에게만 공개",
            subtitle: "팔로워들만 내 게시물을 볼 수 있습니다.",
            value: _isPublicToFriendsOnly,
            onChanged: (val) {
              setState(() {
                _isPublicToFriendsOnly = val;
                if (val) {
                  _isPublicToEveryone = false;
                  _isPublicToCloseFriends = false;
                  _selectedSpecificFriends.clear();
                }
              });
            },
          ),

          const Divider(),

          // 3. 친한 친구에게만 공개
          _buildSwitchTile(
            title: "친한 친구에게만 공개",
            subtitle: "친한 친구 리스트에 있는 사람만 볼 수 있습니다.",
            value: _isPublicToCloseFriends,
            onChanged: (val) {
              setState(() {
                _isPublicToCloseFriends = val;
                if (val) {
                  _isPublicToEveryone = false;
                  _isPublicToFriendsOnly = false;
                  _selectedSpecificFriends.clear();
                }
              });
            },
          ),

          const Divider(),
          const SizedBox(height: 20),

          // 4. 선택한 친구에게만 공개 (친구 목록 이동)
          const Text(
            "특정 대상에게 공개",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          GestureDetector(
            onTap: () async {
              // 친구 목록 화면으로 이동 (선택 모드)
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const FriendListScreen(isSelectionMode: true),
                ),
              );

              // [수정] 리스트(List<String>) 형태로 결과를 받음
              if (result != null &&
                  result is List<String> &&
                  result.isNotEmpty) {
                setState(() {
                  _selectedSpecificFriends = result;
                  // 다른 옵션 끄기
                  _isPublicToEveryone = false;
                  _isPublicToFriendsOnly = false;
                  _isPublicToCloseFriends = false;
                });
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedSpecificFriends.isNotEmpty
                      ? Colors.blue
                      : Colors.transparent,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "선택한 친구에게만 공개",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_selectedSpecificFriends.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            // [수정] 선택된 친구들 이름 표시 (최대 3명 + 외 N명)
                            child: Text(
                              "선택됨: ${_formatFriendList(_selectedSpecificFriends)}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 친구 리스트를 보기 좋게 포맷팅하는 함수
  String _formatFriendList(List<String> friends) {
    if (friends.isEmpty) return "";
    if (friends.length <= 3) {
      return friends.join(", ");
    } else {
      return "${friends[0]}, ${friends[1]} 외 ${friends.length - 2}명";
    }
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CA1AF), // Tripic 메인 컬러
      contentPadding: EdgeInsets.zero,
    );
  }
}
