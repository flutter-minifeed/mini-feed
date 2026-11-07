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
2. 저장소 루트에서 `cd app` 실행 후 `flutter pub get`
3. `flutter run`
