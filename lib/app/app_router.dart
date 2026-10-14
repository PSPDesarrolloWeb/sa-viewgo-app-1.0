import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/features/alerts/alerts_screen.dart';
import 'package:saviewgo/features/auth/welcome_screen.dart';
import 'package:saviewgo/features/businesses/businesses_screen.dart';
import 'package:saviewgo/features/cities/cities_screen.dart';
import 'package:saviewgo/features/dashboard/dashboard_screen.dart';
import 'package:saviewgo/features/profile/profile_screen.dart';
import 'package:saviewgo/features/shell/main_shell.dart';
import 'package:saviewgo/features/splash/splash_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';

  // Pestañas del shell. El orden de las ramas en el router debe
  // coincidir con el orden de MainTab.
  static const home = '/home';
  static const businesses = '/businesses';
  static const alerts = '/alerts';
  static const cities = '/cities';
  static const profile = '/profile';
}

/// Navigator raíz. Las pantallas que deben cubrir el bottom nav (detalle
/// de negocio, formularios a pantalla completa) se declaran dentro de su
/// rama con `parentNavigatorKey: rootNavigatorKey`.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authRefresh = _AuthRefresh(FirebaseAuth.instance.authStateChanges());
  ref.onDispose(authRefresh.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // La app siempre abre en el inicio. Sin sesión muestra el acceso;
    // con sesión abierta funciona como bloqueo (huella o PIN del
    // dispositivo). El splash solo corre después de entrar o desbloquear.
    initialLocation: AppRoutes.login,
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
      // Cada rama mantiene su propia pila y su estado (scroll, filtros)
      // al cambiar de pestaña.
      StatefulShellRoute.indexedStack(
        builder: (_, __, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (_, __) => const DashboardScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.businesses,
              builder: (_, __) => const BusinessesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.alerts,
              builder: (_, __) => const AlertsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.cities,
              builder: (_, __) => const CitiesScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (_, __) => const ProfileScreen(),
            ),
          ]),
        ],
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