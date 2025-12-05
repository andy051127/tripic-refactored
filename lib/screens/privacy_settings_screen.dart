import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;

  // 설정 값 상태 관리
  bool _isPublicToFollowers = true; // 나를 팔로워한 사람들에게 공개
  bool _isPublicToMutuals = false; // 맞팔로우한 사람에게만 공개

  List<String> _selectedFollowingFriends = []; // 팔로잉 목록에서 선택한 친구들

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  // Firebase에서 프라이버시 설정 불러오기
  Future<void> _loadPrivacySettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _db.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data();
          final privacySettings = data?['privacySettings'];
          if (privacySettings != null && mounted) {
            setState(() {
              _isPublicToFollowers =
                  privacySettings['isPublicToFollowers'] ?? true;
              _isPublicToMutuals =
                  privacySettings['isPublicToMutuals'] ?? false;
              _selectedFollowingFriends = List<String>.from(
                privacySettings['selectedFollowingFriends'] ?? [],
              );
              _isLoading = false;
            });
          } else if (mounted) {
            setState(() => _isLoading = false);
          }
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('프라이버시 설정 로드 실패: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Firebase에 프라이버시 설정 저장
  Future<void> _savePrivacySettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'privacySettings': {
            'isPublicToFollowers': _isPublicToFollowers,
            'isPublicToMutuals': _isPublicToMutuals,
            'selectedFollowingFriends': _selectedFollowingFriends,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 공개 범위 설정이 저장되었습니다.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('프라이버시 설정 저장 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 설정 저장에 실패했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 팔로잉 목록 불러오기
  Future<List<Map<String, dynamic>>> _getFollowingList() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final followingSnapshot = await _db
            .collection('users')
            .doc(user.uid)
            .collection('following')
            .get();

        List<Map<String, dynamic>> users = [];
        for (var doc in followingSnapshot.docs) {
          final userDoc = await _db.collection('users').doc(doc.id).get();
          if (userDoc.exists) {
            final data = userDoc.data();
            users.add({
              'uid': doc.id,
              'userName': data?['userName'] ?? data?['username'] ?? 'Unknown',
            });
          }
        }
        return users;
      }
      return [];
    } catch (e) {
      print('팔로잉 목록 조회 실패: $e');
      return [];
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
        title: const Text(
          "계정 공개 범위",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        const Text(
                          "내 계정을 볼 수 있는 사람을 설정하세요.",
                          style: TextStyle(color: Colors.grey, fontSize: 14),
                        ),
                        const SizedBox(height: 20),

                        // 1. 나를 팔로워한 사람들에게 공개
                        _buildSwitchTile(
                          title: "모든 팔로워에게 공개",
                          subtitle: "나를 팔로워한 사람들이 내 계정을 볼 수 있습니다.",
                          value: _isPublicToFollowers,
                          onChanged: (val) {
                            if (val) {
                              setState(() {
                                _isPublicToFollowers = true;
                                _isPublicToMutuals = false;
                                _selectedFollowingFriends.clear();
                              });
                            }
                          },
                        ),

                        const Divider(),

                        // 2. 맞팔로우한 사람에게만 공개
                        _buildSwitchTile(
                          title: "맞팔로우한 사람에게만 공개",
                          subtitle: "나를 팔로잉하고 나도 팔로잉하는 사람만 볼 수 있습니다.",
                          value: _isPublicToMutuals,
                          onChanged: (val) {
                            if (val) {
                              setState(() {
                                _isPublicToFollowers = false;
                                _isPublicToMutuals = true;
                                _selectedFollowingFriends.clear();
                              });
                            }
                          },
                        ),

                        const Divider(),

                        // 3. 특정 팔로잉 사람에게만 공개
                        _buildSwitchTile(
                          title: "특정 사람에게만 공개",
                          subtitle: "선택한 사람들만 내 계정을 볼 수 있습니다.",
                          value: _selectedFollowingFriends.isNotEmpty,
                          onChanged: (val) async {
                            if (val) {
                              // 팔로잉 목록 가져오기
                              final followingUsers = await _getFollowingList();
                              if (!mounted) return;

                              if (followingUsers.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('팔로잉하는 사람이 없습니다.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // 선택 다이얼로그 표시
                              showDialog(
                                context: context,
                                builder: (context) {
                                  List<String> tempSelected = List.from(
                                    _selectedFollowingFriends,
                                  );
                                  return StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return AlertDialog(
                                        backgroundColor: Colors.white,
                                        title: const Text("팔로잉 목록에서 선택"),
                                        content: SingleChildScrollView(
                                          child: SizedBox(
                                            width: double.maxFinite,
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: followingUsers.map((
                                                user,
                                              ) {
                                                return CheckboxListTile(
                                                  title: Text(user['userName']),
                                                  value: tempSelected.contains(
                                                    user['uid'],
                                                  ),
                                                  onChanged: (val) {
                                                    setDialogState(() {
                                                      if (val == true) {
                                                        tempSelected.add(
                                                          user['uid'],
                                                        );
                                                      } else {
                                                        tempSelected.remove(
                                                          user['uid'],
                                                        );
                                                      }
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("취소"),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedFollowingFriends =
                                                    tempSelected;
                                                if (_selectedFollowingFriends
                                                    .isNotEmpty) {
                                                  _isPublicToFollowers = false;
                                                  _isPublicToMutuals = false;
                                                } else {
                                                  // 아무도 선택하지 않았다면 기본값으로
                                                  _isPublicToFollowers = true;
                                                }
                                              });
                                              Navigator.pop(context);
                                            },
                                            child: const Text("확인"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            } else {
                              setState(() {
                                _selectedFollowingFriends.clear();
                                _isPublicToFollowers = true;
                              });
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        // 선택된 사람 수 표시 및 수정 버튼
                        if (_selectedFollowingFriends.isNotEmpty)
                          GestureDetector(
                            onTap: () async {
                              // 팔로잉 목록 가져오기
                              final followingUsers = await _getFollowingList();
                              if (!mounted) return;

                              if (followingUsers.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('팔로잉하는 사람이 없습니다.'),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }

                              // 선택 다이얼로그 표시
                              showDialog(
                              context: context,
                              builder: (context) {
                                List<String> tempSelected = List.from(
                                  _selectedFollowingFriends,
                                );
                                return StatefulBuilder(
                                  builder: (context, setDialogState) {
                                    return AlertDialog(
                                      backgroundColor: Colors.white,
                                      title: const Text("팔로잉 목록에서 선택"),
                                      content: SingleChildScrollView(
                                        child: SizedBox(
                                          width: double.maxFinite,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: followingUsers.map((
                                              user,
                                            ) {
                                              return CheckboxListTile(
                                                title: Text(user['userName']),
                                                value: tempSelected.contains(
                                                  user['uid'],
                                                ),
                                                onChanged: (val) {
                                                  setDialogState(() {
                                                    if (val == true) {
                                                      tempSelected.add(
                                                        user['uid'],
                                                      );
                                                    } else {
                                                      tempSelected.remove(
                                                        user['uid'],
                                                      );
                                                    }
                                                  });
                                                },
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text("취소"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _selectedFollowingFriends =
                                                  tempSelected;
                                              if (_selectedFollowingFriends
                                                  .isNotEmpty) {
                                                _isPublicToFollowers = false;
                                                _isPublicToMutuals = false;
                                              }
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: const Text("확인"),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _selectedFollowingFriends.isNotEmpty
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "선택한 사람 수정",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4.0,
                                          ),
                                          child: Text(
                                            "${_selectedFollowingFriends.length}명 선택됨",
                                            style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.bold,
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
                        ),
                      ],
                    ),
                  ),
                  // 저장 버튼
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savePrivacySettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CA1AF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "저장",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF4CA1AF), // Tripic 메인 컬러
      contentPadding: EdgeInsets.zero,
    );
  }
}
