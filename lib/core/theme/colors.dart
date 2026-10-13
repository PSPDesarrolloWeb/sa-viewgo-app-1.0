import 'package:flutter/material.dart';

/// Paleta de colores ViewGo, alineada 1:1 con el tailwind.config.js
/// usado en la app pública (web). Se mantiene la misma lógica de
/// nombres: primary, secondary, tertiary, quaternary, quinary, senary,
/// septenary, octonary — cada uno con sus variantes container, on-*,
/// fixed, fixedDim y dark-* (para dark mode).
///
/// Mapeo marca → rol:
///  primary     -> ViewGo Verde        (72CF59)
///  secondary   -> ViewGo Naranja      (F76B0C)
///  tertiary    -> ViewGo Teal         (28B3A3) — E-commerce & Retail
///  quaternary  -> ViewGo Ámbar        (DE9A00) — Gastronomía
///  quinary     -> ViewGo Magenta      (DB2777) — Servicios & Citas
///  senary      -> ViewGo Azul         (3F81C3) — Parking
///  septenary   -> ViewGo Violeta      (7459B5) — Eventos & Conciertos
///  octonary    -> ViewGo Gris Logistic(71716B) — Logística (alterno)
///
/// Nota (heredada del config web): en senary y septenary la saturación
/// de los tonos derivados (container/dark) se refuerza respecto al HEX
/// de marca, porque a igual luminancia el azul y el violeta se perciben
/// más oscuros que el resto — sin ese ajuste se ven casi negros en dark
/// mode.
class AppColors {
  // ────────────────────────────────────────────────────────────────
  // PRIMARY — Verde ViewGo (72CF59)
  // ────────────────────────────────────────────────────────────────
  static const Color surfaceTint = Color(0xFF72CF59);
  static const Color primary = Color(0xFF72CF59);
  static const Color primaryDark = Color(0xFF42962C); // hover en light mode
  static const Color primaryContainer = Color(0xFFA1E98D);
  static const Color primaryFixed = Color(0xFF78E05C);
  static const Color primaryFixedDim = Color(0xFF46C225);
  static const Color onPrimary = Color(0xFF1A1A1A);
  static const Color onPrimaryContainer = Color(0xFF256613);
  static const Color onPrimaryFixed = Color(0xFF1F4715);
  static const Color onPrimaryFixedVariant = Color(0xFF3D8A28);
  static const Color inversePrimary = Color(0xFF93DA80);
  static const Color darkPrimary = Color(0xFF55C038); // uso en dark mode
  static const Color darkPrimaryContainer = Color(0xFF255519);

  // ────────────────────────────────────────────────────────────────
  // SECONDARY — Naranja ViewGo (F76B0C)
  // ────────────────────────────────────────────────────────────────
  static const Color secondary = Color(0xFFF76B0C);
  static const Color secondaryContainer = Color(0xFFFCCEAF);
  static const Color secondaryFixed = Color(0xFFFBBB8F);
  static const Color secondaryFixedDim = Color(0xFFF98E46);
  static const Color onSecondary = Color(0xFF1A1A1A);
  static const Color onSecondaryContainer = Color(0xFF953F05);
  static const Color onSecondaryFixed = Color(0xFF592603);
  static const Color onSecondaryFixedVariant = Color(0xFFAD4906);
  static const Color darkSecondary = Color(0xFFF98E46);
  static const Color darkSecondaryContainer = Color(0xFF7E3504);

  // ────────────────────────────────────────────────────────────────
  // TERTIARY — Teal ViewGo, E-commerce & Retail (28B3A3)
  // ────────────────────────────────────────────────────────────────
  static const Color tertiary = Color(0xFF28B3A3);
  static const Color onTertiary = Color(0xFF1A1A1A);
  static const Color tertiaryContainer = Color(0xFF7BEADD);
  static const Color tertiaryFixed = Color(0xFF3ADFCC);
  static const Color tertiaryFixedDim = Color(0xFF1FBEAC);
  static const Color onTertiaryContainer = Color(0xFF10645A);
  static const Color onTertiaryFixed = Color(0xFF114B44);
  static const Color onTertiaryFixedVariant = Color(0xFF219285);
  static const Color darkTertiary = Color(0xFF2ABDAC);
  static const Color darkTertiaryContainer = Color(0xFF13544C);

  // ────────────────────────────────────────────────────────────────
  // QUATERNARY — Ámbar ViewGo, Gastronomía (DE9A00)
  // ────────────────────────────────────────────────────────────────
  static const Color quaternary = Color(0xFFDE9A00);
  static const Color quaternaryContainer = Color(0xFFFFD16A);
  static const Color quaternaryFixed = Color(0xFFFFBD29);
  static const Color quaternaryFixedDim = Color(0xFFE29C00);
  static const Color onQuaternary = Color(0xFF1A1A1A);
  static const Color onQuaternaryContainer = Color(0xFF775200);
  static const Color darkQuaternary = Color(0xFFE29C00);
  static const Color darkQuaternaryContainer = Color(0xFF644500);

  // ────────────────────────────────────────────────────────────────
  // QUINARY — Magenta ViewGo, Servicios & Citas (DB2777)
  // ────────────────────────────────────────────────────────────────
  static const Color quinary = Color(0xFFDB2777);
  static const Color quinaryContainer = Color(0xFFF9CBDF);
  static const Color quinaryFixed = Color(0xFFF6B7D3);
  static const Color quinaryFixedDim = Color(0xFFF089B7);
  static const Color onQuinary = Color(0xFFFFFFFF);
  static const Color onQuinaryContainer = Color(0xFFAC1558);
  static const Color darkQuinary = Color(0xFFEC8CB7);
  static const Color darkQuinaryContainer = Color(0xFF8F184D);

