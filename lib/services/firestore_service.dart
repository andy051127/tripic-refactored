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
    String? country, // 국가 정보 추가
    String? travelPlanId, // 여행 계획 ID 추가
    String? travelPlanTitle, // 여행 계획 제목 추가
    String? travelPlanDate, // 여행 계획 날짜 추가
    String? travelPlanCountry, // 여행 계획 국가 추가
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
          userName =
              userData?['userName'] ??
              userData?['username'] ??
              userData?['name'] ??
              '알 수 없음';
          userProfileImage = userData?['profileImage'] ?? '';
        }
      } else {
        userName = '익명';
      }

      List<String> downloadUrls = [];

      // 여러 이미지 처리
      final imagePaths =
          localImagePaths ?? (localImagePath != null ? [localImagePath] : []);

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
        'imageUrl': downloadUrls.isNotEmpty
            ? downloadUrls[0]
            : '', // 첫 번째 이미지를 기본 이미지로
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
      if (locationName != null)
        postData['locationName'] = locationName; // 위치 이름 저장
      if (country != null) postData['country'] = country; // 국가 정보 저장
      if (travelPlanId != null)
        postData['travelPlanId'] = travelPlanId; // 여행 계획 ID 저장
      if (travelPlanTitle != null)
        postData['travelPlanTitle'] = travelPlanTitle; // 여행 계획 제목 저장
      if (travelPlanDate != null)
        postData['travelPlanDate'] = travelPlanDate; // 여행 계획 날짜 저장
      if (travelPlanCountry != null)
        postData['travelPlanCountry'] = travelPlanCountry; // 여행 계획 국가 저장

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

  // [추가] 게시물 삭제
  Future<void> deletePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) {
      print('❌ deletePost 실패: 로그인된 사용자 없음');
      throw Exception("로그인이 필요합니다.");
    }

    print('🗑️ deletePost 시작 - postId: $postId, userId: ${user.uid}');

    try {
      // 게시물 정보 가져오기
      print('📄 게시물 정보 조회 중...');
      final postDoc = await _db.collection('posts').doc(postId).get();

      if (!postDoc.exists) {
        print('❌ 게시물을 찾을 수 없음: $postId');
        throw Exception("게시물을 찾을 수 없습니다.");
      }

      final postData = postDoc.data();
      final postUid = postData?['uid'];
      print('📌 게시물 작성자 UID: $postUid');

      // 본인의 게시물인지 확인
      if (postUid != user.uid) {
        print('❌ 권한 없음: 작성자($postUid) != 현재사용자(${user.uid})');
        throw Exception("본인의 게시물만 삭제할 수 있습니다.");
      }

      print('✅ 권한 확인 완료 - 삭제 진행');

      // Storage에서 이미지 삭제
      final imageUrls = postData?['imageUrls'] as List<dynamic>?;
      if (imageUrls != null && imageUrls.isNotEmpty) {
        print('🖼️ 이미지 ${imageUrls.length}개 삭제 중...');
        for (var imageUrl in imageUrls) {
          try {
            if (imageUrl is String && imageUrl.isNotEmpty) {
              final ref = _storage.refFromURL(imageUrl);
              await ref.delete();
              print('✅ 이미지 삭제 완료: $imageUrl');
            }
          } catch (e) {
            print('⚠️ 이미지 삭제 실패 (계속 진행): $e');
          }
        }
      }

      // 게시물의 하위 컬렉션 삭제 (좋아요)
      print('❤️ 좋아요 삭제 중...');
      final likesSnapshot = await _db
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .get();

      for (var doc in likesSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ 좋아요 ${likesSnapshot.docs.length}개 삭제 완료');

      // 댓글 삭제
      print('💬 댓글 삭제 중...');
      final commentsSnapshot = await _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .get();

      for (var doc in commentsSnapshot.docs) {
        await doc.reference.delete();
      }
      print('✅ 댓글 ${commentsSnapshot.docs.length}개 삭제 완료');

      // 게시물 문서 삭제
      print('📝 게시물 문서 삭제 중...');
      await _db.collection('posts').doc(postId).delete();
      print('✅ 게시물 삭제 완료: $postId');
    } catch (e) {
      print('❌ deletePost 실패: $e');
      rethrow;
    }
  }

  // [추가] 관리자용 게시물 삭제 (Soft Delete & Schedule)
  Future<void> deletePostByAdmin(String postId) async {
    try {
      // 7일 후 삭제 예정일 설정
      final deletionDueAt = DateTime.now().add(const Duration(days: 7));

      // 게시물 문서를 업데이트하여 삭제 예정 상태로 변경
      await _db.collection('posts').doc(postId).update({
        'status': 'scheduled_for_deletion', // 상태 표시
        'deletionDueAt': Timestamp.fromDate(deletionDueAt), // 삭제 예정 시간
        'deletedAt': FieldValue.serverTimestamp(), // 삭제 요청 시간
      });

      // 참고: 실제 데이터(이미지, 하위 컬렉션 등) 삭제는 Firebase Cloud Functions를 통해 처리
    } catch (e) {
      print('❌ deletePostByAdmin 실패: $e');
      rethrow;
    }
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
          .set({'timestamp': FieldValue.serverTimestamp()});

      // 상대방의 followers 컬렉션에 추가
      await _db
          .collection('users')
          .doc(targetUserId)
          .collection('followers')
          .doc(user.uid)
          .set({'timestamp': FieldValue.serverTimestamp()});
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
            'userName':
                data['userName'] ??
                data['username'] ??
                data['name'] ??
                '알 수 없음',
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

      String fileName =
          "profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg";
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
        await likeRef.set({'timestamp': FieldValue.serverTimestamp()});

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
      final userName =
          userData?['userName'] ??
          userData?['username'] ??
          userData?['name'] ??
          '알 수 없음';
      final userProfileImage = userData?['profileImage'] ?? '';

      // 댓글 추가
      await _db.collection('posts').doc(postId).collection('comments').add({
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

      DocumentReference chatRoomRef = _db
          .collection('chatRooms')
          .doc(chatRoomId);

      DocumentSnapshot chatRoomDoc = await chatRoomRef.get();

      if (!chatRoomDoc.exists) {
        // 채팅방이 없으면 생성
        print('✨ 새 채팅방 생성 중...');
        await chatRoomRef.set({
          'participants': [user.uid, otherUserId],
          'lastMessage': '',
          'lastMessageType': 'text',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': {user.uid: 0, otherUserId: 0},
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
      final userName =
          userData?['userName'] ??
          userData?['username'] ??
          userData?['name'] ??
          '알 수 없음';
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

      String fileName =
          "chat_${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg";
      Reference ref = _storage.ref().child('chat_images/$fileName');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String imageUrl = await snapshot.ref.getDownloadURL();

      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName =
          userData?['userName'] ??
          userData?['username'] ??
          userData?['name'] ??
          '알 수 없음';
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
      final userName =
          userData?['userName'] ??
          userData?['username'] ??
          userData?['name'] ??
          '알 수 없음';
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

  // 게시물 공유 메시지 전송
  Future<void> sendPostMessage({
    required String chatRoomId,
    required String receiverId,
    required String postId,
    required String postTitle,
    required String postImageUrl,
    required String postAuthor,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName =
          userData?['userName'] ??
          userData?['username'] ??
          userData?['name'] ??
          '알 수 없음';
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
            'content': '게시물을 공유했습니다.',
            'type': 'post',
            'postId': postId,
            'postTitle': postTitle,
            'postImageUrl': postImageUrl,
            'postAuthor': postAuthor,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // 채팅방 정보 업데이트
      await _db.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': '게시물을 공유했습니다.',
        'lastMessageType': 'post',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      print("게시물 전송 실패: $e");
      rethrow;
    }
  }

  // 여행 계획 공유 메시지 전송
  Future<void> sendTravelPlanMessage({
    required String chatRoomId,
    required String receiverId,
    required String travelPlanId,
    required String travelPlanTitle,
    required String travelPlanDate,
    required String travelPlanCountry,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 사용자 정보 가져오기
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final userName =
          userData?['userName'] ??
          userData?['username'] ??
          userData?['name'] ??
          '알 수 없음';
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
            'content': '여행 계획을 공유했습니다.',
            'type': 'travelPlan',
            'travelPlanId': travelPlanId,
            'travelPlanTitle': travelPlanTitle,
            'travelPlanDate': travelPlanDate,
            'travelPlanCountry': travelPlanCountry,
            'timestamp': FieldValue.serverTimestamp(),
          });

      // 채팅방 정보 업데이트
      await _db.collection('chatRooms').doc(chatRoomId).update({
        'lastMessage': '여행 계획을 공유했습니다.',
        'lastMessageType': 'travelPlan',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount.$receiverId': FieldValue.increment(1),
      });
    } catch (e) {
      print("여행 계획 전송 실패: $e");
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
    DocumentSnapshot doc = await _db
        .collection('chatRooms')
        .doc(chatRoomId)
        .get();

    if (doc.exists) {
      return chatRoomId;
    }
    return null;
  }

  // --- [프라이버시 설정 관련] ---

  // 1. 게시물이 현재 사용자에게 공개되는지 확인
  Future<bool> isPostVisibleToUser(
    String postOwnerId,
    String currentUserId,
  ) async {
    if (postOwnerId == currentUserId) return true; // 본인 게시물은 항상 보임

    try {
      // 게시물 소유자의 프라이버시 설정 가져오기
      final userDoc = await _db.collection('users').doc(postOwnerId).get();
      if (!userDoc.exists) return false;

      final privacySettings = userDoc.data()?['privacySettings'];
      if (privacySettings == null) {
        // 설정이 없으면 기본값으로 팔로워에게 공개
        return await _isFollowing(currentUserId, postOwnerId);
      }

      final isPublicToFollowers =
          privacySettings['isPublicToFollowers'] ?? false;
      final isPublicToMutuals = privacySettings['isPublicToMutuals'] ?? false;
      final selectedFollowingFriends = List<String>.from(
        privacySettings['selectedFollowingFriends'] ?? [],
      );

      // 1. 특정 사람에게만 공개되는 경우
      if (selectedFollowingFriends.isNotEmpty) {
        return selectedFollowingFriends.contains(currentUserId);
      }

      // 2. 맞팔로우한 사람에게만 공개
      if (isPublicToMutuals) {
        return await _isMutualFollowing(postOwnerId, currentUserId);
      }

      // 3. 팔로워에게 공개
      if (isPublicToFollowers) {
        return await _isFollowing(currentUserId, postOwnerId);
      }

      return false;
    } catch (e) {
      print('게시물 공개 범위 확인 실패: $e');
      return false;
    }
  }

  // 2. 팔로잉 여부 확인 (내부 메서드)
  Future<bool> _isFollowing(String followerId, String followeeId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(followerId)
          .collection('following')
          .doc(followeeId)
          .get();
      return doc.exists;
    } catch (e) {
      print('팔로잉 확인 실패: $e');
      return false;
    }
  }

  // 3. 맞팔로우 여부 확인 (서로 팔로잉하는지)
  Future<bool> _isMutualFollowing(String userId1, String userId2) async {
    try {
      // userId1이 userId2를 팔로잉하는지 확인
      final doc1 = await _db
          .collection('users')
          .doc(userId1)
          .collection('following')
          .doc(userId2)
          .get();

      // userId2가 userId1을 팔로잉하는지 확인
      final doc2 = await _db
          .collection('users')
          .doc(userId2)
          .collection('following')
          .doc(userId1)
          .get();

      return doc1.exists && doc2.exists;
    } catch (e) {
      print('맞팔로우 확인 실패: $e');
      return false;
    }
  }

  // 게시물 숨기기
  Future<void> hidePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('hiddenPosts')
          .doc(postId)
          .set({'hiddenAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('게시물 숨기기 실패: $e');
      rethrow;
    }
  }

  // 사용자 차단
  Future<void> blockUser(String targetUserId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('blockedUsers')
          .doc(targetUserId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('사용자 차단 실패: $e');
      rethrow;
    }
  }

  // 숨긴 게시물 목록 가져오기
  Future<List<String>> getHiddenPostIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('hiddenPosts')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('숨긴 게시물 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 차단한 사용자 목록 가져오기
  Future<List<String>> getBlockedUserIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('blockedUsers')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('차단한 사용자 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 차단 해제
  Future<void> unblockUser(String targetUserId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('blockedUsers')
          .doc(targetUserId)
          .delete();
    } catch (e) {
      print('차단 해제 실패: $e');
      rethrow;
    }
  }

  // 게시물 숨김 해제
  Future<void> unhidePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('hiddenPosts')
          .doc(postId)
          .delete();
    } catch (e) {
      print('게시물 숨김 해제 실패: $e');
      rethrow;
    }
  }

  // 차단된 사용자 상세 정보 가져오기 (스트림)
  Stream<List<Map<String, dynamic>>> getBlockedUsersStream() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('blockedUsers')
        .snapshots()
        .asyncMap((snapshot) async {
          List<Map<String, dynamic>> blockedUsers = [];

          for (var doc in snapshot.docs) {
            try {
              final userDoc = await _db.collection('users').doc(doc.id).get();
              if (userDoc.exists) {
                final userData = userDoc.data() ?? {};
                blockedUsers.add({
                  'uid': doc.id,
                  'userName':
                      userData['userName'] ?? userData['username'] ?? '알 수 없음',
                  'profileImage': userData['profileImage'] ?? '',
                  'blockedAt': doc.data()['blockedAt'],
                });
              }
            } catch (e) {
              print('차단된 사용자 정보 가져오기 실패: $e');
            }
          }

          return blockedUsers;
        });
  }

  // 게시물 보관함에 저장
  Future<void> savePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('savedPosts')
          .doc(postId)
          .set({'savedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      print('게시물 저장 실패: $e');
      rethrow;
    }
  }

  // 보관함에서 게시물 삭제
  Future<void> unsavePost(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .collection('savedPosts')
          .doc(postId)
          .delete();
    } catch (e) {
      print('보관함에서 삭제 실패: $e');
      rethrow;
    }
  }

  // 보관된 게시물 ID 목록 가져오기
  Future<List<String>> getSavedPostIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _db
          .collection('users')
          .doc(user.uid)
          .collection('savedPosts')
          .get();
      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('보관된 게시물 목록 가져오기 실패: $e');
      return [];
    }
  }

  // 게시물이 보관되어 있는지 확인
  Future<bool> isPostSaved(String postId) async {
    User? user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _db
          .collection('users')
          .doc(user.uid)
          .collection('savedPosts')
          .doc(postId)
          .get();
      return doc.exists;
    } catch (e) {
      print('보관 상태 확인 실패: $e');
      return false;
    }
  }

  // --- [Admin Features] ---

  // 1. Dashboard Stats
  Future<Map<String, int>> getDashboardStats() async {
    try {
      // 1. Users Count
      final usersCount = await _db.collection('users').count().get();

      // 2. Total Posts Count
      final postsCount = await _db.collection('posts').count().get();

      // 3. Community Posts Count (category != 'feed')
      // Note: This requires an index if we use notEqualTo.
      // Alternatively, we can count specific community categories if known (general, companion).
      // For now, let's try counting where category is 'general' or 'companion'.
      final communityGeneralCount = await _db
          .collection('posts')
          .where('category', isEqualTo: 'general')
          .count()
          .get();
      final communityCompanionCount = await _db
          .collection('posts')
          .where('category', isEqualTo: 'companion')
          .count()
          .get();
      final totalCommunityCount =
          (communityGeneralCount.count ?? 0) +
          (communityCompanionCount.count ?? 0);

      // 4. Comments Count (using collectionGroup)
      final commentsCount = await _db.collectionGroup('comments').count().get();

      // 5. Travel Plans Count
      final plansCount = await _db.collection('travel_plans').count().get();

      // 6. Reports Count
      final reportsCount = await _db.collection('reports').count().get();

      // 7. Image Count (Calculate by reading posts - potentially expensive)
      int totalImages = 0;
      final postsSnapshot = await _db.collection('posts').get();
      for (var doc in postsSnapshot.docs) {
        final data = doc.data();
        final List<dynamic>? urls = data['imageUrls'] as List<dynamic>?;
        if (urls != null) {
          totalImages += urls.length;
        } else if (data['imageUrl'] != null &&
            data['imageUrl'].toString().isNotEmpty) {
          totalImages += 1;
        }
      }

      return {
        'users': usersCount.count ?? 0,
        'posts': postsCount.count ?? 0,
        'communityPosts': totalCommunityCount,
        'comments': commentsCount.count ?? 0,
        'images': totalImages,
        'plans': plansCount.count ?? 0,
        'reports': reportsCount.count ?? 0,
      };
    } catch (e) {
      print('Error fetching dashboard stats: $e');
      return {
        'users': 0,
        'posts': 0,
        'communityPosts': 0,
        'comments': 0,
        'images': 0,
        'plans': 0,
        'reports': 0,
      };
    }
  }

  // 2. All Users Stream
  Stream<QuerySnapshot> getAllUsersStream() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 3. Delete User (Soft Delete & Schedule)
  Future<void> deleteUser(String userId) async {
    try {
      // 7일 후 삭제 예정일 설정
      final deletionDueAt = DateTime.now().add(const Duration(days: 7));

      // 사용자 문서를 업데이트하여 삭제 예정 상태로 변경
      await _db.collection('users').doc(userId).update({
        'isBanned': true, // 로그인 차단
        'status': 'scheduled_for_deletion', // 상태 표시
        'deletionDueAt': Timestamp.fromDate(deletionDueAt), // 삭제 예정 시간
        'deletedAt': FieldValue.serverTimestamp(), // 삭제 요청 시간
      });

      // 참고: 실제 데이터 삭제는 Firebase Cloud Functions를 통해 deletionDueAt이 지난 문서를 주기적으로 정리해야 합니다.
    } catch (e) {
      print('Error deleting user: $e');
      rethrow;
    }
  }

  // [추가] Ban User
  Future<void> banUser(String userId, String reason) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isBanned': true,
        'banReason': reason,
        'bannedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error banning user: $e');
      rethrow;
    }
  }

  // [추가] Unban User
  Future<void> unbanUser(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isBanned': false,
        'banReason': FieldValue.delete(),
        'bannedAt': FieldValue.delete(),
      });
    } catch (e) {
      print('Error unbanning user: $e');
      rethrow;
    }
  }

  // [추가] Check Ban Status
  Future<Map<String, dynamic>?> checkBanStatus(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null && data['isBanned'] == true) {
          return {
            'isBanned': true,
            'banReason': data['banReason'] ?? 'No reason provided',
          };
        }
      }
      return null;
    } catch (e) {
      print('Error checking ban status: $e');
      return null;
    }
  }

  // 4. Reports Stream
  Stream<QuerySnapshot> getReportsStream() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // 5. Update Report Status
  Future<void> updateReportStatus(String reportId, String status) async {
    try {
      await _db.collection('reports').doc(reportId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating report status: $e');
      rethrow;
    }
  }

  // [추가] Report Post
  Future<void> reportPost({
    required String postId,
    required String reason,
    required String targetUserId,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      await _db.collection('reports').add({
        'reporterId': user.uid,
        'targetId': postId, // 게시물 ID
        'targetUserId': targetUserId, // 게시물 작성자 ID
        'reason': reason,
        'type': 'post',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error reporting post: $e');
      rethrow;
    }
  }

  // 6. Get Current User Role
  Future<String?> getUserRole() async {
    User? user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  // [추가] Get Admin User
  Future<Map<String, dynamic>?> getAdminUser() async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['uid'] = doc.id; // 문서 ID를 uid로 추가
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching admin user: $e');
      return null;
    }
  }
}
