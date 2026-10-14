import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/theme_config.dart';

/// Título de sección en mayúsculas pequeñas, con un elemento opcional a la
/// derecha (contador, enlace "Ver todo").
class DashboardSection extends StatelessWidget {
  const DashboardSection({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 24,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: ThemeConfig.getTextBold12(context).copyWith(
                    color: ThemeConfig.getSubtleTextColor(context),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
