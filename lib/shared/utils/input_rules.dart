import 'package:flutter/services.dart';

/// Reglas de entrada compartidas (ver CLAUDE.md, "Entrada de datos").
///
/// Los filtros se aplican igual al escribir y al pegar.

/// Recorta los extremos y junta los espacios repetidos.
String cleanText(String value) =>
    value.replaceAll(RegExp(r'\s+'), ' ').trim();

/// Motivos y notas de una línea: sin símbolos de código ni saltos de línea.
String cleanReason(String value) =>
    cleanText(value.replaceAll(RegExp(r'[<>{}\[\]\\;`$]'), ''));

/// Texto libre corto (motivos, notas): descarta `< > { } [ ] \ ; $ \``
/// y los saltos de línea, sin espacio al inicio ni espacios seguidos.
List<TextInputFormatter> reasonInputFormatters({int maxLength = 200}) => [
      FilteringTextInputFormatter.deny(RegExp(r'[<>{}\[\]\\;`$\r\n]')),
      _SingleSpaceFormatter(),
      LengthLimitingTextInputFormatter(maxLength),
    ];

/// Nombres cortos (negocio, marca, búsqueda): letras con tildes, números,
/// espacio y `. , - ' & /`. Sin espacio al inicio ni espacios seguidos.
List<TextInputFormatter> nameInputFormatters({int maxLength = 40}) => [
      FilteringTextInputFormatter.allow(
        RegExp(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,\-'&/]"),
      ),
      _SingleSpaceFormatter(),
      LengthLimitingTextInputFormatter(maxLength),
    ];

/// Quita el espacio inicial y colapsa los espacios consecutivos. El
/// recorte del final se hace al usar el valor (`cleanText`), para que la
/// persona pueda escribir el espacio entre dos palabras.
class _SingleSpaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r' {2,}'), ' ');
    final cleaned = text.startsWith(' ') ? text.substring(1) : text;
    if (cleaned == newValue.text) return newValue;
    final offset = cleaned.length;
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
