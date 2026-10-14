import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/shell/main_nav_bar.dart';

/// Contenedor de las pestañas principales: cuerpo de la rama activa más
/// el bottom nav.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Tocar la pestaña que ya está activa la regresa a su pantalla raíz.
  void _goTo(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final onFirstTab = navigationShell.currentIndex == 0;

    // En Android, "atrás" desde otra pestaña vuelve a Inicio en vez de
    // cerrar la app. Desde Inicio sí cierra.
    return PopScope(
      canPop: onFirstTab,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goTo(0);
      },
      child: Scaffold(
        backgroundColor: ThemeConfig.getBackgroundColor(context),
        body: navigationShell,
        bottomNavigationBar: MainNavBar(
          currentIndex: navigationShell.currentIndex,
          onTap: _goTo,
        ),
      ),
    );
  }
}