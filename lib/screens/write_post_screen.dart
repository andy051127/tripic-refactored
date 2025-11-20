import 'package:flutter/material.dart';
import 'dart:io';
import '../models/post_model.dart'; // 위에서 만든 모델 파일 import

class WritePostScreen extends StatefulWidget {
  final List<String> images;
  final String? taggedFriend;

  const WritePostScreen({super.key, required this.images, this.taggedFriend});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
        title: const Text(
          "새 게시물",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_titleController.text.isEmpty || widget.images.isEmpty) {
                return;
              }

              // 새 게시물 데이터 생성
              final newPost = Post(
                userName: "내 프로필",
                location: "Seoul, Korea",
                imagePath: widget.images[0],
                title: _titleController.text,
                content: _contentController.text,
                isFile: true,
              );

              // 전역 리스트에 추가
              final currentPosts = globalPostsNotifier.value;
              globalPostsNotifier.value = [newPost, ...currentPosts];

              // 홈으로 이동
              Navigator.popUntil(context, (route) => route.isFirst);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("게시물이 업로드되었습니다!")));
            },
            child: const Text(
              "업로드",
              style: TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "게시물의 제목을 입력해주세요.",
                ),
              ),
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "내용을 입력해주세요.",
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: widget.images.isNotEmpty
                    ? Image.file(
                        File(widget.images[0]),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(height: 200, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
