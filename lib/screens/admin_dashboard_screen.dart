import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  Map<String, int> _stats = {
    'users': 0,
    'posts': 0,
    'communityPosts': 0,
    'comments': 0,
    'images': 0,
    'plans': 0,
    'reports': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _firestoreService.getDashboardStats();
    if (mounted) {
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자 대시보드'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: GridView.count(
                padding: const EdgeInsets.all(16.0),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.3,
                children: [
                  _buildStatCard(
                    '총 사용자',
                    _stats['users'].toString(),
                    Icons.people,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    '총 게시물',
                    _stats['posts'].toString(),
                    Icons.article,
                    Colors.green,
                  ),
                  _buildStatCard(
                    '커뮤니티 게시물',
                    _stats['communityPosts'].toString(),
                    Icons.forum,
                    Colors.teal,
                  ),
                  _buildStatCard(
                    '총 댓글',
                    _stats['comments'].toString(),
                    Icons.comment,
                    Colors.amber,
                  ),
                  _buildStatCard(
                    '총 이미지',
                    _stats['images'].toString(),
                    Icons.image,
                    Colors.purple,
                  ),
                  _buildStatCard(
                    '여행 계획',
                    _stats['plans'].toString(),
                    Icons.map,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    '신고 건수',
                    _stats['reports'].toString(),
                    Icons.report_problem,
                    Colors.red,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
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
}
