import 'package:cloud_firestore/cloud_firestore.dart';

class TravelPlan {
  final String id;
  final String uid; // 작성자 ID
  final String title;
  final String date;
  final String country;
  final String flightInfo;
  final String hotelInfo;
  final List<String> members;
  final List<String> supplies;
  final List<Map<String, dynamic>> todoList; // 체크박스 상태 포함
  final Timestamp createdAt;

  TravelPlan({
    this.id = '',
    this.uid = '',
    required this.title,
    required this.date,
    required this.country,
    this.flightInfo = '',
    this.hotelInfo = '',
    this.members = const [],
    this.supplies = const [],
    this.todoList = const [],
    Timestamp? createdAt,
  }) : createdAt = createdAt ?? Timestamp.now();

  // Firebase 문서 -> 객체 변환
  factory TravelPlan.fromMap(Map<String, dynamic> data, String documentId) {
    return TravelPlan(
      id: documentId,
      uid: data['uid'] ?? '',
      title: data['title'] ?? '',
      date: data['date'] ?? '',
      country: data['country'] ?? '',
      flightInfo: data['flightInfo'] ?? '',
      hotelInfo: data['hotelInfo'] ?? '',
      members: List<String>.from(data['members'] ?? []),
      supplies: List<String>.from(data['supplies'] ?? []),
      todoList:
          (data['todoList'] as List<dynamic>?)
              ?.map((item) => Map<String, dynamic>.from(item))
              .toList() ??
          [],
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // 객체 -> Firebase 저장용 Map 변환
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'title': title,
      'date': date,
      'country': country,
      'flightInfo': flightInfo,
      'hotelInfo': hotelInfo,
      'members': members,
      'supplies': supplies,
      'todoList': todoList,
      'createdAt': createdAt,
    };
  }
}
