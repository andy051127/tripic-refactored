import 'package:flutter/material.dart';
import '../models/post_model.dart';

class MemberInfoScreen extends StatelessWidget {
  const MemberInfoScreen({super.key});

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
          "회원 정보",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder<String>(
        valueListenable: globalUserName,
        builder: (context, name, _) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                "기본 정보",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoTile(Icons.person_outline, "이름", name),
              _buildInfoTile(Icons.perm_identity, "아이디", "tripic_user_01"),
              _buildInfoTile(Icons.calendar_today, "가입일", "2024. 01. 01"),

              const SizedBox(height: 30),
              const Text(
                "연락처 정보",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<String>(
                valueListenable: globalUserEmail,
                builder: (context, email, _) =>
                    _buildInfoTile(Icons.email_outlined, "이메일", email),
              ),
              ValueListenableBuilder<String>(
                valueListenable: globalUserPhone,
                builder: (context, phone, _) =>
                    _buildInfoTile(Icons.phone_android, "전화번호", phone),
              ),

              const SizedBox(height: 30),
              const Text(
                "활동 정보",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoTile(Icons.grade_outlined, "회원 등급", "일반 회원"),
              _buildInfoTile(Icons.location_on_outlined, "주 활동 지역", "서울, 대한민국"),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 22),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const Spacer(),
          Text(
            content,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
