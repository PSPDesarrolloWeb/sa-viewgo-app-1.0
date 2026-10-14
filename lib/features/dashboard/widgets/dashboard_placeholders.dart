import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';
import 'package:saviewgo/shared/utils/theme_x.dart';

/// Esqueleto mientras carga el Resumen.
class DashboardLoading extends StatelessWidget {
  const DashboardLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final color = ThemeConfig.getColor12(context);
    Widget box(double height, {double? width}) => Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
        );

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        box(22, width: 220),
        const SizedBox(height: 6),
        box(12, width: 180),
        const SizedBox(height: 22),
        Row(children: [Expanded(child: box(118)), const SizedBox(width: 8), Expanded(child: box(118))]),
        const SizedBox(height: 8),
        Row(children: [Expanded(child: box(118)), const SizedBox(width: 8), Expanded(child: box(118))]),
        const SizedBox(height: 18),
        box(70),
        const SizedBox(height: 18),
        box(110),
      ],
    );
  }
}

/// Error con opción de reintentar.
class DashboardError extends StatelessWidget {
  const DashboardError({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.cloud_off_rounded, size: 40, color: ThemeConfig.getSubtleTextColor(context)),
        const SizedBox(height: 12),
        Text(
          'No pudimos cargar el resumen.',
          textAlign: TextAlign.center,
          style: ThemeConfig.getTextBold14(context).copyWith(
            color: ThemeConfig.getPrimaryColor(context),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Revisa tu conexión e inténtalo de nuevo.',
          textAlign: TextAlign.center,
          style: ThemeConfig.getTextLight12(context).copyWith(
            color: ThemeConfig.getSubtleTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: onRetry,
            child: Text(
              'Reintentar',
              style: ThemeConfig.getTextBold13(context).copyWith(color: context.accentText),
            ),
          ),
        ),
      ],
    );
  }
}