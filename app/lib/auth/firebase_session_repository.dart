import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_config.dart';
import '../models/author.dart';
import '../models/user_profile.dart';
import 'anonymous_identity.dart';
import 'session_repository.dart';

class FirebaseSessionRepository implements SessionRepository {
  FirebaseSessionRepository({
    this.auth,
    this.firestore,
    Future<void> Function()? initialize,
  }) : _initialize = initialize ?? _initializeFirebase;

  final FirebaseAuth? auth;
  final FirebaseFirestore? firestore;
  final Future<void> Function() _initialize;
  Future<UserProfile>? _pending;

  static Future<void> _initializeFirebase() async {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: firebaseOptionsFromEnvironment());
    }
  }

  @override
  Future<UserProfile> signIn({void Function(Author)? onAuthorReady}) {
    // 화면에서 대기를 끝내도 진행 중인 인증을 중복 실행하지 않는다.
    return _pending ??= _signIn(onAuthorReady)
        .whenComplete(() => _pending = null);
  }

  Future<UserProfile> _signIn(void Function(Author)? onAuthorReady) async {
    try {
      await _initialize();
      final firebaseAuth = auth ?? FirebaseAuth.instance;
      final db = firestore ?? FirebaseFirestore.instance;
      final user =
          firebaseAuth.currentUser ??
          (await firebaseAuth.signInAnonymously()).user;
      if (user == null || !user.isAnonymous) {
        throw const SessionException(SessionFailure.configuration);
      }
      final candidate = anonymousAuthor(user.uid);
      final ref = db.collection('users').doc(user.uid);

      // 재실행·오프라인에서도 서버에 확정된 기존 프로필을 사용한다.
      try {
        final cached = await ref.get(const GetOptions(source: Source.cache));
        if (cached.exists && !cached.metadata.hasPendingWrites) {
          final profile = _profile(user.uid, cached.data());
          onAuthorReady?.call(profile.author);
          return profile;
        }
      } on FirebaseException catch (error) {
        if (![
          'unavailable',
          'not-found',
          'failed-precondition',
        ].contains(error.code)) {
          rethrow;
        }
      }

      // 같은 UID로 재시도해도 생성 시각과 표시 정보를 덮어쓰지 않는다.
      await db.runTransaction<void>((transaction) async {
        final snapshot = await transaction.get(ref);
        if (snapshot.exists) {
          final profile = _profile(user.uid, snapshot.data());
          onAuthorReady?.call(profile.author);
          return;
        }
        onAuthorReady?.call(candidate);
        transaction.set(ref, {
          'nickName': candidate.nickName,
          'colorIndex': candidate.colorIndex,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }, timeout: const Duration(seconds: 15));
      final saved = await ref.get(const GetOptions(source: Source.server));
      return _profile(user.uid, saved.data());
    } on SessionException {
      rethrow;
    } on FirebaseException catch (error) {
      throw SessionException(switch (error.code) {
        'network-request-failed' ||
        'unavailable' ||
        'deadline-exceeded' => SessionFailure.offline,
        'permission-denied' ||
        'unauthenticated' => SessionFailure.permissionDenied,
        'operation-not-allowed' ||
        'invalid-api-key' ||
        'app-not-authorized' => SessionFailure.configuration,
        _ => SessionFailure.unknown,
      });
    } on StateError {
      throw const SessionException(SessionFailure.configuration);
    } on UnsupportedError {
      throw const SessionException(SessionFailure.configuration);
    }
  }

  UserProfile _profile(String uid, Map<String, dynamic>? data) {
    final name = data?['nickName'];
    final color = data?['colorIndex'];
    final time = data?['createdAt'];
    if (name is! String ||
        name.trim().isEmpty ||
        color is! int ||
        color < 0 ||
        color > 7 ||
        time is! Timestamp) {
      throw const SessionException(SessionFailure.invalidProfile);
    }
    return UserProfile(
      author: Author(id: uid, nickName: name, colorIndex: color),
      createdAt: time.toDate(),
    );
  }
}
