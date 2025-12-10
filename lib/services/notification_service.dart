import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 알림 생성
  Future<void> createNotification({
    required String userId, // 알림을 받을 사용자 ID
    required NotificationType type,
    String? postId,
    String? postImageUrl,
    String? commentText,
    String? chatRoomId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid == userId) {
        // 자기 자신에게는 알림을 보내지 않음
        return;
      }

      // 사용자의 알림 설정 확인
      final settingsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('notifications')
          .get();

      if (settingsDoc.exists) {
        final settings = settingsDoc.data()!;
        final pauseAll = settings['pauseAll'] ?? false;

        // 모든 알림이 중지되어 있으면 알림 생성 안 함
        if (pauseAll) {
          print('알림 중지 상태: 알림 생성 건너뜀');
          return;
        }

        // 타입별 알림 설정 확인
        switch (type) {
          case NotificationType.like:
          case NotificationType.comment:
            final postCommentAlert = settings['postCommentAlert'] ?? true;
            if (!postCommentAlert) {
              print('게시물/댓글 알림 꺼짐: 알림 생성 건너뜀');
              return;
            }
            break;
          case NotificationType.follow:
            final followAlert = settings['followAlert'] ?? true;
            if (!followAlert) {
              print('팔로우 알림 꺼짐: 알림 생성 건너뜀');
              return;
            }
            break;
          case NotificationType.dm:
            final messageAlert = settings['messageAlert'] ?? true;
            if (!messageAlert) {
              print('메시지 알림 꺼짐: 알림 생성 건너뜀');
              return;
            }
            break;
        }
      }

      // 현재 사용자 정보 가져오기
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userData = userDoc.data();

      final notification = NotificationModel(
        id: '', // Firestore에서 자동 생성
        userId: userId,
        fromUserId: currentUser.uid,
        fromUserName: userData?['userName'] ?? userData?['username'] ?? userData?['name'] ?? 'Unknown',
        fromUserProfileImage: userData?['profileImage'],
        type: type,
        postId: postId,
        postImageUrl: postImageUrl,
        commentText: commentText,
        chatRoomId: chatRoomId,
        createdAt: DateTime.now(),
        isRead: false,
      );

      await _firestore.collection('notifications').add(notification.toFirestore());
      print('알림 생성 완료: $type');
    } catch (e) {
      print('알림 생성 실패: $e');
    }
  }

  // 알림 목록 스트림 (실시간 업데이트)
  Stream<List<NotificationModel>> getNotificationsStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      // 클라이언트 측에서 정렬 (createdAt 기준 내림차순)
      final notifications = snapshot.docs
          .map((doc) => NotificationModel.fromFirestore(doc))
          .toList();
      
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      // 최근 50개만 반환
      return notifications.take(50).toList();
    });
  }

  // 읽지 않은 알림 개수 스트림
  Stream<int> getUnreadCountStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots()
        .map((snapshot) {
      // 클라이언트 측에서 isRead 필터링
      return snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isRead'] == false;
      }).length;
    });
  }

  // 알림 읽음 처리
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('알림 읽음 처리 실패: $e');
    }
  }

  // 모든 알림 읽음 처리
  Future<void> markAllAsRead() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      final allNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      final batch = _firestore.batch();
      for (var doc in allNotifications.docs) {
        final data = doc.data() as Map<String, dynamic>;
        // 클라이언트 측에서 isRead 필터링
        if (data['isRead'] == false) {
          batch.update(doc.reference, {'isRead': true});
        }
      }
      await batch.commit();
    } catch (e) {
      print('모든 알림 읽음 처리 실패: $e');
    }
  }

  // 알림 삭제
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      print('알림 삭제 실패: $e');
    }
  }

  // 특정 타입의 중복 알림 방지 (최근 5분 이내)
  Future<bool> shouldCreateNotification({
    required String userId,
    required String fromUserId,
    required NotificationType type,
    String? postId,
  }) async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));
      
      // 기본 쿼리만 사용 (인덱스 불필요)
      final allNotifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('fromUserId', isEqualTo: fromUserId)
          .get();

      // 클라이언트 측에서 필터링
      final recentNotifications = allNotifications.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
        final docType = data['type'] as String?;
        final docPostId = data['postId'] as String?;
        
        if (createdAt == null || createdAt.isBefore(fiveMinutesAgo)) return false;
        if (docType != type.toString().split('.').last) return false;
        if (postId != null && docPostId != postId) return false;
        
        return true;
      }).toList();

      return recentNotifications.isEmpty;
    } catch (e) {
      print('중복 알림 확인 실패: $e');
      return true; // 에러 발생 시 알림 생성 허용
    }
  }
}
