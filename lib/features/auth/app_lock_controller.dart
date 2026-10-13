import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/security/biometric_service.dart';
import 'package:saviewgo/core/security/secure_storage.dart';

final biometricAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(biometricServiceProvider).isAvailable(),
);

/// Bloqueo con huella sobre una sesión de Firebase que sigue abierta.
/// El estado indica si la app ya se desbloqueó en esta ejecución.
final appLockProvider =
    NotifierProvider<AppLockController, bool>(AppLockController.new);

class AppLockController extends Notifier<bool> {
  @override
  bool build() => false;

  /// La preferencia se guarda con el uid, para que no se aplique a
  /// otra cuenta que inicie sesión en el mismo dispositivo.
  Future<bool> isEnabledFor(String uid) async =>
      await ref.read(secureStorageProvider).read(key: StorageKeys.biometricUid) ==
      uid;

  Future<bool> enableFor(String uid) async {
    final confirmed = await ref
        .read(biometricServiceProvider)
        .authenticate('Confirma para activar el ingreso con huella');
    if (confirmed) {
      await ref
          .read(secureStorageProvider)
          .write(key: StorageKeys.biometricUid, value: uid);
    }
    return confirmed;
  }

  Future<void> disable() =>
      ref.read(secureStorageProvider).delete(key: StorageKeys.biometricUid);

  Future<bool> unlock() async {
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate('Desbloquea SAViewGo');
    if (ok) state = true;
    return ok;
  }

  void markUnlocked() => state = true;

  void lock() => state = false;
}