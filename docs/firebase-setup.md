# Firebase 연결 준비 (#12)

이 브랜치는 Firebase 패키지 추가와 앱 시작 시 초기화까지 준비한 상태입니다. 익명 로그인·고정 프로필·실패 및 재시도 처리는 아직 구현하지 않았습니다. MP1 검증용 main에 병합하기 전 선행 이슈 #11 완료를 확인합니다.

## 설정 파일 준비

팀 Firebase 프로젝트에 접근할 수 있는 Google 계정으로 Firebase CLI에 로그인합니다. 팀에서 사용하는 Android applicationId는 `com.minifeed`입니다.

저장소 루트에서 다음 명령을 순서대로 실행합니다. Flutter SDK와 Firebase CLI, FlutterFire CLI가 설치되어 있어야 합니다.

```powershell
firebase.cmd login
cd app
flutter pub get
flutterfire configure --platforms=android
```

기존 팀 Firebase 프로젝트와 Android 앱을 선택합니다. 새 팀 프로젝트를 중복 생성하지 않습니다. FlutterFire 실행 경로가 PATH에 없다면 Flutter에 포함된 Dart로 실행할 수 있습니다.

```powershell
dart pub global run flutterfire_cli:flutterfire configure --platforms=android
```

다음 파일은 각 개발 환경에서 생성하고 Git에는 올리지 않습니다. 다른 환경에서 브랜치를 받은 뒤에는 위 설정 과정을 먼저 수행해야 분석·빌드가 가능합니다.

- `app/android/app/google-services.json`
- `app/lib/firebase_options.dart`
- `app/firebase.json` (FlutterFire가 생성한 플랫폼 연결 정보)

현재는 Android만 설정합니다. 웹 등 다른 플랫폼 연결과 제출용 `.env.example` 구성은 아직 완료하지 않았습니다. Firestore 접근 규칙도 별도로 구현해야 합니다.

## 확인 결과

- Flutter 3.47.9 / Dart 3.13.7 실행 확인
- 로컬 Firebase 설정 파일과 패키지 추가 확인
- Firebase 초기화 추가 후 정적 분석 통과
- 원래 경로에서는 분석 서버가 JSON 처리 오류로 종료되어, 같은 앱 폴더를 임시 드라이브 경로로 연결한 후 `flutter analyze --no-pub` 실행: No issues found
- Android 빌드·실기기 실행·실제 Firebase 연결·인증·프로필 저장은 미검증
