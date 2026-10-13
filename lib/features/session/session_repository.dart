import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saviewgo/core/security/secure_storage.dart';
import 'package:saviewgo/features/session/session_context.dart';

final sessionRepositoryProvider = Provider<SessionRepository>(
  (ref) => SessionRepository(ref.read(secureStorageProvider)),
);

class SessionRepository {
  SessionRepository(this._storage);

  final FlutterSecureStorage _storage;

  FirebaseFunctions get _functions => FirebaseFunctions.instance;

  Future<DeviceSummary> readDevice() async {
    final package = await PackageInfo.fromPlatform();
    final plugin = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final android = await plugin.androidInfo;
      return DeviceSummary(
        label: '${_deviceName(android.manufacturer, android.model)}'
            ' · Android ${android.version.release}',
        platform: 'android',
        appVersion: package.version,
      );
    }
    if (Platform.isIOS) {
      final ios = await plugin.iosInfo;
      return DeviceSummary(
        label: '${ios.model} · iOS ${ios.systemVersion}',
        platform: 'ios',
        appVersion: package.version,
      );
    }
    return DeviceSummary(
      label: Platform.operatingSystem,
      platform: Platform.operatingSystem,
      appVersion: package.version,
    );
  }

  /// Sin autenticación: se muestra antes de iniciar sesión.
  Future<NetworkContext> fetchNetworkContext() async {
    final result =
        await _functions.httpsCallable('getSessionContext').call<Object?>();
    return NetworkContext.fromMap(result.data);
  }

  /// Registra el ingreso en admin_sessions (auditoría).
  Future<NetworkContext> registerSession(DeviceSummary device) async {
    final result = await _functions
        .httpsCallable('registerSession')
        .call<Object?>(device.toMap());
    return NetworkContext.fromMap(result.data);
  }

  Future<LastAccess?> readLastAccess() async {
    final raw = await _storage.read(key: StorageKeys.lastAccess);
    if (raw == null) return null;
    try {
      return LastAccess.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveLastAccess(LastAccess access) => _storage.write(
        key: StorageKeys.lastAccess,
        value: jsonEncode(access.toJson()),
      );

  static String _deviceName(String manufacturer, String model) {
    if (manufacturer.isEmpty ||
        model.toLowerCase().startsWith(manufacturer.toLowerCase())) {
      return model;
    }
    final brand = manufacturer[0].toUpperCase() + manufacturer.substring(1);
    return '$brand $model';
  }
}