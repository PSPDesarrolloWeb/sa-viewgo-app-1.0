import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/auth/app_lock_controller.dart';
import 'package:saviewgo/features/auth/auth_repository.dart';
import 'package:saviewgo/features/cities/cities_provider.dart';
import 'package:saviewgo/features/session/session_context.dart';
import 'package:saviewgo/features/session/session_providers.dart';
import 'package:saviewgo/features/session/session_repository.dart';
import 'package:saviewgo/features/splash/startup_state.dart';

final startupControllerProvider =
    NotifierProvider.autoDispose<StartupController, StartupState>(
  StartupController.new,
);

class StartupController extends Notifier<StartupState> {
  /// Tiempo mínimo por paso para que la lista se alcance a leer
  /// cuando todo responde desde caché.
  static const _minStepDuration = Duration(milliseconds: 350);

  /// Tiempo mínimo que se ve el splash antes de navegar.
  static const _minSplashDuration = Duration(milliseconds: 1500);

  static const _allowedRoles = {'superadmin_global', 'superadmin_city'};

  @override
  StartupState build() {
    Future.microtask(run);
    return StartupState.initial();
  }

  Future<void> run() async {
    state = StartupState.initial();
    final stopwatch = Stopwatch()..start();

    try {
      final user = await _step(
        StartupStep.session,
        () => FirebaseAuth.instance.authStateChanges().first,
      );
      if (user == null) {
        _skipFrom(StartupStep.permissions);
        await _waitRemaining(stopwatch);
        state = state.finish(StartupOutcome.signedOut);
        return;
      }

      final hasAccess = await _step(
        StartupStep.permissions,
        () => _hasValidRole(user),
      );
      if (!hasAccess) {
        await ref.read(authRepositoryProvider).signOut();
        state = state
            .withStep(StartupStep.permissions, StepStatus.failed)
            .finish(
              StartupOutcome.noAccess,
              message: 'Esta cuenta no tiene acceso a SAViewGo.',
            );
        return;
      }

      // Sesión abierta con huella activada: se pide desbloquear antes
      // de cargar datos o registrar el acceso.
      final unlocked = ref.read(appLockProvider);
      if (!unlocked &&
          await ref.read(appLockProvider.notifier).isEnabledFor(user.uid)) {
        _skipFrom(StartupStep.cities);
        await _waitRemaining(stopwatch);
        state = state.finish(StartupOutcome.locked);
        return;
      }

      // P1: abre el listener compartido de ciudades, que queda vivo
      // toda la sesión.
      await _step(StartupStep.cities, () => ref.read(citiesProvider.future));

      await _step(StartupStep.register, _registerSession);

      await _waitRemaining(stopwatch);
      state = state.finish(StartupOutcome.ready);
    } catch (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack);
      state = state.finish(
        StartupOutcome.failed,
        message:
            'No se pudo cargar SAViewGo. Revisa tu conexión e intenta de nuevo.',
      );
    }
  }

  /// Deja constancia del ingreso en admin_sessions y guarda el último
  /// acceso en el dispositivo para mostrarlo en la pantalla de inicio.
  Future<void> _registerSession() async {
    final repository = ref.read(sessionRepositoryProvider);
    final device = await ref.read(deviceSummaryProvider.future);
    final network = await repository.registerSession(device);
    await repository.saveLastAccess(
      LastAccess(at: DateTime.now(), city: network.city),
    );
    ref.invalidate(lastAccessProvider);
  }

  Future<bool> _hasValidRole(User user) async {
    final token = await user.getIdTokenResult(true);
    final role = token.claims?['role'];
    final city = token.claims?['city'];

    if (!_allowedRoles.contains(role)) return false;
    if (role == 'superadmin_city' && (city is! String || city.isEmpty)) {
      return false;
    }
    return true;
  }

  /// Marca como omitidos el paso indicado y los siguientes.
  void _skipFrom(StartupStep first) {
    for (final step in StartupStep.values.skip(first.index)) {
      state = state.withStep(step, StepStatus.skipped);
    }
  }

  Future<void> _waitRemaining(Stopwatch stopwatch) async {
    final remaining = _minSplashDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) await Future<void>.delayed(remaining);
  }

  Future<T> _step<T>(StartupStep step, Future<T> Function() task) async {
    state = state.withStep(step, StepStatus.running);
    try {
      final results = await Future.wait<Object?>([
        task(),
        Future<void>.delayed(_minStepDuration),
      ]);
      state = state.withStep(step, StepStatus.done);
      return results.first as T;
    } catch (_) {
      state = state.withStep(step, StepStatus.failed);
      rethrow;
    }
  }
}