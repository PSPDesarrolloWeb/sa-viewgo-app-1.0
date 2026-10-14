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

  // En desarrollo los errores se muestran en consola como siempre. Si
  // se reportaran como fatales, un error durante un hot restart podía
  // cerrar la app por completo.
  await FirebaseCrashlytics.instance
      .setCrashlyticsCollectionEnabled(!kDebugMode);
  if (!kDebugMode) {
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  applyFirestoreSettings();
}

/// En un hot restart el código Dart vuelve a empezar, pero Firestore
/// sigue iniciado en el lado nativo y ya no acepta ajustes nuevos. Los
/// que tenía siguen vigentes, así que el error se ignora.
void applyFirestoreSettings() {
  try {
    FirebaseFirestore.instance.settings = firestoreSettings;
  } catch (error) {
    debugPrint('[Firestore] Ajustes no aplicados: $error');
  }
}