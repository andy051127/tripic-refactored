import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  final String chatPartnerName; // 대화 상대방 이름

  const ChatDetailScreen({
    super.key,
    this.chatPartnerName = "알 수 없음", // [수정] 기본값 설정으로 오류 방지
  });

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
        centerTitle: true,
        // 상단 가운데 상대방 이름 표시
        title: Text(
          chatPartnerName,
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
          // 1. 상단 지도 영역
          Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Stack(
              children: [
                const Center(child: Text("지도 경로 표시 (API 연동)")),
                Positioned(top: 40, left: 100, child: _buildMapPin()),
                Positioned(top: 80, left: 150, child: _buildMapPin()),
                Positioned(top: 60, left: 220, child: _buildMapPin()),
                const Center(
                  child: Icon(
                    Icons.linear_scale,
                    color: Colors.black,
                    size: 100,
                  ),
                ),
              ],
            ),
          ),

          // 2. 채팅 메시지 리스트
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildMessageBubble("안녕하세요! 여행 계획은 잘 세우셨나요?", isMe: false),
                _buildMessageBubble("네, 거의 다 짰어요. 일정 공유해드릴까요?", isMe: true),
                _buildMessageBubble("좋아요! 지도 보고 같이 이야기해요.", isMe: false),
              ],
            ),
          ),

          // 3. 하단 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "메시지 보내기...",
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
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
                ],
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildMapPin() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: const Icon(Icons.circle, color: Colors.red, size: 8),
    );
  }

  Widget _buildMessageBubble(String text, {required bool isMe}) {
    return Align(
      alignment: isMe
          ? Alignment.centerRight
          : Alignment.centerLeft, // 내 메시지 오른쪽, 상대방 왼쪽
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFE0F7FA)
              : const Color(0xFFE8F5E9), // 색상 구분
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
        child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
      ),
    );
  }
}
