import 'package:flutter/material.dart';
import '../models/activity_model.dart'; // 모델 import
import 'dart:io';
import 'community_activity_screen.dart'; // 커뮤니티 활동 화면 import

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // 댓글, 좋아요, 공유
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
              Tab(text: "공유"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CommentTabView(), _LikeTabView(), _ShareTabView()],
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

// 댓글 탭 뷰 (커뮤니티 / Tripic 구분)
class _CommentTabView extends StatelessWidget {
  const _CommentTabView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tripic 섹션
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tripic',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const _TripicCommentList(),
          const SizedBox(height: 20),
          // 커뮤니티 섹션
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '커뮤니티',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const _CommunityCommentList(),
        ],
      ),
    );
  }
}

// 좋아요 탭 뷰 (커뮤니티 / Tripic 구분)
class _LikeTabView extends StatelessWidget {
  const _LikeTabView();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tripic 섹션
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tripic',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const _TripicLikeList(),
          const SizedBox(height: 20),
          // 커뮤니티 섹션
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  '커뮤니티',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const _CommunityLikeList(),
        ],
      ),
    );
  }
}

// 공유 탭 뷰 (기존 방식)
class _ShareTabView extends StatelessWidget {
  const _ShareTabView();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityItem>>(
      valueListenable: globalActivitiesNotifier,
      builder: (context, activities, child) {
        final filteredActivities = activities
            .where((activity) => activity.type == ActivityType.share)
            .toList();

        if (filteredActivities.isEmpty) {
          return const Center(
            child: Text(
              "아직 공유한 게시물이 없습니다.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: filteredActivities.length,
          itemBuilder: (context, index) {
            final activity = filteredActivities[index];
            return _ActivityItem(activity: activity);
          },
        );
      },
    );
  }
}

// Tripic 댓글 리스트
class _TripicCommentList extends StatelessWidget {
  const _TripicCommentList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityItem>>(
      valueListenable: globalActivitiesNotifier,
      builder: (context, activities, child) {
        final filteredActivities = activities
            .where((activity) => activity.type == ActivityType.comment)
            .toList();

        if (filteredActivities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "아직 댓글한 게시물이 없습니다.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filteredActivities.length,
          itemBuilder: (context, index) {
            final activity = filteredActivities[index];
            return _ActivityItem(activity: activity);
          },
        );
      },
    );
  }
}

// 커뮤니티 댓글 리스트
class _CommunityCommentList extends StatelessWidget {
  const _CommunityCommentList();

  @override
  Widget build(BuildContext context) {
    return const CommunityActivityList(activityType: 'comment');
  }
}

// Tripic 좋아요 리스트
class _TripicLikeList extends StatelessWidget {
  const _TripicLikeList();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<ActivityItem>>(
      valueListenable: globalActivitiesNotifier,
      builder: (context, activities, child) {
        final filteredActivities = activities
            .where((activity) => activity.type == ActivityType.like)
            .toList();

        if (filteredActivities.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                "아직 좋아요한 게시물이 없습니다.",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: filteredActivities.length,
          itemBuilder: (context, index) {
            final activity = filteredActivities[index];
            return _ActivityItem(activity: activity);
          },
        );
      },
    );
  }
}

// 커뮤니티 좋아요 리스트
class _CommunityLikeList extends StatelessWidget {
  const _CommunityLikeList();

  @override
  Widget build(BuildContext context) {
    return const CommunityActivityList(activityType: 'like');
  }
}

// 활동 아이템 위젯
class _ActivityItem extends StatelessWidget {
  final ActivityItem activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
          image: activity.imagePath != null
              ? DecorationImage(
                  image: activity.imagePath!.startsWith('assets')
                      ? AssetImage(activity.imagePath!) as ImageProvider
                      : FileImage(File(activity.imagePath!)),
                  fit: BoxFit.cover,
                  onError: (e, s) {}, // 에러 발생 시 기본 배경 유지
                )
              : null,
        ),
        child: activity.imagePath == null
            ? const Icon(Icons.image, color: Colors.grey)
            : null,
      ),
      title: Text(
        activity.content,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(
          "${activity.postTitle} • ${activity.time}",
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
      onTap: () {
        // 클릭 시 해당 게시물로 이동하는 기능 (추후 구현 가능)
      },
    );
  }
}
