import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:image_editor_plus/image_editor_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'add_friend_screen.dart';
import 'write_post_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
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
      body: SingleChildScrollView(
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

            // 지도 영역
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: const Center(
                child: Text(
                  "지도 API 연동 영역",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
