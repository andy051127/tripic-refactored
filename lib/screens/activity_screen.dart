import 'package:flutter/material.dart';
import '../models/activity_model.dart'; // 모델 import
import 'dart:io';
import 'community_activity_screen.dart'; // 커뮤니티 활동 화면 import
import 'post_detail_screen.dart'; // PostDetailScreen import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 댓글, 좋아요
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
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              tooltip: '활동 내역 초기화',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('활동 내역 초기화'),
                    content: const Text('모든 활동 내역을 삭제하시겠습니까?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      TextButton(
                        onPressed: () {
                          globalActivitiesNotifier.value = [];
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('활동 내역이 초기화되었습니다')),
                          );
                        },
                        child: const Text('삭제', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.black,
            tabs: [
              Tab(text: "댓글"),
              Tab(text: "좋아요"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_CommentTabView(), _LikeTabView()],
        ),
      ),
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
          image: activity.imagePath != null && activity.imagePath!.isNotEmpty
              ? DecorationImage(
                  image: activity.imagePath!.startsWith('http')
                      ? NetworkImage(activity.imagePath!) as ImageProvider
                      : activity.imagePath!.startsWith('assets')
                          ? AssetImage(activity.imagePath!)
                          : FileImage(File(activity.imagePath!)),
                  fit: BoxFit.cover,
                  onError: (e, s) {}, // 에러 발생 시 기본 배경 유지
                )
              : null,
        ),
        child: activity.imagePath == null || activity.imagePath!.isEmpty
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
      onTap: () async {
        print('ActivityItem 클릭됨 - postId: ${activity.postId}');
        
        // Tripic 게시물로 이동 (상세 화면)
        if (activity.postId != null && activity.postId!.isNotEmpty) {
          try {
            print('게시물 ID로 Firestore 조회 중: ${activity.postId}');
            
            // Firestore에서 게시물 데이터 가져오기
            final postDoc = await FirebaseFirestore.instance
                .collection('posts')
                .doc(activity.postId)
                .get();
            
            print('Firestore 문서 존재 여부: ${postDoc.exists}');
            
            if (postDoc.exists && context.mounted) {
              // Post 객체로 변환
              final post = Post.fromMap(
                postDoc.data() as Map<String, dynamic>,
                postDoc.id,
              );
              
              print('Post 객체 생성 완료, 화면 이동 시작');
              
              // PostDetailScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PostDetailScreen(post: post),
                ),
              );
            } else {
              print('게시물을 찾을 수 없음');
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('게시물을 찾을 수 없습니다')),
                );
              }
            }
          } catch (e) {
            print('오류 발생: $e');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('오류가 발생했습니다: $e')),
              );
            }
          }
        } else {
          print('postId가 null이거나 비어있음');
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('이 활동은 이전 버전에서 기록되어 상세 정보가 없습니다.\n우측 상단 삭제 버튼으로 활동 내역을 초기화해주세요.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      },
    );
  }
}
