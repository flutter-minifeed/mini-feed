import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/models/compose_tag.dart';

void main() {
  test('직접 입력 태그만 확정 순서대로 분석에 전달하고 추천을 제거하면 다시 추가할 수 있다', () {
    // given
    final selection = ComposeTags();
    selection.add(' #Jeju ', TagSource.manual);
    selection.add('운동·건강', TagSource.recommended);
    selection.add('사진_2', TagSource.manual);

    // when
    expect(selection.add('jeju', TagSource.manual), isNotNull);
    selection.remove(selection.tags[1]);
    expect(selection.add('운동·건강', TagSource.recommended), isNull);

    // then
    expect(selection.manualTags, ['Jeju', '사진_2']);
    expect(selection.names, ['Jeju', '사진_2', '운동·건강']);
  });

  test('형식이 틀리거나 여섯 번째인 태그는 목록에 들어가지 않는다', () {
    // given
    final selection = ComposeTags();

    // when
    for (final invalid in ['#', '##여행', '제주 여행', '운동·건강', '가' * 21]) {
      expect(selection.add(invalid, TagSource.manual), isNotNull);
    }
    for (final name in ['가' * 20, '나', '다', '라', '마']) {
      expect(selection.add(name, TagSource.manual), isNull);
    }

    // then
    expect(selection.add('바', TagSource.recommended), isNotNull);
    expect(selection.names, hasLength(5));
  });
}
