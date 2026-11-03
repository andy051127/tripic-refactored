# 로컬 API 설정

공개 저장소에서 키를 제거했다. 다음 파일과 값은 Git에 올리지 않고 각 개발 환경에서 설정한다.

## Firebase

Firebase 콘솔에서 앱용 구성 파일을 다시 받아 아래 경로에 둔다.

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

두 경로는 `.gitignore`에 추가되어 있다. 파일이 없으면 Firebase를 사용하는 앱 빌드·실행이 정상 동작하지 않는다.

## Google Maps

- Android: `GOOGLE_MAPS_API_KEY` 환경 변수 또는 로컬 Gradle 속성에 지도 SDK 키를 지정한다. 예: 사용자 홈의 `~/.gradle/gradle.properties`에 `GOOGLE_MAPS_API_KEY=...`를 추가한다.
- iOS: Git에서 제외된 `ios/Flutter/Secrets.xcconfig`를 만들고 `GOOGLE_MAPS_API_KEY = ...`를 지정한다.
- 지도 화면의 장소 검색: `flutter run --dart-define=GOOGLE_PLACES_API_KEY=...`처럼 전달한다.

모바일 앱에 주입한 지도·Places 키는 빌드 산출물에서 추출될 수 있다. 키를 비밀값으로 간주해 앱 내부에 보관하는 방식만으로 보호할 수 없으므로, Google Cloud 콘솔에서 앱·API 제한을 설정해야 한다. Places 웹 서비스 호출을 비공개로 유지하려면 향후 서버를 통해 요청하도록 옮겨야 한다.

## Figma MCP

`.vscode/mcp.json`에 저장되어 있던 Figma 토큰을 제거했다. 필요하면 `FIGMA_API_KEY`를 개발 환경의 환경 변수로 설정한다.

## 이미 공개된 값

파일에서 값을 지워도 Git 기록과 이전 복제본에는 남을 수 있다. 기존 Figma 토큰을 폐기하고 새 토큰을 발급받아야 한다. 기존 Google API 키도 사용 여부를 확인해 교체하고 제한을 걸어야 한다. 이 작업은 외부 서비스 콘솔 접근이 필요하다.
