import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import 'add_friend_screen.dart';
import 'write_post_screen.dart';
import 'map_screen.dart';

class PhotoEditorScreen extends StatefulWidget {
  final List<String> initialImages;

  const PhotoEditorScreen({super.key, required this.initialImages});

  @override
  State<PhotoEditorScreen> createState() => _PhotoEditorScreenState();
}

class _PhotoEditorScreenState extends State<PhotoEditorScreen> {
  late List<String> _images;
  String? _taggedFriend;
  final ImagePicker _picker = ImagePicker();
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _selectedLocation;
  LatLng _currentPosition = const LatLng(37.5666805, 126.9784147); // 서울 시청 기본값

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
    _getCurrentLocation();
  }

  // 현재 위치 가져오기
  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
      
      final controller = await _mapController.future;
      controller.animateCamera(
        CameraUpdate.newLatLng(_currentPosition),
      );
    } catch (e) {
      print("위치 가져오기 실패: $e");
    }
  }

  void _showMenu(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("사진 편집"),
                onTap: () async {
                  Navigator.pop(context);
                  await _editImage(index);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("사진 삭제", style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _images.removeAt(index));
                  Navigator.pop(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.add_photo_alternate, color: Colors.green),
                title: const Text("사진 추가"),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    // 갤러리 열기 (줄바꿈 오류 수정됨)
                    final List<XFile> newImages = await _picker
                        .pickMultiImage();
                    if (newImages.isNotEmpty) {
                      setState(() {
                        for (var img in newImages) {
                          _images.add(img.path);
                        }
                      });
                    }
                  } catch (e) {
                    print("Error picking images: $e");
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_add, color: Colors.orange),
                title: const Text("함께 있는 사람 +"),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddFriendScreen(),
                    ),
                  );
                  if (result != null) {
                    setState(() => _taggedFriend = result);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 이미지 편집 기능 추가
  Future<void> _editImage(int index) async {
    try {
      final File imageFile = File(_images[index]);
      final Uint8List imageBytes = await imageFile.readAsBytes();

      // 이미지 에디터 열기
      final Uint8List? editedImage = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageEditor(
            image: imageBytes,
          ),
        ),
      );

      if (editedImage != null) {
        // 편집된 이미지를 임시 파일로 저장
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final editedFile = File('${tempDir.path}/edited_$timestamp.jpg');
        await editedFile.writeAsBytes(editedImage);

        // 이미지 경로 업데이트
        setState(() {
          _images[index] = editedFile.path;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('사진이 편집되었습니다'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print("Error editing image: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사진 편집에 실패했습니다'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          TextButton(
            onPressed: _images.isEmpty
                ? null
                : () {
                    // 다음 화면으로 이동 (오류 해결됨)
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WritePostScreen(
                          images: _images,
                          taggedFriend: _taggedFriend,
                          selectedLocation: _selectedLocation, // 선택된 위치 전달
                        ),
                      ),
                    );
                  },
            child: Text(
              "다음",
              style: TextStyle(
                fontSize: 16,
                color: _images.isEmpty ? Colors.grey : Colors.blue,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            children: [
            if (_images.isEmpty)
              SizedBox(
                height: 400,
                child: Center(
                  child: Text(
                    "사진을 추가하세요!",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Stack(
                      children: [
                        Container(
                          height: 300,
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(File(_images[index])),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (_taggedFriend != null && index == 0)
                          Positioned(
                            top: 20,
                            left: 30,
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
                                "같이 있는 사람 $_taggedFriend",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          top: 10,
                          right: 25,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.more_vert,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            onPressed: () => _showMenu(index),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          right: 25,
                          child: FloatingActionButton.small(
                            heroTag: 'edit_$index',
                            backgroundColor: Colors.blue,
                            child: const Icon(Icons.edit, size: 20),
                            onPressed: () => _editImage(index),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // 지도 영역 (클릭하면 map_screen으로 이동)
            GestureDetector(
              onTap: () async {
                // map_screen으로 이동하여 위치 선택 (선택 모드로 전환)
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MapScreen(isSelectionMode: true),
                  ),
                );
                
                // map_screen에서 위치를 선택하고 돌아온 경우
                if (result != null && result is LatLng) {
                  setState(() {
                    _selectedLocation = result;
                  });
                  
                  // 선택된 위치로 지도 이동
                  final controller = await _mapController.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLng(result),
                  );
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '위치 선택됨: ${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                }
              },
              child: Container(
                height: 250,
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[100]!),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    // 지도는 터치 비활성화 (보기만 가능)
                    AbsorbPointer(
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition,
                          zoom: 15,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController.complete(controller);
                        },
                        markers: _selectedLocation != null
                            ? {
                                Marker(
                                  markerId: const MarkerId('selected'),
                                  position: _selectedLocation!,
                                  icon: BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed,
                                  ),
                                  infoWindow: const InfoWindow(title: '선택한 위치'),
                                ),
                              }
                            : {},
                      ),
                    ),
                    // 중앙 오버레이 (지도 클릭 유도)
                    if (_selectedLocation == null)
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, size: 20, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                '탭하여 위치 선택하기',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    // 위치 선택됨 표시
                    if (_selectedLocation != null)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 16, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '위치 선택 완료',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }
}
