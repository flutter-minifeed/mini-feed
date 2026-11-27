/// 서버에 연결할 수 없고 기기 캐시로도 요청을 채울 수 없을 때 저장소가 던진다(#15).
///
/// 화면은 Firestore 오류 코드 대신 이 타입으로 오프라인 상태를 구분한다.
/// 저장 시한 초과를 `TimeoutException`으로 바꿔 전달하는 것과 같은 이유다.
class OfflineException implements Exception {
  const OfflineException();

  @override
  String toString() => 'OfflineException: 서버에 연결할 수 없습니다.';
}
