import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/cities/city_model.dart';
import 'package:saviewgo/features/cities/city_picker_sheet.dart';

/// Chip de la barra superior con la ciudad que se está viendo.
///
/// superadmin_global: "Todas" o la ciudad elegida, con flecha; abre el
/// selector. superadmin_city: su ciudad con candado, sin acción.
class CityScopeChip extends ConsumerWidget {
  const CityScopeChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final claims = ref.watch(adminClaimsProvider).value;
    if (claims == null || (!claims.isGlobal && !claims.isCity)) {
      return const SizedBox.shrink();
    }

    final locked = !claims.isGlobal;
    final cityId = locked ? claims.cityId : ref.watch(selectedCityIdProvider);
    final cities = ref.watch(citiesProvider).value ?? const [];
    final label = cityId == null ? 'Todas' : cities.byId(cityId)?.name ?? 'Ciudad';

    final color = ThemeConfig.getPrimaryColor(context);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: ThemeConfig.getBorderColorStrong(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : () => showCityPickerSheet(context),
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ThemeConfig.getTextBold12(context).copyWith(color: color),
                  ),
                ),
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