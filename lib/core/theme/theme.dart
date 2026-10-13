import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';

class TextStyles {
  static const String fontFamily = 'PlusJakartaSans';

  static const TextStyle displayLarge = TextStyle(
      fontFamily: fontFamily, fontSize: 20.0, fontWeight: FontWeight.bold);
  static const TextStyle displayMedium = TextStyle(
      fontFamily: fontFamily, fontSize: 18.0, fontWeight: FontWeight.bold);
  static const TextStyle displaySmall = TextStyle(
      fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.bold);
  static const TextStyle headlineMedium = TextStyle(
      fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w600);
  static const TextStyle headlineSmall = TextStyle(
      fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.w300);
  static const TextStyle titleLarge = TextStyle(
      fontFamily: fontFamily, fontSize: 16.0, fontWeight: FontWeight.w500);
  static const TextStyle bodyLarge = TextStyle(
      fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.normal);
  static const TextStyle bodyMedium = TextStyle(
      fontFamily: fontFamily, fontSize: 13.0, fontWeight: FontWeight.normal);
  static const TextStyle bodySmall = TextStyle(
      fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w300);
  static const TextStyle labelLarge = TextStyle(
      fontFamily: fontFamily, fontSize: 12.0, fontWeight: FontWeight.w500);
  static const TextStyle labelSmall = TextStyle(
      fontFamily: fontFamily, fontSize: 14.0, fontWeight: FontWeight.bold);
}

class TAppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.light(
      primary: AppColors.viewGoColorB,
      secondary: AppColors.secondary,
    ),
    hintColor: AppColors.secondary,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.primary.withOpacity(0.6),
      selectionHandleColor: AppColors.secondary,
    ),
    fontFamily: TextStyles.fontFamily,
    textTheme: TextTheme(
      displayLarge: TextStyles.displayLarge,
      displayMedium: TextStyles.displayMedium,
      displaySmall: TextStyles.displaySmall,
      headlineMedium: TextStyles.headlineMedium,
      headlineSmall: TextStyles.headlineSmall,
      titleLarge: TextStyles.titleLarge,
      bodyLarge: TextStyles.bodyLarge,
      bodyMedium: TextStyles.bodyMedium,
      bodySmall: TextStyles.bodySmall,
      labelLarge: TextStyles.labelLarge,
      labelSmall: TextStyles.labelSmall,
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    colorScheme: ColorScheme.dark(
      primary: AppColors.viewGoColorW,
      secondary: AppColors.secondary,
    ),
    hintColor: AppColors.secondary,
    textSelectionTheme: TextSelectionThemeData(
      selectionColor: AppColors.primary.withOpacity(0.6),
      selectionHandleColor: AppColors.secondary,
    ),
    fontFamily: TextStyles.fontFamily,
    textTheme: TextTheme(
      displayLarge: TextStyles.displayLarge,
      displayMedium: TextStyles.displayMedium,
      displaySmall: TextStyles.displaySmall,
      headlineMedium: TextStyles.headlineMedium,
      headlineSmall: TextStyles.headlineSmall,
      titleLarge: TextStyles.titleLarge,
      bodyLarge: TextStyles.bodyLarge,
      bodyMedium: TextStyles.bodyMedium,
      bodySmall: TextStyles.bodySmall,
      labelLarge: TextStyles.labelLarge,
      labelSmall: TextStyles.labelSmall,
    ),
  );
}
