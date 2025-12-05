import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post_model.dart';
import 'home_screen.dart'; // PostItem 사용을 위해 import

class MyPostsDetailScreen extends StatefulWidget {
  final int initialIndex; // 시작할 게시물 인덱스

  const MyPostsDetailScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MyPostsDetailScreen> createState() => _MyPostsDetailScreenState();
}

class _MyPostsDetailScreenState extends State<MyPostsDetailScreen> {
  late PageController _pageController;
  String? _selectedCountry; // 선택된 국가
  List<String> _userCountries = []; // 사용자가 게시물에 사용한 국가 목록

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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadUserCountries();
  }

  // 사용자가 게시물에 사용한 국가 목록 로드
  Future<void> _loadUserCountries() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: currentUser.uid)
          .get();

      final Set<String> countries = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final country = data['country'] as String?;
        final category = data['category'] as String?;
        
        // 커뮤니티 게시물 제외하고 국가 정보가 있는 경우만 추가
        if (country != null && 
            country.isNotEmpty && 
            category != 'general' && 
            category != 'companion') {
          countries.add(country);
        }
      }

      if (mounted) {
        setState(() {
          _userCountries = countries.toList()..sort();
        });
      }
    } catch (e) {
      print('국가 목록 로드 실패: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text("로그인이 필요합니다.", style: TextStyle(color: Colors.grey)),
        ),
      );
    }

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
          "내 게시물",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("오류가 발생했습니다: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var allPosts = snapshot.data?.docs ?? [];

          if (allPosts.isEmpty) {
            return const Center(
              child: Text("작성한 게시물이 없습니다.", style: TextStyle(color: Colors.grey)),
            );
          }

          // 국가 필터 적용
          if (_selectedCountry != null) {
            allPosts = allPosts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final country = data['country'] as String?;
              return country == _selectedCountry;
            }).toList();
          }

          // 클라이언트에서 정렬 (최신순)
          allPosts.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return bTime.compareTo(aTime);
          });

          // Post 객체로 변환
          final posts = allPosts
              .map((doc) => Post.fromMap(
                    doc.data() as Map<String, dynamic>,
                    doc.id,
                  ))
              .toList();

          // 인스타그램 피드처럼 일반 ListView로 변경
          return Column(
            children: [
              // 국가 필터 배너
              if (_userCountries.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _userCountries.length,
                      itemBuilder: (context, index) {
                        final country = _userCountries[index];
                        final isSelected = _selectedCountry == country;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_selectedCountry == country) {
                                _selectedCountry = null; // 토글
                              } else {
                                _selectedCountry = country;
                              }
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF4CA1AF)
                                  : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF4CA1AF)
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  _countryFlags[country] ?? '🌍',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  country,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              // 게시물 리스트
              Expanded(
                child: posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "게시물이 없습니다.",
                              style: TextStyle(color: Colors.grey),
                            ),
                            if (_selectedCountry != null)
                              const SizedBox(height: 8),
                            if (_selectedCountry != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedCountry = null;
                                  });
                                },
                                child: const Text('전체 보기'),
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _pageController,
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          // 홈 화면과 동일한 PostItem 위젯 사용
                          return PostItem(
                            post: post,
                            currentUserId: currentUser.uid,
                            onDelete: () {
                              // 삭제 후 화면 닫기
                              if (posts.length <= 1) {
                                Navigator.pop(context);
                              }
                            },
                            onBlock: () {
                              // 차단 로직 (자기 자신은 차단 불가)
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
