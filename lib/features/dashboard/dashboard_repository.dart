import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saviewgo/features/alerts/alert_type.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/shared/models/business_module.dart';

/// Fuente de datos del Resumen.
abstract interface class DashboardRepository {
  /// [cityId] null = todas las ciudades (superadmin global).
  Future<DashboardSummary> fetchSummary({String? cityId});
}

/// Ficha: FirestoreDashboardRepository
/// - Colecciones: business, city, ecommerce-orders, food-orders,
///   adminNotifications
/// - Documentos hoy: decenas de negocios · pedidos y avisos crecen sin tope
/// - Quién lee: superadmin_global y superadmin_city
/// - Pantalla: Inicio (Resumen)
/// - Tiempo real: no; se pide al entrar y al jalar hacia abajo
/// - Patrón: P6 (contadores con `count()`: 1 lectura por cada 1000
///   entradas del índice, nunca se leen los documentos) más P3 acotado
///   (últimos 5 avisos, `limit(5)`).
/// - Filtros: la ciudad va siempre en el servidor (`cityIds` en negocios,
///   `cityId` en pedidos y avisos). Las reglas del superadmin_city lo
///   exigen en pedidos y avisos.
/// - Índices: todos ya existen (cityId+createdAt en pedidos y avisos;
///   las igualdades de negocios y pedidos se combinan por fusión).
///
/// Criterios (definidos aquí; el panel web no los calculaba):
/// - Prueba por vencer: módulo con `status == 'trial'` y `trialEndsAt` dentro
///   de los próximos 7 días o ya vencida (sigue en prueba).
/// - Suscripción atrasada: módulo con `status == 'active'` y
///   `nextBillingDate` igual o anterior a ahora. Incluye los módulos activados
///   sin recibir el pago (`paymentStatus: pending` deja `nextBillingDate` en
///   la fecha de activación). Un negocio con dos módulos en esa situación
///   cuenta dos veces: se cuentan módulos, no negocios.
/// - Entregadores (solo al ver una ciudad): documentos de `courier` con
///   `status == 'active'` y `cityId` igual a la ciudad, estén en línea o no.
///   Se cambió desde `logisticsProfiles`, cuyo `scope`/`scopeId` no coincidió
///   con los datos reales (daba 0 con un entregador activo en Ibarra).
/// - Índices: `modules.X.status + modules.X.trialEndsAt` y
///   `modules.X.status + modules.X.nextBillingDate`, solos (global) y con
///   `cityIds` por delante (ciudad); 20 en total.
class FirestoreDashboardRepository implements DashboardRepository {
  const FirestoreDashboardRepository();

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  Future<DashboardSummary> fetchSummary({String? cityId}) async {
    final startOfDay = _startOfToday();

    final results = await Future.wait<Object?>([
      _activeBusinesses(cityId),
      _missingBranch(cityId),
      _ordersToCheck(cityId),
      _ordersSince(startOfDay, cityId),
      cityId == null ? _activeCities() : Future.value(0),
      _moduleStats(cityId),
      _recentNotifications(cityId),
      _trialsExpiring(cityId),
      _overdueSubscriptions(cityId),
      cityId == null ? Future.value(null) : _activeOperators(cityId),
    ]);

    return DashboardSummary(
      cityId: cityId,
      pending: [
        PendingItem(type: PendingType.paymentsToVerify, count: results[2] as int),
        PendingItem(type: PendingType.overdueSubscriptions, count: results[8] as int),
        PendingItem(type: PendingType.missingMainBranch, count: results[1] as int),
        PendingItem(type: PendingType.trialsExpiring, count: results[7] as int),
      ],
      metrics: DashboardMetrics(
        activeBusinesses: results[0] as int,
        ordersToday: results[3] as int,
        activeCities: results[4] as int,
        activeOperators: results[9] as int?,
      ),
      modules: results[5] as List<ModuleStat>,
      activity: results[6] as List<ActivityItem>,
    );
  }

  DateTime _startOfToday() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Query<Map<String, dynamic>> _business(String? cityId) {
    final col = _db.collection('business');
    return cityId == null ? col : col.where('cityIds', arrayContains: cityId);
  }

