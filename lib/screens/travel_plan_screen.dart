import 'package:flutter/material.dart';
import 'travel_plan_setup_screen.dart';
import '../models/travel_plan_model.dart'; // 모델 import

class TravelPlanScreen extends StatefulWidget {
  const TravelPlanScreen({super.key});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  // 여행 계획 목록을 저장할 리스트
  final List<TravelPlan> _myPlans = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        title: const Text(
          "여행 계획",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.black,
              size: 26,
            ),
            onPressed: () async {
              // [중요] 설정 화면으로 이동하고, 돌아올 때 데이터(result)를 기다림
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TravelPlanSetupScreen(),
                ),
              );

              // 받아온 데이터가 있다면 리스트에 추가
              if (result != null && result is TravelPlan) {
                setState(() {
                  _myPlans.add(result);
                });
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      // 계획이 없으면 빈 화면, 있으면 리스트 화면
      body: _myPlans.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "아직 나의 여행 계획이 없어요",
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "계획을 추가해 보세요!",
                    style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myPlans.length,
              itemBuilder: (context, index) {
                final plan = _myPlans[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 둥근 이미지 (국가별 이미지 or 지도 아이콘)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          color: Color(0xFF4CA1AF),
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              plan.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${plan.date}  |  ${plan.country}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
