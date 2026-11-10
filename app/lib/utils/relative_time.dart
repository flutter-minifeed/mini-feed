/// 작성 시각과 기준 시각의 차이를 한국어로 표시한다 (#10 / B2).
/// 달력의 날짜가 아닌 경과 시간 기준이며, 외부에서 now를 고정할 수 있다.
/// 7일 이상인 날짜는 now와 같은 시간대(UTC 또는 기기 로컬)로 표시한다.
String relativeTime(DateTime createdAt, {required DateTime now}) {
  final elapsed = now.difference(createdAt);
  if (elapsed < const Duration(minutes: 1)) return '방금 전';
  if (elapsed < const Duration(hours: 1)) return '${elapsed.inMinutes}분 전';
  if (elapsed < const Duration(days: 1)) return '${elapsed.inHours}시간 전';
  if (elapsed < const Duration(days: 2)) return '어제';
  if (elapsed < const Duration(days: 7)) return '${elapsed.inDays}일 전';

  final date = now.isUtc ? createdAt.toUtc() : createdAt.toLocal();
  return '${date.month}월 ${date.day}일';
}
