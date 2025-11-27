import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart'; // Firestore 서비스 import

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // [수정] _firestoreService 멤버 변수 선언
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  // 상태 변수들
  String _selectedCategory = 'general'; // 'general' or 'companion'
  bool _isUploading = false;
  List<String> _selectedImages = [];

  // 동행글 전용 상태 변수
  String? _selectedLocation;
  DateTimeRange? _selectedDateRange;
  int? _selectedMemberCount;
  bool _isAnonymous = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 게시하기 버튼 클릭 시 실행
  void _uploadCommunityPost() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("제목과 내용을 입력해주세요.")));
      return;
    }

    // 동행글 필수 정보 확인
    if (_selectedCategory == 'companion') {
      if (_selectedLocation == null ||
          _selectedDateRange == null ||
          _selectedMemberCount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("여행 장소, 날짜, 인원을 모두 설정해주세요.")),
        );
        return;
      }
    }

    setState(() => _isUploading = true);

    try {
      // 이미지 경로 처리 (첫 번째 이미지만 사용하거나 여러 개를 리스트로 저장할 수 있음)
      List<String> imagePaths = _selectedImages;

      // 날짜 포맷팅
      String? formattedDateRange;
      if (_selectedDateRange != null) {
        formattedDateRange =
            "${DateFormat('yyyy.MM.dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy.MM.dd').format(_selectedDateRange!.end)}";
      }

      await _firestoreService.addPost(
        title: _titleController.text,
        content: _contentController.text,
        category: _selectedCategory,
        // TODO: FirestoreService.addPost 메소드가 아래 필드들을 받을 수 있도록 수정 필요
        // images: imagePaths,
        // location: _selectedLocation,
        // dateRange: formattedDateRange,
        // memberCount: _selectedMemberCount,
        // isAnonymous: _isAnonymous,
        location: _selectedLocation ?? "", // location 필수값이므로 임시값 설정 또는 수정 필요
        localImagePath: imagePaths.isNotEmpty ? imagePaths[0] : "", // 필수값 처리
      );

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시글이 등록되었습니다.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // 이미지 선택 기능
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var img in images) _selectedImages.add(img.path);
        });
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  // 장소 선택 모달 (임시 구현 - 추후 구글 맵 연동 등으로 교체)
  void _showLocationModal() {
    showDialog(
      context: context,
      builder: (context) {
        String tempLocation = '';
        return AlertDialog(
          title: const Text("여행 장소 선택"),
          content: TextField(
            onChanged: (value) => tempLocation = value,
            decoration: const InputDecoration(
              hintText: "장소를 입력하세요 (예: 서울, 부산)",
            ),
          ),
          actions: [
            TextButton(
              child: const Text("취소"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("확인"),
              onPressed: () {
                setState(() => _selectedLocation = tempLocation);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // 날짜 선택 모달 (기간 선택)
  void _showDateModal() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CA1AF), // 선택된 날짜 색상
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateRange) {
      setState(() => _selectedDateRange = picked);
    }
  }

  // 인원 설정 모달
  void _showMemberCountModal() {
    showDialog(
      context: context,
      builder: (context) {
        int tempCount = _selectedMemberCount ?? 1;
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return AlertDialog(
              title: const Text("인원 설정"),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () => setStateModal(() {
                      if (tempCount > 1) tempCount--;
                    }),
                  ),
                  Text(
                    "$tempCount명",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () => setStateModal(() {
                      tempCount++;
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text("취소"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text("확인"),
                  onPressed: () {
                    setState(() => _selectedMemberCount = tempCount);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
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
        centerTitle: true,
        title: const Text(
          "새 게시물 작성",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          _isUploading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF4CA1AF)),
                      ),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _uploadCommunityPost,
                  child: const Text(
                    "게시하기",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF4CA1AF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ],
      ),
      body: Column(
        children: [
          // 1. 상단 카테고리 선택 탭
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                _buildCategoryTab("게시글", "general"),
                _buildCategoryTab("동행", "companion"),
              ],
            ),
          ),

          // 2. 메인 컨텐츠 영역
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 선택된 사진 미리보기
                  if (_selectedImages.isNotEmpty) _buildImagePreview(),

                  // 동행 정보 표시 (동행 탭일 때만)
                  if (_selectedCategory == 'companion') _buildCompanionInfo(),

                  // 제목 입력
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                    decoration: const InputDecoration(
                      hintText: "제목을 입력하세요",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const Divider(
                    height: 30,
                    thickness: 1,
                    color: Color(0xFFEEEEEE),
                  ),

                  // 내용 입력
                  TextField(
                    controller: _contentController,
                    maxLines: null, // 다중 행 입력 허용
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      hintText: "내용을 입력하세요.\n(동행 모집 글 작성 시 자세한 일정과 조건을 적어주세요.)",
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 100), // 하단 메뉴 공간 확보
                ],
              ),
            ),
          ),

          // 3. 하단 메뉴 (고정)
          _buildBottomMenu(),
        ],
      ),
    );
  }

  // 카테고리 탭 버튼 위젯
  Widget _buildCategoryTab(String label, String categoryValue) {
    final bool isSelected = _selectedCategory == categoryValue;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedCategory = categoryValue;
            // 탭 변경 시 동행 정보 초기화 (선택 사항)
            // if (_selectedCategory == 'general') {
            //   _selectedLocation = null; _selectedDateRange = null; _selectedMemberCount = null;
            // }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4CA1AF) : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 이미지 미리보기 위젯
  Widget _buildImagePreview() {
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(File(_selectedImages[index])),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 15,
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedImages.removeAt(index)),
                      child: const CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 10,
                        child: Icon(Icons.close, size: 15, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // 동행 정보 표시 위젯
  Widget _buildCompanionInfo() {
    if (_selectedLocation == null &&
        _selectedDateRange == null &&
        _selectedMemberCount == null)
      return const SizedBox.shrink();

    String dateText = _selectedDateRange != null
        ? "${DateFormat('yyyy.MM.dd').format(_selectedDateRange!.start)} - ${DateFormat('yyyy.MM.dd').format(_selectedDateRange!.end)} (${_selectedDateRange!.duration.inDays + 1}일)"
        : "여행 날짜 선택";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          if (_selectedLocation != null)
            _buildInfoRow(Icons.location_on, _selectedLocation!),
          if (_selectedDateRange != null)
            _buildInfoRow(Icons.calendar_today, dateText),
          if (_selectedMemberCount != null)
            _buildInfoRow(Icons.person, "$_selectedMemberCount명 모집"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4CA1AF)),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  // 하단 메뉴 위젯
  Widget _buildBottomMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomMenuItem(Icons.image_outlined, "사진 추가", _pickImages),
          if (_selectedCategory == 'companion') ...[
            _buildBottomMenuItem(
              Icons.location_on_outlined,
              "장소 추가",
              _showLocationModal,
            ),
            _buildBottomMenuItem(
              Icons.calendar_today_outlined,
              "날짜 추가",
              _showDateModal,
            ),
            _buildBottomMenuItem(
              Icons.person_add_outlined,
              "인원 설정",
              _showMemberCountModal,
            ),
            _buildAnonymousToggle(),
          ] else ...[
            _buildBottomMenuItem(
              Icons.location_on_outlined,
              "장소 추가",
              _showLocationModal,
            ), // 게시글에도 장소 추가는 유지
          ],
        ],
      ),
    );
  }

  Widget _buildBottomMenuItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey[700]),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymousToggle() {
    return InkWell(
      onTap: () => setState(() => _isAnonymous = !_isAnonymous),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isAnonymous ? Icons.check_circle : Icons.radio_button_unchecked,
              color: _isAnonymous ? const Color(0xFF4CA1AF) : Colors.grey[700],
            ),
            const SizedBox(height: 5),
            Text(
              "익명 설정",
              style: TextStyle(
                color: _isAnonymous
                    ? const Color(0xFF4CA1AF)
                    : Colors.grey[700],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
