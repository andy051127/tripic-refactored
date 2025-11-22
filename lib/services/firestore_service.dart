import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart'; // 고유 ID 생성용 (패키지 없으면 DateTime으로 대체 가능)

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 1. 게시물 업로드 (이미지 업로드 -> URL 획득 -> Firestore 저장)
  Future<void> addPost({
    required String title,
    required String content,
    required String location,
    required String localImagePath, // 폰에 있는 파일 경로
  }) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다.");

    try {
      // 1-1. 이미지 파일 업로드
      File file = File(localImagePath);
      String fileName =
          "${DateTime.now().millisecondsSinceEpoch}_${user.uid}.jpg";
      Reference ref = _storage.ref().child('post_images/$fileName');

      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      // 1-2. Firestore에 데이터 저장
      await _db.collection('posts').add({
        'uid': user.uid,
        'userName': user.displayName ?? '익명', // 사용자 이s름 (없으면 익명)
        'userProfileImage': user.photoURL ?? '', // 프로필 사진 (없으면 빈값)
        'title': title,
        'content': content,
        'location': location,
        'imageUrl': downloadUrl, // Storage에서 받은 URL 저장
        'likeCount': 0,
        'createdAt': FieldValue.serverTimestamp(), // 서버 시간
      });
    } catch (e) {
      print("게시물 업로드 실패: $e");
      rethrow;
    }
  }

  // 2. 게시물 스트림 가져오기 (실시간 업데이트)
  Stream<QuerySnapshot> getPostsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true) // 최신순 정렬
        .snapshots();
  }
}
