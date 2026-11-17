import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/cities/city_scope_chip.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/features/orders/order_audit.dart';
import 'package:saviewgo/features/orders/orders_providers.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';
import 'package:saviewgo/shared/widgets/list_message.dart';

/// Pedidos de ecommerce y food, solo lectura: filtros por módulo y estado,
/// y el detalle con su historial. Cancelar y registrar reembolsos se hace
/// en el panel web.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(ordersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersProvider);
    final filters = ref.watch(orderFiltersProvider);
    final cities = ref.watch(citiesProvider).value ?? const <CityModel>[];
    final notifier = ref.read(orderFiltersProvider.notifier);

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: ThemeConfig.getBackgroundColor(context),
        surfaceTintColor: Colors.transparent,
        shape: Border(bottom: BorderSide(color: ThemeConfig.getBorderColor(context))),
        title: Text('Pedidos', style: ThemeConfig.getTextBold18(context)),
        actions: const [CityScopeChip(), SizedBox(width: 16)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PillRow<OrderModuleKind>(
                  values: OrderModuleKind.values,
                  selected: filters.module,
                  label: (m) => m.label,
                  onSelected: notifier.setModule,
                ),
                const SizedBox(height: 10),
                PillRow<String?>(
                  values: [null, ...orderStatusLabels.keys],
                  selected: filters.status,
                  label: (s) => s == null ? 'Todos' : statusLabel(s),
                  onSelected: notifier.setStatus,
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: context.accentText,
              onRefresh: () => ref.read(ordersProvider.notifier).refresh(),
              child: _list(state, cities),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(OrdersState state, List<CityModel> cities) {
    if (state.loading) return const ListMessage(loading: true);
    if (state.error) {
      return ListMessage(
        icon: Icons.cloud_off_rounded,
        text: 'No se pudieron cargar los pedidos.',
        actionLabel: 'Reintentar',
        onAction: () => ref.read(ordersProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return const ListMessage(
        icon: Icons.receipt_long_outlined,
        text: 'No hay pedidos con estos filtros.',
      );
    }

    final extra = (state.loadingMore || state.moreError || state.hasMore) ? 1 : 0;
    return ListView.separated(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: state.items.length + extra,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return state.moreError
              ? Center(
                  child: TextButton(
                    onPressed: () => ref.read(ordersProvider.notifier).loadMore(),
                    child: const Text('No se pudo cargar más. Reintentar'),
                  ),
                )
              : const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
        }
        final order = state.items[index];
        return _OrderCard(
          order: order,
          cityName: cities.byId(order.cityId)?.name,
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            backgroundColor: ThemeConfig.getBackgroundColor(context),
            builder: (_) => _OrderSheet(order: order, cityName: cities.byId(order.cityId)?.name),
          ),
        );
      },
    );
  }
}

Color _toneColor(BuildContext context, StatusTone tone) => switch (tone) {
      StatusTone.good => AppColors.primary,
      StatusTone.bad => AppColors.error,
      StatusTone.warn => AppColors.septenary,
      StatusTone.neutral => ThemeConfig.getSubtleTextColor(context),
    };

class _StatusTag extends StatelessWidget {
  const _StatusTag(this.status);

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, statusTone(status));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        statusLabel(status),
        style: ThemeConfig.getTextBold10(context).copyWith(color: color),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.cityName, required this.onTap});

  final AuditOrder order;
  final String? cityName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConfig.getTextBold14(context),
                ),
              ),
              const SizedBox(width: 8),
              Text('\$${order.total.toStringAsFixed(2)}',
                  style: ThemeConfig.getTextBold14(context)),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            [order.businessName, order.clientName].where((s) => s.isNotEmpty).join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _StatusTag(order.status),
              if (order.needsAudit) ...[
                const SizedBox(width: 6),
                const Icon(Icons.flag_rounded, size: 14, color: AppColors.septenary),
                const SizedBox(width: 2),
                Text(
                  'Revisar',
                  style: ThemeConfig.getTextBold10(context)
                      .copyWith(color: AppColors.septenary),
                ),
              ],
              const Spacer(),
              Text(
                [
                  ?cityName,
                  if (order.createdAt != null) relativeTime(order.createdAt!),
                ].join(' · '),
                style: ThemeConfig.getTextLight10(context).copyWith(color: subtle),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderSheet extends StatelessWidget {
  const _OrderSheet({required this.order, required this.cityName});

  final AuditOrder order;
  final String? cityName;

  String _usd(double v) => '\$${v.toStringAsFixed(2)}';

  String _when(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final lines = <(String, String)>[
      ('Negocio', [order.businessName, order.branchName].where((s) => s.isNotEmpty).join(' · ')),
      if (cityName != null) ('Ciudad', cityName!),
      if (order.clientName.isNotEmpty) ('Cliente', order.clientName),
      ('Pago', paymentMethodLabels[order.paymentMethod] ?? order.paymentMethod),
      ('Entrega', deliveryTypeLabels[order.deliveryType] ?? order.deliveryType),
      ('Productos', _usd(order.subtotal)),
      if (order.deliveryCost > 0) ('Envío', _usd(order.deliveryCost)),
      if (order.serviceFee > 0) ('Servicio', _usd(order.serviceFee)),
      if (order.totalWeightKg != null) ('Peso', '${order.totalWeightKg} kg'),
      if (order.distanceKm != null) ('Distancia', '${order.distanceKm!.toStringAsFixed(1)} km'),
      if (order.requiredVehicle != null)
        ('Vehículo requerido', vehicleLabels[order.requiredVehicle] ?? order.requiredVehicle!),
      if (order.courierName != null)
        (
          'Entregador',
          [
            order.courierName!,
            if (order.courierVehicle != null) vehicleLabels[order.courierVehicle] ?? order.courierVehicle!,
          ].join(' · '),
        ),
      if (order.cashCollected != null) ('Efectivo cobrado', _usd(order.cashCollected!)),
      if (order.refundAmount != null) ('Reembolso registrado', _usd(order.refundAmount!)),
      if (order.paymentRejection != null) ('Pago rechazado', order.paymentRejection!),
      if (order.cancellation != null) ('Cancelación', order.cancellation!),
      if (order.issueReason != null) ('Problema de entrega', order.issueReason!),
      if (order.issueNote != null) ('Nota', order.issueNote!),
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(order.orderNumber, style: ThemeConfig.getTextBold18(context)),
                ),
                _StatusTag(order.status),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              order.module.label,
              style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
            ),
            const SizedBox(height: 12),
            Text(_usd(order.total),
                style: ThemeConfig.getTextBold20(context).copyWith(fontSize: 28)),
            const SizedBox(height: 10),
            for (final (label, value) in lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(label,
                          style: ThemeConfig.getTextLight12(context).copyWith(color: subtle)),
                    ),
                    Expanded(child: Text(value, style: ThemeConfig.getTextBold13(context))),
                  ],
                ),
              ),
            if (order.history.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('Historial', style: ThemeConfig.getTextBold14(context)),
              const SizedBox(height: 6),
              for (final h in order.history)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          h.at == null ? '' : _when(h.at!),
                          style: ThemeConfig.getTextLight10(context).copyWith(color: subtle),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          [statusLabel(h.status), if (h.note != null) h.note!].join(' · '),
                          style: ThemeConfig.getTextLight12(context),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 14),
            Text(
              'Para cancelar o registrar un reembolso, usa el panel web.',
              style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
            ),
          ],
        ),
      ),
    );
  }
}
