import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import 'home_screen.dart'; // PostItem 사용을 위해 import

class OtherUserPostsDetailScreen extends StatefulWidget {
  final int initialIndex; // 시작할 게시물 인덱스
  final String userId; // 다른 사용자의 UID

  const OtherUserPostsDetailScreen({
    super.key,
    this.initialIndex = 0,
    required this.userId,
  });

  @override
  State<OtherUserPostsDetailScreen> createState() => _OtherUserPostsDetailScreenState();
}

class _OtherUserPostsDetailScreenState extends State<OtherUserPostsDetailScreen> {
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
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('uid', isEqualTo: widget.userId)
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
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('uid', isEqualTo: widget.userId)
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

          var posts = snapshot.data?.docs ?? [];
          
          // 커뮤니티 게시물 제외 (category가 'general' 또는 'companion'인 것 제외)
          posts = posts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final category = data['category'] as String?;
            return category != 'general' && category != 'companion';
          }).toList();
          
          // 클라이언트 측에서 최신순 정렬
          posts.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;
            if (aTime == null || bTime == null) return 0;
            return bTime.compareTo(aTime); // 내림차순 (최신순)
          });

          // 국가 필터 적용
          if (_selectedCountry != null) {
            posts = posts.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final country = data['country'] as String?;
              return country == _selectedCountry;
            }).toList();
          }

          if (posts.isEmpty) {
            return Center(
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
            );
          }

          // PostItem을 ListView로 표시 (인스타그램 피드 방식)
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
                child: ListView.builder(
                  controller: _pageController,
                  itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              
              // Post 모델로 변환
              final post = Post(
                id: posts[index].id,
                uid: postData['uid'] ?? '',
                userName: postData['userName'] ?? 'Unknown',
                location: postData['location'] ?? '',
                title: postData['title'] ?? '',
                content: postData['content'] ?? '',
                likeCount: postData['likeCount'] ?? 0,
                createdAt: postData['createdAt'] as Timestamp?,
                imageUrl: postData['imageUrl'] ?? '',
                imageUrls: postData['imageUrls'] != null
                    ? List<String>.from(postData['imageUrls'])
                    : (postData['imageUrl'] != null && postData['imageUrl'].toString().isNotEmpty
                        ? [postData['imageUrl'].toString()]
                        : []),
                latitude: postData['latitude']?.toDouble(),
                longitude: postData['longitude']?.toDouble(),
                locationName: postData['locationName'],
                category: postData['category'] ?? 'feed',
                country: postData['country'] as String?,
                taggedFriend: postData['taggedFriend'] as String?,
              );

              // home_screen.dart의 PostItem 위젯 재사용
              return PostItem(
                post: post,
                currentUserId: widget.userId,
                onDelete: () {},
                onBlock: () {},
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
