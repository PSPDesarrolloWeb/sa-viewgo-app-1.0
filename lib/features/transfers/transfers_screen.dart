import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/cities/city_scope_chip.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/features/transfers/transfer_item.dart';
import 'package:saviewgo/features/transfers/transfer_sheet.dart';
import 'package:saviewgo/features/transfers/transfers_providers.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

/// Transferencias: pedidos (ecommerce y food), reservas de servicios, parking
/// y tickets de eventos. ViewGo recibe el pago y el superadmin lo compara con
/// su banco, luego valida o rechaza con motivo. Contratos: contrato_pedidos §8,
/// contrato_reservas §5, contrato_eventos §5 y contrato_qr (parking).
class TransfersScreen extends ConsumerStatefulWidget {
  const TransfersScreen({super.key});

  @override
  ConsumerState<TransfersScreen> createState() => _TransfersScreenState();
}

class _TransfersScreenState extends ConsumerState<TransfersScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(transfersProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(TransferItem item) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      builder: (_) => TransferSheet(item: item),
    );
    if (message != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(transfersProvider);
    final filters = ref.watch(transferFiltersProvider);
    final cities = ref.watch(citiesProvider).value ?? const <CityModel>[];
    final notifier = ref.read(transferFiltersProvider.notifier);

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(
        title: 'Transferencias',
        actions: [CityScopeChip()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Segmented<TransferKind>(
                  values: TransferKind.values,
                  selected: filters.kind,
                  label: (k) => k.label,
                  onSelected: (k) => notifier.set(filters.copyWith(kind: k)),
                ),
                const SizedBox(height: 10),
                _Segmented<TransferBucket>(
                  values: TransferBucket.values,
                  selected: filters.bucket,
                  label: (b) => b.label,
                  onSelected: (b) => notifier.set(filters.copyWith(bucket: b)),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: context.accentText,
              onRefresh: () => ref.read(transfersProvider.notifier).refresh(),
              child: _list(state, filters, cities),
            ),
          ),
        ],
      ),
    );
  }

  Widget _list(TransfersState state, TransferFilters filters, List<CityModel> cities) {
    if (state.loading) return const _Message(loading: true);
    if (state.error) {
      return _Message(
        icon: Icons.cloud_off_rounded,
        text: 'No se pudieron cargar las transferencias.',
        actionLabel: 'Reintentar',
        onAction: () => ref.read(transfersProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return _Message(
        icon: Icons.account_balance_outlined,
        text: switch (filters.bucket) {
          TransferBucket.toValidate => 'No hay transferencias por validar.',
          TransferBucket.approved => 'Aún no hay transferencias aprobadas.',
          TransferBucket.rejected => 'No hay transferencias rechazadas.',
        },
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
                    onPressed: () => ref.read(transfersProvider.notifier).loadMore(),
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
        final item = state.items[index];
        return _TransferCard(
          item: item,
          cityName: cities.byId(item.cityId)?.name,
          onTap: () => _open(item),
        );
      },
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final primary = ThemeConfig.getPrimaryColor(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final value in values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: value == selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
                shape: StadiumBorder(
                  side: BorderSide(
                    color: value == selected
                        ? primary
                        : ThemeConfig.getBorderColorStrong(context),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(value),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    child: Text(
                      label(value),
                      style: value == selected
                          ? ThemeConfig.getTextBold12(context)
                          : ThemeConfig.getTextLight12(context),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  const _TransferCard({required this.item, required this.cityName, required this.onTap});

  final TransferItem item;
  final String? cityName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIcon(
            icon: Icons.account_balance_rounded,
            color: AppColors.secondary,
            size: 34,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ThemeConfig.getTextBold14(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.amount == 0 ? 'Gratis' : '\$${item.amount.toStringAsFixed(2)}',
                      style: ThemeConfig.getTextBold14(context),
                    ),
                  ],
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  [
                    ?cityName,
                    if (item.createdAt != null) relativeTime(item.createdAt!),
                  ].join(' · '),
                  style: ThemeConfig.getTextLight10(context).copyWith(color: subtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({this.loading = false, this.icon, this.text, this.actionLabel, this.onAction});

  final bool loading;
  final IconData? icon;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 320,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 40, color: subtle),
                        const SizedBox(height: 12),
                        Text(
                          text ?? '',
                          textAlign: TextAlign.center,
                          style: ThemeConfig.getTextLight14(context).copyWith(color: subtle),
                        ),
                        if (onAction != null)
                          TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
