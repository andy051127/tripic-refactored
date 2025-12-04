import 'package:flutter/material.dart';
import 'dart:io';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../models/post_model.dart'; // 로컬 상태 업데이트용
import 'package:firebase_auth/firebase_auth.dart'; // 사용자 정보 확인

class WritePostScreen extends StatefulWidget {
  final List<String> images;
  final String? taggedFriend;
  final LatLng? selectedLocation; // 선택된 위치 추가
  final String? selectedLocationName; // 선택된 위치 이름 추가

  const WritePostScreen({
    super.key, 
    required this.images, 
    this.taggedFriend,
    this.selectedLocation, // 선택된 위치 추가
    this.selectedLocationName, // 선택된 위치 이름 추가
  });

  @override
  State<WritePostScreen> createState() => _WritePostScreenState();
}

class _WritePostScreenState extends State<WritePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isUploading = false;
  String? _selectedCountry; // 선택된 국가
  String _countrySearchQuery = ''; // 국가 검색어

  // 국가 목록 (travel_plan_setup_screen과 동일)
  final Map<String, String> _countryFlags = {
    '대한민국': '🇰🇷', '일본': '🇯🇵', '중국': '🇨🇳', '대만': '🇹🇼', '홍콩': '🇭🇰', '마카오': '🇲🇴',
    '싱가포르': '🇸🇬', '태국': '🇹🇭', '베트남': '🇻🇳', '필리핀': '🇵🇭', '말레이시아': '🇲🇾',
    '인도네시아': '🇮🇩', '미얀마': '🇲🇲', '캄보디아': '🇰🇭', '라오스': '🇱🇦', '인도': '🇮🇳',
    '네팔': '🇳🇵', '몰디브': '🇲🇻', '스리랑카': '🇱🇰', '미국': '🇺🇸', '캐나다': '🇨🇦',
    '멕시코': '🇲🇽', '쿠바': '🇨🇺', '브라질': '🇧🇷', '아르헨티나': '🇦🇷', '페루': '🇵🇪',
    '칠레': '🇨🇱', '영국': '🇬🇧', '프랑스': '🇫🇷', '이탈리아': '🇮🇹', '스페인': '🇪🇸',
    '독일': '🇩🇪', '네덜란드': '🇳🇱', '벨기에': '🇧🇪', '스위스': '🇨🇭', '오스트리아': '🇦🇹',
    '체코': '🇨🇿', '헝가리': '🇭🇺', '폴란드': '🇵🇱', '그리스': '🇬🇷', '터키': '🇹🇷',
    '포르투갈': '🇵🇹', '아일랜드': '🇮🇪', '노르웨이': '🇳🇴', '스웨덴': '🇸🇪', '덴마크': '🇩🇰',
    '핀란드': '🇫🇮', '아이슬란드': '🇮🇸', '러시아': '🇷🇺', '호주': '🇦🇺', '뉴질랜드': '🇳🇿',
    '이집트': '🇪🇬', '모로코': '🇲🇦', '남아프리카공화국': '🇿🇦', '케냐': '🇰🇪', '탄자니아': '🇹🇿',
    '아랍에미리트': '🇦🇪', '사우디아라비아': '🇸🇦', '카타르': '🇶🇦', '요르단': '🇯🇴', '이스라엘': '🇮🇱',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _uploadPost() async {
    if (_titleController.text.isEmpty || widget.images.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("사진과 제목은 필수입니다!")));
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isUploading = true);

    try {
      // 1. Firestore에 저장 (서버) - 여러 이미지 업로드
      await _firestoreService.addPost(
        title: _titleController.text,
        content: _contentController.text,
        location: widget.selectedLocationName ?? 
            (widget.selectedLocation != null
                ? "${widget.selectedLocation!.latitude.toStringAsFixed(4)}, ${widget.selectedLocation!.longitude.toStringAsFixed(4)}"
                : ""),
        localImagePaths: widget.images, // 여러 이미지 전달
        taggedFriend: widget.taggedFriend,
        latitude: widget.selectedLocation?.latitude,
        longitude: widget.selectedLocation?.longitude,
        locationName: widget.selectedLocationName, // 위치 이름 전달
        country: _selectedCountry, // 국가 정보 전달
      );

      // 2. 로컬 상태(globalPostsNotifier) 업데이트
      // [수정] 실제 사용자 정보를 사용하여 Post 생성
      final currentUser = FirebaseAuth.instance.currentUser;
      final String currentUserName = globalUserName.value; // 전역 변수(내 닉네임) 사용

      final newLocalPost = Post(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        uid: currentUser?.uid ?? '',
        userName: currentUserName, // 올바른 닉네임 사용
        location: widget.selectedLocationName ?? 
            (widget.selectedLocation != null
                ? "${widget.selectedLocation!.latitude.toStringAsFixed(4)}, ${widget.selectedLocation!.longitude.toStringAsFixed(4)}"
                : ""),
        imagePath: widget.images[0],
        imageUrls: widget.images, // 여러 이미지 경로 추가
        title: _titleController.text,
        content: _contentController.text,
        isFile: true,
        latitude: widget.selectedLocation?.latitude,
        longitude: widget.selectedLocation?.longitude,
        locationName: widget.selectedLocationName, // 위치 이름 전달
      );

      final currentPosts = List<Post>.from(globalPostsNotifier.value);
      currentPosts.insert(0, newLocalPost);
      globalPostsNotifier.value = currentPosts;

      if (!mounted) return;

      Navigator.of(context).popUntil((route) => route.isFirst);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시물이 성공적으로 업로드되었습니다! 🎉")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("업로드 실패: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "새 게시물",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          _isUploading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _uploadPost,
                  child: const Text(
                    "업로드",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "게시물의 제목을 입력해주세요.",
                ),
              ),
            ),
            Container(
              height: 200,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "내용을 입력해주세요.",
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 국가 선택 드롭다운
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () {
                  _showCountrySelectionDialog();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      if (_selectedCountry != null)
                        Text(
                          _countryFlags[_selectedCountry] ?? '🌍',
                          style: const TextStyle(fontSize: 20),
                        ),
                      if (_selectedCountry != null)
                        const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedCountry ?? "국가 선택 (선택사항)",
                          style: TextStyle(
                            fontSize: 16,
                            color: _selectedCountry != null ? Colors.black : Colors.grey[600],
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // 선택한 사진들 모두 표시
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  children: [
                    // 모든 이미지를 세로로 나열
                    ...widget.images.asMap().entries.map((entry) {
                      final index = entry.key;
                      final imagePath = entry.value;
                      
                      return Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                height: 300,
                                width: double.infinity,
                                color: Colors.grey[300],
                                child: Image.file(
                                  File(imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              // 첫 번째 이미지에만 태그 표시
                              if (widget.taggedFriend != null && index == 0)
                                Positioned(
                                  top: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "함께: ${widget.taggedFriend!}",
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              // 이미지 순서 표시 (2개 이상일 때만)
                              if (widget.images.length > 1)
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      "${index + 1}/${widget.images.length}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          // 이미지 사이 간격
                          if (index < widget.images.length - 1)
                            const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    // 지도 배너 (선택된 위치 표시)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: widget.selectedLocation != null
                          ? Stack(
                              children: [
                                // 선택된 위치가 있으면 지도 표시
                                GoogleMap(
                                  initialCameraPosition: CameraPosition(
                                    target: widget.selectedLocation!,
                                    zoom: 15,
                                  ),
                                  markers: {
                                    Marker(
                                      markerId: const MarkerId('selected'),
                                      position: widget.selectedLocation!,
                                      icon: BitmapDescriptor.defaultMarkerWithHue(
                                        BitmapDescriptor.hueRed,
                                      ),
                                    ),
                                  },
                                  myLocationButtonEnabled: false,
                                  zoomControlsEnabled: false,
                                  zoomGesturesEnabled: false,
                                  scrollGesturesEnabled: false,
                                  rotateGesturesEnabled: false,
                                  tiltGesturesEnabled: false,
                                  mapToolbarEnabled: false,
                                ),
                                // 위치 정보 표시
                                Positioned(
                                  bottom: 10,
                                  left: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.location_on,
                                          size: 16,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '위치: ${widget.selectedLocation!.latitude.toStringAsFixed(4)}, ${widget.selectedLocation!.longitude.toStringAsFixed(4)}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.location_off,
                                    size: 40,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    "위치가 선택되지 않았습니다",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
        ),
      ),
    );
  }

  // 국가 선택 다이얼로그
  void _showCountrySelectionDialog() {
    String searchQuery = '';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // 검색어로 필터링된 국가 목록
            final filteredCountries = _countryFlags.keys.where((country) {
              return country.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 제목
                    const Text(
                      '국가 선택',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // 검색창
                    TextField(
                      decoration: InputDecoration(
                        hintText: '국가 검색...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // 선택 해제 버튼
                    if (_selectedCountry != null)
                      ListTile(
                        leading: const Icon(Icons.clear, color: Colors.red),
                        title: const Text('선택 해제'),
                        onTap: () {
                          setState(() {
                            _selectedCountry = null;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    
                    // 국가 목록
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final flag = _countryFlags[country] ?? '🌍';
                          final isSelected = _selectedCountry == country;
                          
                          return ListTile(
                            leading: Text(flag, style: const TextStyle(fontSize: 24)),
                            title: Text(country),
                            trailing: isSelected 
                              ? const Icon(Icons.check_circle, color: Colors.blue)
                              : null,
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedCountry = country;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                    
                    // 닫기 버튼
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('닫기'),
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
}
