import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import '../widgets/comment_modal.dart';
import '../services/firestore_service.dart';
import 'other_user_profile_screen.dart';
import 'profile_screen.dart';

class PostDetailScreen extends StatefulWidget {
  final Post post;

  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  bool _isLiked = false;
  bool _isSaved = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _profileImageUrl;
  
  // 국기 매핑
  final Map<String, String> _countryFlags = {
    '대한민국': '🇰🇷',
    '일본': '🇯🇵',
    '중국': '🇨🇳',
    '대만': '🇹🇼',
    '홍콩': '🇭🇰',
    '마카오': '🇲🇴',
    '싱가포르': '🇸🇬',
    '태국': '🇹🇭',
    '베트남': '🇻🇳',
    '필리핀': '🇵🇭',
    '말레이시아': '🇲🇾',
    '인도네시아': '🇮🇩',
    '미얀마': '🇲🇲',
    '캄보디아': '🇰🇭',
    '라오스': '🇱🇦',
    '인도': '🇮🇳',
    '네팔': '🇳🇵',
    '몰디브': '🇲🇻',
    '스리랑카': '🇱🇰',
    '미국': '🇺🇸',
    '캐나다': '🇨🇦',
    '멕시코': '🇲🇽',
    '쿠바': '🇨🇺',
    '브라질': '🇧🇷',
    '아르헨티나': '🇦🇷',
    '페루': '🇵🇪',
    '칠레': '🇨🇱',
    '영국': '🇬🇧',
    '프랑스': '🇫🇷',
    '이탈리아': '🇮🇹',
    '스페인': '🇪🇸',
    '독일': '🇩🇪',
    '네덜란드': '🇳🇱',
    '벨기에': '🇧🇪',
    '스위스': '🇨🇭',
    '오스트리아': '🇦🇹',
    '체코': '🇨🇿',
    '헝가리': '🇭🇺',
    '폴란드': '🇵🇱',
    '그리스': '🇬🇷',
    '터키': '🇹🇷',
    '포르투갈': '🇵🇹',
    '아일랜드': '🇮🇪',
    '노르웨이': '🇳🇴',
    '스웨덴': '🇸🇪',
    '덴마크': '🇩🇰',
    '핀란드': '🇫🇮',
    '아이슬란드': '🇮🇸',
    '러시아': '🇷🇺',
    '호주': '🇦🇺',
    '뉴질랜드': '🇳🇿',
    '이집트': '🇪🇬',
    '모로코': '🇲🇦',
    '남아프리카공화국': '🇿🇦',
    '케냐': '🇰🇪',
    '탄자니아': '🇹🇿',
    '아랍에미리트': '🇦🇪',
    '사우디아라비아': '🇸🇦',
    '카타르': '🇶🇦',
    '요르단': '🇯🇴',
    '이스라엘': '🇮🇱',
  };

