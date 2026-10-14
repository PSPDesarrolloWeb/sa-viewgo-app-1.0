import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';

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
///
/// - superadmin_city: siempre la de su claim; no puede cambiarla.
/// - superadmin_global: la que eligió en el selector (null = todas).
final scopeCityIdProvider = FutureProvider<String?>((ref) async {
  final selected = ref.watch(selectedCityIdProvider);
  final claims = await ref.watch(adminClaimsProvider.future);
  return claims.isGlobal ? selected : claims.cityId;
});