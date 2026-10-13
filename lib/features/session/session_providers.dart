import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/session/session_context.dart';
import 'package:saviewgo/features/session/session_repository.dart';

/// Local y estable durante la sesión: no se descarta.
final deviceSummaryProvider = FutureProvider<DeviceSummary>(
  (ref) => ref.read(sessionRepositoryProvider).readDevice(),
);

/// Sin reintentos automáticos: si la Function falla, la tarjeta
/// muestra "No disponible" en vez de quedarse cargando.
final networkContextProvider = FutureProvider.autoDispose<NetworkContext>(
  (ref) => ref.read(sessionRepositoryProvider).fetchNetworkContext(),
  retry: (_, __) => null,
);

final lastAccessProvider = FutureProvider.autoDispose<LastAccess?>(
  (ref) => ref.read(sessionRepositoryProvider).readLastAccess(),
);