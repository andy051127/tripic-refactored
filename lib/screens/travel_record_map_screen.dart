import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_record_model.dart';
import '../services/travel_tracker_service.dart';

/// 여행 경로와 사진을 표시하는 전체 화면 지도
class TravelRecordMapScreen extends StatefulWidget {
  final TravelRecord? travelRecord; // null이면 현재 활성 기록 사용
  final String? userId; // 특정 사용자의 모든 여행 기록 표시

  const TravelRecordMapScreen({
    super.key,
    this.travelRecord,
    this.userId,
  });

  @override
  State<TravelRecordMapScreen> createState() => _TravelRecordMapScreenState();
}

class _TravelRecordMapScreenState extends State<TravelRecordMapScreen> {
  final TravelTrackerService _trackerService = TravelTrackerService();
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  PhotoRecord? _selectedPhoto;
  LatLng? _currentPosition;
  BitmapDescriptor? _blackDotIcon; // 검은 점 아이콘
  List<TravelRecord> _userTravelRecords = []; // 사용자의 모든 여행 기록
  bool _isLoadingRecords = false;

  @override
  void initState() {
    super.initState();
    print('🚀 TravelRecordMapScreen initState 호출됨');
    print('   - userId: ${widget.userId}');
    print('   - travelRecord: ${widget.travelRecord?.id}');
    
    // 항상 실시간 업데이트 리스너 등록
    _trackerService.addListener(_updateMap);
    
    if (widget.userId != null) {
      print('   → 사용자 여행 기록 로드 모드 (실시간 업데이트 활성화)');
      _loadUserTravelRecords();
    } else {
      print('   → 현재 추적 중인 기록 표시 모드');
    }
    _getCurrentLocation();
    _initializeMap();
  }

  // 지도 초기화 - 아이콘 생성 후 맵 요소 빌드
  Future<void> _initializeMap() async {
    await _createBlackDotIcon();
    _buildMapElements();
  }

  // 검은 점 아이콘 생성 (24px 크기 - 동선보다 잘 보이도록)
  Future<void> _createBlackDotIcon() async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    // 24x24 픽셀 크기의 검은 원
    canvas.drawCircle(const Offset(12, 12), 10, paint);
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(24, 24);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();
    
