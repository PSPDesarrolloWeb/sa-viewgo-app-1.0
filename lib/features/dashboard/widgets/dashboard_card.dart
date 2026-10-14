import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Superficie base del Resumen: fondo de tarjeta, borde fino y radio 12.
class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Material(
      color: ThemeConfig.getForegroundColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: ThemeConfig.getBorderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Cuadro de ícono con el color de la categoría.
class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.icon, required this.color, this.size = 28});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: size * 0.56, color: color),
    );
  }
}