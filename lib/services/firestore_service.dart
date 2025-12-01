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
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
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
        'userName': isAnonymous ? '익명' : (user.displayName ?? '알 수 없음'),
        'userProfileImage': isAnonymous ? '' : (user.photoURL ?? ''),
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
        return doc.data();
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

      // Firestore에 프로필 이미지 URL 저장
      await _db.collection('users').doc(user.uid).set({
        'profileImage': downloadUrl,
        'userName': user.displayName ?? '알 수 없음',
        'email': user.email,
      }, SetOptions(merge: true));

      return downloadUrl;
    } catch (e) {
      print("프로필 이미지 업로드 실패: $e");
      rethrow;
    }
  }
}
