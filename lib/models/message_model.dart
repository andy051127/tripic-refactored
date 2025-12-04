import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String senderId;
  final String senderName;
  final String senderProfileImage;
  final String receiverId;
  final String content; // 텍스트 메시지 내용
  final String type; // 'text', 'image', 'location'
  final String? imageUrl; // 이미지 URL (type='image'일 때)
  final double? latitude; // 위도 (type='location'일 때)
  final double? longitude; // 경도 (type='location'일 때)
  final String? locationName; // 위치 이름 (type='location'일 때)
  final DateTime? timestamp;

  Message({
    this.id = '',
    required this.senderId,
    required this.senderName,
    required this.senderProfileImage,
    required this.receiverId,
    required this.content,
    this.type = 'text',
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.locationName,
    this.timestamp,
  });

  // Firestore에서 데이터를 가져올 때
  factory Message.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Message(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '알 수 없음',
      senderProfileImage: data['senderProfileImage'] ?? '',
      receiverId: data['receiverId'] ?? '',
      content: data['content'] ?? '',
      type: data['type'] ?? 'text',
      imageUrl: data['imageUrl'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      locationName: data['locationName'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
    );
  }

  // Firestore에 저장할 때
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'senderProfileImage': senderProfileImage,
      'receiverId': receiverId,
      'content': content,
      'type': type,
      'imageUrl': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
    };
  }
}

class ChatRoom {
  final String id;
  final List<String> participants; // 참여자 uid 리스트 (2명)
  final String lastMessage;
  final String lastMessageType; // 'text', 'image', 'location'
  final DateTime? lastMessageTime;
  final Map<String, int> unreadCount; // uid별 읽지 않은 메시지 수

  ChatRoom({
    this.id = '',
    required this.participants,
    this.lastMessage = '',
    this.lastMessageType = 'text',
    this.lastMessageTime,
    this.unreadCount = const {},
  });

  factory ChatRoom.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatRoom(
      id: doc.id,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageType: data['lastMessageType'] ?? 'text',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate(),
      unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageType': lastMessageType,
      'lastMessageTime': lastMessageTime != null ? Timestamp.fromDate(lastMessageTime!) : FieldValue.serverTimestamp(),
      'unreadCount': unreadCount,
    };
  }
}
