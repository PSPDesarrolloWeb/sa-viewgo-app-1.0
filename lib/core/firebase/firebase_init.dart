import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:saviewgo/firebase_options.dart';

/// Se vuelve a aplicar después de limpiar la caché al cerrar sesión.
const firestoreSettings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: 100 * 1024 * 1024,
);

/// Solo lo que no necesita red y debe existir antes de runApp.
/// Sesión, claims y ciudades se cargan en el splash.
Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  FirebaseFirestore.instance.settings = firestoreSettings;
}