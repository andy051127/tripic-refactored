# Screens (화면) - 이동 흐름별 정리

앱의 각 페이지를 담당하는 UI 파일들을 사용자의 이동 흐름에 따라 정리했습니다.

---

## 1️⃣ 앱 시작 플로우

### `lib/screens/splash_screen.dart`
- **진입점**: 앱 실행 시 자동 표시
- **설명**: 로고를 보여주는 로딩 화면 (2초 후 자동 이동)
- **이동**: → `login_screen.dart`

### `lib/screens/login_screen.dart`
- **진입**: `splash_screen.dart` 자동 이동 또는 로그아웃 시
- **설명**: 이메일/비밀번호 입력 및 소셜 로그인 버튼 제공
- **이동**:
  - 회원가입 버튼 → `signup_screen.dart`
  - 로그인 성공 → `home_screen.dart` (메인 탭 화면)

### `lib/screens/signup_screen.dart`
- **진입**: `login_screen.dart`의 회원가입 버튼
- **설명**: 사용자 정보를 입력받는 회원가입 폼
- **이동**: 
  - 가입 완료 → `profile_creation_screen.dart` 또는 `home_screen.dart`

### `lib/screens/profile_creation_screen.dart`
- **진입**: `signup_screen.dart` 완료 후
- **설명**: 프로필 사진, 이름, 소개 등 초기 프로필 설정
- **이동**: → `home_screen.dart`

---

## 2️⃣ 메인 화면 (Bottom Navigation - 5개 탭)

### 탭 1: `lib/screens/home_screen.dart` - 홈 피드
- **설명**: 팔로우한 사용자들의 게시물 피드
- **구성**:
  - 상단: 지도 배너, 검색 버튼, 메시지 버튼
  - 중앙: PostItem 리스트 (좋아요, 댓글, DM, 더보기 기능)
  - 하단: 네비게이션 바
- **이동**:
  - 지도 배너 클릭 → `map_detail_screen.dart`
  - 검색 버튼 → `search_screen.dart`
  - 메시지 버튼 → `message_list_screen.dart`
  - + 버튼 → `photo_picker_screen.dart` (게시물 작성 시작)
  - 게시물 사진 클릭 → 게시물 상세 보기
  - 더보기 메뉴 → 신고/차단/숨기기/팔로우 액션

### 탭 2: `lib/screens/travel_plan_screen.dart` - 여행 계획
- **설명**: 등록된 여행 계획 목록 표시
- **구성**: 계획 카드 리스트 또는 추가 안내 메시지
- **이동**:
  - + 버튼 → `travel_plan_setup_screen.dart`
  - 계획 카드 클릭 → `travel_plan_detail_screen.dart`

### 탭 3: (+ 버튼) - 게시물 작성 플로우
- **설명**: 중앙 + 버튼 클릭 시 게시물 작성 시작
- **이동**: → `photo_picker_screen.dart`

### 탭 4: `lib/screens/community_screen.dart` - 커뮤니티
- **설명**: 커뮤니티 게시글 및 동행 찾기 탭
- **구성**: '게시글'/'동행' 탭, 검색 기능
- **이동**:
  - + 버튼 → `community_write_screen.dart`
  - 게시글 클릭 → `community_detail_screen.dart`
  - 검색 → 필터링된 결과 표시

### 탭 5: `lib/screens/profile_screen.dart` - 마이페이지
- **설명**: 내 프로필 정보 및 게시물 그리드
- **구성**: 프로필 사진, 이름, 소개, 통계(게시물/팔로워/팔로잉), 게시물 그리드
- **이동**:
  - 프로필 사진 클릭 → 사진 변경 기능
  - + 버튼 → `photo_picker_screen.dart`
  - 햄버거 버튼 → `member_info_screen.dart`
  - 설정 버튼 → `settings_screen.dart`
  - 팔로워/팔로잉 숫자 클릭 → `follow_list_screen.dart`
  - 로그아웃 버튼 → `login_screen.dart`

---

## 3️⃣ 게시물 작성 플로우 (3단계)

### Step 1: `lib/screens/photo_picker_screen.dart`
- **진입**: 홈 화면 또는 프로필 화면의 + 버튼
- **설명**: 갤러리 또는 카메라에서 사진 선택
- **이동**: → `photo_editor_screen.dart`

### Step 2: `lib/screens/photo_editor_screen.dart`
- **진입**: `photo_picker_screen.dart`
- **설명**: 선택한 사진 확인, 추가/삭제, 친구 태그, 위치 선택(구글 지도 통합)
- **기능**: 이미지 편집, 지도 위치 선택 (전체 화면 지도 모달)
- **이동**: → `write_post_screen.dart`

### Step 3: `lib/screens/write_post_screen.dart`
- **진입**: `photo_editor_screen.dart`
- **설명**: 제목과 내용 입력 후 최종 업로드
- **이동**: 
  - 업로드 완료 → `home_screen.dart` (게시물 추가됨)

---

