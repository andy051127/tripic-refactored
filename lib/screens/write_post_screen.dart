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
}
