import 'package:flutter/material.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});

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
        // 앱바 타이틀 비움 (디자인 반영)
      ),
      body: Column(
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
                // 핀 예시
                Positioned(top: 40, left: 100, child: _buildMapPin()),
                Positioned(top: 80, left: 150, child: _buildMapPin()),
                Positioned(top: 60, left: 220, child: _buildMapPin()),
                // 점선 예시 (간단히 표현)
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
                _buildMessageBubble(
                  "국가는 재해를 예방하고 그 위험으로부터 국민을 보호하기 위하여 노력하여야 한다. 이 헌법공포 당시의 국회의원의 임기는 제1항에 의한 국회의 최초의 집회일 전일까지로 한다.",
                  isMe: true,
                ),
                _buildMessageBubble("대한민국의 영토는 한반도와 그 ...", isMe: false),
                _buildMessageBubble("대통령은 조약을 ...", isMe: false),
                _buildMessageBubble("국가", isMe: true),
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
                          hintText: "동해물과 백두산이 마르고 닳도록...",
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
          ? Alignment.centerLeft
          : Alignment.centerRight, // 내 메시지 왼쪽(초록), 상대방 오른쪽(파랑) - 사진 기준
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFE8F5E9)
              : const Color(0xFFE0F7FA), // 초록(나) / 파랑(상대)
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isMe ? Colors.green[200]! : Colors.cyan[100]!,
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
