import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// 여행 기록 세션 (하나의 여행 기록)
class TravelRecord {
  final String id;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final List<RoutePoint> routePoints; // GPS 경로
  final List<PhotoRecord> photos; // 사진 기록
  final bool isActive;

  TravelRecord({
    required this.id,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.routePoints = const [],
    this.photos = const [],
    this.isActive = true,
  });

  factory TravelRecord.fromMap(Map<String, dynamic> data, String documentId) {
    return TravelRecord(
      id: documentId,
      userId: data['userId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: data['endTime'] != null ? (data['endTime'] as Timestamp).toDate() : null,
      routePoints: (data['routePoints'] as List<dynamic>?)
              ?.map((e) => RoutePoint.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      photos: (data['photos'] as List<dynamic>?)
              ?.map((e) => PhotoRecord.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'routePoints': routePoints.map((e) => e.toMap()).toList(),
      'photos': photos.map((e) => e.toMap()).toList(),
      'isActive': isActive,
    };
  }

  TravelRecord copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    List<RoutePoint>? routePoints,
    List<PhotoRecord>? photos,
    bool? isActive,
  }) {
    return TravelRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      routePoints: routePoints ?? this.routePoints,
      photos: photos ?? this.photos,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// GPS 경로 포인트
class RoutePoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracy;

  RoutePoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracy,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory RoutePoint.fromMap(Map<String, dynamic> data) {
    return RoutePoint(
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      accuracy: data['accuracy']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'accuracy': accuracy,
    };
  }
}

/// 사진 기록 (위치 + 시간)
class PhotoRecord {
  final String photoPath; // 로컬 경로 또는 URL
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final String? caption;

  PhotoRecord({
    required this.photoPath,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.caption,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  factory PhotoRecord.fromMap(Map<String, dynamic> data) {
    return PhotoRecord(
      photoPath: data['photoPath'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      caption: data['caption'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'photoPath': photoPath,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'caption': caption,
    };
  }
}
