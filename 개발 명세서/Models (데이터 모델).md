앱에서 사용하는 데이터 구조를 정의하고, 상태를 관리합니다.

lib/models/post_model.dart:

Post 클래스: 게시물 하나에 대한 정보(작성자, 위치, 사진 경로, 제목, 내용 등)를 담습니다.

전역 상태 관리: globalPostsNotifier(전체 게시물 리스트), globalFollowingCount(팔로잉 수), globalFollowerCount(팔로워 수), globalProfileImage(내 프로필 사진), blockedUsersNotifier(차단된 사용자 목록), globalUserName/Bio/Email/Phone(내 프로필 정보) 등을 ValueNotifier로 관리하여 앱 전체에서 실시간으로 공유하고 업데이트합니다.

lib/models/travel_plan_model.dart:

TravelPlan 클래스: 여행 계획 하나에 대한 정보(제목, 날짜, 국가 등)를 정의합니다.

lib/models/activity_model.dart:

ActivityItem 클래스: 사용자의 활동(댓글, 좋아요, 스크랩 등) 정보를 담습니다.

globalActivitiesNotifier: 전체 활동 내역 리스트를 관리합니다.

savedPostsNotifier: 보관함(스크랩)에 저장된 게시물 리스트를 별도로 관리합니다.