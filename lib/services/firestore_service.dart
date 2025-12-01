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
}
