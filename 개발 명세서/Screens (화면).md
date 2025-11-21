앱의 각 페이지를 담당하는 UI 파일들입니다. 기능별로 분류했습니다.

인증 (Auth)

lib/screens/splash_screen.dart: 앱 실행 시 로고를 보여주는 로딩 화면입니다. 2초 후 로그인 화면으로 자동 이동합니다.

lib/screens/login_screen.dart: 로그인 화면입니다. 이메일/비밀번호 입력 및 소셜 로그인 버튼(카카오, 네이버, 구글 - UI만 구현)을 제공하며, 회원가입 화면으로 이동할 수 있습니다.

lib/screens/signup_screen.dart: 회원가입 화면입니다. 사용자 정보를 입력받는 폼을 제공합니다.



메인 탭 (Main Tabs - Bottom Navigation)

lib/screens/home_screen.dart (탭 1): 홈 피드입니다.

상단: 지도 배너(클릭 시 지도 상세 이동), 검색 버튼(통합 검색 이동), 메시지 버튼(메시지 목록 이동).

중앙: PostItem 위젯을 리스트로 보여줍니다. 각 게시물에서 좋아요, 댓글, DM, 더보기(신고/차단/숨기기/팔로우) 기능을 수행할 수 있습니다.

하단: 네비게이션 바를 통해 5개의 주요 탭으로 이동합니다.

lib/screens/travel_plan_screen.dart (탭 2): 여행 계획 목록입니다.

계획이 없으면 추가 안내 문구를, 있으면 계획 카드 리스트를 보여줍니다.

+ 버튼이나 하단 추가 버튼을 통해 여행 계획 설정 화면으로 이동합니다.

lib/screens/community_screen.dart (탭 4): 커뮤니티입니다.

'게시글'과 '동행' 탭으로 나뉘어 있으며, 검색 기능을 제공합니다.

+ 버튼을 통해 커뮤니티 전용 글쓰기 화면으로 이동합니다.

lib/screens/profile_screen.dart (탭 5): **마이페이지(내 프로필)**입니다.

내 정보(사진, 이름, 소개, 국기)와 통계(게시물, 팔로워, 팔로잉)를 보여줍니다.

프로필 사진을 클릭하여 변경할 수 있습니다.

내가 올린 게시물 사진들을 그리드 뷰로 보여줍니다.

+ 버튼(사진 선택), 햄버거 버튼(회원 정보), 설정 버튼(설정 메뉴), 로그아웃 버튼 기능을 제공합니다.



여행 계획 상세 (Travel Plan Details)

lib/screens/travel_plan_setup_screen.dart: 여행 계획을 세부적으로 설정하는 화면입니다.

날짜(달력 모달), 국가(검색/지도 모달), 비행편(입력/시간선택 모달), 숙소, 인원(친구목록 연동), 준비물/리스트(입력/체크박스 모달) 등 다양한 입력 방식을 제공합니다.



게시물 작성 (Create Post)

lib/screens/photo_picker_screen.dart (Step 1): 갤러리나 카메라를 통해 사진을 선택하는 화면입니다.

lib/screens/photo_editor_screen.dart (Step 2): 선택한 사진을 확인하고, 추가/삭제하거나 친구를 태그하는 편집 화면입니다.

lib/screens/write_post_screen.dart (Step 3): 제목과 내용을 입력하고 최종적으로 업로드하는 화면입니다. 업로드 시 홈 피드에 게시물이 추가됩니다.

lib/screens/community_write_screen.dart: 커뮤니티 전용 글쓰기 화면입니다. 사진, 장소(지도), 날짜(달력), 인원(친구목록)을 한 화면에서 설정하고 게시합니다.



메시지 & 친구 (Message & Friends)

lib/screens/message_list_screen.dart: 메시지 목록 화면입니다. 채팅방 리스트와 즐겨찾기를 보여줍니다.

lib/screens/friend_list_screen.dart: 친구 목록 화면입니다. 두 가지 모드로 작동합니다.

선택 모드: 여행 계획 인원 추가나 공개 범위 설정 시 여러 명을 선택하여 반환합니다.

일반 모드: 친구를 클릭하면 해당 친구와의 채팅방으로 이동합니다.

lib/screens/chat_detail_screen.dart: 채팅방 상세 화면입니다. 상단에 지도 경로가 표시되고, 상대방 이름이 앱바에 나옵니다.



지도 (Map)

lib/screens/map_detail_screen.dart: 전체 화면 지도입니다. 내 현재 위치를 표시하고, 친구들이 글을 올린 위치에 마커를 찍어 보여줍니다. 마커 클릭 시 미리보기가 뜹니다.

lib/screens/map_search_screen.dart: 지도 검색 화면입니다. 지도가 메인이며, 상단 검색창을 통해 친구 이름이나 지역명으로 지도를 이동시킵니다.



설정 & 정보 (Settings & Info)

lib/screens/settings_screen.dart: 설정 메뉴 리스트 화면입니다. 계정공개범위, 차단된계정, 활동, 알림, 정보 등 다양한 설정 메뉴로 이동합니다. ('화면' 메뉴는 삭제됨)

lib/screens/notification_settings_screen.dart: 푸시 알림을 켜고 끄는 스위치가 있는 화면입니다.

lib/screens/privacy_settings_screen.dart: 게시물 공개 범위를 설정하는 화면입니다. (전체/친구만/친한친구/특정친구 선택)

lib/screens/blocked_users_screen.dart: 차단된 사용자 목록을 관리하고 해제하는 화면입니다.

lib/screens/activity_screen.dart: 내 활동 내역(댓글, 좋아요, 스크랩 등)을 탭으로 구분하여 보여주는 화면입니다.

lib/screens/saved_posts_screen.dart: 보관함(스크랩)에 저장된 게시물을 그리드로 보여주는 화면입니다.

lib/screens/language_translation_screen.dart: 언어 번역 기능을 시뮬레이션하는 화면입니다.

lib/screens/help_screen.dart: 자주 묻는 질문(FAQ)을 아코디언 형태로 보여주는 도움말 화면입니다.

lib/screens/information_screen.dart: 앱 정보(버전, 개발사 등)를 보여주는 화면입니다. (내 정보 수정 화면에서 변경됨)

lib/screens/member_info_screen.dart: 햄버거 버튼 클릭 시 나오는 회원 정보 상세 리스트 화면입니다.



기타 (Others)

lib/screens/search_screen.dart: 통합 검색 화면입니다. 사용자 계정을 검색하여 타인 프로필로 이동하거나, 장소 검색(지도)으로 연결됩니다.

lib/screens/other_user_profile_screen.dart: 검색된 다른 사용자의 프로필 화면입니다. 팔로우 기능이 있습니다.

lib/screens/community_detail_screen.dart: 커뮤니티 게시글 상세 보기 화면입니다. 댓글 작성, 좋아요, DM 보내기 기능이 있습니다.

lib/screens/follow_list_screen.dart: 팔로워/팔로잉 목록을 보여주는 화면입니다.