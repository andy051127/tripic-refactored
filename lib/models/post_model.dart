import 'package:flutter/foundation.dart';

// 게시물 데이터 구조 정의
class Post {
  final String id;
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

// 팔로잉 수
final ValueNotifier<int> globalFollowingCount = ValueNotifier<int>(5);

// 팔로워 수
final ValueNotifier<String> globalFollowerCount = ValueNotifier<String>("3.1M");

// 프로필 이미지
final ValueNotifier<String> globalProfileImage = ValueNotifier<String>(
  "assets/logo.png",
);
final ValueNotifier<bool> isProfileImageFile = ValueNotifier<bool>(false);

// 차단된 사용자 목록
final ValueNotifier<List<String>> blockedUsersNotifier =
    ValueNotifier<List<String>>([]);

// [추가] 사용자 프로필 정보 (수정 가능하도록 전역 관리)
final ValueNotifier<String> globalUserName = ValueNotifier<String>("leeeee_kh");
final ValueNotifier<String> globalUserBio = ValueNotifier<String>(
  "Traveler ✈️",
);
final ValueNotifier<String> globalUserEmail = ValueNotifier<String>(
  "leeeee_kh@tripic.com",
);
final ValueNotifier<String> globalUserPhone = ValueNotifier<String>(
  "010-1234-5678",
);
