import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minifeed/screens/write_screen.dart';
import 'package:minifeed/repository/post/post_repository.dart';
import 'package:minifeed/viewmodels/write_view_model.dart';

import '../helpers/fake_write_view_model.dart';
import '../helpers/test_app.dart';

Future<FakePostRepository> pumpWriteScreen(
  WidgetTester tester, {
  FakePostRepository? repository,
  WriteViewModel? viewModel,
  List<String> recommendedTags = const [],
}) async {
  final postRepository = repository ?? FakePostRepository();
  final writeViewModel =
      viewModel ?? WriteViewModelImpl(repository: postRepository);
  final navigatorKey = GlobalKey<NavigatorState>();

  await tester.pumpWidget(
    MaterialApp(navigatorKey: navigatorKey, home: const Scaffold()),
  );

  navigatorKey.currentState!.push(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => WriteScreen(
        viewModel: writeViewModel,
        recommendedTags: recommendedTags,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return postRepository;
}

void main() {
  testWidgets('추천과 직접 입력한 칩이 줄바꿈되고 실패 후 같은 여섯 태그로 재시도한다', (tester) async {
    // given
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repository = await pumpWriteScreen(
      tester,
      recommendedTags: ['운동·건강', '여행'],
    );
    expect(find.text('이런 주제의 글 같아요'), findsOneWidget);
    expect(find.text('선택한 태그만 게시글에 추가돼요'), findsOneWidget);
    await tester.enterText(find.byKey(const ValueKey('post-body')), '달리기');
    await tester.tap(find.text('운동·건강'));
    await tester.pump();
    await tester.tap(find.byTooltip('운동·건강 제거'));
    await tester.pump();
    expect(find.text('#운동·건강'), findsNothing);
    await tester.tap(find.text('운동·건강'));
    await tester.pump();
    const names = ['운동·건강', 'Run', '제주여행', '친구', '휴식', '주말달리기'];
    for (final name in names.skip(1)) {
      await tester.enterText(
        find.widgetWithText(TextField, '#태그 입력'),
        ' #$name ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
    }
    expect(
      tester.getCenter(find.text('#주말달리기')).dy,
      greaterThan(tester.getCenter(find.text('#운동·건강')).dy),
    );
    final gate = Completer<void>();
    repository.blockAddUntil = gate;

    // when
    await tester.tap(_postButton);
    gate.completeError(StateError('저장 거부'));
    await tester.pumpAndSettle();

    // then
    expect(find.text('올리지 못했어요. 입력한 글은 그대로 있어요.'), findsOneWidget);
    expect(find.text('#Run'), findsOneWidget);
    expect(find.text('#운동·건강'), findsOneWidget);
    expect(find.text('달리기'), findsOneWidget);
    repository.blockAddUntil = null;
    await tester.tap(find.text('다시 시도'));
    await tester.pumpAndSettle();
    expect(repository.posts.single.tags, names);
    expect(repository.requestIds.toSet(), hasLength(1));
  });

  testWidgets('문서 용량을 초과하면 입력을 보존하고 태그를 줄여 게시할 수 있다', (tester) async {
    final repository = await pumpWriteScreen(tester, recommendedTags: ['여행']);
    await tester.enterText(find.byKey(const ValueKey('post-body')), '달리기');
    await tester.tap(find.text('여행'));
    await tester.pump();
    final gate = Completer<void>();
    repository.blockAddUntil = gate;
    await tester.tap(_postButton);
    gate.completeError(const PostTooLargeException());
    await tester.pumpAndSettle();

    expect(find.textContaining('저장 용량을 넘었어요'), findsOneWidget);
    expect(find.text('#여행'), findsOneWidget);
    expect(find.text('달리기'), findsOneWidget);
    await tester.tap(find.byTooltip('여행 제거'));
    await tester.pump();
    repository.blockAddUntil = null;
    await tester.tap(_postButton);
    await tester.pumpAndSettle();
    expect(repository.posts.single.body, '달리기');
    expect(repository.posts.single.tags, isEmpty);
  });

  testWidgets('추천을 제거하고 직접 입력 태그만 남겨도 닫기 전에 확인한다', (tester) async {
    // given
    await pumpWriteScreen(tester, recommendedTags: ['여행']);
    await tester.tap(find.text('여행'));
    await tester.pump();
    await tester.tap(find.byTooltip('여행 제거'));
    await tester.enterText(find.widgetWithText(TextField, '#태그 입력'), '제주');
    await tester.pump();
    await tester.tap(find.byTooltip('태그 추가'));
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(AlertDialog), findsOneWidget);
    await tester.tap(find.text('계속 쓰기'));
    await tester.pumpAndSettle();
    expect(find.text('#제주'), findsOneWidget);
    expect(find.text('#여행'), findsNothing);
    expect(_canPost(tester), isFalse);
  });

  group('게시 실패와 시간 초과', () {
    late FakePostRepository repository;

    setUp(() {
      repository = FakePostRepository();
    });

    testWidgets('FakeViewModel이 실패하면 하단에 다시 시도 안내가 보인다', (tester) async {
      // given
      await pumpWriteScreen(tester, viewModel: FakeWriteViewModel());
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();

      // when
      await tester.tap(_postButton);
      await tester.pumpAndSettle();

      // then
      expect(find.text('올리지 못했어요. 입력한 글은 그대로 있어요.'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);
    });

    testWidgets('FakeViewModel이 시간 초과를 알리면 결과 불확실성을 안내한다', (tester) async {
      // given
      await pumpWriteScreen(tester, viewModel: FakeWriteViewModel.timedOut());
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();

      // when
      await tester.tap(_postButton);
      await tester.pumpAndSettle();

      // then
      expect(
        find.text('응답이 늦어요. 입력한 글은 그대로 있고, 요청한 글은 나중에 게시될 수 있어요.'),
        findsOneWidget,
      );
    });

    testWidgets('저장이 거부되면 원본 본문을 유지하고 다시 편집할 수 있다', (tester) async {
      // given
      final gate = Completer<void>();
      repository.blockAddUntil = gate;
      await pumpWriteScreen(tester, repository: repository);
      await tester.enterText(
        find.byKey(const ValueKey('post-body')),
        '  첫 줄\n둘째 줄  ',
      );
      await tester.pump();

      // when
      await tester.tap(_postButton);
      gate.completeError(StateError('저장 거부'));
      await tester.pumpAndSettle();

      // then
      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('post-body')),
      );
      expect(field.controller!.text, '  첫 줄\n둘째 줄  ');
      expect(field.readOnly, isFalse);
      expect(_canPost(tester), isTrue);
    });

    testWidgets('실패 안내의 다시 시도를 누르면 같은 요청 ID로 저장하고 닫힌다', (tester) async {
      // given
      final gate = Completer<void>();
      repository.blockAddUntil = gate;
      await pumpWriteScreen(tester, repository: repository);
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();
      await tester.tap(_postButton);
      gate.completeError(StateError('저장 거부'));
      await tester.pumpAndSettle();
      repository.blockAddUntil = null;

      // when
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();

      // then
      expect(repository.requestIds, hasLength(2));
      expect(repository.requestIds.toSet(), hasLength(1));
      expect(find.byType(WriteScreen), findsNothing);
    });

    testWidgets('게시 중에는 본문을 편집할 수 없다', (tester) async {
      // given
      final gate = Completer<void>();
      repository.blockAddUntil = gate;
      await pumpWriteScreen(tester, repository: repository);
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();

      // when
      await tester.tap(_postButton);
      await tester.pump();
      final readOnly = tester
          .widget<TextField>(find.byKey(const ValueKey('post-body')))
          .readOnly;
      gate.complete();
      await tester.pumpAndSettle();

      // then
      expect(readOnly, isTrue);
    });

    testWidgets('10초 무응답이면 본문을 유지하고 늦은 성공에도 화면을 닫지 않는다', (tester) async {
      // given
      final gate = Completer<void>();
      repository.blockAddUntil = gate;
      await pumpWriteScreen(tester, repository: repository);
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();
      await tester.tap(_postButton);
      await tester.pump(const Duration(seconds: 10));

      // when
      gate.complete();
      await tester.pumpAndSettle();

      // then
      expect(repository.posts, hasLength(1));
      expect(find.byType(WriteScreen), findsOneWidget);
      expect(find.text('작성한 글'), findsOneWidget);
      expect(_canPost(tester), isTrue);
    });

    testWidgets('실패 후 닫기 확인에서 계속 쓰기를 고르면 본문이 남는다', (tester) async {
      // given
      await pumpWriteScreen(tester, viewModel: FakeWriteViewModel());
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();
      await tester.tap(_postButton);
      await tester.pumpAndSettle();

      // when
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('계속 쓰기'));
      await tester.pumpAndSettle();

      // then
      expect(find.byType(WriteScreen), findsOneWidget);
      expect(find.text('작성한 글'), findsOneWidget);
    });

    testWidgets('시간 초과 후 버리기를 고르면 화면과 실패 안내가 닫힌다', (tester) async {
      // given
      await pumpWriteScreen(tester, viewModel: FakeWriteViewModel.timedOut());
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();
      await tester.tap(_postButton);
      await tester.pumpAndSettle();

      // when
      await tester.tap(find.byType(CloseButton));
      await tester.pumpAndSettle();
      final warningVisible = find
          .text('입력한 본문은 사라져요. 이미 요청한 글은 나중에 게시될 수 있어요.')
          .evaluate()
          .isNotEmpty;
      await tester.tap(find.text('버리기'));
      await tester.pumpAndSettle();

      // then
      expect(warningVisible, isTrue);
      expect(find.byType(WriteScreen), findsNothing);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('저장 중 화면이 해제되면 늦은 응답이 화면 오류를 만들지 않는다', (tester) async {
      // given
      final gate = Completer<void>();
      repository.blockAddUntil = gate;
      await pumpWriteScreen(tester, repository: repository);
      await tester.enterText(find.byKey(const ValueKey('post-body')), '작성한 글');
      await tester.pump();
      await tester.tap(_postButton);
      await tester.pump();

      // when
      await tester.pumpWidget(const SizedBox.shrink());
      gate.complete();
      await tester.pump();

      // then
      expect(tester.takeException(), isNull);
      expect(find.byType(WriteScreen), findsNothing);
    });
  });

  testWidgets('글쓰기를 열면 새 글의 작성자 닉네임이 보인다', (tester) async {
    // when
    await pumpWriteScreen(tester);

    // then
    expect(find.text(testUser.nickName), findsOneWidget);
  });

  testWidgets('본문이 비어 있으면 게시할 수 없다', (tester) async {
    // when
    await pumpWriteScreen(tester);

    // then
    expect(_canPost(tester), isFalse);
  });

  testWidgets('공백 및 줄바꿈만 입력하면 게시할 수 없습니다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byKey(const ValueKey('post-body')), '  \n\n  ');
    await tester.pump();

    // then
    expect(_canPost(tester), isFalse);
  });

  testWidgets('한글 299자에서는 카운터가 기본색이어야 한다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byKey(const ValueKey('post-body')), '가' * 299);
    await tester.pump();

    // then
    expect(_counterColor(tester, '299 / 300'), isNot(_errorColor(tester)));
  });

  testWidgets('글자 수가 바뀌면 스크린리더가 카운터를 읽도록 표시된다', (tester) async {
    // given: 테스트에서는 접근성 정보를 켜야 Semantics를 확인할 수 있다.
    final semantics = tester.ensureSemantics();
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byKey(const ValueKey('post-body')), '안녕');
    await tester.pump();

    // then
    expect(
      tester.getSemantics(find.text('2 / 300')),
      isSemantics(label: '2 / 300', isLiveRegion: true),
    );
    semantics.dispose();
  });

  testWidgets('키보드를 내린 뒤 글 아래 빈 곳을 누르면 키보드가 다시 올라온다', (tester) async {
    // given: 입력칸에서 포커스가 빠져 키보드가 내려간 상태
    await pumpWriteScreen(tester);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(tester.testTextInput.isVisible, isFalse);

    // when: 입력칸이 아닌 화면 아래쪽을 누른다.
    await tester.tapAt(const Offset(400, 500));
    await tester.pump();

    // then
    expect(tester.testTextInput.isVisible, isTrue);
  });

  testWidgets('글자를 입력하면 게시가 가능합니다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byKey(const ValueKey('post-body')), '  안녕\n');
    await tester.pump();

    // then
    expect(_canPost(tester), isTrue);
  });

  testWidgets('한글 300자가 되면 카운터가 강조된다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byKey(const ValueKey('post-body')), '가' * 300);
    await tester.pump();

    // then
    expect(_counterColor(tester, '300 / 300'), _errorColor(tester));
  });

  testWidgets('한글 301자를 붙여넣으면 300자까지만 남는다', (tester) async {
    // given
    await pumpWriteScreen(tester);

    // when
    await tester.enterText(find.byKey(const ValueKey('post-body')), '가' * 301);
    await tester.pump();

    // then
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('post-body')),
    );
    expect(field.controller!.text, '가' * 300);
    expect(find.text('300 / 300'), findsOneWidget);
  });

  testWidgets('iOS에서 한글 조합 중 301자가 되면 게시할 수 없다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.showKeyboard(find.byKey(const ValueKey('post-body')));

    // when: 301번째 글자를 아직 조합 중인 상태
    // iOS는 조합이 끝날 때까지 maxLength를 넘는 입력을 허용한다.
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: '가' * 301,
        selection: const TextSelection.collapsed(offset: 301),
        composing: const TextRange(start: 300, end: 301),
      ),
    );
    await tester.pump();

    // then
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('post-body')),
    );
    expect(field.controller!.text, hasLength(301));
    expect(_canPost(tester), isFalse);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('게시하면 앞뒤 공백만 지운 본문이 저장되고 화면이 닫힌다', (tester) async {
    // given
    final repository = await pumpWriteScreen(tester);
    await tester.enterText(
      find.byKey(const ValueKey('post-body')),
      '  첫 줄\n\n둘째 줄  ',
    );
    await tester.pump();

    // when
    await tester.tap(_postButton);
    await tester.pumpAndSettle();

    // then
    expect(repository.addedBodies, ['첫 줄\n\n둘째 줄']);
    expect(find.byType(WriteScreen), findsNothing);
  });

  testWidgets('게시 중에는 다시 눌러도 한 번만 저장한다', (tester) async {
    // given: 저장이 끝나지 않고 멈춰 있는 상태
    final repository = await pumpWriteScreen(tester);
    repository.blockAddUntil = Completer<void>();
    await tester.enterText(find.byKey(const ValueKey('post-body')), '안녕');
    await tester.pump();

    // when
    await tester.tap(_postButton);
    await tester.pump();
    await tester.tap(_postButton);
    await tester.pump();

    final canPostWhileSaving = _canPost(tester);
    final showsSaving = find.text('게시 중…').evaluate().isNotEmpty;
    repository.blockAddUntil!.complete();
    await tester.pumpAndSettle();

    // then
    expect(repository.addedBodies, hasLength(1));
    expect(canPostWhileSaving, isFalse);
    expect(showsSaving, isTrue);
  });

  testWidgets('게시 중에는 X를 눌러도 닫히지 않는다', (tester) async {
    // given: 저장이 끝나지 않고 멈춰 있는 상태
    final repository = await pumpWriteScreen(tester);
    repository.blockAddUntil = Completer<void>();
    await tester.enterText(find.byKey(const ValueKey('post-body')), '안녕');
    await tester.pump();
    await tester.tap(_postButton);
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    final stillOpen = find.byType(WriteScreen).evaluate().isNotEmpty;
    repository.blockAddUntil!.complete();
    await tester.pumpAndSettle();

    // then
    expect(stillOpen, isTrue);
  });

  testWidgets('공백만 있는 본문은 X를 누르면 확인 없이 닫힌다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('post-body')), '  \n ');
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(WriteScreen), findsNothing);
  });

  testWidgets('본문이 있으면 X를 눌렀을 때 계속 쓰기를 고르면 입력이 남는다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('post-body')), '쓰던 글');
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('계속 쓰기'));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(WriteScreen), findsOneWidget);
    expect(find.text('쓰던 글'), findsOneWidget);
  });

  testWidgets('본문이 있으면 X를 눌렀을 때 버리기를 고르면 닫힌다', (tester) async {
    // given
    final repository = await pumpWriteScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('post-body')), '쓰던 글');
    await tester.pump();

    // when
    await tester.tap(find.byType(CloseButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('버리기'));
    await tester.pumpAndSettle();

    // then
    expect(find.byType(WriteScreen), findsNothing);
    expect(repository.addedBodies, isEmpty);
  });

  testWidgets('본문이 있으면 Android 뒤로가기도 확인 창을 띄운다', (tester) async {
    // given
    await pumpWriteScreen(tester);
    await tester.enterText(find.byKey(const ValueKey('post-body')), '쓰던 글');
    await tester.pump();

    // when: 시스템 뒤로가기 신호를 보낸다.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    // then
    expect(find.text('작성 중인 글을 버릴까요?'), findsOneWidget);
    expect(find.byType(WriteScreen), findsOneWidget);
  });
}

// FilledButton.icon은 FilledButton의 하위 클래스라 byType으로는 찾지 못한다.
final _postButton = find.byWidgetPredicate((widget) => widget is FilledButton);

bool _canPost(WidgetTester tester) {
  final button = tester.widget<FilledButton>(_postButton);

  return button.onPressed != null;
}

Color? _counterColor(WidgetTester tester, String counter) {
  final counterText = tester.widget<Text>(find.text(counter));

  return counterText.style?.color;
}

Color _errorColor(WidgetTester tester) {
  final context = tester.element(find.byType(WriteScreen));

  return Theme.of(context).colorScheme.error;
}
