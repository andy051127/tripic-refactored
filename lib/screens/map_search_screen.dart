import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'dart:async';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final Completer<NaverMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();

  // 초기 위치 (서울)
  static const NLatLng _kDefaultLocation = NLatLng(37.5666, 126.9784);

  // [데이터] 친구들의 게시물 위치 (검색 대상 1)
  final List<Map<String, dynamic>> _friendPosts = [
    {"name": "김찬희", "location": "남산", "lat": 37.5512, "lng": 126.9882},
    {"name": "이경환", "location": "경복궁", "lat": 37.5796, "lng": 126.9770},
    {"name": "안해진", "location": "익선동", "lat": 37.5743, "lng": 126.9898},
    {"name": "박지성", "location": "해운대", "lat": 35.1587, "lng": 129.1603},
    {"name": "손흥민", "location": "제주도", "lat": 33.4996, "lng": 126.5312},
  ];

  // [데이터] 주요 지역 위치 (검색 대상 2 - 실제 앱에선 Geocoding API 필요)
  final Map<String, NLatLng> _cityLocations = {
    "서울": const NLatLng(37.5665, 126.9780),
    "부산": const NLatLng(35.1796, 129.0756),
    "제주": const NLatLng(33.4996, 126.5312),
    "인천": const NLatLng(37.4563, 126.7052),
    "대구": const NLatLng(35.8714, 128.6014),
    "대전": const NLatLng(36.3504, 127.3845),
    "광주": const NLatLng(35.1595, 126.8526),
  };

  // 검색 실행 함수
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    final controller = await _controller.future;
    NLatLng? targetLocation;
    String? foundName;

    // 1. 친구 이름 검색
    final friend = _friendPosts.firstWhere(
      (post) => post['name'].toString().contains(query),
      orElse: () => {},
    );

    if (friend.isNotEmpty) {
      targetLocation = NLatLng(friend['lat'], friend['lng']);
      foundName = "${friend['name']}님의 게시물";
    }
    // 2. 지역명 검색
    else if (_cityLocations.containsKey(query)) {
      targetLocation = _cityLocations[query];
      foundName = query;
    }

    // 이동
    if (targetLocation != null) {
      final cameraUpdate = NCameraUpdate.withParams(
        target: targetLocation,
        zoom: 15, // 확대 레벨
      );
      await controller.updateCamera(cameraUpdate);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("📍 '$foundName'(으)로 이동합니다.")));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("검색 결과를 찾을 수 없습니다.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. 전체 화면 지도
          NaverMap(
            options: const NaverMapViewOptions(
              initialCameraPosition: NCameraPosition(
                target: _kDefaultLocation,
                zoom: 10,
              ),
              consumeSymbolTapEvents: false,
            ),
            onMapReady: (controller) {
              _controller.complete(controller);

              // 친구 마커 찍기
              for (var post in _friendPosts) {
                final marker = NMarker(
                  id: post['name'], // ID는 유니크해야 함
                  position: NLatLng(post['lat'], post['lng']),
                  caption: NOverlayCaption(
                    text: "${post['name']} (${post['location']})",
                  ),
                );
                controller.addOverlay(marker);
              }
            },
          ),

          // 2. 상단 검색창 (떠있는 UI)
          Positioned(
            top: 50, // 상태바 아래
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
                      onSubmitted: _performSearch, // 엔터 누르면 검색
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