    _blackDotIcon = BitmapDescriptor.fromBytes(buffer);
    print('✅ 검은 점 아이콘 생성 완료: ${buffer.length} bytes');
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _trackerService.getCurrentPosition();
      if (position != null && mounted) {
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
        });
        // 지도가 준비되면 현재 위치로 이동
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_currentPosition!, 15),
          );
        }
      }
    } catch (e) {
      print('현재 위치 가져오기 실패: $e');
    }
  }

  // 특정 사용자의 모든 여행 기록 불러오기
  Future<void> _loadUserTravelRecords() async {
    if (widget.userId == null) return;
    
    setState(() {
      _isLoadingRecords = true;
    });

    try {
      print('📍 사용자 여행 기록 로드 시작: ${widget.userId}');
      
      // orderBy 제거 - Firestore 인덱스 불필요
      final snapshot = await FirebaseFirestore.instance
          .collection('travel_records')
          .where('userId', isEqualTo: widget.userId)
          .get();

      print('📊 Firestore 쿼리 결과: ${snapshot.docs.length}개 문서');

      final records = snapshot.docs
          .map((doc) {
            print('  - 문서 ID: ${doc.id}');
            final data = doc.data();
            print('    userId: ${data['userId']}');
            print('    isActive: ${data['isActive']}');
            print('    routePoints: ${(data['routePoints'] as List?)?.length ?? 0}개');
            print('    photos: ${(data['photos'] as List?)?.length ?? 0}개');
            return TravelRecord.fromMap(data, doc.id);
          })
          .toList();

      // 메모리에서 시작 시간으로 정렬 (최신순)
      records.sort((a, b) => b.startTime.compareTo(a.startTime));

      print('✅ 여행 기록 ${records.length}개 로드 완료');
      for (int i = 0; i < records.length; i++) {
        print('  [${i + 1}] 경로: ${records[i].routePoints.length}개, 사진: ${records[i].photos.length}개');
      }
      
      if (mounted) {
        setState(() {
          _userTravelRecords = records;
          _isLoadingRecords = false;
        });
        _buildMapElements();
      }
    } catch (e) {
      print('❌ 여행 기록 로드 실패: $e');
      print('   스택: ${StackTrace.current}');
      if (mounted) {
        setState(() {
          _isLoadingRecords = false;
        });
      }
    }
  }

  @override
  void dispose() {
    // 항상 리스너 제거
    _trackerService.removeListener(_updateMap);
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMap() {
    if (mounted) {
      setState(() {
        // userId 모드이고 현재 활성 기록이 있으면 즉시 반영
        if (widget.userId != null && _trackerService.currentRecord != null) {
          // 기존 리스트에서 활성 기록 찾아서 업데이트
          final activeRecordId = _trackerService.currentRecord!.id;
          final index = _userTravelRecords.indexWhere((r) => r.id == activeRecordId);
          if (index != -1) {
            _userTravelRecords[index] = _trackerService.currentRecord!;
          } else {
            // 새로운 기록이면 추가
            _userTravelRecords.add(_trackerService.currentRecord!);
          }
        }
        _buildMapElements();
      });
    }
  }

  TravelRecord? get _currentRecord =>
      widget.travelRecord ?? _trackerService.currentRecord;

  void _buildMapElements() {
    _polylines = {};
    _markers = {};

    // userId가 있으면 사용자의 모든 여행 기록 표시
    if (widget.userId != null) {
      _buildUserTravelRecordsMap();
      return;
    }

    // 단일 여행 기록 표시
    final record = _currentRecord;
    if (record == null) return;

    // 경로 선 생성 (부드럽고 두껍게)
    if (record.routePoints.isNotEmpty) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('travel_route'),
          points: record.routePoints.map((p) => p.latLng).toList(),
          color: Colors.blue.withOpacity(0.8),
          width: 8,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    // 모든 사진 위치를 작은 검은 점 마커로 표시
    print('📍 사진 개수: ${record.photos.length}, 아이콘 준비: ${_blackDotIcon != null}');
    if (_blackDotIcon != null) {
      for (int i = 0; i < record.photos.length; i++) {
        final photo = record.photos[i];
        
        _markers.add(
          Marker(
            markerId: MarkerId('photo_$i'),
            position: photo.latLng,
            icon: _blackDotIcon!,
            anchor: const Offset(0.5, 0.5),
            zIndex: 10, // 동선(기본 0) 위에 표시
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                _selectedPhoto = photo;
              });
            },
          ),
        );
      }
      print('✅ 마커 ${_markers.length}개 생성 완료');
    }
  }

  // 사용자의 모든 여행 기록을 지도에 표시
  void _buildUserTravelRecordsMap() {
    print('🗺️ _buildUserTravelRecordsMap 시작');
    print('   - 여행 기록 수: ${_userTravelRecords.length}');
    print('   - 아이콘 준비: ${_blackDotIcon != null}');
    
    if (_userTravelRecords.isEmpty) {
      print('⚠️ 여행 기록이 비어있음');
      return;
    }
    
    if (_blackDotIcon == null) {
      print('⚠️ 검은 점 아이콘이 준비되지 않음');
      return;
    }

    final polylines = <Polyline>{};
    final markers = <Marker>{};
    int photoIndex = 0;

    // 각 여행 기록마다 다른 색상 사용
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
    ];

    for (int recordIndex = 0; recordIndex < _userTravelRecords.length; recordIndex++) {
      final record = _userTravelRecords[recordIndex];
      final color = colors[recordIndex % colors.length];

      print('📊 기록 [$recordIndex]:');
      print('   - 경로 포인트: ${record.routePoints.length}개');
      print('   - 사진: ${record.photos.length}개');

      // 경로 선
      if (record.routePoints.isNotEmpty) {
        final points = record.routePoints.map((p) => p.latLng).toList();
        print('   - 첫 포인트: ${points.first.latitude}, ${points.first.longitude}');
        print('   - 마지막 포인트: ${points.last.latitude}, ${points.last.longitude}');
        
        polylines.add(
          Polyline(
            polylineId: PolylineId('route_$recordIndex'),
            points: points,
            color: color.withOpacity(0.8),
            width: 8,
            geodesic: true,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }

      // 사진 마커
      for (final photo in record.photos) {
        print('   - 사진 마커 추가: ${photo.latitude}, ${photo.longitude}');
        markers.add(
          Marker(
            markerId: MarkerId('photo_${recordIndex}_${photoIndex++}'),
            position: photo.latLng,
            icon: _blackDotIcon!,
            anchor: const Offset(0.5, 0.5),
            zIndex: 10,
            consumeTapEvents: true,
            onTap: () {
              setState(() {
                _selectedPhoto = photo;
              });
            },
          ),
        );
      }
    }

    print('✅ 최종 결과:');
    print('   - 폴리라인: ${polylines.length}개');
    print('   - 마커: ${markers.length}개');

    setState(() {
      _polylines = polylines;
      _markers = markers;
    });

    print('✅ 여행 기록 ${_userTravelRecords.length}개의 경로와 사진 ${markers.length}개 표시');
  }

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  LatLng get _initialPosition {
    // userId 모드: 사용자의 첫 번째 여행 기록 위치
    if (widget.userId != null && _userTravelRecords.isNotEmpty) {
      final firstRecord = _userTravelRecords.first;
      if (firstRecord.routePoints.isNotEmpty) {
        return firstRecord.routePoints.first.latLng;
      }
      if (firstRecord.photos.isNotEmpty) {
        return firstRecord.photos.first.latLng;
      }
    }
    
    // 1순위: 현재 위치
    if (_currentPosition != null) {
      return _currentPosition!;
    }
    // 2순위: 기록된 경로의 첫 위치
    final record = _currentRecord;
    if (record != null && record.routePoints.isNotEmpty) {
      return record.routePoints.first.latLng;
    }
    // 3순위: 서울 기본 위치
    return const LatLng(37.5665, 126.9780);
  }

  void _fitMapToRoute() {
    if (_mapController == null) return;

    List<LatLng> points = [];

    // userId 모드: 모든 여행 기록의 포인트 수집
    if (widget.userId != null) {
      for (final record in _userTravelRecords) {
        points.addAll(record.routePoints.map((p) => p.latLng));
        points.addAll(record.photos.map((p) => p.latLng));
      }
    } else {
      // 단일 기록 모드
      final record = _currentRecord;
      if (record == null || record.routePoints.isEmpty) return;
      points = record.routePoints.map((p) => p.latLng).toList();
    }

    if (points.isEmpty) return;
    
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50),
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = _currentRecord;
    final isUserMode = widget.userId != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isUserMode ? '여행 기록 지도' : '여행 기록',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isUserMode)
              Text(
                '총 ${_userTravelRecords.length}개의 여행 기록',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              )
            else if (record != null)
              Text(
                _formatTime(record.startTime) +
                    (record.endTime != null
                        ? ' ~ ${_formatTime(record.endTime!)}'
                        : ' (진행 중)'),
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        actions: [
          if ((isUserMode && _userTravelRecords.isNotEmpty) ||
              (!isUserMode && record != null && record.routePoints.isNotEmpty))
            IconButton(
              icon: const Icon(Icons.fit_screen, color: Colors.black),
              onPressed: _fitMapToRoute,
              tooltip: '전체 경로 보기',
            ),
        ],
      ),
      body: _isLoadingRecords
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 15,
                  ),
            onMapCreated: (controller) {
              _mapController = controller;
              if (mounted) {
                // 현재 위치가 있으면 먼저 이동
                if (_currentPosition != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_currentPosition!, 15),
                  );
                }
                // 경로가 있으면 전체 경로 표시
                Future.delayed(
                  const Duration(milliseconds: 800),
                  () {
                    final record = _currentRecord;
                    if (record != null && record.routePoints.isNotEmpty) {
                      _fitMapToRoute();
                    }
                  },
                );
              }
            },
            polylines: _polylines,
            markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),

                // 사진 팝업 (중앙)
                if (_selectedPhoto != null)
                  Center(
                    child: _buildPhotoPopup(_selectedPhoto!),
                  ),
              ],
            ),
    );
  }

  Widget _buildPhotoPopup(PhotoRecord photo) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPhoto = null;
        });
      },
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 사진 표시
              Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildPhotoImage(photo),
                ),
              ),
              
              // 촬영 시간
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '촬영 시간: ${_formatTime(photo.timestamp)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoImage(PhotoRecord photo) {
    final file = File(photo.photoPath);
    
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
      );
    } else if (photo.photoPath.startsWith('http')) {
      return Image.network(
        photo.photoPath,
        fit: BoxFit.contain,
        errorBuilder: (c, o, s) => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                size: 50,
                color: Colors.grey,
              ),
              SizedBox(height: 8),
              Text('사진을 불러올 수 없습니다'),
            ],
          ),
        ),
      );
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: 50,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text('사진을 불러올 수 없습니다'),
          ],
        ),
      );
    }
  }
}
