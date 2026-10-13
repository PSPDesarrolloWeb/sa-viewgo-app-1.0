import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Claves guardadas en el dispositivo. Ninguna es una credencial:
/// solo preferencias y datos de la última sesión.
abstract final class StorageKeys {
  static const themeMode = 'theme_mode';
  static const biometricUid = 'biometric_uid';
  static const lastAccess = 'last_access';
}

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);