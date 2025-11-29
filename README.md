[메인 네비게이션]
home_screen ⟷ travel_plan_screen ⟷ community_screen ⟷ profile_screen

[게시물 작성]
home_screen → photo_picker_screen → photo_editor_screen → write_post_screen → home_screen

[검색 및 프로필]
home_screen → search_screen → other_user_profile_screen // 계정 검색
                            → map_search_screen // 지도 검색

[메시지]
home_screen → message_list_screen → chat_detail_screen // 채팅
                                  → friend_list_screen // 친구 목록

[지도]
home_screen → map_detail_screen 

[설정]
profile_screen → settings_screen → [각종 설정 화면들]
profile_screen → member_info_screen

[여행 계획]
travel_plan_screen → travel_plan_setup_screen → travel_plan_screen
travel_plan_screen → travel_plan_detail_screen

[커뮤니티]
community_screen → community_write_screen → community_screen
community_screen → community_detail_screen

1130 앱 개선점 총 정리

1130에 확인한 현재 개선해야하는 점들입니다.
전체적인 기능 별로 정리해놓았습니다
화면 흐름 순으로 나열해 놓았으니 위쪽의 파일 흐름 보시고 파일 찾을 때 참고해주세요.
업데이트 하시게 되면 날짜 게속 업데이트 해주시고 해결 완료하신 사항은
옆에 주석 표시(//) 달아놓으시죠.

1. 홈화면(home_screen): 
    - 중앙 상단의 지도영역에서 지도가 보이도록 수정
    - 프로필 클릭시 해당 프로필로 이동하도록 수정
    - 하트, 댓글, 게시물 공유 DB 연결
    - 보관함 저장 UI DB에 맞게 작동하도록 수정
    - 게시물 우측 상단 ... 버튼:
        -- UI가 안드로이드 네비게이션바에 가려지지 않도록 수정
        -- 팔로우 버튼 구현
        -- 숨기기 버튼 구현
        -- 차단 버튼 구현(+ 차단 시 한번 더 물어보기)
        -- 신고 기능 구현
2. 게시물 작성
    - photo_picker_screen: 문제 없음
    - photo_editor_screen:
        -- 지도 위치 지정시 지역 검색 기능 추가
        -- 지도 확대 후 위치 지정시 지도 화면이 다시 작아지지 않도록 구현
        -- 지도 위치 정보 DB에 연결
    - write_post_screen:
        -- photo_editor_screen에서 선택한 위치가 뜨도록 설정
3. 검색 및 프로필
    - search_screen: 
        -- 계정검색 DB 연결 
    - other_user_profile_screen: 
        -- DB 연결
        -- 페이지 국가 선택 기능 및 지도 보기 기능 추가
    - map_search_screen: 
        -- 지도 검색 잘되게 수정 
        -- 지도에서 뒤로가기 누를시 다시 해당페이지로 리턴
4. 메세지
    - message_list_screen: DB 연결, 현재 활동 중 기능 구현(구현 어려우면 걍 뺴시죠)
    - chat_detail_screen: 
        -- UI Figma 버전으로 수정
        -- 사진 보내기, 지도 보내기, 사진 찍어 보내기 기능 구현 및 DB 연결
        -- 채팅 DB 연결
        -- 지도 API 연결
    - friend_list_screen: DB 연결
5. 지도
    - map_detail_screen: 
        -- 지도 검색기능 추가 및 기능 구현
        -- ps. 이 페이지는 그냥 빼고 map_search_screen(검색 및 프로필)과 통합하여
        "map.dart"로 만드는게 좋을 것 같습니다. 두 페이지에 필요한 기능이
        똑같습니다.

6. 

