import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 갤러리 연동
import 'dart:io'; // 파일 처리
import 'package:table_calendar/table_calendar.dart'; // 달력
import 'package:intl/intl.dart'; // 날짜 포맷
// import 'community_screen.dart'; // 로컬 모델은 이제 필요 없으므로 주석 처리 (DB 직접 저장)
import 'package:firebase_storage/firebase_storage.dart'; // 스토리지
import 'package:cloud_firestore/cloud_firestore.dart'; // DB
import 'package:firebase_auth/firebase_auth.dart'; // 인증

class CommunityWriteScreen extends StatefulWidget {
  const CommunityWriteScreen({super.key});

  @override
  State<CommunityWriteScreen> createState() => _CommunityWriteScreenState();
}

class _CommunityWriteScreenState extends State<CommunityWriteScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  // 데이터 상태 변수들
  bool _isAnonymous = false;
  List<String> _selectedImages = []; // 선택된 사진 경로 리스트 (로컬)
  String? _selectedLocation; // 선택된 장소
  DateTime? _selectedDate; // 선택된 날짜
  List<String> _selectedMembers = []; // 선택된 인원 이름 리스트
  bool _isUploading = false; // 업로드 중 상태 확인

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ★ [핵심] Firebase에 커뮤니티 글 업로드
  Future<void> _uploadCommunityPost() async {
    // 1. 유효성 검사
    if (_titleController.text.trim().isEmpty ||
        _contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("제목과 내용을 입력해주세요.")));
      return;
    }

    setState(() {
      _isUploading = true; // 로딩 시작
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
        return;
      }

      // 2. [Storage] 이미지 여러 장 업로드
      List<String> downloadUrls = [];

      if (_selectedImages.isNotEmpty) {
        for (int i = 0; i < _selectedImages.length; i++) {
          File imageFile = File(_selectedImages[i]);
          // 파일명: community_images/시간_유저ID_순서.jpg
          String fileName =
              '${DateTime.now().millisecondsSinceEpoch}_${user.uid}_$i.jpg';
          Reference ref = FirebaseStorage.instance.ref().child(
            'community_images/$fileName',
          );

          await ref.putFile(imageFile); // 업로드
          String url = await ref.getDownloadURL(); // URL 받기
          downloadUrls.add(url);
        }
      }

      // 3. [Firestore] DB에 저장
      // 커뮤니티 글은 'community_posts' 라는 별도 컬렉션에 저장합니다.
      await FirebaseFirestore.instance.collection('community_posts').add({
        'uid': user.uid, // 작성자 ID
        'writerName': _isAnonymous
            ? "익명"
            : (user.displayName ?? "알 수 없음"), // 작성자 표시 이름
        'isAnonymous': _isAnonymous, // 익명 여부
        'title': _titleController.text.trim(), // 제목
        'content': _contentController.text.trim(), // 내용
        'location': _selectedLocation ?? "", // 장소
        'tripDate': _selectedDate != null
            ? Timestamp.fromDate(_selectedDate!)
            : null, // 여행 날짜
        'members': _selectedMembers, // 함께한 멤버 리스트
        'imageUrls': downloadUrls, // 업로드된 이미지 URL 리스트
        'likeCount': 0, // 좋아요 수 초기화
        'commentCount': 0, // 댓글 수 초기화
        'viewCount': 0, // 조회수 초기화
        'createdAt': FieldValue.serverTimestamp(), // 작성 시간
        'category': 'general', // 카테고리 (필요시 확장)
      });

      // 4. 성공 처리
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("게시글이 등록되었습니다!")));
      Navigator.pop(context); // 목록 화면으로 돌아가기
    } catch (e) {
      print("업로드 에러: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("업로드 중 오류가 발생했습니다.")));
    } finally {
      setState(() {
        _isUploading = false; // 로딩 끝
      });
    }
  }

  // 1. 갤러리에서 사진 가져오기
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var img in images) {
            _selectedImages.add(img.path);
          }
        });
      }
    } catch (e) {
      print("Error picking images: $e");
    }
  }

  // 2. 장소 선택 모달
  void _showLocationModal() {
    String tempLocation = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalHeader("여행 장소 추가"),
            const SizedBox(height: 20),
            // 검색창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                onChanged: (val) => tempLocation = val,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: "장소 검색 (예: 에펠탑)",
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // 지도 이미지 (더미)
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map, size: 80, color: Colors.black12),
                      Text(
                        "지도에서 위치 선택",
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (tempLocation.isNotEmpty) {
                    setState(() => _selectedLocation = tempLocation);
                  } else {
                    setState(() => _selectedLocation = "선택된 지도 위치"); // 기본값
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CA1AF),
                ),
                child: const Text(
                  "이 장소 선택",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 날짜 선택 모달 (달력)
  void _showDateModal() {
    DateTime focusedDay = _selectedDate ?? DateTime.now();
    DateTime? selectedDay = _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildModalHeader("여행 날짜 선택"),
              const SizedBox(height: 20),
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: (selected, focused) {
                  setModalState(() {
                    selectedDay = selected;
                    focusedDay = focused;
                  });
                },
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: const CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color: Color(0xFF4CA1AF),
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Color(0xFF81C784),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: selectedDay != null
                      ? () {
                          setState(() => _selectedDate = selectedDay);
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA1AF),
                  ),
                  child: const Text(
                    "날짜 적용",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. 인원 설정 모달
  void _showMembersModal() {
    final List<String> friends = [
      "김찬희",
      "이경환",
      "안해진",
      "박지성",
      "손흥민",
      "아이유",
      "유재석",
      "강호동",
      "이수근",
    ];
    List<String> tempSelected = List.from(_selectedMembers);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModalHeader("함께할 인원 선택"),
              const SizedBox(height: 10),
              Text(
                "선택됨: ${tempSelected.length}명",
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final name = friends[index];
                    final isSelected = tempSelected.contains(name);
                    return CheckboxListTile(
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      secondary: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      value: isSelected,
                      activeColor: const Color(0xFF4CA1AF),
                      onChanged: (val) {
                        setModalState(() {
                          if (val == true) {
                            tempSelected.add(name);
                          } else {
                            tempSelected.remove(name);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() => _selectedMembers = tempSelected);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA1AF),
                  ),
                  child: const Text(
                    "완료",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
          "동행 새 게시물",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // 게시하기 버튼 (로딩 중에는 뺑뺑이)
          TextButton(
            onPressed: _isUploading ? null : _uploadCommunityPost,
            child: _isUploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    "게시하기",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // [1] 선택된 사진 미리보기 (가로 스크롤)
                  if (_selectedImages.isNotEmpty) ...[
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
                                    image: FileImage(
                                      File(_selectedImages[index]),
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 15,
                                top: 5,
                                child: GestureDetector(
                                  onTap: () => setState(
                                    () => _selectedImages.removeAt(index),
                                  ),
                                  child: const CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.black54,
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
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

                  // [2] 선택된 정보 칩(Chip) 표시 영역
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      // 장소 칩
                      if (_selectedLocation != null)
                        Chip(
                          label: Text(_selectedLocation!),
                          avatar: const Icon(
                            Icons.place,
                            size: 16,
                            color: Colors.blue,
                          ),
                          backgroundColor: Colors.blue[50],
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _selectedLocation = null),
                        ),
                      // 날짜 칩
                      if (_selectedDate != null)
                        Chip(
                          label: Text(
                            DateFormat('yyyy.MM.dd').format(_selectedDate!),
                          ),
                          avatar: const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.green,
                          ),
                          backgroundColor: Colors.green[50],
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () => setState(() => _selectedDate = null),
                        ),
                      // 인원 칩 (개별 표시)
                      ..._selectedMembers.map(
                        (member) => Chip(
                          label: Text(member),
                          avatar: const Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.orange,
                          ),
                          backgroundColor: Colors.orange[50],
                          deleteIcon: const Icon(Icons.close, size: 14),
                          onDeleted: () =>
                              setState(() => _selectedMembers.remove(member)),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedLocation != null ||
                      _selectedDate != null ||
                      _selectedMembers.isNotEmpty)
                    const SizedBox(height: 20),

                  // [3] 제목 입력
                  const Text(
                    "제목",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: "제목을 입력하세요",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                    ),
                    maxLength: 30,
                  ),
                  const SizedBox(height: 10),

                  // [4] 내용 입력
                  const Text(
                    "내용",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextField(
                    controller: _contentController,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      hintText: "여행의 즐거운 순간을 기록해보세요.",
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      border: InputBorder.none,
                    ),
                    maxLength: 1000,
                  ),
                ],
              ),
            ),
          ),

          // [5] 하단 메뉴 영역
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  Icons.image_outlined,
                  "사진 추가",
                  onTap: _pickImages,
                ),
                _buildMenuItem(
                  Icons.location_on_outlined,
                  "여행 장소 추가",
                  onTap: _showLocationModal,
                ),
                _buildMenuItem(
                  Icons.calendar_today_outlined,
                  "여행 날짜 추가",
                  onTap: _showDateModal,
                ),
                _buildMenuItem(
                  Icons.people_outline,
                  "인원 설정",
                  onTap: _showMembersModal,
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility_off_outlined,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        "익명 설정",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _isAnonymous,
                        onChanged: (val) => setState(() => _isAnonymous = val),
                        activeColor: const Color(0xFF4CA1AF),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModalHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
