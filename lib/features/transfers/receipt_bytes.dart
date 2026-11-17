import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Descarga un comprobante solo en memoria.
///
/// `Image.network` guarda lo que baja en la caché de disco del teléfono, y
/// un comprobante trae datos bancarios y personales. Aquí los bytes viven
/// mientras la pantalla los usa y se descartan con el provider (autoDispose).
/// No pasa por Firebase: la URL de Storage ya trae su token.
final receiptBytesProvider =
    FutureProvider.autoDispose.family<Uint8List, String>((ref, url) async {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https') {
    throw const FormatException('Comprobante con enlace no válido.');
  }

  const maxBytes = 10 * 1024 * 1024;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  ref.onDispose(() => client.close(force: true));

  final request = await client.getUrl(uri).timeout(const Duration(seconds: 20));
  final response = await request.close().timeout(const Duration(seconds: 20));
  if (response.statusCode != 200) {
    throw HttpException('Respuesta ${response.statusCode}');
  }

  final builder = BytesBuilder(copy: false);
  await for (final chunk in response.timeout(const Duration(seconds: 30))) {
    builder.add(chunk);
    if (builder.length > maxBytes) {
      throw const HttpException('El comprobante es demasiado grande.');
    }
  }
  return builder.takeBytes();
});
