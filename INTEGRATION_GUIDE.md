# 🗺️ 여행 기록 기능 통합 가이드

## 📦 생성된 파일 목록

이 기능은 **독립적인 모듈**로 구현되어 있어, 다른 팀원과의 코드 충돌을 최소화합니다.

### 새로 생성된 파일 (복사만 하면 됨)

1. **`lib/models/travel_record_model.dart`**
   - 여행 기록, GPS 경로, 사진 정보 데이터 모델

2. **`lib/services/travel_tracker_service.dart`**
   - GPS 추적, 경로 저장, 사진 메타데이터 관리 핵심 로직
   - Singleton 패턴으로 앱 전체에서 하나의 인스턴스만 사용

3. **`lib/widgets/travel_tracker_button.dart`**
   - 여행 기록 시작/중지 버튼 위젯

4. **`lib/screens/travel_record_map_screen.dart`**
   - 경로와 사진을 지도에 표시하는 전체 화면

### 수정된 파일 (최소한의 수정)

5. **`lib/screens/photo_picker_screen.dart`**
   - **추가된 부분**: import 1줄 + 버튼 위젯 3줄

---

## 🔧 A팀원의 코드에 통합하는 방법

### Step 1: 새 파일 복사

위 4개의 **새 파일**을 A팀원의 프로젝트의 **동일한 경로**에 복사합니다.

```
lib/
  models/
    ✅ travel_record_model.dart (신규)
  services/
    ✅ travel_tracker_service.dart (신규)
  widgets/
    ✅ travel_tracker_button.dart (신규)
  screens/
    ✅ travel_record_map_screen.dart (신규)
```

### Step 2: photo_picker_screen.dart 수정

A팀원의 `lib/screens/photo_picker_screen.dart` 파일을 열고:

#### (1) import 추가 (파일 상단)
```dart
import '../widgets/travel_tracker_button.dart'; // [추가]
```

#### (2) 버튼 추가 (갤러리 선택 버튼 아래)
```dart
const Divider(height: 1),

// [추가] 여행 기록 버튼
const TravelTrackerButton(),

const Divider(height: 1),
```

**전체 코드 예시:**
```dart
body: SafeArea(
  child: Column(
    children: [
      // 기존 갤러리/카메라 버튼
      Padding(...),
      
      const Divider(height: 1),
      
      // ✅ 이 부분 추가
      const TravelTrackerButton(),
      
      const Divider(height: 1),
      
      // 선택된 사진 그리드
      Expanded(...),
    ],
  ),
),
```

### Step 3: 사진 촬영 시 위치 정보 기록 (선택사항)

**photo_picker_screen.dart**의 `_takePhoto()` 함수를 수정하여 여행 기록 중일 때 위치를 저장:

```dart
import '../services/travel_tracker_service.dart'; // import 추가

// _takePhoto() 함수 수정
Future<void> _takePhoto() async {
  try {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImagePaths.add(photo.path);
      });
      
      // ✅ 여행 기록 중이면 위치 정보 저장
      final tracker = TravelTrackerService();
      if (tracker.isTracking) {
        final position = await tracker.getCurrentPosition();
        if (position != null) {
          await tracker.addPhotoRecord(photo.path, position);
        }
      }
    }
  } catch (e) {
    print("카메라 에러: $e");
  }
}
```

---

## 🎯 기능 사용 방법

### 1️⃣ 여행 기록 시작
1. 앱에서 **게시물 작성 탭**(+) 누르기
2. **"여행 기록 시작하기"** 버튼 클릭
3. 위치 권한 허용
4. 버튼이 **"여행 기록 중..."**으로 변경됨
5. 백그라운드에서 GPS 추적 시작 (10m마다 위치 저장)

### 2️⃣ 사진 촬영
- 여행 기록 중 찍은 사진에는 자동으로 위치와 시간 정보가 저장됨

### 3️⃣ 지도에서 경로 확인
1. **프로필 탭** → **두 번째 탭(지도 아이콘)** 클릭
2. 또는 코드에서 직접 호출:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TravelRecordMapScreen(),
  ),
);
```

### 4️⃣ 여행 기록 종료
- **"여행 기록 중..."** 버튼을 다시 클릭하면 기록 종료

---

## 📱 필요한 권한 설정

### Android (`android/app/src/main/AndroidManifest.xml`)

이미 설정되어 있을 가능성이 높지만, 확인해주세요:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
```

