# Mini Feed

Flutter로 개발하는 미니 피드 팀 프로젝트입니다. 앱 소스는 저장소 루트의 `app/` 한 곳에서 관리합니다.

[이슈 #3](https://github.com/flutter-minifeed/mini-feed/issues/3)의 기본 프로젝트를 준비한 상태입니다. 현재 화면은 Flutter 기본 카운터 예제이며, 피드·글쓰기·상세 기능은 후속 이슈에서 구현합니다.

## 개발 환경

Flutter 3.47.2에서 프로젝트를 생성한 뒤 아래 환경으로 업데이트하여 검사했습니다. 팀에서는 Flutter 3.47.9 stable을 기준으로 같은 버전을 사용합니다. 설치 버전은 `flutter --version`으로 확인합니다.

| 항목 | 확인한 값 |
| --- | --- |
| Flutter / Dart | 3.47.9 stable / 3.13.7 |
| JDK / Java·Kotlin 컴파일 대상 | 로컬 Android Studio JBR 21.0.10 / 17 |
| Android Gradle Plugin / Kotlin | 9.1.0 / 2.4.0 |
| Gradle | 9.3.1 |
| compileSdk / targetSdk | Flutter 기본값을 참조하며 현재 SDK에서 36 / 36 |
| Android 최소 API | `minSdk = 24`로 명시 |
| NDK | Flutter 기본값을 참조하며 현재 SDK에서 28.2.13676358 |
| Android applicationId / namespace | `com.minifeed.minifeed` — 현재 적용값이며 팀 최종 확인 필요 |
| cupertino_icons | pubspec.lock에 1.0.9 |
| flutter_lints / lints | pubspec.lock에 6.0.0 / 6.1.0 |

Flutter SDK는 [공식 아카이브](https://docs.flutter.dev/install/archive)에서 지정 버전을 준비합니다. `flutter upgrade`는 실행 시점의 채널 최신 버전으로 바뀌므로 특정 버전을 고정하는 명령이 아닙니다. Dart는 Flutter에 포함됩니다.

`pubspec.yaml`의 `sdk: ^3.13.2`는 허용 범위이고, 위 표의 Dart 3.13.7도 포함합니다. 패키지 버전은 `app/pubspec.lock`을 함께 공유합니다. Firebase·tflite 패키지나 계정·키는 현재 기본 앱에 필요하지 않습니다.

## 설치와 Chrome 실행

이미 클론한 저장소 루트에서 실행합니다. 앱이 이미 있으므로 `flutter create`를 다시 실행하거나 `app/app`을 만들지 않습니다.

```powershell
cd app
flutter --version
flutter pub get
flutter run -d chrome
```

Windows에서 이 작업에 사용한 SDK 경로는 `C:\src\flutter`입니다. `Get-Command flutter`가 한글 사용자 폴더의 이전 SDK를 가리키면 경로를 확인하고 VS Code와 터미널을 완전히 종료한 뒤 다시 엽니다. 이 PC에서는 아래처럼 SDK를 직접 지정할 수도 있습니다.

```powershell
Set-Location C:\dev\minifeed\app
& C:\src\flutter\bin\flutter.bat --version
& C:\src\flutter\bin\flutter.bat pub get
& C:\src\flutter\bin\flutter.bat run -d chrome
```

Chrome에서 기본 카운터 화면이 표시되는지, `+` 버튼을 누르면 숫자가 증가하는지 확인합니다. 실행한 터미널에서 `q`를 누르면 종료합니다.

## 코드 검사와 웹 빌드

아래 명령은 모두 `app/`에서 실행합니다.

```powershell
flutter analyze
flutter test
flutter build web --no-pub
```

## 실제 검증 결과 — 2026-11-03

| 항목 | 결과 |
| --- | --- |
| Flutter 3.47.9 / Dart 3.13.7 버전 | 실행 확인 |
| flutter pub get | 성공 |
| flutter analyze | 문제 없음 |
| flutter test | 기본 카운터 위젯 테스트 1개 통과 |
| flutter build web --no-pub | 성공, build/web 생성 |
| Chrome 실행 | 업데이트 전 3.47.2에서 디버거 연결과 main 진입 로그 확인 |
| Chrome 화면·실제 버튼 조작 | 자동화 도구가 브라우저 주소를 판별하지 못해 직접 확인 미완료 |
| 업데이트 후 3.47.9의 Chrome 실행 | 웹 빌드는 성공했으나 Chrome 재실행·화면 확인 미실행 |
| Android 빌드·USB 실기기 실행 | 미실행 |
| GitHub CI·팀원 리뷰 | 로컬 검사와 별개이며 아직 확인하지 않음 |

Chrome 실행 로그나 웹 빌드 성공으로 Android 실기기 검증을 완료 처리하지 않습니다. 이전 impellerc SIGSEGV·셰이더 오류의 원인과 Android에서의 재발 여부도 확정하지 않았습니다.

## Android에서 남은 작업

Android SDK 환경 설정과 빌드, 실기기 검증은 아직 완료하지 않았습니다. 이전 환경 진단에서 Command-line Tools 누락과 라이선스 상태 확인 불가가 나왔습니다.

1. Android Studio SDK Manager에서 Command-line Tools와 프로젝트에 필요한 SDK Platform 36, Build-Tools, NDK 등 설치 상태를 확인하고 준비합니다.
2. `app/`에서 `flutter doctor --android-licenses`를 실행하여 필요한 약관을 읽고 동의한 뒤 `flutter doctor`로 다시 진단합니다.
3. `app/`에서 `flutter build apk --debug`로 Android 빌드를 확인합니다.
4. 각 팀원이 USB Android 기기를 연결하고 `flutter devices`에 표시된 기기 ID로 `flutter run -d <기기_ID>`를 실행합니다.
5. 담당자가 4명의 결과를 이슈 #3에 취합합니다. 기록 항목은 담당자·기기 모델·Android/API 버전·실행한 커밋·성공/실패·남은 오류입니다. 기기가 없는 팀원의 검증 방법은 팀과 조율합니다.

패키지 ID를 팀에서 확정하고 Android 빌드와 4명 실기기 검증 결과를 확인하기 전까지 이슈 #3 전체 완료를 선언하지 않습니다.

## AI 사용 기록

이 작업의 실제 AI 사용 기록은 [sxngwxn의 이슈 #3 기록](ai_logs/sxngwxn/2026-11-03-issue-3.md#ai-20261103-sxngwxn-01)에 남깁니다. 제출용 `prompts_log.md` 취합과 공통 CI·PR 양식 구성은 이슈 #6의 담당 범위입니다.
