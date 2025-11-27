import 'package:flutter/material.dart';
import 'dart:io';
import '../services/firestore_service.dart';
import '../models/post_model.dart'; // [중요] 로컬 상태 업데이트를 위해 import

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
  final FirestoreService _firestoreService = FirestoreService();

  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _uploadPost() async {
    if (_titleController.text.isEmpty || widget.images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("사진과 제목은 필수입니다!")));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isUploading = true);

    try {
      // 1. Firestore에 저장 (서버)
      await _firestoreService.addPost(
        title: _titleController.text,
        content: _contentController.text,
        location: "Seoul, Korea", // 추후 위치 선택 연동 가능
        localImagePath: widget.images[0],
        taggedFriend: widget.taggedFriend,
      );

      // 2. [핵심 추가] 로컬 상태(globalPostsNotifier)에도 추가하여 즉시 반영
      // (Firestore 스트림을 쓰는 곳은 자동 반영되지만, 로컬 상태를 쓰는 곳을 위해 추가)
      final newLocalPost = Post(
        userName: "내 프로필", // 또는 현재 로그인 유저 정보
        location: "Seoul, Korea",
        imagePath: widget.images[0],
        title: _titleController.text,
        content: _contentController.text,
        isFile: true, // 로컬 파일이므로 true
      );

      // 리스트 맨 앞에 추가
      final currentPosts = List<Post>.from(globalPostsNotifier.value);
      currentPosts.insert(0, newLocalPost);
      globalPostsNotifier.value = currentPosts;

      if (!mounted) return;

      // 홈으로 복귀
      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시물이 성공적으로 업로드되었습니다! 🎉")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("업로드 실패: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
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
        title: const Text(
          "새 게시물",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isUploading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _uploadPost,
                  child: const Text(
                    "업로드",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
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
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: widget.images.isNotEmpty
                              ? Image.file(
                                  File(widget.images[0]),
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.image,
                                    size: 50,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        if (widget.taggedFriend != null)
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "함께: ${widget.taggedFriend!}",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: 150,
                      width: double.infinity,
                      color: Colors.blue[50],
                      child: const Center(child: Text("지도 위치 표시")),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
