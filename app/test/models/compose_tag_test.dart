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

  test('여섯 번째 태그도 추가하고 형식과 대소문자 중복은 계속 검사한다', () {
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
    expect(selection.add('여행', TagSource.recommended), isNull);
    expect(selection.add('Trip_7', TagSource.manual), isNull);
    expect(selection.add('tRIP_7', TagSource.manual), isNotNull);
    expect(selection.add('여행!', TagSource.manual), isNotNull);
    selection.remove(selection.tags.last);
    expect(selection.add('Trip_7', TagSource.manual), isNull);
    expect(selection.names, ['가' * 20, '나', '다', '라', '마', '여행', 'Trip_7']);
  });
}
