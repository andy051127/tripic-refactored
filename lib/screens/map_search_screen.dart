import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};

  // 초기 위치 (서울)
  static const LatLng _kDefaultLocation = LatLng(37.5666, 126.9784);

  // [데이터] 친구들의 게시물 위치 (검색 대상 1)
  final List<Map<String, dynamic>> _friendPosts = [
    {"name": "김찬희", "location": "남산", "lat": 37.5512, "lng": 126.9882},
    {"name": "이경환", "location": "경복궁", "lat": 37.5796, "lng": 126.9770},
    {"name": "안해진", "location": "익선동", "lat": 37.5743, "lng": 126.9898},
    {"name": "박지성", "location": "해운대", "lat": 35.1587, "lng": 129.1603},
    {"name": "손흥민", "location": "제주도", "lat": 33.4996, "lng": 126.5312},
  ];

  // [데이터] 주요 지역 위치 (검색 대상 2 - 실제 앱에선 Geocoding API 필요)
  final Map<String, LatLng> _cityLocations = {
    "서울": const LatLng(37.5665, 126.9780),
    "부산": const LatLng(35.1796, 129.0756),
    "제주": const LatLng(33.4996, 126.5312),
    "인천": const LatLng(37.4563, 126.7052),
    "대구": const LatLng(35.8714, 128.6014),
    "대전": const LatLng(36.3504, 127.3845),
    "광주": const LatLng(35.1595, 126.8526),
  };

  @override
  void initState() {
    super.initState();
    _createMarkers();
  }

  // 마커 생성
  void _createMarkers() {
    setState(() {
      _markers = _friendPosts.map((post) {
        return Marker(
          markerId: MarkerId(post['name']),
          position: LatLng(post['lat'], post['lng']),
          infoWindow: InfoWindow(
            title: post['name'],
            snippet: post['location'],
          ),
        );
      }).toSet();
    });
  }

  // 검색 실행 함수
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    final controller = await _controller.future;
    LatLng? targetLocation;
    String? foundName;

    // 1. 친구 이름 검색
    final friend = _friendPosts.firstWhere(
      (post) => post['name'].toString().contains(query),
      orElse: () => {},
    );

    if (friend.isNotEmpty) {
      targetLocation = LatLng(friend['lat'], friend['lng']);
      foundName = "${friend['name']}님의 게시물";
    }
    // 2. 지역명 검색
    else if (_cityLocations.containsKey(query)) {
      targetLocation = _cityLocations[query];
      foundName = query;
    }

    // 이동
    if (targetLocation != null) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 15,
          ),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📍 '$foundName'(으)로 이동합니다.")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("검색 결과를 찾을 수 없습니다.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 전체 화면 지도
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _kDefaultLocation,
              zoom: 10,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),

          // 2. 상단 검색창 (떠있는 UI)
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
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
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: _performSearch,
                      decoration: const InputDecoration(
                        hintText: "친구 이름 또는 지역 검색 (예: 김찬희, 부산)",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: Colors.blue),
                    onPressed: () => _performSearch(_searchController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
