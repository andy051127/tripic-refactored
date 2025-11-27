import 'package:flutter/material.dart';
import 'chat_detail_screen.dart'; // DM 이동용
import 'package:intl/intl.dart'; // 날짜 포맷용

class CommunityDetailScreen extends StatefulWidget {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final DateTime createdAt; // [추가] 작성일 받기

  const CommunityDetailScreen({
    super.key,
    required this.name,
    this.location = "",
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    required this.createdAt, // 필수 인자로 변경
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  // 좋아요 상태
  bool _isLiked = false;
  int _likeCount = 0;

  // 댓글 상태
  final TextEditingController _commentController = TextEditingController();

  // 댓글 리스트 초기화 (기본 댓글 삭제됨)
  final List<Map<String, String>> _comments = [];

  @override
  void initState() {
    super.initState();
    // stats 문자열에서 초기 좋아요 수 파싱
    try {
      _likeCount = int.parse(widget.stats.split(' · ')[0]);
    } catch (e) {
      _likeCount = 0;
    }
  }

  // 댓글 추가 함수
  void _addComment() {
    if (_commentController.text.isNotEmpty) {
      setState(() {
        _comments.add({
          'name': '나(Me)',
          'content': _commentController.text,
          'time': '방금 전',
        });
        _commentController.clear();
      });
      FocusScope.of(context).unfocus();
    }
  }

  // 더보기 메뉴 (점 3개)
  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionItem(
              Icons.person_add_outlined,
              "팔로우",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("팔로우 했습니다!")));
              },
            ),
            const Divider(height: 1),
            _buildOptionItem(
              Icons.bookmark_border,
              "저장",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("게시물이 저장되었습니다.")));
              },
            ),
            const Divider(height: 1),
            _buildOptionItem(
              Icons.visibility_off_outlined,
              "숨기기",
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("게시물을 숨겼습니다.")));
              },
            ),
            const Divider(height: 1),
            _buildOptionItem(
              Icons.campaign_outlined,
              "신고",
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("신고가 접수되었습니다.")));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    IconData icon,
    String text, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // [수정] 날짜 포맷팅
    String formattedDate = DateFormat('yyyy.MM.dd').format(widget.createdAt);

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
        actions: [
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
          Expanded(
            child: SingleChildScrollView(
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
                          backgroundColor: Colors.grey,
                          backgroundImage: AssetImage('assets/logo.png'),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          widget.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        if (widget.location.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.location,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. 메인 게시글 이미지
                  if (widget.imageUrl != null)
                    Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[200],
                      child: Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  // 3. 게시글 내용
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // [수정됨] 실제 작성 날짜 표시
                        Text(
                          "$formattedDate 작성",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. 통계 및 액션 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLiked = !_isLiked;
                              if (_isLiked)
                                _likeCount++;
                              else
                                _likeCount--;
                            });
                          },
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 28,
                            color: _isLiked ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "$_likeCount",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(width: 20),

                        const Icon(Icons.chat_bubble_outline, size: 28),
                        const SizedBox(width: 6),
                        Text(
                          "${_comments.length}",
                          style: const TextStyle(fontSize: 16),
                        ),

                        const SizedBox(width: 20),

                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  chatPartnerName: widget.name,
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.near_me_outlined, size: 28),
                        ),

                        const Spacer(),
                        const Icon(Icons.bookmark_border, size: 28),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

                  // 5. 댓글 리스트 섹션
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "댓글",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_comments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "아직 댓글이 없습니다. 첫 댓글을 남겨보세요!",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comments.length,
                            itemBuilder: (context, index) {
                              final comment = _comments[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                comment['name']!,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                comment['time']!,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            comment['content']!,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.near_me_outlined,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChatDetailScreen(
                                                  chatPartnerName:
                                                      comment['name']!,
                                                ),
                                          ),
                                        );
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. 하단 댓글 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 20, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "댓글 달기...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _addComment,
                  child: const Text(
                    "게시",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
