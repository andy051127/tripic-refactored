import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/firestore_service.dart';
import '../models/message_model.dart';
import 'map_screen.dart';

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
          child: Container(
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
                    Icon(Icons.map, size: 14, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text(
                      "지도에서 보기",
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade700),
                    ),
                  ],
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
