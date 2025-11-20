class TravelPlan {
  final String title; // 여행 제목 (예: "즐거운 파리 여행")
  final String date; // 날짜 (예: "01.12 - 01.16")
  final String country; // 국가 (예: "프랑스")
  // 필요한 다른 필드들도 나중에 추가 가능 (숙소, 비행편 등)

  TravelPlan({required this.title, required this.date, required this.country});
}
