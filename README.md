# Mini Feed

Flutter로 개발하는 미니 피드 팀 프로젝트입니다. 앱 소스는 저장소 루트의 `app/` 한 곳에서 관리합니다.

MP1 제출 당시의 실행·캡처 기록은 [MP1 검증 기록](docs/mp1-verification.md)에 보존합니다. 현재 앱에는 #12의 Firebase 익명 인증·고정 프로필이 추가돼 있으며, 아래 실행 절차는 이 구성을 기준으로 합니다.

## 화면 구성

| 화면 | 현재 구성 |
| --- | --- |
| 시작 | 익명 인증과 고정 프로필을 준비한 뒤 피드로 이동합니다. 첫 실행에 네트워크가 없으면 재시도를 안내합니다. |
| 피드 | 최신순 게시글을 스크롤하며 아바타·닉네임·상대 시간·본문·좋아요 수·댓글 수를 확인합니다. 본문을 누르면 상세, 댓글 아이콘을 누르면 상세의 댓글 입력창으로 이동합니다. |
| 글쓰기 | 피드의 글쓰기 버튼으로 이동합니다. 본문 입력·300자 제한·게시·작성 취소 확인을 지원합니다. 게시하면 피드 최상단에 새 글이 추가됩니다. |
| 상세 | 선택한 글의 전체 본문과 댓글 목록을 표시합니다. 뒤로가기로 피드에 돌아갑니다. 댓글 등록과 좋아요 변경은 후속 MP3 범위입니다. |

