import 'package:flutter/material.dart';

class CommunityDetailScreen extends StatelessWidget {
  // 목록에서 전달받을 데이터들
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;

  const CommunityDetailScreen({
    super.key,
    required this.name,
    this.location = "",
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
  });

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
          "커뮤니티",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 작성자 정보 헤더
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/logo.png'), // 임시 이미지
                    backgroundColor: Colors.grey,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (location.isNotEmpty) ...[
                    const Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // 2. 메인 게시글 이미지 (이미지가 있을 때만 표시)
            if (imageUrl != null)
              Container(
                width: double.infinity,
                height: 300, // 사진 크기 시원하게
                color: Colors.grey[200],
                child: Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[100],
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              ),

            // 3. 게시글 내용
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "2025.10.16 작성", // 날짜는 임시 고정
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),

            // 4. 통계 및 액션 버튼
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Icon(Icons.favorite_border, size: 28),
                  const SizedBox(width: 6),
                  Text(
                    stats.split(" · ")[0],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.chat_bubble_outline, size: 28),
                  const SizedBox(width: 6),
                  Text(
                    stats.split(" · ")[1],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 20),
                  const Icon(Icons.near_me_outlined, size: 28), // 종이비행기
                  const SizedBox(width: 6),
                  Text(
                    stats.split(" · ")[2],
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_horiz, size: 28), // 더보기 메뉴
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

            // 5. 댓글 섹션
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "댓글",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  // 댓글 아이템 1 (예시)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey,
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Text(
                                  "chanhui_kk",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "5시간 전",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              "2명만 구매 가능한가요?????",
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40), // 하단 여백
          ],
        ),
      ),
    );
  }
}
