import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/features/auth/app_lock_controller.dart';

/// Vuelve a bloquear la app si estuvo en segundo plano más de [relockAfter].
///
/// Es un candado local: no usa Firebase ni red. Al bloquear, la persona
/// vuelve a la pantalla de acceso, desbloquea con huella o PIN del
/// dispositivo y el arranque revalida su rol con un token nuevo.
///
/// El tiempo da margen para ir a la app del banco a comparar un comprobante
/// y volver sin tener que desbloquear otra vez.
class AppLockWatcher extends ConsumerStatefulWidget {
  const AppLockWatcher({super.key, required this.child});

  final Widget child;

  static const relockAfter = Duration(minutes: 2);

  @override
  ConsumerState<AppLockWatcher> createState() => _AppLockWatcherState();
}

class _AppLockWatcherState extends ConsumerState<AppLockWatcher>
    with WidgetsBindingObserver {
  DateTime? _leftAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // Solo el primer aviso: `inactive` y `hidden` pueden repetirse.
        _leftAt ??= DateTime.now();
      case AppLifecycleState.resumed:
        final leftAt = _leftAt;
        _leftAt = null;
        if (leftAt == null) return;
        if (DateTime.now().difference(leftAt) >= AppLockWatcher.relockAfter) {
          _relock();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _relock() {
    // Sin sesión o ya bloqueada: no hay nada que bloquear.
    if (FirebaseAuth.instance.currentUser == null) return;
    if (!ref.read(appLockProvider)) return;

    ref.read(appLockProvider.notifier).lock();
    ref.read(appRouterProvider).go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
