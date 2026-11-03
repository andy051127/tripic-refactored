# Tripic 프로젝트 분석

## 1. 프로젝트 개요

Tripic은 여행의 **계획, 기록, 공유**를 한 앱에서 처리하는 Flutter 모바일 앱이다. 사용자는 여행 일정을 만들고, 사진과 위치가 포함된 게시물을 올리며, 이동 경로를 기록할 수 있다. 피드·지도·커뮤니티에서 다른 사용자의 여행을 보고 팔로우, 댓글, 메시지로 소통한다. 관리자용 사용자·게시물·신고·문의 관리 화면도 포함되어 있다.

현재 저장소는 Android와 iOS용 Flutter 클라이언트가 중심이다. 별도 자체 서버 코드는 없고 Firebase Authentication, Cloud Firestore, Firebase Storage를 백엔드로 사용한다.

## 2. 기술 구성과 디렉터리

| 영역 | 실제 구성 |
| --- | --- |
| 앱 | Flutter/Dart, Material UI, Android·iOS 프로젝트 |
| 인증 | Firebase Authentication의 이메일 가입·로그인·비밀번호 재설정 |
| 데이터 | Cloud Firestore 문서 및 실시간 스트림 |
| 파일 | Firebase Storage에 게시물·프로필 사진 업로드 |
| 지도·위치 | Google Maps, Google Places 관련 기능, Geolocator, HTTP 요청 |
| 기기 기능 | 사진 선택·촬영·편집, 위치 및 미디어 권한 |
| 로컬 저장 | SharedPreferences에 온보딩·로그인 유지·여행 추적 세션 정보 저장 |

주요 코드는 다음처럼 나뉜다.

```text
lib/
  main.dart       앱 초기화, 테마, 인증 상태에 따른 첫 화면
  screens/        피드·계획·작성·지도·채팅·설정·관리자 화면과 화면 내 상태
  services/       인증, Firestore CRUD/스트림, 알림, GPS 추적
  models/         게시물, 여행 계획·기록, 메시지, 알림, 활동 데이터
  widgets/        입력 필드, 버튼, 댓글 모달, 여행 기록 버튼
assets/           로고, 기본 프로필, 소셜 아이콘, 온보딩 이미지
android/, ios/    네이티브 설정, 권한, Firebase 및 지도 설정
test/            앱 위젯 스모크 테스트 1개
```

`pubspec.yaml`의 패키지 이름은 `my_app`, 앱 표시 이름은 `Tripic`이다. 주요 의존성은 `firebase_*`, `cloud_firestore`, `google_maps_flutter`, `geolocator`, `image_picker`, `image_editor_plus`, `shared_preferences`, `table_calendar`, `intl`이다.

## 3. 아키텍처와 데이터 흐름

이 앱은 별도 상태 관리 프레임워크나 선언형 라우터를 두지 않은 **화면 중심 구조**다. 화면별 `StatefulWidget`이 로컬 UI 상태를 관리하고, `Navigator`와 `MaterialPageRoute`로 상세 화면을 연다. 홈과 관리자 화면은 각각 `BottomNavigationBar`로 탭을 전환한다.

```text
사용자 조작
  → screens: 화면 상태 및 입력 검증
  → services: 인증, 게시물·계획·채팅 CRUD, 알림, 위치 추적
  → Firebase Auth / Firestore / Storage 또는 기기 위치·사진 API
  → Firestore StreamBuilder·서비스 스트림 / ValueNotifier
  → 화면 갱신
```

- `main.dart`는 Firebase와 날짜 형식 데이터를 초기화하고 여행 추적 세션을 복원한다. `authStateChanges()`를 구독하여 인증 확인 중에는 스플래시, 로그인 상태에는 홈, 비로그인 상태에는 로그인 화면을 보여준다.
- `AuthService`는 이메일 계정 생성·로그인·비밀번호 초기화를 담당한다. 로그인 시 Firestore의 계정 정지 상태도 확인한다.
- `FirestoreService`는 게시물·여행 계획·팔로우·좋아요·댓글·채팅·차단·저장·신고·관리자 작업을 모은 큰 서비스다. 일부 화면은 이 서비스를 거치지 않고 Firestore를 직접 조회한다.
- `NotificationService`는 Firestore 알림 생성·조회·읽음 처리와 알림 설정 확인을 담당한다.
- `TravelTrackerService`는 싱글턴 `ChangeNotifier`로 GPS 추적 상태를 유지하고 경로·사진 위치를 `travel_records`에 저장한다. 앱 시작 시 이전 추적 세션 복원을 시도한다.
- `Post`, `TravelPlan`, `TravelRecord`, `Message`/`ChatRoom`, `NotificationModel` 등이 Firestore 문서와 화면 사이의 데이터 형식이다. 프로필과 피드에는 `ValueNotifier` 전역 상태도 사용한다.

