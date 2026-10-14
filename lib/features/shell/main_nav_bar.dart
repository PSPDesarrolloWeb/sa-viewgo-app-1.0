import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/alerts/alerts_providers.dart';
import 'package:saviewgo/features/shell/main_tab.dart';

/// Bottom nav con salomon_bottom_bar: la pestaña activa se abre en una
/// píldora con su texto; las demás muestran solo el ícono.
class MainNavBar extends ConsumerWidget {
  const MainNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unreadAlerts = ref.watch(unreadAlertsCountProvider);

    // Verde con contraste suficiente para texto en cada tema.
    final selectedColor =
        isDark ? AppColors.inversePrimary : AppColors.onPrimaryContainer;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: ThemeConfig.getForegroundColor(context),
        border: Border(
          top: BorderSide(color: ThemeConfig.getBorderColor(context)),
        ),
      ),
      // SalomonBottomBar ya incluye su SafeArea inferior.
      child: SalomonBottomBar(
        currentIndex: currentIndex,
        onTap: onTap,
        selectedItemColor: selectedColor,
        unselectedItemColor: ThemeConfig.getColor54(context),
        selectedColorOpacity: isDark ? 0.16 : 0.12,
        itemShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        items: [
          for (final tab in MainTab.values)
            SalomonBottomBarItem(
              icon: _TabIcon(
                icon: tab.icon,
                badgeCount: tab == MainTab.alerts ? unreadAlerts : 0,
              ),
              activeIcon: _TabIcon(
                icon: tab.activeIcon,
                badgeCount: tab == MainTab.alerts ? unreadAlerts : 0,
              ),
              title: Text(tab.label, style: ThemeConfig.getTextBold13(context)),
            ),
        ],
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.badgeCount});

  final IconData icon;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Badge.count(
      count: badgeCount,
      isLabelVisible: badgeCount > 0,
      backgroundColor: AppColors.error,
      textColor: AppColors.onError,
      child: Icon(icon, size: 22),
    );
  }
}