
앱 개선점 총 정리

현재 개선해야하는 점들입니다.(아직 다 완성 못함)
전체적인 기능 별로 정리해놓았습니다
최대한 화면 흐름 순으로 나열해 놓았으니 "주요 이동 흐름 요약.md" 보시고 파일 찾을 때 참고해주세요.
업데이트 하시게 되면 날짜 게속 업데이트 해주시고 해결 완료하신 사항은
옆에 주석 표시(//) 달아놓으시죠.


0. 스플래쉬 화면 및 아이콘 로고
    // - 앱 아이콘 tripic 로고로 바꾸기
    // - 앱 처음 실행시 스플래시 화면 뜨게 만들기

1. 앱 시작 및 로그인
    - login_screen:
        -- 비밀번호 찾기 페이지 구현
        -- 소셜미디어 로그인 구현
    - signup_screen: 문제 없음
    - profile_creation_screen: 문제 없음

2. 메인 네비게이션
    - 문제 없음

3. 홈화면(home_screen)
    - // 중앙 상단의 지도영역에서 지도가 보이도록 수정
    - 프로필 클릭시 해당 프로필로 이동하도록 수정
    - 하트, 댓글, 게시물 공유 DB 연결 + 게시물 공유 기능 쓸때 friend_list_screen 재활용
    - 보관함 저장 UI DB에 맞게 작동하도록 수정
    - 게시물 우측 상단 ... 버튼:
        -- UI가 안드로이드 네비게이션바에 가려지지 않도록 수정
        -- 팔로우 버튼 구현
        -- 숨기기 버튼 구현
        -- 차단 버튼 구현(+ 차단 시 한번 더 물어보기)
        -- 신고 기능 구현

4. 게시물 작성
    - photo_picker_screen: 문제 없음
    - photo_editor_screen:
        -- 지도 위치 지정시 지역 검색 기능 추가
        -- 지도 확대 후 위치 지정시 지도 화면이 다시 작아지지 않도록 구현
        -- 지도 위치 정보 DB에 연결
    - write_post_screen:
        -- photo_editor_screen에서 선택한 위치가 뜨도록 설정

5. 검색 및 프로필
    - search_screen: 친구 검색 DB 연결하기
    - other_user_profile_screen:
        -- 팔로우 , 팔로우 취소 DB 연결
        -- 팔로워 누를시 --> follow_list_screen 로 이동하게 수정
        -- 팔로잉 누를시 --> follow_list_screen 로 이동하게 수정
        -- 메세지 버튼 누를시 --> chat_detail_screen으로 이동하게 수정
    - map_search_screen: "7. 지도" 참고

6. 메세지
    - message_list_screen:
        -- 즐겨찾기, 채팅방 내역 DB 연결
        -- 현재 활동중 기능 --> 이거 구현해보고 빡세면 시마이 하시죠 걍
        -- 즐겨찾기에 있는 프로필 클릭시 other_user_profile_screen로 해당 프로필 연결
    - friend_list_screen:
        -- ps. 이 파일은 "일반 모드"와 "선택 모드"로 구분해서 일반모드일때는 DM창 띄우고
        선택모드일때는 선택하여 확인하는 기능 넣어야 합니다.
        -- DB 연동
            --- 일반 모드: 누르면 DM창으로 연결되도록 수정
            --- 선택 모드: message_list_screen에서 즐겨찾기 추가 버튼 누르면 선택모드로 진입,
            선택 후 확인 누르면 즐겨찾기에 해당 인물들 추가 및 DB에 전송되도록 수정

7. 지도
    - // map_detail_screen, map_search_screen:
        -- // ps. 생각해봤는데 얘네 둘 다 기능이 같아서 걍 하나로 묶고(map_screen.dart) 작업했습니다.
        -- 게시물 올릴때 등록된 위치 이름으로 찾는 기능 구현
        -- 지명으로 위치 찾는 기능 구현

8. 설정
    - settings_screen: 문제 없음, 만약 다크 모드 추가할거면 아래 탭 하나 추가
    - privacy_settings_screen: 계정 공개 범위 기능 적용/ 선택한 친구에게만 공개 --> 친한친구 기능으로 전환
    - blocked_users_screen: 차단 기능 구현
    - activity_screen: 기능 구현
    - notification_settings_screen: 기능 구현해야되긴 하는데 알림 오는거 못만들겠으면 걍 하지 마시죠
    - saved_posts_screen: 기능 구현
    - language_translation_screen: Google Translate API 활용해서 기능 구현
    - help_screen: 안드로이드 네비게이션 바에 버튼 가려지는 문제 해결
    - information_screen: 문제 없음

9. 여행 계획
    - travel_plan_screen: 문제 없음
    - travel_plan_setup_screen: 
        -- 안드로이드 네비게이션 바에 버튼 가려지는 문제 해결
        -- 국가설정: 국가 검색 기능과 빠른 지역 찾기에 주요 나라들 올리기
        -- 비행편 설정: 비행기 오는편, 가는편, 경유 비행기 추가 기능 구현
    - travel_plan_detail_screen: 문제 없음


            
        
    

