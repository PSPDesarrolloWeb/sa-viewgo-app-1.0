import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/theme/theme.dart';
import 'package:saviewgo/core/theme/theme_mode_provider.dart';

class SAViewGoApp extends ConsumerWidget {
  const SAViewGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'SAViewGo',
      debugShowCheckedModeBanner: false,
      theme: TAppTheme.lightTheme,
      darkTheme: TAppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      // La primera pantalla la define el router: initialLocation = /splash.
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('es', 'EC'),
      supportedLocales: const [Locale('es', 'EC'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}