import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricServiceProvider = Provider<BiometricService>(
  (ref) => BiometricService(LocalAuthentication()),
);

/// Envoltorio de local_auth. Acepta huella, rostro o el PIN del
/// dispositivo como respaldo.
class BiometricService {
  BiometricService(this._auth);

  final LocalAuthentication _auth;

  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() && await _auth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return false;
    }
  }
}