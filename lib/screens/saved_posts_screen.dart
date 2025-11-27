import 'package:flutter/material.dart';
import 'dart:io';
import '../models/activity_model.dart';

class SavedPostsScreen extends StatelessWidget {
  const SavedPostsScreen({super.key});

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
          "보관함",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<ActivityItem>>(
        valueListenable: savedPostsNotifier,
        builder: (context, savedPosts, child) {
          if (savedPosts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 60, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    "보관된 게시물이 없습니다.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(2),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3열 그리드
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            itemCount: savedPosts.length,
            itemBuilder: (context, index) {
              final item = savedPosts[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 이미지 표시
                  item.imagePath != null
                      ? (item.imagePath!.startsWith('assets')
                            ? Image.asset(item.imagePath!, fit: BoxFit.cover)
                            : Image.file(
                                File(item.imagePath!),
                                fit: BoxFit.cover,
                              ))
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.image, color: Colors.white),
                        ),

                  // 삭제 버튼 (선택 사항)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () {
                        removeSavedPost(item.id); // 삭제 기능
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("보관함에서 삭제되었습니다.")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
        ),
      ),
    );
  }
}
