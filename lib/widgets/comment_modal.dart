import 'package:flutter/material.dart';
import '../models/activity_model.dart'; // 활동 모델 import

class CommentModal extends StatefulWidget {
  // 어떤 게시물에 댓글을 다는지 알기 위해 제목과 이미지 경로를 받음
  final String postTitle;
  final String? postImage;

  const CommentModal({super.key, this.postTitle = "게시물", this.postImage});

  @override
  State<CommentModal> createState() => _CommentModalState();
}

class _CommentModalState extends State<CommentModal> {
  final List<Map<String, String>> _comments = [
    {'name': 'chanhui_kk', 'content': '사진 진짜 잘 찍으셨네요! 👍', 'time': '5분 전'},
    {
      'name': 'travel_lover',
      'content': '여기 어디인가요? 정보 좀 부탁드려요',
      'time': '1시간 전',
    },
  ];
  final TextEditingController _controller = TextEditingController();

  void _addComment() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _comments.add({
          'name': '나(Me)',
          'content': _controller.text,
          'time': '방금 전',
        });

        // [추가] 활동 내역에 저장
        addActivity(
          ActivityType.comment,
          widget.postTitle,
          _controller.text, // 댓글 내용
          widget.postImage,
        );

        _controller.clear();
      });
    }
  }

  // ... (build 메서드 내용은 기존과 동일, 그대로 유지)
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 500,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "댓글",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: _comments.length,
                itemBuilder: (context, index) {
                  final comment = _comments[index];
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    title: Row(
                      children: [
                        Text(
                          comment['name']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          comment['time']!,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      comment['content']!,
                      style: const TextStyle(color: Colors.black87),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
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
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: "댓글 달기...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
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
