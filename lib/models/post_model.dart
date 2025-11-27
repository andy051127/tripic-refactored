import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String uid;
  final String userName;
  final String location;
  final String title;
  final String content;
  final int likeCount;
  final Timestamp createdAt;
  final String imageUrl;
  final String imagePath;
  final bool isFile;
  final String category;

  Post({
    String? id,
    this.uid = '',
    required this.userName,
    required this.location,
    required this.title,
    required this.content,
    this.likeCount = 0,
    Timestamp? createdAt,
    this.imageUrl = '',
    this.imagePath = '',
    this.isFile = false,
    this.category = 'feed',
  }) : this.id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       this.createdAt = createdAt ?? Timestamp.now();

  factory Post.fromMap(Map<String, dynamic> data, String documentId) {
    return Post(
      id: documentId,
      uid: data['uid'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      location: data['location'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      createdAt: data['createdAt'] as Timestamp?,
      imageUrl: data['imageUrl'] ?? '',
      imagePath: data['imageUrl'] ?? '',
      isFile: false,
      category: data['category'] ?? 'feed',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'location': location,
      'title': title,
      'content': content,
      'likeCount': likeCount,
      'createdAt': createdAt,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}

final ValueNotifier<List<Post>> globalPostsNotifier = ValueNotifier<List<Post>>(
  [],
);

// 팔로워/팔로잉 수 관리 (초기값 0)
final ValueNotifier<int> globalFollowingCount = ValueNotifier<int>(0);
final ValueNotifier<int> globalFollowerCount = ValueNotifier<int>(0);

final ValueNotifier<String> globalProfileImage = ValueNotifier<String>(
  "assets/logo.png",
);
final ValueNotifier<bool> isProfileImageFile = ValueNotifier<bool>(false);

final ValueNotifier<List<String>> blockedUsersNotifier =
    ValueNotifier<List<String>>([]);

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
