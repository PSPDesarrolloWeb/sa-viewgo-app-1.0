import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';

/// Atajos de tema que se repiten en varias pantallas.
extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Verde de marca con contraste suficiente para texto en cada tema.
  Color get accentText =>
      isDark ? AppColors.inversePrimary : AppColors.onPrimaryContainer;

  /// Fondo suave verde para chips, avatares y estados activos.
  Color get accentSoft =>
      AppColors.primary.withValues(alpha: isDark ? 0.16 : 0.2);
}