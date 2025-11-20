import 'package:flutter/foundation.dart';

// 게시물 데이터 구조 정의
class Post {
  final String userName;
  final String location;
  final String imagePath;
  final String title;
  final String content;
  final bool isFile;

  Post({
    required this.userName,
    required this.location,
    required this.imagePath,
    required this.title,
    required this.content,
    this.isFile = false,
  });
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
