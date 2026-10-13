/// Datos del dispositivo, que se leen localmente.
class DeviceSummary {
  const DeviceSummary({
    required this.label,
    required this.platform,
    required this.appVersion,
  });

  /// Ej. "Pixel 8 · Android 16".
  final String label;
  final String platform;
  final String appVersion;

  Map<String, Object> toMap() => {
        'deviceLabel': label,
        'platform': platform,
        'appVersion': appVersion,
      };
}

/// IP y ubicación aproximada, resueltas en el servidor.
class NetworkContext {
  const NetworkContext({this.ip, this.city, this.region, this.country});

  factory NetworkContext.fromMap(Object? data) {
    final map = data is Map ? data : const {};
    String? read(String key) {
      final value = map[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return NetworkContext(
      ip: read('ip'),
      city: read('city'),
      region: read('region'),
      country: read('country'),
    );
  }

  final String? ip;
  final String? city;
  final String? region;
  final String? country;

  /// Ej. "Ibarra, Imbabura".
  String? get locationLabel {
    final parts = [city, region].whereType<String>();
    return parts.isEmpty ? null : parts.join(', ');
  }
}

/// Último ingreso exitoso desde este dispositivo.
class LastAccess {
  const LastAccess({required this.at, this.city});

  factory LastAccess.fromJson(Map<String, dynamic> json) => LastAccess(
        at: DateTime.parse(json['at'] as String),
        city: json['city'] as String?,
      );

  final DateTime at;
  final String? city;

  Map<String, dynamic> toJson() => {'at': at.toIso8601String(), 'city': city};
}