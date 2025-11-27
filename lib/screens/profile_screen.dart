import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/post_model.dart';
import 'settings_screen.dart';
import 'splash_screen.dart';
import 'follow_list_screen.dart';
import 'photo_picker_screen.dart';
import 'member_info_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // [프로필 사진 변경 함수]
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
                      globalProfileImage.value = image.path;
                      isProfileImageFile.value = true;
                    }
                  } catch (e) {
                    print("갤러리 에러: $e");
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
                      globalProfileImage.value = image.path;
                      isProfileImageFile.value = true;
                    }
                  } catch (e) {
                    print("카메라 에러: $e");
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

  // [로그아웃 팝업]
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
              // 1. 다이얼로그 닫기
              Navigator.pop(context);

              // 2. Firebase 로그아웃 실행 (import 필요)
              // await AuthService().signOut(); // auth_service import가 필요하면 추가

              // 3. 로그인 화면으로 이동
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
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
                  Tab(icon: Icon(Icons.person_pin_outlined)),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildMyPostsGrid(),
                    const Center(child: Text("태그된 게시물이 없습니다.")),
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
              // 프로필 사진
              GestureDetector(
                onTap: () => _showImageSourceSelection(context),
                child: Stack(
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: globalProfileImage,
                      builder: (context, path, child) {
                        return CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.grey,
                          backgroundImage: isProfileImageFile.value
                              ? FileImage(File(path))
                              : AssetImage(path) as ImageProvider,
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
                    // 게시물 수
                    ValueListenableBuilder<List<Post>>(
                      valueListenable: globalPostsNotifier,
                      builder: (context, posts, child) {
                        // 내 게시물 필터링
                        final myPosts = posts
                            .where(
                              (p) =>
                                  p.userName == globalUserName.value ||
                                  p.uid ==
                                      FirebaseAuth.instance.currentUser?.uid ||
                                  p.userName == "내 프로필", // 호환성 추가
                            )
                            .toList();

                        return _buildStatItem(
                          "${myPosts.length}",
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
                    // 팔로워 수
                    ValueListenableBuilder<String>(
                      valueListenable: globalFollowerCount,
                      builder: (context, count, child) => _buildStatItem(
                        count,
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
                    // 팔로잉 수
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

  // [수정됨] 이미지를 제대로 표시하는 그리드
  Widget _buildMyPostsGrid() {
    return ValueListenableBuilder<List<Post>>(
      valueListenable: globalPostsNotifier,
      builder: (context, posts, child) {
        // [필터링] 내 게시물만 가져오기
        final myPosts = posts
            .where(
              (p) =>
                  p.userName == globalUserName.value ||
                  p.uid == FirebaseAuth.instance.currentUser?.uid ||
                  p.userName == "내 프로필", // 임시 호환성
            )
            .toList();

        if (myPosts.isEmpty) {
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
          itemCount: myPosts.length,
          itemBuilder: (context, index) {
            final post = myPosts[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                // [복구] 실제 이미지를 표시하는 코드
                post.isFile
                    ? Image.file(File(post.imagePath), fit: BoxFit.cover)
                    : (post.imageUrl.isNotEmpty
                          ? Image.network(
                              post.imageUrl,
                              fit: BoxFit.cover,
                            ) // Firestore 이미지
                          : Image.asset(
                              post.imagePath,
                              fit: BoxFit.cover, // 기본 에셋
                              errorBuilder: (c, o, s) =>
                                  Container(color: Colors.grey[300]),
                            )),

                if (index % 2 == 0)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: Icon(Icons.play_circle_outline, color: Colors.white),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
