# MP1 검증 결과 기록

> 최신 결과는 문서 끝의 **2026-11-18~19 sxngwxn Flutter 3.47.5 로컬 재검증** 절을 따릅니다. 이전 절의 SDK 버전·캡처·ZIP 구성과 미확인 표시는 당시 기록입니다.

- 관련 이슈 [#11](https://github.com/flutter-minifeed/mini-feed/issues/11)
- 제출 기준 [MP1 완료 기준](mp1.md)
- 갱신 날짜 2026-11-19
- 최신 앱 소스 기준 커밋 `ddd04b48aee207503a26879795a7cf63b9eab280` (#54·#55 병합 포함). 아래 과거 검사 표는 각 절에 적힌 커밋 기준입니다.
- 최신 main 재검증 — #54·#55가 병합된 main `ddd04b4`를 2026-11-16 Galaxy S23 Ultra에서 다시 확인했습니다. 결과는 [2026-11-16 최신 main 실기기 검증](#2026-11-16-최신-main-실기기-검증)에 있습니다.
- 현재 상태 — 현재 main의 자동 검사와 주요 실기기 흐름·캡처 완료. T09~T13 번호별 원문 대조, 팀원 설명 확인이 남아 있습니다. 실제 301자 붙여넣기는 2026-11-16 main `ddd04b4`에서 확인했습니다. T15는 GitHub #9의 명시 범위로 통과를 확인했습니다.

이번 sxngwxn의 최신 결과와 캡처는 [2026-11-16 sxngwxn 최종 실기기 검증](#2026-11-16-sxngwxn-최종-실기기-검증)에 있습니다. 아래 2026-11-13 표는 당시 검사 기록입니다.

## 2026-11-13 실행 전에 확인한 항목

- [x] #8 PR #50이 main에 반영됐으며 위 커밋의 앱 소스와 현재 app/의 차이가 없음을 확인했다.
- [x] 상세 보완 PR #55와 글쓰기 디자인 PR #54는 2026-11-13 확인 시 미병합이다. 현재 검사는 위 main의 앱을 대상으로 한다.
- [ ] 아래 Notion 테스트 원문의 T09~T13·T15 정의를 확인해 표에 옮긴다.
- [x] Android 기기를 연결하고 flutter doctor, flutter devices 결과를 아래에 기록했다.

테스트 원문 [테스트 케이스·자동화 도구](https://app.notion.com/p/40a8d812628a8147ad06c29535a12b10)

사용자가 전달한 [프로젝트 Notion 링크](https://app.notion.com/p/3db8d812628a80709085f3be61b9fd6c?v=3db8d812628a802ebcce000c8d44bdc8)와 테스트 원문은 2026-11-12와 2026-11-13 도구 연결에서 접근되지 않았습니다. 전달받은 사진은 도구 선정·자동화 적용 계획이며 T09~T13·T15의 개별 절차는 아직 확인하지 못했습니다. 아래 기능 점검표는 GitHub #11·현재 코드·docs/mp1.md를 참고해 준비했으며 공식 T번호에 임의로 대응시키지 않았습니다.

기준 문서 확인 사항 — #11 검증 문구는 “MP1 통과 기준 4개”, docs/mp1.md 평가 기준은 3개입니다. 팀에서 원문 기준을 확인한 뒤 적용하며, 임의의 네 번째 평가 기준을 추가하지 않습니다.

## 검사한 앱과 환경

| 항목 | 실제 기록 |
| --- | --- |
| 실행 날짜·검사자 | 2026-11-13 · sxngwxn의 Galaxy Note10 5G, Codex 로컬 실행 보조 |
| 실제 실행한 앱의 Git 커밋 | `36007e1b9e0966ee5298930120998bef06e3bfb8`. #11 브랜치 `de02be8`의 app/과 같은 소스로 확인했다. |
| APK 빌드·설치 방법 | `flutter build apk --debug --no-pub` 성공 → USB adb 설치 성공 → `com.minifeed/.MainActivity` 실행 성공 |
| Android 기기 모델·OS 버전 | Galaxy Note10 5G (SM-N971N), Android 12 (API 31), 1080×2280 |
| Flutter·Dart 버전 | 실제 `flutter doctor -v`에서 Flutter 3.47.9 stable / Dart 3.13.7 확인 |
| flutter doctor 결과 | 실행 완료. Android SDK 일부 라이선스 미동의 경고가 남아 있으며 약관 자동 동의는 하지 않았다. 이 APK의 빌드·설치·실행은 성공 |
| flutter devices의 USB 기기 확인 | SM N971N, android-arm64, Android 12 (API 31) 확인 |
| 실행 로그 경로·첨부 | 로컬 명령 결과로 확인. 제출용 실행 로그는 아직 미첨부 |

Chrome에서 별도로 확인한 결과가 생기면 아래에 남깁니다. Android 결과 칸에 옮겨 적지 않습니다.

| Chrome 실행 날짜·앱 커밋 | 확인 내용·실제 결과·로그 |
| --- | --- |
| 미기록 | 이번 문서 준비 작업에서는 앱 실행 미실행 |

설치한 debug APK의 SHA-256은 `1855CC9C6C7B44C52DD004CF98536450145B2540FB3964912ABEC2C941D5FFB6`입니다. 빌드 중 SDK XML 버전 차이 경고가 있었으며 빌드는 성공했습니다.

## 원문 테스트 번호별 결과

2026-11-13 GitHub에서 검사 범위를 추가 확인했습니다. [#8](https://github.com/flutter-minifeed/mini-feed/issues/8)의 검증 절은 T09~T13을 한글 299·300·301자, 공백·줄바꿈·닫기 취소 검사로 묶어 설명합니다. 작업·완료 기준에는 붙여넣기, 앞뒤 공백 제거와 중간 줄바꿈 유지, 게시 중 제어와 새 글 추가도 적혀 있습니다. 개별 번호와 각 절차의 대응표는 GitHub에서 찾지 못해 T09~T13의 번호별 판정은 보류합니다. [#9](https://github.com/flutter-minifeed/mini-feed/issues/9)는 T15를 본문·댓글 아이콘의 두 진입 경로 검사로 명시해 해당 범위의 실제 결과를 아래에 기록했습니다.

| 원문 번호 | 원문의 절차·예상 결과 | 실제 결과 | 판정 | 증거 |
| --- | --- | --- | --- | --- |
| T09 | 원문 접근 후 기입 | 미실행 | 미판정 | 없음 |
| T10 | 원문 접근 후 기입 | 미실행 | 미판정 | 없음 |
| T11 | 원문 접근 후 기입 | 미실행 | 미판정 | 없음 |
| T12 | 원문 접근 후 기입 | 미실행 | 미판정 | 없음 |
| T13 | 원문 접근 후 기입 | 미실행 | 미판정 | 없음 |
| T15 | [#9 검증 절](https://github.com/flutter-minifeed/mini-feed/issues/9) — 실기기에서 카드 본문·댓글 아이콘 두 진입 경로 확인 | post-01 본문으로 상세 진입 시 키보드 자동 표시 없음. 피드 댓글 아이콘으로 같은 상세 진입 시 입력창 포커스·키보드 표시 확인 | 통과 — GitHub #9에 명시된 범위 | [상세](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/detail.png) · [댓글 진입](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/detail-keyboard.png) |

## 기능별 통합 점검

각 행은 실제로 실행한 후 결과·판정을 바꿉니다. #8은 위 main에 반영된 상태입니다.

| 점검 | 절차와 기대 결과 | 실제 결과 | 판정 | 로그·캡처 |
| --- | --- | --- | --- | --- |
| 피드 표시·스크롤 | 앱 실행 후 더미 글이 최신순으로 표시되고 마지막 글까지 스크롤할 수 있다. 실제 JSON은 게시글 50개다. | 최초 post-01과 마지막 post-50의 본문을 JSON과 대조. 끝까지 스크롤 가능 | 통과 | [목록 끝](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/feed-bottom.png) |
| 본문 → 상세 → 뒤로 | 같은 글의 전체 내용·댓글을 확인하고 피드로 돌아온다. | 새 글 및 post-01 본문으로 상세 진입, 같은 본문과 post-01 댓글 1개 표시. Android 뒤로가기·상단 화살표로 복귀 | 통과 | [상세](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/detail.png) |
| 댓글 아이콘 → 상세 | 같은 글의 상세가 열리고 댓글 입력창에 포커스와 키보드가 표시된다. | post-01 댓글 버튼으로 동일 상세 진입. 입력창과 삼성 키보드가 함께 표시되며 입력창 가림 없음 | 통과 | 로컬 실제 화면 및 input_method의 mInputShown=true 확인 |
| 피드 → 글쓰기 → 뒤로 | 글쓰기 화면 진입·복귀가 가능하다. | 피드 글쓰기 버튼으로 진입, 게시 및 사용자 직접 X → 버리기로 복귀 확인 | 통과 | [글쓰기](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write.png) |
| 빈 글·공백 | 빈 입력과 공백만 입력했을 때 게시할 수 없다. | 빈 글에서 게시를 눌러도 이동 없음. 공백 3자에서 회색 비활성 게시 버튼 확인 | 통과 | 로컬 실제 화면 확인 |
| 300자 경계·한글 입력 | 299·300·301자 입력, 붙여넣기, 한글 조합 중 글자 수와 게시 가능 상태가 #8 요구사항에 맞다. | 299자 게시 활성, 300자 빨간 카운터, 301번째 C 입력 차단 확인. 삼성 키보드에서 A 299자 뒤 ㄱ → 가 조합을 300자로 표시. 301자 붙여넣기는 위젯 테스트 통과, 실기기 직접 붙여넣기는 미실행 | 일부 확인 — 실기기 붙여넣기 남음 | [299자](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write-299.png) · [300자](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write-300.png) · [301번째 차단](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write-301-blocked.png) · [한글 조합](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write-korean-300.png) |
| 작성 취소 확인 | 작성 중 닫기·Android 뒤로가기로 취소 확인이 열리고 계속 쓰기는 내용 유지, 버리기는 복귀한다. | X 및 키보드를 닫은 뒤 Android 뒤로가기로 확인 창 표시. 계속 쓰기는 한글 18자 유지. 사용자 직접 X → 버리기 후 피드 복귀를 캡처로 확인. 자동 좌표 입력으로 버리기 선택이 정확하지 않았던 시도는 성공 결과에서 제외 | 통과 — 사용자 직접 선택 포함 | 로컬 실제 화면과 사용자 답변 확인 |
| 새 글 게시·상단 추가 | 창작한 글을 게시하면 피드로 복귀해 한 번만 추가되고 최상단에서 본문·상대 시간을 확인할 수 있다. | 09:27:01 KST 게시 버튼 1회 → 피드 최상단에 ‘미니피드 실기기 확인용 글입니다.’ 1개와 ‘방금 전’ 표시 | 통과 | [피드](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/feed.png) |
| 새 글 상세 | 방금 쓴 글을 눌러 동일한 전체 본문이 표시되는지 확인한다. | 새 글 본문으로 상세 진입해 같은 내용·작성자·댓글 0개 확인 | 통과 | [새 글 상세](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/detail-new-post.png) |
| 상대 시간 | 기준 시각을 기록하고 #10의 방금 전·분·시간·어제·일·날짜 경계 결과를 확인한다. 고정 시각 더미 글의 오래된 날짜 표시도 확인한다. | 자동 테스트에서 #10 경계 검사 통과. 실기기 새 글은 09:27:01 KST 게시 직후 ‘방금 전’, 고정 더미 글은 ‘11월 4일’ 표시 | 통과 — 경계는 단위 테스트, 화면은 새 글·날짜 확인 | [피드](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/feed.png) |
| 작은 화면·키보드 | 글쓰기·상세에서 작은 화면과 키보드가 열린 상태에도 필요한 조작이 가려지지 않는다. | SM-N971N 세로 화면에서 키보드와 글자 수·게시 버튼·댓글 입력창 표시. 300자 및 한글 조합 화면에서 가림·넘침 오류 미관찰. 더 작은 화면·다른 배율은 미검사 | 해당 기기 범위 통과 | [댓글 키보드](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/detail-keyboard.png) · [300자](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write-300.png) |
| 더미 데이터·비밀값 | 실제 사용한 소스와 캡처에 실명·연락처·실제 키·토큰이 없는지 사람이 검토한다. | JSON 50글·83댓글에서 이메일·휴대폰 패턴 0건, 댓글 postId 미연결 0건. 저장할 앱 캡처를 시각 확인. .env·google-services.json·service-account 파일 검색 결과 없음. 팀원 최종 개인정보 검토는 대기 | 자동 점검·캡처 확인 완료, 사람 검토 대기 | 로컬 검색 결과 |

현재 상대 시간 함수의 경계는 1분·1시간·24시간·48시간·7일입니다. 미래 시각은 방금 전, 7일 이상은 월·일로 표시합니다. 함수 테스트 통과 여부와 실기기 화면 확인 결과를 각각 기록합니다.

## 분석·테스트·빌드 결과

| 검사 | 실행한 앱 커밋 | 실제 결과 | 로그 |
| --- | --- | --- | --- |
| flutter analyze --no-pub | `36007e1` | 오류 없음. 2026-11-13 재실행 | 로컬 명령 결과 |
| flutter test --no-pub | `36007e1` | 기존 테스트 63개 모두 통과. 2026-11-13 재실행 | 로컬 명령 결과 |
| Android 빌드·설치·실행 | `36007e1` | debug APK 빌드·USB 설치 성공. 게시·상세·댓글 진입·스크롤·입력 제한 확인. 앱 PID의 logcat에서 Flutter 예외·RenderFlex·충돌 일치 줄 0건 | [실기기 캡처](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/) |

이전 PR의 분석·테스트 결과를 최종 통합 앱의 결과로 대신 적지 않습니다.

## 캡처와 제출물

아래 이미지는 2026-11-13 Galaxy Note10 5G에서 실행한 debug APK의 원본 캡처입니다. 앱 소스는 `36007e1`이며 각 화면을 직접 확인했습니다. #54·#55 병합 후 화면이 바뀌면 제출 전 다시 확인합니다.

| 루트 기준 저장 위치 예시 | 실제 캡처 앱 커밋·기기·날짜 | 상태 |
| --- | --- | --- |
| [screenshots/feed.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/feed.png) | `36007e1` · SM-N971N / Android 12 · 2026-11-13 | 촬영·이미지 확인 완료 |
| [screenshots/write.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/write.png) | `36007e1` · SM-N971N / Android 12 · 2026-11-13 | 촬영·이미지 확인 완료 |
| [screenshots/detail.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/detail.png) | `36007e1` · SM-N971N / Android 12 · 2026-11-13 | 촬영·이미지 확인 완료 |

- [x] README의 화면 구성·더미 데이터 구조·실행 절차를 현재 main의 앱과 대조했다. 후속 병합 시 재확인한다.
- [x] 병합된 #8 및 오늘 #11 원본을 prompts_log.md에 추가하고 16개 원본 파일·17개 ID의 누락·중복·본문 일치를 확인했다. 후속 병합 시 재확인한다.
- [x] 실제 피드·글쓰기·상세 캡처가 루트 screenshots/에 있다. 새 글 상세도 추가했다.
- [x] 로컬 검토용 ZIP 최상위가 app/·README.md·screenshots/·prompts_log.md인지 확인했다.
- [x] 검토용 ZIP에서 .env·설치·빌드 폴더·docs/·Git 정보를 제외했다.

로컬 임시 폴더에 `minifeed-MP1-review-36007e1-20261113.zip`을 만들었습니다. 75개 파일·10,304,750바이트이며 ZIP 무결성과 필수 루트 4개 항목을 확인했습니다. T번호 원문 대조·실기기 붙여넣기·팀 확인 전의 검토용이며, 앱 소스나 기록이 바뀌면 다시 생성합니다.

## 팀 설명 확인

담당별 코드 흐름을 정리했습니다. 팀원 3명은 본인의 설명 댓글을 출처로 취합했고, sxngwxn은 현재 코드와 대조해 설명을 기록했습니다. 아래 표는 담당별 구현 설명이며 구두시험이나 이해도 확인 결과가 아닙니다.

| 팀원 | 담당 구현·설명한 흐름 | 확인 날짜·결과 |
| --- | --- | --- |
| sxngwxn | #3 기본 설정·앱 시작, #4 공통 테마, #7 피드 조회·화면 이동, #10 상대 시간 | 2026-11-19 현재 코드 기준으로 아래 설명 기록 |
| titanfall7274 | #8 입력·게시·취소, #49 AuthorTile·테마·카운터·키보드 | 2026-11-17 [본인 설명 댓글](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6950978671) 확인 |
| gunzzzang | #9 상세의 두 진입 경로·댓글 표시, #40 메모리 저장소·RepositoryScope | 2026-11-16 [본인 설명 댓글](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6920009128) 확인 |
| UTORY4624 | #6 CI의 SDK·lock 설치·분석·테스트, ai_logs 원본 기록 규칙 | 2026-11-17 [본인 설명 댓글](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6943930339) 확인 |


### sxngwxn — #3 기본 설정·#4 공통 테마·#7 피드·#10 상대 시간

- #3 기본 설정: 저장소의 app/ 한 곳에 Android·웹 프로젝트를 구성하고 Android 최소 API를 24로 설정했습니다. 현재 제출 기준은 Flutter 3.47.5 / Dart 3.13.4입니다.
- 앱 시작: main()에서 Flutter를 준비한 다음 게시글·댓글 JSON을 메모리 저장소로 읽습니다. RepositoryScope로 같은 저장소를 화면들에 공유하고, MaterialApp의 첫 화면을 FeedScreen으로 지정합니다.
- #4 공통 테마: appTheme에 색상과 Noto Sans KR 글꼴을 모았습니다. 화면에서는 Theme.of(context)를 사용하며, 작성자 아바타에는 공통 사용자 색상 8개를 사용합니다.
- #7 피드 목록: FeedScreen이 공통 저장소의 getPosts()로 글을 조회하고, ListView.builder가 각 게시글을 PostCard로 표시합니다. 로딩·빈 목록·조회 실패·다시 시도도 처리합니다.
- #7 화면 이동: 본문은 게시글 ID와 함께 상세로 이동하고, 댓글 아이콘은 focusComment를 true로 전달해 상세의 댓글 입력창과 키보드가 열리게 합니다. 글쓰기에서 돌아오면 목록을 다시 조회하고 새 글이 추가됐을 때 최상단으로 이동합니다.
- #10 상대 시간: relativeTime()이 작성 시각과 기준 현재 시각의 차이로 표시 문자열을 만듭니다. 1분 미만은 방금 전, 1시간 미만은 분 전, 24시간 미만은 시간 전, 48시간 미만은 어제, 7일 미만은 일 전, 이후는 월·일로 표시합니다. 테스트에서는 현재 시각을 고정해 경계를 확인합니다.

MP1은 JSON에서 시작하는 메모리 저장소를 사용하므로 앱을 완전히 재실행하면 새로 작성한 글은 초기 상태로 돌아갑니다.

코드 근거: `app/lib/main.dart`, `app/lib/screens/feed_screen.dart`, `app/lib/theme/app_theme.dart`, `app/lib/utils/relative_time.dart`. 현재 구현을 설명한 기록입니다.

### gunzzzang (#9 상세, #40 저장소)

[설명 원문](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6920009128)

- #9 상세: 피드 카드 본문으로 들어오면 키보드 없이, 💬로 들어오면 댓글 입력창에 포커스·키보드가 바로 열려요. 게시글 ID로 글과 댓글을 저장소에서 불러오고 작성자 아바타·닉네임·상대 시간, 댓글 목록(오래된 순)을 보여줘요. 댓글 입력은 공백만 있거나 200자를 넘으면 전송 버튼이 꺼지고, 실제 등록은 MP3 #20에서 연결해요. 뒤로가기로 피드에 돌아가요.
- #40 저장소: 더미 JSON을 읽어서 게시글은 최신순, 댓글은 오래된 순으로 돌려주는 메모리 저장소예요. 화면들은 `RepositoryScope`로 받아서 쓰기 때문에 MP2에서 Firestore로 바꿔도 화면 코드는 그대로예요.

### UTORY4624 (#6 CI, AI 사용 기록)

[설명 원문](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6943930339)

- #6 CI: `main`으로 향하는 PR을 열거나 업데이트하면 GitHub Actions가 자동 검사를 실행해요. Flutter 3.47.5를 준비한 뒤 `app/`에서 `pubspec.lock` 기준으로 의존성을 설치하고, `flutter analyze`와 `flutter test`를 실행해요. 실패하면 PR의 Checks 탭에서 어느 단계가 실패했는지 로그를 볼 수 있어요.
- #6 AI 사용 기록: AI를 사용한 작업은 `ai_logs/본인아이디/`에 작업별로 기록하고 PR 본문에 해당 기록 링크를 남겨요. 사용하지 않았다면 PR에 `미사용`으로 표시해요. MP1에서 `prompts_log.md`는 선택 제출로 바뀌어서, 팀은 `ai_logs/`에 원본 기록을 남겨요.

### titanfall7274 (#8 글쓰기, #49 글쓰기 UI)

[설명 원문](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6950978671)

- #8 입력·게시: 피드의 글쓰기 버튼으로 진입해 본문을 입력합니다. 빈 글·공백만 있는 글은 게시할 수 없고, 보이는 글자 기준 300자로 제한합니다. 저장할 때 앞뒤 공백은 제거하고 내부 줄바꿈은 유지합니다. 게시 중에는 중복 게시와 닫기를 막고, 성공하면 작성한 글을 피드로 돌려줘 맨 위에 표시합니다.
- #8 작성 취소: 내용이 있는 상태에서 X나 뒤로가기를 누르면 확인 창을 띄웁니다. 계속 쓰기는 입력을 유지하고, 버리기는 저장하지 않고 피드로 돌아갑니다.
- #49 UI: 공용 `AuthorTile`로 작성자 아바타·닉네임과 익명 안내를 표시하고, 공통 테마로 글쓰기 화면·게시 버튼·취소 창의 색과 글꼴을 적용합니다. 글자 수는 입력에 따라 갱신하며 300자에서 빨간색으로 표시합니다. 입력칸 아래 빈 곳을 눌러도 키보드가 다시 열리도록 연결했습니다.

현재 MP1의 게시글은 메모리 저장소에 보관하므로 앱을 완전히 재실행하면 새로 작성한 글은 유지되지 않습니다. 서버 저장과 저장 실패 안내는 MP2 #14에서 연결합니다.

## 이번 문서 준비에서 확인한 결과

- 앱 기준은 main의 위 커밋이며 #7·#8·#9·#10이 포함돼 있습니다.
- #8 PR #50 병합을 확인하고 README 글쓰기 설명을 실제 구현에 맞게 갱신했습니다.
- 앱 소스와 설정은 변경하지 않았습니다.
- README 3개 절, AI 원본과 취합본 일치 여부, 변경 파일의 공백 오류를 점검했습니다.
- Galaxy Note10 5G에서 주요 화면 이동·새 글 게시·입력 제한을 검사하고 실제 캡처를 저장했습니다. 원문 T번호별 판정과 팀 설명 확인은 미완료입니다.

## 2026-11-13 연결 중단 기록

- USB 연결이 검사 중 여러 차례 끊겨 재연결·사용자 디버깅 허용 후 재개했습니다.
- 첫 입력 제한 검사 시도는 연결 중단과 설정 화면 전환으로 판정에서 제외했습니다. 사용자가 설정을 마친 뒤 앱으로 복귀해 빈 글·공백·299/300/301번째 입력과 한글 조합을 다시 확인했습니다.
- 299자 입력 명령은 시간 초과로 실제 289자에서 중단됐습니다. 실제 글자 수를 확인한 뒤 10자를 더해 299자부터 경계 검사를 진행했습니다.

## 2026-11-13 PR #54 추가 실기기 검증

[titanfall7274의 PR #54](https://github.com/flutter-minifeed/mini-feed/pull/54)의 `4a45176fff48956de39c8abdf73113646a70a2e7`을 별도 로컬 작업 폴더에서 빌드해 확인했습니다. 이 절의 결과는 해당 PR 커밋을 대상으로 합니다.

| 항목 | 확인한 결과 |
| --- | --- |
| 실행 환경 | Galaxy Note10 5G (SM-N971N), Android 12 / API 31, USB 설치·실행 |
| Flutter / Dart | 3.47.9 stable / 3.13.7 |
| 분석·테스트 | `flutter analyze --no-pub` 오류 없음, `flutter test --no-pub` 66개 통과 |
| Android 빌드 | `flutter build apk --debug --no-pub` 성공. SDK XML 버전 차이 경고 출력 |
| APK SHA-256 | `692c8c015bc2771567f0fa1028566132cea46e6a6b3c7bc59fc3f5d1687062f9` |
| 앱 실행 기록 | 해당 앱 PID에서 Flutter 예외·RenderFlex overflow·FATAL EXCEPTION 검색 결과 0줄 |

### 화면과 동작

- 피드의 작성자 아바타·닉네임·작성 시각 표시를 확인했습니다.
- 글쓰기에 `새 글` 제목, 작성자 `처음 온 펭귄`, 익명 닉네임 안내가 표시됩니다.
- 빈 입력에서 게시 버튼 비활성을 확인했습니다. 시험용 본문 `Review54-phone-check` 20자를 입력하면 `20 / 300`과 활성 게시 버튼이 표시됩니다.
- Android 뒤로가기로 키보드를 내린 후 글 아래 빈 곳을 누르면 다시 열립니다.
- 게시 후 피드 최상단에 같은 본문과 `방금 전`이 표시됩니다.
- 본문 선택 시 같은 글의 상세가 표시됩니다. 댓글 버튼으로 진입하면 입력창과 키보드가 표시됩니다.
- X로 작성 취소 확인 창이 열립니다. `계속 쓰기` 선택 시 본문이 유지되고 `버리기` 선택 시 피드로 복귀합니다.
- 299자 회색 카운터, 300자 빨간 카운터를 확인했습니다. 301번째 영문 입력은 차단되고 본문 300자가 유지됩니다.

### 캡처

각 이미지는 위 PR 커밋의 debug APK를 실행한 휴대폰 원본입니다.

| 화면 | 파일 |
| --- | --- |
| 게시 후 피드 | [feed.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/pr-54-review/feed.png) |
| 빈 글쓰기 | [write-empty.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/pr-54-review/write-empty.png) |
| 본문으로 상세 진입 | [detail.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/pr-54-review/detail.png) |
| 댓글 버튼으로 상세 진입 | [detail-keyboard.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/pr-54-review/detail-keyboard.png) |
| 작성 취소 확인 창 | [discard.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/pr-54-review/discard.png) |
| 300자 입력 | [write-300.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/pr-54-review/write-300.png) |

### 이어서 확인할 항목

- #54·#55가 반영된 앱에서 최종 화면·실행 결과·캡처·AI 누적본·제출 ZIP을 갱신합니다.
- 이번 #54 버전의 한글 조합 경계 입력과 301자 실제 붙여넣기는 추가 확인이 필요합니다.
- TalkBack 실제 음성 출력, 다른 기기·화면 배율, Figma 치수·색상 정밀 대조는 미확인입니다.

## AuthorTile 로컬 코드 반영

- 2026-11-13 사용자 요청으로 PR #54의 작성자 줄 공통 위젯 변경을 현재 작업 폴더에 적용했습니다.
- 기준은 main 36007e1이며, app/lib/widgets/author_tile.dart와 app/lib/widgets/post_card.dart는 PR #54의 4a45176 원본과 파일 내용이 같습니다.
- flutter analyze --no-pub 오류 없음, flutter test --no-pub 전체 63개 통과, git diff --check 통과.
- 이 로컬 조합의 Android 빌드·실기기 검사는 미실행입니다. 앞 절의 실기기 사진은 각각 명시된 main 및 PR #54 커밋에서 촬영했습니다.

## 2026-11-15 리뷰 반영

- #54가 병합된 main 4cbf358을 로컬 #11 브랜치에 충돌 없이 반영했습니다. #55는 확인 시점 병합 전입니다.
- README의 화면 구성 절에 앱 실행·게시 성공·작성 취소·본문 및 댓글 상세 진입·피드 복귀 흐름을 추가했습니다.
- 지호님의 모든 PR 병합 후 최종 README 갱신 요청은 #55 반영 후 상세 화면 설명을 다시 확인해 마무리합니다.
- 병합 후 flutter analyze --no-pub 오류 없음, flutter test --no-pub 66개 통과. 현재 app/은 main 4cbf358과 같습니다.

## 2026-11-16 최신 main 실기기 검증

#54·#55가 병합된 main `ddd04b48aee207503a26879795a7cf63b9eab280`을 별도 작업 폴더에서 빌드해 확인했습니다. 이 절의 결과는 해당 커밋만을 대상으로 하며, 앞 절의 `36007e1`·PR #54 결과를 대신하지 않습니다. 해당 검사 기록 작성 시점의 #11 브랜치에는 #55가 반영되기 전이었습니다. 아래 sxngwxn 검증에서는 #55를 로컬에 반영했습니다.

| 항목 | 확인한 결과 |
| --- | --- |
| 실행 날짜·검사자 | 2026-11-16 · titanfall7274의 Galaxy S23 Ultra, Claude Code 로컬 실행 보조 |
| 실행 환경 | Galaxy S23 Ultra (SM-S918N), Android 16 / API 36, 1440×3088 |
| 설치 방법 | Tailscale 경유 무선 adb(`adb connect <기기 Tailscale IP>:5555`) → `adb install -r` 성공 → `com.minifeed/.MainActivity` 실행 |
| Flutter / Dart | 3.47.2 stable / 3.13.2 — 팀 기준 3.47.9 / 3.13.7과 다름 |
| 분석·테스트 | `flutter analyze` 오류 없음, `flutter test` 67개 통과 |
| Android 빌드 | `flutter build apk --debug` 성공. SDK XML 버전 차이 경고 출력 |
| APK SHA-256 | `0e2a3b589e2d3623927cf5ae3af59287bb5030cc6497c8ce0a35848da9da5944` |
| 앱 실행 기록 | 앱 PID logcat에서 exception·RenderFlex·overflow·FATAL 검색 결과 0줄, 전체 logcat FATAL EXCEPTION 0줄 |

### 기능별 결과

| 점검 | 실제 결과 | 판정 | 캡처 |
| --- | --- | --- | --- |
| 피드 표시·스크롤 | 최상단 post-01, 마지막 post-50 본문이 JSON과 일치. 끝까지 스크롤 가능. 작성자 아바타·닉네임·날짜 표시 | 통과 | [피드](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/feed.png) · [목록 끝](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/feed-bottom.png) |
| 본문 → 상세 → 뒤로 | post-01 본문으로 상세 진입, 같은 본문·댓글 1개 표시, 키보드 자동 표시 없음(mInputShown=false). Android 뒤로가기로 피드 복귀 | 통과 | [상세](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/detail.png) |
| 댓글 아이콘 → 상세 (T15 범위) | post-01 댓글 버튼으로 같은 상세 진입. 입력창 포커스·키보드 표시(mInputShown=true), 입력창 가림 없음. 상단 화살표로 피드 복귀 | 통과 | [댓글 진입](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/detail-keyboard.png) |
| 빈 글·공백 | 빈 글 게시 버튼 비활성, 눌러도 화면 유지. 공백 3자 입력 시 `3 / 300`, 게시 비활성 | 통과 | [빈 글](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/write-empty.png) · [공백](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/write-spaces.png) |
| 300자 경계 | 영문 299자 `299 / 300` 게시 활성, 300번째 입력 시 빨간 `300 / 300`, 301번째 `C` 입력 차단·본문 300자 유지 | 통과 | [299자](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/write-299.png) · [301번째 차단](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/write-301-blocked.png) |
| 한글 조합 | 삼성 키보드로 299자 뒤 ㄱ → 가 → 각 입력. 조합 중에도 `300 / 300`을 넘지 않고 마지막 글자만 바뀜 | 통과 | [한글 조합](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/write-korean-300.png) |
| 301자 붙여넣기 | adb로는 클립보드를 채울 수 없어 titanfall7274가 폰에서 예시 301자(끝 글자 `끝`)를 직접 붙여넣음. 카운터 `300 / 300`, 본문은 `차`로 끝나 301번째 글자가 잘림 | 통과 — 사용자 직접 확인 | [301자 붙여넣기](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/write-paste-301.jpg) |
| 작성 취소 확인 | X로 확인 창 표시 → 계속 쓰기 시 300자 유지. 키보드를 내린 뒤 Android 뒤로가기로 확인 창 표시 → 버리기 시 피드 복귀, 새 글 추가 없음 | 통과 | [취소 확인](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/discard.png) |
| 새 글 게시·공백 처리 | 앞뒤 공백 2칸과 중간 줄바꿈이 있는 25자 입력 후 게시 버튼을 연달아 2회 탭(13:57:50 KST). 피드 최상단에 1개만 추가, 앞뒤 공백 제거·줄바꿈 유지, `방금 전` 표시 | 통과 | [게시 후 피드](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/feed-new-post.png) |
| 새 글 상세 | 새 글 본문으로 상세 진입, 같은 본문·작성자·`방금 전`·댓글 0개 표시 | 통과 | [새 글 상세](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/detail-new-post.png) |
| 더미 데이터 | JSON 게시글 50개·댓글 83개, 이메일·휴대폰 패턴 0건, 연결되지 않은 댓글 postId 0건. 캡처의 상태 표시줄에 개인정보 없음 | 자동 점검 통과, 사람 검토 대기 | 로컬 검색 결과 |

### 남은 항목

- T09~T13 원문 번호별 판정, 팀원 설명 확인은 그대로 남아 있습니다.
- 이 절의 빌드는 Flutter 3.47.2입니다. 3.47.5 재검증 결과는 아래 [2026-11-17 Flutter 3.47.5 재검증](#2026-11-17-flutter-3475-재검증)에 있습니다.
- 2026-11-17 개정 기준(최대 12장, `01_` 번호)에 맞춰 마지막에 취합하는 sxngwxn의 2026-11-16 캡처 12장을 `screenshots/01_feed.png`~`12_detail_new_post.png` 대표 캡처로 정했습니다. 나머지 검증 캡처는 저장소에서 지우고 촬영 대상 PR의 댓글에 보관합니다. 11-13 `36007e1` 캡처는 [PR #50](https://github.com/flutter-minifeed/mini-feed/pull/50#issuecomment-6939123682), PR #54 리뷰 캡처는 [PR #54](https://github.com/flutter-minifeed/mini-feed/pull/54#issuecomment-6939124320), 팀원별 11-16·11-17 캡처는 PR #53의 각자 검증 댓글에 있습니다. 이 문서의 캡처 링크는 삭제 전 커밋 `4a60181`에 고정했습니다.

## 2026-11-16 sxngwxn 최종 실기기 검증

PR #53의 실기기 안내에 따라 #54·#55가 포함된 main ddd04b48aee207503a26879795a7cf63b9eab280과 동일한 app/을 검사했습니다. 같은 PR 브랜치의 팀원 문서 추가 커밋 eba0914도 로컬에 함께 반영했습니다. git diff origin/main -- app에 차이가 없음을 확인했습니다.

| 항목 | 실제 기록 |
| --- | --- |
| 날짜·검사자 | 2026-11-16 · sxngwxn의 Galaxy Note10 5G, Codex 로컬 실행 보조 |
| 기기·OS | Galaxy Note10 5G (SM-N971N), Android 12 / API 31, 1080×2280 |
| Flutter / Dart | 3.47.9 stable / 3.13.7 |
| 설치 방법 | flutter build apk --debug --no-pub → USB adb install -r → 앱 실행 |
| 분석·테스트 | flutter analyze --no-pub 오류 없음, flutter test --no-pub 67개 통과 |
| Android 빌드 | 성공. 기존 SDK XML 버전 차이 경고 출력 |
| APK SHA-256 | d752dcabd0ae4158b1c336fed6ff96e203328f677767ce2a47c8fc82debb35d7 |
| 앱 실행 기록 | 첫 검사와 재촬영 후 앱 프로세스의 logcat에서 E/flutter·Unhandled Exception·RenderFlex overflow·FATAL EXCEPTION 일치 0줄 |

### 기능별 결과

| 점검 | 실제 결과 | 판정 | 캡처 |
| --- | --- | --- | --- |
| 피드 표시·스크롤 | 첫 글 「아침에 추워서 니트…」와 마지막 글 「우산 같이 쓰고 가자고…」 표시 | 통과 | [feed.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/feed.png) · [feed-bottom.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/feed-bottom.png) |
| 본문 → 상세 → 뒤로 | 같은 첫 글 본문·댓글 1개 표시, 키보드 닫힘, 피드 복귀 | 통과 | [detail.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/detail.png) |
| 댓글 아이콘 → 상세(키보드) | 같은 첫 글 상세, 입력창 포커스·키보드 표시, 입력창 가림 없음 | 통과 | [detail-keyboard.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/detail-keyboard.png) |
| 빈 글·공백만 입력 | 빈 글 0 / 300, 공백 3개 입력 시 3 / 300, 두 경우 모두 게시 비활성 | 통과 | [write-empty.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/write-empty.png) |
| 299·300·301자 경계 | A 299개 입력 후 B로 300자, 추가 C 차단, 빨간 300 / 300 유지 | 통과 | [write-301-blocked.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/write-301-blocked.png) |
| 한글 조합 경계 | A 299개 뒤 삼성 한글 키보드로 ㄱ → ㅏ 입력, 마지막 가와 300 / 300 확인 | 통과 | [write-korean-300.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/write-korean-300.png) |
| 301자 붙여넣기 | PR #53 예시 301자를 휴대폰 Chrome에서 복사해 Paste 메뉴로 붙여넣음. 끝은 잘리고 차로 끝나는 300자 유지 | 통과 | [write-paste-301.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/write-paste-301.png) |
| 작성 취소(계속 쓰기·버리기) | X → 확인 창, 계속 쓰기 → A 299개와 가 유지, 다시 X → 버리기 → 피드 복귀 | 통과 | [discard.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/discard.png) |
| 새 글 게시(1개만 추가·공백 처리) | 앞뒤 공백 각 2칸을 포함한 두 줄 37자 입력 후 게시. 공백 제거·줄바꿈 유지, 최상단 1개와 방금 전 표시 | 통과 | [write-before-post.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/write-before-post.png) · [feed-new-post.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/feed-new-post.png) |
| 새 글 상세 | Minifeed phone check와 Second line.의 두 줄 본문, 같은 작성자, 댓글 0개 | 통과 | [detail-new-post.png](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/detail-new-post.png) |

### 캡처와 확인 범위

- 위 캡처 12장은 이번 삼성폰 실행의 원본 PNG이며 자르거나 표시를 덧그리지 않았습니다. 해상도와 복사 전후 SHA-256 일치를 확인했습니다.
- 실제 붙여넣기 입력은 팀원 댓글의 301자 예시를 휴대폰 Chrome의 코드 복사 버튼으로 복사하고, Flutter 입력칸을 길게 눌러 Paste를 선택했습니다. 본문 300자와 마지막 차, 빨간 카운터를 확인했습니다.
- 최초 한글 자동 입력 시도와 게시 후 피드 촬영에는 입력 누락·이전 화면 캡처가 있었습니다. 한글은 실제 ㄱ → 가와 300자를 다시 확인했고, 피드는 앱을 재실행해 초기 데이터에서 다시 게시한 뒤 화면 갱신을 확인해 촬영했습니다. 위 파일은 재확인한 최종본입니다.
- 새 글 검사는 시험용 영어 두 줄을 사용했습니다. 한글 조합 경계는 별도 항목에서 삼성 키보드로 확인했습니다.
- README에서 상세 아바타·상대 시간이 미구현이라는 오래된 문구를 현재 공통 카드 구현에 맞게 고쳤습니다.
- T09~T13 개별 번호의 원문 대응과 팀원별 담당 흐름 설명은 기존 미확인 상태를 유지합니다. 이번 기능 검사는 PR #53의 명시된 10개 항목을 기준으로 했습니다.

### 다른 팀원의 검증 기록

| 작성자 | 보고한 기기·버전 | 기록과 캡처 |
| --- | --- | --- |
| titanfall7274 | Galaxy S23 Ultra / Android 16, main ddd04b4. 이 문서의 해당 절에 Flutter 3.47.2 / Dart 3.13.2로 기록 | 위 최신 main 실기기 검증 절과 screenshots/main-ddd04b4/ |
| gunzzzang | Galaxy A32 / Android 13, main ddd04b4, Flutter 3.47.9 / Dart 3.13.7 | [원본 댓글](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6908379511) · [캡처 11장](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/) |
| UTORY4624 | S25 Ultra / Android 17, main ddd04b4, Flutter 3.47.9 / Dart 3.13.7 | [원본 댓글](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6913792138) · [캡처 12장](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/) |

팀원의 기기 결과는 원본 문서·댓글에 보고된 내용입니다. 각자의 담당 코드 설명 확인 표와는 별도로 기록합니다.

### 갱신한 제출 검토용 ZIP

minifeed-MP1-review-ddd04b4-20261116.zip을 로컬 임시 폴더에 생성했습니다. 최상위 app/·README.md·screenshots/·prompts_log.md, 129개 파일의 ZIP 무결성을 확인했습니다. 팀원 원본 JPG 23장을 포함해 다시 생성했습니다. 앱 소스는 main ddd04b4와 같습니다. 사용자 최종 검토와 원문 T번호·팀 설명 확인은 기존 미확인 상태입니다.

## 2026-11-16 팀원 검증 자료 취합

PR #53 댓글에 올라온 검사 결과와 원본 사진을 모았습니다. 기기·도구 버전과 검사 판정은 각 작성자의 보고를 옮겼습니다. 사진 파일은 내려받은 원본 JPG이며 해상도·SHA-256과 파일 열기를 확인했습니다.

| 작성자 | 기기·OS | Flutter / Dart | 앱 소스 | 원본 캡처 |
| --- | --- | --- | --- | --- |
| sxngwxn | Galaxy Note10 5G / Android 12 | 3.47.9 stable / 3.13.7 | ddd04b4 | [12장](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-sxngwxn/) |
| titanfall7274 | Galaxy S23 Ultra / Android 16 | 3.47.2 stable / 3.13.2 | ddd04b4 | [12장](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/main-ddd04b4/) |
| gunzzzang | Galaxy A32 / Android 13 | 3.47.9 / 3.13.7 | ddd04b4 | [11장](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/) |
| UTORY4624 | S25 Ultra / Android 17 | 3.47.9 stable / 3.13.7 | ddd04b4 | [12장](https://github.com/flutter-minifeed/mini-feed/tree/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/) |

sxngwxn과 titanfall7274의 상세 결과는 위 각 검사 절에 있습니다. 아래는 이번에 취합한 두 팀원의 원본 댓글 내용과 사진입니다.

### gunzzzang

[원본 검사 결과와 첨부 사진](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6908379511)

| 항목 | 작성자가 보고한 내용 |
| --- | --- |
| 날짜 | 2026-11-16 |
| 앱 커밋 | `ddd04b4` |
| 기기·OS | Galaxy A32 (SM-A325N), Android 13 |
| Flutter / Dart | 3.47.9 / 3.13.7 |
| 설치 방법 | USB (`flutter install --debug`, PATH에 adb 없음) |
| analyze·test | 오류 없음 / 테스트 67개 통과 |

| 점검 | 결과 | 판정 |
| --- | --- | --- |
| 피드 표시·스크롤 | 첫 글 「아침에 추워서 니트…」, 마지막 「우산 같이 쓰고 가자고…」 확인 | 통과 |
| 본문 → 상세 → 뒤로 | 같은 본문·댓글 1개, 키보드 안 뜸, 뒤로가기로 피드 복귀 | 통과 |
| 댓글 아이콘 → 상세(키보드) | 입력창 커서·키보드 표시, 입력창 가림 없음 | 통과 |
| 빈 글·공백만 입력 | `0 / 300`, 게시 버튼 비활성 | 통과 |
| 299·300·301자 경계 | 300자에서 `300 / 300` 빨간색. 300자 뒤 `ㅣ` 입력 시 천지인 키보드가 마지막 `차`와 조합해 `채`로 바뀌고 글자 수는 300 유지 | 통과 |
| 한글 조합 경계 | 299자 뒤 `ㄱ`+`ㅐ`가 `개`로 조합, 300 초과 없음 | 통과 |
| 301자 붙여넣기 | 301자(끝에 `끝`) 붙여넣기 시 `끝`이 잘리고 300자 | 통과 |
| 작성 취소(계속 쓰기·버리기) | 계속 쓰기 → 내용 유지, 버리기 → 피드 복귀 | 통과 |
| 새 글 게시(1개만 추가·공백 처리) | 맨 위 1개 추가, 앞 공백 제거·줄바꿈 유지, `방금 전` | 통과 |
| 새 글 상세 | 같은 본문, 댓글 0개 | 통과 |

| 캡처 | 로컬 원본 |
| --- | --- |
| feed | [feed.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/feed.jpg) |
| feed-bottom | [feed-bottom.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/feed-bottom.jpg) |
| detail | [detail.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/detail.jpg) |
| detail-keyboard | [detail-keyboard.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/detail-keyboard.jpg) |
| write-empty | [write-empty.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/write-empty.jpg) |
| write-301-blocked | [write-301-blocked.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/write-301-blocked.jpg) |
| write-korean-300 | [write-korean-300.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/write-korean-300.jpg) |
| write-paste-301 | [write-paste-301.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/write-paste-301.jpg) |
| discard | [discard.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/discard.jpg) |
| feed-new-post | [feed-new-post.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/feed-new-post.jpg) |
| detail-new-post | [detail-new-post.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-gunzzzang/detail-new-post.jpg) |

작성자가 보고한 이상한 점은 없음입니다.

### UTORY4624

[원본 검사 결과와 첨부 사진](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6913792138)

| 항목 | 작성자가 보고한 내용 |
| --- | --- |
| 날짜 | 2026-11-16 |
| 앱 커밋 | `ddd04b4` |
| 기기·OS | S25 Ultra / Android 17 |
| Flutter / Dart | 3.47.9 stable / 3.13.7 |
| 설치 방법 | 무선 adb |
| analyze·test | 테스트 67개 통과 |

| 점검 | 결과 | 판정 |
| --- | --- | --- |
| 피드 표시·스크롤 | 첫 글 「아침에 추워서 니트…」와 마지막 글 「우산 같이 쓰고 가자고…」를 확인했습니다. | 통과 |
| 본문 → 상세 → 뒤로 | 첫 글의 본문과 댓글 1개가 표시되고 키보드는 닫혀 있었습니다. 뒤로가기 후 피드 복귀도 작동합니다. | 통과 |
| 댓글 아이콘 → 상세(키보드) | 첫 글 상세에서 키보드가 열리고 댓글 입력창이 가려지지 않았습니다. | 통과 |
| 빈 글·공백만 입력 | 빈 글에서 `0 / 300`이 표시되고 게시 버튼이 비활성화됐습니다. 공백만 입력해도 숫자가 증가합니다. | 통과 |
| 299·300·301자 경계 | 300자에서 카운터가 빨간색으로 표시됐습니다. 키보드로 한 글자 더 입력해도 본문과 `300 / 300` 표시가 그대로였습니다. | 통과 |
| 한글 조합 경계 | 마지막 글자가 `ㄱ`에서 `가`로 조합됐고 카운터는 `300 / 300`을 유지했습니다. | 통과 |
| 301자 붙여넣기 | 붙여넣기 후 카운터가 `300 / 300`이었고, 본문은 `차`로 끝났습니다. | 통과 |
| 작성 취소(계속 쓰기·버리기) | X를 누른 뒤 「작성 중인 글을 버릴까요?」 창과 두 버튼을 확인했습니다. | 통과 |
| 새 글 게시(1개만 추가·공백 처리) | 피드 맨 위에 새 글 1개가 `방금 전`으로 표시됐고 본문 줄바꿈이 유지됐습니다. | 통과 |
| 새 글 상세 | 피드와 같은 본문 및 줄바꿈이 표시되고 댓글은 0개였습니다. | 통과 |

| 캡처 | 로컬 원본 |
| --- | --- |
| feed | [feed.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/feed.jpg) |
| feed-bottom | [feed-bottom.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/feed-bottom.jpg) |
| detail | [detail.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/detail.jpg) |
| detail-keyboard | [detail-keyboard.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/detail-keyboard.jpg) |
| write-empty | [write-empty.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/write-empty.jpg) |
| write-korean-300-composing | [write-korean-300-composing.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/write-korean-300-composing.jpg) |
| write-korean-300 | [write-korean-300.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/write-korean-300.jpg) |
| write-paste-301 | [write-paste-301.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/write-paste-301.jpg) |
| discard | [discard.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/discard.jpg) |
| write-before-post | [write-before-post.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/write-before-post.jpg) |
| feed-new-post | [feed-new-post.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/feed-new-post.jpg) |
| detail-new-post | [detail-new-post.jpg](https://github.com/flutter-minifeed/mini-feed/blob/4a60181454bb3d7fb12478dadbecefc1a51bbb44/screenshots/2026-11-16-UTORY4624/detail-new-post.jpg) |

## 2026-11-17 Flutter 3.47.5 재검증

개정 기준의 Flutter 3.47.5 / Dart 3.13.4로 PR 브랜치 `4951f47`과 같은 앱 소스(main `ddd04b4`의 `app/lib`)를 빌드해 다시 확인했습니다. `pubspec.yaml`의 SDK 제약을 `sdk: ^3.13.4`, `flutter: ">=3.47.5"`로 올렸고 `pubspec.lock`은 SDK 하한 2줄만 바뀌었습니다.

| 항목 | 확인한 결과 |
| --- | --- |
| 실행 날짜·검사자 | 2026-11-17 · titanfall7274, Claude Code 로컬 실행 보조 |
| 실행 환경 | Galaxy S23 Ultra (SM-S918N), Android 16 / API 36, USB 설치·실행 |
| Flutter / Dart | 3.47.5 stable / 3.13.4 |
| 분석·테스트 | `flutter analyze` 오류 없음, `flutter test` 67개 통과 |
| Android 빌드 | `flutter build apk --debug` 성공 |
| APK SHA-256 | `56072db58f1a20e40992eb45db8024d9c74f912f8e02f60b0f552a0539720faa` |
| 앱 실행 기록 | 앱 PID logcat에서 exception·RenderFlex·overflow·FATAL 0줄, 전체 FATAL EXCEPTION 0줄 |

피드 첫 글·마지막 글, 본문·댓글 아이콘 상세 진입, 빈 글·공백 게시 비활성, 299·300·301자 경계, 한글 조합, 작성 취소(계속 쓰기·버리기), 게시 버튼 연속 2회 탭 시 1개만 추가·앞뒤 공백 제거·줄바꿈 유지, 새 글 상세를 다시 확인해 모두 통과했습니다. 게시 3~4분 뒤 피드의 새 글이 `4분 전`으로 표시되는 것도 확인했습니다. 301자 붙여넣기는 titanfall7274가 폰에서 직접 확인했습니다. 캡처는 [PR #53의 titanfall7274 검증 댓글](https://github.com/flutter-minifeed/mini-feed/pull/53#issuecomment-6939108278)에만 남깁니다.

## 2026-11-18~19 sxngwxn Flutter 3.47.5 로컬 재검증

개정된 제출 기준으로 SDK와 실행 결과를 다시 확인했습니다. 커밋·푸시·PR 편집·댓글 게시는 하지 않았습니다. 아래 결과는 Codex가 연결된 사용자 기기를 조작해 확인한 결과이며, 사용자의 최종 검토나 구두 설명을 대신하지 않습니다.

### 소스와 실행 환경

| 항목 | 실제 결과 |
| --- | --- |
| 앱 소스 | PR #53 원격 기준 `fb9fc6d686eb67c4656a0a31cfba1f31ee21fd0e`의 `app/`과 차이 없음. `app/lib`는 main `ddd04b4`와 동일 |
| Flutter / Dart | 3.47.5 stable / 3.13.4. 공식 태그 `3.47.5`, 프레임워크 `6a19cca564` |
| 기기 | Galaxy Note10 5G (SM-N971N), Android 12 / API 31, 1080×2280 |
| 의존성 | `flutter pub get --enforce-lockfile` 성공 |
| 분석·테스트 | `flutter analyze --no-pub` 오류 없음, `flutter test --no-pub --reporter expanded` 67개 통과 |
| Android 빌드·실행 | `flutter build apk --debug --no-pub` 성공, USB 설치·실행 성공 |
| APK SHA-256 | `C009333F046163C2F382224F918B315BAE228489625B9C75A3D65CFB457F0042` |
| 실행 로그 | 검사한 앱 PID의 logcat에서 E/flutter·Unhandled Exception·RenderFlex overflow·FATAL EXCEPTION 일치 0줄 |
| 빌드 경고 | SDK XML 버전 차이 경고가 있으나 빌드는 성공. SDK 약관을 추가로 자동 동의하지 않음 |

### 실제 동작

| 점검 | 확인 결과 | 대표 캡처 |
| --- | --- | --- |
| 피드·스크롤 | 첫 글과 마지막 글까지 표시, 본문·작성자·날짜·반응 수 확인 | [01_feed.png](../screenshots/01_feed.png), [02_feed_bottom.png](../screenshots/02_feed_bottom.png) |
| 본문·댓글 상세 진입 | 본문은 키보드 없이 상세 진입, 댓글 아이콘은 같은 글의 입력창·키보드 표시. 상단 뒤로 버튼으로 피드 복귀 | [03_detail.png](../screenshots/03_detail.png), [04_detail_keyboard.png](../screenshots/04_detail_keyboard.png) |
| 빈 글·공백 | 빈 글과 공백 3자 모두 게시 비활성 | [05_write_empty.png](../screenshots/05_write_empty.png) |
| 299·300·301자 | A 299자 뒤 B로 300자, 추가 C 차단·빨간 카운터 유지 | [06_write_301_blocked.png](../screenshots/06_write_301_blocked.png) |
| 한글 조합 | 삼성 키보드에서 A 299자 뒤 ㄱ → 가, 300자 유지 | [07_write_korean_300.png](../screenshots/07_write_korean_300.png) |
| 실제 301자 붙여넣기 | `가나다라마바사아자차` 30회 + `끝`을 로컬 페이지에서 복사 후 Paste 메뉴로 입력. 끝은 제외되고 차로 끝나는 300자 | [08_write_paste_301.png](../screenshots/08_write_paste_301.png) |
| 작성 취소 | 계속 쓰기는 A 299자+가 유지, 버리기는 피드 복귀 | [09_discard.png](../screenshots/09_discard.png) |
| 새 글·공백·줄바꿈 | 앞뒤 공백 각 2칸인 두 줄 33자 입력 후 1회 게시. 공백 제거·내부 줄바꿈 유지, 피드 최상단 새 글 1개와 방금 전 표시 | [10_write_before_post.png](../screenshots/10_write_before_post.png), [11_feed_new_post.png](../screenshots/11_feed_new_post.png) |
| 새 글 상세·상대 시간 | 같은 두 줄 본문·댓글 0개, 게시 약 85초 뒤 상세를 다시 열어 1분 전 확인. 나머지 시간 경계는 단위 테스트로 확인 | [12_detail_new_post.png](../screenshots/12_detail_new_post.png) |

이번 검사에서 게시 버튼을 여러 번 누르는 검사는 별도로 반복하지 않았습니다. 이전 검증과 자동 테스트의 결과를 이번 실기기 조작 결과로 바꾸어 적지 않았습니다. 최초 상대 시간 조회는 게시 25초 뒤라 정상적으로 방금 전이었고, 1분을 넘긴 뒤 다시 열어 1분 전을 확인했습니다.

### 제출 파일 점검

- 대표 12장을 위 3.47.5 빌드로 촬영한 원본 PNG로 갱신했습니다. 기존 `01_`~`12_` 이름을 유지하고 복사 전후 SHA-256 일치를 확인했습니다. 자르기·덧그리기는 하지 않았습니다.
- 게시글 50개·댓글 83개, 이메일·전화번호 패턴 0건. 캡처를 시각 확인했으며 실제 인물 사진·실명·연락처를 발견하지 못했습니다. 사용자의 최종 개인정보 검토는 별도입니다.
- README의 네 절, 데이터 파일 위치·필드 설명, 실행 명령·SDK·기기, 확인 방법별 조작·기대 결과·이미지 이름, 시험 데이터·네트워크 조건을 확인했습니다.
- 제출 검토용 ZIP은 `app/`, `README.md`, `screenshots/`만 최상위에 넣습니다. `pubspec.lock`과 Gradle wrapper properties를 포함하고 설치·빌드 산출물, Git 정보, docs, ai_logs, prompts_log는 제외합니다.
- 과거 촬영본과 ZIP 설명은 위 날짜별 기록에만 남겨 두었습니다. 현재 대표 파일은 이 절의 3.47.5 촬영본입니다.
- 이 실행·캡처 작업만을 위한 새 AI 사용 기록은 추가하지 않았습니다.

### 남은 확인

- 사용자 요청대로 T09 및 원문 T번호 대응 작업은 이번 범위에서 제외했습니다.
- 과제의 확인 방법 견본 전체를 확보하지 못해 README의 `###` 소제목이 공식 기준 이름 전체와 정확히 일치하는지는 확인 불가입니다. 현재 팀이 작성한 소제목을 임의로 바꾸지 않았습니다.
- 팀원 3명의 설명 댓글과 sxngwxn의 현재 코드 기반 설명을 위 팀 설명 절에 취합했습니다.
- 사용자 최종 파일 검토, 커밋·푸시와 GitHub 본문·댓글 갱신은 사용자가 진행합니다.