현재 피드(#7)·글쓰기(#8)·상세(#9)·상대 시간 함수(#10)가 반영돼 있습니다. 피드와 상세는 공통 게시글 카드·작성자 표시를 사용하며, 댓글에도 아바타·작성 시각이 표시됩니다.

### 화면 흐름

```text
앱 실행 → 시작 화면 → 익명 인증·프로필 준비 성공 → 피드
시작 화면 → 연결 오류 안내 → 연결 복구 후 다시 시도 → 피드
피드 → 글쓰기 → 게시 성공 → 새 글이 추가된 피드 최상단
글쓰기 → 닫기 → 작성 내용이 있으면 계속 쓰기 또는 버리기 선택
피드 본문 → 상세 → 뒤로가기 → 피드
피드 댓글 아이콘 → 상세의 댓글 입력창·키보드 → 뒤로가기 → 피드
```

## 더미 데이터 구조

게시글 50개와 댓글 83개를 JSON 배열로 저장합니다. 모두 창작한 내용입니다. 아래 예시는 각 파일의 항목 하나이며, `//` 주석은 설명을 위해 README에만 붙였습니다.

### 게시글 — [`app/assets/dummy/post/posts.json`](app/assets/dummy/post/posts.json)

작성 시각 최신순으로 저장합니다.

```jsonc
{
  "id": "post-01",                           // 게시글 ID
  "authorId": "user-03",                     // 더미 작성자 ID. "user-me"는 MP1 사용자
  "nickName": "졸린 판다",                    // 작성자 닉네임
  "colorIndex": 2,                           // 아바타 색상 번호(0~7)
  "body": "아침에 추워서 니트 입었는데 …",       // 본문. 300자 이내
  "createdAt": "2026-11-04T12:48:00+09:00",  // 작성 시각. +09:00은 한국 시간
  "likeCount": 3,                            // 좋아요 수
  "commentCount": 1,                         // 댓글 수
  "likedByMe": false                         // 현재 사용자의 좋아요 여부(true/false)
}
```

### 댓글 — [`app/assets/dummy/comment/comments.json`](app/assets/dummy/comment/comments.json)

작성 시각 오래된 순으로 저장합니다.

```jsonc
{
  "id": "post-50-c1",                        // 댓글 ID
  "postId": "post-50",                       // 댓글이 달린 게시글의 id
  "authorId": "user-11",                     // 더미 작성자 ID. "user-me"는 MP1 사용자
  "nickName": "구름 위 토끼",                  // 작성자 닉네임
  "colorIndex": 2,                           // 아바타 색상 번호(0~7)
  "body": "오늘 비 진짜 왔다갔다 하더라",          // 본문. 200자 이내
  "createdAt": "2026-10-30T13:23:00+09:00"   // 작성 시각. +09:00은 한국 시간
}
```

JSON의 `createdAt`은 고정값입니다. `likedByMe`는 화면 표시용 값이며 Firestore 공용 게시글 문서에는 저장하지 않습니다.

더미 데이터의 `user-me`는 MP1 사용자입니다. 현재 앱에서 작성하는 새 글에는 인증된 UID·닉네임·색상을 사용합니다. 게시글·댓글은 계속 메모리 저장소로 관리하므로, 앱을 완전히 종료하고 다시 실행하면 게시글·댓글 데이터는 JSON 초기 상태로 돌아갑니다. Firebase에 저장한 익명 계정·프로필은 재사용합니다.

## 실행 절차

- 프레임워크·SDK: Flutter 3.47.5 stable / Dart 3.13.4
- Android 최소 API: 24
- 기존 #12 실기기 검증 기기: Galaxy S25 Ultra (SM-S938N), Android 17 / API 37. 이번 병합본의 실기기 재검증은 별도입니다.
- MP1 캡처·검증 당시 기기: Galaxy Note10 5G (SM-N971N), Android 12 / API 31. `screenshots/`는 당시 기록입니다.
- Android 패키지 ID: `com.minifeed`

먼저 아래 [백엔드 설정](#백엔드-설정)을 준비합니다. 명령은 저장소 루트에서 시작합니다.

```bash
flutter --version          # Flutter 3.47.5 / Dart 3.13.4 확인
flutter doctor
cd app
flutter pub get --enforce-lockfile
flutter devices            # 연결한 기기 ID 확인
flutter run -d <기기_ID> --dart-define-from-file=../.env
```

`app/assets/fonts/`의 Noto Sans KR 글꼴은 오프라인에서도 한글을 같은 모양으로 표시하려고 앱에 포함했습니다.

## BaaS 선택

Firebase는 익명 인증과 Firestore를 같은 팀 프로젝트에서 사용할 수 있어 선택했습니다.

현재 게시글·댓글은 더미 데이터를 메모리에서 관리합니다. 이 데이터의 서버 연동은 #47에서 진행합니다.

## 익명 인증

Android 앱은 시작 화면에서 익명 인증과 고정 프로필을 준비한 뒤 피드로 이동합니다. 기존 익명 ID와 저장된 닉네임·색·생성 시각은 재사용합니다. 첫 실행에 연결이 없으면 재시도를 안내합니다. 이메일·전화번호를 입력받지 않습니다.

프로필을 한 번 정상적으로 저장했다면 재실행 시 확정된 로컬 캐시를 사용할 수 있습니다. 첫 프로필 생성에는 연결이 필요합니다. 앱 삭제·데이터 초기화 후에는 기존 익명 ID 복구를 보장하지 않습니다.

## 백엔드 설정

실제 값이 없는 루트 `.env.example`을 `.env`로 복사한 뒤 팀 Firebase 프로젝트의 값으로 채웁니다. 기존 `.env`가 있으면 덮어쓰지 않습니다. Firebase 콘솔 → 프로젝트 설정 → 내 앱에서 Android 앱 `com.minifeed`의 `google-services.json`을 다운로드하여 `app/android/app/`에 둡니다. 팀원에게 별도로 전달받을 수도 있습니다.

| .env 항목 | Android JSON에서 확인할 값 |
| --- | --- |
| `FIREBASE_API_KEY` | `com.minifeed` client의 `api_key[].current_key` |
| `FIREBASE_APP_ID` | 같은 client의 `client_info.mobilesdk_app_id` |
| `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` |
| `FIREBASE_PROJECT_ID` | `project_info.project_id` |
| `FIREBASE_STORAGE_BUCKET` | `project_info.storage_bucket` (없으면 빈 값) |

`.env`와 Android JSON은 같은 프로젝트·앱으로 맞춥니다. 앱은 환경값을 읽는 `firebase_config.dart`를 사용하며, FlutterFire가 생성한 `firebase_options.dart`는 가져오지 않습니다. 설정 변경 후에는 앱을 종료하고 위 실행 명령으로 다시 시작합니다.

팀 Firebase 프로젝트의 Authentication에서 익명 로그인을 활성화하고 Firestore 데이터베이스를 준비합니다. 루트 `firestore.rules`를 게시해야 첫 프로필을 저장할 수 있습니다. 팀 프로젝트 관리자가 기존 서버 규칙과 비교한 뒤 저장소 루트에서 실행합니다.

```powershell
firebase deploy --only firestore:rules --project <팀_프로젝트_ID>
```

프로필 규칙은 본인 프로필의 생성·단건 조회만 허용하며, 프로필 변경·삭제·전체 목록 조회를 차단합니다. `users/{uid}`에 `nickName`(문자열), `colorIndex`(0~7 정수), `createdAt`(서버 시각)을 저장합니다. 닉네임은 UID의 UTF-8 FNV-1a 32비트 해시로 고정된 30개 수식어와 30개 동물 이름 중에서 선택하고, 색은 해시를 8로 나눈 나머지로 결정합니다. 닉네임 중복을 허용하며 사용자 식별은 UID로 합니다.

게시글 규칙(#16)은 인증된 사용자의 목록·상세 조회와 정상 형식의 자기 글 생성을 허용합니다. 작성자는 본인 UID와 프로필의 닉네임·색상으로 기록하며, 최초 작성 시각은 서버 시각이고 두 초기 카운터는 0입니다. 빈 본문과 300개를 초과하는 Unicode 글자 묶음은 거부합니다. 가족 이모지처럼 여러 문자로 조합된 글자도 Flutter와 같은 Unicode 16 기준으로 셉니다. 인증된 사용자는 기존 게시글의 댓글을 조회할 수 있습니다. 게시글 수정·삭제와 댓글을 포함한 하위 경로 쓰기는 거부합니다.

분석과 위젯 테스트는 `app/`에서 `flutter analyze`, `flutter test`로 실행합니다. 실제 설정 없이도 이 검사는 가능합니다. Android APK 빌드는 로컬 설정을 준비한 뒤 실행합니다.

```powershell
flutter build apk --debug --dart-define-from-file=../.env
```

Firestore 접근 규칙 테스트는 **Node.js 24.12.0 이상**·Firebase CLI·Java 21 이상을 준비한 뒤 `tests/firestore/`에서 `npm ci`, `npm test`로 실행합니다. 잠금 파일의 Firebase 패키지가 Node.js 24.12.0 이상을 요구합니다. GitHub Actions의 `Firestore rules` 작업도 Node.js 24.22.3 / Firebase CLI 15.36.0 / Java 25로 같은 명령을 실행합니다. `demo-minifeed-auth` 프로젝트의 로컬 에뮬레이터에서 프로필·게시글 테스트를 순차 실행하며 실제 팀 서버에 쓰지 않습니다.

300자 기준을 앱과 서버에서 같게 적용하려고 Unicode 16의 글자 묶음을 셉니다. Firestore의 `size()`만 쓰면 가족 이모지 300개처럼 앱에서 허용하는 글도 거부되고, Unicode 속성을 한 정규식에 모두 넣으면 에뮬레이터의 길이 제한을 넘습니다. 그래서 문자 속성을 먼저 짧은 기호로 바꾸고, 짧아진 패턴으로 글자 묶음을 세도록 구성했습니다. 이 방식은 무료 Firestore 규칙에서 실행할 수 있습니다.

Firestore의 Unicode 글자 수 함수는 Dart `characters` 1.4.1이 사용하는 Unicode 16 데이터에서 생성합니다. 데이터 원본은 해당 패키지의 `third_party/Unicode_Consortium/`에 있습니다. 규칙을 다시 생성할 때 저장소 루트에서 `python tests/firestore/generate_grapheme_rules.py <Unicode_16_데이터_폴더>`를 실행합니다. 파일을 쓰지 않고 재현 여부를 검사하려면 같은 명령 뒤에 `--check`를 붙입니다.

Git·제출 ZIP에는 `.env`, `app/android/app/google-services.json`, `app/lib/firebase_options.dart`, `app/firebase.json`, 빌드 결과·캐시를 넣지 않습니다. `.gitignore`는 ZIP에서 파일을 자동 제외하지 않으므로 압축할 때 직접 제외합니다. 루트 `.env.example`과 이 설정·실행 안내는 제출물에 포함합니다.

## 확인 방법

다음은 MP1 기능의 확인 방법입니다. `스크린샷:`의 파일명은 MP1 제출 당시 캡처이며, 현재 앱의 인증·프로필 검증 결과는 PR #56과 `ai_logs/UTORY4624/`의 #12 기록에서 따로 확인합니다. 현재 앱으로 아래 항목을 확인할 때는 시작 화면의 인증·프로필 준비를 마치고 피드에서 진행합니다.

### 피드·글쓰기·상세와 더미 데이터

- 조작: 앱을 실행해 피드 첫 글의 본문을 누르고, 뒤로 돌아와 같은 글의 댓글 아이콘을 누른 뒤, 다시 뒤로 돌아와 오른쪽 아래 연필 버튼을 누른다
- 기대 결과: 피드에 더미 게시글이 표시되고, 본문을 누르면 같은 글의 상세가, 댓글 아이콘을 누르면 댓글 입력창에 커서와 키보드가 올라온 상세가, 연필 버튼을 누르면 글쓰기 화면이 열린다
- 스크린샷: 01_feed.png, 03_detail.png, 04_detail_keyboard.png, 05_write_empty.png

### 게시글 카드·스크롤

- 조작: 앱을 실행하고 피드를 끝까지 아래로 스크롤한다
- 기대 결과: 아바타·닉네임·작성 시각·본문·좋아요 수·댓글 수가 있는 카드가 최신순으로 표시되고, 마지막 글까지 스크롤된다
- 스크린샷: 01_feed.png, 02_feed_bottom.png

### 새 글 최상단 반영·상세 이동

- 조작: 연필 버튼으로 글쓰기 화면을 열어 본문을 입력하고 게시를 누른 뒤, 피드 맨 위의 새 글을 누른다
- 기대 결과: 방금 쓴 글이 피드 맨 위에 1개 추가되고, 누르면 같은 본문의 상세 화면이 열린다
- 스크린샷: 10_write_before_post.png, 11_feed_new_post.png, 12_detail_new_post.png

### 상대 시간 표시

- 조작: 새 글을 게시한 직후 피드의 작성 시각을 보고, 몇 분 뒤 그 글의 상세를 열어 다시 본다. 더미 게시글의 작성 시각과도 비교한다
- 기대 결과: 새 글은 게시 직후 `방금 전`, 몇 분 뒤 `N분 전`으로 표시된다. 7일 이상 지난 더미 게시글은 `11월 4일`처럼 날짜로 표시된다. `N시간 전`·`어제`·`N일 전`과 각 경계는 `app/test/utils/relative_time_test.dart`로 확인한다
- 스크린샷: 11_feed_new_post.png, 12_detail_new_post.png, 01_feed.png

### 글쓰기 입력 제한·작성 취소

- 조작: 글쓰기 화면에서 빈 상태로 게시 버튼을 확인하고, 300자까지 입력한 뒤 한 글자를 더 입력하거나 301자를 붙여넣는다. 이어서 왼쪽 위 X를 누른다
- 기대 결과: 빈 글에서는 게시 버튼이 비활성이고, 300자에서 카운터가 빨간색이 되며 301번째 글자는 입력되지 않는다. X를 누르면 작성 취소 확인 창이 열리고, 계속 쓰기는 내용을 유지하며 버리기는 피드로 돌아간다
- 스크린샷: 05_write_empty.png, 06_write_301_blocked.png, 07_write_korean_300.png, 08_write_paste_301.png, 09_discard.png

### 더미 데이터·스크린샷 개인정보

- 조작: `app/assets/dummy/` 아래 JSON 파일과 `screenshots/`의 이미지를 연다
- 기대 결과: 닉네임은 창작한 별명이고, 실명·연락처·실제 인물 사진이 없다
- 스크린샷: 01_feed.png, 02_feed_bottom.png, 03_detail.png, 12_detail_new_post.png

시험 데이터: `app/assets/dummy/post/posts.json`(게시글 50개), `app/assets/dummy/comment/comments.json`(댓글 83개)

네트워크: 첫 익명 인증·프로필 생성에는 온라인 연결이 필요합니다. 기존 익명 계정과 확정된 프로필 캐시가 있으면 오프라인에서도 재진입할 수 있습니다. 피드·글쓰기·상세는 앱 안의 JSON과 메모리 저장소로 동작합니다.
