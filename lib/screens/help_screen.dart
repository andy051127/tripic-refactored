import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  // 자주 묻는 질문 데이터
  final List<Map<String, String>> _faqList = const [
    {
      "question": "계정 비밀번호를 잊어버렸어요.",
      "answer":
          "로그인 화면 하단의 '비밀번호 찾기'를 눌러 가입한 이메일 주소를 입력하시면 비밀번호 재설정 링크를 보내드립니다.",
    },
    {
      "question": "게시물을 삭제하고 싶어요.",
      "answer":
          "삭제하려는 게시물 우측 상단의 더보기(...) 버튼을 누른 후 '삭제'를 선택하시면 됩니다. 삭제된 게시물은 복구할 수 없습니다.",
    },
    {
      "question": "알림 설정을 변경하고 싶어요.",
      "answer": "마이페이지 > 설정(톱니바퀴) > 알림 메뉴에서 푸시 알림을 켜거나 끌 수 있습니다.",
    },
    {
      "question": "친구를 차단하면 어떻게 되나요?",
      "answer":
          "상대방이 내 게시물을 볼 수 없으며, 나에게 메시지를 보낼 수 없습니다. 차단 목록은 설정 > 차단된 계정에서 관리할 수 있습니다.",
    },
    {
      "question": "여행 계획은 어떻게 공유하나요?",
      "answer":
          "여행 계획 화면에서 '친구 초대' 기능을 사용하여 함께 여행할 친구를 추가하면 계획을 공유하고 같이 수정할 수 있습니다.",
    },
  ];

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
        title: const Text(
          "도움말",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 안내 문구
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: Colors.grey[100],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "무엇을 도와드릴까요?",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "자주 묻는 질문을 확인해보세요.",
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),

            // FAQ 리스트
            Expanded(
              child: ListView.builder(
                itemCount: _faqList.length,
                itemBuilder: (context, index) {
                  final faq = _faqList[index];
                  return ExpansionTile(
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        color: Colors.grey[50],
                        child: Text(
                          faq['answer']!,
                          style: const TextStyle(
                            color: Colors.black87,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
