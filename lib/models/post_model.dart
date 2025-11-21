import 'package:flutter/foundation.dart';

// 게시물 데이터 구조 정의
class Post {
  final String id; // 게시물 식별을 위한 ID
  final String userName;
  final String location;
  final String imagePath;
  final String title;
  final String content;
  final bool isFile;

  Post({
    String? id,
    required this.userName,
    required this.location,
    required this.imagePath,
    required this.title,
    required this.content,
    this.isFile = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();
}

// 앱 전체에서 공유할 게시물 리스트
final ValueNotifier<List<Post>> globalPostsNotifier =
    ValueNotifier<List<Post>>([
      Post(
        userName: "leeeee_kh",
        location: "Toronto, Canada",
        imagePath: "assets/logo.png",
        title: "기본 게시물",
        content: "The sunset was really good today 🌇",
        isFile: false,
      ),
    ]);

// [추가] 앱 전체에서 공유할 팔로잉 수 (초기값 5)
final ValueNotifier<int> globalFollowingCount = ValueNotifier<int>(5);

// [추가] 앱 전체에서 공유할 팔로워 수 (초기값 "3.1M")
final ValueNotifier<String> globalFollowerCount = ValueNotifier<String>("3.1M");

// [추가] 내 프로필 이미지 경로 (초기값: 로고)
// 이 부분이 없어서 오류가 났던 것입니다.
final ValueNotifier<String> globalProfileImage = ValueNotifier<String>(
  "assets/logo.png",
);
final ValueNotifier<bool> isProfileImageFile = ValueNotifier<bool>(
  false,
); // 파일인지 여부
