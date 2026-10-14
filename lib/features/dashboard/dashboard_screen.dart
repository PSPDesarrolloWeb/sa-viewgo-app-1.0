import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/cities/city_scope_chip.dart';
import 'package:saviewgo/features/dashboard/dashboard_providers.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/features/dashboard/widgets/activity_list.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_header.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_placeholders.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_section.dart';
import 'package:saviewgo/features/dashboard/widgets/metrics_strip.dart';
import 'package:saviewgo/features/dashboard/widgets/modules_breakdown.dart';
import 'package:saviewgo/features/dashboard/widgets/pending_grid.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';
import 'package:saviewgo/shared/widgets/shell_app_bar.dart';

/// Inicio (Resumen): pendientes primero, luego métricas, módulos activos
/// y actividad reciente.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);

    return Scaffold(
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      appBar: ShellAppBar(
        title: 'Resumen',
        actions: const [CityScopeChip()],
      ),
      body: RefreshIndicator(
        color: context.accentText,
        onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
        child: summary.when(
          // Al refrescar se mantiene el contenido anterior visible.
          skipLoadingOnRefresh: true,
          data: (data) => _DashboardBody(summary: data),
          loading: () => const DashboardLoading(),
          error: (_, __) => DashboardError(
            onRetry: () => ref.invalidate(dashboardSummaryProvider),
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const gap = SizedBox(height: 18);
    final isGlobalRole = ref.watch(adminClaimsProvider).value?.isGlobal ?? false;
    final cities = ref.watch(citiesProvider).value ?? const [];
    final cityName = cities.byId(summary.cityId)?.name;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        DashboardHeader(isGlobalRole: isGlobalRole, cityName: cityName),
        gap,
        DashboardSection(
          title: 'Requiere atención',
          trailing: PendingTotalBadge(total: summary.pendingTotal),
          child: PendingGrid(items: summary.pending),
        ),
        gap,
        MetricsStrip(metrics: summary.metrics, isAllCities: summary.isAllCities),
        gap,
        DashboardSection(
          title: 'Módulos activos',
          trailing: Text(
            '${summary.activeModulesTotal} en total',
            style: ThemeConfig.getTextLight12(context).copyWith(
              color: ThemeConfig.getSubtleTextColor(context),
            ),
          ),
          child: ModulesBreakdown(modules: summary.modules),
        ),
        gap,
        DashboardSection(
          title: 'Actividad reciente',
          trailing: GestureDetector(
            onTap: () => context.go(AppRoutes.alerts),
            child: Text(
              'Ver todo',
              style: ThemeConfig.getTextBold12(context).copyWith(color: context.accentText),
            ),
          ),
          child: ActivityList(items: summary.activity),
        ),
      ],
    );
  }
}