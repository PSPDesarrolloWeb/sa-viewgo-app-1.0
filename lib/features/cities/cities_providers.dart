import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/features/cities/cities_repository.dart';
import 'package:saviewgo/features/cities/city_model.dart';

/// Ciudades activas, leídas una sola vez por sesión y guardadas en memoria
/// (sin autoDispose). Se vuelven a leer solo al cambiar de usuario o con
/// `ref.invalidate(citiesProvider)`.
final citiesProvider = FutureProvider<List<CityModel>>((ref) async {
  final uid = ref.watch(firebaseUserProvider.select((u) => u.value?.uid));
  if (uid == null) return const [];
  return const CitiesRepository().fetchActive();
});

/// Ciudad elegida por el superadmin_global en el selector.
/// null = todas las ciudades. Se reinicia al cambiar de usuario.
final selectedCityIdProvider =
    NotifierProvider<SelectedCityId, String?>(SelectedCityId.new);

class SelectedCityId extends Notifier<String?> {
  @override
  String? build() {
    ref.watch(firebaseUserProvider.select((u) => u.value?.uid));
    return null;
  }

  void select(String? cityId) => state = cityId;
}

/// Ciudad con la que se filtran las pantallas.
/// - superadmin_city: siempre la de su claim.
/// - superadmin_global: la elegida en el selector (null = todas).
final scopeCityIdProvider = FutureProvider<String?>((ref) async {
  final selected = ref.watch(selectedCityIdProvider);
  final claims = await ref.watch(adminClaimsProvider.future);
  return claims.isGlobal ? selected : claims.cityId;
});