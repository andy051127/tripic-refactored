import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'travel_plan_setup_screen.dart';
import 'travel_plan_detail_screen.dart'; // [신규] 상세 화면 import
import 'translator_screen.dart';
import '../models/travel_plan_model.dart';
import '../services/firestore_service.dart';

class TravelPlanScreen extends StatefulWidget {
  const TravelPlanScreen({super.key});

  @override
  State<TravelPlanScreen> createState() => _TravelPlanScreenState();
}

class _TravelPlanScreenState extends State<TravelPlanScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  // 설정 화면으로 이동 (새 계획 추가)
  void _navigateAndAddPlan() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TravelPlanSetupScreen()),
    );
  }

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
              Icons.translate,
              color: Colors.black,
              size: 26,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TranslatorScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.black,
              size: 26,
            ),
            onPressed: _navigateAndAddPlan,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getMyTravelPlansStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return const Center(child: Text("오류가 발생했습니다."));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          // 정렬 (최신순)
          docs.sort((a, b) {
            final t1 = (b.data() as Map)['createdAt'] as Timestamp?;
            final t2 = (a.data() as Map)['createdAt'] as Timestamp?;
            if (t1 == null) return -1;
            if (t2 == null) return 1;
            return t1.compareTo(t2);
          });

          if (docs.isEmpty) {
            return Center(
              child: GestureDetector(
                onTap: _navigateAndAddPlan,
                behavior: HitTestBehavior.translucent,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.add_circle_outline,
                      size: 60,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "아직 나의 여행 계획이 없어요",
                      style: TextStyle(fontSize: 16, color: Color(0xFF757575)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "여기를 눌러 계획을 추가해 보세요!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length + 1,
            itemBuilder: (context, index) {
              if (index == docs.length) {
                return GestureDetector(
                  onTap: _navigateAndAddPlan,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 10),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.add, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          "새로운 여행 추가하기",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final doc = docs[index];
              final plan = TravelPlan.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              // [수정] 리스트 아이템 클릭 시 상세 화면으로 이동
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelPlanDetailScreen(plan: plan),
                    ),
                  );
                },
                child: Container(
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
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flight_takeoff,
                          color: Colors.white,
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
                            if (plan.members.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "함께: ${plan.members.length}명",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blue[300],
                                  ),
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}
