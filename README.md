# Mini Feed

Flutter로 개발하는 미니 피드 팀 프로젝트입니다. 앱 소스는 저장소 루트의 `app/` 한 곳에서 관리합니다.

## 화면 구성

(#7·#8·#9 구현 후 작성)

## 더미 데이터 구조

게시글 50개와 댓글 83개를 JSON 배열로 저장합니다. 모두 창작한 내용입니다.

- [게시글](app/assets/dummy/post/posts.json): 작성 시각 최신순
- [댓글](app/assets/dummy/comment/comments.json): 작성 시각 오래된 순. `postId`로 게시글의 `id`와 연결

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `id` | 문자열 | 게시글 또는 댓글 ID |
| `authorId` | 문자열 | 작성자 ID. `user-me`는 현재 사용자 |
| `nickName` | 문자열 | 작성자 닉네임 |
| `colorIndex` | 정수 | 아바타 색상 번호(0~7) |
| `body` | 문자열 | 본문. 게시글 300자, 댓글 200자 이내 |
| `createdAt` | 문자열 | 작성 시각(예: `2026-11-04T12:48:00+09:00`). `+09:00`은 한국 시간 |
| `likeCount` | 정수 | 좋아요 수. 게시글에만 포함 |
| `commentCount` | 정수 | 댓글 수. 게시글에만 포함 |
| `likedByMe` | 불리언(`true`/`false`) | 현재 사용자의 좋아요 여부. 게시글에만 포함 |
| `postId` | 문자열 | 댓글이 달린 게시글 ID. 댓글에만 포함 |

`createdAt`은 고정값입니다. `likedByMe`는 화면 표시용 값이며 Firestore 공용 게시글 문서에는 저장하지 않습니다.

## 실행 절차

Flutter 3.47.9 stable / Dart 3.13.7, Android 최소 API 24

Android 패키지 ID: `com.minifeed`

1. `flutter doctor`로 환경 확인
2. 아래 Firebase 로컬 설정 준비
3. 저장소 루트에서 `cd app` 실행 후 `flutter pub get`
4. `flutter devices`에서 Android 기기 ID를 확인하고 실행

```powershell
flutter run -d <Android_기기_ID> --dart-define-from-file=../.env
```

## Firebase 로컬 설정 (#12 준비)

Firebase는 익명 인증과 Firestore를 같은 팀 프로젝트에서 사용할 수 있어 선택했습니다. 현재는 Android Firebase 초기화만 연결했으며 익명 인증·고정 프로필과 서버 동기화는 아직 구현하지 않았습니다.

실제 값이 없는 루트 `.env.example`을 `.env`로 복사한 뒤 팀 Firebase 프로젝트의 값으로 채웁니다. 기존 `.env`가 있으면 덮어쓰지 않습니다. Firebase 콘솔 → 프로젝트 설정 → 내 앱에서 Android 앱 `com.minifeed`의 `google-services.json`을 다운로드하여 `app/android/app/`에 둡니다. 팀원에게 별도로 전달받을 수도 있습니다.

| .env 항목 | Android JSON에서 확인할 값 |
| --- | --- |
| `FIREBASE_API_KEY` | `com.minifeed` client의 `api_key[].current_key` |
| `FIREBASE_APP_ID` | 같은 client의 `client_info.mobilesdk_app_id` |
| `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` |
| `FIREBASE_PROJECT_ID` | `project_info.project_id` |
| `FIREBASE_STORAGE_BUCKET` | `project_info.storage_bucket` (없으면 빈 값) |

`.env`와 Android JSON은 같은 프로젝트·앱으로 맞춥니다. 앱은 환경값을 읽는 `firebase_config.dart`를 사용하며, FlutterFire가 생성한 `firebase_options.dart`는 가져오지 않습니다. 설정 변경 후에는 앱을 종료하고 위 실행 명령으로 다시 시작합니다.

분석과 위젯 테스트는 `app/`에서 `flutter analyze`, `flutter test`로 실행합니다. 실제 설정 없이도 이 검사는 가능합니다. Android APK 빌드는 로컬 설정을 준비한 뒤 실행합니다.

```powershell
flutter build apk --debug --dart-define-from-file=../.env
```

Git·제출 ZIP에는 `.env`, `app/android/app/google-services.json`, `app/lib/firebase_options.dart`, `app/firebase.json`, 빌드 결과·캐시를 넣지 않습니다. `.gitignore`는 ZIP에서 파일을 자동 제외하지 않으므로 압축할 때 직접 제외합니다. 루트 `.env.example`과 이 설정·실행 안내는 제출물에 포함합니다.
