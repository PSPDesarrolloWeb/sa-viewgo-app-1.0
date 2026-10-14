import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/session/session_context.dart';
import 'package:saviewgo/features/session/session_repository.dart';

/// Local y estable durante la sesión: no se descarta.
final deviceSummaryProvider = FutureProvider<DeviceSummary>(
  (ref) => ref.read(sessionRepositoryProvider).readDevice(),
);

/// Lectura local: la sesión se registró al iniciar con contraseña.
final registeredSessionProvider =
    FutureProvider.autoDispose<RegisteredSession?>(
  (ref) => ref.read(sessionRepositoryProvider).readRegisteredSession(),
);

final lastAccessProvider = FutureProvider.autoDispose<LastAccess?>(
  (ref) => ref.read(sessionRepositoryProvider).readLastAccess(),
);