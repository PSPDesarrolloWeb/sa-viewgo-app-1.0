import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/app/app_router.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/dashboard/dashboard_summary.dart';
import 'package:saviewgo/features/dashboard/widgets/dashboard_card.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';

/// Ícono, color y destino de cada tipo de pendiente.
extension on PendingType {
  IconData get icon => switch (this) {
        PendingType.paymentsToVerify => Icons.credit_card_rounded,
        PendingType.overdueSubscriptions => Icons.warning_amber_rounded,
        PendingType.missingMainBranch => Icons.schedule_rounded,
        PendingType.trialsExpiring => Icons.hourglass_bottom_rounded,
      };

  Color get color => switch (this) {
        PendingType.paymentsToVerify => AppColors.secondary,
        PendingType.overdueSubscriptions => AppColors.error,
        PendingType.missingMainBranch => AppColors.senary,
        PendingType.trialsExpiring => AppColors.septenary,
      };

  /// Las pantallas destino leerán el filtro cuando existan.
  String get location => switch (this) {
        PendingType.paymentsToVerify =>
          '${AppRoutes.alerts}?type=payment.pending_review',
        PendingType.overdueSubscriptions =>
          '${AppRoutes.alerts}?type=subscription.overdue',
        PendingType.missingMainBranch =>
          '${AppRoutes.businesses}?setupStatus=pending_branch',
        PendingType.trialsExpiring =>
          '${AppRoutes.businesses}?filter=trial_expiring',
      };
}

/// Pendientes en una cuadrícula de 2 columnas.
class PendingGrid extends StatelessWidget {
  const PendingGrid({super.key, required this.items});

  final List<PendingItem> items;

  @override
  Widget build(BuildContext context) {
    const gap = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - gap) / 2;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final item in items)
              SizedBox(width: width, child: _PendingCard(item: item)),
          ],
        );
      },
    );
  }
}

class _PendingCard extends StatelessWidget {
  const _PendingCard({required this.item});

  final PendingItem item;

  @override
  Widget build(BuildContext context) {
    final type = item.type;
    return DashboardCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.go(type.location),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CategoryIcon(icon: type.icon, color: type.color),
              const Spacer(),
              Text(
                '${item.count}',
                style: ThemeConfig.getTextBold20(context).copyWith(
                  fontSize: 22,
                  color: ThemeConfig.getPrimaryColor(context),
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Text(
              type.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: ThemeConfig.getTextLight12(context).copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
                color: ThemeConfig.getPrimaryColor(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Revisar',
                style: ThemeConfig.getTextBold12(context)
                    .copyWith(color: context.accentText),
              ),
              const SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded, size: 14, color: context.accentText),
            ],
          ),
        ],
      ),
    );
  }
}

/// Contador total junto al título de la sección.
class PendingTotalBadge extends StatelessWidget {
  const PendingTotalBadge({super.key, required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final color = context.isDark ? AppColors.darkError : AppColors.onErrorContainer;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        total == 1 ? '1 pendiente' : '$total pendientes',
        style: ThemeConfig.getTextBold10(context).copyWith(fontSize: 11, color: color),
      ),
    );
  }
}