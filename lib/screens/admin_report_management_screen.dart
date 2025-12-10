import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class AdminReportManagementScreen extends StatelessWidget {
  const AdminReportManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('신고 관리'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestoreService.getReportsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('신고 목록 로딩 오류'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: Colors.green,
                  ),
                  SizedBox(height: 16),
                  Text('대기 중인 신고가 없습니다'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final reason = data['reason'] ?? '사유 없음';
              final type = data['type'] ?? '알 수 없음'; // post, comment, user
              final status = data['status'] ?? 'pending';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              final reporterId = data['reporterId'] ?? '알 수 없음';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: _buildStatusIcon(status),
                  title: Text(
                    reason,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '유형: $type • ${createdAt != null ? DateFormat('MMM d, y').format(createdAt) : ''}',
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('신고 ID', doc.id),
                          _buildDetailRow('신고자 ID', reporterId),
                          _buildDetailRow('대상 ID', data['targetId'] ?? 'N/A'),
                          _buildDetailRow('전체 사유', reason),
                          const SizedBox(height: 16),
                          _buildReportedContent(type, data['targetId']),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (type == 'post' && status == 'pending')
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () => _deletePostAndResolve(
                                      context,
                                      firestoreService,
                                      doc.id,
                                      data['targetId'],
                                    ),
                                    child: const Text('게시물 삭제'),
                                  ),
                                ),
                              OutlinedButton(
                                onPressed: () => _updateStatus(
                                  context,
                                  firestoreService,
                                  doc.id,
                                  'dismissed',
                                ),
                                child: const Text('기각 (무시)'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => _updateStatus(
                                  context,
                                  firestoreService,
                                  doc.id,
                                  'resolved',
                                ),
                                child: const Text('처리 완료'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildReportedContent(String type, String? targetId) {
    if (type != 'post' || targetId == null) return const SizedBox.shrink();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('posts')
          .doc(targetId)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null) {
          return const Text(
            '삭제된 게시물입니다.',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          );
        }

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '신고된 게시물 내용:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 8),
              if (data['imageUrl'] != null &&
                  data['imageUrl'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      data['imageUrl'],
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              Text(
                data['title'] ?? '제목 없음',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(data['content'] ?? '내용 없음'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(String status) {
    Color color;
    IconData icon;

    switch (status) {
      case 'resolved':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'dismissed':
        color = Colors.grey;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.warning;
    }

    return Icon(icon, color: color);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _deletePostAndResolve(
    BuildContext context,
    FirestoreService service,
    String reportId,
    String? postId,
  ) async {
    if (postId == null) return;

    try {
      await service.deletePostByAdmin(postId);
      await service.updateReportStatus(reportId, 'resolved');
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('게시물이 삭제되고 신고가 처리되었습니다')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    }
  }

  Future<void> _updateStatus(
    BuildContext context,
    FirestoreService service,
    String reportId,
    String newStatus,
  ) async {
    try {
      await service.updateReportStatus(reportId, newStatus);
      if (context.mounted) {
        String statusMessage = newStatus == 'resolved' ? '처리 완료' : '기각';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('신고가 $statusMessage 상태로 변경되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('신고 처리 중 오류 발생: $e')));
      }
    }
  }
}
