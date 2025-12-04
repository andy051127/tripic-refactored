import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/travel_record_model.dart';
import '../services/travel_tracker_service.dart';

/// 여행 경로와 사진을 표시하는 전체 화면 지도
class TravelRecordMapScreen extends StatefulWidget {
  final TravelRecord? travelRecord; // null이면 현재 활성 기록 사용

  const TravelRecordMapScreen({
    super.key,
    this.travelRecord,
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

  @override
  void initState() {
    super.initState();
    _trackerService.addListener(_updateMap);
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

  @override
  void dispose() {
    _trackerService.removeListener(_updateMap);
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMap() {
    if (mounted) {
      setState(() {
        _buildMapElements();
      });
    }
  }

  TravelRecord? get _currentRecord =>
      widget.travelRecord ?? _trackerService.currentRecord;

  void _buildMapElements() {
    final record = _currentRecord;
    if (record == null) return;

    // 경로 선 생성 (부드럽게)
    if (record.routePoints.isNotEmpty) {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('travel_route'),
          points: record.routePoints.map((p) => p.latLng).toList(),
          color: Colors.blue,
          width: 4,
          geodesic: true,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }

    // 모든 사진 위치를 작은 검은 점 마커로 표시
    _markers = {};
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

  String _formatTime(DateTime time) {
    return '${time.month}/${time.day} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
  }

  LatLng get _initialPosition {
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
    final record = _currentRecord;
    if (record == null ||
        record.routePoints.isEmpty ||
        _mapController == null) return;

    final points = record.routePoints.map((p) => p.latLng).toList();
    
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
            const Text(
              '여행 기록',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (record != null)
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
          if (record != null && record.routePoints.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.fit_screen, color: Colors.black),
              onPressed: _fitMapToRoute,
              tooltip: '전체 경로 보기',
            ),
        ],
      ),
      body: Stack(
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
