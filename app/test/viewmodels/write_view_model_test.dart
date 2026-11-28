import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

import '../helpers/test_app.dart';

void main() {
  late FakePostRepository repository;
  late WriteViewModelImpl viewModel;
  late List<WriteStatus> statuses;
  late bool disposed;

  setUp(() {
    repository = FakePostRepository();
    viewModel = WriteViewModelImpl(repository: repository);
    statuses = [];
    disposed = false;
    viewModel.addListener(() => statuses.add(viewModel.status));
  });

  tearDown(() {
    if (!disposed) viewModel.dispose();
  });

  test('저장에 성공하면 성공 상태와 저장한 게시글을 반환한다', () async {
    // when
    final post = await viewModel.submit('첫 글');

    // then
    expect(statuses, [WriteStatus.saving, WriteStatus.succeeded]);
    expect(post, same(repository.posts.single));
    expect(post?.author, same(viewModel.author));
  });

  test('게시 중 다시 눌러도 저장 요청은 한 번만 전달된다', () async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;

    // when
    final first = viewModel.submit('첫 글');
    final duplicate = await viewModel.submit('첫 글');
    gate.complete();
    await first;

    // then
    expect(repository.addedBodies, ['첫 글']);
    expect(duplicate, isNull);
  });

  test('저장 거부 후 같은 본문을 재시도하면 같은 요청 ID로 저장한다', () async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    final first = viewModel.submit('첫 글');
    gate.completeError(StateError('저장 거부'));
    await first;
    repository.blockAddUntil = null;

    // when
    final post = await viewModel.submit('첫 글');

    // then
    expect(repository.requestIds[1], repository.requestIds[0]);
    expect(post, same(repository.posts.single));
  });

  test('실패 후 태그만 수정하면 새 요청 ID와 수정한 태그를 전달한다', () async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    final first = viewModel.submit('첫 글', tags: ['여행']);
    gate.completeError(StateError('저장 거부'));
    await first;
    repository.blockAddUntil = null;

    // when
    final post = await viewModel.submit('첫 글', tags: ['제주']);

    // then
    expect(repository.requestIds.toSet(), hasLength(2));
    expect(post?.tags, ['제주']);
  });

  test('저장 오류는 실패 상태로 알리고 성공 결과를 반환하지 않는다', () async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;

    // when
    final pending = viewModel.submit('첫 글');
    gate.completeError(StateError('저장 거부'));
    final result = await pending;

    // then
    expect(viewModel.status, WriteStatus.failed);
    expect(result, isNull);
  });

  testWidgets('10초가 되기 전에는 저장 대기를 유지한다', (tester) async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    final pending = viewModel.submit('첫 글');

    // when
    await tester.pump(const Duration(milliseconds: 9999));
    final statusBeforeDeadline = viewModel.status;
    gate.complete();
    await tester.pump();
    await pending;

    // then
    expect(statusBeforeDeadline, WriteStatus.saving);
    expect(statuses, [WriteStatus.saving, WriteStatus.succeeded]);
  });

  testWidgets('10초 동안 응답이 없으면 시간 초과로 대기를 끝낸다', (tester) async {
    // given
    repository.blockAddUntil = Completer<void>();

    // when
    final pending = viewModel.submit('첫 글');
    await tester.pump(const Duration(seconds: 10));
    final result = await pending;

    // then
    expect(viewModel.status, WriteStatus.timedOut);
    expect(result, isNull);
  });

  testWidgets('시간 초과 후 늦은 성공은 성공 상태를 다시 알리지 않는다', (tester) async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    final pending = viewModel.submit('첫 글');
    await tester.pump(const Duration(seconds: 10));
    await pending;

    // when
    gate.complete();
    await tester.pump();

    // then
    expect(repository.posts, hasLength(1));
    expect(statuses, [WriteStatus.saving, WriteStatus.timedOut]);
  });

  testWidgets('시간 초과 뒤 늦은 오류는 상태를 바꾸거나 전파하지 않는다', (tester) async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    final pending = viewModel.submit('첫 글');
    await tester.pump(const Duration(seconds: 10));
    await pending;

    // when
    gate.completeError(StateError('늦은 저장 거부'));
    await tester.pump();

    // then
    expect(viewModel.status, WriteStatus.timedOut);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시간 초과 뒤 재시도하면 같은 요청 ID로 보내고 늦은 이전 응답은 무시한다', (tester) async {
    // given
    final oldGate = Completer<void>();
    repository.blockAddUntil = oldGate;
    final first = viewModel.submit('첫 글');
    await tester.pump(const Duration(seconds: 10));
    await first;
    final retryGate = Completer<void>();
    repository.blockAddUntil = retryGate;

    // when
    final retry = viewModel.submit('첫 글');
    oldGate.complete();
    await tester.pump();
    final statusAfterOldResponse = viewModel.status;
    retryGate.complete();
    await tester.pump();
    final result = await retry;

    // then
    expect(repository.requestIds.toSet(), hasLength(1));
    expect(statusAfterOldResponse, WriteStatus.saving);
    expect(result?.body, '첫 글');
  });

  testWidgets('시간 초과 뒤 수정한 본문은 새 요청 ID로 저장한다', (tester) async {
    // given
    final oldGate = Completer<void>();
    repository.blockAddUntil = oldGate;
    final first = viewModel.submit('이전 글');
    await tester.pump(const Duration(seconds: 10));
    await first;
    repository.blockAddUntil = null;

    // when
    final pending = viewModel.submit('수정한 글');
    await tester.pump();
    final result = await pending;
    oldGate.complete();
    await tester.pump();

    // then
    expect(repository.requestIds.toSet(), hasLength(2));
    expect(result?.body, '수정한 글');
    expect(statuses.last, WriteStatus.succeeded);
  });

  testWidgets('화면 해제는 대기 타이머를 끝내고 늦은 응답을 알리지 않는다', (tester) async {
    // given
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    final pending = viewModel.submit('첫 글');

    // when
    viewModel.dispose();
    disposed = true;
    final result = await pending;
    gate.complete();
    await tester.pump();

    // then
    expect(result, isNull);
    expect(statuses, [WriteStatus.saving]);
    expect(tester.takeException(), isNull);
  });
}
