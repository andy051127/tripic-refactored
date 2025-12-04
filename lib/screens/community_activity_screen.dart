import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'community_detail_screen.dart';
import 'community_write_screen.dart';

class CommunityActivityScreen extends StatelessWidget {
  final String activityType; // 'comment' 또는 'like'

  const CommunityActivityScreen({super.key, required this.activityType});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
        child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.grey)),
      );
    }

    if (activityType == 'comment') {
      return _buildCommentedPostsList(currentUser.uid);
    } else if (activityType == 'like') {
      return _buildLikedPostsList(currentUser.uid);
    } else {
      return const Center(child: Text("잘못된 활동 타입입니다."));
    }
  }

  // 댓글 단 커뮤니티 게시물 목록
  Widget _buildCommentedPostsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPosts = snapshot.data?.docs ?? [];

        // 커뮤니티 게시물만 필터링 (클라이언트 측)
        final communityPosts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String?;
          return category == 'general' || category == 'companion';
        }).toList();

        // 각 게시물에 대해 사용자가 댓글을 달았는지 확인
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getPostsWithUserComments(communityPosts, userId),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "댓글 단 커뮤니티 게시물이 없습니다.",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final posts = postsSnapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _CommunityActivityItem(
                  postId: posts[index]['postId'],
                  postData: posts[index]['postData'],
                  activityType: activityType,
                );
              },
            );
          },
        );
      },
    );
  }

  // 좋아요 누른 커뮤니티 게시물 목록
  Widget _buildLikedPostsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("오류가 발생했습니다: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allPosts = snapshot.data?.docs ?? [];

        // 커뮤니티 게시물만 필터링 (클라이언트 측)
        final communityPosts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String?;
          return category == 'general' || category == 'companion';
        }).toList();

        // 각 게시물에 대해 사용자가 좋아요를 눌렀는지 확인
        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getPostsWithUserLikes(communityPosts, userId),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
              return const Center(
                child: Text(
                  "좋아요 누른 커뮤니티 게시물이 없습니다.",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final posts = postsSnapshot.data!;

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _CommunityActivityItem(
                  postId: posts[index]['postId'],
                  postData: posts[index]['postData'],
                  activityType: activityType,
                );
              },
            );
          },
        );
      },
    );
  }

  // 사용자가 댓글을 단 게시물 필터링
  Future<List<Map<String, dynamic>>> _getPostsWithUserComments(
    List<QueryDocumentSnapshot> posts,
    String userId,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final post in posts) {
      final postId = post.id;
      final postData = post.data() as Map<String, dynamic>;

      // 해당 게시물의 댓글 중 사용자가 작성한 댓글이 있는지 확인
      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();

      if (commentsSnapshot.docs.isNotEmpty) {
        result.add({'postId': postId, 'postData': postData});
      }
    }

    // 최신순 정렬
    result.sort((a, b) {
      final aTime = a['postData']['createdAt'] as Timestamp?;
      final bTime = b['postData']['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return result;
  }

  // 사용자가 좋아요를 누른 게시물 필터링
  Future<List<Map<String, dynamic>>> _getPostsWithUserLikes(
    List<QueryDocumentSnapshot> posts,
    String userId,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final post in posts) {
      final postId = post.id;
      final postData = post.data() as Map<String, dynamic>;

      // 해당 게시물의 좋아요 중 사용자가 누른 좋아요가 있는지 확인
      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      if (likeDoc.exists) {
        result.add({'postId': postId, 'postData': postData});
      }
    }

    // 최신순 정렬
    result.sort((a, b) {
      final aTime = a['postData']['createdAt'] as Timestamp?;
      final bTime = b['postData']['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return result;
  }
}

class _CommunityActivityItem extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> postData;
  final String activityType;

  const _CommunityActivityItem({
    required this.postId,
    required this.postData,
    required this.activityType,
  });

  String _getTimeAgo(Timestamp? timestamp) {
    if (timestamp == null) return '방금 전';

    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('yyyy.MM.dd').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
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
                  _editPost(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text("삭제하기", style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePost(context);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editPost(BuildContext context) async {
    try {
      // Firestore에서 최신 데이터 가져오기
      final docSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .get();

      if (!docSnapshot.exists) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("게시물을 찾을 수 없습니다.")));
        }
        return;
      }

      final data = docSnapshot.data()!;

      if (context.mounted) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityWriteScreen(
              isEdit: true,
              postId: postId,
              initialData: data,
            ),
          ),
        );

        // 수정 완료 후 돌아왔을 때
        if (result == true && context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("게시글이 수정되었습니다.")));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("오류 발생: $e")));
      }
    }
  }

  Future<void> _deletePost(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("게시물 삭제"),
        content: const Text("정말로 이 게시물을 삭제하시겠습니까?"),
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

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(postId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("게시물이 삭제되었습니다.")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("삭제 실패: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final title = postData['title'] ?? '제목 없음';
    final content = postData['content'] ?? '';
    final category = postData['category'] ?? 'general';
    final createdAt = postData['createdAt'] as Timestamp?;
    final imageUrl = postData['imageUrl'] ?? '';
    final imageUrls = postData['imageUrls'] as List<dynamic>?;
    final postUid = postData['uid'] ?? '';

    // 본인 게시물인지 확인
    final isMyPost = currentUser != null && postUid == currentUser.uid;

    // 첫 번째 이미지 URL 가져오기
    String? displayImage = imageUrl.isNotEmpty ? imageUrl : null;
    if (displayImage == null && imageUrls != null && imageUrls.isNotEmpty) {
      displayImage = imageUrls[0].toString();
    }

    // 카테고리 표시
    String categoryText = category == 'companion' ? '동행' : '게시글';
    Color categoryColor = category == 'companion'
        ? const Color(0xFF4CA1AF)
        : Colors.grey;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      onTap: () {
        // 상세 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CommunityDetailScreen(
              name: postData['userName'] ?? postData['name'] ?? 'Unknown',
              location: postData['location'] ?? '',
              title: title,
              content: content,
              stats:
                  '${postData['likes'] ?? 0} 좋아요 · ${postData['comments'] ?? 0} 댓글',
              imageUrl: displayImage,
              createdAt: createdAt?.toDate() ?? DateTime.now(),
              postUid: postUid,
              postId: postId,
              category: category,
            ),
          ),
        );
      },
      leading: displayImage != null
          ? Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  displayImage,
                  fit: BoxFit.cover,
                  errorBuilder: (c, o, s) => Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
            )
          : Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: const Icon(Icons.article, color: Colors.grey),
            ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: categoryColor, width: 1),
            ),
            child: Text(
              categoryText,
              style: TextStyle(
                fontSize: 11,
                color: categoryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _getTimeAgo(createdAt),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
      trailing: isMyPost
          ? IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.grey),
              onPressed: () => _showMoreOptions(context),
            )
          : null,
    );
  }
}

