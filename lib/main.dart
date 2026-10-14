import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/app/app.dart';
import 'package:saviewgo/core/firebase/firebase_init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initFirebase();

  // Sin reintentos automáticos: cada pantalla maneja sus errores y
  // ofrece reintentar. Con reintentos, un error de permisos dejaba
  // los providers cargando para siempre.
  runApp(
    ProviderScope(
      retry: (_, __) => null,
      child: const SAViewGoApp(),
    ),
  );
}