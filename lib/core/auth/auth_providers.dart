import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Usuario de Firebase Auth. Los providers de sesión lo observan para
/// cerrar sus listeners y limpiar su estado al cerrar sesión.
final firebaseUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.authStateChanges(),
);

/// Claims de superadmin: `{ role, city? }`.
class AdminClaims {
  const AdminClaims({this.role, this.cityId});

  final String? role;

  /// Id de `city/{cityId}`. Solo existe para superadmin_city.
  final String? cityId;

  bool get isGlobal => role == 'superadmin_global';
  bool get isCity => role == 'superadmin_city';
}

/// Claims del usuario actual. Se recalcula al cambiar de usuario.
///
/// Si al volver a primer plano validas el rol con
/// `getIdTokenResult(true)`, llama `ref.invalidate(adminClaimsProvider)`
/// después para que la app use los claims nuevos.
final adminClaimsProvider = FutureProvider<AdminClaims>((ref) async {
  final user = ref.watch(firebaseUserProvider).value;
  if (user == null) return const AdminClaims();

  final token = await user.getIdTokenResult();
  return AdminClaims(
    role: token.claims?['role'] as String?,
    cityId: token.claims?['city'] as String?,
  );
});