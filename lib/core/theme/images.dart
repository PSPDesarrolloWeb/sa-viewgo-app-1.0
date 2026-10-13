import 'package:flutter/material.dart';

/// Centraliza todas las variantes de imágenes de marca (ViewGo) usadas
/// en la app, para no repetir rutas de assets por todo el código.
///
/// IMPORTANTE: ajusta [_basePath] a la ruta real declarada en tu
/// `pubspec.yaml` (por ejemplo: assets/images/brand/).
class AppImages {
  AppImages._();

  static const String loadingAnimation = 'assets/lottie/ViewGoIconAnim.json';

  static const String _basePath = 'assets/brand';

  // ---------------------------------------------------------------------
  // LOGOTIPO COMPLETO (marca + texto)
  // ---------------------------------------------------------------------
  static const String fullLight = '$_basePath/viewgo_full_fc_light.png';
  static const String fullDark = '$_basePath/viewgo_full_fc_dark.png';

  /// Logotipo completo adaptado automáticamente al tema actual.
  static String full(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? fullLight
        : fullDark;
  }

  /// Logotipo horizontal iso + wordmark
  static const String horizontal = '$_basePath/viewgo_hz_fc.png';

  // ---------------------------------------------------------------------
  // LOGOTIPO HORIZONTAL
  // ---------------------------------------------------------------------
  static const String horizontalLight = '$_basePath/viewgo_hzf_fc_light.png';
  static const String horizontalDark = '$_basePath/viewgo_hzf_fc_dark.png';

  static String horizontalFull(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? horizontalLight
        : horizontalDark;
  }

  // ---------------------------------------------------------------------
  // LOCKUP (lkp) — variante compacta del logo
  // ---------------------------------------------------------------------
  static const String lockupLight = '$_basePath/viewgo_lkp_fc_light.png';
  static const String lockupDark = '$_basePath/viewgo_lkp_fc_dark.png';

  static String lockup(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? lockupLight
        : lockupDark;
  }

  // ---------------------------------------------------------------------
  // ISOTIPO (símbolo solo, sin texto)
  // ---------------------------------------------------------------------
  static const String isoFullColor = '$_basePath/viewgo_iso_fc.png';
  static const String isoBlack = '$_basePath/viewgo_iso_black.png';
  static const String isoWhite = '$_basePath/viewgo_iso_white.png';
  static const String isoGreen = '$_basePath/viewgo_iso_green.png';
  static const String isoOrange = '$_basePath/viewgo_iso_orange.png';

  /// Isotipo en blanco o negro, según el tema (útil sobre fondos sólidos).
  static String isoAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? isoBlack
        : isoWhite;
  }

  // ---------------------------------------------------------------------
  // MARCA DE AGUA / WATERMARK (wm) — por color y por categoría de servicio
  // ---------------------------------------------------------------------
  static const String wmFullColor = '$_basePath/viewgo_wm_fc.png';
  static const String wmBlack = '$_basePath/viewgo_wm_black.png';
  static const String wmWhite = '$_basePath/viewgo_wm_white.png';
  static const String wmGreen = '$_basePath/viewgo_wm_green.png';
  static const String wmOrange = '$_basePath/viewgo_wm_orange.png';

  static const String wmEcommerce = '$_basePath/viewgo_wm_ecommerce.png';
  static const String wmEvents = '$_basePath/viewgo_wm_events.png';
  static const String wmFood = '$_basePath/viewgo_wm_food.png';
  static const String wmParking = '$_basePath/viewgo_wm_parking.png';
  static const String wmServices = '$_basePath/viewgo_wm_services.png';

  /// Watermark en blanco o negro, según el tema.
  static String wmAdaptive(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light ? wmBlack : wmWhite;
  }

  /// Watermark según la categoría de servicio (módulo) que se muestra.
  static String wmByCategory(String category) {
    switch (category) {
      case 'ecommerce':
        return wmEcommerce;
      case 'events':
        return wmEvents;
      case 'food':
        return wmFood;
      case 'parking':
        return wmParking;
      case 'services':
        return wmServices;
      default:
        return wmFullColor;
    }
  }

  /// vt = variante vertical a color.
  static const String vtFc = '$_basePath/viewgo_vt_fc.png';

  // ---------------------------------------------------------------------
  // LOGISTICA
  // ---------------------------------------------------------------------
  static const String logisticWm = '$_basePath/viewgo_logistic_wm_fc.png';
  static const String logisticIconAppFc =
      '$_basePath/viewgo_logistic_icon_app_fc.png';

  //PSP INNOVATIONS
  static const _logoPSPLight =
      'assets/images/PSPInnovations/LogoPSPInColorDark.png';
  static const _logoPSPDark =
      'assets/images/PSPInnovations/LogoPSPInColorLight.png';
  static String logoPSP(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? _logoPSPLight
        : _logoPSPDark;
  }
}
