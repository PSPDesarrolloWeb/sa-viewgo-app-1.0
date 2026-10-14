import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alertas sin leer para el badge del bottom nav.
///
/// Temporal: devuelve 0 hasta crear admin_alerts. Se reemplazará por un
/// conteo P6 (count() de alertas con createdAt > lastSeenAt del usuario),
/// nunca leyendo la colección completa.
final unreadAlertsCountProvider = Provider<int>((ref) => 0);