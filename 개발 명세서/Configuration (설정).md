앱의 권한 및 초기 설정을 담당하는 파일들입니다.

android/app/src/main/AndroidManifest.xml: Android 앱의 권한 설정 파일입니다. 카메라, 갤러리(저장소), 위치(GPS), 마이크 권한을 선언하고, 네이버 지도 API 사용을 위한 Client ID를 등록합니다.

ios/Runner/Info.plist: iOS 앱의 설정 파일입니다. 사용자에게 권한(카메라, 위치 등)을 요청할 때 보여줄 메시지를 설정하고, 네이버 지도 API Client ID를 등록합니다. 앱 이름(CFBundleDisplayName)도 여기서 설정합니다.

lib/main.dart: 앱의 진입점(Entry Point)입니다.

네이버 지도 SDK를 초기화합니다.

intl 패키지를 위한 날짜 포맷팅 데이터를 초기화합니다.

앱의 기본 테마(색상, 폰트 등)를 설정하고 첫 화면(SplashScreen)을 실행합니다.