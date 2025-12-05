import 'package:flutter/foundation.dart';

enum ActivityType { comment, like, save, share }

class ActivityItem {
  final String id;
  final ActivityType type;
  final String postTitle;
  final String content;
  final String time;
  final String? imagePath;
  final String? postId; // 게시물 ID 추가

  ActivityItem({
    required this.type,
    required this.postTitle,
    required this.content,
    required this.time,
    this.imagePath,
    this.postId, // postId 추가
  }) : id = DateTime.now().millisecondsSinceEpoch.toString();
}

// 전역 활동 리스트 (내 활동 기록용)
final ValueNotifier<List<ActivityItem>> globalActivitiesNotifier =
    ValueNotifier<List<ActivityItem>>([]);

// [추가] 전역 보관함 리스트 (실제 저장된 게시물 목록용)
final ValueNotifier<List<ActivityItem>> savedPostsNotifier =
    ValueNotifier<List<ActivityItem>>([]);

// 활동 추가 함수
void addActivity(
  ActivityType type,
  String postTitle,
  String content,
  String? imagePath, {
  String? postId, // postId 파라미터 추가
}) {
  final newItem = ActivityItem(
    type: type,
    postTitle: postTitle,
    content: content,
    time: "방금 전",
    imagePath: imagePath,
    postId: postId, // postId 전달
  );
  globalActivitiesNotifier.value = [newItem, ...globalActivitiesNotifier.value];

  // [추가] 저장(스크랩) 활동인 경우 보관함 리스트에도 추가
  if (type == ActivityType.save) {
    savedPostsNotifier.value = [newItem, ...savedPostsNotifier.value];
  }
}

// [추가] 보관함에서 삭제 함수
void removeSavedPost(String id) {
  final currentSaved = List<ActivityItem>.from(savedPostsNotifier.value);
  currentSaved.removeWhere((item) => item.id == id);
  savedPostsNotifier.value = currentSaved;
}
