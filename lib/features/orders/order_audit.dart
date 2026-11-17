import 'package:cloud_firestore/cloud_firestore.dart';

/// Módulos con pedidos de envío.
enum OrderModuleKind {
  ecommerce('ecommerce-orders', 'Ecommerce'),
  food('food-orders', 'Gastronomía');

  const OrderModuleKind(this.collection, this.label);

  final String collection;
  final String label;
}

/// Vocabulario único de estados (contrato_pedidos.md §2).
const orderStatusLabels = <String, String>{
  'pending': 'Pendiente',
  'payment_pending': 'Pago pendiente',
  'payment_received': 'Pago por validar',
  'payment_succeeded': 'Pago validado',
  'payment_rejected': 'Pago rechazado',
  'confirmed': 'Confirmado',
  'processing': 'Preparando',
  'ready_for_courier': 'Listo para entregador',
  'ready_for_pickup': 'Listo para retiro',
  'assigned': 'Entregador asignado',
  'on_the_way': 'En camino',
  'delivered': 'Entregado',
  'completed': 'Completado',
  'cancelled': 'Cancelado',
  'failed': 'No se pudo entregar',
  'rejected': 'Rechazado por el cliente',
  'returned': 'Devuelto al negocio',
};

const paymentMethodLabels = <String, String>{
  'cash': 'Efectivo',
  'transfer': 'Transferencia',
  'card': 'Tarjeta',
};

const deliveryTypeLabels = <String, String>{
  'pickup': 'Retiro en tienda',
  'delivery': 'Delivery inmediato',
  'scheduled': 'Entrega programada',
};

const deliveryIssueLabels = <String, String>{
  'client_absent': 'El cliente no está',
  'client_unreachable': 'El cliente no contesta',
  'wrong_address': 'Dirección incorrecta',
  'client_refused': 'El cliente no quiso recibirlo',
  'damaged': 'Pedido dañado',
  'payment_issue': 'Problema con el cobro',
  'other': 'Otro motivo',
};

const vehicleLabels = <String, String>{
  'bicycle': 'Bicicleta',
  'scooter': 'Scooter',
  'motorcycle': 'Motocicleta',
  'car': 'Auto',
  'suv': 'Camioneta',
  'van': 'Furgón',
  'truck': 'Camión',
};

String statusLabel(String status) => orderStatusLabels[status] ?? status;

enum StatusTone { good, bad, warn, neutral }

StatusTone statusTone(String status) => switch (status) {
      'completed' || 'delivered' || 'payment_succeeded' => StatusTone.good,
      'cancelled' ||
      'payment_rejected' ||
      'failed' ||
      'rejected' ||
      'returned' =>
        StatusTone.bad,
      'pending' || 'payment_received' || 'payment_pending' => StatusTone.warn,
      _ => StatusTone.neutral,
    };

class OrderHistoryEntry {
  const OrderHistoryEntry({required this.status, this.at, this.note});

  final String status;
  final DateTime? at;
  final String? note;
}

/// Pedido para auditoría, solo lectura. A propósito NO trae teléfonos ni
/// la dirección de entrega: la app no los necesita y quedarían en el
/// teléfono.
class AuditOrder {
  const AuditOrder({
    required this.id,
    required this.module,
    required this.orderNumber,
    required this.businessName,
    required this.branchName,
    required this.cityId,
    required this.clientName,
    required this.status,
    required this.paymentMethod,
    required this.deliveryType,
    required this.subtotal,
    required this.deliveryCost,
    required this.serviceFee,
    required this.total,
    required this.history,
    this.totalWeightKg,
    this.requiredVehicle,
    this.distanceKm,
    this.courierName,
    this.courierVehicle,
    this.cashCollected,
    this.refundAmount,
    this.paymentRejection,
    this.cancellation,
    this.issueReason,
    this.issueNote,
    this.createdAt,
  });

  factory AuditOrder.fromDoc(
    OrderModuleKind module,
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final r = doc.data() ?? const {};
    String str(Object? v) => v is String ? v : '';
    double? num_(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
    String? nz(String v) => v.isEmpty ? null : v;
    Map map(Object? v) => v is Map ? v : const {};

    final issue = map(r['deliveryIssue']);
    final history = r['statusHistory'];

    return AuditOrder(
      id: doc.id,
      module: module,
      orderNumber: str(r['orderNumber']).isEmpty ? doc.id : str(r['orderNumber']),
      businessName: str(r['businessName']),
      branchName: str(map(r['branch'])['name']),
      cityId: str(r['cityId']),
      clientName: str(r['clientName']),
      status: str(r['status']),
      paymentMethod: str(r['paymentMethod']),
      deliveryType: str(r['deliveryType']),
      subtotal: num_(r['subtotal']) ?? 0,
      deliveryCost: num_(r['deliveryCost']) ?? 0,
      serviceFee: num_(r['serviceFee']) ?? 0,
      total: num_(r['total']) ?? 0,
      totalWeightKg: num_(r['totalWeightKg']),
      requiredVehicle: nz(str(r['requiredVehicle'])),
      distanceKm: num_(r['distanceKm']),
      courierName: nz(str(map(r['courier'])['name'])),
      courierVehicle: nz(str(map(r['courier'])['vehicle'])),
      cashCollected: num_(map(r['cashCollected'])['amount']),
      refundAmount: num_(map(r['refund'])['amount']),
      paymentRejection: nz(str(map(r['paymentRejection'])['reason'])),
      cancellation: nz(str(map(r['cancellation'])['reason'])),
      issueReason: issue.isEmpty
          ? null
          : (deliveryIssueLabels[str(issue['kind'])] ?? nz(str(issue['reason']))),
      issueNote: nz(str(issue['note'])),
      createdAt: (r['createdAt'] as Timestamp?)?.toDate(),
      history: history is List
          ? [
              for (final h in history.whereType<Map>())
                OrderHistoryEntry(
                  status: str(h['status']),
                  at: (h['timestamp'] as Timestamp?)?.toDate(),
                  note: nz(str(h['note'])),
                ),
            ]
          : const [],
    );
  }

  final String id;
  final OrderModuleKind module;
  final String orderNumber;
  final String businessName;
  final String branchName;
  final String cityId;
  final String clientName;
  final String status;
  final String paymentMethod;
  final String deliveryType;
  final double subtotal;
  final double deliveryCost;
  final double serviceFee;
  final double total;
  final List<OrderHistoryEntry> history;
  final double? totalWeightKg;
  final String? requiredVehicle;
  final double? distanceKm;
  final String? courierName;
  final String? courierVehicle;
  final double? cashCollected;
  final double? refundAmount;
  final String? paymentRejection;
  final String? cancellation;
  final String? issueReason;
  final String? issueNote;
  final DateTime? createdAt;

  /// Pedido que pide revisión antes de decidir qué se devuelve.
  bool get needsAudit =>
      (status == 'failed' || status == 'rejected' || status == 'returned') &&
      refundAmount == null;

  @override
  bool operator ==(Object other) =>
      other is AuditOrder && other.module == module && other.id == id;

  @override
  int get hashCode => Object.hash(module, id);
}
