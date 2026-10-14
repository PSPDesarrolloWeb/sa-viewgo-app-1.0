import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/shared/utils/date_labels.dart';

/// Últimas entradas de actividad en una tarjeta con divisores.
class ActivityList extends StatelessWidget {
  const ActivityList({super.key, required this.items});

  final List<ActivityItem> items;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);

    if (items.isEmpty) {
      return DashboardCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Sin actividad reciente.',
          textAlign: TextAlign.center,
          style: ThemeConfig.getTextLight12(context).copyWith(color: subtle),
        ),
      );
    }

    return DashboardCard(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: ThemeConfig.getBorderColor(context)),
            _ActivityRow(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final subtle = ThemeConfig.getSubtleTextColor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        children: [
          CategoryIcon(icon: item.type.icon, color: item.type.color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: ThemeConfig.getTextBold13(context).copyWith(
                    color: ThemeConfig.getPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ThemeConfig.getTextLight12(context)
                      .copyWith(fontSize: 11.5, color: subtle),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            relativeTime(item.createdAt),
            style: ThemeConfig.getTextLight10(context).copyWith(fontSize: 11, color: subtle),
          ),
        ],
      ),
    );
  }
}