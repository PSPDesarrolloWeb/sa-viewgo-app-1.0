import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

Future<void> initFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Crashlytics: solo reporta en builds release, para no mezclar errores
  // de desarrollo con los reales.
  final crashlytics = FirebaseCrashlytics.instance;
  await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
  FlutterError.onError = crashlytics.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };

  // La caché persistente ya viene activa en móvil; se deja explícita porque
  // al cerrar sesión se limpia con terminate() + clearPersistence()
  // (README, sección 5.2).
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}