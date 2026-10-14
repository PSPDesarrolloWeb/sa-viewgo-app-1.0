import 'package:flutter/material.dart';

/// Pestañas del bottom nav. El orden debe coincidir con las ramas de
/// StatefulShellRoute en app_router.dart.
enum MainTab {
  home('Inicio', Icons.home_outlined, Icons.home_rounded),
  businesses('Negocios', Icons.storefront_outlined, Icons.storefront_rounded),
  alerts('Alertas', Icons.notifications_none_rounded, Icons.notifications_rounded),
  cities('Ciudades', Icons.location_on_outlined, Icons.location_on_rounded),
  profile('Perfil', Icons.person_outline_rounded, Icons.person_rounded);

  const MainTab(this.label, this.icon, this.activeIcon);

  final String label;
  final IconData icon;
  final IconData activeIcon;
}