import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/travel_record_model.dart';

/// 여행 기록 추적 서비스 (Singleton)
class TravelTrackerService extends ChangeNotifier {
  static final TravelTrackerService _instance = TravelTrackerService._internal();
  factory TravelTrackerService() => _instance;
  TravelTrackerService._internal();

  // 상태
  bool _isTracking = false;
  TravelRecord? _currentRecord;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _periodicTimer; // 5초 타이머 추가
  Position? _lastRecordedPosition; // 마지막으로 기록된 위치
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  DateTime? _lastFirestoreSave; // 마지막 Firestore 저장 시간
  int _unsavedPointsCount = 0; // 저장되지 않은 포인트 수

  // Getters
  bool get isTracking => _isTracking;
  TravelRecord? get currentRecord => _currentRecord;
  List<RoutePoint> get currentRoute => _currentRecord?.routePoints ?? [];
  List<PhotoRecord> get currentPhotos => _currentRecord?.photos ?? [];

  /// 여행 기록 시작
  Future<void> startTracking() async {
    if (_isTracking) return;

    try {
      // 위치 권한 확인
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('위치 권한이 거부되었습니다.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('위치 권한이 영구적으로 거부되었습니다. 설정에서 권한을 허용해주세요.');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인이 필요합니다.');

      // 1. 기존 활성화된 기록이 있는지 확인
      final prefs = await SharedPreferences.getInstance();
      final existingRecordId = prefs.getString('active_travel_record_id');
      
      if (existingRecordId != null) {
        // 기존 기록 불러오기
        final doc = await _firestore
            .collection('travel_records')
            .doc(existingRecordId)
            .get();
        
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isActive'] == true) {
            // 기존 활성 기록 이어가기
            _currentRecord = TravelRecord.fromMap(data, doc.id);
            print('✅ 기존 여행 기록 이어가기: $existingRecordId');
            print('   - 경로 포인트: ${_currentRecord!.routePoints.length}개');
            print('   - 사진: ${_currentRecord!.photos.length}개');
            
            // 마지막 기록된 위치 복원
            if (_currentRecord!.routePoints.isNotEmpty) {
              final lastPoint = _currentRecord!.routePoints.last;
              _lastRecordedPosition = Position(
                latitude: lastPoint.latitude,
                longitude: lastPoint.longitude,
                timestamp: lastPoint.timestamp,
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            }
            
            // GPS 추적 시작
            _startLocationTracking();
            _isTracking = true;
            notifyListeners();
            return;
          }
        }
      }

      // 2. 새 여행 기록 생성
      final recordId = DateTime.now().millisecondsSinceEpoch.toString();
      _currentRecord = TravelRecord(
        id: recordId,
        userId: user.uid,
        startTime: DateTime.now(),
        isActive: true,
      );

      // Firestore에 저장
      await _firestore
          .collection('travel_records')
          .doc(recordId)
          .set(_currentRecord!.toMap());

      // SharedPreferences에 현재 기록 ID 저장 (앱 재시작 대응)
      await prefs.setString('active_travel_record_id', recordId);

      // GPS 추적 시작
      _startLocationTracking();

      _isTracking = true;
      notifyListeners();

      print('✅ 여행 기록 시작: $recordId');
    } catch (e) {
      print('❌ 여행 기록 시작 실패: $e');
      rethrow;
    }
  }

  /// 여행 기록 중지
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      print('🛑 여행 기록 종료 시작...');
      
      // GPS 추적 중지
      await _positionSubscription?.cancel();
      _positionSubscription = null;
      
      // 타이머 중지
      _periodicTimer?.cancel();
      _periodicTimer = null;
      
      // 마지막 위치 초기화
      _lastRecordedPosition = null;

      if (_currentRecord != null) {
        print('📊 현재 기록 상태:');
        print('   - ID: ${_currentRecord!.id}');
        print('   - 경로 포인트: ${_currentRecord!.routePoints.length}개');
        print('   - 사진: ${_currentRecord!.photos.length}개');
        
        // 종료 시간 설정
        final endTime = DateTime.now();
        _currentRecord = _currentRecord!.copyWith(
          endTime: endTime,
          isActive: false,
        );

        print('💾 Firestore에 최종 데이터 저장 중...');
        
        // 최종 저장 (미저장된 데이터 포함)
        await _saveToFirestore();

        print('✅ Firestore 최종 저장 완료');
        print('   - 경로 포인트: ${_currentRecord!.routePoints.length}개 저장됨');
        print('   - 사진: ${_currentRecord!.photos.length}개 저장됨');
        print('   - isActive: false');
        print('   - endTime: $endTime');
      }

      // SharedPreferences에서 제거
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('active_travel_record_id');
      print('✅ SharedPreferences 정리 완료');

      _isTracking = false;
      notifyListeners();

      print('✅ 여행 기록 종료 완료');
    } catch (e) {
      print('❌ 여행 기록 종료 실패: $e');
      print('   스택: ${StackTrace.current}');
      rethrow;
    }
  }

  /// GPS 위치 추적 시작
  void _startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // 5미터마다 업데이트
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) async {
        await _addRoutePoint(position);
      },
      onError: (error) {
        print('❌ 위치 추적 오류: $error');
      },
    );

    // 추가: 5초마다 강제 위치 업데이트
    _periodicTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isTracking) {
        timer.cancel();
        return;
      }
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        await _addRoutePoint(position);
        print('⏱️ 5초 주기 위치 업데이트: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('❌ 주기적 위치 업데이트 실패: $e');
      }
    });
  }

  /// Firestore에 현재 기록 저장
  Future<void> _saveToFirestore() async {
    if (_currentRecord == null) return;
    
    try {
      await _firestore
          .collection('travel_records')
          .doc(_currentRecord!.id)
          .set(_currentRecord!.toMap(), SetOptions(merge: true));
      
      _lastFirestoreSave = DateTime.now();
      _unsavedPointsCount = 0;
      
      print('💾 Firestore 저장 완료: 경로 ${_currentRecord!.routePoints.length}개, 사진 ${_currentRecord!.photos.length}개');
    } catch (e) {
      print('❌ Firestore 저장 실패: $e');
    }
  }

  /// 경로 포인트 추가
  Future<void> _addRoutePoint(Position position) async {
    if (_currentRecord == null || !_isTracking) return;

    // GPS 정확도 체크 (30m 이하만 신뢰)
    if (position.accuracy > 30.0) {
      print('📡 GPS 정확도 낮음 ${position.accuracy.toStringAsFixed(1)}m - 기록 생략');
      return;
    }

    // 이전 위치가 있으면 거리 계산
    if (_lastRecordedPosition != null) {
      final distance = Geolocator.distanceBetween(
        _lastRecordedPosition!.latitude,
        _lastRecordedPosition!.longitude,
        position.latitude,
        position.longitude,
      );
      
      // 3m 미만 이동시에는 기록하지 않음
      if (distance < 3.0) {
        print('⏭️ 이동 거리 ${distance.toStringAsFixed(1)}m - 기록 생략');
        return;
      }
      print('✅ 이동 거리 ${distance.toStringAsFixed(1)}m (정확도: ${position.accuracy.toStringAsFixed(1)}m)');
    }

    try {
      final routePoint = RoutePoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      // 메모리에 추가
      final updatedRoute = List<RoutePoint>.from(_currentRecord!.routePoints)
        ..add(routePoint);
      _currentRecord = _currentRecord!.copyWith(routePoints: updatedRoute);
      
      // 마지막 위치 업데이트
      _lastRecordedPosition = position;
      _unsavedPointsCount++;

      notifyListeners();

      print('📍 경로 포인트 추가: ${position.latitude}, ${position.longitude} (총 ${_currentRecord!.routePoints.length}개, 미저장: $_unsavedPointsCount개)');      

      // Firestore 배치 저장 (10개마다 또는 30초마다)
      final now = DateTime.now();
      final shouldSave = _unsavedPointsCount >= 10 || 
                        _lastFirestoreSave == null || 
                        now.difference(_lastFirestoreSave!).inSeconds >= 30;
      
      if (shouldSave) {
        await _saveToFirestore();
      }
    } catch (e) {
      print('❌ 경로 포인트 추가 실패: $e');
    }
  }

  /// 사진 기록 추가 (위치 + 시간)
  Future<void> addPhotoRecord(
    String photoPath,
    Position? position,
  ) async {
    if (_currentRecord == null || !_isTracking) {
      print('⚠️ 여행 기록이 활성화되지 않음');
      return;
    }

    try {
      // position이 없으면 현재 위치 가져오기
      final actualPosition = position ?? await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final photoRecord = PhotoRecord(
        photoPath: photoPath,
        latitude: actualPosition.latitude,
        longitude: actualPosition.longitude,
        timestamp: DateTime.now(),
      );

      // 메모리에 추가
      final updatedPhotos = List<PhotoRecord>.from(_currentRecord!.photos)
        ..add(photoRecord);
      _currentRecord = _currentRecord!.copyWith(photos: updatedPhotos);

      notifyListeners();

      print('📸 사진 기록 추가: $photoPath at ${actualPosition.latitude}, ${actualPosition.longitude} (총 ${_currentRecord!.photos.length}개)');      

      // 사진은 중요하므로 즉시 Firestore에 저장
      await _saveToFirestore();
    } catch (e) {
      print('❌ 사진 기록 추가 실패: $e');
    }
  }

  /// 현재 위치 가져오기 (한 번만)
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ 현재 위치 가져오기 실패: $e');
      return null;
    }
  }

  /// 앱 재시작 시 이전 기록 복구
  Future<void> restoreTrackingSession() async {
    try {
      print('🔄 여행 기록 세션 복구 시도...');
      final prefs = await SharedPreferences.getInstance();
      final recordId = prefs.getString('active_travel_record_id');

      if (recordId != null) {
        print('📱 저장된 기록 ID 발견: $recordId');
        final doc = await _firestore
            .collection('travel_records')
            .doc(recordId)
            .get();

        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          print('📊 Firestore에서 기록 로드:');
          print('   - isActive: ${data['isActive']}');
          print('   - routePoints: ${(data['routePoints'] as List?)?.length ?? 0}개');
          print('   - photos: ${(data['photos'] as List?)?.length ?? 0}개');
          
          _currentRecord = TravelRecord.fromMap(data, doc.id);

          if (_currentRecord!.isActive) {
            // 마지막 기록된 위치 복원
            if (_currentRecord!.routePoints.isNotEmpty) {
              final lastPoint = _currentRecord!.routePoints.last;
              _lastRecordedPosition = Position(
                latitude: lastPoint.latitude,
                longitude: lastPoint.longitude,
                timestamp: lastPoint.timestamp,
                accuracy: 0,
                altitude: 0,
                altitudeAccuracy: 0,
                heading: 0,
                headingAccuracy: 0,
                speed: 0,
                speedAccuracy: 0,
              );
            }
            
            _isTracking = true;
            _startLocationTracking();
            notifyListeners();
            print('✅ 이전 여행 기록 복구 완료: $recordId');
            print('   - 경로: ${_currentRecord!.routePoints.length}개');
            print('   - 사진: ${_currentRecord!.photos.length}개');
          } else {
            print('⚠️ 기록이 비활성 상태 (isActive: false)');
          }
        } else {
          print('⚠️ Firestore에 기록이 존재하지 않음');
        }
      } else {
        print('ℹ️ 저장된 활성 기록 없음');
      }
    } catch (e) {
      print('❌ 여행 기록 복구 실패: $e');
      print('   스택: ${StackTrace.current}');
    }
  }

  /// 특정 사용자의 모든 여행 기록 가져오기
  Stream<List<TravelRecord>> getUserTravelRecords(String userId) {
    return _firestore
        .collection('travel_records')
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TravelRecord.fromMap(
                  doc.data(),
                  doc.id,
                ))
            .toList());
  }

  /// 서비스 정리
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _periodicTimer?.cancel();
    super.dispose();
  }
}
