import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 패키지 필수
import 'dart:io'; // 파일 처리를 위해 필수
import 'photo_editor_screen.dart'; // 다음 화면 연결

class PhotoPickerScreen extends StatefulWidget {
  const PhotoPickerScreen({super.key});

  @override
  State<PhotoPickerScreen> createState() => _PhotoPickerScreenState();
}

class _PhotoPickerScreenState extends State<PhotoPickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImagePaths = []; // 선택된 사진 경로들

  // 1. 카메라 촬영
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() {
          _selectedImagePaths.add(photo.path);
        });
      }
    } catch (e) {
      print("카메라 에러: $e");
    }
  }

  // 2. 갤러리 다중 선택
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            _selectedImagePaths.add(image.path);
          }
        });
      }
    } catch (e) {
      print("갤러리 에러: $e");
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "새 게시물",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            // 사진이 없으면 버튼 비활성화 (회색), 있으면 활성화 (파란색)
            onPressed: _selectedImagePaths.isEmpty
                ? null
                : () {
                    // 다음 화면(편집)으로 경로 리스트 전달
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotoEditorScreen(
                          initialImages: _selectedImagePaths,
                        ),
                      ),
                    );
                  },
            child: Text(
              "다음",
              style: TextStyle(
                fontSize: 16,
                color: _selectedImagePaths.isEmpty ? Colors.grey : Colors.blue,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 상단 버튼 (갤러리/카메라)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library, color: Colors.black),
                    label: const Text(
                      "갤러리에서 선택",
                      style: TextStyle(color: Colors.black),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _takePhoto,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    elevation: 0,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.black),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 선택된 사진 그리드
          Expanded(
            child: _selectedImagePaths.isEmpty
                ? Center(
                    child: Text(
                      "사진을 선택해주세요",
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(2),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 2,
                          mainAxisSpacing: 2,
                        ),
                    itemCount: _selectedImagePaths.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          // 실제 파일 이미지 표시
                          Image.file(
                            File(_selectedImagePaths[index]),
                            fit: BoxFit.cover,
                          ),
                          // 삭제 버튼 (x)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedImagePaths.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          // 순서 번호
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