// 커뮤니티 활동 리스트 (섹션용)
class CommunityActivityList extends StatelessWidget {
  final String activityType;

  const CommunityActivityList({super.key, required this.activityType});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (activityType == 'comment') {
      return _buildCommentedPostsList(currentUser.uid);
    } else if (activityType == 'like') {
      return _buildLikedPostsList(currentUser.uid);
    } else {
      return const Center(child: Text("잘못된 활동 타입입니다."));
    }
  }

  Widget _buildCommentedPostsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("오류가 발생했습니다: ${snapshot.error}")),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allPosts = snapshot.data?.docs ?? [];
        final communityPosts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String?;
          return category == 'general' || category == 'companion';
        }).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getPostsWithUserComments(communityPosts, userId),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "댓글 단 커뮤니티 게시물이 없습니다.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final posts = postsSnapshot.data!;

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _CommunityActivityItem(
                  postId: posts[index]['postId'],
                  postData: posts[index]['postData'],
                  activityType: activityType,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLikedPostsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("오류가 발생했습니다: ${snapshot.error}")),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final allPosts = snapshot.data?.docs ?? [];
        final communityPosts = allPosts.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] as String?;
          return category == 'general' || category == 'companion';
        }).toList();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getPostsWithUserLikes(communityPosts, userId),
          builder: (context, postsSnapshot) {
            if (postsSnapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!postsSnapshot.hasData || postsSnapshot.data!.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    "좋아요 누른 커뮤니티 게시물이 없습니다.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            final posts = postsSnapshot.data!;

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: posts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _CommunityActivityItem(
                  postId: posts[index]['postId'],
                  postData: posts[index]['postData'],
                  activityType: activityType,
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _getPostsWithUserComments(
    List<QueryDocumentSnapshot> posts,
    String userId,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final post in posts) {
      final postId = post.id;
      final postData = post.data() as Map<String, dynamic>;

      final commentsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .where('uid', isEqualTo: userId)
          .limit(1)
          .get();

      if (commentsSnapshot.docs.isNotEmpty) {
        result.add({'postId': postId, 'postData': postData});
      }
    }

    result.sort((a, b) {
      final aTime = a['postData']['createdAt'] as Timestamp?;
      final bTime = b['postData']['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return result;
  }

  Future<List<Map<String, dynamic>>> _getPostsWithUserLikes(
    List<QueryDocumentSnapshot> posts,
    String userId,
  ) async {
    final result = <Map<String, dynamic>>[];

    for (final post in posts) {
      final postId = post.id;
      final postData = post.data() as Map<String, dynamic>;

      final likeDoc = await FirebaseFirestore.instance
          .collection('posts')
          .doc(postId)
          .collection('likes')
          .doc(userId)
          .get();

      if (likeDoc.exists) {
        result.add({'postId': postId, 'postData': postData});
      }
    }

    result.sort((a, b) {
      final aTime = a['postData']['createdAt'] as Timestamp?;
      final bTime = b['postData']['createdAt'] as Timestamp?;
      if (aTime == null || bTime == null) return 0;
      return bTime.compareTo(aTime);
    });

    return result;
  }
}
