import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/utils/relative_time.dart';

void main() {
  final now = DateTime.utc(2026, 11, 10, 12);
  final cases = <Duration, String>{
    const Duration(minutes: -5): '방금 전',
    Duration.zero: '방금 전',
    const Duration(seconds: 59): '방금 전',
    const Duration(seconds: 60): '1분 전',
    const Duration(minutes: 59): '59분 전',
    const Duration(minutes: 59, seconds: 59): '59분 전',
    const Duration(minutes: 60): '1시간 전',
    const Duration(hours: 23, minutes: 59, seconds: 59): '23시간 전',
    const Duration(hours: 24): '어제',
    const Duration(hours: 47, minutes: 59, seconds: 59): '어제',
    const Duration(hours: 48): '2일 전',
    const Duration(days: 6, hours: 23, minutes: 59, seconds: 59): '6일 전',
    const Duration(days: 7): '11월 3일',
    const Duration(days: 8): '11월 2일',
  };
  for (final entry in cases.entries) {
    test('${entry.key} 차이는 ${entry.value}', () {
      expect(relativeTime(now.subtract(entry.key), now: now), entry.value);
    });
  }
  test('자정을 지났어도 24시간 미만이면 시간으로 표시한다', () {
    expect(
      relativeTime(
        DateTime.utc(2026, 11, 9, 23),
        now: DateTime.utc(2026, 11, 10, 1),
      ),
      '2시간 전',
    );
  });
  test('연도가 달라도 7일 이상이면 월·일만 표시한다', () {
    expect(
      relativeTime(DateTime.utc(2025, 12, 31), now: DateTime.utc(2026, 1, 10)),
      '12월 31일',
    );
  });
  test('다른 시간대로 입력한 같은 순간은 차이가 없다', () {
    expect(
      relativeTime(DateTime.parse('2026-11-10T21:00:00+09:00'), now: now),
      '방금 전',
    );
  });
  test('UTC 기준 시각이면 UTC 달력 날짜를 사용한다', () {
    expect(
      relativeTime(DateTime.parse('2026-11-01T01:00:00+09:00'), now: now),
      '10월 31일',
    );
  });
  test('로컬 기준 시각이면 기기 시간대로 날짜를 표시한다', () {
    final createdAt = DateTime(2026, 10, 31, 23, 30);
    expect(
      relativeTime(createdAt.toUtc(), now: DateTime(2026, 11, 10)),
      '10월 31일',
    );
  });
}
