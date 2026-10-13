import 'package:flutter/material.dart';

class StyleService {
  // Método para aplicar fontWeightDelta a cualquier TextStyle
  static TextStyle? applyFontWeightDelta(
      TextStyle? textStyle, {
      int delta = 1,
      FontWeight? defaultWeight = FontWeight.w300,
    }) {
    return textStyle?.copyWith(fontWeight: defaultWeight).apply(fontWeightDelta: delta);
  }
}
