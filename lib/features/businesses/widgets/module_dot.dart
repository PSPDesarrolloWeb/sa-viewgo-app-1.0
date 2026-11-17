import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/features/businesses/business_model.dart';

/// Color con el que se marca el estado de un módulo.
Color moduleStatusColor(BuildContext context, ModuleStatus status) =>
    switch (status) {
      ModuleStatus.active => AppColors.primary,
      ModuleStatus.trial => AppColors.septenary,
      ModuleStatus.suspended => AppColors.error,
      ModuleStatus.disabled => ThemeConfig.getSubtleTextColor(context),
    };

/// Punto de color del módulo + su nombre. Si no está activo, añade el
/// estado ("Parking · Prueba").
class ModuleDot extends StatelessWidget {
  const ModuleDot({super.key, required this.state});

  final BusinessModuleState state;

  @override
  Widget build(BuildContext context) {
    final extra = state.status == ModuleStatus.active ? '' : ' · ${state.status.label}';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: state.module.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          '${state.module.label}$extra',
          style: ThemeConfig.getTextLight12(context).copyWith(
            fontSize: 11.5,
            color: state.status == ModuleStatus.suspended
                ? AppColors.error
                : ThemeConfig.getPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}
