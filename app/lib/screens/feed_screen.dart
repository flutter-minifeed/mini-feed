import 'package:flutter/material.dart';

import 'detail_screen.dart';
import 'write_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('미니피드')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 임시 버튼: #7에서 게시글 카드·글쓰기 버튼으로 바뀐다.
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DetailScreen()),
              ),
              child: const Text('상세 열기'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => const WriteScreen(),
                ),
              ),
              child: const Text('글쓰기 열기'),
            ),
          ],
        ),
      ),
    );
  }
}
