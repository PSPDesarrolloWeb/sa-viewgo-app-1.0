import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';

/// Barra apilada con los módulos activos por categoría y su leyenda.
class ModulesBreakdown extends StatelessWidget {
  const ModulesBreakdown({super.key, required this.modules});

  final List<ModuleStat> modules;

  @override
  Widget build(BuildContext context) {
    final visible = modules.where((m) => m.count > 0).toList();

    return DashboardCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: visible.isEmpty
                  ? ColoredBox(color: ThemeConfig.getColor12(context))
                  : Row(
                      children: [
                        for (var i = 0; i < visible.length; i++) ...[
                          if (i > 0) const SizedBox(width: 2),
                          Expanded(
                            flex: visible[i].count,
                            child: ColoredBox(color: visible[i].module.color),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  for (final stat in modules)
                    SizedBox(width: width, child: _LegendItem(stat: stat)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.stat});

  final ModuleStat stat;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: stat.module.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            stat.module.label,
            style: ThemeConfig.getTextLight12(context).copyWith(
              color: ThemeConfig.getSubtleTextColor(context),
            ),
          ),
        ),
        Text(
          '${stat.count}',
          style: ThemeConfig.getTextBold12(context).copyWith(
            color: ThemeConfig.getPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}