## 4️⃣ 커뮤니티 글쓰기

### `lib/screens/community_write_screen.dart`
- **진입**: `community_screen.dart`의 + 버튼
- **설명**: 커뮤니티 전용 게시글 작성 (사진, 장소, 날짜, 인원 한 번에 설정)
- **이동**: 
  - 게시 완료 → `community_screen.dart`
  - 장소 선택 → 지도 모달
  - 날짜 선택 → 달력 모달
  - 인원 선택 → `friend_list_screen.dart` (선택 모드)

### `lib/screens/community_detail_screen.dart`
- **진입**: `community_screen.dart`의 게시글 클릭
- **설명**: 커뮤니티 게시글 상세 보기, 댓글 작성, 좋아요, DM 전송
- **이동**:
  - DM 보내기 → `chat_detail_screen.dart` (해당 사용자와의 채팅방)
  - 작성자 프로필 → `other_user_profile_screen.dart`

---

## 5️⃣ 여행 계획 관리

### `lib/screens/travel_plan_setup_screen.dart`
- **진입**: `travel_plan_screen.dart`의 + 버튼
- **설명**: 여행 계획 세부 설정 화면
- **구성**: 날짜(달력), 국가(검색/지도), 비행편, 숙소, 인원(친구목록), 준비물 리스트
- **이동**:
  - 저장 완료 → `travel_plan_screen.dart` (계획 추가됨)
  - 인원 추가 → `friend_list_screen.dart` (선택 모드)
  - 국가 선택 → 지도 모달

### `lib/screens/travel_plan_detail_screen.dart`
- **진입**: `travel_plan_screen.dart`의 계획 카드 클릭
- **설명**: 등록된 여행 계획 상세 정보 조회 및 수정
- **이동**: 
  - 수정 → `travel_plan_setup_screen.dart` (편집 모드)

---

## 6️⃣ 검색 및 프로필 탐색

### `lib/screens/search_screen.dart`
- **진입**: `home_screen.dart`의 검색 버튼
- **설명**: 통합 검색 (사용자 계정, 장소)
- **이동**:
  - 사용자 검색 결과 클릭 → `other_user_profile_screen.dart`
  - 장소 검색 → `map_search_screen.dart` 또는 지도 모달

### `lib/screens/other_user_profile_screen.dart`
- **진입**: `search_screen.dart`, 게시물의 사용자명 클릭
- **설명**: 다른 사용자의 프로필 보기 및 팔로우 기능
- **구성**: 프로필 정보, 게시물 그리드, 팔로우/언팔로우 버튼
- **이동**:
  - 게시물 클릭 → 게시물 상세
  - 팔로워/팔로잉 클릭 → `follow_list_screen.dart` (해당 사용자 기준)
  - DM 버튼 → `chat_detail_screen.dart`

### `lib/screens/follow_list_screen.dart`
- **진입**: 프로필 화면의 팔로워/팔로잉 숫자 클릭
- **설명**: 팔로워 또는 팔로잉 목록 표시
- **이동**:
  - 사용자 클릭 → `other_user_profile_screen.dart`

---

## 7️⃣ 메시지 및 친구

### `lib/screens/message_list_screen.dart`
- **진입**: `home_screen.dart`의 메시지 버튼
- **설명**: 채팅방 목록 및 즐겨찾기
- **이동**:
  - 채팅방 클릭 → `chat_detail_screen.dart`
  - + 버튼 → `friend_list_screen.dart` (새 채팅 시작)

### `lib/screens/friend_list_screen.dart`
- **진입**: 
  - `message_list_screen.dart`의 + 버튼
  - 여행 계획 인원 추가
  - 공개 범위 설정
- **설명**: 친구 목록 (두 가지 모드)
  - **선택 모드**: 여러 명 선택 후 반환 (여행 계획, 공개 범위 등)
  - **일반 모드**: 친구 클릭 시 채팅방으로 이동
- **이동**:
  - 일반 모드에서 친구 클릭 → `chat_detail_screen.dart`
  - 선택 모드에서 확인 → 이전 화면으로 선택 결과 반환
  - + 버튼 → `add_friend_screen.dart`

### `lib/screens/add_friend_screen.dart`
- **진입**: `friend_list_screen.dart`의 + 버튼
- **설명**: 친구 추가 화면 (검색 또는 초대)
- **이동**: 
  - 친구 추가 완료 → `friend_list_screen.dart`

### `lib/screens/chat_detail_screen.dart`
- **진입**: 
  - `message_list_screen.dart`의 채팅방 클릭
  - `friend_list_screen.dart`의 친구 클릭 (일반 모드)
  - 게시물의 DM 버튼
- **설명**: 1:1 채팅 화면 (상단에 지도 경로 표시)
- **구성**: 상대방 이름 앱바, 메시지 리스트, 입력창
- **이동**:
  - 상대방 이름 클릭 → `other_user_profile_screen.dart`

---

## 8️⃣ 지도 기능

