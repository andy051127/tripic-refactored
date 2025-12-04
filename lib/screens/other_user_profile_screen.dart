import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'travel_record_map_screen.dart';
import 'other_user_posts_detail_screen.dart';
import 'chat_detail_screen.dart';
import 'follow_list_screen.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final String userName;
  final String profileImage;
  final String? userId; // 추가: Firebase UID

  const OtherUserProfileScreen({
    super.key,
    required this.userName,
    required this.profileImage,
    this.userId,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isFollowing = false;
  bool _isLoading = true;
  int _followerCount = 0;
  int _followingCount = 0;
  int _postCount = 0;
  String? _targetUserId;
  String _userBio = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // userId를 이용하여 팔로우 상태 확인
      String targetId = widget.userId ?? '';
      
      print('🔍 OtherUserProfile - 초기 userId: $targetId');
      print('🔍 OtherUserProfile - userName: ${widget.userName}');
      
      // userId가 없으면 userName으로 검색
      if (targetId.isEmpty) {
        // userName 필드로 먼저 검색
        var usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('userName', isEqualTo: widget.userName)
            .limit(1)
            .get();
        
        print('🔍 userName 검색 결과: ${usersSnapshot.docs.length}개');
        
        // 찾지 못했다면 username 필드로 검색
        if (usersSnapshot.docs.isEmpty) {
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('username', isEqualTo: widget.userName)
              .limit(1)
              .get();
          print('🔍 username 검색 결과: ${usersSnapshot.docs.length}개');
        }
        
        // 그래도 찾지 못했다면 name 필드로 검색
        if (usersSnapshot.docs.isEmpty) {
          usersSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('name', isEqualTo: widget.userName)
              .limit(1)
              .get();
          print('🔍 name 검색 결과: ${usersSnapshot.docs.length}개');
        }
        
        if (usersSnapshot.docs.isNotEmpty) {
          targetId = usersSnapshot.docs.first.id;
          print('✅ 사용자 찾음: $targetId');
        } else {
          print('❌ 사용자를 찾을 수 없음');
        }
      }

      if (targetId.isNotEmpty) {
        if (mounted) {
          setState(() {
            _targetUserId = targetId;
          });
        }
        
        print('✅ _targetUserId 설정됨: $_targetUserId');
        
        // 팔로우 상태 확인
        final isFollowing = await _firestoreService.isFollowing(targetId);
        
        // 팔로워/팔로잉 수 가져오기
        final counts = await _firestoreService.getFollowCounts(targetId);
        
        // 게시물 수 가져오기
        final postsSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: targetId)
            .get();

        // 사용자 정보 가져오기 (자기소개 포함)
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(targetId)
            .get();
        
        String userBio = '';
        if (userDoc.exists) {
          final userData = userDoc.data();
          userBio = userData?['bio'] ?? '';
        }

        print('📊 게시물 수: ${postsSnapshot.docs.length}개');

        if (mounted) {
          setState(() {
            _isFollowing = isFollowing;
            _followerCount = counts['followers'] ?? 0;
            _followingCount = counts['following'] ?? 0;
            _postCount = postsSnapshot.docs.length;
            _userBio = userBio;
            _isLoading = false;
          });
        }
      } else {
        print('❌ targetId가 비어있음');
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ 사용자 데이터 로드 실패: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    if (_targetUserId == null) return;

    try {
      if (_isFollowing) {
        await _firestoreService.unfollowUser(_targetUserId!);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _followerCount--;
            globalFollowingCount.value--;
          });
        }
      } else {
        await _firestoreService.followUser(_targetUserId!);
        if (mounted) {
          setState(() {
            _isFollowing = true;
            _followerCount++;
            globalFollowingCount.value++;
          });
        }
      }
    } catch (e) {
      print('팔로우 토글 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류가 발생했습니다: $e')),
        );
      }
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
        centerTitle: false,
        title: Text(
          widget.userName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey,
                            backgroundImage: widget.profileImage.isNotEmpty
                                ? NetworkImage(widget.profileImage)
                                : const AssetImage('assets/basic_profile.png'),
                            child: null,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem("$_postCount", "게시물", onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("아래에서 게시물을 확인하세요! ↓"),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                }),
                                _buildStatItem("$_followerCount", "팔로워", onTap: () {
                                  if (_targetUserId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowListScreen(
                                          userName: widget.userName,
                                          initialIndex: 0,
                                          userId: _targetUserId,
                                        ),
                                      ),
                                    );
                                  }
                                }),
                                _buildStatItem("$_followingCount", "팔로잉", onTap: () {
                                  if (_targetUserId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FollowListScreen(
                                          userName: widget.userName,
                                          initialIndex: 1,
                                          userId: _targetUserId,
                                        ),
                                      ),
                                    );
                                  }
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (_userBio.isNotEmpty)
                        Text(
                          _userBio,
                          style: const TextStyle(fontSize: 14),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _toggleFollow,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      _isFollowing ? Colors.white : Colors.blue,
                                  border: Border.all(
                                    color: _isFollowing
                                        ? Colors.grey.shade300
                                        : Colors.transparent,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Center(
                                  child: Text(
                                    _isFollowing ? "팔로잉" : "팔로우",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: _isFollowing
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (_targetUserId != null) {
                                  // DM 화면으로 이동
                                  try {
                                    final chatRoomId = await _firestoreService.getOrCreateChatRoom(_targetUserId!);
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ChatDetailScreen(
                                            chatRoomId: chatRoomId,
                                            chatPartnerId: _targetUserId!,
                                            chatPartnerName: widget.userName,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    print('채팅방 생성 실패: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('채팅방 생성에 실패했습니다: $e')),
                                      );
                                    }
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Center(
                                  child: Text(
                                    "메시지",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        const TabBar(
                          indicatorColor: Colors.black,
                          labelColor: Colors.black,
                          unselectedLabelColor: Colors.grey,
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on)),
                            Tab(icon: Icon(Icons.map_outlined)),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _buildUserPostsGrid(),
                              _buildUserPostsMap(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildUserPostsGrid() {
    if (_targetUserId == null || _targetUserId!.isEmpty) {
      return const Center(child: Text("사용자 정보를 찾을 수 없습니다."));
    }

    print('📱 _buildUserPostsGrid - _targetUserId: $_targetUserId');

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: _targetUserId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ 게시물 로드 에러: ${snapshot.error}');
          return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];
        
        // 클라이언트 측에서 최신순 정렬
        posts.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['createdAt'] as Timestamp?;
          final bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime); // 내림차순 (최신순)
        });
        
        print('📊 로드된 게시물 수: ${posts.length}개');

        if (posts.isEmpty) {
          return const Center(child: Text("게시물이 없습니다."));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final imageUrl = postData['imageUrl'] ?? '';
            final imageUrls = postData['imageUrls'] as List<dynamic>?;
            
            // 첫 번째 이미지 URL 가져오기
            String displayImage = imageUrl;
            if (imageUrls != null && imageUrls.isNotEmpty) {
              displayImage = imageUrls[0].toString();
            }

            return GestureDetector(
              onTap: () {
                // 게시물 상세 화면으로 이동
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtherUserPostsDetailScreen(
                      initialIndex: index,
                      userId: _targetUserId!,
                    ),
                  ),
                );
              },
              child: Container(
                color: Colors.grey[300],
                child: displayImage.isNotEmpty
                    ? Image.network(
                        displayImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error, color: Colors.grey),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                      )
                    : const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildUserPostsMap() {
    if (_targetUserId == null || _targetUserId!.isEmpty) {
      return const Center(child: Text("사용자 정보를 찾을 수 없습니다."));
    }

    return GestureDetector(
      onTap: () {
        // 전체 화면 지도로 이동 (해당 사용자의 여행 동선과 사진 위치 표시)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TravelRecordMapScreen(
              userId: _targetUserId,
            ),
          ),
        );
      },
      child: Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // 간단한 지도 (현재 위치만 표시)
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(37.5665, 126.9780), // 서울 기본 위치
                  zoom: 12,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                mapToolbarEnabled: false,
              ),
              // 반투명 오버레이와 안내 문구
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map,
                        size: 60,
                        color: Colors.white,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '탭하여 전체 지도 보기',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '이 사용자의 여행 동선과 사진 위치를 확인하세요',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String count, String label, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.translucent,
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
