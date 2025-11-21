Tripic 프로젝트 파일 구조 및 설명

1. Configuration (설정)

android/app/src/main/AndroidManifest.xml: Android 권한 (카메라, 위치 등) 및 네이버 지도 API 키 설정.

ios/Runner/Info.plist: iOS 권한 요청 메시지 및 네이버 지도 API 키 설정.

lib/main.dart: 앱 진입점. 네이버 지도 초기화, 날짜 로케일 설정, 테마 설정.

2. Models (데이터 모델)

lib/models/post_model.dart: 게시물 데이터 클래스 (Post). 전역 상태 관리 (globalPostsNotifier).

lib/models/travel_plan_model.dart: 여행 계획 데이터 클래스 (TravelPlan).

3. Screens (화면)

인증 (Auth)

lib/screens/splash_screen.dart: 스플래시 화면.

lib/screens/login_screen.dart: 로그인 화면.

lib/screens/signup_screen.dart: 회원가입 화면.

메인 탭 (Main Tabs)

lib/screens/home_screen.dart: [탭 1] 홈 피드. 게시물 리스트, 상단 지도 배너, 탭바 관리.

lib/screens/travel_plan_screen.dart: [탭 2] 여행 계획 목록. 계획 추가 및 리스트 표시.

lib/screens/community_screen.dart: [탭 4] 커뮤니티. 게시글/동행 탭, 검색 기능.

lib/screens/profile_screen.dart: [탭 5] 마이페이지. 내 정보 및 업로드한 게시물 그리드.

여행 계획 상세 (Travel Plan Details)

lib/screens/travel_plan_setup_screen.dart: 여행 계획 설정. 날짜(달력), 국가(지도/검색), 비행편, 숙소, 인원, 준비물 등 입력 모달.

게시물 작성 (Create Post)

lib/screens/photo_picker_screen.dart: [Step 1] 사진 선택 (갤러리/카메라).

lib/screens/photo_editor_screen.dart: [Step 2] 사진 편집 및 친구 태그.

lib/screens/write_post_screen.dart: [Step 3] 내용 입력 및 업로드 (홈 피드 연동).

lib/screens/community_write_screen.dart: 커뮤니티 전용 글쓰기 (사진, 지도, 달력, 인원 선택 포함).

메시지 & 친구 (Message & Friends)

lib/screens/message_list_screen.dart: 메시지 목록. 채팅방 및 친구 목록으로 이동.

lib/screens/friend_list_screen.dart: 친구 목록. 채팅 상대 선택 또는 인원 추가 선택 기능.

lib/screens/chat_detail_screen.dart: 채팅방. 지도 경로 표시 및 메시지 전송 UI.

지도 (Map)

lib/screens/map_detail_screen.dart: 전체 화면 지도. 친구 게시물 마커 표시 및 내 위치 이동.

lib/screens/map_search_screen.dart: 지도 검색. 친구/지역 검색 및 카메라 이동.

lib/screens/community_detail_screen.dart: 커뮤니티 게시글 상세 보기.

4. Widgets (공통 위젯)

lib/widgets/custom_textfield.dart: 커스텀 입력창.

lib/widgets/gradient_button.dart: 그라데이션 버튼.

lib/widgets/comment_modal.dart: 댓글 작성 및 표시용 바텀 시트.

5. Packages (사용된 패키지)

image_picker: 갤러리/카메라 연동

flutter_naver_map: 네이버 지도 SDK

geolocator: GPS 위치 정보

permission_handler: 권한 관리

table_calendar: 달력 UI

intl: 날짜 포맷팅
