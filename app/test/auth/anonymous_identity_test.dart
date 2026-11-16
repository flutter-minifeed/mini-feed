import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/auth/anonymous_identity.dart';

void main() {
  test('같은 UID로 다시 생성하면 닉네임과 색이 유지된다', () {
    // given
    final first = anonymousAuthor('user-a');
    // when
    final again = anonymousAuthor('user-a');
    // then: FNV-1a 고정 벡터. 실행별 String.hashCode를 사용하지 않는다.
    expect(first.nickName, '용감한 치타');
    expect(first.colorIndex, 4);
    expect(again.nickName, first.nickName);
    expect(again.colorIndex, first.colorIndex);
    expect(again.id, 'user-a');
  });
  test('서로 다른 UID는 각자의 표시 정보와 ID를 받는다', () {
    // given / when
    final user = anonymousAuthor('user-b');
    // then
    expect(user.nickName, '졸린 사슴');
    expect(user.colorIndex, 5);
    expect(user.id, 'user-b');
    final colors = {
      for (var i = 0; i < 200; i++) anonymousAuthor('uid-$i').colorIndex,
    };
    expect(colors, {0, 1, 2, 3, 4, 5, 6, 7});
  });
  test('빈 UID는 프로필을 생성하지 않는다', () {
    expect(() => anonymousAuthor(''), throwsArgumentError);
  });
}
