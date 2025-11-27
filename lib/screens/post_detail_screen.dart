import 'package:flutter/material.dart';
import 'dart:io';
import '../models/post_model.dart';
import '../widgets/comment_modal.dart'; // 댓글창 재사용
import 'chat_detail_screen.dart'; // DM용

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.post.likeCount;
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
          "게시물",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 헤더 (작성자 정보)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.userName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              widget.post.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 2. 이미지 (크게 보기)
                  Container(
                    width: double.infinity,
                    // 높이 제한 없이 이미지 비율에 맞게 표시
                    constraints: const BoxConstraints(
                      minHeight: 300,
                      maxHeight: 500,
                    ),
                    color: Colors.grey[200],
                    child: widget.post.isFile
                        ? Image.file(
                            File(widget.post.imagePath),
                            fit: BoxFit.contain,
                          )
                        : (widget.post.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.post.imageUrl,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  widget.post.imagePath,
                                  fit: BoxFit.contain,
                                )),
                  ),

                  // 3. 액션 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLiked = !_isLiked;
                              _isLiked ? _likeCount++ : _likeCount--;
                            });
                          },
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 32,
                            color: _isLiked ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "$_likeCount",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => CommentModal(
                                postTitle: widget.post.title,
                                postImage: widget.post.imageUrl,
                              ),
                            );
                          },
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatDetailScreen(
                                  chatPartnerName: widget.post.userName,
                                ),
                              ),
                            );
                          },
                          child: const Icon(Icons.near_me_outlined, size: 30),
                        ),
                        const Spacer(),
                        const Icon(Icons.bookmark_border, size: 30),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 4. 본문 내용
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.post.content,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "2025.01.01 작성",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. 하단 댓글 바로가기 바 (누르면 댓글창 뜸)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => CommentModal(
                  postTitle: widget.post.title,
                  postImage: widget.post.imageUrl,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text("댓글 달기...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
