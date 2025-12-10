import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/travel_record_model.dart';

/// 여행 기록 디버그 화면 - Firestore 데이터 확인용
class TravelRecordsDebugScreen extends StatelessWidget {
  const TravelRecordsDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('여행 기록 디버그'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: user == null
          ? const Center(child: Text('로그인이 필요합니다'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('travel_records')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('오류: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '저장된 여행 기록이 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'userId: ${user.uid}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final record = TravelRecord.fromMap(data, doc.id);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 제목
                            Row(
                              children: [
                                Icon(
                                  record.isActive
                                      ? Icons.play_circle_filled
                                      : Icons.check_circle,
                                  color: record.isActive
                                      ? Colors.blue
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  record.isActive ? '진행 중' : '완료됨',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),

                            // 문서 ID
                            _buildInfoRow(
                              '문서 ID',
                              doc.id,
                              isCode: true,
                            ),

                            // 시작 시간
                            _buildInfoRow(
                              '시작 시간',
                              _formatTime(record.startTime),
                            ),

                            // 종료 시간
                            if (record.endTime != null)
                              _buildInfoRow(
                                '종료 시간',
                                _formatTime(record.endTime!),
                              ),

                            // 경로 포인트 수
                            _buildInfoRow(
                              '경로 포인트',
                              '${record.routePoints.length}개',
                              color: record.routePoints.isEmpty
                                  ? Colors.red
                                  : Colors.green,
                            ),

                            // 첫 번째 포인트 정보
                            if (record.routePoints.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '첫 번째 포인트:',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lat: ${record.routePoints.first.latitude.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      'Lng: ${record.routePoints.first.longitude.toStringAsFixed(6)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // 사진 수
                            _buildInfoRow(
                              '사진',
                              '${record.photos.length}개',
                            ),

                            // userId
                            _buildInfoRow(
                              'User ID',
                              data['userId'] ?? 'N/A',
                              isCode: true,
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

  Widget _buildInfoRow(String label, String value,
      {Color? color, bool isCode = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color,
                fontFamily: isCode ? 'Courier' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')} '
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
