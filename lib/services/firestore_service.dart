import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/travel_plan_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // [기존] 게시물 업로드
  Future<void> addPost({
    required String title,
    required String content,
    required String location,
    String? localImagePath, // 단일 이미지 (하위 호환성)
    List<String>? localImagePaths, // 여러 이미지
    String? taggedFriend,
    String category = 'feed',
    String? dateRange,
    int? memberCount,
    bool isAnonymous = false,
    double? latitude,
    double? longitude,
    String? locationName, // 위치 이름 추가
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // [수정] Firestore에서 사용자 정보 가져오기
      String userName = '알 수 없음';
      String userProfileImage = '';
      
      if (!isAnonymous) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          userName = userData?['userName'] ?? userData?['username'] ?? userData?['name'] ?? '알 수 없음';
          userProfileImage = userData?['profileImage'] ?? '';
        }
      } else {
        userName = '익명';
      }

      List<String> downloadUrls = [];
      
      // 여러 이미지 처리
      final imagePaths = localImagePaths ?? (localImagePath != null ? [localImagePath] : []);
      
      for (String imagePath in imagePaths) {
        if (imagePath.isNotEmpty) {
          File file = File(imagePath);
          if (file.existsSync()) {
            String fileName =
                "${DateTime.now().millisecondsSinceEpoch}_${user.uid}_${downloadUrls.length}.jpg";
            Reference ref = _storage.ref().child('post_images/$fileName');
            UploadTask uploadTask = ref.putFile(file);
            TaskSnapshot snapshot = await uploadTask;
            String url = await snapshot.ref.getDownloadURL();
            downloadUrls.add(url);
          }
        }
      }

      Map<String, dynamic> postData = {
        'uid': user.uid,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'title': title,
        'content': content,
        'location': location,
        'imageUrl': downloadUrls.isNotEmpty ? downloadUrls[0] : '', // 첫 번째 이미지를 기본 이미지로
        'imageUrls': downloadUrls, // 모든 이미지 URL
        'taggedFriend': taggedFriend ?? '',
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'category': category,
      };

      if (dateRange != null) postData['dateRange'] = dateRange;
      if (memberCount != null) postData['memberCount'] = memberCount;
      postData['isAnonymous'] = isAnonymous;
      if (latitude != null) postData['latitude'] = latitude;
      if (longitude != null) postData['longitude'] = longitude;
      if (locationName != null) postData['locationName'] = locationName; // 위치 이름 저장

      await _db.collection('posts').add(postData);
    } catch (e) {
      print("업로드 실패: $e");
      rethrow;
    }
  }

  // [기존] 게시물 스트림
  Stream<QuerySnapshot> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- [여행 계획 관련 코드] ---

  // 1. 여행 계획 저장 (생성)
  Future<void> addTravelPlan(TravelPlan plan) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      Map<String, dynamic> data = plan.toMap();
      data['uid'] = user.uid;
      await _db.collection('travel_plans').add(data);
    } catch (e) {
      print("여행 계획 저장 실패: $e");
      rethrow;
    }
  }

  // [추가] 2. 여행 계획 수정 (Update)
  Future<void> updateTravelPlan(TravelPlan plan) async {
    try {
      // id를 이용해 해당 문서 업데이트
      await _db.collection('travel_plans').doc(plan.id).update(plan.toMap());
    } catch (e) {
      print("여행 계획 수정 실패: $e");
      rethrow;
    }
  }

  // [추가] 3. 여행 계획 삭제 (Delete)
  Future<void> deleteTravelPlan(String planId) async {
    try {
      await _db.collection('travel_plans').doc(planId).delete();
    } catch (e) {
      print("여행 계획 삭제 실패: $e");
      rethrow;
    }
  }

  // 4. 내 여행 계획 불러오기
  Stream<QuerySnapshot> getMyTravelPlansStream() {
    User? user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _db
        .collection('travel_plans')
        .where('uid', isEqualTo: user.uid)
        .snapshots();
  }

  // --- [팔로우/팔로잉 기능] ---

  // 1. 팔로우하기
  Future<void> followUser(String targetUserId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 내 following 컬렉션에 추가
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(targetUserId)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 상대방의 followers 컬렉션에 추가
      await _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(user.uid)
          .set({
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("팔로우 실패: $e");
      rethrow;
    }
  }

  // 2. 언팔로우하기
  Future<void> unfollowUser(String targetUserId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 내 following 컬렉션에서 제거
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(targetUserId)
          .delete();

      // 상대방의 followers 컬렉션에서 제거
      await _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(user.uid)
          .delete();
    } catch (e) {
      print("언팔로우 실패: $e");
      rethrow;
    }
  }

  // 3. 팔로우 여부 확인
  Future<bool> isFollowing(String targetUserId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('following')
          .doc(targetUserId)
          .get();

      return doc.exists;
    } catch (e) {
      print("팔로우 확인 실패: $e");
      return false;
    }
  }

  // 4. 팔로워 목록 가져오기 (스트림)
  Stream<QuerySnapshot> getFollowersStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('followers')
        .snapshots();
  }

  // 5. 팔로잉 목록 가져오기 (스트림)
  Stream<QuerySnapshot> getFollowingStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('following')
        .snapshots();
  }

  // 6. 팔로워 삭제 (내 팔로워 목록에서 특정 사용자 제거)
  Future<void> removeFollower(String followerUserId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 내 followers 컬렉션에서 해당 사용자 제거
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('followers')
          .doc(followerUserId)
          .delete();

      // 상대방의 following 컬렉션에서 나를 제거
      await _db
          .collection('users')
          .doc(followerUserId)
          .collection('following')
          .doc(user.uid)
          .delete();

      print('✅ 팔로워 삭제 완료: $followerUserId');
    } catch (e) {
      print("팔로워 삭제 실패: $e");
      rethrow;
    }
  }

  // 6. 팔로워/팔로잉 수 가져오기
  Future<Map<String, int>> getFollowCounts(String userId) async {
    try {
      final followersSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();

      final followingSnapshot = await _db
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();

      return {
        'followers': followersSnapshot.docs.length,
        'following': followingSnapshot.docs.length,
      };
    } catch (e) {
      print("팔로우 수 가져오기 실패: $e");
      return {'followers': 0, 'following': 0};
    }
  }

  // 7. 사용자 정보 가져오기 (userName, profileImage 등)
  Future<Map<String, dynamic>?> getUserInfo(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          // userName 필드가 없으면 다른 필드들도 확인
          return {
            ...data,
            'userName': data['userName'] ?? data['username'] ?? data['name'] ?? '알 수 없음',
          };
        }
      }
      return null;
    } catch (e) {
      print("사용자 정보 가져오기 실패: $e");
      return null;
    }
  }

  // 8. 프로필 이미지 업로드
  Future<String> uploadProfileImage(String localImagePath) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      File file = File(localImagePath);
      if (!file.existsSync()) throw Exception("파일이 존재하지 않습니다.");

      String fileName = "profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child('profile_images/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore에 프로필 이미지 URL만 업데이트 (기존 사용자 정보는 유지)
      await _db.collection('users').doc(user.uid).update({
        'profileImage': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      print("프로필 이미지 업로드 실패: $e");
      rethrow;
    }
  }

  // --- [좋아요 기능] ---

  // 1. 좋아요 추가
  Future<void> likePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      final likeRef = _db
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid);

      final likeDoc = await likeRef.get();

      if (!likeDoc.exists) {
        // 좋아요 추가
        await likeRef.set({
          'timestamp': FieldValue.serverTimestamp(),
        });

        // 게시물의 likeCount 증가
        await _db.collection('posts').doc(postId).update({
          'likeCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      print("좋아요 추가 실패: $e");
      rethrow;
    }
  }

  // 2. 좋아요 취소
  Future<void> unlikePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      final likeRef = _db
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid);

      final likeDoc = await likeRef.get();

      if (likeDoc.exists) {
        // 좋아요 제거
        await likeRef.delete();

        // 게시물의 likeCount 감소
        await _db.collection('posts').doc(postId).update({
          'likeCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      print("좋아요 취소 실패: $e");
      rethrow;
    }
  }

  // 3. 좋아요 여부 확인
  Future<bool> isPostLiked(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(user.uid)
          .get();

      return doc.exists;
    } catch (e) {
      print("좋아요 확인 실패: $e");
      return false;
    }
  }

  // 4. 좋아요 수 실시간 스트림
  Stream<int> getLikeCountStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .snapshots()
        .map((snapshot) => snapshot.data()?['likeCount'] ?? 0);
  }

  // --- [댓글 기능] ---

  // 1. 댓글 추가
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['userName'] ?? userData?['username'] ?? userData?['name'] ?? '알 수 없음';
      final userProfileImage = userData?['profileImage'] ?? '';

      // 댓글 추가
      await _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .add({
        'uid': user.uid,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("댓글 추가 실패: $e");
      rethrow;
    }
  }

  // 2. 댓글 삭제
  Future<void> deleteComment(String postId, String commentId) async {
    try {
      await _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .delete();
    } catch (e) {
      print("댓글 삭제 실패: $e");
      rethrow;
    }
  }

  // 3. 댓글 목록 스트림
  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 4. 댓글 수 가져오기
  Stream<int> getCommentCountStream(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- [DM/채팅 기능] ---

  // 1. 채팅방 ID 생성 (두 사용자 uid를 정렬하여 일관된 ID 생성)
  String _getChatRoomId(String uid1, String uid2) {
    List<String> uids = [uid1, uid2]..sort();
    return '${uids[0]}_${uids[1]}';
  }

  // 2. 채팅방 생성 또는 가져오기
  Future<String> getOrCreateChatRoom(String otherUserId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      String chatRoomId = _getChatRoomId(user.uid, otherUserId);
      print('🔑 채팅방 ID: $chatRoomId (${user.uid} <-> $otherUserId)');
      
      DocumentReference chatRoomRef = _db.collection('chatRooms').doc(chatRoomId);

      DocumentSnapshot chatRoomDoc = await chatRoomRef.get();

      if (!chatRoomDoc.exists) {
        // 채팅방이 없으면 생성
        print('✨ 새 채팅방 생성 중...');
        await chatRoomRef.set({
          'participants': [user.uid, otherUserId],
          'lastMessage': '',
          'lastMessageType': 'text',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {
            user.uid: 0,
            otherUserId: 0,
          },
        });
        print('✅ 채팅방 생성 완료');
      } else {
        print('✅ 기존 채팅방 사용');
      }

      return chatRoomId;
    } catch (e) {
      print("❌ 채팅방 생성 실패: $e");
      rethrow;
    }
  }

  // 3. 메시지 전송 (텍스트)
  Future<void> sendTextMessage({
    required String chatRoomId,
    required String receiverId,
    required String content,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['userName'] ?? userData?['username'] ?? userData?['name'] ?? '알 수 없음';
      final userProfileImage = userData?['profileImage'] ?? '';

      // 메시지 추가
      print('📤 텍스트 메시지 전송 중: "$content"');
      await _db
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': userName,
        'senderProfileImage': userProfileImage,
        'receiverId': receiverId,
        'content': content,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 채팅방 정보 업데이트
      print('📝 채팅방 정보 업데이트 중...');
      await _db.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': content,
        'lastMessageType': 'text',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
      print('✅ 메시지 전송 완료');
    } catch (e) {
      print("❌ 메시지 전송 실패: $e");
      rethrow;
    }
  }

  // 4. 메시지 전송 (이미지)
  Future<void> sendImageMessage({
    required String chatRoomId,
    required String receiverId,
    required String localImagePath,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 이미지 업로드
      File file = File(localImagePath);
      if (!file.existsSync()) throw Exception("파일이 존재하지 않습니다.");

      String fileName = "chat_${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg";
      Reference ref = _storage.ref().child('chat_images/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['userName'] ?? userData?['username'] ?? userData?['name'] ?? '알 수 없음';
      final userProfileImage = userData?['profileImage'] ?? '';

      // 메시지 추가
      await _db
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': userName,
        'senderProfileImage': userProfileImage,
        'receiverId': receiverId,
        'content': '사진을 보냈습니다.',
        'type': 'image',
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 채팅방 정보 업데이트
      await _db.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': '사진을 보냈습니다.',
        'lastMessageType': 'image',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      print("이미지 전송 실패: $e");
      rethrow;
    }
  }

  // 5. 메시지 전송 (위치)
  Future<void> sendLocationMessage({
    required String chatRoomId,
    required String receiverId,
    required double latitude,
    required double longitude,
    required String locationName,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName = userData?['userName'] ?? userData?['username'] ?? userData?['name'] ?? '알 수 없음';
      final userProfileImage = userData?['profileImage'] ?? '';

      // 메시지 추가
      await _db
          .collection('chatRooms')
          .doc(chatRoomId)
          .collection('messages')
          .add({
        'senderId': user.uid,
        'senderName': userName,
        'senderProfileImage': userProfileImage,
        'receiverId': receiverId,
        'content': '위치를 보냈습니다.',
        'type': 'location',
        'latitude': latitude,
        'longitude': longitude,
        'locationName': locationName,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 채팅방 정보 업데이트
      await _db.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': '위치를 보냈습니다.',
        'lastMessageType': 'location',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      print("위치 전송 실패: $e");
      rethrow;
    }
  }

  // 6. 메시지 목록 스트림
  Stream<QuerySnapshot> getMessagesStream(String chatRoomId) {
    return _db
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 7. 내 채팅방 목록 스트림
  Stream<QuerySnapshot> getMyChatRoomsStream() {
    User? user = _auth.currentUser;
    if (user == null) {
      print('❌ getMyChatRoomsStream: 로그인된 사용자 없음');
      return const Stream.empty();
    }

    print('🔍 getMyChatRoomsStream: 사용자 ${user.uid}의 채팅방 조회 중...');
    
    return _db
        .collection('chatRooms')
        .where('participants', arrayContains: user.uid)
        .snapshots();
  }

  // 8. 읽지 않은 메시지 수 초기화
  Future<void> markMessagesAsRead(String chatRoomId) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      await _db.collection('chatRooms').doc(chatRoomId).update({
        'unreadCount.${user.uid}': 0,
      });
    } catch (e) {
      print("읽음 처리 실패: $e");
    }
  }

  // 9. 특정 사용자와의 채팅방 ID 가져오기
  Future<String?> getChatRoomIdWithUser(String otherUserId) async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    String chatRoomId = _getChatRoomId(user.uid, otherUserId);
    DocumentSnapshot doc = await _db.collection('chatRooms').doc(chatRoomId).get();
    
    if (doc.exists) {
      return chatRoomId;
    }
    return null;
  }
}
