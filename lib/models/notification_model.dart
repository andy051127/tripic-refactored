import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  dm, // DM 수신
  follow, // 팔로우
  like, // 좋아요
  comment, // 댓글
}

class NotificationModel {
  final String id;
  final String userId; // 알림을 받을 사용자 ID
  final String fromUserId; // 알림을 보낸 사용자 ID
  final String fromUserName; // 알림을 보낸 사용자 이름
  final String? fromUserProfileImage; // 알림을 보낸 사용자 프로필 이미지
  final NotificationType type; // 알림 타입
  final String? postId; // 관련 게시물 ID (좋아요, 댓글인 경우)
  final String? postImageUrl; // 게시물 썸네일 이미지
  final String? commentText; // 댓글 내용 (댓글인 경우)
  final String? chatRoomId; // 채팅방 ID (DM인 경우)
  final DateTime createdAt; // 알림 생성 시간
  final bool isRead; // 읽음 여부

  NotificationModel({
    required this.id,
    required this.userId,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserProfileImage,
    required this.type,
    this.postId,
    this.postImageUrl,
    this.commentText,
    this.chatRoomId,
    required this.createdAt,
    this.isRead = false,
  });

  // Firestore에서 데이터 가져올 때
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserProfileImage: data['fromUserProfileImage'],
      type: _parseNotificationType(data['type']),
      postId: data['postId'],
      postImageUrl: data['postImageUrl'],
      commentText: data['commentText'],
      chatRoomId: data['chatRoomId'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  // Firestore에 저장할 때
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserProfileImage': fromUserProfileImage,
      'type': type.toString().split('.').last,
      'postId': postId,
      'postImageUrl': postImageUrl,
      'commentText': commentText,
      'chatRoomId': chatRoomId,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
    };
  }

  // 알림 타입 파싱
  static NotificationType _parseNotificationType(String? typeString) {
    switch (typeString) {
      case 'dm':
        return NotificationType.dm;
      case 'follow':
        return NotificationType.follow;
      case 'like':
        return NotificationType.like;
      case 'comment':
        return NotificationType.comment;
      default:
        return NotificationType.like;
    }
  }

  // 알림 메시지 생성
  String getMessage() {
    switch (type) {
      case NotificationType.dm:
        return '님이 메시지를 보냈습니다.';
      case NotificationType.follow:
        return '님이 회원님을 팔로우하기 시작했습니다.';
      case NotificationType.like:
        return '님이 회원님의 게시물을 좋아합니다.';
      case NotificationType.comment:
        if (commentText != null && commentText!.isNotEmpty) {
          return '님이 댓글을 남겼습니다: $commentText';
        }
        return '님이 회원님의 게시물에 댓글을 남겼습니다.';
    }
  }

  // 읽음 처리된 알림 복사본 생성
  NotificationModel copyWith({
    String? id,
    String? userId,
    String? fromUserId,
    String? fromUserName,
    String? fromUserProfileImage,
    NotificationType? type,
    String? postId,
    String? postImageUrl,
    String? commentText,
    String? chatRoomId,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserProfileImage: fromUserProfileImage ?? this.fromUserProfileImage,
      type: type ?? this.type,
      postId: postId ?? this.postId,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      commentText: commentText ?? this.commentText,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}
