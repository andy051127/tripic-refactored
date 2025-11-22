import 'package:flutter/material.dart';
import 'dart:io';
// import '../models/post_model.dart'; // 기존 모델은 로컬 저장용이라 당분간 주석 처리
import 'package:firebase_storage/firebase_storage.dart'; // 사진 저장소
import 'package:cloud_firestore/cloud_firestore.dart'; // DB
import 'package:firebase_auth/firebase_auth.dart'; // 로그인 정보

class WritePostScreen extends StatefulWidget {
  final List<String> images; // 선택된 이미지 경로 리스트
  final String? taggedFriend;

  const WritePostScreen({super.key, required this.images, this.taggedFriend});

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 업로드 중인지 확인하는 상태 변수 (로딩 표시용)
  bool _isUploading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ★ [핵심] Firebase 업로드 함수
  Future<void> _uploadToFirebase() async {
    // 1. 유효성 검사
    if (_titleController.text.isEmpty || widget.images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("사진과 제목은 필수입니다.")));
      return;
    }

    setState(() {
      _isUploading = true; // 로딩 시작
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
        return;
      }

      // 2. [Storage] 이미지 업로드
      // 파일명: post_images/시간_유저ID.jpg
      final String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(
        'post_images/$fileName',
      );

      // 로컬 파일(widget.images[0])을 가져와서 업로드
      File imageFile = File(widget.images[0]);
      await storageRef.putFile(imageFile);

      // 3. [Storage] 업로드된 이미지의 다운로드 URL 받기
      final String imageUrl = await storageRef.getDownloadURL();

      // 4. [Firestore] 게시글 정보 DB에 저장
      await FirebaseFirestore.instance.collection('posts').add({
        'uid': user.uid, // 작성자 ID
        'username': user.displayName ?? '익명', // 작성자 이름
        'userProfileImage': user.photoURL ?? '', // 작성자 프로필 사진(있으면)
        'title': _titleController.text, // 제목
        'content': _contentController.text, // 내용
        'imageUrl': imageUrl, // ★ 스토리지 이미지 주소
        'location': "Seoul, Korea", // 위치 (나중에 GPS로 교체 가능)
        'taggedFriend': widget.taggedFriend ?? '', // 태그된 친구
        'likes': [], // 좋아요 리스트
        'timestamp': FieldValue.serverTimestamp(), // 서버 시간
      });

      // 5. 성공 처리
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시물이 업로드되었습니다!")));

      // 홈으로 이동 (모든 화면 끄고 이동하거나, 단순히 뒤로가기)
      Navigator.pop(context);
    } catch (e) {
      print("업로드 에러: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("업로드 중 오류가 발생했습니다.")));
    } finally {
      setState(() {
        _isUploading = false; // 로딩 끝
      });
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
          // 업로드 버튼
          TextButton(
            // 로딩 중이면 버튼 비활성화 (null), 아니면 함수 연결
            onPressed: _isUploading ? null : _uploadToFirebase,
            child: _isUploading
                ? const SizedBox(
                    // 로딩 중일 때 뺑뺑이 표시
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "업로드",
                    style: TextStyle(fontSize: 16, color: Colors.blue),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 제목 입력창
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

            // 2. 내용 입력창
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

            // 3. 이미지 미리보기
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
