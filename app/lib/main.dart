import 'package:flutter/material.dart';

import 'screens/feed_screen.dart';
import 'theme/app_theme.dart';

//앱 실행
void main() {
  runApp(const MyApp());
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