### `lib/screens/map_detail_screen.dart`
- **진입**: `home_screen.dart`의 지도 배너 클릭
- **설명**: 전체 화면 지도 (구글 지도 API)
- **구성**: 내 현재 위치, 친구들의 게시물 위치 마커
- **이동**:
  - 마커 클릭 → 게시물 미리보기 팝업
  - 미리보기 클릭 → 게시물 상세

### `lib/screens/map_search_screen.dart`
- **진입**: 
  - `search_screen.dart`의 장소 검색
  - 여행 계획 설정의 국가 선택
  - 커뮤니티 글쓰기의 장소 선택
- **설명**: 지도 기반 검색 화면
- **구성**: 지도 메인, 상단 검색창 (친구 이름, 지역명)
- **이동**:
  - 위치 선택 → 이전 화면으로 위치 정보 반환

---

## 9️⃣ 설정 및 관리

### `lib/screens/settings_screen.dart`
- **진입**: `profile_screen.dart`의 설정 버튼
- **설명**: 설정 메뉴 리스트
- **이동**:
  - 계정 공개 범위 → `privacy_settings_screen.dart`
  - 차단된 계정 → `blocked_users_screen.dart`
  - 활동 → `activity_screen.dart`
  - 알림 → `notification_settings_screen.dart`
  - 보관함 → `saved_posts_screen.dart`
  - 언어 번역 → `language_translation_screen.dart`
  - 도움말 → `help_screen.dart`
  - 정보 → `information_screen.dart`

### `lib/screens/member_info_screen.dart`
- **진입**: `profile_screen.dart`의 햄버거 버튼
- **설명**: 회원 정보 상세 리스트 (이메일, 전화번호, 생년월일 등)
- **이동**: 
  - 정보 수정 → 각 항목 편집 모달 또는 인라인 편집

### `lib/screens/notification_settings_screen.dart`
- **진입**: `settings_screen.dart`의 알림 메뉴
- **설명**: 푸시 알림 on/off 스위치
- **이동**: 뒤로가기 → `settings_screen.dart`

### `lib/screens/privacy_settings_screen.dart`
- **진입**: `settings_screen.dart`의 계정 공개 범위 메뉴
- **설명**: 게시물 공개 범위 설정 (전체/친구만/친한친구/특정친구)
- **이동**:
  - 특정 친구 선택 → `friend_list_screen.dart` (선택 모드)
  - 저장 → `settings_screen.dart`

### `lib/screens/blocked_users_screen.dart`
- **진입**: `settings_screen.dart`의 차단된 계정 메뉴
- **설명**: 차단한 사용자 목록 및 차단 해제 기능
- **이동**: 
  - 차단 해제 → 목록에서 제거

### `lib/screens/activity_screen.dart`
- **진입**: `settings_screen.dart`의 활동 메뉴
- **설명**: 내 활동 내역 (댓글, 좋아요, 스크랩 등)
- **구성**: 탭으로 구분된 활동 유형별 리스트
- **이동**:
  - 활동 항목 클릭 → 해당 게시물 상세

### `lib/screens/saved_posts_screen.dart`
- **진입**: `settings_screen.dart`의 보관함 메뉴
- **설명**: 스크랩한 게시물 그리드 보기
- **이동**:
  - 게시물 클릭 → 게시물 상세

### `lib/screens/language_translation_screen.dart`
- **진입**: `settings_screen.dart`의 언어 번역 메뉴
- **설명**: 언어 번역 기능 시뮬레이션
- **이동**: 뒤로가기 → `settings_screen.dart`

### `lib/screens/help_screen.dart`
- **진입**: `settings_screen.dart`의 도움말 메뉴
- **설명**: 자주 묻는 질문(FAQ) 아코디언 리스트
- **이동**: 뒤로가기 → `settings_screen.dart`

### `lib/screens/information_screen.dart`
- **진입**: `settings_screen.dart`의 정보 메뉴
- **설명**: 앱 정보 (버전, 개발사 등)
- **이동**: 뒤로가기 → `settings_screen.dart`

---

## 🔄 주요 이동 흐름 요약

```
[앱 시작]
splash_screen → login_screen → signup_screen → profile_creation_screen → home_screen

[메인 네비게이션]
home_screen ⟷ travel_plan_screen ⟷ community_screen ⟷ profile_screen

[게시물 작성]
home_screen → photo_picker_screen → photo_editor_screen → write_post_screen → home_screen

[검색 및 프로필]
home_screen → search_screen → other_user_profile_screen

[메시지]
home_screen → message_list_screen → chat_detail_screen

[지도]
home_screen → map_detail_screen
search_screen → map_search_screen

[설정]
profile_screen → settings_screen → [각종 설정 화면들]
profile_screen → member_info_screen

[여행 계획]
travel_plan_screen → travel_plan_setup_screen → travel_plan_screen
travel_plan_screen → travel_plan_detail_screen

[커뮤니티]
community_screen → community_write_screen → community_screen
community_screen → community_detail_screen
```