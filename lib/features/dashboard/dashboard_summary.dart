import 'package:saviewgo/features/alerts/alert_type.dart';
import 'package:saviewgo/shared/models/business_module.dart';

/// Todo lo que muestra el Resumen en una sola lectura.
class DashboardSummary {
  const DashboardSummary({
    required this.cityId,
    required this.pending,
    required this.metrics,
    required this.modules,
    required this.activity,
  });

  /// Ciudad consultada. null = todas las ciudades.
  final String? cityId;
  final List<PendingItem> pending;
  final DashboardMetrics metrics;
  final List<ModuleStat> modules;
  final List<ActivityItem> activity;

  bool get isAllCities => cityId == null;
  int get pendingTotal => pending.fold(0, (sum, p) => sum + p.count);
  int get activeModulesTotal => modules.fold(0, (sum, m) => sum + m.count);
}

enum PendingType {
  paymentsToVerify('Pagos por verificar'),
  overdueSubscriptions('Suscripciones atrasadas'),
  missingMainBranch('Negocios sin sucursal'),
  trialsExpiring('Trials por vencer');

  const PendingType(this.label);
  final String label;
}

class PendingItem {
  const PendingItem({required this.type, required this.count});

  final PendingType type;
  final int count;
}

class DashboardMetrics {
  const DashboardMetrics({
    required this.activeBusinesses,
    required this.ordersToday,
    required this.activeCities,
    required this.activeOperators,
  });

  final int activeBusinesses;
  final int ordersToday;

  /// Se muestra al ver todas las ciudades.
  final int activeCities;

  /// Se muestra al ver una sola ciudad, en lugar de las ciudades.
  final int activeOperators;
}

class ModuleStat {
  const ModuleStat({required this.module, required this.count});

  final BusinessModule module;
  final int count;
}

/// Una entrada de actividad. Vendrá de `admin_alerts`.
class ActivityItem {
  const ActivityItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.refPath,
  });

  final AlertType type;
  final String title;
  final String subtitle;
  final DateTime createdAt;

  /// Documento relacionado, por ejemplo `orders/{id}`.
  final String? refPath;
}