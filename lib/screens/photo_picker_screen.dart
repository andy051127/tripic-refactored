import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 패키지 필수
import 'dart:io'; // 파일 처리를 위해 필수
import 'dart:convert'; // JSON 인코딩/디코딩
import 'package:path_provider/path_provider.dart'; // 앱 디렉토리 접근
import 'photo_editor_screen.dart'; // 다음 화면 연결
import '../widgets/travel_tracker_button.dart'; // [추가] 여행 기록 버튼
import 'package:geolocator/geolocator.dart';
import '../services/travel_tracker_service.dart';

class PhotoPickerScreen extends StatefulWidget {
  const PhotoPickerScreen({super.key});

  @override
  State<PhotoPickerScreen> createState() => _PhotoPickerScreenState();
}

class _PhotoPickerScreenState extends State<PhotoPickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _selectedImagePaths = []; // 선택된 사진 경로들

  // 1. 카메라 촬영 - GPS 정보 즉시 저장
  Future<void> _takePhoto() async {
    print('🎯 _takePhoto() 시작');
    try {
      print('📷 카메라 앱 열기 시도...');
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      print('📷 카메라 앱에서 돌아옴: photo = ${photo?.path}');
      
      if (photo != null) {
        print('✅ 사진 촬영 성공: ${photo.path}');
        // 촬영 즉시 GPS 정보를 JSON 파일로 저장
        await _savePhotoGpsInfo(photo.path);
        
        setState(() {
          _selectedImagePaths.add(photo.path);
        });
        print('✅ 사진 리스트에 추가 완료');
      } else {
        print('❌ 사진 촬영 취소됨 (photo == null)');
      }
    } catch (e) {
      print("❌ 카메라 에러: $e");
      print("   스택: ${StackTrace.current}");
    }
  }
  
  // 사진 경로에 대한 GPS 정보를 JSON 파일로 저장
  Future<void> _savePhotoGpsInfo(String photoPath) async {
    print('📸 사진 촬영 감지: $photoPath');
    
    try {
      // 현재 위치 가져오기
      print('📍 GPS 위치 요청 중...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      print('📍 GPS 위치 수신: ${position.latitude}, ${position.longitude}');
      
      // 앱 디렉토리에 GPS 파일 저장 (사진 파일명 기반 해시)
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = photoPath.split('/').last.split('\\').last;
      final gpsFile = File('${appDir.path}/gps_$fileName.json');
      
      final gpsData = {
        'photoPath': photoPath,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': position.accuracy,
      };
      await gpsFile.writeAsString(json.encode(gpsData));
      print('✅ GPS 저장 성공: $fileName');
      print('   위도: ${position.latitude}, 경도: ${position.longitude}');
      print('   정확도: ${position.accuracy}m');
      print('   파일: ${gpsFile.path}');
    } catch (e) {
      print('❌ GPS 정보 저장 실패: $e');
      print('   스택: ${StackTrace.current}');
    }
  }
  
  // 저장된 GPS 정보 불러오기
  Future<Position?> _loadPhotoGpsInfo(String photoPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = photoPath.split('/').last.split('\\').last;
      final gpsFile = File('${appDir.path}/gps_$fileName.json');
      
      print('🔍 GPS 파일 검색: ${gpsFile.path}');
      
      if (await gpsFile.exists()) {
        final jsonString = await gpsFile.readAsString();
        final gpsData = json.decode(jsonString);
        
        final position = Position(
          latitude: gpsData['latitude'],
          longitude: gpsData['longitude'],
          timestamp: DateTime.parse(gpsData['timestamp']),
          accuracy: gpsData['accuracy'] ?? 0.0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        
        print('✅ GPS 로드 성공: $fileName');
        print('   위도: ${position.latitude}, 경도: ${position.longitude}');
        return position;
      } else {
        print('❌ GPS 파일 없음: ${gpsFile.path}');
      }
    } catch (e) {
      print('❌ GPS 정보 로드 실패: $e');
    }
    return null;
  }

  // 2. 갤러리 다중 선택 - GPS 정보 없으므로 현재 위치 저장
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        // 갤러리 사진은 현재 위치로 GPS 정보 저장
        for (var image in images) {
          await _savePhotoGpsInfo(image.path);
        }
        
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

  // 사진 위치 기록 함수 - 저장된 GPS 정보 활용
  Future<void> _recordPhotoLocations(List<String> imagePaths) async {
    final tracker = TravelTrackerService();
    if (!tracker.isTracking) return;

    for (var imagePath in imagePaths) {
      try {
        // 저장된 GPS 정보 불러오기
        Position? position = await _loadPhotoGpsInfo(imagePath);
        
        if (position == null) {
          // GPS 정보 없으면 현재 위치 사용
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          print('⚠️ GPS 파일 없음 - 현재 위치 사용: ${position.latitude}, ${position.longitude}');
        }

        await tracker.addPhotoRecord(imagePath, position);
        print('✅ 사진 위치 기록 완료: ${position.latitude}, ${position.longitude}');
      } catch (e) {
        print('❌ 사진 위치 기록 실패: $e');
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
                : () async {
                    // 여행 기록 활성화 시 GPS 정보 기록
                    await _recordPhotoLocations(_selectedImagePaths);
                    
                    // 다음 화면(편집)으로 경로 리스트 전달
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoEditorScreen(
                            initialImages: _selectedImagePaths,
                          ),
                        ),
                      );
                    }
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
      body: SafeArea(
        child: Column(
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

          // [추가] 여행 기록 버튼
          const TravelTrackerButton(),

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
      ),
    );
  }
}
