import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Chip de la barra superior con la ciudad que se está viendo.
///
/// Superadmin global: "Todas" con flecha (el selector llegará con el
/// catálogo de ciudades, P1). Superadmin de ciudad: su ciudad con candado,
/// sin acción.
class CityScopeChip extends StatelessWidget {
  const CityScopeChip({super.key, required this.cityName, this.onTap});

  /// null = todas las ciudades.
  final String? cityName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final locked = cityName != null;
    final color = ThemeConfig.getPrimaryColor(context);
    final style = ThemeConfig.getTextBold12(context).copyWith(color: color);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: ThemeConfig.getBorderColorStrong(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : onTap,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  locked ? Icons.lock_outline_rounded : Icons.location_on_outlined,
                  size: 14,
                  color: color,
                ),
                const SizedBox(width: 6),
                Text(cityName ?? 'Todas', style: style),
                if (!locked) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}