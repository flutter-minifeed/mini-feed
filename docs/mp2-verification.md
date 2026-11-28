# MP2 두 실기기 검증 및 제출물 점검

- 관련 이슈 [#17](https://github.com/flutter-minifeed/mini-feed/issues/17)
- 평가·제출 기준 [MP2 완료 기준](mp2.md)
- 두 실기기 동기화, Firestore 대조, S23 오프라인 검증과 후보 ZIP 점검을 완료했다. 병합 후 제출본을 대조하고 ANT 접수 결과를 기록한다.

## 실행 준비

- [PR #62](https://github.com/flutter-minifeed/mini-feed/pull/62)와 [PR #79](https://github.com/flutter-minifeed/mini-feed/pull/79)가 반영된 앱을 사용했다. 검증 기기 A와 B의 커밋은 다르며 `app/`의 파일 내용은 동일하다. 두 기기를 같은 팀 Firebase 프로젝트에 연결했다.
- B를 무선 ADB로 검증했다. #17의 USB 연결 조건은 서로 다른 두 물리 기기에서 수행한 이번 무선 ADB 실기기 검증으로 갈음한다.
- 실행할 때는 [README](../README.md)를 따른다. 재검증할 때는 이전 글과 구분되고 개인정보가 없는 테스트 본문을 사용한다.

| 기록 항목 | 값 |
| --- | --- |
| 실행 날짜·검증 담당 | 2026-11-28 · A UTORY4624 · B titanfall7274 |
| Flutter / Dart | Flutter 3.47.5 stable / Dart 3.13.4 |
| 기기 A · 글 작성 | Galaxy S25 Ultra · Android 17 · `45333a1` · 무선 ADB로 검증용 APK 설치 |
| 기기 B · 새로고침 | Galaxy S23 Ultra · Android 16 · `fb7ded8` · 무선 ADB |
| 동기화 시험 본문 | `MP2-74-동기화-2차` |
| 오프라인 게시 실패 시험 본문 | `MP2-QA-fb7ded8-S23-retry` |
| 검증 기록 | [A 게시 전 기록](https://github.com/flutter-minifeed/mini-feed/pull/74#issuecomment-7235388447) · [B 동기화·Firestore·오프라인 QA 기록](https://github.com/flutter-minifeed/mini-feed/pull/74#issuecomment-7235013501) |

## 실기기 검증

| 점검 항목 | 절차 및 예상 결과 | 실제 결과 | 증거 |
| --- | --- | --- | --- |
| 익명 인증 | 두 기기에서 앱을 실행하고 이메일·전화번호 입력 없이 피드에 진입한다. | A는 ‘조용한 곰’, B는 ‘책읽는 펭귄’ 익명 프로필로 앱을 사용했다. 앱 소스에서 익명 인증 호출을 확인했다. | [A 게시 전](https://github.com/user-attachments/assets/7672cb2d-ec12-43c4-9c95-70e0afe03bd3) · [B 작성 화면](https://github.com/user-attachments/assets/6822e1d1-1192-4412-865d-6c79f102be40) |
| 작성 및 서버 기록 | A에서 테스트 글을 한 번 게시하고 Firestore의 본문과 서버 작성 시각을 확인한다. | Firestore에 `MP2-74-동기화-2차` 한 건이 저장됐다. 작성자는 ‘조용한 곰’이고 `createdAt`은 2026-11-28 15:26:45 KST였다. | [Firestore 기록](https://github.com/user-attachments/assets/387e3d0b-ce0c-41aa-8a92-4a4c0cc7e5d1) |
| 두 기기 동기화 | A가 게시하기 전에 B에서 피드를 열고, A가 게시한 뒤 B에서 당겨 새로고침한다. | B에 ‘새 글 1개’가 표시됐다. 알림을 누르자 A의 글이 최상단에 한 번 표시됐고 상세 본문도 같았다. | [새 글 알림](https://github.com/user-attachments/assets/7b1cfc83-9c2a-4907-92f7-c372fb8d5e86) · [B 동기화 화면](https://github.com/user-attachments/assets/980d5d2d-8b52-4294-bcf3-5d171fe59e2c) |
| 게시 실패 | B에서 글을 입력하고 비행기 모드에서 Wi-Fi도 끈 뒤 게시한다. 앱이 종료되지 않고 안내와 본문이 남아야 한다. | 실패 안내와 본문이 남았다. 연결을 켠 직후에는 재시도가 한 번 더 실패했다. 실제 통신이 복구된 뒤 재시도하니 서버에 한 건만 저장됐다. | [작성 실패 화면](https://github.com/user-attachments/assets/6822e1d1-1192-4412-865d-6c79f102be40) |
| 오프라인 읽기·재연결 | B에서 온라인으로 읽은 글을 오프라인 피드·상세에서 확인하고 연결을 복구한다. | 피드와 상세에 캐시된 본문이 표시됐고 상세 댓글 입력은 제한됐다. 재연결 후 최신 글을 다시 불러왔다는 안내가 표시됐다. | [오프라인 피드·상세와 복구 기록](https://github.com/flutter-minifeed/mini-feed/pull/74#issuecomment-7235013501) |

동기화와 익명 인증 후 피드 진입에는 온라인 연결을 사용했다. 오프라인 읽기와 게시 실패는 S23 Ultra에서 비행기 모드를 켜고 Wi-Fi를 끈 상태로 확인했다.

#17의 대조 범위는 T01~T08, T14, T28, T30 중 MP2 범위, T32, T33이다. 첫 설치 오프라인, T14의 10초 무응답 조건, T30의 네 상황 각 3회, T33의 팀원 기기 네 대는 이번 실측에서 완료 처리하지 않는다. [테스트 케이스 원문](https://app.notion.com/p/40a8d812628a8147ad06c29535a12b10)

## ANT 제출용 MP2 평가 기준

2026-11-25 ANT 2108 MP2 과제 화면에서 확인한 [평가 기준 다섯 항목](mp2.md#평가-기준)을 실기기 기록, 앱 소스, 후보 ZIP과 대조했다.

- [x] 기기 A에서 작성한 글이 기기 B의 당겨서 새로고침 후 표시된다.
- [x] 익명 인증만 사용하고 이메일·전화번호 등 개인정보를 수집하는 코드가 없다.
- [x] 작성 실패 시 종료되지 않고 실패 안내를 표시하며 입력한 본문이 유지된다.
- [x] 설정 키를 환경에서 읽고, 후보 ZIP에 실제 설정값이 없는 `.env.example`을 포함했다.
- [x] README에 BaaS 선택, 익명 인증, 백엔드 설정, 확인 방법, 실행 절차가 있다.

## README와 제출 ZIP 점검

| 제출 파일 | 확인 내용 | 원본 기록 |
| --- | --- | --- |
| `01_A_write.png` | A의 게시 전 본문 | [캡처](https://github.com/user-attachments/assets/7672cb2d-ec12-43c4-9c95-70e0afe03bd3) |
| `02_B_sync.png` | 새로고침 후 B 피드 최상단의 같은 글 | [캡처](https://github.com/user-attachments/assets/980d5d2d-8b52-4294-bcf3-5d171fe59e2c) |
| `03_firestore.png` | 같은 본문과 서버 작성 시각 | [캡처](https://github.com/user-attachments/assets/387e3d0b-ce0c-41aa-8a92-4a4c0cc7e5d1) |
| `04_offline_write.png` | 오프라인 게시 실패 안내와 입력 본문 | [캡처](https://github.com/user-attachments/assets/6822e1d1-1192-4412-865d-6c79f102be40) |

- `6d5bd4a`에서 만든 `MP2_ANT_6d5bd4a_Flutter3.47.5.zip`의 최상위 `app/`, `README.md`, `.env.example`, `screenshots/`를 확인했다. `app/.metadata`의 Flutter 리비전과 `app/pubspec.lock`, `app/android/gradle/wrapper/gradle-wrapper.properties`를 확인했다.
- README의 실행 절차에 설치·실행 명령, SDK, 검증 기기, 최소 API 26을 명시했다. 확인 방법의 다섯 평가 항목에는 조작·기대 결과·스크린샷 파일명을 기록했다. 캡처는 모두 PNG이고 한 장당 2MB 이하이다.
- ZIP에는 실제 `.env`, `google-services.json`, `docs/`, APK와 빌드 캐시가 없다. 캡처의 개인정보·설정값 노출도 확인했다.
- 압축을 푼 소스에서 `flutter analyze --no-pub` 문제 0건, `flutter test --no-pub` 202개 통과·1개 건너뜀을 확인했다. 검증용 복사본에 팀 설정을 준비하고 Android 디버그 APK 빌드와 서명, 최소 API 26을 확인했다. [#74 CI](https://github.com/flutter-minifeed/mini-feed/actions/runs/46118592294)
- #17 작업의 AI 사용 내역은 [AI 사용 기록](../ai_logs/UTORY4624/2026-11-28-issue-17.md)에 남겼다. 팀 저장소의 취합 기준은 [#6](https://github.com/flutter-minifeed/mini-feed/issues/6)을 따르며, `prompts_log.md`는 ANT 선택 제출 항목이다.

## #74 병합과 ANT 제출

1. #74 병합 후 병합된 `main`의 `app/`, `README.md`, `.env.example`을 후보 ZIP에 사용한 커밋과 대조한다. 제출 구성에 변경이 있으면 ZIP에 반영하고 관련 검사를 다시 실행한다.
2. ANT에서 MP1 통과 상태와 2108 MP2 제출 대상을 확인한 뒤 ZIP을 제출한다.
3. 제출 커밋, ZIP 파일명, ANT 접수 결과를 #17에 남긴다.
