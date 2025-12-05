import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../services/firestore_service.dart'; // Firestore 서비스 import
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/travel_plan_model.dart';
import 'select_travel_plan_screen.dart';
import 'travel_plan_detail_screen.dart';

class CommunityWriteScreen extends StatefulWidget {
  final bool isEdit; // 수정 모드 여부
  final String? postId; // 수정할 게시물 ID
  final Map<String, dynamic>? initialData; // 초기 데이터

  const CommunityWriteScreen({
    super.key,
    this.isEdit = false,
    this.postId,
    this.initialData,
  });

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
  TravelPlan? _selectedTravelPlan; // 선택된 여행 계획

  @override
  void initState() {
    super.initState();
    // 수정 모드일 경우 초기 데이터 로드
    if (widget.isEdit && widget.initialData != null) {
      _loadInitialData();
    }
  }

  void _loadInitialData() {
    final data = widget.initialData!;
    _titleController.text = data['title'] ?? '';
    _contentController.text = data['content'] ?? '';
    _selectedCategory = data['category'] ?? 'general';
    _selectedLocation = data['location'];

    // 이미지 URL 로드
    if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
      _selectedImages = [data['imageUrl']];
    } else if (data['imageUrls'] != null) {
      _selectedImages = List<String>.from(data['imageUrls']);
    }

    // 동행글 데이터 로드
    if (_selectedCategory == 'companion') {
      if (data['memberCount'] != null) {
        _selectedMemberCount = data['memberCount'];
      }
      // 날짜 범위는 저장된 형식에 따라 파싱 필요
    }

    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // 게시하기/수정하기 버튼 클릭 시 실행
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
      if (widget.isEdit) {
        // 수정 모드
        await _updatePost();
      } else {
        // 등록 모드
        await _createPost();
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // 새 게시물 등록
  Future<void> _createPost() async {
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
        travelPlanId: _selectedTravelPlan?.id,
        travelPlanTitle: _selectedTravelPlan?.title,
        travelPlanDate: _selectedTravelPlan?.date,
        travelPlanCountry: _selectedTravelPlan?.country,
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
    }
  }

  // 게시물 수정
  Future<void> _updatePost() async {
    if (widget.postId == null) return;

    try {
      // Firestore 업데이트
      final updateData = {
        'title': _titleController.text.trim(),
        'content': _contentController.text.trim(),
        'category': _selectedCategory,
        'location': _selectedLocation ?? '',
        'updatedAt': Timestamp.now(),
      };

      // 동행글인 경우 추가 필드
      if (_selectedCategory == 'companion') {
        if (_selectedMemberCount != null) {
          updateData['memberCount'] = _selectedMemberCount!;
        }
        if (_selectedDateRange != null) {
          updateData['startDate'] = Timestamp.fromDate(
            _selectedDateRange!.start,
          );
          updateData['endDate'] = Timestamp.fromDate(_selectedDateRange!.end);
        }
      }

      // 이미지 처리 (기존 이미지 URL은 그대로 유지, 새 이미지는 업로드 필요)
      if (_selectedImages.isNotEmpty) {
        // 첫 번째 이미지가 URL이 아니라 로컬 경로인 경우 업로드 필요
        // 여기서는 간단히 URL 리스트로 저장
        updateData['imageUrls'] = _selectedImages;
        updateData['imageUrl'] = _selectedImages.first;
      }

      // 여행 계획 정보 저장
      if (_selectedTravelPlan != null) {
        updateData['travelPlanId'] = _selectedTravelPlan!.id;
        updateData['travelPlanTitle'] = _selectedTravelPlan!.title;
        updateData['travelPlanDate'] = _selectedTravelPlan!.date;
        updateData['travelPlanCountry'] = _selectedTravelPlan!.country;
      }

      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .update(updateData);

      if (!mounted) return;
      Navigator.pop(context, true); // 수정 완료 신호와 함께 돌아가기
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시글이 수정되었습니다.")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("수정 실패: $e")));
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

  // 여행 계획 선택
  void _selectTravelPlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SelectTravelPlanScreen(),
      ),
    );

    if (result != null && result is TravelPlan) {
      setState(() {
        _selectedTravelPlan = result;
      });
    }
  }

  // 여행 계획 배너 표시
  void _showTravelPlanBanner() async {
    if (_selectedTravelPlan == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '여행 계획',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TravelPlanDetailScreen(plan: _selectedTravelPlan!),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.flight_takeoff,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedTravelPlan!.title,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTravelPlan!.country,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTravelPlan!.date,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.blue[200]!.withOpacity(0.3),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(11),
                          bottomRight: Radius.circular(11),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app, size: 16, color: Colors.blue[700]),
                          const SizedBox(width: 6),
                          Text(
                            '탭하여 여행 계획 보기',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
        title: Text(
          widget.isEdit ? "게시물 수정" : "새 게시물 작성",
          style: const TextStyle(
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
                  child: Text(
                    widget.isEdit ? "수정하기" : "게시하기",
                    style: const TextStyle(
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

                  // 여행 계획 배너 표시
                  if (_selectedTravelPlan != null) _buildTravelPlanBanner(),

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
              final imagePath = _selectedImages[index];
              final isNetworkImage =
                  imagePath.startsWith('http://') ||
                  imagePath.startsWith('https://');

              return Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.only(right: 10),
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: isNetworkImage
                            ? NetworkImage(imagePath) as ImageProvider
                            : FileImage(File(imagePath)),
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

  // 여행 계획 배너 위젯
  Widget _buildTravelPlanBanner() {
    return GestureDetector(
      onTap: _showTravelPlanBanner,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.blue[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTravelPlan!.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () {
                          setState(() {
                            _selectedTravelPlan = null;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTravelPlan!.country,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedTravelPlan!.date,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue[200]!.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(11),
                  bottomRight: Radius.circular(11),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 6),
                  Text(
                    '탭하여 여행 계획 상세보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 10,
        bottom: 10 + MediaQuery.of(context).padding.bottom, // 안드로이드 네비게이션바 고려
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomMenuItem(Icons.image_outlined, "사진 추가", _pickImages),
          _buildBottomMenuItem(
            Icons.flight_takeoff_outlined,
            "여행 계획",
            _selectTravelPlan,
          ),
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
}
