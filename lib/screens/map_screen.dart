import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  
  // ⚠️ 중요: Google Cloud Console에서 발급받은 실제 API 키로 교체하세요
  static const String _googleApiKey = 'AIzaSyBZt7UnBDxY-D6jrsuj_Y7Q5JSolghwwjg';

  // 초기 위치 (서울 시청)
  static const LatLng _kSeoulCityHall = LatLng(37.5666805, 126.9784147);

  // 친구들의 게시물 데이터
  final List<Map<String, dynamic>> _friendPosts = [
    {
      "id": "1",
      "name": "김찬희",
      "title": "남산 타워 뷰 맛집!",
      "location": "남산",
      "lat": 37.5512,
      "lng": 126.9882,
      "image": "assets/logo.png",
    },
    {
      "id": "2",
      "name": "이경환",
      "title": "경복궁 야간 개장",
      "location": "경복궁",
      "lat": 37.5796,
      "lng": 126.9770,
      "image": "assets/logo.png",
    },
    {
      "id": "3",
      "name": "안해진",
      "title": "익선동 카페거리",
      "location": "익선동",
      "lat": 37.5743,
      "lng": 126.9898,
      "image": "assets/logo.png",
    },
    {
      "id": "4",
      "name": "박지성",
      "title": "해운대 해수욕장",
      "location": "해운대",
      "lat": 35.1587,
      "lng": 129.1603,
      "image": "assets/logo.png",
    },
    {
      "id": "5",
      "name": "손흥민",
      "title": "제주도 여행",
      "location": "제주",
      "lat": 33.4996,
      "lng": 126.5312,
      "image": "assets/logo.png",
    },
  ];

  // 주요 지역 위치
  final Map<String, LatLng> _cityLocations = {
    "서울": const LatLng(37.5665, 126.9780),
    "부산": const LatLng(35.1796, 129.0756),
    "인천": const LatLng(37.4563, 126.7052),
    "대구": const LatLng(35.8714, 128.6014),
    "대전": const LatLng(36.3504, 127.3845),
    "광주": const LatLng(35.1595, 126.8526),
    "울산": const LatLng(35.5384, 129.3114),
    "세종": const LatLng(36.4800, 127.2890),
    "수원": const LatLng(37.2636, 127.0286),
    "용인": const LatLng(37.2410, 127.1775),
    "고양": const LatLng(37.6584, 126.8320),
    "창원": const LatLng(35.2280, 128.6811),
    "강릉": const LatLng(37.7519, 128.8761),
    "제주": const LatLng(33.4996, 126.5312),
    "전주": const LatLng(35.8242, 127.1480),
    "천안": const LatLng(36.8151, 127.1139),
    "청주": const LatLng(36.6424, 127.4890),
    "포항": const LatLng(36.0190, 129.3435),
    "경주": const LatLng(35.8562, 129.2247),
    "춘천": const LatLng(37.8813, 127.7300),
    "남산": const LatLng(37.5512, 126.9882),
    "명동": const LatLng(37.5636, 126.9826),
    "강남": const LatLng(37.4979, 127.0276),
    "홍대": const LatLng(37.5566, 126.9235),
    "이태원": const LatLng(37.5347, 126.9945),
    "해운대": const LatLng(35.1587, 129.1603),
    "광안리": const LatLng(35.1532, 129.1189),
    "익선동": const LatLng(37.5743, 126.9898),
    "경복궁": const LatLng(37.5796, 126.9770),
  };

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _createMarkers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 위치 권한 확인
  Future<void> _checkPermissions() async {
    await Permission.location.request();
  }

  // 마커 생성
  void _createMarkers() {
    setState(() {
      _markers = _friendPosts.map((post) {
        return Marker(
          markerId: MarkerId(post['id']),
          position: LatLng(post['lat'], post['lng']),
          infoWindow: InfoWindow(
            title: post['name'],
            snippet: post['title'],
          ),
          onTap: () => _showPostPreview(post),
        );
      }).toSet();
    });
  }

  // 현재 위치로 이동
  Future<void> _moveToCurrentLocation() async {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치를 가져올 수 없습니다')),
        );
      }
    }
  }

  // 검색 실행 함수
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    final controller = await _controller.future;
    LatLng? targetLocation;
    String? foundName;

    // 1. 친구 이름으로 검색
    final friend = _friendPosts.firstWhere(
      (post) => post['name'].toString().toLowerCase().contains(query.toLowerCase()),
      orElse: () => {},
    );

    if (friend.isNotEmpty) {
      targetLocation = LatLng(friend['lat'], friend['lng']);
      foundName = "${friend['name']}님의 게시물";
      
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetLocation,
            zoom: 15,
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("📍 '$foundName'(으)로 이동합니다.")),
        );
      }
      return;
    }

    // 2. 로컬 위치명으로 검색
    bool foundInLocalData = false;
    for (var entry in _cityLocations.entries) {
      if (entry.key.toLowerCase().contains(query.toLowerCase())) {
        targetLocation = entry.value;
        foundName = entry.key;
        foundInLocalData = true;
        
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: targetLocation,
              zoom: 15,
            ),
          ),
        );

        if (mounted) {
          setState(() {
            _isSearching = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("📍 '$foundName'(으)로 이동합니다.")),
          );
        }
        return;
      }
    }

    // 3. Google Places API로 검색
    if (!foundInLocalData) {
      await _searchWithGooglePlaces(query);
    }
  }

  // Google Places API 검색
  Future<void> _searchWithGooglePlaces(String query) async {
    try {
      // Places API - Text Search 사용
      final String url = 
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$query'
          '&language=ko'
          '&key=$_googleApiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          // 검색 결과 저장
          List<Map<String, dynamic>> results = [];
          for (var result in data['results']) {
            results.add({
              'name': result['name'],
              'address': result['formatted_address'] ?? '',
              'lat': result['geometry']['location']['lat'],
              'lng': result['geometry']['location']['lng'],
              'placeId': result['place_id'],
            });
          }

          setState(() {
            _searchResults = results;
            _isSearching = true;
          });

          // 첫 번째 결과가 하나만 있으면 바로 이동
          if (results.length == 1) {
            _moveToSearchResult(results[0]);
          }
        } else {
          // 검색 결과 없음
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['status'] == 'ZERO_RESULTS' 
                    ? '검색 결과를 찾을 수 없습니다.'
                    : 'API 오류: ${data['status']}'),
              ),
            );
          }
        }
      } else {
        throw Exception('API 요청 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('Places API 검색 오류: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('검색 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 검색 결과로 이동
  Future<void> _moveToSearchResult(Map<String, dynamic> result) async {
    final controller = await _controller.future;
    final targetLocation = LatLng(result['lat'], result['lng']);

    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: targetLocation,
          zoom: 15,
        ),
      ),
    );

    // 검색된 위치에 임시 마커 추가
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('search_result_${result['placeId']}'),
          position: targetLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: InfoWindow(
            title: result['name'],
            snippet: result['address'],
          ),
        ),
      );
      _isSearching = false;
      _searchResults = [];
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📍 '${result['name']}'(으)로 이동합니다.")),
      );
    }
  }

  // 마커 클릭 시 미리보기 창 표시
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
                ),
                child: const Icon(Icons.image, color: Colors.grey, size: 50),
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
          // 전체 화면 지도
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _kSeoulCityHall,
              zoom: 15,
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

          // 상단 검색창
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
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
                          onChanged: (value) {
                            // 입력하는 동안 검색 결과 초기화
                            if (_searchResults.isNotEmpty) {
                              setState(() {
                                _searchResults = [];
                              });
                            }
                          },
                          onTap: () {
                            setState(() {
                              _isSearching = true;
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: "장소, 주소, 친구 이름 검색",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 10),
                          ),
                        ),
                      ),
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _isSearching = false;
                              _searchResults = [];
                            });
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.search, color: Colors.blue),
                        onPressed: () => _performSearch(_searchController.text),
                      ),
                    ],
                  ),
                ),
                
                // 검색 결과 리스트
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 300),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.place, color: Colors.blue),
                          title: Text(
                            result['name'],
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            result['address'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onTap: () => _moveToSearchResult(result),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // 내 위치로 이동 버튼
          Positioned(
            bottom: 30,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