### iOS (`ios/Runner/Info.plist`)

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>여행 경로를 기록하기 위해 위치 정보가 필요합니다.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>백그라운드에서 여행 경로를 기록하기 위해 위치 정보가 필요합니다.</string>
```

---

## 🔥 Firebase 설정

### Firestore 데이터 구조

이 기능은 Firebase Firestore에 다음과 같은 컬렉션을 생성합니다:

```
travel_records/
  {recordId}/
    userId: "user123"
    startTime: Timestamp
    endTime: Timestamp (nullable)
    isActive: boolean
    routePoints: [
      {
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: Timestamp,
        accuracy: 10.5
      },
      ...
    ]
    photos: [
      {
        photoPath: "path/to/photo.jpg",
        latitude: 37.5665,
        longitude: 126.9780,
        timestamp: Timestamp,
        caption: "optional"
      },
      ...
    ]
```

### Firestore 보안 규칙

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /travel_records/{recordId} {
      allow read: if request.auth != null && 
                     resource.data.userId == request.auth.uid;
      allow write: if request.auth != null && 
                      request.resource.data.userId == request.auth.uid;
    }
  }
}
```

---

## 🚀 테스트 방법

### 1. 기본 테스트
```bash
flutter pub get
flutter run
```

### 2. 여행 기록 테스트
1. 앱 실행
2. 게시물 작성(+) 탭 → "여행 기록 시작하기" 클릭
3. 위치 권한 허용
4. 잠시 이동 (또는 에뮬레이터에서 위치 변경)
5. 프로필 → 지도 탭에서 경로 확인

### 3. 사진 기록 테스트
1. 여행 기록 시작
2. 카메라 버튼으로 사진 촬영
3. 지도에서 사진 마커 확인
4. 마커 클릭 → 사진 팝업 확인

---

## ⚠️ 주의사항

### 코드 충돌 방지
- **기존 파일 최소 수정**: `photo_picker_screen.dart`만 3줄 추가
- **독립적인 서비스**: 다른 코드에 영향 없음
- **네이밍 충돌 없음**: 모든 클래스명이 `TravelTracker`로 시작

### 성능 최적화
- GPS 추적은 10m마다만 업데이트 (배터리 절약)
- Firestore 업데이트는 배치로 처리
- 앱 재시작 시 이전 기록 자동 복구

### 디버깅
콘솔에서 다음 로그 확인:
```
✅ 여행 기록 시작: 1234567890
📍 경로 포인트 추가: 37.5665, 126.9780
📸 사진 기록 추가: /path/to/photo.jpg
✅ 여행 기록 종료
```

---

## 🤝 A팀원에게 전달할 파일

### 필수 파일 (4개)
1. `lib/models/travel_record_model.dart`
2. `lib/services/travel_tracker_service.dart`
3. `lib/widgets/travel_tracker_button.dart`
4. `lib/screens/travel_record_map_screen.dart`

### 선택 파일
5. `INTEGRATION_GUIDE.md` (이 문서)

### 전달 메시지 예시
```
안녕하세요!
여행 기록 기능을 독립 모듈로 구현했습니다.

📦 첨부 파일:
- 4개의 새 파일 (models, services, widgets, screens)
- 통합 가이드 문서

🔧 통합 방법:
1. 4개 파일을 동일한 경로에 복사
2. photo_picker_screen.dart에 3줄만 추가
   (가이드 문서의 Step 2 참고)

✅ 기존 코드와 충돌 없음 보장
✅ 기능 독립적으로 작동
✅ 언제든지 제거 가능

궁금한 점 있으면 연락주세요!
```

---

## 📚 추가 기능 확장 (향후)

### 기능 아이디어
- [ ] 여행 기록 히스토리 목록 화면
- [ ] 경로 재생 (애니메이션)
- [ ] 여행 기록 공유 기능
- [ ] 거리/시간 통계
- [ ] 오프라인 모드 지원

---

## 🐛 문제 해결

### 위치 권한 거부됨
- 설정 → 앱 권한 → 위치 → 항상 허용

### 경로가 표시되지 않음
- Firebase Console에서 데이터 확인
- 콘솔 로그 확인

### 백그라운드 추적 안됨 (iOS)
- Background Modes 활성화 필요
- Xcode → Runner → Signing & Capabilities → Background Modes → Location updates 체크

---

**구현 완료! 🎉**
문의사항이 있으면 언제든지 연락주세요.
