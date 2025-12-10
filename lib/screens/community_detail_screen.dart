import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용
import '../models/activity_model.dart'; // 활동 내역 저장용
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_write_screen.dart'; // 수정 화면용
import '../services/firestore_service.dart'; // 팔로우 기능용
import '../models/travel_plan_model.dart';
import 'travel_plan_detail_screen.dart';
import 'other_user_profile_screen.dart';
import 'profile_screen.dart';
import 'share_post_screen.dart';
import '../models/post_model.dart';

class CommunityDetailScreen extends StatefulWidget {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final DateTime createdAt; // [추가] 작성일 받기
  final String postUid; // [추가] 게시물 작성자 uid
  final String? postId; // [추가] 게시물 ID (삭제용)
  final String? category; // [추가] 게시물 카테고리
  final String? travelPlanId; // 여행 계획 ID
  final String? travelPlanTitle; // 여행 계획 제목
  final String? travelPlanDate; // 여행 계획 날짜
  final String? travelPlanCountry; // 여행 계획 국가
  final String? userProfileImage; // 프로필 이미지

  const CommunityDetailScreen({
    super.key,
    required this.name,
    this.location = "",
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    required this.createdAt, // 필수 인자로 변경
    required this.postUid, // 필수 인자로 추가
    this.postId, // 선택적 인자
    this.category, // 선택적 인자
    this.travelPlanId,
    this.travelPlanTitle,
    this.travelPlanDate,
    this.travelPlanCountry,
    this.userProfileImage,
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  // 좋아요 상태
  bool _isLiked = false;
  int _likeCount = 0;

  // 댓글 상태
  final TextEditingController _commentController = TextEditingController();

  // 팔로우 상태
  bool _isFollowing = false;

  // 저장 상태
  bool _isSaved = false;

  // 현재 사용자 프로필 이미지
  String _currentUserProfileImage = '';

  @override
  void initState() {
    super.initState();
    // stats 문자열에서 초기 좋아요 수 파싱
    try {
      _likeCount = int.parse(widget.stats.split(' · ')[0]);
    } catch (e) {
      _likeCount = 0;
    }
    // 팔로우 상태 확인
    _checkFollowStatus();
    // 좋아요 상태 확인
    _checkLikeStatus();
    // 저장 상태 확인
    _checkSaveStatus();
    // 현재 사용자 프로필 이미지 로드
    _loadCurrentUserProfile();
  }

  // 현재 사용자 프로필 이미지 로드
  Future<void> _loadCurrentUserProfile() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (mounted && userDoc.exists) {
          setState(() {
            _currentUserProfileImage = userDoc.data()?['profileImage'] ?? '';
          });
        }
      }
    } catch (e) {
      print('프로필 이미지 로드 실패: $e');
    }
  }

  // 저장 상태 확인
  Future<void> _checkSaveStatus() async {
    if (widget.postId == null) return;

    try {
      final isSaved = await _firestoreService.isPostSaved(widget.postId!);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      print('저장 상태 확인 실패: $e');
    }
  }

  // 저장/저장 취소 토글
  Future<void> _toggleSave() async {
    if (widget.postId == null) return;

    try {
      if (_isSaved) {
        await _firestoreService.unsavePost(widget.postId!);
        if (mounted) {
          setState(() {
            _isSaved = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("보관함에서 삭제되었습니다.")));
        }
      } else {
        await _firestoreService.savePost(widget.postId!);
        if (mounted) {
          setState(() {
            _isSaved = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("게시물이 보관함에 저장되었습니다.")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  // 여행 계획 배너 표시
  void _showTravelPlanBanner() async {
    if (widget.travelPlanId == null || widget.travelPlanId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 게시물에는 여행 계획이 연결되어 있지 않습니다')),
      );
      return;
    }

    try {
      // Firestore에서 여행 계획 조회
      final planDoc = await FirebaseFirestore.instance
          .collection('travel_plans')
          .doc(widget.travelPlanId)
          .get();

      if (!planDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('여행 계획을 찾을 수 없습니다')));
        }
        return;
      }

      final plan = TravelPlan.fromMap(
        planDoc.data() as Map<String, dynamic>,
        planDoc.id,
      );

      if (!mounted) return;

      // 배너 모달 표시
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
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
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '여행 계획',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelPlanDetailScreen(plan: plan),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.flight_takeoff,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    plan.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plan.country,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    plan.date,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[200]!.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(11),
                            bottomRight: Radius.circular(11),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.touch_app,
                              size: 16,
                              color: Colors.blue[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '탭하여 여행 계획 보기',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류가 발생했습니다: $e')));
      }
    }
  }

  // 좋아요 상태 확인
  Future<void> _checkLikeStatus() async {
    if (widget.postId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .doc(currentUser.uid)
          .get();

      if (mounted) {
        setState(() {
          _isLiked = likeDoc.exists;
        });
      }

      // 실제 좋아요 개수 가져오기
      final likesSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .get();

      if (mounted) {
        setState(() {
          _likeCount = likesSnapshot.docs.length;
        });
      }
    } catch (e) {
      print('좋아요 상태 확인 실패: $e');
    }
  }

  // 좋아요 토글
  Future<void> _toggleLike() async {
    if (widget.postId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    try {
      final likeRef = FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('likes')
          .doc(currentUser.uid);

      if (_isLiked) {
        // 좋아요 취소
        await likeRef.delete();
        if (mounted) {
          setState(() {
            _isLiked = false;
            if (_likeCount > 0) _likeCount--;
          });
        }
      } else {
        // 좋아요 추가
        await likeRef.set({
          'uid': currentUser.uid,
          'timestamp': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() {
            _isLiked = true;
            _likeCount++;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
      }
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // 팔로우 상태 확인
  Future<void> _checkFollowStatus() async {
    if (widget.postUid.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || currentUser.uid == widget.postUid) return;

    try {
      final isFollowing = await _firestoreService.isFollowing(widget.postUid);
      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
        });
      }
    } catch (e) {
      print('팔로우 상태 확인 실패: $e');
    }
  }

  // 팔로우/언팔로우 토글
  Future<void> _toggleFollow() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    try {
      if (_isFollowing) {
        // 언팔로우
        await _firestoreService.unfollowUser(widget.postUid);
        if (mounted) {
          setState(() {
            _isFollowing = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("팔로우를 취소했습니다.")));
        }
      } else {
        // 팔로우
        await _firestoreService.followUser(widget.postUid);
        if (mounted) {
          setState(() {
            _isFollowing = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("팔로우 했습니다!")));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
      }
    }
  }

  // 댓글 추가 함수 (Firestore 저장)
  Future<void> _addComment() async {
    if (_commentController.text.isEmpty || widget.postId == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("로그인이 필요합니다.")));
      return;
    }

    try {
      // 사용자 정보 가져오기
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      final userName =
          userDoc.data()?['userName'] ??
          userDoc.data()?['username'] ??
          userDoc.data()?['name'] ??
          'Unknown';
      final userProfileImage = userDoc.data()?['profileImage'] ?? '';

      print('댓글 작성자 정보: userName=$userName, profileImage=$userProfileImage');

      final commentText = _commentController.text.trim();

      // Firestore에 댓글 저장
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .collection('comments')
          .add({
            'uid': currentUser.uid,
            'userName': userName,
            'userProfileImage': userProfileImage,
            'content': commentText,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 활동 내역에 댓글 저장
      addActivity(
        ActivityType.comment,
        widget.title,
        commentText,
        widget.imageUrl,
        postId: widget.postId,
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("댓글이 등록되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("댓글 등록 실패: $e")));
      }
    }
  }

  // 댓글 수정
  Future<void> _editComment(String commentId, String currentContent) async {
    final TextEditingController editController = TextEditingController(
      text: currentContent,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("댓글 수정"),
        content: TextField(
          controller: editController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: "댓글을 입력하세요",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, editController.text.trim()),
            child: const Text("수정"),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && widget.postId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .update({
              'content': result,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("댓글이 수정되었습니다.")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("댓글 수정 실패: $e")));
        }
      }
    }

    editController.dispose();
  }

  // 댓글 삭제
  Future<void> _deleteComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("댓글 삭제"),
        content: const Text("정말로 이 댓글을 삭제하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("삭제", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.postId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .collection('comments')
            .doc(commentId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("댓글이 삭제되었습니다.")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("댓글 삭제 실패: $e")));
        }
      }
    }
  }

  // 댓글 옵션 메뉴 (수정/삭제)
  void _showCommentOptions(
    String commentId,
    String commentUid,
    String content,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyComment = currentUser != null && currentUser.uid == commentUid;

    if (!isMyComment) return; // 본인 댓글이 아니면 메뉴 표시 안 함

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.black),
              title: const Text("수정하기"),
              onTap: () {
                Navigator.pop(context);
                _editComment(commentId, content);
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text("삭제하기", style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _deleteComment(commentId);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 더보기 메뉴 (점 3개)
  void _showMoreOptions() {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isMyPost = currentUser != null && currentUser.uid == widget.postUid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: isMyPost
              ? [
                  // 본인 게시물: 수정하기, 삭제하기
                  _buildOptionItem(
                    Icons.edit_outlined,
                    "수정하기",
                    onTap: () {
                      Navigator.pop(context);
                      _editPost();
                    },
                  ),
                  const Divider(height: 1),
                  _buildOptionItem(
                    Icons.delete_outline,
                    "삭제하기",
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _deletePost();
                    },
                  ),
                ]
              : [
                  // 타인 게시물: 저장, 팔로우/언팔로우, 신고
                  _buildOptionItem(
                    _isSaved ? Icons.bookmark : Icons.bookmark_border,
                    _isSaved ? "보관함에서 삭제" : "보관함에 저장",
                    onTap: () {
                      Navigator.pop(context);
                      _toggleSave();
                    },
                  ),
                  const Divider(height: 1),
                  _buildOptionItem(
                    _isFollowing
                        ? Icons.person_remove_outlined
                        : Icons.person_add_outlined,
                    _isFollowing ? "언팔로우" : "팔로우",
                    onTap: () {
                      Navigator.pop(context);
                      _toggleFollow();
                    },
                  ),
                  const Divider(height: 1),
                  _buildOptionItem(
                    Icons.campaign_outlined,
                    "신고",
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _showReportDialog();
                    },
                  ),
                ],
        ),
      ),
    );
  }

  // 게시물 수정
  void _editPost() async {
    if (widget.postId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('게시물 ID를 찾을 수 없습니다.')));
      return;
    }

    // Firestore에서 전체 게시물 데이터 가져오기
    try {
      final doc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.postId)
          .get();

      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('게시물을 찾을 수 없습니다.')));
        }
        return;
      }

      final data = doc.data()!;

      // 수정 화면으로 이동
      if (mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityWriteScreen(
              isEdit: true,
              postId: widget.postId,
              initialData: data,
            ),
          ),
        );

        // 수정 완료 후 돌아오면 현재 화면도 닫기
        if (result == true && mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
      }
    }
  }

  // 게시물 삭제
  Future<void> _deletePost() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('게시물 삭제'),
        content: const Text('이 게시물을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.postId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .delete();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('게시물이 삭제되었습니다.')));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
        }
      }
    }
  }

  Widget _buildOptionItem(
    IconData icon,
    String text, {
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    // [수정] 날짜 포맷팅
    String formattedDate = DateFormat('yyyy.MM.dd').format(widget.createdAt);

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          "커뮤니티",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          // 여행 계획 보기 버튼
          IconButton(
            onPressed: _showTravelPlanBanner,
            icon: const Icon(Icons.edit_note, color: Colors.blue),
          ),
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 작성자 정보 헤더
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            // 현재 사용자 확인 후 프로필 화면으로 이동
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser != null &&
                                currentUser.uid == widget.postUid) {
                              // 내 프로필
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            } else {
                              // 다른 사용자 프로필
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserProfileScreen(
                                    userId: widget.postUid,
                                    userName: widget.name,
                                    profileImage: widget.userProfileImage ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: _UserProfileAvatar(
                            userId: widget.postUid,
                            userName: widget.name,
                            profileImage: widget.userProfileImage,
                            radius: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            // 현재 사용자 확인 후 프로필 화면으로 이동
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser != null &&
                                currentUser.uid == widget.postUid) {
                              // 내 프로필
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            } else {
                              // 다른 사용자 프로필
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserProfileScreen(
                                    userId: widget.postUid,
                                    userName: widget.name,
                                    profileImage: widget.userProfileImage ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            widget.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.location.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.black,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.location,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // 2. 메인 게시글 이미지
                  if (widget.imageUrl != null)
                    Container(
                      width: double.infinity,
                      height: 300,
                      color: Colors.grey[200],
                      child: Image.network(
                        widget.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Center(
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[100],
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                        ),
                      ),
                    ),

                  // 3. 게시글 내용
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.content,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // [수정됨] 실제 작성 날짜 표시
                        Text(
                          "$formattedDate 작성",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. 통계 및 액션 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _toggleLike,
                          child: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 28,
                            color: _isLiked ? Colors.red : Colors.black,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // 좋아요 개수 실시간 표시
                        widget.postId != null
                            ? StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(widget.postId)
                                    .collection('likes')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final likeCount =
                                      snapshot.data?.docs.length ?? 0;
                                  return Text(
                                    "$likeCount",
                                    style: const TextStyle(fontSize: 16),
                                  );
                                },
                              )
                            : Text(
                                "$_likeCount",
                                style: const TextStyle(fontSize: 16),
                              ),

                        const SizedBox(width: 20),

                        const Icon(Icons.chat_bubble_outline, size: 28),
                        const SizedBox(width: 6),
                        // 댓글 개수 실시간 표시
                        widget.postId != null
                            ? StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(widget.postId)
                                    .collection('comments')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final commentCount =
                                      snapshot.data?.docs.length ?? 0;
                                  return Text(
                                    "$commentCount",
                                    style: const TextStyle(fontSize: 16),
                                  );
                                },
                              )
                            : const Text("0", style: TextStyle(fontSize: 16)),

                        const SizedBox(width: 20),

                        GestureDetector(
                          onTap: () async {
                            // 공유하기 기능
                            if (widget.postId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('게시물 정보를 찾을 수 없습니다'),
                                ),
                              );
                              return;
                            }

                            // Firestore에서 전체 데이터 가져오기
                            final postDoc = await FirebaseFirestore.instance
                                .collection('posts')
                                .doc(widget.postId)
                                .get();

                            if (postDoc.exists) {
                              final data = postDoc.data()!;
                              final post = Post(
                                id: postDoc.id,
                                uid: data['uid'] ?? '',
                                userName: data['userName'] ?? '',
                                imageUrl: data['imageUrl'] ?? '',
                                imageUrls: data['imageUrls'] != null
                                    ? List<String>.from(data['imageUrls'])
                                    : [],
                                title: data['title'] ?? '',
                                content: data['content'] ?? '',
                                location: data['location'] ?? '',
                                category: data['category'] ?? 'feed',
                              );

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SharePostScreen(post: post),
                                ),
                              );
                            }
                          },
                          child: const Icon(Icons.near_me_outlined, size: 28),
                        ),

                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleSave,
                          child: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 28,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(thickness: 1, color: Color(0xFFEEEEEE)),

                  // 5. 댓글 리스트 섹션
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "댓글",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Firestore StreamBuilder로 댓글 표시
                        widget.postId != null
                            ? StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('posts')
                                    .doc(widget.postId)
                                    .collection('comments')
                                    .orderBy('createdAt', descending: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "댓글을 불러올 수 없습니다.",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  }

                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }

                                  final comments = snapshot.data?.docs ?? [];

                                  if (comments.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          "아직 댓글이 없습니다. 첫 댓글을 남겨보세요!",
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    );
                                  }

                                  return ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: comments.length,
                                    itemBuilder: (context, index) {
                                      final commentDoc = comments[index];
                                      final commentData =
                                          commentDoc.data()
                                              as Map<String, dynamic>;
                                      final commentId = commentDoc.id;
                                      final commentUid =
                                          commentData['uid'] ?? '';
                                      final userName =
                                          commentData['userName'] ?? 'Unknown';
                                      final content =
                                          commentData['content'] ?? '';
                                      final createdAt =
                                          commentData['createdAt']
                                              as Timestamp?;
                                      final userProfileImage =
                                          commentData['userProfileImage'] ?? '';

                                      print(
                                        '댓글 표시: userName=$userName, profileImage=$userProfileImage, isEmpty=${userProfileImage.isEmpty}',
                                      );

                                      // 시간 포맷
                                      String timeAgo = '방금 전';
                                      if (createdAt != null) {
                                        final now = DateTime.now();
                                        final date = createdAt.toDate();
                                        final difference = now.difference(date);

                                        if (difference.inDays > 0) {
                                          timeAgo = '${difference.inDays}일 전';
                                        } else if (difference.inHours > 0) {
                                          timeAgo = '${difference.inHours}시간 전';
                                        } else if (difference.inMinutes > 0) {
                                          timeAgo =
                                              '${difference.inMinutes}분 전';
                                        }
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 16.0,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                final currentUser = FirebaseAuth
                                                    .instance
                                                    .currentUser;
                                                if (currentUser?.uid ==
                                                    commentUid) {
                                                  // 내 프로필
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          const ProfileScreen(),
                                                    ),
                                                  );
                                                } else {
                                                  // 다른 사용자 프로필
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          OtherUserProfileScreen(
                                                            userId: commentUid,
                                                            userName: userName,
                                                            profileImage:
                                                                userProfileImage,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                backgroundImage:
                                                    userProfileImage.isNotEmpty
                                                    ? NetworkImage(
                                                            userProfileImage,
                                                          )
                                                          as ImageProvider
                                                    : null,
                                                onBackgroundImageError:
                                                    userProfileImage.isNotEmpty
                                                    ? (exception, stackTrace) {
                                                        print(
                                                          '프로필 이미지 로드 실패: $userProfileImage',
                                                        );
                                                      }
                                                    : null,
                                                child: userProfileImage.isEmpty
                                                    ? const Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      GestureDetector(
                                                        onTap: () {
                                                          final currentUser =
                                                              FirebaseAuth
                                                                  .instance
                                                                  .currentUser;
                                                          if (currentUser
                                                                  ?.uid ==
                                                              commentUid) {
                                                            // 내 프로필
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder:
                                                                    (context) =>
                                                                        const ProfileScreen(),
                                                              ),
                                                            );
                                                          } else {
                                                            // 다른 사용자 프로필
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                builder: (context) => OtherUserProfileScreen(
                                                                  userId:
                                                                      commentUid,
                                                                  userName:
                                                                      userName,
                                                                  profileImage:
                                                                      userProfileImage,
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                        child: Text(
                                                          userName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        timeAgo,
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    content,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // 본인 댓글이면 수정/삭제 버튼
                                            if (FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid ==
                                                commentUid)
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.more_vert,
                                                  size: 18,
                                                  color: Colors.grey,
                                                ),
                                                onPressed: () {
                                                  _showCommentOptions(
                                                    commentId,
                                                    commentUid,
                                                    content,
                                                  );
                                                },
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              )
                            : const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: Text(
                                    "댓글을 불러올 수 없습니다.",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 6. 하단 댓글 입력창
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 10,
              bottom:
                  10 +
                  MediaQuery.of(context).viewInsets.bottom +
                  MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  backgroundImage: _currentUserProfileImage.isNotEmpty
                      ? NetworkImage(_currentUserProfileImage)
                      : null,
                  child: _currentUserProfileImage.isEmpty
                      ? const Icon(Icons.person, size: 20, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "댓글 달기...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      onSubmitted: (_) => _addComment(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _addComment,
                  child: const Text(
                    "게시",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("신고 사유 선택"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildReportOption("스팸 또는 홍보성"),
            _buildReportOption("부적절한 콘텐츠"),
            _buildReportOption("욕설 또는 비방"),
            _buildReportOption("기타"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
        ],
      ),
    );
  }

  Widget _buildReportOption(String reason) {
    return ListTile(
      title: Text(reason),
      onTap: () {
        Navigator.pop(context);
        _submitReport(reason);
      },
    );
  }

  Future<void> _submitReport(String reason) async {
    if (widget.postId == null) return;

    try {
      await _firestoreService.reportPost(
        postId: widget.postId!,
        reason: reason,
        targetUserId: widget.postUid,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("신고가 접수되었습니다.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("신고 중 오류가 발생했습니다: $e")));
      }
    }
  }
}

// 사용자 프로필 아바타 위젯 - 프로필 이미지가 없으면 Firestore에서 가져옴
class _UserProfileAvatar extends StatelessWidget {
  final String userId;
  final String userName;
  final String? profileImage;
  final double radius;

  const _UserProfileAvatar({
    required this.userId,
    required this.userName,
    required this.profileImage,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    // 프로필 이미지가 이미 있으면 그대로 사용
    if (profileImage != null && profileImage!.isNotEmpty) {
      return _buildAvatar(context, profileImage!);
    }

    // 프로필 이미지가 없으면 Firestore에서 가져오기
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        String? imageUrl;

        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          imageUrl = userData?['profileImage'] as String?;
        }

        return _buildAvatar(context, imageUrl);
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String? imageUrl) {
    return GestureDetector(
      onTap: () {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null && currentUser.uid == userId) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                userId: userId,
                userName: userName,
                profileImage: imageUrl ?? '',
              ),
            ),
          );
        }
      },
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[300],
        child: imageUrl != null && imageUrl.isNotEmpty
            ? ClipOval(
                child: Image.network(
                  imageUrl,
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.person,
                      size: radius,
                      color: Colors.white,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: radius,
                        height: radius,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                ),
              )
            : Icon(Icons.person, size: radius, color: Colors.white),
      ),
    );
  }
}
