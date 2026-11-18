import 'dart:async';

import 'package:flutter/material.dart';

import '../models/author.dart';
import '../service/auth/auth_service.dart';
import '../theme/app_theme.dart';
import 'start_screen.dart';

/// 인증·프로필·저장소가 준비되기 전에는 피드로 진입하지 않는다.
class SessionGate extends StatefulWidget {
  const SessionGate({
    super.key,
    required this.authService,
    required this.buildSession,
    this.waitLimit = const Duration(seconds: 30),
    this.profileDisplayDuration = const Duration(milliseconds: 600),
  });

  final AuthService authService;
  final Future<Widget> Function(Author) buildSession;
  final Duration waitLimit;
  final Duration profileDisplayDuration;

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  Author? _author;
  SessionFailure? _failure;
  Widget? _session;
  Timer? _timer;
  bool _busy = false;
  int _attempt = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  bool _active(int attempt) => mounted && attempt == _attempt;

  Future<void> _start() async {
    if (_busy) return;
    final attempt = ++_attempt;
    setState(() {
      _busy = true;
      _failure = null;
    });
    _timer?.cancel();
    _timer = Timer(widget.waitLimit, () {
      if (!_active(attempt)) return;
      ++_attempt; // 늦은 응답은 화면에 적용하지 않는다.
      setState(() {
        _busy = false;
        _failure = SessionFailure.unknown;
      });
    });
    try {
      final profile = await widget.authService.signIn(
        onAuthorReady: (author) {
          if (_active(attempt)) setState(() => _author = author);
        },
      );
      if (!_active(attempt)) return;
      setState(() => _author = profile.author);
      final session = await widget.buildSession(profile.author);
      if (!_active(attempt)) return;
      _timer?.cancel();
      await Future<void>.delayed(widget.profileDisplayDuration);
      if (!_active(attempt)) return;
      setState(() {
        _session = session;
        _busy = false;
      });
    } catch (error) {
      if (!_active(attempt)) return;
      _timer?.cancel();
      setState(() {
        _busy = false;
        _failure = error is SessionException
            ? error.failure
            : SessionFailure.unknown;
      });
    }
  }

  @override
  void dispose() {
    ++_attempt;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _session ??
      MaterialApp(
        title: '미니피드',
        theme: appTheme,
        home: StartScreen(
          author: _author,
          failure: _failure,
          onRetry: _busy ? null : _start,
        ),
      );
}
