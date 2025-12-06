import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'other_user_profile_screen.dart';
import 'chat_detail_screen.dart';
import 'package:timeago/timeago.dart' as timeago;

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // 한국어 시간 표기 설정
    timeago.setLocaleMessages('ko', timeago.KoMessages());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '알림',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _notificationService.markAllAsRead();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('모든 알림을 읽음 처리했습니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text(
              '모두 읽음',
              style: TextStyle(
                color: Color(0xFF4CA1AF),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('오류가 발생했습니다: ${snapshot.error}'),
            );
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '알림이 없습니다',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationItem(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('알림이 삭제되었습니다'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () => _handleNotificationTap(notification),
        child: Container(
          color: notification.isRead ? Colors.white : Colors.blue[50],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 프로필 이미지
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[300],
                backgroundImage: notification.fromUserProfileImage != null &&
                        notification.fromUserProfileImage!.isNotEmpty
                    ? NetworkImage(notification.fromUserProfileImage!)
                    : null,
                child: notification.fromUserProfileImage == null ||
                        notification.fromUserProfileImage!.isEmpty
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              // 알림 내용
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        children: [
                          TextSpan(
                            text: notification.fromUserName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: notification.getMessage(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(notification.createdAt, locale: 'ko'),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 게시물 썸네일 (좋아요, 댓글인 경우)
              if (notification.postImageUrl != null &&
                  notification.postImageUrl!.isNotEmpty)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: NetworkImage(notification.postImageUrl!),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              // 읽지 않음 표시
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF4CA1AF),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // 알림 읽음 처리
    if (!notification.isRead) {
      _notificationService.markAsRead(notification.id);
    }

    // 알림 타입에 따라 다른 화면으로 이동
    switch (notification.type) {
      case NotificationType.follow:
        // 팔로우한 사용자 프로필로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtherUserProfileScreen(
              userId: notification.fromUserId,
              userName: notification.fromUserName,
              profileImage: notification.fromUserProfileImage ?? '',
            ),
          ),
        );
        break;

      case NotificationType.like:
      case NotificationType.comment:
        // 게시물 상세로 이동 (현재는 사용자 프로필로 이동)
        // TODO: 게시물 상세 화면 구현 시 수정 필요
        if (notification.postId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                userId: notification.fromUserId,
                userName: notification.fromUserName,
                profileImage: notification.fromUserProfileImage ?? '',
              ),
            ),
          );
        }
        break;

      case NotificationType.dm:
        // 채팅방으로 이동
        if (notification.chatRoomId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreen(
                chatRoomId: notification.chatRoomId!,
                chatPartnerId: notification.fromUserId,
                chatPartnerName: notification.fromUserName,
              ),
            ),
          );
        }
        break;
    }
  }
}
