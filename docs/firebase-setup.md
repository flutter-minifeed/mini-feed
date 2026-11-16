# Firebase 익명 인증·고정 프로필 (#12)

이 브랜치는 앱 시작 시 Firebase 초기화·익명 인증·고정 프로필 준비 후 피드에 진입합니다. 실패하면 시작 화면에서 재시도합니다. MP1 검증용 main에 병합하기 전 선행 이슈 #11 완료를 확인합니다. 게시글·댓글의 Firestore 연동은 #47의 범위입니다.

## 로컬 설정 준비

실제 값은 Git·제출 ZIP에서 제외하고, 루트 `.env.example`에는 항목 이름만 둡니다. 앱은 `firebase_config.dart`에서 빌드 시 전달된 값을 읽으며 생성된 `firebase_options.dart`를 import하지 않습니다. 현재 연결 대상은 Android입니다.

1. 저장소 루트에서 `.env.example`을 `.env`로 복사합니다. 기존 `.env`가 있으면 덮어쓰지 않습니다.
2. Firebase 콘솔 → 프로젝트 설정 → 내 앱에서 팀 Android 앱(`com.minifeed`)의 `google-services.json`을 다운로드해 `app/android/app/google-services.json`에 둡니다. 팀원에게 별도로 전달받아도 됩니다.
3. 아래 표에 따라 같은 프로젝트·앱의 값으로 `.env`를 채웁니다.

| .env 항목 | google-services.json의 항목 |
| --- | --- |
| `FIREBASE_API_KEY` | 패키지가 `com.minifeed`인 client의 `api_key[].current_key` |
| `FIREBASE_APP_ID` | 같은 client의 `client_info.mobilesdk_app_id` |
| `FIREBASE_MESSAGING_SENDER_ID` | `project_info.project_number` |
| `FIREBASE_PROJECT_ID` | `project_info.project_id` |
| `FIREBASE_STORAGE_BUCKET` | `project_info.storage_bucket` (없으면 빈 값) |

Android Gradle의 Google services 플러그인이 JSON을 읽으므로 `.env`와 JSON을 모두 준비합니다. 기존 팀 프로젝트를 사용하고 새 프로젝트를 중복 생성하지 않습니다.

## 실행과 검사

설정 준비 후 저장소 루트에서 실행합니다.

```powershell
cd app
flutter pub get
flutter analyze
flutter test
flutter devices
flutter run -d <Android_기기_ID> --dart-define-from-file=../.env
```

APK 빌드에도 같은 설정 옵션을 사용합니다.

```powershell
flutter build apk --debug --dart-define-from-file=../.env
```

`.env`는 assets에 등록하지 않습니다. 실제 값이 없어도 소스 분석·위젯 테스트는 가능하지만 Android 빌드·실행에는 로컬 설정이 필요합니다. 값을 변경하면 앱을 종료한 뒤 같은 명령으로 다시 실행합니다.

FlutterFire CLI를 다시 실행하면 생성 파일이 생길 수 있습니다. 앱에서 `firebase_options.dart`를 다시 import하지 말고 `.env`와 Android JSON의 프로젝트도 맞춥니다.

## 제출

- 포함: 앱 소스, 루트 `.env.example`, README 설정·실행 안내와 해당 MP의 필수 산출물
- 제외: `.env`, `app/android/app/google-services.json`, `app/lib/firebase_options.dart`, `app/firebase.json`, 빌드 결과·캐시
- `.gitignore`는 ZIP에서 파일을 자동으로 제외하지 않습니다. 압축 시 직접 제외하고 ZIP 내부를 확인합니다.
- 이 문서는 개발용입니다. MP2 제출 전 필요한 설정·실행 절차를 제출 대상인 루트 README에도 반영합니다. 단계 제출물 점검은 #17·#31에서 진행합니다.

설정 분리는 소스·제출물 관리 목적이며 APK 안의 Firebase 설정값을 비밀로 만드는 기능이 아닙니다. 데이터 접근 권한은 Firestore 규칙으로 별도 구현해야 합니다.

## 확인 결과

- Flutter 3.47.9 / Dart 3.13.7 사용
- 2026-11-16 정적 분석 통과, Flutter 테스트 87개 통과·기존 1개 건너뜀
- Firestore 에뮬레이터 접근 규칙 테스트 5개 통과
- Google Drive 경로의 분석 서버 문제를 피하려고 같은 저장소를 임시 드라이브 경로로 연결하여 검사
- 실기기 결과와 남은 검증은 해당 날짜 AI 기록에 작성
- 사용자 요청으로 코드와 규칙 파일을 작업 브랜치에만 올리며, 실제 Firebase 규칙은 미게시 상태
- Android 디버그 APK 빌드 통과. Z 드라이브와 C 드라이브 Pub 캐시 사이의 Kotlin 증분 캐시 오류는 앱 소스와 로컬 설정을 C 드라이브 임시 폴더로 복사하여 빌드하는 방식으로 해결

## 인증·프로필 규칙

`SessionGate`가 준비 중·실패 화면을 표시하고 `FirebaseSessionRepository`가 기존 `currentUser`를 재사용하거나 최초 익명 계정을 만듭니다. `users/{uid}`의 확정된 캐시가 있으면 재사용하고, 없으면 트랜잭션으로 기존 서버 프로필을 확인하거나 최초 프로필을 생성합니다. `createdAt`은 서버 시각입니다. 재시도해도 기존 필드를 덮어쓰지 않습니다.

UID의 UTF-8 FNV-1a 32비트 해시를 사용합니다. `anonymous_identity.dart`의 30개 수식어·30개 동물 목록에서 각각 `hash % 30`, `(hash ~/ 30) % 30` 위치를 선택하며 색은 `hash % 8`입니다. 이 알고리즘과 단어 목록은 A2를 구현하기 위한 이 PR의 선택으로, 이미 저장된 프로필을 다시 생성하지 않습니다.

인증 작업은 동시에 하나만 진행합니다. 화면은 30초 후 재시도를 허용하고 늦은 응답을 무시합니다. SDK 작업을 강제 취소하지 않으며, 진행 중인 인증 요청이 있으면 공유하므로 새 UID를 중복 생성하지 않습니다. 권한·설정 오류는 오프라인과 구분해 안내합니다.

실제 서버 규칙을 변경하기 전에 기존 규칙을 확인합니다. 루트 `firestore.rules`의 게시 방법과 접근 범위, 에뮬레이터 실행 절차는 README에 있습니다. Windows에서 Google Drive의 `node_modules` 설치가 실패하면 규칙·설정·테스트를 로컬 디스크의 임시 폴더에 같은 상대 구조로 복사하여 검사할 수 있습니다.
