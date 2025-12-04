import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 이 스크립트를 한 번 실행하여 기존 채팅방 데이터를 수정합니다.
// 실행 후 삭제해도 됩니다.

void fixChatRooms() async {
  final db = FirebaseFirestore.instance;
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    print('❌ 로그인된 사용자가 없습니다.');
    return;
  }
  
  print('👤 현재 사용자: ${currentUser.uid}');
  print('🔧 채팅방 데이터 수정 시작...');
  
  // 모든 채팅방 가져오기
  final snapshot = await db.collection('chatRooms').get();
  print('📦 총 ${snapshot.docs.length}개의 채팅방 발견');
  
  for (var doc in snapshot.docs) {
    final chatRoomId = doc.id;
    final data = doc.data();
    
    print('\n🔍 채팅방 ID: $chatRoomId');
    print('   기존 데이터: $data');
    
    // chatRoomId에서 participants 추출 (uid1_uid2 형식)
    final parts = chatRoomId.split('_');
    if (parts.length == 2) {
      final uid1 = parts[0];
      final uid2 = parts[1];
      
      print('   → participants 복구: [$uid1, $uid2]');
      
      // participants 필드 업데이트
      await db.collection('chatRooms').doc(chatRoomId).update({
        'participants': [uid1, uid2],
      });
      
      print('   ✅ 수정 완료');
    } else {
      print('   ⚠️ 잘못된 형식의 채팅방 ID');
    }
  }
  
  print('\n🎉 모든 채팅방 수정 완료!');
}
