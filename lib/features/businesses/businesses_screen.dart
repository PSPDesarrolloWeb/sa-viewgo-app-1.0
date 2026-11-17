import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/businesses/business_categories.dart';
import 'package:saviewgo/features/businesses/business_model.dart';
import 'package:saviewgo/features/businesses/businesses_providers.dart';
import 'package:saviewgo/features/businesses/businesses_repository.dart';
import 'package:saviewgo/features/businesses/widgets/business_avatar.dart';
import 'package:saviewgo/features/businesses/widgets/module_dot.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/cities/city_scope_chip.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/shared/models/business_module.dart';
import 'package:saviewgo/shared/utils/input_rules.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

/// Pestaña Negocios: lista paginada (20 por página) con búsqueda por
/// nombre y filtros por estado y módulo. La ciudad sale del selector.
class BusinessesScreen extends ConsumerStatefulWidget {
  const BusinessesScreen({super.key});

  @override
  ConsumerState<BusinessesScreen> createState() => _BusinessesScreenState();
}

class _BusinessesScreenState extends ConsumerState<BusinessesScreen> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400) {
      ref.read(businessListProvider.notifier).loadMore();
    }
  }

  void _onSearchChanged(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final filters = ref.read(businessFiltersProvider);
      final query = cleanText(text);
      if (query == filters.query) return;
      ref.read(businessFiltersProvider.notifier).set(filters.copyWith(query: query));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    final filters = ref.read(businessFiltersProvider);
    if (filters.query.isNotEmpty) {
      ref.read(businessFiltersProvider.notifier).set(filters.copyWith(query: ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(businessListProvider);
    final filters = ref.watch(businessFiltersProvider);
    final cities = ref.watch(citiesProvider).value ?? const <CityModel>[];
    final cityId = ref.watch(scopeCityIdProvider).value;

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: const ShellAppBar(
        title: 'Negocios',
        actions: [CityScopeChip()],
      ),
      body: Column(
        children: [
          _SearchAndFilters(
            controller: _search,
            filters: filters,
            onChanged: _onSearchChanged,
            onClear: _clearSearch,
          ),
          Expanded(
            child: RefreshIndicator(
              color: context.accentText,
              onRefresh: () => ref.read(businessListProvider.notifier).refresh(),
              child: _buildList(state, filters, cities, cityId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BusinessListState state,
    BusinessFilters filters,
    List<CityModel> cities,
    String? cityId,
  ) {
    if (state.loading) {
      return const _ListMessage(loading: true);
    }
    if (state.error) {
      return _ListMessage(
        icon: Icons.cloud_off_rounded,
        message: 'No se pudieron cargar los negocios.',
        actionLabel: 'Reintentar',
        onAction: () => ref.read(businessListProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return _ListMessage(
        icon: Icons.storefront_outlined,
        message: filters.isSearching || filters.hasFilters
            ? 'Ningún negocio coincide con la búsqueda.'
            : 'Todavía no hay negocios aquí.',
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
          return _ListFooter(
            loadingMore: state.loadingMore,
            failed: state.moreError,
            onRetry: () => ref.read(businessListProvider.notifier).loadMore(),
          );
        }
        final business = state.items[index];
        return _BusinessCard(
          business: business,
          cityLabel: business.cityLabel(cities, preferredCityId: cityId),
          onTap: () {
            // Sin esto, al volver del detalle el campo de búsqueda recupera
            // el foco y el teclado tapa la barra inferior.
            FocusManager.instance.primaryFocus?.unfocus();
            context.push('/businesses/${business.id}', extra: business);
          },
        );
      },
    );
  }
}

// ── Búsqueda y filtros ────────────────────────────────────────────────

class _SearchAndFilters extends ConsumerWidget {
  const _SearchAndFilters({
    required this.controller,
    required this.filters,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final BusinessFilters filters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(businessFiltersProvider.notifier);
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final searching = filters.isSearching;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            onChanged: onChanged,
            textInputAction: TextInputAction.search,
            inputFormatters: nameInputFormatters(maxLength: 40),
            style: ThemeConfig.getTextLight14(context),
            decoration: InputDecoration(
              hintText: 'Buscar negocio por nombre',
              hintStyle: ThemeConfig.getTextLight14(context).copyWith(color: subtle),
              isDense: true,
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: subtle),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (_, value, __) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        icon: Icon(Icons.close_rounded, size: 18, color: subtle),
                        onPressed: onClear,
                      ),
              ),
              filled: true,
              fillColor: ThemeConfig.getForegroundColor(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ThemeConfig.getBorderColor(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ThemeConfig.getBorderColor(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: ThemeConfig.getBorderColorActive(context)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterPill(
                  label: 'Activos',
                  selected: filters.active == true,
                  onTap: () => notifier.set(filters.copyWith(
                    active: filters.active == true ? null : true,
                  )),
                ),
                _FilterPill(
                  label: 'Inactivos',
                  selected: filters.active == false,
                  onTap: () => notifier.set(filters.copyWith(
                    active: filters.active == false ? null : false,
                  )),
                ),
                for (final module in BusinessModule.values)
                  _FilterPill(
                    label: module.label,
                    color: module.color,
                    selected: filters.module == module,
                    onTap: () => notifier.set(filters.copyWith(
                      module: filters.module == module ? null : module,
                    )),
                  ),
              ],
            ),
          ),
          if (searching && filters.hasFilters)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Con búsqueda, los filtros se aplican a los primeros resultados.',
                style: ThemeConfig.getTextLight10(context).copyWith(color: subtle),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final base = color ?? ThemeConfig.getPrimaryColor(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? base.withValues(alpha: 0.14) : Colors.transparent,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? base : ThemeConfig.getBorderColorStrong(context),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                label,
                style: (selected
                        ? ThemeConfig.getTextBold12(context)
                        : ThemeConfig.getTextLight12(context))
                    .copyWith(color: selected ? base : ThemeConfig.getPrimaryColor(context)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tarjeta ───────────────────────────────────────────────────────────

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.business,
    required this.cityLabel,
    required this.onTap,
  });

  final BusinessModel business;
  final String cityLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    final modules = business.enabledModules;
    final warnings = <String>[
      if (business.missingBranch) 'Sin sucursal',
      if (!business.hasOwnerAccount) 'Sin cuenta de dueño',
    ];

    return DashboardCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BusinessAvatar(name: business.name, imageUrl: business.profileImageUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        business.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: ThemeConfig.getTextBold14(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusTag(active: business.active),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${categoryLabel(business.category)} · $cityLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
                ),
                if (modules.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      for (final m in modules) ModuleDot(state: m),
                    ],
                  ),
                ],
                if (warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.septenary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          warnings.join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ThemeConfig.getTextLight12(context)
                              .copyWith(fontSize: 11.5, color: AppColors.septenary),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : ThemeConfig.getSubtleTextColor(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Activo' : 'Inactivo',
        style: ThemeConfig.getTextBold10(context).copyWith(color: color),
      ),
    );
  }
}

// ── Estados vacíos y pie ──────────────────────────────────────────────

class _ListMessage extends StatelessWidget {
  const _ListMessage({
    this.loading = false,
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final bool loading;
  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    // ListView para que jalar hacia abajo funcione también aquí.
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
                          message ?? '',
                          textAlign: TextAlign.center,
                          style: ThemeConfig.getTextLight14(context).copyWith(color: subtle),
                        ),
                        if (onAction != null) ...[
                          const SizedBox(height: 8),
                          TextButton(onPressed: onAction, child: Text(actionLabel ?? '')),
                        ],
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({
    required this.loadingMore,
    required this.failed,
    required this.onRetry,
  });

  final bool loadingMore;
  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (failed) {
      return Center(
        child: TextButton(
          onPressed: onRetry,
          child: const Text('No se pudo cargar más. Reintentar'),
        ),
      );
    }
    return const Padding(
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
}
