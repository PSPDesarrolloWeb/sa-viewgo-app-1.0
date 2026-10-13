import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/features/auth/welcome_screen.dart';
import 'package:saviewgo/features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const home = '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefresh(FirebaseAuth.instance.authStateChanges());
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authRefresh,
    redirect: (context, state) {
      final location = state.matchedLocation;

      // El splash decide a dónde ir. /login también admite una sesión
      // abierta: ahí funciona como pantalla de bloqueo.
      if (location == AppRoutes.splash || location == AppRoutes.login) {
        return null;
      }

      final signedIn = FirebaseAuth.instance.currentUser != null;
      return signedIn ? null : AppRoutes.login;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const _PendingScreen('Inicio'),
      ),
    ],
  );
});

/// Vuelve a evaluar el redirect cada vez que cambia la sesión.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<User?> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

/// Temporal hasta crear HomeScreen.
class _PendingScreen extends StatelessWidget {
  const _PendingScreen(this.title);

  final String title;

  @override
  Widget build(BuildContext context) =>
      Scaffold(body: Center(child: Text(title)));
}