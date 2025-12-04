import 'package:flutter/material.dart';
import 'chat_detail_screen.dart'; // DM 이동용
import 'package:intl/intl.dart'; // 날짜 포맷용
import '../models/activity_model.dart'; // 활동 내역 저장용
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'community_write_screen.dart'; // 수정 화면용
import '../services/firestore_service.dart'; // 팔로우 기능용

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
  });

  @override
  State<CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<CommunityDetailScreen> {
  // 좋아요 상태
  bool _isLiked = false;
  int _likeCount = 0;

  // 댓글 상태
  final TextEditingController _commentController = TextEditingController();

  // 팔로우 상태
  bool _isFollowing = false;
  final FirestoreService _firestoreService = FirestoreService();

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
            _likeCount--;
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
        margin: const EdgeInsets.all(20),
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
                  // 타인 게시물: 팔로우/언팔로우, 신고
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("신고가 접수되었습니다.")),
                      );
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
          IconButton(
            onPressed: _showMoreOptions,
            icon: const Icon(Icons.more_vert, color: Colors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
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
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.grey,
                            backgroundImage: AssetImage('assets/logo.png'),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                            onTap: () {
                              // TODO: 작성자 uid를 파라미터로 받아서 전달해야 함
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatDetailScreen(
                                    chatPartnerName: widget.name,
                                    chatPartnerId:
                                        '', // 임시: 빈 문자열 (나중에 uid 추가 필요)
                                  ),
                                ),
                              );
                            },
                            child: const Icon(Icons.near_me_outlined, size: 28),
                          ),

                          const Spacer(),
                          const Icon(Icons.bookmark_border, size: 28),
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
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
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
                                            style: TextStyle(
                                              color: Colors.grey,
                                            ),
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
                                            commentData['userName'] ??
                                            'Unknown';
                                        final content =
                                            commentData['content'] ?? '';
                                        final createdAt =
                                            commentData['createdAt']
                                                as Timestamp?;
                                        final userProfileImage =
                                            commentData['userProfileImage'] ??
                                            '';

                                        // 시간 포맷
                                        String timeAgo = '방금 전';
                                        if (createdAt != null) {
                                          final now = DateTime.now();
                                          final date = createdAt.toDate();
                                          final difference = now.difference(
                                            date,
                                          );

                                          if (difference.inDays > 0) {
                                            timeAgo = '${difference.inDays}일 전';
                                          } else if (difference.inHours > 0) {
                                            timeAgo =
                                                '${difference.inHours}시간 전';
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
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor:
                                                    Colors.grey[300],
                                                backgroundImage:
                                                    userProfileImage.isNotEmpty
                                                    ? NetworkImage(
                                                        userProfileImage,
                                                      )
                                                    : null,
                                                child: userProfileImage.isEmpty
                                                    ? const Icon(
                                                        Icons.person,
                                                        size: 20,
                                                        color: Colors.white,
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Text(
                                                          userName,
                                                          style:
                                                              const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 14,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Text(
                                                          timeAgo,
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.grey,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
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
      ),
    );
  }
}
