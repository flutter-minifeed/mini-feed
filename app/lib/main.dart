import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'repository/comment/in_memory_comment_repository.dart';
import 'repository/post/in_memory_post_repository.dart';
import 'repository/repository_scope.dart';
import 'screens/feed_screen.dart';
import 'screens/session_gate.dart';
import 'service/auth/firebase_auth_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/write_view_model.dart';

//앱 실행
// 저장소는 여기서 한 번만 만들고 RepositoryScope로 모든 화면에 공유한다.
Future<void> main() async {
  // runApp 전에 asset을 읽으려면 Flutter 엔진을 먼저 준비해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(
    SessionGate(
      authService: FirebaseAuthService(),
      buildSession: (author) async {
        final postRepository = await InMemoryPostRepository.load(
          currentUser: author,
        );
        return RepositoryScope(
          postRepository: postRepository,
          commentRepository: await InMemoryCommentRepository.load(),
          child: MyApp(
            createWriteViewModel: () =>
                WriteViewModelImpl(repository: postRepository),
          ),
        );
      },
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.createWriteViewModel});

  final WriteViewModel Function() createWriteViewModel;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '미니피드',
      theme: appTheme,
      home: FeedScreen(createWriteViewModel: createWriteViewModel),
    );
  }
}
