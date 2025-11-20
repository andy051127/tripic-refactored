import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart'; // 달력 패키지
import 'package:intl/intl.dart'; // 날짜 포맷팅
import '../models/travel_plan_model.dart'; // 데이터 모델
import 'friend_list_screen.dart'; // 친구 목록 화면 연결

class TravelPlanSetupScreen extends StatefulWidget {
  const TravelPlanSetupScreen({super.key});

  @override
  State<TravelPlanSetupScreen> createState() => _TravelPlanSetupScreenState();
}

class _TravelPlanSetupScreenState extends State<TravelPlanSetupScreen> {
  // 1. 날짜/국가 데이터
  String _selectedDateRange = "날짜 설정";
  DateTime? _startDate;
  DateTime? _endDate;
  String _selectedCountry = "국가 설정";

  // 2. 부가 정보 데이터
  String _flightInfo = "비행편 설정";
  String _hotelInfo = "숙소 설정";

  // 3. 리스트형 데이터
  final List<String> _members = []; // 인원 리스트 (이름만 저장)
  final List<String> _supplies = []; // 준비물 리스트

  // [수정됨] 할 일 리스트를 Map 형태로 변경하여 체크 상태 저장
  // 예: {'title': '환전하기', 'isChecked': false}
  final List<Map<String, dynamic>> _todoList = [];

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
          "여행 계획",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              if (_selectedDateRange == "날짜 설정" ||
                  _selectedCountry == "국가 설정") {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("날짜와 국가는 필수입니다!")));
                return;
              }

              final newPlan = TravelPlan(
                title: "$_selectedCountry 여행",
                date: _selectedDateRange,
                country: _selectedCountry,
              );

              Navigator.pop(context, newPlan);
            },
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
      body: SingleChildScrollView(
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
            // [수정됨] 리스트 개수 표시
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
    );
  }

  // ==================================================================
  // [5] 인원 추가 모달 (친구 목록 연동 수정)
  // ==================================================================
  void _showMemberModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
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

                  // 친구 검색/추가 버튼
                  GestureDetector(
                    onTap: () async {
                      // 친구 목록 화면으로 이동
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendListScreen(),
                        ),
                      );

                      // [수정됨] 받아온 데이터 처리 (Map이든 String이든 처리)
                      if (result != null) {
                        String friendName = "";
                        if (result is Map) {
                          friendName = result['name'] ?? ""; // Map에서 이름 추출
                        } else if (result is String) {
                          friendName = result;
                        }

                        if (friendName.isNotEmpty &&
                            !_members.contains(friendName)) {
                          setState(() {
                            _members.add(friendName);
                          });
                          setModalState(() {}); // 모달 갱신
                        }
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
                  const Text(
                    "추가된 인원",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

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
                            itemBuilder: (context, index) {
                              return ListTile(
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle_outline,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _members.removeAt(index);
                                    });
                                    setModalState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),

                  const SizedBox(height: 10),
                  const Text(
                    "인원 추가하기",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  // 하단 + 버튼 (친구 목록 이동)
                  GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FriendListScreen(),
                        ),
                      );
                      // [수정됨] 동일한 데이터 처리 로직
                      if (result != null) {
                        String friendName = "";
                        if (result is Map)
                          friendName = result['name'] ?? "";
                        else if (result is String)
                          friendName = result;

                        if (friendName.isNotEmpty &&
                            !_members.contains(friendName)) {
                          setState(() => _members.add(friendName));
                          setModalState(() {});
                        }
                      }
                    },
                    child: _buildAddButton(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================================================================
  // [6] 준비물 추가 모달
  // ==================================================================
  void _showSupplyModal(BuildContext context) {
    String tempSupply = "";
    final TextEditingController _controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModalHeader(context, "준비물 추가"),
                  const SizedBox(height: 20),
                  _buildTextInputBox(
                    "준비물 (예: 여권)",
                    (val) => tempSupply = val,
                    controller: _controller,
                  ),
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
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.check_circle,
                              color: Color(0xFF4CA1AF),
                              size: 20,
                            ),
                            title: Text(_supplies[index]),
                            trailing: GestureDetector(
                              onTap: () {
                                setState(() => _supplies.removeAt(index));
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
                    const SizedBox(height: 20),
                  ],
                  const Text(
                    "준비물 추가하기",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (tempSupply.isNotEmpty) {
                        setState(() => _supplies.add(tempSupply));
                        setModalState(() {
                          tempSupply = "";
                          _controller.clear();
                        });
                      }
                    },
                    child: _buildAddButton(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==================================================================
  // [7] 리스트 추가 모달 (체크박스 기능 구현)
  // ==================================================================
  void _showListModal(BuildContext context) {
    String tempList = "";
    final TextEditingController _controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalHeader(context, "리스트 추가"),
                const SizedBox(height: 20),

                _buildTextInputBox(
                  "할 일 입력 (예: 맛집 예약)",
                  (val) => tempList = val,
                  controller: _controller,
                ),

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
                      itemBuilder: (context, index) {
                        final item = _todoList[index];
                        final isChecked = item['isChecked'] as bool;

                        return ListTile(
                          dense: true,
                          // [수정됨] 클릭 시 체크박스 토글 기능
                          onTap: () {
                            setState(() {
                              _todoList[index]['isChecked'] = !isChecked;
                            });
                            setModalState(() {}); // 모달 화면 즉시 갱신
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
                              // 체크되면 취소선 긋기
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isChecked ? Colors.grey : Colors.black,
                            ),
                          ),
                          trailing: GestureDetector(
                            onTap: () {
                              setState(() => _todoList.removeAt(index));
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
                  const SizedBox(height: 20),
                ],

                const Text(
                  "리스트 추가하기",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    if (tempList.isNotEmpty) {
                      // [수정됨] 체크 상태를 포함한 Map으로 추가
                      setState(() {
                        _todoList.add({'title': tempList, 'isChecked': false});
                      });
                      setModalState(() {
                        tempList = "";
                        _controller.clear();
                      });
                    }
                  },
                  child: _buildAddButton(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- 기존 기능들 (날짜, 국가, 비행편, 숙소 등) ---
  // (코드가 너무 길어지지 않게 기존 로직을 그대로 유지합니다. 위쪽 코드와 합쳐져서 작동합니다.)

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

  // --- 공통 UI ---
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
