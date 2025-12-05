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
  List<String> _flights = []; // 비행편 리스트로 변경
  String _hotelInfo = "숙소 설정";

  List<String> _members = [];
  List<String> _supplies = [];
  List<Map<String, dynamic>> _todoList = [];

  bool _isSaving = false;

  // 전세계 주요 국가 및 도시 데이터
  final Map<String, List<String>> _countriesAndCities = {
    '대한민국': ['서울', '부산', '제주도', '인천', '대구', '광주', '대전', '울산', '수원', '창원'],
    '일본': ['도쿄', '오사카', '교토', '후쿠오카', '삿포로', '오키나와', '나고야', '요코하마', '고베', '나라'],
    '중국': ['베이징', '상하이', '광저우', '청두', '심천', '항저우', '시안', '충칭', '우한'],
    '대만': ['타이페이', '가오슝', '타이중', '타이난', '지룽'],
    '홍콩': ['홍콩'],
    '마카오': ['마카오'],
    '싱가포르': ['싱가포르'],
    '태국': ['방콕', '치앙마이', '푸껫', '파타야', '크라비', '후아힌'],
    '베트남': ['하노이', '호치민', '다낭', '나트랑', '하롱베이', '호이안'],
    '필리핀': ['마닐라', '세부', '보라카이', '팔라완', '보홀'],
    '말레이시아': ['쿠알라룸푸르', '페낭', '코타키나발루', '랑카위', '조호바루'],
    '인도네시아': ['자카르타', '발리', '족자카르타', '수라바야', '반둥'],
    '미얀마': ['양곤', '만달레이', '바간', '인레호수'],
    '캄보디아': ['프놈펜', '시엠립', '씨아누크빌'],
    '라오스': ['비엔티안', '루앙프라방', '방비엥'],
    '인도': ['델리', '뭄바이', '자이푸르', '아그라', '벵갈루루', '첸나이', '고아'],
    '네팔': ['카트만두', '포카라', '룸비니'],
    '몰디브': ['말레', '북몰리', '남몰리', '아리'],
    '스리랑카': ['콜롬보', '캔디', '갈레'],
    '미국': ['뉴욕', '로스앤젤레스', '샌프란시스코', '라스베가스', '시카고', '마이애미', '보스턴', '시애틀', '워싱턴DC', '올랜도'],
    '캐나다': ['밴쿠버', '토론토', '몬트리올', '퀘벡', '캘거리', '오타와'],
    '멕시코': ['멕시코시티', '칸쿤', '과달라하라', '몬테레이'],
    '쿠바': ['아바나', '산티아고', '바라데로'],
    '브라질': ['리우데자네이루', '상파울루', '브라질리아', '살바도르'],
    '아르헨티나': ['부에노스아이레스', '멘도사', '이과수'],
    '페루': ['리마', '쿠스코', '마추픽추'],
    '칠레': ['산티아고', '발파라이소', '푼타아레나스'],
    '영국': ['런던', '에든버러', '맨체스터', '리버풀', '옥스퍼드', '캠브리지'],
    '프랑스': ['파리', '니스', '리옹', '마르세유', '칸', '보르도', '스트라스부르'],
    '이탈리아': ['로마', '베네치아', '밀라노', '피렌체', '나폴리', '베로나', '볼로냐'],
    '스페인': ['바르셀로나', '마드리드', '세비야', '발렌시아', '그라나다', '빌바오'],
    '독일': ['베를린', '뮌헨', '프랑크푸르트', '함부르크', '쾰른', '드레스덴'],
    '네덜란드': ['암스테르담', '로테르담', '헤이그', '위트레흐트'],
    '벨기에': ['브뤼셀', '브뤼헤', '겐트', '앤트워프'],
    '스위스': ['취리히', '제네바', '루체른', '인터라켄', '베른', '로잔'],
    '오스트리아': ['비엔나', '잘츠부르크', '인스브루크', '할슈타트'],
    '체코': ['프라하', '체스키크룸로프', '브르노'],
    '헝가리': ['부다페스트', '데브레첸', '세게드'],
    '폴란드': ['바르샤바', '크라쿠프', '그단스크', '브로츠와프'],
    '그리스': ['아테네', '산토리니', '미코노스', '크레타', '테살로니키'],
    '터키': ['이스탄불', '카파도키아', '안탈리아', '이즈미르', '파묵칼레'],
    '포르투갈': ['리스본', '포르투', '파티마', '신트라'],
    '아일랜드': ['더블린', '골웨이', '코크'],
    '노르웨이': ['오슬로', '베르겐', '트롬쇠'],
    '스웨덴': ['스톡홀름', '예테보리', '말뫼'],
    '덴마크': ['코펜하겐', '오르후스', '오덴세'],
    '핀란드': ['헬싱키', '로바니에미', '탐페레'],
    '아이슬란드': ['레이캬비크', '아쿠레이리', '비크'],
    '러시아': ['모스크바', '상트페테르부르크', '블라디보스토크', '이르쿠츠크'],
    '호주': ['시드니', '멜버른', '브리즈번', '골드코스트', '퍼스', '케언즈'],
    '뉴질랜드': ['오클랜드', '웰링턴', '퀸스타운', '크라이스트처치'],
    '이집트': ['카이로', '룩소르', '아스완', '후르가다'],
    '모로코': ['마라케시', '카사블랑카', '페즈', '라바트'],
    '남아프리카공화국': ['케이프타운', '요하네스버그', '더반'],
    '케냐': ['나이로비', '몸바사', '말린디'],
    '탄자니아': ['다르에스살람', '아루샤', '잔지바르'],
    '아랍에미리트': ['두바이', '아부다비', '샤르자'],
    '사우디아라비아': ['리야드', '제다', '메카', '메디나'],
    '카타르': ['도하'],
    '요르단': ['암만', '페트라', '아카바'],
    '이스라엘': ['예루살렘', '텔아비브', '하이파'],
  };

  // 국가별 국기 이모지
  final Map<String, String> _countryFlags = {
    '대한민국': '🇰🇷', '일본': '🇯🇵', '중국': '🇨🇳', '대만': '🇹🇼', '홍콩': '🇭🇰', '마카오': '🇲🇴',
    '싱가포르': '🇸🇬', '태국': '🇹🇭', '베트남': '🇻🇳', '필리핀': '🇵🇭', '말레이시아': '🇲🇾',
    '인도네시아': '🇮🇩', '미얀마': '🇲🇲', '캄보디아': '🇰🇭', '라오스': '🇱🇦', '인도': '🇮🇳',
    '네팔': '🇳🇵', '몰디브': '🇲🇻', '스리랑카': '🇱🇰', '미국': '🇺🇸', '캐나다': '🇨🇦',
    '멕시코': '🇲🇽', '쿠바': '🇨🇺', '브라질': '🇧🇷', '아르헨티나': '🇦🇷', '페루': '🇵🇪',
    '칠레': '🇨🇱', '영국': '🇬🇧', '프랑스': '🇫🇷', '이탈리아': '🇮🇹', '스페인': '🇪🇸',
    '독일': '🇩🇪', '네덜란드': '🇳🇱', '벨기에': '🇧🇪', '스위스': '🇨🇭', '오스트리아': '🇦🇹',
    '체코': '🇨🇿', '헝가리': '🇭🇺', '폴란드': '🇵🇱', '그리스': '🇬🇷', '터키': '🇹🇷',
    '포르투갈': '🇵🇹', '아일랜드': '🇮🇪', '노르웨이': '🇳🇴', '스웨덴': '🇸🇪', '덴마크': '🇩🇰',
    '핀란드': '🇫🇮', '아이슬란드': '🇮🇸', '러시아': '🇷🇺', '호주': '🇦🇺', '뉴질랜드': '🇳🇿',
    '이집트': '🇪🇬', '모로코': '🇲🇦', '남아프리카공화국': '🇿🇦', '케냐': '🇰🇪', '탄자니아': '🇹🇿',
    '아랍에미리트': '🇦🇪', '사우디아라비아': '🇸🇦', '카타르': '🇶🇦', '요르단': '🇯🇴', '이스라엘': '🇮🇱',
  };

  @override
  void initState() {
    super.initState();
    // [수정] 전달받은 plan이 있다면(수정 모드) 초기값 설정
    if (widget.plan != null) {
      final p = widget.plan!;
      _selectedDateRange = p.date;
      _selectedCountry = p.country;
      // flightInfo가 비어있지 않으면 리스트에 추가
      if (p.flightInfo.isNotEmpty) {
        _flights = [p.flightInfo];
      }
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
        flightInfo: _flights.isNotEmpty ? _flights.join(', ') : "",
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
          padding: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 10.0,
            bottom: 80.0, // 하단 패딩 추가하여 네비게이션 바에 가려지지 않도록 함
          ),
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
                title: _flights.isEmpty
                    ? "비행편 추가"
                    : "비행편 ${_flights.length}개",
                onTap: () => _showFlightModal(context),
                isSelected: _flights.isNotEmpty,
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
                title: _supplies.isEmpty
                    ? "준비물 추가"
                    : "준비물 ${_supplies.length}개",
                onTap: () => _showSupplyModal(context),
                isSelected: _supplies.isNotEmpty,
              ),
              _buildMenuCard(
                context,
                icon: "📋",
                title: _todoList.isEmpty
                    ? "리스트 추가"
                    : "할 일 ${_todoList.length}개",
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
    String? tempCountry;
    String? tempCity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.9,
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 
                     MediaQuery.of(context).padding.bottom + 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              _buildModalHeader(context, "국가 설정"),
              const SizedBox(height: 20),
              const Text(
                "국가 및 도시 선택",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    // 국가 선택 드롭다운
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("국가 선택"),
                          value: tempCountry,
                          items: _countriesAndCities.keys.map((country) {
                            final flag = _countryFlags[country] ?? '🌍';
                            return DropdownMenuItem(
                              value: country,
                              child: Row(
                                children: [
                                  Text(
                                    flag,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(country),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              tempCountry = value;
                              tempCity = null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 도시 선택 드롭다운
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: tempCountry == null
                            ? Colors.grey.shade200
                            : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("도시 선택"),
                          value: tempCity,
                          items: tempCountry != null
                              ? _countriesAndCities[tempCountry]!.map((city) {
                                  return DropdownMenuItem(
                                    value: city,
                                    child: Text(city),
                                  );
                                }).toList()
                              : [],
                          onChanged: tempCountry != null
                              ? (value) {
                                  setModalState(() {
                                    tempCity = value;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // 선택된 국가/도시 표시
                    if (tempCountry != null && tempCity != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade700,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _countryFlags[tempCountry] ?? '🌍',
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "$tempCountry, $tempCity",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (tempCountry != null && tempCity != null)
                      ? () {
                          final flag = _countryFlags[tempCountry] ?? '🌍';
                          setState(() {
                            _selectedCountry = "$flag $tempCountry, $tempCity";
                          });
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CA1AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: const Text(
                    "이 지역으로 선택하기",
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModalHeader(context, "비행편 추가"),
                const SizedBox(height: 20),
                // 이미 추가된 비행편 리스트 표시
                if (_flights.isNotEmpty) ...[
                  const Text(
                    "추가된 비행편",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _flights.length,
                      itemBuilder: (context, i) => ListTile(
                        dense: true,
                        leading: const Icon(
                          Icons.flight_takeoff,
                          color: Color(0xFF4CA1AF),
                          size: 20,
                        ),
                        title: Text(_flights[i]),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() => _flights.removeAt(i));
                            setModalState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),
                ],
                const Text(
                  "새 비행편 추가",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      String flightInfo = dAirport;
                      if (dFlight.isNotEmpty) flightInfo += " ($dFlight)";
                      if (dTime != null) {
                        flightInfo += " 출발: ${dTime!.format(context)}";
                      }
                      if (aTime != null) {
                        flightInfo += " 도착: ${aTime!.format(context)}";
                      }
                      setState(() => _flights.add(flightInfo));
                      setModalState(() {
                        dAirport = "";
                        dFlight = "";
                        dTime = null;
                        aTime = null;
                      });
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 
                   MediaQuery.of(context).padding.bottom + 20,
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
            bottom: MediaQuery.of(context).viewInsets.bottom + 
                   MediaQuery.of(context).padding.bottom + 20,
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
}
