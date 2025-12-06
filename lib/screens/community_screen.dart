import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'community_detail_screen.dart';
import 'community_write_screen.dart';
import 'community_search_screen.dart';
import 'profile_screen.dart';
import 'other_user_profile_screen.dart';
import '../models/post_model.dart'; // 통합된 Post 모델 사용
import '../services/firestore_service.dart';
import 'package:intl/intl.dart'; // 날짜 포맷용

// [수정됨] 커뮤니티 게시글 데이터 모델 (createdAt 추가)
class CommunityPost {
  final String name;
  final String location;
  final String title;
  final String content;
  final String stats;
  final String? imageUrl;
  final bool isFileImage;
  final String category;
  final DateTime createdAt; // [추가] 작성 시간
  final String uid; // [추가] 작성자 uid
  final String id; // [추가] 게시물 id
  final String? travelPlanId; // 여행 계획 ID
  final String? travelPlanTitle; // 여행 계획 제목
  final String? travelPlanDate; // 여행 계획 날짜
  final String? travelPlanCountry; // 여행 계획 국가
  final String? userProfileImage; // 프로필 이미지

  CommunityPost({
    required this.name,
    required this.location,
    required this.title,
    required this.content,
    required this.stats,
    this.imageUrl,
    this.isFileImage = false,
    required this.category,
    DateTime? createdAt, // 선택적 매개변수
    required this.uid,
    required this.id,
    this.travelPlanId,
    this.travelPlanTitle,
    this.travelPlanDate,
    this.travelPlanCountry,
    this.userProfileImage,
  }) : createdAt = createdAt ?? DateTime.now(); // 없으면 현재 시간
}

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _viewMode = 'split'; // split, post, companion
  final FirestoreService _firestoreService = FirestoreService();

  void _toggleView(String mode) {
    setState(() {
      if (_viewMode == mode) {
        _viewMode = 'split';
      } else {
        _viewMode = mode;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "커뮤니티",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunityWriteScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.black),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CommunitySearchScreen(),
                ),
              );
            },
            icon: const Icon(Icons.search, color: Colors.black),
          ),
          const SizedBox(width: 10),
        ],
      ),
      // StreamBuilder로 데이터 수신
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("오류 발생"));
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data?.docs ?? [];

          // Firestore 데이터를 CommunityPost로 변환
          final allPosts = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // userProfileImage가 없거나 빈 문자열인 경우 uid로 프로필 정보 가져오기
            String? profileImage = data['userProfileImage'];
            if ((profileImage == null || profileImage.isEmpty) &&
                data['uid'] != null) {
              // 비동기 작업을 동기적으로 처리할 수 없으므로
              // uid를 통해 나중에 가져올 수 있도록 null로 유지
              profileImage = null;
            }

            return CommunityPost(
              name: data['userName'] ?? 'Unknown',
              location: data['location'] ?? '',
              title: data['title'] ?? '',
              content: data['content'] ?? '',
              stats: "${data['likeCount'] ?? 0} · 0 · 0",
              imageUrl: data['imageUrl'],
              category: data['category'] ?? 'general',
              createdAt: (data['createdAt'] as Timestamp?)
                  ?.toDate(), // Firestore Timestamp -> DateTime 변환
              uid: data['uid'] ?? '',
              id: doc.id,
              travelPlanId: data['travelPlanId'],
              travelPlanTitle: data['travelPlanTitle'],
              travelPlanDate: data['travelPlanDate'],
              travelPlanCountry: data['travelPlanCountry'],
              userProfileImage: profileImage,
            );
          }).toList();

          // 카테고리별 분류
          final generalPosts = allPosts
              .where((p) => p.category == 'general')
              .toList();
          final companionPosts = allPosts
              .where((p) => p.category == 'companion')
              .toList();

          // 통합된 리스트 생성 (홈 화면처럼 연속 스크롤)
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: (_viewMode == 'split'
                ? generalPosts.length +
                      companionPosts.length +
                      3 // 헤더 2개 + 구분선 1개
                : _viewMode == 'post'
                ? generalPosts.length +
                      1 // 헤더 1개
                : companionPosts.length + 1), // 헤더 1개
            itemBuilder: (context, index) {
              // split 모드
              if (_viewMode == 'split') {
                // 게시글 헤더
                if (index == 0) {
                  return GestureDetector(
                    onTap: () => _toggleView('post'),
                    child: Container(
                      color: Colors.white,
                      child: _sectionHeader("게시글", isExpanded: false),
                    ),
                  );
                }
                // 게시글 아이템들
                if (index <= generalPosts.length) {
                  return _postItem(context, post: generalPosts[index - 1]);
                }
                // 구분선
                if (index == generalPosts.length + 1) {
                  return const Divider(
                    thickness: 8,
                    height: 8,
                    color: Color(0xFFF5F5F5),
                  );
                }
                // 동행 헤더
                if (index == generalPosts.length + 2) {
                  return GestureDetector(
                    onTap: () => _toggleView('companion'),
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.only(top: 10.0, bottom: 5),
                      child: _sectionHeader(
                        "동행",
                        isExpanded: false,
                        showArrow: true,
                      ),
                    ),
                  );
                }
                // 동행 아이템들
                return _postItem(
                  context,
                  post: companionPosts[index - generalPosts.length - 3],
                );
              }
              // post 모드 (게시글만)
              else if (_viewMode == 'post') {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () => _toggleView('post'),
                    child: Container(
                      color: Colors.white,
                      child: _sectionHeader("게시글", isExpanded: true),
                    ),
                  );
                }
                if (generalPosts.isEmpty && index == 1) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("게시글이 없습니다."),
                    ),
                  );
                }
                return _postItem(context, post: generalPosts[index - 1]);
              }
              // companion 모드 (동행만)
              else {
                if (index == 0) {
                  return GestureDetector(
                    onTap: () => _toggleView('companion'),
                    child: Container(
                      color: Colors.white,
                      child: _sectionHeader(
                        "동행",
                        isExpanded: true,
                        showArrow: true,
                      ),
                    ),
                  );
                }
                if (companionPosts.isEmpty && index == 1) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: Text("동행 글이 없습니다."),
                    ),
                  );
                }
                return _postItem(context, post: companionPosts[index - 1]);
              }
            },
          );
        },
      ),
    );
  }

  Widget _sectionHeader(
    String title, {
    bool showViewAll = true,
    bool isExpanded = false,
    bool showArrow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (isExpanded || showArrow)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_up : null,
                size: 20,
                color: Colors.grey,
              ),
            ),
          const Spacer(),
          if (showViewAll)
            const Text(
              "전체보기",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _postItem(BuildContext context, {required CommunityPost post}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              name: post.name,
              location: post.location,
              title: post.title,
              content: post.content,
              stats: post.stats,
              imageUrl: post.imageUrl,
              createdAt: post.createdAt, // [추가] 작성일 전달
              postUid: post.uid,
              postId: post.id,
              category: post.category, // [추가] 카테곣0리 전달
              travelPlanId: post.travelPlanId, // 여행 계획 ID 전달
              travelPlanTitle: post.travelPlanTitle, // 여행 계획 제목 전달
              travelPlanDate: post.travelPlanDate, // 여행 계획 날짜 전달
              travelPlanCountry: post.travelPlanCountry, // 여행 계획 국가 전달
              userProfileImage: post.userProfileImage, // 프로필 이미지 전달
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _UserProfileAvatar(
                          userId: post.uid,
                          userName: post.name,
                          profileImage: post.userProfileImage,
                          radius: 12,
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            if (currentUser != null &&
                                currentUser.uid == post.uid) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ProfileScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherUserProfileScreen(
                                    userId: post.uid,
                                    userName: post.name,
                                    profileImage: post.userProfileImage ?? '',
                                  ),
                                ),
                              );
                            }
                          },
                          child: Text(
                            post.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                        ),
                        if (post.location.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Text(
                              post.location,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      post.content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF424242),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      color: Colors.grey[200],
                      width: 80,
                      height: 80,
                      child: Image.network(
                        post.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) => const Icon(Icons.image),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