  // 국가 코드 매핑
  final Map<String, String> _countryCodeMap = {
    '대한민국': 'KOR',
    '일본': 'JPN',
    '중국': 'CHN',
    '대만': 'TWN',
    '홍콩': 'HKG',
    '마카오': 'MAC',
    '싱가포르': 'SGP',
    '태국': 'THA',
    '베트남': 'VNM',
    '필리핀': 'PHL',
    '말레이시아': 'MYS',
    '인도네시아': 'IDN',
    '미얀마': 'MMR',
    '캄보디아': 'KHM',
    '라오스': 'LAO',
    '인도': 'IND',
    '네팔': 'NPL',
    '몰디브': 'MDV',
    '스리랑카': 'LKA',
    '미국': 'USA',
    '캐나다': 'CAN',
    '멕시코': 'MEX',
    '쿠바': 'CUB',
    '브라질': 'BRA',
    '아르헨티나': 'ARG',
    '페루': 'PER',
    '칠레': 'CHL',
    '영국': 'GBR',
    '프랑스': 'FRA',
    '이탈리아': 'ITA',
    '스페인': 'ESP',
    '독일': 'DEU',
    '네덜란드': 'NLD',
    '벨기에': 'BEL',
    '스위스': 'CHE',
    '오스트리아': 'AUT',
    '체코': 'CZE',
    '헝가리': 'HUN',
    '폴란드': 'POL',
    '그리스': 'GRC',
    '터키': 'TUR',
    '포르투갈': 'PRT',
    '아일랜드': 'IRL',
    '노르웨이': 'NOR',
    '스웨덴': 'SWE',
    '덴마크': 'DNK',
    '핀란드': 'FIN',
    '아이슬란드': 'ISL',
    '러시아': 'RUS',
    '호주': 'AUS',
    '뉴질랜드': 'NZL',
    '이집트': 'EGY',
    '모로코': 'MAR',
    '남아프리카공화국': 'ZAF',
    '케냐': 'KEN',
    '탄자니아': 'TZA',
    '아랍에미리트': 'ARE',
    '사우디아라비아': 'SAU',
    '카타르': 'QAT',
    '요르단': 'JOR',
    '이스라엘': 'ISR',
  };

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _checkIfLiked();
    _checkIfSaved();
  }

  Future<void> _loadProfileImage() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.post.uid)
          .get();
      if (userDoc.exists && mounted) {
        setState(() {
          _profileImageUrl = userDoc.data()?['profileImage'];
        });
      }
    } catch (e) {
      // 프로필 이미지 로드 실패 시 기본 아이콘 사용
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final isLiked = await _firestoreService.isPostLiked(widget.post.id);
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
        });
      }
    } catch (e) {
      print('좋아요 확인 실패: $e');
    }
  }

  Future<void> _checkIfSaved() async {
    try {
      final isSaved = await _firestoreService.isPostSaved(widget.post.id);
      if (mounted) {
        setState(() {
          _isSaved = isSaved;
        });
      }
    } catch (e) {
      print('보관 상태 확인 실패: $e');
    }
  }

  Future<void> _toggleLike() async {
    // UI 즉시 업데이트
    setState(() {
      _isLiked = !_isLiked;
    });

    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.id);
      } else {
        await _firestoreService.unlikePost(widget.post.id);
      }
    } catch (e) {
      // 오류 발생 시 상태 되돌리기
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    // UI 즉시 업데이트
    setState(() {
      _isSaved = !_isSaved;
    });

    try {
      if (_isSaved) {
        await _firestoreService.savePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("게시물이 보관함에 저장되었습니다.")),
          );
        }
      } else {
        await _firestoreService.unsavePost(widget.post.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("보관함에서 삭제되었습니다.")),
          );
        }
      }
    } catch (e) {
      // 오류 발생 시 상태 되돌리기
      if (mounted) {
        setState(() {
          _isSaved = !_isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
    }
  }

  void _navigateToProfile() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    if (widget.post.uid == currentUser.uid) {
      // 자신의 프로필로 이동
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    } else {
      // 다른 사용자 프로필로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtherUserProfileScreen(
            userId: widget.post.uid,
            userName: widget.post.userName,
            profileImage: _profileImageUrl ?? '',
          ),
        ),
      );
    }
  }

  Future<void> _navigateToTaggedProfile(String userName) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userName', isEqualTo: userName)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        final userDoc = querySnapshot.docs.first;
        final userId = userDoc.id;
        final userProfileImage = userDoc.data()['profileImage'] as String?;
        final currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser != null && userId == currentUser.uid) {
          // 자신의 프로필로 이동
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else {
          // 다른 사용자 프로필로 이동
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtherUserProfileScreen(
                userId: userId,
                userName: userName,
                profileImage: userProfileImage ?? '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('프로필 이동 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필을 불러올 수 없습니다.')),
        );
      }
    }
  }

  List<Widget> _buildTaggedFriendWidgets(String taggedFriends) {
    final names = taggedFriends.split(',').map((e) => e.trim()).toList();
    final List<Widget> widgets = [];

    for (int i = 0; i < names.length; i++) {
      final name = names[i];
      
      widgets.add(
        GestureDetector(
          onTap: () => _navigateToTaggedProfile(name),
          child: Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      if (i < names.length - 1) {
        widgets.add(
          const Text(
            ", ",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        );
      }
    }

    return widgets;
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
        title: const Text(
          "게시물",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 헤더 (작성자 정보)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: _navigateToProfile,
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey,
                                backgroundImage: _profileImageUrl != null &&
                                        _profileImageUrl!.isNotEmpty
                                    ? NetworkImage(_profileImageUrl!)
                                    : const AssetImage('assets/basic_profile.png')
                                        as ImageProvider,
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        widget.post.userName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      if (widget.post.country != null &&
                                          widget.post.country!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 6),
                                          child: Row(
                                            children: [
                                              Text(
                                                _countryFlags[widget.post.country] ??
                                                    '🌍',
                                                style: const TextStyle(fontSize: 16),
                                              ),
                                              const SizedBox(width: 2),
                                              Text(
                                                _countryCodeMap[
                                                        widget.post.country] ??
                                                    '',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (widget.post.location.isNotEmpty)
                                    Text(
                                      widget.post.location,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  if (widget.post.taggedFriend != null &&
                                      widget.post.taggedFriend!.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      children: [
                                        const Text(
                                          "함께: ",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        ..._buildTaggedFriendWidgets(
                                            widget.post.taggedFriend!),
                                      ],
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 2. 이미지 (크게 보기)
                  Container(
                    width: double.infinity,
                    // 높이 제한 없이 이미지 비율에 맞게 표시
                    constraints: const BoxConstraints(
                      minHeight: 300,
                      maxHeight: 500,
                    ),
                    color: Colors.grey[200],
                    child: widget.post.isFile
                        ? Image.file(
                            File(widget.post.imagePath),
                            fit: BoxFit.contain,
                          )
                        : (widget.post.imageUrl.isNotEmpty
                              ? Image.network(
                                  widget.post.imageUrl,
                                  fit: BoxFit.contain,
                                )
                              : Image.asset(
                                  widget.post.imagePath,
                                  fit: BoxFit.contain,
                                )),
                  ),

                  // 3. 액션 버튼
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        // 좋아요 StreamBuilder
                        StreamBuilder<int>(
                          stream: _firestoreService.getLikeCountStream(widget.post.id),
                          builder: (context, snapshot) {
                            final likeCount = snapshot.data ?? widget.post.likeCount;
                            
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: _toggleLike,
                                  child: Icon(
                                    _isLiked ? Icons.favorite : Icons.favorite_border,
                                    size: 32,
                                    color: _isLiked ? Colors.red : Colors.black,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$likeCount",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        // 댓글 StreamBuilder
                        StreamBuilder<int>(
                          stream: _firestoreService.getCommentCountStream(widget.post.id),
                          builder: (context, snapshot) {
                            final commentCount = snapshot.data ?? 0;
                            
                            return Row(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      useSafeArea: true,
                                      builder: (context) => CommentModal(
                                        postId: widget.post.id,
                                        postTitle: widget.post.title,
                                        postImage: widget.post.imageUrl,
                                      ),
                                    );
                                  },
                                  child: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "$commentCount",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _toggleSave,
                          child: Icon(
                            _isSaved ? Icons.bookmark : Icons.bookmark_border,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // 4. 본문 내용
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.post.content,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "2025.01.01 작성",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. 하단 댓글 바로가기 바 (누르면 댓글창 뜸)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                useSafeArea: true,
                builder: (context) => CommentModal(
                  postId: widget.post.id,
                  postTitle: widget.post.title,
                  postImage: widget.post.imageUrl,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 20, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  const Text("댓글 달기...", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
