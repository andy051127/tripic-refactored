import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // 알림 상태 변수들
  bool _pauseAll = false;
  bool _postCommentAlert = true;
  bool _followAlert = true;
  bool _messageAlert = true;
  bool _marketingAlert = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  // Firestore에서 알림 설정 불러오기
  Future<void> _loadNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _pauseAll = data['pauseAll'] ?? false;
          _postCommentAlert = data['postCommentAlert'] ?? true;
          _followAlert = data['followAlert'] ?? true;
          _messageAlert = data['messageAlert'] ?? true;
          _marketingAlert = data['marketingAlert'] ?? false;
          _isLoading = false;
        });
      } else {
        // 설정이 없으면 기본값으로 저장
        await _saveNotificationSettings();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('알림 설정 불러오기 실패: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Firestore에 알림 설정 저장
  Future<void> _saveNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('notifications')
          .set({
        'pauseAll': _pauseAll,
        'postCommentAlert': _postCommentAlert,
        'followAlert': _followAlert,
        'messageAlert': _messageAlert,
        'marketingAlert': _marketingAlert,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('알림 설정 저장 완료');
    } catch (e) {
      print('알림 설정 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('설정 저장 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            "알림 설정",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
          "알림 설정",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              "푸시 알림",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // 1. 모두 일시 중지
            _buildSwitchTile(
              title: "모두 일시 중지",
              value: _pauseAll,
              onChanged: (val) {
                setState(() {
                  _pauseAll = val;
                  if (val) {
                    // 모두 중지 시 나머지 알림도 끄기
                    _postCommentAlert = false;
                    _followAlert = false;
                    _messageAlert = false;
                  }
                });
                _saveNotificationSettings();
              },
            ),
            const Divider(),

            // 2. 게시물, 댓글
            _buildSwitchTile(
              title: "게시물, 댓글",
              subtitle: "내 게시물에 댓글이나 좋아요가 달리면 알림을 받습니다.",
              value: _postCommentAlert,
              onChanged: _pauseAll
                  ? null
                  : (val) {
                      setState(() => _postCommentAlert = val);
                      _saveNotificationSettings();
                    },
            ),

            // 3. 팔로잉 및 팔로워
            _buildSwitchTile(
              title: "팔로잉 및 팔로워",
              subtitle: "누군가 나를 팔로우하면 알림을 받습니다.",
              value: _followAlert,
              onChanged: _pauseAll
                  ? null
                  : (val) {
                      setState(() => _followAlert = val);
                      _saveNotificationSettings();
                    },
            ),

            // 4. 메시지
            _buildSwitchTile(
              title: "메시지 및 통화",
              subtitle: "새로운 메시지나 통화 요청이 오면 알림을 받습니다.",
              value: _messageAlert,
              onChanged: _pauseAll
                  ? null
                  : (val) {
                      setState(() => _messageAlert = val);
                      _saveNotificationSettings();
                    },
            ),

            const Divider(),
            const SizedBox(height: 10),

            // 설명 텍스트
            const Text(
              "※ 알림 설정은 자동으로 저장됩니다.",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CA1AF), // 앱 테마 컬러
      contentPadding: EdgeInsets.zero,
    );
  }
}