  Future<int> _count(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }

  Future<int> _activeBusinesses(String? cityId) =>
      _count(_business(cityId).where('active', isEqualTo: true));

  /// Negocios que aún no tienen sucursal.
  Future<int> _missingBranch(String? cityId) =>
      _count(_business(cityId).where('branchCount', isEqualTo: 0));

  Future<int> _activeCities() =>
      _count(_db.collection('city').where('active', isEqualTo: true));

  /// Transferencias con comprobante esperando validación, en las dos
  /// colecciones de pedidos.
  Future<int> _ordersToCheck(String? cityId) async {
    final counts = await Future.wait([
      for (final name in _orderCollections)
        _count(_orders(name, cityId).where('status', isEqualTo: 'payment_received')),
    ]);
    return counts.fold<int>(0, (a, b) => a + b);
  }

  Future<int> _ordersSince(DateTime since, String? cityId) async {
    final counts = await Future.wait([
      for (final name in _orderCollections)
        // Se pide en orden descendente a propósito: así usa el índice
        // `cityId + createdAt` (descendente) que ya existe. Sin `orderBy`,
        // Firestore pediría otro en orden ascendente para cada colección.
        _count(_orders(name, cityId)
            .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(since))
            .orderBy('createdAt', descending: true)),
    ]);
    return counts.fold<int>(0, (a, b) => a + b);
  }

  /// Módulos en prueba que vencen en 7 días o ya vencieron.
  Future<int> _trialsExpiring(String? cityId) async {
    final limit = Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)));
    final counts = await Future.wait([
      for (final module in BusinessModule.values)
        _count(_business(cityId)
            .where('modules.${module.key}.status', isEqualTo: 'trial')
            .where('modules.${module.key}.trialEndsAt', isLessThanOrEqualTo: limit)),
    ]);
    return counts.fold<int>(0, (a, b) => a + b);
  }

  /// Módulos activos cuya fecha de cobro ya llegó.
  Future<int> _overdueSubscriptions(String? cityId) async {
    final now = Timestamp.now();
    final counts = await Future.wait([
      for (final module in BusinessModule.values)
        _count(_business(cityId)
            .where('modules.${module.key}.status', isEqualTo: 'active')
            .where('modules.${module.key}.nextBillingDate', isLessThanOrEqualTo: now)),
    ]);
    return counts.fold<int>(0, (a, b) => a + b);
  }

  Future<int> _activeOperators(String cityId) => _count(_db
      .collection('courier')
      .where('status', isEqualTo: 'active')
      .where('cityId', isEqualTo: cityId));

  static const _orderCollections = ['ecommerce-orders', 'food-orders'];

  Query<Map<String, dynamic>> _orders(String name, String? cityId) {
    final col = _db.collection(name);
    return cityId == null ? col : col.where('cityId', isEqualTo: cityId);
  }

  /// Negocios con cada módulo encendido, de mayor a menor.
  Future<List<ModuleStat>> _moduleStats(String? cityId) async {
    final counts = await Future.wait([
      for (final module in BusinessModule.values)
        _count(_business(cityId).where('modules.${module.key}.enabled', isEqualTo: true)),
    ]);
    final stats = [
      for (var i = 0; i < BusinessModule.values.length; i++)
        ModuleStat(module: BusinessModule.values[i], count: counts[i]),
    ];
    stats.sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }

  /// Últimos 5 avisos para el superadmin (`adminNotifications`): hoy, las
  /// transferencias por validar.
  Future<List<ActivityItem>> _recentNotifications(String? cityId) async {
    Query<Map<String, dynamic>> query = _db.collection('adminNotifications');
    if (cityId != null) query = query.where('cityId', isEqualTo: cityId);
    final snapshot = await query.orderBy('createdAt', descending: true).limit(5).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      final orderId = data['orderId'] as String?;
      final module = data['module'] as String?;
      return ActivityItem(
        type: AlertType.paymentPendingReview,
        title: data['title'] as String? ?? 'Aviso',
        subtitle: data['body'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        refPath: orderId == null || module == null ? null : '$module-orders/$orderId',
      );
    }).toList();
  }
}
