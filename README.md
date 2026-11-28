# Mini Feed

Mini Feed는 Android에서 익명으로 글을 쓰고 읽는 Flutter 앱입니다. 두 기기를 같은 Firebase 프로젝트에 연결한 뒤 한쪽에서 글을 씁니다. 다른 기기에서 피드를 아래로 당겨 새로고침하면 새 글을 확인할 수 있습니다.

[백엔드 설정](#백엔드-설정) · [실행 절차](#실행-절차) · [MP2 확인 방법](#확인-방법) · [MP1 검증 기록](https://github.com/flutter-minifeed/mini-feed/blob/fb7ded8/docs/mp1-verification.md)

## 화면 구성

| 화면 | 현재 구성 |
| --- | --- |
| 시작 | 익명 인증과 고정 프로필을 준비한 뒤 피드를 엽니다. 처음 실행할 때 네트워크에 연결되지 않으면 다시 시도하라는 안내가 나옵니다. |
| 피드 | 서버에서 최신 글부터 20개씩 불러옵니다. 아래로 당겨 새로고침하면 새 글 알림이 뜹니다. 알림을 누르면 목록 맨 위에 새 글과 구분선이 보입니다. 본문을 누르면 상세 화면이 열리고 댓글 아이콘을 누르면 상세 화면의 댓글 입력창이 열립니다. 연결이 끊기면 이전에 불러온 글과 오프라인 안내가 보입니다. 다시 연결되면 서버에서 글을 불러옵니다. |
| 글쓰기 | 피드에서 글쓰기 버튼을 눌러 300자까지 쓸 수 있습니다. 쓰던 글을 닫으면 내용을 버릴지 묻습니다. 게시하면 피드 맨 위에 새 글이 보입니다. |
| 상세 | 선택한 글의 전체 본문과 댓글 목록을 봅니다. 연결이 끊기면 저장된 본문만 볼 수 있고 댓글을 읽거나 입력할 수 없습니다. 뒤로가기를 누르면 피드로 돌아갑니다. 댓글 등록과 좋아요 변경은 MP3에서 다룹니다. |

피드(#7), 글쓰기(#8), 상세(#9) 화면과 상대 시간 함수(#10)를 구현했습니다. 피드와 상세 화면은 같은 게시글 카드와 작성자 표시를 사용합니다. 댓글에도 아바타와 작성 시각이 보입니다.

### 화면 흐름

```text
앱 실행 → 시작 화면 → 익명 인증·프로필 준비 성공 → 피드
시작 화면 → 연결 오류 안내 → 연결 복구 후 다시 시도 → 피드
피드 → 글쓰기 → 게시 성공 → 새 글이 추가된 피드 최상단
글쓰기 → 닫기 → 작성 내용이 있으면 계속 쓰기 또는 버리기 선택
피드 본문 → 상세 → 뒤로가기 → 피드
피드 댓글 아이콘 → 상세의 댓글 입력창·키보드 → 뒤로가기 → 피드
피드 → 연결 끊김 → 캐시 글·오프라인 안내 → 연결 복구(자동 재조회) → 다시 연결 안내·새 글 알림
```

### #13 피드 조회 확인

- 첫 조회에서는 커서를 생략합니다. 다음 페이지를 요청할 때는 앞선 조회에서 받은 `nextCursor`를 그대로 전달합니다. 마지막 페이지에 글이 정확히 20개 있으면 다음 페이지가 비어 있을 때 목록이 끝난 것으로 판단합니다.
- 새로고침 중에도 읽던 목록과 위치를 유지합니다. 새 글 알림을 눌러야 목록 맨 위로 이동합니다. 첫 페이지가 전부 새 글이면 새 글이 더 있을 수 있어 ‘20개 이상’으로 표시합니다. 자동 실시간 구독은 사용하지 않습니다.
- 글쓰기를 취소하면 읽던 목록의 같은 위치로 돌아갑니다. 게시에 성공하면 첫 페이지를 다시 불러옵니다. 같은 글의 상세 화면을 다시 열 때도 해당 ID로 글을 새로 조회합니다.
- 2026-11-19 로컬 검증에서 분석 오류는 없었고 Flutter 테스트 133개가 통과했습니다. 기존 테스트 1개는 건너뛰었습니다. Galaxy Note10 5G / Android 12(API 31)에서 로컬 Auth·Firestore 에뮬레이터의 글 45개를 조회하고 새 글 알림, 상세 화면 열기, 글쓰기 취소를 확인했습니다.

두 기기를 실제 팀 서버에 연결해 새 글을 확인한 절차와 결과는 [MP2 확인 방법](#확인-방법)에 있습니다.

USB 통합 검사는 로컬 데모 프로젝트만 사용합니다. 저장소 루트에서 Auth·Firestore 에뮬레이터를 켠 뒤 다른 터미널을 열어 데이터를 준비합니다. `adb`는 Android SDK의 `platform-tools`에 있습니다.

```powershell
npx --package firebase-tools@15.36.0 firebase emulators:start --only auth,firestore --project demo-minifeed-repositories
```

```powershell
# 다른 터미널, 저장소 루트에서 실행
$env:FIRESTORE_EMULATOR_HOST='127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST='127.0.0.1:9099'
cd tests/firestore
npm ci
node seed-repository-fixtures.mjs
cd ../../app
flutter pub get --enforce-lockfile
adb -s <기기_ID> reverse tcp:8080 tcp:8080
adb -s <기기_ID> reverse tcp:9099 tcp:9099
$env:MINIFEED_TEST_ARTIFACTS=Join-Path $env:TEMP 'minifeed-issue13-captures'
flutter drive --no-pub --driver test_driver/feed_integration.dart --target integration_test/feed_server_device_test.dart -d <기기_ID>
adb -s <기기_ID> reverse --remove tcp:8080
adb -s <기기_ID> reverse --remove tcp:9099
```

데이터 준비 스크립트는 `demo-minifeed-repositories` 에뮬레이터 데이터를 초기화하므로 저장소 브라우저 테스트와 USB 검사는 따로 실행합니다. USB 검사는 자체 데모 설정을 사용하므로 실제 `.env`가 필요 없습니다. 지정한 폴더에서 캡처를 확인한 뒤 PR에 첨부합니다. 검사가 끝나면 에뮬레이터를 실행한 터미널에서 Ctrl+C를 누릅니다. Android 로컬 HTTP 연결은 debug 빌드의 localhost에서만 허용합니다.

### #15 오프라인 확인

- 피드를 한 번 불러온 뒤 연결을 끊고 새로고침하면 이전에 읽은 글이 그대로 남고 ‘오프라인이에요. 이전에 불러온 글을 보여주고 있어요.’라는 안내가 뜹니다. 한 번도 글을 불러오지 못했다면 빈 피드 대신 글을 불러올 수 없다는 안내가 보입니다.
- 오프라인에서는 피드와 상세 화면이 10초마다 서버 연결을 확인합니다. ‘다시 시도’를 누르면 바로 확인합니다. 연결이 복구되면 ‘다시 연결됐어요. 최신 글을 불러왔어요.’라는 안내가 뜹니다. 새 글은 알림 칩으로만 표시해 읽던 위치를 유지합니다. 오프라인에서 새로고침해도 이미 보이던 글은 그대로 남습니다. 다시 연결됐다는 안내는 오프라인 상태에서 연결이 복구됐을 때만 뜹니다. 연결을 확인하다 시간이 초과되면 오프라인 안내를 유지하고 연결 확인을 계속합니다. 아래로 내려 다음 페이지를 읽다가 연결이 끊기면 캐시에 남은 글 일부를 목록에 덧붙이지 않습니다. 이때도 오프라인 안내와 ‘다시 불러오기’가 보입니다.
- 오프라인에서 상세 화면을 열면 저장된 본문과 댓글 수만 보입니다. 댓글 목록에는 댓글을 불러올 수 없다는 안내가 나오고 입력칸에는 ‘연결되면 댓글을 쓸 수 있어요’가 표시되어 입력할 수 없습니다. 연결되면 댓글을 자동으로 다시 불러옵니다. 기기 캐시에도 없는 글은 불러올 수 없다는 안내가 뜨고 연결이 복구되면 글을 자동으로 다시 불러옵니다.

USB로 연결한 실기기에서는 #13과 같은 로컬 데모 에뮬레이터를 사용합니다. 비행기 모드를 켜도 `adb reverse` 포트 연결은 유지되므로 앱의 Firestore 연결만 끊었다 다시 잇습니다. 실제 앱처럼 기기 저장소 캐시를 켜고 검사 전에 비웁니다. #13 절차대로 에뮬레이터와 데이터를 준비하고 `adb reverse`를 설정한 뒤 실행 대상과 캡처 폴더만 아래와 같이 바꿉니다.

```powershell
$env:MINIFEED_TEST_ARTIFACTS=Join-Path $env:TEMP 'minifeed-issue15-captures'
flutter drive --no-pub --driver test_driver/feed_integration.dart --target integration_test/offline_device_test.dart -d <기기_ID>
```

캡처는 `01_feed_offline`, `02_feed_reconnected`, `03_detail_offline`, `04_detail_reconnected` 4장입니다.

## 더미 데이터 구조

MP1과 메모리 저장소 테스트에 쓰는 게시글 50개와 댓글 83개를 JSON 배열로 저장했습니다. 모두 창작한 내용입니다. 일반 앱은 Firestore에서 글을 읽으며 이 JSON을 서버에 자동으로 올리지 않습니다. 아래는 각 파일에서 항목을 하나씩 꺼낸 예시입니다. `//` 주석은 README에만 붙였습니다.

### 게시글 — [`app/assets/dummy/post/posts.json`](app/assets/dummy/post/posts.json)

최근에 작성한 게시글부터 저장합니다.

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

먼저 작성한 댓글부터 저장합니다.

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

더미 데이터의 `user-me`는 MP1 사용자입니다. 현재 앱은 새 글에 인증된 사용자의 UID, 닉네임, 색상을 기록합니다. 일반 앱은 Firestore에서 게시글과 댓글을 읽고 새 게시글을 저장합니다. 앱을 다시 시작해도 기존 익명 계정과 프로필을 사용하며 서버에서 읽은 글은 서버에 남습니다. 댓글 등록과 좋아요 변경은 MP3에서 다룹니다.

## 실행 절차

Flutter 3.47.5 stable / Dart 3.13.4를 사용합니다. Android 패키지 ID는 `com.minifeed`이며 최소 지원 버전은 Android 8.0(API 26)입니다.

| 역할 | 2026-11-28 검증 기기 | 앱 소스 기준 |
| --- | --- | --- |
| A · 글 작성 | Galaxy S25 Ultra · Android 17 | `45333a1` |
| B · 당겨서 새로고침 | Galaxy S23 Ultra · Android 16 | `fb7ded8` |

두 커밋의 `app/` 내용은 같습니다. 아래 명령의 `<기기_ID>` 자리에 `flutter devices`에 나온 Android 기기 ID를 넣습니다. 두 기기를 함께 연결했다면 각 기기의 ID로 실행합니다.

[백엔드 설정](#백엔드-설정)을 마친 뒤 저장소 루트에서 터미널을 열고 아래 명령을 순서대로 실행합니다.

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

팀 프로젝트 하나에서 익명 인증과 Firestore를 함께 쓸 수 있어 Firebase를 선택했습니다.

게시글은 작성 시각과 문서 ID의 내림차순으로 한 번에 최대 20개씩 읽습니다. 댓글은 오래된 순서대로 읽습니다. 먼저 서버에서 조회하고 연결할 수 없을 때만 기기 캐시에서 다시 읽습니다(#15).

## 익명 인증

Android 앱을 열면 시작 화면에서 익명 인증과 고정 프로필을 준비한 뒤 피드로 이동합니다. 기존 익명 ID가 있으면 저장된 닉네임, 색, 생성 시각을 그대로 사용합니다. 처음 실행할 때 네트워크에 연결되지 않으면 다시 시도하라는 안내가 뜹니다. 이메일이나 전화번호는 입력받지 않습니다.

첫 프로필을 만들 때는 네트워크 연결이 필요합니다. 프로필을 정상적으로 저장한 뒤에는 앱을 다시 열 때 기기에 저장된 프로필을 사용할 수 있습니다. 앱을 삭제하거나 데이터를 초기화하면 기존 익명 ID를 복구하지 못할 수 있습니다.

## 백엔드 설정

저장소 루트의 `.env.example`에는 실제 설정값이 없습니다. `.env`가 없으면 예시 파일을 `.env`로 복사합니다. 기존 `.env`가 있으면 덮어쓰지 말고 팀 Firebase 프로젝트의 값이 들어 있는지 확인합니다. 아래 표에 맞춰 설정값을 채웁니다. Firebase 콘솔의 프로젝트 설정 → 내 앱에서 Android 앱 `com.minifeed`를 선택하고 `google-services.json`을 내려받아 `app/android/app/`에 넣습니다. 같은 파일을 팀원에게 받아도 됩니다.

| .env 항목 | Android JSON에서 확인할 값 |
| --- | --- |
| `FIREBASE_API_KEY` | `com.minifeed` client의 `api_key[].current_key` |
| `FIREBASE_APP_ID` | 같은 client의 `client_info.mobilesdk_app_id` |
| `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` |
| `FIREBASE_PROJECT_ID` | `project_info.project_id` |
| `FIREBASE_STORAGE_BUCKET` | `project_info.storage_bucket` (없으면 빈 값) |

`.env`에는 Android JSON과 같은 프로젝트, 같은 앱의 값을 입력합니다. 앱은 `firebase_config.dart`에서 환경값을 읽습니다. FlutterFire가 생성한 `firebase_options.dart`는 가져오지 않습니다. 설정을 바꾼 뒤에는 앱을 종료하고 실행 절차에 나온 명령으로 다시 시작합니다.

두 기기를 팀에서 이미 설정한 Firebase 프로젝트에 연결하면 양쪽에서 같은 피드를 볼 수 있습니다. 새 프로젝트를 쓴다면 Authentication의 로그인 제공업체에서 익명을 켜고 Firestore 데이터베이스를 만듭니다. 프로젝트 관리자는 배포할 규칙을 기존 서버 규칙과 비교한 뒤 저장소 루트에서 아래 명령을 실행합니다. 제출 ZIP으로 새 프로젝트를 설정할 때는 아래 링크에서 검증에 사용한 규칙 파일과 CLI 설정 파일을 받을 수 있습니다. [firestore.rules](https://github.com/flutter-minifeed/mini-feed/blob/fb7ded8/firestore.rules) · [firebase.json](https://github.com/flutter-minifeed/mini-feed/blob/fb7ded8/firebase.json)

```powershell
firebase deploy --only firestore:rules --project <팀_프로젝트_ID>
```

프로필 규칙은 본인 프로필을 만들거나 그 프로필 한 건을 읽는 것만 허용합니다. 프로필 변경, 삭제, 전체 목록 조회는 차단합니다. `users/{uid}`에 `nickName`(문자열), `colorIndex`(0~7 정수), `createdAt`(서버 시각)을 저장합니다. 닉네임은 UID의 UTF-8 FNV-1a 32비트 해시를 사용해 고정된 수식어 30개와 동물 이름 30개 중에서 하나씩 골라 만듭니다. 색은 해시를 8로 나눈 나머지로 정합니다. 닉네임은 겹칠 수 있어 사용자를 구분할 때는 UID를 씁니다.

게시글 규칙(#16)에 따라 인증된 사용자는 목록과 상세를 조회하고 정해진 형식으로 자기 글을 쓸 수 있습니다. 작성자 정보에는 본인 UID와 프로필의 닉네임, 색상을 기록합니다. 처음 게시할 때 작성 시각은 서버 시각이고 좋아요 수와 댓글 수는 모두 0입니다. 본문이 비어 있거나 Unicode 글자 묶음이 300개를 넘으면 게시를 거부합니다. 가족 이모지처럼 여러 문자로 조합된 글자도 Flutter와 같은 Unicode 16 기준으로 셉니다. 인증된 사용자는 기존 게시글의 댓글을 조회할 수 있습니다. 게시글 수정·삭제와 댓글을 포함한 하위 경로 쓰기는 거부합니다.

`app/`에서 `flutter analyze`로 코드를 분석하고 `flutter test`로 위젯 테스트를 실행합니다. 두 명령은 실제 Firebase 설정 없이도 실행할 수 있습니다. Android APK를 빌드할 때는 먼저 로컬 설정을 준비합니다.

```powershell
flutter build apk --debug --dart-define-from-file=../.env
```

Firestore 접근 규칙 테스트는 **Node.js 24.12.0 이상**·Firebase CLI·Java 21 이상을 준비한 뒤 `tests/firestore/`에서 `npm ci`, `npm test`로 실행합니다. 잠금 파일의 Firebase 패키지가 Node.js 24.12.0 이상을 요구합니다. GitHub Actions의 `Firestore rules` 작업도 Node.js 24.22.3 / Firebase CLI 15.36.0 / Java 25로 같은 명령을 실행합니다. `demo-minifeed-auth` 프로젝트의 로컬 에뮬레이터에서 프로필·게시글 테스트를 순차 실행하며 실제 팀 서버에 쓰지 않습니다.

Firestore 저장소 통합 검사를 실행하려면 Chrome을 준비하고 `app/`의 잠금 파일에 지정된 의존성을 설치합니다. 그런 다음 `tests/firestore/`에서 `npm run test:repositories`를 실행합니다. 테스트는 #16 규칙을 적용한 `demo-minifeed-repositories`용 Auth·Firestore 에뮬레이터에 연결합니다. Flutter SDK로 페이지 조회, 게시, 재시도, 댓글 읽기와 연결을 끊었다가 다시 이을 때의 캐시 조회를 검사합니다.

게시·댓글 테스트와 페이지 조회 테스트는 각 테스트 파일을 실행하기 전에 에뮬레이터 데이터를 다시 준비합니다. Windows에서는 임시 러너가 Flutter 3.47.5 웹 러너의 CanvasKit URL 경로를 보정합니다. 실행 전에는 사용 중인 Flutter를 PATH에 등록하고 앱의 의존성을 설치합니다.

앱과 서버 모두 Unicode 16의 글자 묶음을 세어 300자 제한을 적용합니다. Firestore의 `size()`만 쓰면 가족 이모지 300개처럼 앱에서 허용하는 글도 거부됩니다. Unicode 속성을 한 정규식에 모두 넣으면 에뮬레이터의 길이 제한을 넘습니다. 그래서 문자 속성을 먼저 짧은 기호로 바꾼 뒤 짧아진 패턴으로 글자 묶음을 셉니다. 이 방식은 무료 Firestore 규칙에서 실행할 수 있습니다.

Firestore의 Unicode 글자 수 함수는 Dart `characters` 1.4.1이 사용하는 Unicode 16 데이터에서 생성합니다. 원본 데이터는 해당 패키지의 `third_party/Unicode_Consortium/`에 있습니다. 규칙을 다시 만들려면 저장소 루트에서 `python tests/firestore/generate_grapheme_rules.py <Unicode_16_데이터_폴더>`를 실행합니다. 명령 끝에 `--check`를 붙이면 파일을 쓰지 않고 생성 결과가 기존 규칙과 일치하는지 확인합니다.

Git과 제출 ZIP에는 `.env`, `app/android/app/google-services.json`, `app/lib/firebase_options.dart`, `app/firebase.json`, 빌드 결과와 캐시를 넣지 않습니다. ZIP을 만들 때는 `.gitignore`가 적용되지 않으므로 압축 대상에서 직접 뺍니다. 루트의 `.env.example`과 이 설정·실행 안내는 제출물에 포함합니다.

## 확인 방법

두 기기를 같은 팀 Firebase 프로젝트에 연결합니다. 아래 스크린샷은 2026-11-28에 진행한 실기기 시험 기록입니다. 다시 시험할 때는 이전 글과 구분할 수 있도록 새 본문을 입력합니다.

### 기기 A에서 작성한 글이 기기 B에서 새로고침한 뒤 표시된다

- 조작: B에서 기존 피드를 열어 둔 뒤 A에서 글을 써서 게시합니다. B에서 피드를 아래로 당기고 ‘새 글 N개’를 누릅니다. 맨 위의 글을 열어 Firestore 콘솔의 `posts` 문서와 대조합니다.
- 기대 결과: A에서 쓴 글은 B의 피드에 한 번만 뜹니다. 본문과 닉네임은 상세 화면에서도 A에서 본 내용과 같습니다. Firestore에는 같은 본문이 한 건만 저장되고, 그 문서의 `createdAt`에 서버 작성 시각이 남습니다.
- 스크린샷: [01_A_write.png](https://github.com/user-attachments/assets/7672cb2d-ec12-43c4-9c95-70e0afe03bd3), [02_B_sync.png](https://github.com/user-attachments/assets/980d5d2d-8b52-4294-bcf3-5d171fe59e2c), [03_firestore.png](https://github.com/user-attachments/assets/387e3d0b-ce0c-41aa-8a92-4a4c0cc7e5d1)

### 익명 인증만 사용하며 이메일·전화번호 등 개인정보 수집 코드가 없다

- 조작: 앱을 열고 글쓰기 화면에서 닉네임을 확인합니다. 앱을 종료했다가 다시 열어 닉네임과 색이 그대로인지 봅니다. `app/lib/service/auth/firebase_auth_service.dart`의 `signIn`을 열어 새 사용자가 어떤 메서드로 인증하는지 확인합니다.
- 기대 결과: 이메일이나 전화번호를 입력하지 않아도 피드가 열립니다. 새 사용자는 `signInAnonymously()`로 인증합니다. 기존 익명 사용자는 앱을 다시 열어도 닉네임과 색이 같습니다.
- 스크린샷: [01_A_write.png](https://github.com/user-attachments/assets/7672cb2d-ec12-43c4-9c95-70e0afe03bd3)

### 작성 실패 시 크래시 없이 안내한다

- 조작: 온라인에서 글쓰기 화면을 열고 본문을 입력합니다. 비행기 모드를 켜고 Wi-Fi도 꺼졌는지 확인한 뒤 게시합니다. 실패 안내가 뜨면 연결을 복구하고 같은 본문으로 ‘다시 시도’를 누릅니다.
- 기대 결과: 게시에 실패하면 작성 화면에 실패 안내와 입력한 본문이 그대로 남습니다. 연결을 복구한 뒤 재시도에 성공하면 피드로 돌아옵니다. 서버에는 같은 글이 한 건만 남습니다. 실기기에서는 Wi-Fi를 다시 켠 직후에도 게시에 실패한 경우가 있었습니다.
- 스크린샷: [04_offline_write.png](https://github.com/user-attachments/assets/6822e1d1-1192-4412-865d-6c79f102be40)

### 설정 키를 하드코딩하지 않고, `.env.example`만 제출한다

- 조작: 제출 ZIP에서 루트의 `.env.example`과 `app/lib/firebase_config.dart`를 열어 봅니다. 압축 파일 목록에 실제 `.env`와 `google-services.json`이 없는지도 확인합니다.
- 기대 결과: 예시 파일의 Firebase 설정값은 비어 있습니다. 앱을 실행할 때 로컬에서 실제 프로젝트 설정을 넘기면 앱이 `String.fromEnvironment`로 값을 읽습니다.
- 스크린샷: 해당 없음 (소스와 압축 파일 확인)

### README에 BaaS 선택·익명 인증·백엔드 설정·확인 방법·실행 절차 절이 있다

- 조작: 이 문서의 백엔드 설정과 실행 절차에 따라 앱을 실행합니다. 위 절차대로 A에서 쓴 글이 B에 뜨는지 확인한 뒤 연결을 끊고 게시해 실패 안내를 확인합니다.
- 기대 결과: Firebase를 선택한 이유, 익명 사용자 식별 방식, 필요한 설정값, SDK 버전, 검증 기기와 실행 명령을 찾을 수 있습니다. 제출 폴더의 캡처 파일명은 각 평가 항목에 적힌 이름과 일치합니다.
- 스크린샷: 해당 없음 (README와 제출 파일명 확인)

**시험 데이터** — 동기화 시험은 A의 익명 닉네임 `조용한 곰`, 본문 `MP2-74-동기화-2차`를 사용했습니다. Firestore에 기록된 시각은 2026-11-28 15:26:45(한국 시각)입니다. 작성 실패 시험은 B에서 별도 본문 `MP2-QA-fb7ded8-S23-retry`로 진행했습니다.

**네트워크** — 동기화와 첫 익명 인증은 온라인에서 확인했습니다. 작성 실패를 시험할 때는 비행기 모드를 켜고 Wi-Fi도 껐습니다. 다시 연결하기 전에도 피드와 상세 화면에는 캐시에 남은 글의 본문이 보였고 상세 화면의 댓글 입력칸은 비활성화돼 있었습니다.
