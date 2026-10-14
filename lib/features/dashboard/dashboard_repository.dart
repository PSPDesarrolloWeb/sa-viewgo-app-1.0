import 'package:saviewgo/features/alerts/alert_type.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/shared/models/business_module.dart';

/// Fuente de datos del Resumen.
///
/// La implementación real usará `count()` y contadores guardados (P6) o la
/// callable `getDashboardStats`, más las últimas `admin_alerts` con
/// `limit` (P3). Nunca leerá colecciones completas.
abstract interface class DashboardRepository {
  /// [cityId] null = todas las ciudades (superadmin global).
  Future<DashboardSummary> fetchSummary({String? cityId});
}

/// Datos de ejemplo mientras se conecta Firestore.
class MockDashboardRepository implements DashboardRepository {
  const MockDashboardRepository();

  @override
  Future<DashboardSummary> fetchSummary({String? cityId}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final isGlobal = cityId == null;
    final now = DateTime.now();
    // Con una ciudad elegida no se repite su nombre en cada fila.
    String place(String city) => isGlobal ? ' · $city' : '';

    return DashboardSummary(
      cityId: cityId,
      pending: [
        PendingItem(type: PendingType.paymentsToVerify, count: isGlobal ? 2 : 1),
        PendingItem(type: PendingType.overdueSubscriptions, count: isGlobal ? 5 : 1),
        PendingItem(type: PendingType.missingMainBranch, count: isGlobal ? 4 : 1),
        PendingItem(type: PendingType.trialsExpiring, count: isGlobal ? 3 : 1),
      ],
      metrics: DashboardMetrics(
        activeBusinesses: isGlobal ? 62 : 18,
        ordersToday: isGlobal ? 148 : 37,
        activeCities: 6,
        activeOperators: 6,
      ),
      modules: [
        ModuleStat(module: BusinessModule.food, count: isGlobal ? 31 : 10),
        ModuleStat(module: BusinessModule.ecommerce, count: isGlobal ? 24 : 7),
        ModuleStat(module: BusinessModule.services, count: isGlobal ? 19 : 5),
        ModuleStat(module: BusinessModule.parking, count: isGlobal ? 11 : 3),
        ModuleStat(module: BusinessModule.events, count: isGlobal ? 9 : 2),
      ],
      activity: [
        ActivityItem(
          type: AlertType.orderCreated,
          title: 'Nuevo pedido',
          subtitle: 'Café Andino${place('Ibarra')}',
          createdAt: now.subtract(const Duration(minutes: 4)),
        ),
        ActivityItem(
          type: AlertType.paymentVerified,
          title: 'Pago confirmado',
          subtitle: 'Glow Haus${place('Quito')}',
          createdAt: now.subtract(const Duration(minutes: 18)),
        ),
        ActivityItem(
          type: AlertType.businessPendingSetup,
          title: 'Negocio registrado',
          subtitle: 'Ferretería Norte${place('Otavalo')} · sin sucursal',
          createdAt: now.subtract(const Duration(hours: 1)),
        ),
        ActivityItem(
          type: AlertType.moduleTrialExpiring,
          title: 'Trial vence en 3 días',
          subtitle: 'Parking Centro · Parking',
          createdAt: now.subtract(const Duration(hours: 2)),
        ),
      ],
    );
  }
}