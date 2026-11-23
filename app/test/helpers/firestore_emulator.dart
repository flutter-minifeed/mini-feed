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

Future<({FirebaseAuth auth, FirebaseFirestore firestore})>
openFirestoreEmulatorClient(String name) async {
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
