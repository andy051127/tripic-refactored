import 'package:flutter/material.dart';
import 'dart:io'; // 파일 처리를 위해 필수
import 'package:image_picker/image_picker.dart'; // 사진 변경용
import '../models/post_model.dart'; // 데이터 모델 import

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

              // 1. 갤러리에서 선택
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.black),
                title: const Text("갤러리에서 선택"),
                onTap: () async {
                  Navigator.pop(context); // 모달 닫기
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null) {
                      // 전역 변수 업데이트 -> 화면 자동 갱신
                      globalProfileImage.value = image.path;
                      isProfileImageFile.value = true;
                    }
                  } catch (e) {
                    print("갤러리 에러: $e");
                  }
                },
              ),
              const Divider(),

              // 2. 카메라로 촬영
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.black),
                title: const Text("카메라로 촬영"),
                onTap: () async {
                  Navigator.pop(context); // 모달 닫기
                  try {
                    final XFile? image = await picker.pickImage(
                      source: ImageSource.camera,
                    );
                    if (image != null) {
                      // 전역 변수 업데이트 -> 화면 자동 갱신
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "leeeee_kh",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_box_outlined, color: Colors.black),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.menu, color: Colors.black),
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
              // 프로필 사진 (클릭 시 변경 모달 표시)
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
                          // 파일인지 에셋인지에 따라 다른 ImageProvider 사용
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
              // 통계
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ValueListenableBuilder<List<Post>>(
                      valueListenable: globalPostsNotifier,
                      builder: (context, posts, child) =>
                          _buildStatItem("${posts.length}", "게시물"),
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: globalFollowerCount,
                      builder: (context, count, child) =>
                          _buildStatItem(count, "팔로워"),
                    ),
                    ValueListenableBuilder<int>(
                      valueListenable: globalFollowingCount,
                      builder: (context, count, child) =>
                          _buildStatItem("$count", "팔로잉"),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "leeeee_kh",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Text("🇺🇸", style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Text("🇯🇵", style: TextStyle(fontSize: 20)),
              Spacer(),
              Icon(Icons.input, size: 20),
              SizedBox(width: 16),
              Icon(Icons.settings, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_outlined, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Center(
                    child: Icon(Icons.assignment_ind_outlined, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // [오류 수정된 부분] 그리드 뷰 빌더
  Widget _buildMyPostsGrid() {
    return ValueListenableBuilder<List<Post>>(
      valueListenable: globalPostsNotifier,
      builder: (context, posts, child) {
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                // 1. 사진 이미지
                post.isFile
                    ? Image.file(File(post.imagePath), fit: BoxFit.cover)
                    : Image.asset(
                        post.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (c, o, s) =>
                            Container(color: Colors.grey),
                      ),

                // 2. 동영상 아이콘 (컬렉션 if 문법으로 깔끔하게 처리)
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
