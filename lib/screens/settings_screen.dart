import 'package:flutter/material.dart';
import 'privacy_settings_screen.dart'; // [신규] 공개 범위 설정 화면 import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 타이틀
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 20, bottom: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "SETTING",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.settings, size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 2. 설정 메뉴 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // [수정] 계정공개범위 클릭 시 PrivacySettingsScreen 이동
                  _buildSettingItem(
                    context,
                    Icons.lock_outline,
                    "계정공개범위",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                  ),
                  // 나머지 메뉴는 아직 임시 화면으로 연결
                  _buildSettingItem(context, Icons.block, "차단된계정"),
                  _buildSettingItem(context, Icons.history, "활동"),
                  _buildSettingItem(context, Icons.monitor, "화면"),
                  _buildSettingItem(context, Icons.notifications_none, "알림"),
                  _buildSettingItem(
                    context,
                    Icons.download_outlined,
                    "보관 및 다운로드",
                  ),
                  _buildSettingItem(context, Icons.language, "언어 및 번역"),
                  _buildSettingItem(context, Icons.help_outline, "도움말"),
                  _buildSettingItem(context, Icons.info_outline, "정보"),
                ],
              ),
            ),

            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "닫기",
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // [수정] onTap 콜백을 받을 수 있도록 변경
  Widget _buildSettingItem(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap:
          onTap ??
          () {
            // onTap이 지정되지 않았으면 임시 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => _SettingsDetailScreen(title: title),
              ),
            );
          },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.black),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 0,
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}

// 임시 상세 화면 (그대로 유지)
class _SettingsDetailScreen extends StatelessWidget {
  final String title;
  const _SettingsDetailScreen({required this.title});
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
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.settings, size: 50, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              "'$title' 설정 화면입니다.",
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