주요 Firestore 루트 컬렉션은 `users`, `posts`, `travel_plans`, `travel_records`, `chatRooms`, `notifications`, `reports`다. 사용자별 `followers`/`following`, `blockedUsers`, `hiddenPosts`, `savedPosts`, 게시물별 `likes`/`comments`, 채팅방별 `messages` 등의 하위 컬렉션도 사용한다. 사진 파일은 Storage에 올리고 문서에는 URL 및 메타데이터를 저장한다. 실제 접근 권한은 저장소에 없는 Firestore/Storage 보안 규칙 설정에도 좌우된다.

## 4. 앱 시작과 주요 화면 흐름

### 시작·회원가입

```text
앱 실행 → Firebase·추적 세션 초기화 → 인증 상태 확인
  ├─ 로그인 상태 → 홈
  └─ 비로그인 → 로그인
       ├─ 이메일 로그인 → 홈
       ├─ 비밀번호 재설정
       └─ 회원가입 → 프로필 생성 → 온보딩 → 홈
```

로그인 화면의 Google·Apple 로그인 버튼은 현재 준비 중 안내만 표시한다. `main.dart`는 `seenOnboarding` 값을 읽어 `TripicApp`에 전달하지만 첫 화면 분기에는 사용하지 않는다. 따라서 온보딩은 현재 **회원가입 후 프로필 생성 흐름**에서 열린다. 스플래시 화면 자체에도 `keepLoggedIn`에 따라 이동하는 코드가 있지만, 앱 루트의 인증 상태 분기와 별도로 존재한다.

### 홈의 5개 탭

| 탭 | 화면과 다음 이동 |
| --- | --- |
| 홈 | 사진 게시물 피드. 검색 → 사용자 프로필/지도, 메시지 → 채팅 목록·대화, 알림 → 알림 목록, 게시물 → 좋아요·댓글·저장·공유·신고·차단, 지도 진입 및 국가 필터 |
| 여행 계획 | 내 계획 목록 → 계획 생성/수정 화면 또는 계획 상세. 날짜·국가·항공편·숙소·동행자·준비물을 관리 |
| 중앙 `+` | 사진 선택/촬영 → 사진 편집·위치/동행자 지정 → 제목·내용 입력 → 게시물 업로드. 작성 중 여행 계획을 연결하거나 여행 경로 추적을 시작/종료 가능 |
| 커뮤니티 | 일반 게시글·동행 찾기 목록 → 검색, 글 작성, 상세에서 댓글·좋아요·작성자 프로필·메시지 |
| 프로필 | 내 정보·게시물 격자·여행 지도 → 게시물 상세, 팔로워/팔로잉, 회원 정보, 설정, 로그아웃 |

탭 3은 독립 페이지가 아니라 사진 작성 흐름을 `push`한다. 홈 피드는 게시물 데이터와 좋아요·댓글 수 등을 Firestore 스트림으로 받아 표시한다.

### 주요 하위 흐름

```text
여행 계획: 목록 → 생성/상세 → 상세에서 수정·체크리스트·삭제
게시물: 사진 선택 → 편집·위치 선택 → 글 작성 → Storage 업로드 + Firestore 저장 → 홈
여행 기록: 사진 선택 화면의 기록 버튼 → GPS 경로·사진 위치 저장 → 프로필의 여행 기록 지도
탐색: 검색/피드/지도 → 다른 사용자 프로필 → 팔로우·게시물·DM
채팅: 메시지 목록 → 대화 → 텍스트·이미지·위치·게시물·여행 계획 공유
설정: 공개 범위, 차단·숨김, 보관함, 활동, 알림 설정, 도움말, 1:1 문의, 정보
관리자: 설정의 관리자 진입 → 대시보드·사용자·커뮤니티·신고·1:1 문의 관리
```

관리자 진입 항목은 Firestore 사용자 역할이 `admin`일 때 설정 화면에 표시된다. 지도 화면은 일반 조회, 특정 사용자의 게시물 조회, 게시물 작성 중 위치 선택 모드로 재사용된다.

## 5. 구현 상태를 읽을 때 유의할 점

- 기존 `개발 명세서/`와 발표 자료에는 기획·설명 내용이 섞여 있다. 이 문서는 현재 `lib/`의 진입점, 화면 연결, 서비스 및 모델을 우선으로 요약했다.
- `FIREBASE_FUNCTIONS_GUIDE.md`는 예약 삭제용 Cloud Functions **설정 안내와 예시 코드**다. 저장소에는 `functions/` 구현·배포 설정이 없으므로 자동 삭제가 실제 배포되어 있다고 판단할 수 없다.
- 지도 화면에는 Firestore 게시물 처리 코드 외에 예시 친구 게시물 데이터도 있다. 지도에 보이는 모든 마커가 실데이터라고 가정하면 안 된다.
- `test/widget_test.dart`는 단일 스모크 테스트다. 기능별 자동화 테스트와 Firestore 보안 규칙은 이 저장소에서 확인되지 않는다.
- 위치·카메라 권한과 Google Maps/Firebase 설정은 Android/iOS 네이티브 파일에 들어 있다. 외부 API 설정과 Firebase 프로젝트 상태가 실제 실행 가능 여부에 영향을 준다.
