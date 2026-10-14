import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';

/// Tres métricas en una sola franja, separadas por divisores.
class MetricsStrip extends StatelessWidget {
  const MetricsStrip({super.key, required this.metrics, required this.isAllCities});

  final DashboardMetrics metrics;
  final bool isAllCities;

  @override
  Widget build(BuildContext context) {
    final cells = [
      ('${metrics.activeBusinesses}', 'Negocios activos'),
      ('${metrics.ordersToday}', 'Pedidos hoy'),
      isAllCities
          ? ('${metrics.activeCities}', 'Ciudades')
          : ('${metrics.activeOperators}', 'Operarios'),
    ];
    final divider = VerticalDivider(
      width: 1,
      thickness: 1,
      color: ThemeConfig.getBorderColor(context),
    );

    return DashboardCard(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: IntrinsicHeight(
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) divider,
              Expanded(child: _Cell(value: cells[i].$1, label: cells[i].$2)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: ThemeConfig.getTextBold20(context).copyWith(
            color: ThemeConfig.getPrimaryColor(context),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: ThemeConfig.getTextLight12(context).copyWith(
            fontSize: 11,
            color: ThemeConfig.getSubtleTextColor(context),
          ),
        ),
      ],
    );
  }
}