import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';

class ThemeConfig {
  // ---------------------------------------------------------------------
  // TIPOGRAFÍA
  // Fuente local declarada en pubspec.yaml con sus pesos reales
  // (PlusJakartaSans-Regular, -Medium, -SemiBold, -Bold, etc.)
  // ---------------------------------------------------------------------
  static const String fontFamily = 'PlusJakartaSans';

  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black
        : Colors.white;
  }

  static Color getInvertColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Colors.black;
  }

  static Color getSecondaryColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorW
        : AppColors.viewGoColorB;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorBGLight
        : AppColors.viewGoColorBGDark;
  }

  static Color getBackgroundColorGreen(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorBGLight2
        : AppColors.viewGoColorBGDark;
  }

  static Color getBackgroundColorVG(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorBGLight
        : AppColors.viewGoColorBGDark;
  }

  static Color getBackgroundColorVG2(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorBGLight2
        : AppColors.viewGoColorBGDark2;
  }

  static Color getBackgroundWithOpacity(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withOpacity(0.6)
        : Colors.black.withOpacity(0.6);
  }

  static Color getInvWithOpacity(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black.withOpacity(0.6)
        : Colors.white.withOpacity(0.6);
  }

  static Color getForegroundColorW(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorFGLight
        : AppColors.viewGoColorFGDark;
  }

  static Color getForegroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorFGLight
        : AppColors.viewGoColorFGDark;
  }

  static Color getForegroundColorVG(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorFGLight
        : AppColors.viewGoColorFGDark;
  }

  static Color getColor12(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black12
        : Colors.white12;
  }

  static Color getColor24(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black26
        : Colors.white24;
  }

  static Color getColor38(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black38
        : Colors.white38;
  }

  static Color getInvColor38(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white38
        : Colors.black38;
  }

  static Color getInvColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white
        : Colors.black;
  }

  static Color getColor45(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white38
        : Colors.black45;
  }

  static Color getColorText45(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black45
        : Colors.white38;
  }

  static Color getColor54(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black54
        : Colors.white54;
  }

  // Otros colores o estilos que puedas necesitar
  static Color getCustomColor(
      BuildContext context, Color lightColor, Color darkColor) {
    return Theme.of(context).brightness == Brightness.light
        ? lightColor
        : darkColor;
  }

  static Color getButtonColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorW.withOpacity(0.6)
        : AppColors.viewGoColorFGDark;
  }

  static Color getOpacityColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorW.withOpacity(0.4)
        : Colors.black.withOpacity(0.4);
  }

  static Color getFeedbackColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorFGLight
        : AppColors.viewGoColorFGDark;
  }

// BORDES
  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black.withOpacity(0.08)
        : Colors.white.withOpacity(0.08);
  }

  static Color getBorderColorStrong(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.black.withOpacity(0.15)
        : Colors.white.withOpacity(0.15);
  }

// Para el borde activo del SearchBar (usa viewGoColor1 que ya tienes)
  static Color getBorderColorActive(BuildContext context) {
    return AppColors.primary;
  }

// SUPERFICIE — para el fondo del SearchBar compacto en pantallas internas
  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppColors.viewGoColorBGLight
        : AppColors.viewGoColorFGDark2;
  }

// TEXTO — te falta un estilo para placeholders/hints consistente
  static TextStyle getTextHint13(BuildContext context) {
    return TextStyle(
      fontFamily: fontFamily,
      color: Theme.of(context).brightness == Brightness.light
          ? Colors.black38
          : Colors.white38,
      fontWeight: FontWeight.w400,
      fontSize: 13,
    );
  }

  // Fondo del círculo — blanco semitransparente en light, negro semitransparente en dark
  static Color getFavoriteButtonBg(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.white.withOpacity(0.85)
        : Colors.black.withOpacity(0.65);
  }

// Ícono sin like — gris oscuro en light, gris claro en dark
  static Color getFavoriteIconInactive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.grey.shade600
        : Colors.grey.shade300;
  }

  // Color de superficie para cards/chips (respeta el tema)
  static Color getCardSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.grey.shade100
        : Colors.grey.shade800;
  }

// Color de superficie seleccionada (con opacidad del color del módulo)
  static Color getSelectedSurfaceColor(
      BuildContext context, Color moduleColor) {
    return Theme.of(context).brightness == Brightness.light
        ? moduleColor.withOpacity(0.12)
        : moduleColor.withOpacity(0.22);
  }

// Color de borde para chips seleccionados
  static Color getChipBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.grey.shade300
        : Colors.grey.shade800;
  }

// Color de texto secundario adaptado al tema
  static Color getSubtleTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.grey.shade500
        : Colors.grey.shade400;
  }

  /////ESTILOS DE TEXTO — Plus Jakarta Sans
  //
  // Nota: se eliminó el hack .apply(fontWeightDelta: ...) que compensaba
  // el renderizado de Poppins, y los fallbacks inconsistentes de la
  // versión anterior. Cada estilo ahora es una construcción directa y
  // determinística con la familia/peso/tamaño reales.

  static TextStyle getTextLight18(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 18,
    );
  }

  static TextStyle getTextLightBold18(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 18,
    );
  }

  static TextStyle getTextLightBold16(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 16,
    );
  }

  static TextStyle getTextLight10(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 10,
    );
  }

  static TextStyle getTextLight12(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 12,
    );
  }

  static TextStyle getTextLight14(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    );
  }

  static TextStyle getTextLight16(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 16,
    );
  }

  static TextStyle getTextBold10(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 10,
    );
  }

  static TextStyle getTextBold12(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 12,
    );
  }

  static TextStyle getTextBold13(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 13,
    );
  }

  static TextStyle getTextBold14(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 14,
    );
  }

  static TextStyle getTextBold16(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    );
  }

  static TextStyle getTextBold18(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    );
  }

  static TextStyle getTextBold20(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w700,
      fontSize: 20,
    );
  }

  static TextStyle getTextLightW500(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      fontSize: 18,
    );
  }

  static TextStyle getTextLight48(BuildContext context) {
    return const TextStyle(
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      fontSize: 48,
    );
  }
}