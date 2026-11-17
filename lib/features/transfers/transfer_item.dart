import 'package:cloud_firestore/cloud_firestore.dart';

/// Los cinco flujos de pago por transferencia que valida el superadmin.
enum TransferKind {
  ecommerce('ecommerce', 'Ecommerce'),
  food('food', 'Gastronomía'),
  bookings('bookings', 'Reservas'),
  parking('parking', 'Parking'),
  events('events', 'Eventos');

  const TransferKind(this.key, this.label);

  final String key;
  final String label;

  /// `modulo` de la ruta: 'ecommerce', 'food', 'bookings', 'parking' o 'events'.
  static TransferKind? fromKey(String? key) {
    for (final k in values) {
      if (k.key == key) return k;
    }
    return null;
  }
}

/// Las tres bandejas de cada flujo. El estado real de Firestore cambia
/// según el flujo (ver `TransferSource.statusValue`).
enum TransferBucket {
  toValidate('Por validar'),
  approved('Aprobadas'),
  rejected('Rechazadas');

  const TransferBucket(this.label);

  final String label;
}

/// Un pago por transferencia, con lo que se muestra y lo que hace falta
/// para resolverlo. La lista no necesita nada más.
class TransferItem {
  const TransferItem({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.cityId,
    required this.createdAt,
    required this.canResolve,
    required this.lines,
    required this.confirmText,
    this.receiptUrl,
    this.receiptIsPdf = false,
    this.rejectionReason,
    this.warning,
    this.extra = const {},
  });

  final TransferKind kind;
  final String id;

  /// Lo principal de la tarjeta: número de pedido, placa, evento…
  final String title;
  final String subtitle;
  final double amount;
  final String cityId;
  final DateTime? createdAt;

  /// Solo los que están por validar admiten acciones.
  final bool canResolve;

  /// Pares etiqueta/valor del detalle.
  final List<(String, String)> lines;

  /// Pregunta del diálogo de validar.
  final String confirmText;

  /// Comprobante guardado en el mismo documento. null = se lee aparte
  /// (pedidos) o no tiene (evento gratuito).
  final String? receiptUrl;
  final bool receiptIsPdf;
  final String? rejectionReason;

  /// Aviso que se destaca en el detalle (ej. plazo vencido).
  final String? warning;

  /// Datos propios del flujo que necesitan las acciones.
  final Map<String, Object?> extra;

  @override
  bool operator ==(Object other) =>
      other is TransferItem && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);
}

/// Comprobante listo para mostrar.
class TransferReceipt {
  const TransferReceipt({required this.url, required this.isPdf});

  final String url;
  final bool isPdf;
}

class TransferPage {
  const TransferPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<TransferItem> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

/// Error con un mensaje en español para mostrar tal cual.
class TransferException implements Exception {
  const TransferException(this.message);

  final String message;

  @override
  String toString() => message;
}
