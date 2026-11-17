import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/features/alerts/alerts_screen.dart';
import 'package:saviewgo/features/auth/welcome_screen.dart';
import 'package:saviewgo/features/businesses/business_detail_screen.dart';
import 'package:saviewgo/features/businesses/business_model.dart';
import 'package:saviewgo/features/businesses/businesses_screen.dart';
import 'package:saviewgo/features/couriers/couriers_screen.dart';
import 'package:saviewgo/features/dashboard/dashboard_screen.dart';
import 'package:saviewgo/features/orders/orders_screen.dart';
import 'package:saviewgo/features/profile/profile_screen.dart';
import 'package:saviewgo/features/shell/main_shell.dart';
import 'package:saviewgo/features/splash/splash_screen.dart';
import 'package:saviewgo/features/transfers/transfers_screen.dart';

abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';

  // Pestañas del shell. El orden de las ramas en el router debe
  // coincidir con el orden de MainTab.
  static const home = '/home';
  static const businesses = '/businesses';
  static const transfers = '/transfers';
  static const alerts = '/alerts';
  static const profile = '/profile';

  /// Consultas de solo lectura, a pantalla completa (se abren desde el Resumen).
  static const orders = '/orders';
  static const couriers = '/couriers';
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
      GoRoute(
        path: AppRoutes.orders,
        builder: (_, __) => const OrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.couriers,
        builder: (_, __) => const CouriersScreen(),
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
              routes: [
                // Cubre el bottom nav. Con `extra` reutiliza el negocio ya
                // leído en la lista (0 lecturas); sin él, lo lee una vez.
                GoRoute(
                  path: ':id',
                  parentNavigatorKey: rootNavigatorKey,
                  builder: (_, state) => BusinessDetailScreen(
                    businessId: state.pathParameters['id']!,
                    initial: state.extra is BusinessModel
                        ? state.extra as BusinessModel
                        : null,
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: AppRoutes.transfers,
              builder: (_, __) => const TransfersScreen(),
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