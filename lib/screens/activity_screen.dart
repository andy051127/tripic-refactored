import 'package:flutter/material.dart';
import '../models/activity_model.dart'; // 모델 import
import 'dart:io';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, // 댓글, 좋아요, 스크랩, 공유
      child: Scaffold(
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
            "내 활동",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: "댓글"),
              Tab(text: "좋아요"),
              Tab(text: "스크랩"),
              Tab(text: "공유"), // 공유 내역은 추후 구현 가능
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildActivityList(ActivityType.comment),
            _buildActivityList(ActivityType.like),
            _buildActivityList(ActivityType.save),
            _buildActivityList(ActivityType.share),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityList(ActivityType targetType) {
    return ValueListenableBuilder<List<ActivityItem>>(
      valueListenable: globalActivitiesNotifier,
      builder: (context, activities, child) {
        // 해당 탭의 타입과 일치하는 활동만 필터링
        final filteredList = activities
            .where((item) => item.type == targetType)
            .toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Text("활동 내역이 없습니다.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          itemCount: filteredList.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = filteredList[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 10,
              ),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                  image: item.imagePath != null
                      ? DecorationImage(
                          image: item.imagePath!.startsWith('assets')
                              ? AssetImage(item.imagePath!) as ImageProvider
                              : FileImage(File(item.imagePath!)),
                          fit: BoxFit.cover,
                          onError: (e, s) {}, // 에러 발생 시 기본 배경 유지
                        )
                      : null,
                ),
                child: item.imagePath == null
                    ? const Icon(Icons.image, color: Colors.grey)
                    : null,
              ),
              title: Text(
                item.content,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  "${item.postTitle} • ${item.time}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              onTap: () {
                // 클릭 시 해당 게시물로 이동하는 기능 (추후 구현 가능)
              },
            );
          },
        );
      },
    );
  }
}
