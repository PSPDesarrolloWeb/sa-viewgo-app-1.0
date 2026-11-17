import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/cities/city_scope_chip.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/features/orders/order_audit.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';
import 'package:saviewgo/shared/widgets/list_message.dart';

/// Entregador conectado ahora. Sin nombre ni documento a propósito: la
/// ficha de la persona (`logisticsProfiles`) trae su cédula y dirección, y
/// la app no la necesita para saber qué cobertura hay.
class OnlineCourier {
  const OnlineCourier({
    required this.uid,
    required this.cityId,
    required this.vehicle,
    required this.plate,
    required this.modules,
    required this.activeOrders,
  });

  factory OnlineCourier.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    final vehicle = data['vehicle'];
    List<String> strings(Object? v) => v is List ? v.whereType<String>().toList() : const [];
    return OnlineCourier(
      uid: doc.id,
      cityId: data['cityId'] as String? ?? '',
      vehicle: vehicle is Map ? vehicle['type'] as String? ?? '' : '',
      plate: vehicle is Map ? vehicle['plate'] as String? : null,
      modules: strings(data['modules']),
      activeOrders: strings(data['activeOrderIds']).length,
    );
  }

  final String uid;
  final String cityId;
  final String vehicle;
  final String? plate;
  final List<String> modules;
  final int activeOrders;

  bool get busy => activeOrders > 0;
}

/// Ficha: entregadores en línea
/// - Colección: courier/{uid}; decenas a cientos; cambia con frecuencia
/// - Quién lee: superadmin_global y superadmin_city (su `cityId`)
/// - Pantalla: Entregadores en línea (desde el Resumen), solo lectura
/// - Tiempo real: no; una lectura al abrir y al jalar hacia abajo
/// - Filtros: status == active, available == true y cityId opcional;
///   igualdades que se combinan sin índice compuesto. `limit(50)`.
/// - Patrón: P2 acotado, sin paginar: 50 conectados cubren la operación.
final couriersProvider =
    FutureProvider.autoDispose<List<OnlineCourier>>((ref) async {
  final cityId = await ref.watch(scopeCityIdProvider.future);
  ref.watch(firebaseUserProvider.select((u) => u.value?.uid));

  Query<Map<String, dynamic>> q = FirebaseFirestore.instance
      .collection('courier')
      .where('status', isEqualTo: 'active')
      .where('available', isEqualTo: true);
  if (cityId != null) q = q.where('cityId', isEqualTo: cityId);

  final snapshot = await q.limit(50).get();
  return snapshot.docs.map(OnlineCourier.fromDoc).toList();
});

class CouriersScreen extends ConsumerWidget {
  const CouriersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couriers = ref.watch(couriersProvider);
    final cities = ref.watch(citiesProvider).value ?? const <CityModel>[];

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ThemeConfig.getBackgroundColor(context),
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: ThemeConfig.getBorderColor(context))),
        title: Text('Entregadores en línea', style: ThemeConfig.getTextBold18(context)),
        actions: const [CityScopeChip(), SizedBox(width: 16)],
      ),
      body: RefreshIndicator(
        color: context.accentText,
        onRefresh: () => ref.refresh(couriersProvider.future),
        child: couriers.when(
          skipLoadingOnRefresh: true,
          loading: () => const ListMessage(loading: true),
          error: (_, __) => ListMessage(
            icon: Icons.cloud_off_rounded,
            text: 'No se pudieron cargar los entregadores.',
            actionLabel: 'Reintentar',
            onAction: () => ref.invalidate(couriersProvider),
          ),
          data: (list) => list.isEmpty
              ? const ListMessage(
                  icon: Icons.two_wheeler_outlined,
                  text: 'No hay entregadores en línea ahora.',
                )
              : _CouriersList(list: list, cities: cities),
        ),
      ),
    );
  }
}

class _CouriersList extends StatelessWidget {
  const _CouriersList({required this.list, required this.cities});

  final List<OnlineCourier> list;
  final List<CityModel> cities;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final busy = list.where((c) => c.busy).length;

    // Resumen por tipo de vehículo, de mayor a menor.
    final byVehicle = <String, int>{};
    for (final c in list) {
      byVehicle[c.vehicle] = (byVehicle[c.vehicle] ?? 0) + 1;
    }
    final summary = byVehicle.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        DashboardCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${list.length} en línea · $busy con pedido',
                  style: ThemeConfig.getTextBold14(context)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  for (final e in summary)
                    Text(
                      '${e.value} ${vehicleLabels[e.key] ?? 'Sin dato'}',
                      style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final c in list) ...[
          DashboardCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CategoryIcon(
                  icon: Icons.two_wheeler_rounded,
                  color: c.busy ? AppColors.septenary : AppColors.primary,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          vehicleLabels[c.vehicle] ?? 'Vehículo',
                          if (c.plate != null && c.plate!.isNotEmpty) c.plate!,
                        ].join(' · '),
                        style: ThemeConfig.getTextBold13(context),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          ?cities.byId(c.cityId)?.name,
                          c.modules
                              .map((m) => m == 'food' ? 'Gastronomía' : 'Ecommerce')
                              .join(' y '),
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                      ),
                    ],
                  ),
                ),
                Text(
                  c.busy
                      ? '${c.activeOrders} pedido${c.activeOrders == 1 ? '' : 's'}'
                      : 'Libre',
                  style: ThemeConfig.getTextBold12(context).copyWith(
                    color: c.busy ? AppColors.septenary : AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
