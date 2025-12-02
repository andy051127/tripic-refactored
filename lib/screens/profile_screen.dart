import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'follow_list_screen.dart';
import 'photo_picker_screen.dart';
import 'member_info_screen.dart';
import 'map_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFollowCounts();
  }

  // Firestore에서 사용자 데이터 불러오기
  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists && mounted) {
          final data = userDoc.data();
          if (data != null) {
            // 전역 변수 업데이트
            globalUserName.value = data['userName'] ?? data['username'] ?? data['name'] ?? 'Unknown';
            globalUserBio.value = data['bio'] ?? 'Traveler ✈️';
            globalUserEmail.value = data['email'] ?? user.email ?? '';
            globalUserPhone.value = data['phoneNumber'] ?? '';
            
            // 프로필 이미지가 있으면 업데이트
            if (data['profileImage'] != null && data['profileImage'].toString().isNotEmpty) {
              globalProfileImage.value = data['profileImage'];
              isProfileImageFile.value = false; // 네트워크 이미지
            }
          }
        }
      } catch (e) {
        print('사용자 데이터 로드 실패: $e');
      }
    }
  }

  Future<void> _loadFollowCounts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final counts = await _firestoreService.getFollowCounts(user.uid);
      if (mounted) {
        setState(() {
          _followerCount = counts['followers'] ?? 0;
          _followingCount = counts['following'] ?? 0;
          globalFollowerCount.value = _followerCount;
          globalFollowingCount.value = _followingCount;
        });
      }
    }
  }

  Future<void> _showImageSourceSelection(BuildContext context) async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "프로필 사진 변경",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text("갤러리에서 선택"),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      // 로컬 상태 업데이트
                      globalProfileImage.value = image.path;
                      isProfileImageFile.value = true;
                      
                      // Firestore에 업로드 및 URL 저장
                      final downloadUrl = await _firestoreService.uploadProfileImage(image.path);
                      if (mounted) {
                        globalProfileImage.value = downloadUrl;
                        isProfileImageFile.value = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('프로필 사진이 변경되었습니다')),
                        );
                      }
                    }
                  } catch (e) {
                    print("갤러리 에러: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('사진 업로드 실패: $e')),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black),
                title: const Text("카메라로 촬영"),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      // 로컬 상태 업데이트
                      globalProfileImage.value = image.path;
                      isProfileImageFile.value = true;
                      
                      // Firestore에 업로드 및 URL 저장
                      final downloadUrl = await _firestoreService.uploadProfileImage(image.path);
                      if (mounted) {
                        globalProfileImage.value = downloadUrl;
                        isProfileImageFile.value = false;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('프로필 사진이 변경되었습니다')),
                        );
                      }
                    }
                  } catch (e) {
                    print("카메라 에러: $e");
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('사진 업로드 실패: $e')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "로그아웃",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text("정말 로그아웃 하시겠습니까?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              "로그아웃",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: ValueListenableBuilder<String>(
          valueListenable: globalUserName,
          builder: (context, name, _) => Text(
            name,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PhotoPickerScreen(),
                ),
              );
            },
            icon: const Icon(
              Icons.add_box_outlined,
              color: Colors.black,
              size: 26,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemberInfoScreen(),
                ),
              );
            },
            icon: const Icon(Icons.menu, color: Colors.black, size: 26),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: DefaultTabController(
        length: 2,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileHeader(context),
                ]),
              ),
            ];
          },
          body: Column(
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
                    _buildMyPostsGrid(),
                    _buildMyPostsMap(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showImageSourceSelection(context),
                child: Stack(
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: globalProfileImage,
                      builder: (context, path, child) {
                        ImageProvider imageProvider;
                        
                        if (path.isEmpty || path == "assets/logo.png") {
                          // 기본 이미지
                          imageProvider = const AssetImage("assets/basic_profile.png");
                        } else if (isProfileImageFile.value) {
                          // 로컬 파일
                          imageProvider = FileImage(File(path));
                        } else if (path.startsWith('http')) {
                          // 네트워크 이미지 (Firebase Storage URL)
                          imageProvider = NetworkImage(path);
                        } else {
                          // Asset 이미지
                          imageProvider = AssetImage(path);
                        }
                        
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey,
                          backgroundImage: imageProvider,
                          child: null,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser != null
                          ? FirebaseFirestore.instance
                              .collection('posts')
                              .where('uid', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                              .snapshots()
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        final postCount = snapshot.data?.docs.length ?? 0;
                        return _buildStatItem(
                          "$postCount",
                          "게시물",
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("아래에서 게시물을 확인하세요! ↓"),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: globalFollowerCount,
                      builder: (context, count, child) => _buildStatItem(
                        "$count",
                        "팔로워",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userName: globalUserName.value,
                                initialIndex: 0,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: globalFollowingCount,
                      builder: (context, count, child) => _buildStatItem(
                        "$count",
                        "팔로잉",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userName: globalUserName.value,
                                initialIndex: 1,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<String>(
            valueListenable: globalUserName,
            builder: (context, name, _) => Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          ValueListenableBuilder<String>(
            valueListenable: globalUserBio,
            builder: (context, bio, _) =>
                Text(bio, style: const TextStyle(fontSize: 14)),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text("🇺🇸", style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              const Text("🇯🇵", style: TextStyle(fontSize: 20)),
              const Spacer(),
              IconButton(
                onPressed: () => _showLogoutDialog(context),
                icon: const Icon(Icons.input, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
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

  Widget _buildMyPostsGrid() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Center(
        child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.grey)),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ 내 게시물 로드 에러: ${snapshot.error}');
          return Center(
            child: Text("오류가 발생했습니다: ${snapshot.error}"),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final posts = snapshot.data?.docs ?? [];
        
        print('📊 내 게시물 수: ${posts.length}개');

        if (posts.isEmpty) {
          return const Center(
            child: Text("작성한 게시물이 없습니다.", style: TextStyle(color: Colors.grey)),
          );
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
                // TODO: 게시물 상세 화면으로 이동
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  displayImage.isNotEmpty
                      ? Image.network(
                          displayImage,
                          fit: BoxFit.cover,
                          errorBuilder: (c, o, s) => Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.grey),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                  if (index % 2 == 0)
                    const Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(Icons.play_circle_outline, color: Colors.white),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyPostsMap() {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Center(
        child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.grey)),
      );
    }

    return GestureDetector(
      onTap: () {
        // 전체 화면 지도로 이동 (내 게시물만 표시)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              userId: currentUser.uid,
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
                        '내 게시물 위치를 확인하세요',
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
}