  // ────────────────────────────────────────────────────────────────
  // SENARY — Azul ViewGo, Parking (3F81C3)
  // ────────────────────────────────────────────────────────────────
  static const Color senary = Color(0xFF3F81C3);
  static const Color senaryContainer = Color(0xFFBEDAF7);
  static const Color senaryFixed = Color(0xFFA5CDF4);
  static const Color senaryFixedDim = Color(0xFF70AEED);
  static const Color onSenary = Color(0xFFFFFFFF);
  static const Color onSenaryContainer = Color(0xFF145AA0);
  static const Color darkSenary = Color(0xFF72AEEB);
  static const Color darkSenaryContainer = Color(0xFF134C85);

  // ────────────────────────────────────────────────────────────────
  // SEPTENARY — Violeta ViewGo, Eventos & Conciertos (7459B5)
  // ────────────────────────────────────────────────────────────────
  static const Color septenary = Color(0xFF7459B5);
  static const Color septenaryContainer = Color(0xFFDCD2F3);
  static const Color septenaryFixed = Color(0xFFCFC2EF);
  static const Color septenaryFixedDim = Color(0xFFB39FE5);
  static const Color onSeptenary = Color(0xFFFFFFFF);
  static const Color onSeptenaryContainer = Color(0xFF643ACB);
  static const Color darkSeptenary = Color(0xFFB3A0E1);
  static const Color darkSeptenaryContainer = Color(0xFF5434A4);

  // ────────────────────────────────────────────────────────────────
  // OCTONARY — Gris Logistic ViewGo, alterno / Logística (71716B)
  // ────────────────────────────────────────────────────────────────
  static const Color octonary = Color(0xFF71716B);
  static const Color octonaryContainer = Color(0xFFD7D7D5);
  static const Color octonaryFixed = Color(0xFFC9C9C6);
  static const Color octonaryFixedDim = Color(0xFFAAAAA5);
  static const Color onOctonary = Color(0xFFFFFFFF);
  static const Color onOctonaryContainer = Color(0xFF595955);
  static const Color darkOctonary = Color(0xFFAAAAA5);
  static const Color darkOctonaryContainer = Color(0xFF4B4B47);

    // ────────────────────────────────────────────────────────────────
  // ERROR — Rojo ViewGo, para estados de error / validación
  // ────────────────────────────────────────────────────────────────
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFBD5D5);
  static const Color errorFixed = Color(0xFFF8B4B4);
  static const Color errorFixedDim = Color(0xFFF87171);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF991B1B);
  static const Color darkError = Color(0xFFF87171);
  static const Color darkErrorContainer = Color(0xFF7F1D1D);

  // ────────────────────────────────────────────────────────────────
  // viewGoColor1..10 — REMOVIDOS (suprimidos a pedido, ya no se usan).
  // Equivalencias para quien busque en el historial de git:
  //   viewGoColor1  (80E05C) -> primary / primaryFixed
  //   viewGoColor2  (E25050) -> descontinuado, sin reemplazo
  //   viewGoColor3  (2196F3) -> senary
  //   viewGoColor4  (E96FFF) -> septenary
  //   viewGoColor5  (FFC107) -> quaternary
  //   viewGoColor6  (FF4081) -> quinary
  //   viewGoColor7  (00B8D4) -> tertiary
  //   viewGoColor8  (795548) -> descontinuado, sin reemplazo
  //   viewGoColor9  (FF6D00) -> secondary
  //   viewGoColor10 (00BFA5) -> tertiary
  // ────────────────────────────────────────────────────────────────
  static const Color viewGoColorB = Colors.black;
  static const Color viewGoColorW = Colors.white;
  static const Color viewGoColorBGLight = Color(0xFFF1F5F9);
  static const Color viewGoColorBGLight2 = Color(0xFFF2FDF0);
  static const Color viewGoColorFGLight = Color(0xFFFFFFFF);
  static const Color viewGoColorFGLight2 = Color(0xFFF1F5F9);
  static const Color viewGoColorBGDark = Color(0xFF09090B);
  static const Color viewGoColorBGDark2 = Color(0xFF18181A);
  static const Color viewGoColorFGDark = Color(0xFF151515);
  static const Color viewGoColorFGDark2 = Color.fromARGB(255, 48, 48, 48);
  static const Color viewGoColorDark1 = Color.fromARGB(255, 155, 216, 24);

  static const Color iconColorPrimary = Color(0xFF80E05C);
  static const Color iconColorSecondary1 = Color(0xFFE25050);
  static const Color iconColorSecondary2 = Color(0xFF64B5F6);
  static const Color textColor = Colors.white;
  static const Color backgroundColor = Color(0xFF111111);
  static const Color alternativeColor = Color(0xFFF72585);
  static const Color lightColor = Colors.white;
  static const Color hintColor = Colors.grey;
  static const Color feedbackIconLight = Color(0xFF1A1A2E);
  static const Color feedbackIconDark = Color(0xFFF0F0F0);
}

class AppSizes {
  static const double buttonWidth = 130.0;
  static const double buttonHeight = 120.0;
  static const double borderRadius = 100.0;
  static const double iconSize = 48.0;
  static const double textFieldHeight = 60.0;
  static const double borderRadiusInput = 32.0;
}

class AppTextStyles {
  static const TextStyle titleStyle = TextStyle(
    color: AppColors.primary,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle hintStyle = TextStyle(
    color: AppColors.hintColor,
  );
}

class AppTextStylesSecondary {
  static const TextStyle titleStyle = TextStyle(
    color: AppColors.alternativeColor,
    fontSize: 24.0,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle hintStyle = TextStyle(
    color: AppColors.hintColor,
  );
}