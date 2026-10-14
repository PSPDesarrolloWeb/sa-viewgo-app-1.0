import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Barra superior compacta (56 px) de las pantallas del shell.
class ShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ShellAppBar({super.key, required this.title, this.actions = const []});

  final String title;

  /// Acciones propias de la pantalla; se muestran antes del avatar.
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      toolbarHeight: 56,
      automaticallyImplyLeading: false,
      centerTitle: false,
      titleSpacing: 16,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: ThemeConfig.getBackgroundColor(context),
      surfaceTintColor: Colors.transparent,
      shape: Border(
        bottom: BorderSide(color: ThemeConfig.getBorderColor(context)),
      ),
      title: Text(
        title,
        style: ThemeConfig.getTextBold18(context).copyWith(
          color: ThemeConfig.getPrimaryColor(context),
        ),
      ),
      actions: [
        ...actions,
        const Padding(
          padding: EdgeInsets.only(left: 8, right: 16),
          child: _UserAvatar(),
        ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  String _initials(User? user) {
    final source = (user?.displayName?.trim().isNotEmpty ?? false)
        ? user!.displayName!.trim()
        : (user?.email ?? '');
    final parts = source.split(RegExp(r'[\s@._-]+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'SA' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.2),
      child: Text(
        _initials(FirebaseAuth.instance.currentUser),
        style: ThemeConfig.getTextBold12(context).copyWith(
          color: isDark ? AppColors.inversePrimary : AppColors.onPrimaryContainer,
        ),
      ),
    );
  }
}