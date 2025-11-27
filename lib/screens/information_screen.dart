import 'package:flutter/material.dart';

class InformationScreen extends StatelessWidget {
  const InformationScreen({super.key});

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
          "정보",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: const DecorationImage(
                  image: AssetImage('assets/logo.png'), // 로고 이미지
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Tripic",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "현재 버전 1.0.2",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),

            // 정보 리스트
            _buildInfoRow("개발사", "Tripic Corp."),
            _buildInfoRow("업데이트 날짜", "2025. 11. 20"),
            _buildInfoRow("문의", "support@tripic.com"),

            const Spacer(),
            const Text(
              "Copyright © 2025 Tripic. All rights reserved.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 30),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(
            content,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
