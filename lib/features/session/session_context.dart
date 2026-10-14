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

/// IP y ubicación aproximada que devuelve registerSession.
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
}

/// IP y ubicación con las que se registró la sesión al iniciar con
/// contraseña. Se guarda en el dispositivo y se muestra en el inicio
/// sin volver a consultar al servidor.
class RegisteredSession {
  const RegisteredSession({
    required this.at,
    this.ip,
    this.city,
    this.region,
  });

  factory RegisteredSession.fromNetwork(NetworkContext network, DateTime at) =>
      RegisteredSession(
        at: at,
        ip: network.ip,
        city: network.city,
        region: network.region,
      );

  factory RegisteredSession.fromJson(Map<String, dynamic> json) =>
      RegisteredSession(
        at: DateTime.parse(json['at'] as String),
        ip: json['ip'] as String?,
        city: json['city'] as String?,
        region: json['region'] as String?,
      );

  final DateTime at;
  final String? ip;
  final String? city;
  final String? region;

  String? get locationLabel {
    final parts = [city, region].whereType<String>();
    return parts.isEmpty ? null : parts.join(', ');
  }

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'ip': ip,
        'city': city,
        'region': region,
      };
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