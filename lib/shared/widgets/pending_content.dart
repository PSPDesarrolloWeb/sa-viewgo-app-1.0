import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Contenido temporal mientras se construye cada pestaña.
class PendingContent extends StatelessWidget {
  const PendingContent({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = ThemeConfig.getSubtleTextColor(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ThemeConfig.getTextLight14(context).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}