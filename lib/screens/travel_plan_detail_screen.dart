import 'package:flutter/material.dart';
import '../models/travel_plan_model.dart';
import 'travel_plan_setup_screen.dart'; // 수정 화면으로 이동용
import '../services/firestore_service.dart';

class TravelPlanDetailScreen extends StatelessWidget {
  final TravelPlan plan;

  const TravelPlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // 배경색 약간 어둡게 하여 종이 느낌 강조
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "나의 여행 계획",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          // 1. 수정 버튼
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              // 수정 화면으로 이동 (현재 plan 데이터 전달)
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => TravelPlanSetupScreen(plan: plan),
                ),
              );
            },
          ),
          // 2. 삭제 버튼
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteDialog(context);
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 종이 느낌의 메인 카드
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 타이틀 & 날짜
                  Text(
                    plan.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        plan.date,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  // 상세 정보 리스트
                  _buildDetailRow(
                    Icons.flight,
                    "비행편",
                    plan.flightInfo.isEmpty ? "정보 없음" : plan.flightInfo,
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    Icons.hotel,
                    "숙소",
                    plan.hotelInfo.isEmpty ? "정보 없음" : plan.hotelInfo,
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow(
                    Icons.people,
                    "동행 인원",
                    plan.members.isEmpty ? "없음" : plan.members.join(", "),
                  ),
                  const SizedBox(height: 20),

                  const Divider(height: 40, thickness: 1),

                  // 준비물 & 리스트
                  _buildSectionTitle("🧳 준비물"),
                  if (plan.supplies.isEmpty)
                    const Text("- 없음", style: TextStyle(color: Colors.grey)),
                  ...plan.supplies.map(
                    (e) => Text(
                      "• $e",
                      style: const TextStyle(fontSize: 15, height: 1.5),
                    ),
                  ),

                  const SizedBox(height: 20),

                  _buildSectionTitle("📋 할 일 리스트"),
                  if (plan.todoList.isEmpty)
                    const Text("- 없음", style: TextStyle(color: Colors.grey)),
                  ...plan.todoList.map((e) {
                    bool isChecked = e['isChecked'] ?? false;
                    return Row(
                      children: [
                        Icon(
                          isChecked
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                          color: isChecked ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          e['title'] ?? "",
                          style: TextStyle(
                            fontSize: 15,
                            decoration: isChecked
                                ? TextDecoration.lineThrough
                                : null,
                            color: isChecked ? Colors.grey : Colors.black,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.black54, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // 삭제 확인 팝업
  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("계획 삭제"),
        content: const Text("이 여행 계획을 정말 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () async {
              // Firestore 삭제 요청
              await FirestoreService().deleteTravelPlan(plan.id);
              if (context.mounted) {
                Navigator.pop(context); // 다이얼로그 닫기
                Navigator.pop(context); // 상세 화면 닫기 (목록으로 이동)
              }
            },
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
