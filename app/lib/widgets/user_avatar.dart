import 'package:flutter/material.dart';

import '../models/author.dart';
import '../theme/app_theme.dart';

/// 작성자 색 원과 닉네임 첫 글자. Figma UserAvatar와 이름을 맞춘다(R10).
///
/// 게시글 카드는 반지름 20, 댓글은 반지름 16으로 쓴다.
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.author, this.radius = 20});

  final Author author;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: userColors[author.colorIndex],
      foregroundColor: userOnColor,
      child: Text(
        author.nickName.characters.firstOrNull ?? '',
        // Figma 글자 크기는 반지름의 0.8배다(반지름 20 → 16, 16 → 13).
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: userOnColor, fontSize: radius * 0.8),
      ),
    );
  }
}
