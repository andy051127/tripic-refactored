# 작업 보고: 공개 API 키 제거

## 변경 파일

- `.vscode/mcp.json`: 하드코딩된 Figma 토큰 제거
- `android/app/src/main/AndroidManifest.xml`, `android/app/build.gradle.kts`: 지도 키를 로컬 Gradle 속성 또는 환경 변수로 주입
- `lib/screens/map_screen.dart`: Places 키를 `--dart-define`으로 주입하고 미설정 시 안내
- `ios/Runner/AppDelegate.swift`, `ios/Runner/Info.plist`, `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Release.xcconfig`: 지도 키를 로컬 `Secrets.xcconfig`에서 주입
- `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`: 저장소의 Firebase 구성 파일 삭제
- `.gitignore`: 로컬 Firebase 구성 파일과 iOS 비밀 설정 파일 제외
- `API_KEY_SETUP.md`: 개발 환경별 재설정 및 키 교체 방법 기록
- `.agent/report.md`: 본 보고서 갱신

## 검증 결과

- 작업 폴더에서 Google·Figma 키 및 일반적인 비밀키 패턴을 재검색했고 일치 파일 0개를 확인했다.
- Firebase 구성 파일 2개가 작업 폴더에서 삭제된 것을 확인했다.
- `.vscode/mcp.json`의 JSON 파싱과 `git diff --check`가 통과했다.
- 최종 변경 목록과 민감값을 가린 diff를 확인했다. 기존 `PROJECT_INFO.md`는 수정하지 않았다.
- `flutter`와 `dart` 명령이 없어 앱 테스트·정적 분석·빌드는 실행하지 못했다. Firebase 구성 파일이 없는 상태에서 앱 빌드·실행에는 새 로컬 구성 파일이 필요하다.

## 남은 위험·가정·계획 조정

- 이미 공개된 키와 Figma 토큰은 Git 기록 및 복제본에 남을 수 있다. 각 서비스 콘솔에서 폐기·재발급 및 사용 제한을 해야 한다. Git 기록 재작성이나 원격 저장소 변경은 수행하지 않았다.
- 모바일 앱에 주입한 지도/Places 키는 빌드 산출물에서 추출될 수 있다. 앱·API 제한 또는 서버 프록시가 필요하다.
- 별도 계획 파일은 없었다. 사용자의 요청을 현재 작업 폴더의 실제 값 제거로 해석했다.
