# Firebase 연결 준비 (#12)

이 브랜치는 Firebase 패키지 추가와 앱 시작 시 초기화까지 준비한 상태입니다. 익명 로그인·고정 프로필·실패 및 재시도 처리는 아직 구현하지 않았습니다. MP1 검증용 main에 병합하기 전 선행 이슈 #11 완료를 확인합니다.

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

- Flutter 3.47.9 / Dart 3.13.7 실행 확인
- 로컬 Firebase 설정 파일과 패키지 추가 확인
- Firebase 초기화 추가 후 정적 분석 통과
- 원래 경로에서는 분석 서버가 JSON 처리 오류로 종료되어, 같은 앱 폴더를 임시 드라이브 경로로 연결한 후 `flutter analyze --no-pub` 실행: No issues found
- 위 결과는 최초 초기화 준비 시점의 기록입니다. 환경값 분리 이후의 결과는 AI 기록에 추가합니다.
- Android 빌드·실기기 실행·실제 Firebase 연결·인증·프로필 저장은 미검증
