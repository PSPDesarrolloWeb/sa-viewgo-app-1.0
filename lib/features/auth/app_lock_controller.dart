import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/security/biometric_service.dart';

final biometricAvailableProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.read(biometricServiceProvider).isAvailable(),
);
 
/// Candado local del dispositivo sobre una sesión de Firebase que sigue
/// abierta. No llama a Functions ni a Firestore: solo huella, rostro o
/// PIN del dispositivo. El estado indica si la app está desbloqueada.
final appLockProvider =
    NotifierProvider<AppLockController, bool>(AppLockController.new);
 
class AppLockController extends Notifier<bool> {
  /// true solo tras un inicio de sesión con contraseña: es el único
  /// momento en que se registra la sesión en el servidor.
  bool _needsRegistration = false;
 
  @override
  bool build() => false;
 
  Future<bool> unlock() async {
    final ok = await ref
        .read(biometricServiceProvider)
        .authenticate('Desbloquea SAViewGo');
    if (ok) state = true;
    return ok;
  }
 
  void markLoggedIn() {
    _needsRegistration = true;
    state = true;
  }
 
  /// Devuelve si hay que registrar la sesión y limpia la marca.
  bool consumeRegistration() {
    final pending = _needsRegistration;
    _needsRegistration = false;
    return pending;
  }
 
  void lock() {
    _needsRegistration = false;
    state = false;
  }
}
 