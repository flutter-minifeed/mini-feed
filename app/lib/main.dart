import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'auth/firebase_session_repository.dart';
import 'auth/session_gate.dart';
import 'repository/comment/in_memory_comment_repository.dart';
import 'repository/post/in_memory_post_repository.dart';
import 'repository/repository_scope.dart';
import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

//앱 실행
// 저장소는 여기서 한 번만 만들고 RepositoryScope로 모든 화면에 공유한다.
Future<void> main() async {
  // runApp 전에 asset을 읽으려면 Flutter 엔진을 먼저 준비해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(
    SessionGate(
      repository: FirebaseSessionRepository(),
      buildSession: (author) async => RepositoryScope(
        postRepository: await InMemoryPostRepository.load(currentUser: author),
        commentRepository: await InMemoryCommentRepository.load(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미니피드',
      theme: appTheme,
      home: const FeedScreen(),
    );
  }
}
