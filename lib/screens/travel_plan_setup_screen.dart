import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../models/travel_plan_model.dart';
import 'friend_list_screen.dart';
import '../services/firestore_service.dart';

class TravelPlanSetupScreen extends StatefulWidget {
  // [수정] 수정할 계획 데이터를 받을 수 있도록 파라미터 추가
  final TravelPlan? plan;

  const TravelPlanSetupScreen({super.key, this.plan});

  @override
  State<TravelPlanSetupScreen> createState() => _TravelPlanSetupScreenState();
}

class _TravelPlanSetupScreenState extends State<TravelPlanSetupScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 데이터 상태
  String _selectedDateRange = "날짜 설정";
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCountry = "국가 설정";
  String _flightInfo = "비행편 설정";
  String _hotelInfo = "숙소 설정";

  List<String> _members = [];
  List<String> _supplies = [];
  List<Map<String, dynamic>> _todoList = [];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // [수정] 전달받은 plan이 있다면(수정 모드) 초기값 설정
    if (widget.plan != null) {
      final p = widget.plan!;
      _selectedDateRange = p.date;
      _selectedCountry = p.country;
      _flightInfo = p.flightInfo.isNotEmpty ? p.flightInfo : "비행편 설정";
      _hotelInfo = p.hotelInfo.isNotEmpty ? p.hotelInfo : "숙소 설정";
      _members = List.from(p.members);
      _supplies = List.from(p.supplies);
      _todoList = List.from(p.todoList);
    }
  }

  // 저장 로직
  void _saveTravelPlan() async {
    if (_selectedDateRange == "날짜 설정" || _selectedCountry == "국가 설정") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("날짜와 국가는 필수입니다!")));
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 기존 ID가 있으면(수정) 그대로 사용, 없으면(생성) 빈값
      final newPlan = TravelPlan(
        id: widget.plan?.id ?? '',
        uid: widget.plan?.uid ?? '',
        title: "$_selectedCountry 여행",
        date: _selectedDateRange,
        country: _selectedCountry,
        flightInfo: _flightInfo != "비행편 설정" ? _flightInfo : "",
        hotelInfo: _hotelInfo != "숙소 설정" ? _hotelInfo : "",
        members: _members,
        supplies: _supplies,
        todoList: _todoList,
        createdAt: widget.plan?.createdAt, // 수정 시 기존 시간 유지
      );

      if (widget.plan == null) {
        // 신규 저장
        await _firestoreService.addTravelPlan(newPlan);
      } else {
        // 수정 업데이트
        await _firestoreService.updateTravelPlan(newPlan);
      }

      if (!mounted) return;
      Navigator.pop(context); // 화면 닫기
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.plan == null ? "여행 계획이 저장되었습니다!" : "여행 계획이 수정되었습니다!",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("저장 실패: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
        centerTitle: true,
        title: Text(
          widget.plan == null ? "여행 계획" : "계획 수정", // 타이틀 변경
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          _isSaving
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _saveTravelPlan,
                  child: const Text(
                    "완료",
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
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildMenuCard(
              context,
              icon: "📅",
              title: _selectedDateRange,
              onTap: () => _showDateModal(context),
              isSelected: _selectedDateRange != "날짜 설정",
            ),
            _buildMenuCard(
              context,
              icon: "🌍",
              title: _selectedCountry,
              onTap: () => _showCountryModal(context),
              isSelected: _selectedCountry != "국가 설정",
            ),
            _buildMenuCard(
              context,
              icon: "✈️",
              title: _flightInfo,
              onTap: () => _showFlightModal(context),
              isSelected: _flightInfo != "비행편 설정",
            ),
            _buildMenuCard(
              context,
              icon: "🏠",
              title: _hotelInfo,
              onTap: () => _showHotelModal(context),
              isSelected: _hotelInfo != "숙소 설정",
            ),
            _buildMenuCard(
              context,
              icon: "👥",
              title: _members.isEmpty ? "인원 추가" : "인원 ${_members.length}명",
              onTap: () => _showMemberModal(context),
              isSelected: _members.isNotEmpty,
            ),
            _buildMenuCard(
              context,
              icon: "🧳",
              title: _supplies.isEmpty ? "준비물 추가" : "준비물 ${_supplies.length}개",
              onTap: () => _showSupplyModal(context),
              isSelected: _supplies.isNotEmpty,
            ),
            _buildMenuCard(
              context,
              icon: "📋",
              title: _todoList.isEmpty ? "리스트 추가" : "할 일 ${_todoList.length}개",
              onTap: () => _showListModal(context),
              isSelected: _todoList.isNotEmpty,
            ),
            const SizedBox(height: 30),
          ],
        ),
        ),
      ),
    );
  }

  // --- (기존 UI 코드 유지: _buildMenuCard 및 모달 함수들) ---
  // 편의상 아래 코드는 기존과 동일하므로 생략하지 않고 필요한 부분만 포함시킵니다.

  Widget _buildMenuCard(
    BuildContext context, {
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CA1AF) : Colors.grey.shade100,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 30),
            Expanded(
              child: Center(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }

  // 모달 함수들 (내용은 기존과 동일)
  void _showDateModal(BuildContext context) {
    DateTime focusedDay = _startDate ?? DateTime.now();
    DateTime? tempStart = _startDate;
    DateTime? tempEnd = _endDate;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildModalHeader(context, "날짜 설정"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildDateDisplayBox(
                      "출발",
                      tempStart,
                      Icons.flight_takeoff,
                      isActive: tempStart != null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildDateDisplayBox(
                      "도착",
                      tempEnd,
                      Icons.flight_land,
                      isActive: tempEnd != null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              Expanded(
                child: TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: focusedDay,
                  rangeSelectionMode: RangeSelectionMode.toggledOn,
                  rangeStartDay: tempStart,
                  rangeEndDay: tempEnd,
                  headerStyle: const HeaderStyle(
                    titleCentered: true,
                    formatButtonVisible: false,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: const CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Color(0xFF81C784),
                      shape: BoxShape.circle,
                    ),
                    rangeStartDecoration: BoxDecoration(
                      color: Color(0xFF4CA1AF),
                      shape: BoxShape.circle,
                    ),
                    rangeEndDecoration: BoxDecoration(
                      color: Color(0xFFE57373),
                      shape: BoxShape.circle,
                    ),
                    rangeHighlightColor: Color(0xFFE0F2F1),
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setModalState(() {
                      if (tempStart != null && tempEnd != null) {
                        tempStart = selectedDay;
                        tempEnd = null;
                      } else if (tempStart == null) {
                        tempStart = selectedDay;
                      } else {
                        if (selectedDay.isBefore(tempStart!)) {
                          tempStart = selectedDay;
                        } else {
                          tempEnd = selectedDay;
                        }
                      }
                    });
                  },
                  onPageChanged: (focused) => focusedDay = focused,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (tempStart != null && tempEnd != null)
                      ? () {
                          setState(() {
                            _startDate = tempStart;
                            _endDate = tempEnd;
                            int nights = tempEnd!.difference(tempStart!).inDays;
                            _selectedDateRange =
                                "${DateFormat('MM.dd').format(tempStart!)} - ${DateFormat('MM.dd').format(tempEnd!)} (${nights}박 ${nights + 1}일)";
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA1AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "이 날짜로 선택하기",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

  void _showCountryModal(BuildContext context) {
    /* 기존 코드 복사 */
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalHeader(context, "국가 설정"),
            const SizedBox(height: 20),
            _buildInputBox("여기서 검색", icon: Icons.search),
            const SizedBox(height: 24),
            const Text(
              "지도로 찾기",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.map, size: 50, color: Colors.black26),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "빠른 지역 찾기",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCountryCard(context, "🇺🇸", "미국", "뉴욕"),
                  _buildCountryCard(context, "🇮🇹", "이탈리아", "로마"),
                  _buildCountryCard(context, "🇵🇹", "포르투갈", "리스본"),
                  _buildCountryCard(context, "🇯🇵", "일본", "오사카"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            Expanded(
              child: ListView(
                children: [
                  _buildListTile(context, "🇫🇷", "프랑스", "파리"),
                  _buildListTile(context, "🇬🇧", "영국", "런던"),
                  _buildListTile(context, "🇪🇸", "스페인", "바르셀로나"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFlightModal(BuildContext context) {
    /* 기존 코드 복사 */
    String dAirport = "", dFlight = "";
    TimeOfDay? dTime, aTime;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalHeader(context, "비행편 설정"),
                const SizedBox(height: 20),
                const Text(
                  "출발편",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildTextInputBox("공항명", (v) => dAirport = v),
                const SizedBox(height: 10),
                _buildTextInputBox("항공편 번호", (v) => dFlight = v),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setModalState(() => dTime = t);
                  },
                  child: _buildTimeSelectBox(dTime, "출발 시간"),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (t != null) setModalState(() => aTime = t);
                  },
                  child: _buildTimeSelectBox(aTime, "도착 시간"),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () {
                    if (dAirport.isNotEmpty) {
                      setState(() => _flightInfo = "$dAirport ($dFlight)");
                      Navigator.pop(context);
                    }
                  },
                  child: _buildAddButton(),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHotelModal(BuildContext context) {
    /* 기존 코드 복사 */
    String hName = "";
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalHeader(context, "숙소 설정"),
                const SizedBox(height: 20),
                const Text("1.", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildTextInputBox("숙소명", (v) => hName = v),
                const SizedBox(height: 30),
                const Text(
                  "숙소 추가하기",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    if (hName.isNotEmpty) {
                      setState(() => _hotelInfo = hName);
                      Navigator.pop(context);
                    }
                  },
                  child: _buildAddButton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMemberModal(BuildContext context) {
    /* 기존 코드 복사 */
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: 500,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModalHeader(context, "인원 추가"),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const FriendListScreen(isSelectionMode: true),
                    ),
                  );
                  if (result != null && result is List<String>) {
                    setState(() {
                      for (var name in result) {
                        if (!_members.contains(name)) _members.add(name);
                      }
                    });
                    setModalState(() {});
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, size: 18, color: Colors.black54),
                      SizedBox(width: 10),
                      Text(
                        "친구 목록에서 선택하기",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _members.isEmpty
                    ? const Center(
                        child: Text(
                          "추가된 인원이 없습니다.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _members.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 20,
                            ),
                            radius: 16,
                          ),
                          title: Text(
                            _members[index],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.remove_circle_outline,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() => _members.removeAt(index));
                              setModalState(() {});
                            },
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

  void _showSupplyModal(BuildContext context) {
    /* 기존 코드 복사 */
    String temp = "";
    TextEditingController c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalHeader(context, "준비물 추가"),
              const SizedBox(height: 20),
              _buildTextInputBox("준비물", (v) => temp = v, controller: c),
              const SizedBox(height: 20),
              if (_supplies.isNotEmpty) ...[
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _supplies.length,
                    itemBuilder: (context, i) => ListTile(
                      dense: true,
                      leading: const Icon(
                        Icons.check_circle,
                        color: Color(0xFF4CA1AF),
                        size: 20,
                      ),
                      title: Text(_supplies[i]),
                      trailing: GestureDetector(
                        onTap: () {
                          setState(() => _supplies.removeAt(i));
                          setModalState(() {});
                        },
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (temp.isNotEmpty) {
                    setState(() => _supplies.add(temp));
                    setModalState(() {
                      temp = "";
                      c.clear();
                    });
                  }
                },
                child: _buildAddButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showListModal(BuildContext context) {
    /* 기존 코드 복사 */
    String temp = "";
    TextEditingController c = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModalHeader(context, "리스트 추가"),
              const SizedBox(height: 20),
              _buildTextInputBox("할 일 입력", (v) => temp = v, controller: c),
              const SizedBox(height: 20),
              if (_todoList.isNotEmpty) ...[
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _todoList.length,
                    itemBuilder: (context, i) {
                      final item = _todoList[i];
                      final isChecked = item['isChecked'] as bool;
                      return ListTile(
                        dense: true,
                        onTap: () {
                          setState(
                            () => _todoList[i]['isChecked'] = !isChecked,
                          );
                          setModalState(() {});
                        },
                        leading: Icon(
                          isChecked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          color: isChecked
                              ? const Color(0xFF4CA1AF)
                              : Colors.grey,
                          size: 24,
                        ),
                        title: Text(
                          item['title'],
                          style: TextStyle(
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: isChecked ? Colors.grey : Colors.black,
                          ),
                        ),
                        trailing: GestureDetector(
                          onTap: () {
                            setState(() => _todoList.removeAt(i));
                            setModalState(() {});
                          },
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  if (temp.isNotEmpty) {
                    setState(
                      () => _todoList.add({'title': temp, 'isChecked': false}),
                    );
                    setModalState(() {
                      temp = "";
                      c.clear();
                    });
                  }
                },
                child: _buildAddButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 헬퍼 위젯들
  Widget _buildModalHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(width: 24),
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

  Widget _buildAddButton() {
    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CA1AF), Color(0xFF81C784)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.add_circle_outline, color: Colors.white),
    );
  }

  Widget _buildTextInputBox(
    String hint,
    Function(String) onChanged, {
    TextEditingController? controller,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildInputBox(String hint, {IconData? icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.black54),
            const SizedBox(width: 10),
          ],
          Text(hint, style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildTimeSelectBox(TimeOfDay? time, String hint) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        time != null ? time.format(context) : hint,
        style: TextStyle(
          color: time != null ? Colors.black : Colors.grey[600],
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildDateDisplayBox(
    String label,
    DateTime? date,
    IconData icon, {
    bool isActive = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xFF4CA1AF) : Colors.transparent,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? const Color(0xFF2E7D32) : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            date != null
                ? DateFormat('MM.dd (E)', 'ko_KR').format(date)
                : "날짜 선택",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.black : Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountryCard(
    BuildContext context,
    String flag,
    String country,
    String city,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCountry = "$country, $city");
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(flag, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              country,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              city,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String flag,
    String country,
    String city,
  ) {
    return ListTile(
      leading: Text(flag, style: const TextStyle(fontSize: 24)),
      title: Text(country),
      subtitle: Text(city),
      onTap: () {
        setState(() => _selectedCountry = "$country, $city");
        Navigator.pop(context);
      },
    );
  }
}
