import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'models/author.dart';
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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 현재 사용자는 더미 데이터의 user-me로 둔다. MP2 #12 익명 인증 결과로 바뀐다.
  const currentUser = Author(id: 'user-me', nickName: '처음 온 펭귄', colorIndex: 4);
  final postRepository = await InMemoryPostRepository.load(
    currentUser: currentUser,
  );
  final commentRepository = await InMemoryCommentRepository.load();

  runApp(
    RepositoryScope(
      postRepository: postRepository,
      commentRepository: commentRepository,
      child: const MyApp(),
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
