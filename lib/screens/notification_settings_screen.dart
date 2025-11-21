import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // 알림 상태 변수들
  bool _pauseAll = false;
  bool _postCommentAlert = true;
  bool _followAlert = true;
  bool _messageAlert = true;
  bool _marketingAlert = false;

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
          "알림 설정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "푸시 알림",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // 1. 모두 일시 중지
          _buildSwitchTile(
            title: "모두 일시 중지",
            value: _pauseAll,
            onChanged: (val) {
              setState(() {
                _pauseAll = val;
                if (val) {
                  // 모두 중지 시 나머지는 비활성화처럼 보이게 하거나 끌 수 있음
                  _postCommentAlert = false;
                  _followAlert = false;
                  _messageAlert = false;
                  _marketingAlert = false;
                }
              });
            },
          ),
          const Divider(),

          // 2. 게시물, 댓글
          _buildSwitchTile(
            title: "게시물, 댓글",
            value: _postCommentAlert,
            onChanged: _pauseAll
                ? null
                : (val) => setState(() => _postCommentAlert = val),
          ),

          // 3. 팔로잉 및 팔로워
          _buildSwitchTile(
            title: "팔로잉 및 팔로워",
            value: _followAlert,
            onChanged: _pauseAll
                ? null
                : (val) => setState(() => _followAlert = val),
          ),

          // 4. 메시지
          _buildSwitchTile(
            title: "메시지 및 통화",
            value: _messageAlert,
            onChanged: _pauseAll
                ? null
                : (val) => setState(() => _messageAlert = val),
          ),

          const Divider(),

          // 5. 마케팅 정보 수신
          _buildSwitchTile(
            title: "이메일 및 SMS 마케팅 알림",
            subtitle: "이벤트 및 할인 정보를 받습니다.",
            value: _marketingAlert,
            onChanged: _pauseAll
                ? null
                : (val) => setState(() => _marketingAlert = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CA1AF), // 앱 테마 컬러
      contentPadding: EdgeInsets.zero,
    );
  }
}
