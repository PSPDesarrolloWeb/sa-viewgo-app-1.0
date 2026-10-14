import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/dashboard/dashboard_repository.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';

/// Cambia a la implementación con Firestore cuando esté lista.
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => const MockDashboardRepository(),
);

/// Resumen del Inicio para la ciudad en alcance. Se vuelve a pedir al
/// cambiar de ciudad en el selector y se descarta al salir de la pantalla.
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final cityId = await ref.watch(scopeCityIdProvider.future);
  return ref.watch(dashboardRepositoryProvider).fetchSummary(cityId: cityId);
});