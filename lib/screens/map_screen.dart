import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';

class MapScreen extends StatefulWidget {
  final bool isSelectionMode; // 위치 선택 모드인지 여부
  final LatLng? initialLocation; // 초기 위치 (게시물 위치 등)
  final String? userId; // 특정 사용자의 게시물만 표시할 경우 사용
  
  const MapScreen({
    super.key, 
    this.isSelectionMode = false,
    this.initialLocation,
    this.userId,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final TextEditingController _searchController = TextEditingController();
  Set<Marker> _markers = {};
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];
  LatLng? _selectedLocationForReturn; // 선택된 위치 (반환용)
  List<Post> _userPosts = []; // 검색된 사용자의 게시물 목록
  int _currentPostIndex = 0; // 현재 보고 있는 게시물 인덱스
  String? _searchedUserName; // 검색된 사용자 이름
  
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
    
    // 선택 모드가 아닐 때만 친구 게시물 마커 생성
    if (!widget.isSelectionMode) {
      _loadPostMarkers();
    }
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

  // Firestore에서 게시물 불러와서 마커 생성
  Future<void> _loadPostMarkers() async {
    try {
      // Firestore에서 위치 정보가 있는 게시물만 가져오기
      Query query = FirebaseFirestore.instance.collection('posts');
      
      // userId가 지정되어 있으면 해당 사용자의 게시물만 필터링
      if (widget.userId != null) {
        query = query.where('uid', isEqualTo: widget.userId);
      }
      
      final QuerySnapshot snapshot = await query.get();

      Set<Marker> markers = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        
        // latitude와 longitude가 모두 존재하는지 확인
        if (data['latitude'] != null && data['longitude'] != null) {
          final post = Post.fromMap(data, doc.id);
          
          markers.add(
            Marker(
              markerId: MarkerId(post.id),
              position: LatLng(post.latitude!, post.longitude!),
              infoWindow: InfoWindow(
                title: post.userName,
                snippet: post.title,
              ),
              onTap: () => _showPostPreview(post),
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _markers = markers;
        });
        
        print('✅ 마커 로드 성공: ${markers.length}개의 마커 생성됨');
      }
    } catch (e) {
      print('❌ 게시물 마커 로드 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게시물을 불러오는데 실패했습니다: $e')),
        );
      }
    }
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

    // 1. Firestore에서 게시물 검색 (사용자 이름으로)
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .get();

      List<Post> matchedPosts = [];
      String? matchedUserName;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userName = data['userName'] ?? '';
        
        if (userName.toLowerCase().contains(query.toLowerCase()) &&
            data['latitude'] != null &&
            data['longitude'] != null) {
          matchedPosts.add(Post.fromMap(data, doc.id));
          matchedUserName = userName;
        }
      }

      if (matchedPosts.isNotEmpty) {
        final firstPost = matchedPosts[0];
        targetLocation = LatLng(
          firstPost.latitude!,
          firstPost.longitude!,
        );
        
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
            _userPosts = matchedPosts;
            _currentPostIndex = 0;
            _searchedUserName = matchedUserName;
          });
          
          final postCount = matchedPosts.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("📍 '$matchedUserName'님의 게시물 $postCount개를 찾았습니다. (1/$postCount)"),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    } catch (e) {
      print('게시물 검색 오류: $e');
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

    // 선택 모드일 경우 선택된 위치로 설정
    if (widget.isSelectionMode) {
      setState(() {
        _selectedLocationForReturn = targetLocation;
        _markers.clear(); // 기존 마커 제거
        _markers.add(
          Marker(
            markerId: const MarkerId('selected_location'),
            position: targetLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: '선택한 위치',
              snippet: result['name'],
            ),
          ),
        );
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      // 검색된 위치에 임시 마커 추가 (일반 모드)
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
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("📍 '${result['name']}'(으)로 이동합니다.")),
      );
    }
  }

  // 다음 게시물로 이동
  Future<void> _navigateToNextPost() async {
    if (_userPosts.isEmpty) return;
    
    setState(() {
      _currentPostIndex = (_currentPostIndex + 1) % _userPosts.length;
    });
    
    final post = _userPosts[_currentPostIndex];
    final controller = await _controller.future;
    
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(post.latitude!, post.longitude!),
          zoom: 15,
        ),
      ),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "📍 $_searchedUserName님의 게시물 (${_currentPostIndex + 1}/${_userPosts.length})",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
  
  // 이전 게시물로 이동
  Future<void> _navigateToPreviousPost() async {
    if (_userPosts.isEmpty) return;
    
    setState(() {
      _currentPostIndex = (_currentPostIndex - 1 + _userPosts.length) % _userPosts.length;
    });
    
    final post = _userPosts[_currentPostIndex];
    final controller = await _controller.future;
    
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(post.latitude!, post.longitude!),
          zoom: 15,
        ),
      ),
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "📍 $_searchedUserName님의 게시물 (${_currentPostIndex + 1}/${_userPosts.length})",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // 지도 탭했을 때 마커 추가 (선택 모드 전용)
  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocationForReturn = location;
      _markers.clear(); // 기존 마커 제거
      _markers.add(
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: '선택한 위치',
            snippet: '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          ),
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '위치 선택됨: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // 마커 클릭 시 미리보기 창 표시
  void _showPostPreview(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // 첫 번째 이미지 가져오기
        final String imageUrl = post.imageUrls.isNotEmpty 
            ? post.imageUrls[0] 
            : (post.imageUrl.isNotEmpty ? post.imageUrl : '');
        
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(post.uid)
              .get(),
          builder: (context, userSnapshot) {
            String? profileImageUrl;
            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
              profileImageUrl = userData?['profileImage'];
            }
            
            return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20,
            top: 20,
          ),
          child: Container(
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
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.image, color: Colors.grey, size: 50);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(child: CircularProgressIndicator());
                          },
                        ),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 50),
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
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.grey,
                            backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                                ? NetworkImage(profileImageUrl)
                                : const AssetImage('assets/basic_profile.png') as ImageProvider,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              post.userName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        post.title,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      StreamBuilder<int>(
                        stream: FirebaseFirestore.instance
                            .collection('posts')
                            .doc(post.id)
                            .collection('likes')
                            .snapshots()
                            .map((snapshot) => snapshot.docs.length),
                        builder: (context, likeSnapshot) {
                          final likeCount = likeSnapshot.data ?? post.likeCount;
                          
                          return StreamBuilder<int>(
                            stream: FirebaseFirestore.instance
                                .collection('posts')
                                .doc(post.id)
                                .collection('comments')
                                .snapshots()
                                .map((snapshot) => snapshot.docs.length),
                            builder: (context, commentSnapshot) {
                              final commentCount = commentSnapshot.data ?? 0;
                              
                              return Row(
                                children: [
                                  const Icon(Icons.favorite, size: 16, color: Colors.red),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$likeCount",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.comment, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    "$commentCount",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: true, // 하단 안전 영역 확보
        child: Stack(
          children: [
          // 전체 화면 지도
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialLocation ?? _kSeoulCityHall,
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
            // 선택 모드일 때만 지도 탭으로 마커 추가 가능
            onTap: widget.isSelectionMode ? _onMapTapped : null,
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
                        onPressed: () {
                          // 선택 모드일 경우 선택된 위치 반환
                          if (widget.isSelectionMode && _selectedLocationForReturn != null) {
                            Navigator.pop(context, _selectedLocationForReturn);
                          } else {
                            Navigator.pop(context);
                          }
                        },
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

          // 사용자 게시물 탐색 버튼 (검색된 경우에만 표시)
          if (_userPosts.length > 1)
            Positioned(
              top: 150,
              right: 20,
              child: Column(
                children: [
                  // 이전 게시물 버튼
                  FloatingActionButton(
                    heroTag: 'prev',
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: _navigateToPreviousPost,
                    child: const Icon(Icons.arrow_upward, color: Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  // 게시물 카운터
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_currentPostIndex + 1}/${_userPosts.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 다음 게시물 버튼
                  FloatingActionButton(
                    heroTag: 'next',
                    mini: true,
                    backgroundColor: Colors.white,
                    elevation: 4,
                    onPressed: _navigateToNextPost,
                    child: const Icon(Icons.arrow_downward, color: Colors.blue),
                  ),
                ],
              ),
            ),

          // 내 위치로 이동 버튼
          Positioned(
            bottom: 20, // 안전 영역 고려하여 간격 조정
            right: 20,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              elevation: 4,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // 선택 모드일 때 하단에 확인 버튼 표시
          if (widget.isSelectionMode && _selectedLocationForReturn != null)
            Positioned(
              bottom: 20, // 안전 영역 고려하여 간격 조정
              left: 20,
              right: 90,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, _selectedLocationForReturn);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      '이 위치로 선택',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
