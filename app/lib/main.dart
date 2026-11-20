import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'repository/comment/firestore_comment_repository.dart';
import 'repository/post/firestore_post_repository.dart';
import 'repository/repository_scope.dart';
import 'screens/feed_screen.dart';
import 'screens/session_gate.dart';
import 'service/auth/firebase_auth_service.dart';
import 'theme/app_theme.dart';

//앱 실행
// 저장소는 여기서 한 번만 만들고 RepositoryScope로 모든 화면에 공유한다.
Future<void> main() async {
  // Firebase·플랫폼 플러그인을 사용하기 전에 Flutter 엔진을 준비한다.
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
  runApp(
    SessionGate(
      authService: FirebaseAuthService(),
      buildSession: (author) async => RepositoryScope(
        postRepository: FirestorePostRepository(
          firestore: FirebaseFirestore.instance,
          currentUser: author,
        ),
        commentRepository: FirestoreCommentRepository(
          firestore: FirebaseFirestore.instance,
        ),
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
