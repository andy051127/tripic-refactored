import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../models/message_model.dart';
import '../models/post_model.dart';
import '../models/travel_plan_model.dart';
import 'map_screen.dart';
import 'post_detail_screen.dart';
import 'travel_plan_detail_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String chatPartnerName;
  final String chatPartnerId; // 상대방 uid
  final String? chatRoomId; // 채팅방 ID (없으면 자동 생성)

  const ChatDetailScreen({
    super.key,
    this.chatPartnerName = "알 수 없음",
    required this.chatPartnerId,
    this.chatRoomId,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentChatRoomId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    try {
      // 채팅방 ID가 없으면 생성 또는 가져오기
      if (widget.chatRoomId != null) {
        _currentChatRoomId = widget.chatRoomId;
      } else {
        _currentChatRoomId = await _firestoreService.getOrCreateChatRoom(widget.chatPartnerId);
      }

      // 읽음 처리
      await _firestoreService.markMessagesAsRead(_currentChatRoomId!);

      setState(() => _isLoading = false);
    } catch (e) {
      print("채팅방 초기화 실패: $e");
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendTextMessage() async {
    if (_messageController.text.trim().isEmpty || _currentChatRoomId == null) return;

    try {
      await _firestoreService.sendTextMessage(
        chatRoomId: _currentChatRoomId!,
        receiverId: widget.chatPartnerId,
        content: _messageController.text.trim(),
      );

      _messageController.clear();
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("메시지 전송 실패: $e")),
      );
    }
  }

  Future<void> _sendImageMessage() async {
    if (_currentChatRoomId == null) return;

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        await _firestoreService.sendImageMessage(
          chatRoomId: _currentChatRoomId!,
          receiverId: widget.chatPartnerId,
          localImagePath: image.path,
        );

        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("이미지 전송 실패: $e")),
      );
    }
  }

  Future<void> _sendLocationMessage() async {
    if (_currentChatRoomId == null) return;

    try {
      // MapScreen으로 이동하여 위치 선택
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MapScreen(
            isSelectionMode: true, // 위치 선택 모드
          ),
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        final latitude = result['latitude'] as double;
        final longitude = result['longitude'] as double;
        final locationName = result['locationName'] as String? ?? '선택한 위치';

        await _firestoreService.sendLocationMessage(
          chatRoomId: _currentChatRoomId!,
          receiverId: widget.chatPartnerId,
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
        );

        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("위치 전송 실패: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
          title: Text(
            widget.chatPartnerName,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
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
        title: Text(
          widget.chatPartnerName,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 메시지 리스트
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestoreService.getMessagesStream(_currentChatRoomId!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "메시지가 없습니다.\n첫 메시지를 보내보세요!",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  final messages = snapshot.data!.docs.map((doc) => Message.fromFirestore(doc)).toList();
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == currentUserId;

                      return _buildMessageBubble(message, isMe: isMe);
                    },
                  );
                },
              ),
            ),

            // 하단 입력창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    // 이미지 전송 버튼
                    GestureDetector(
                      onTap: _sendImageMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.image, color: Colors.blue, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 위치 전송 버튼
                    GestureDetector(
                      onTap: _sendLocationMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.orange, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 텍스트 입력창
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _messageController,
                          decoration: const InputDecoration(
                            hintText: "메시지 보내기...",
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 10),
                          ),
                          onSubmitted: (_) => _sendTextMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // 전송 버튼
                    GestureDetector(
                      onTap: _sendTextMessage,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message message, {required bool isMe}) {
    String timeString = '';
    if (message.timestamp != null) {
      timeString = DateFormat('HH:mm').format(message.timestamp!);
    }

    Widget contentWidget;

    switch (message.type) {
      case 'image':
        contentWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.imageUrl != null && message.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.imageUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[200],
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ),
            if (message.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  message.content,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
          ],
        );
        break;

      case 'location':
        contentWidget = GestureDetector(
          onTap: () {
            // 위치를 지도에서 보기
            if (message.latitude != null && message.longitude != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapScreen(
                    initialLocation: LatLng(message.latitude!, message.longitude!),
                    isSelectionMode: false,
                  ),
                ),
              );
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 지도 미리보기
              if (message.latitude != null && message.longitude != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 150,
                    width: 250,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(message.latitude!, message.longitude!),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('location'),
                          position: LatLng(message.latitude!, message.longitude!),
                          infoWindow: InfoWindow(
                            title: message.locationName ?? '위치',
                          ),
                        ),
                      },
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      scrollGesturesEnabled: false,
                      zoomGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.locationName ?? '위치',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "위도: ${message.latitude?.toStringAsFixed(6)}, 경도: ${message.longitude?.toStringAsFixed(6)}",
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.open_in_new, size: 14, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          "탭하여 전체 지도 보기",
                          style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
        break;

      case 'post':
        contentWidget = GestureDetector(
          onTap: () async {
            // 게시물로 이동
            if (message.postId != null) {
              try {
                // Firestore에서 게시물 데이터 가져오기
                final postDoc = await FirebaseFirestore.instance
                    .collection('posts')
                    .doc(message.postId)
                    .get();
                
                if (postDoc.exists && mounted) {
                  // Post 객체로 변환
                  final post = Post.fromMap(
                    postDoc.data() as Map<String, dynamic>,
                    postDoc.id,
                  );
                  
                  // PostDetailScreen으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PostDetailScreen(post: post),
                    ),
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('게시물을 찾을 수 없습니다')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류가 발생했습니다: $e')),
                  );
                }
              }
            }
          },
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 게시물 이미지
                if (message.postImageUrl != null && message.postImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: Image.network(
                      message.postImageUrl!,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: double.infinity,
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, size: 50),
                        );
                      },
                    ),
                  ),
                // 게시물 정보
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.article, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.postTitle ?? '게시물',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '작성자: ${message.postAuthor ?? "알 수 없음"}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.touch_app, size: 14, color: Colors.blue[700]),
                          const SizedBox(width: 4),
                          Text(
                            '탭하여 게시물 보기',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      case 'travelPlan':
        contentWidget = GestureDetector(
          onTap: () async {
            // 여행 계획으로 이동
            print('여행 계획 배너 터치됨');
            print('travelPlanId: ${message.travelPlanId}');
            
            if (message.travelPlanId != null && message.travelPlanId!.isNotEmpty) {
              try {
                // Firestore에서 여행 계획 데이터 가져오기
                print('Firestore에서 여행 계획 조회 중: ${message.travelPlanId}');
                final planDoc = await FirebaseFirestore.instance
                    .collection('travel_plans')
                    .doc(message.travelPlanId)
                    .get();
                
                print('planDoc.exists: ${planDoc.exists}');
                
                if (planDoc.exists && mounted) {
                  // TravelPlan 객체로 변환
                  final plan = TravelPlan.fromMap(
                    planDoc.data() as Map<String, dynamic>,
                    planDoc.id,
                  );
                  
                  print('여행 계획 상세 화면으로 이동: ${plan.title}');
                  
                  // TravelPlanDetailScreen으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TravelPlanDetailScreen(plan: plan),
                    ),
                  );
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('여행 계획을 찾을 수 없습니다')),
                    );
                  }
                }
              } catch (e) {
                print('여행 계획 조회 오류: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('오류가 발생했습니다: $e')),
                  );
                }
              }
            } else {
              print('travelPlanId가 null이거나 비어있습니다');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('여행 계획 정보가 없습니다')),
                );
              }
            }
          },
          child: Container(
            width: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 메인 컨텐츠
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 여행 계획 아이콘 및 제목
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.flight_takeoff,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              message.travelPlanTitle ?? '여행 계획',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // 여행 정보
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.travelPlanCountry ?? '국가 정보 없음',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              message.travelPlanDate ?? '날짜 정보 없음',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 하단 바 (자연스러운 마감)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue[200]!.withOpacity(0.3),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(11),
                      bottomRight: Radius.circular(11),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app, size: 16, color: Colors.blue[700]),
                      const SizedBox(width: 6),
                      Text(
                        '탭하여 여행 계획 보기',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        break;

      default: // text
        contentWidget = Text(
          message.content,
          style: const TextStyle(fontSize: 14, height: 1.4),
        );
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(maxWidth: 280),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFFE0F7FA) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMe ? Colors.cyan[100]! : Colors.green[200]!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: contentWidget,
            ),
            if (timeString.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
                child: Text(
                  timeString,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
