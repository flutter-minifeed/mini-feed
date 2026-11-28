// This browser-only helper registers the FlutterFire versions in the app lockfile.
// ignore_for_file: depend_on_referenced_packages

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore_web/cloud_firestore_web.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:minifeed/models/author.dart';
import 'package:minifeed/service/auth/firebase_auth_service.dart';

const _demoProject = 'demo-minifeed-repositories';
const _host = '127.0.0.1';

void registerFirestoreEmulatorPlugins() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebaseCoreWeb.registerWith(webPluginRegistrar);
  FirebaseAuthWeb.registerWith(webPluginRegistrar);
  FirebaseFirestoreWeb.registerWith(webPluginRegistrar);
}

/// [persistent]가 true면 연결을 끊어도 읽은 문서가 남도록 캐시 유지를 켠다(#15).
/// 설정은 첫 사용 전에만 바꿀 수 있어서 에뮬레이터 연결보다 먼저 지정한다.
Future<({FirebaseAuth auth, FirebaseFirestore firestore})>
openFirestoreEmulatorClient(String name, {bool persistent = false}) async {
  final app = await Firebase.initializeApp(
    name: name,
    options: const FirebaseOptions(
      apiKey: 'emulator-only-key',
      appId: '1:123456789012:web:1234567890123456',
      messagingSenderId: '123456789012',
      projectId: _demoProject,
      authDomain: '$_demoProject.firebaseapp.com',
    ),
  );
  final auth = FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator(_host, 9099);
  final firestore = FirebaseFirestore.instanceFor(app: app);
  if (persistent) firestore.settings = const Settings(persistenceEnabled: true);
  firestore.useFirestoreEmulator(_host, 8080);
  return (auth: auth, firestore: firestore);
}

Future<Author> signInToFirestoreEmulator(
  FirebaseAuth auth,
  FirebaseFirestore firestore,
) async {
  final profile = await FirebaseAuthService(
    auth: auth,
    firestore: firestore,
    initialize: () async {},
  ).signIn();
  return profile.author;
}
