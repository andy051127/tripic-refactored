import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class MapDetailScreen extends StatefulWidget {
  const MapDetailScreen({super.key});

  @override
  State<MapDetailScreen> createState() => _MapDetailScreenState();
}

class _MapDetailScreenState extends State<MapDetailScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  // 초기 위치 (서울 시청) - GPS를 못 잡을 경우 대비
  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.5665, 126.9780),
    zoom: 14.4746,
  );

  // 지도에 표시할 마커들
  final Set<Marker> _markers = {};

  // 친구들의 게시물 데이터 (더미 데이터)
  final List<Map<String, dynamic>> _friendPosts = [
    {
      "id": "1",
      "name": "김찬희",
      "title": "남산 타워 뷰 맛집!",
      "lat": 37.5512,
      "lng": 126.9882,
      "image": "assets/logo.png", // 실제 이미지 경로라면 FileImage 등 사용
    },
    {
      "id": "2",
      "name": "이경환",
      "title": "경복궁 야간 개장",
      "lat": 37.5796,
      "lng": 126.9770,
      "image": "assets/logo.png",
    },
    {
      "id": "3",
      "name": "안해진",
      "title": "익선동 카페거리",
      "lat": 37.5743,
      "lng": 126.9898,
      "image": "assets/logo.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _createMarkers();
  }

  // 1. 위치 권한 확인 및 현재 위치로 이동
  Future<void> _checkPermissions() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      _getCurrentLocation();
    }
  }

  // 2. 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 15,
          ),
        ),
      );
    } catch (e) {
      print("위치 가져오기 실패: $e");
    }
  }

  // 3. 친구들 게시물 위치에 마커 찍기
  void _createMarkers() {
    for (var post in _friendPosts) {
      _markers.add(
        Marker(
          markerId: MarkerId(post['id']),
          position: LatLng(post['lat'], post['lng']),
          infoWindow: InfoWindow(title: post['name'], snippet: post['title']),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () {
            _showPostPreview(post);
          },
        ),
      );
    }
    setState(() {});
  }

  // 마커 클릭 시 하단에 뜨는 미리보기 창
  void _showPostPreview(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(20),
          height: 150,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              // 사진 영역
              Container(
                width: 120,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  color: Colors.grey[200],
                  image: const DecorationImage(
                    image: AssetImage(
                      'assets/logo.png',
                    ), // 실제론 post['image'] 사용
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Icon(
                  Icons.image,
                  color: Colors.grey,
                ), // 이미지가 없을 때 아이콘
              ),
              // 정보 영역
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            post['name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post['title'],
                        style: const TextStyle(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          Icon(Icons.favorite, size: 16, color: Colors.red),
                          SizedBox(width: 4),
                          Text(
                            "12",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          SizedBox(width: 10),
                          Icon(Icons.comment, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(
                            "5",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _kGooglePlex,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers: _markers,
            myLocationEnabled: true, // 내 위치 파란 점 표시
            myLocationButtonEnabled: false, // 기본 버튼 숨김 (커스텀 버튼 사용)
            zoomControlsEnabled: false,
          ),

          // 상단 뒤로가기 버튼
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 내 위치로 이동 버튼
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
