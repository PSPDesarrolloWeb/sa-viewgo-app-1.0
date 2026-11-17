import 'package:cloud_firestore/cloud_firestore.dart';

/// Documento `adminNotifications/{id}` (contrato_pedidos.md §19). Lo escribe
/// la Cloud Function de pedidos; el cliente solo agrega su uid a `readBy`.
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.module,
    required this.orderId,
    required this.status,
    required this.cityId,
    required this.readBy,
    required this.createdAt,
  });

  factory AdminNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    return AdminNotification(
      id: doc.id,
      title: data['title'] as String? ?? 'Aviso',
      body: data['body'] as String? ?? '',
      module: data['module'] as String? ?? '',
      orderId: data['orderId'] as String? ?? '',
      status: data['status'] as String? ?? '',
      cityId: data['cityId'] as String? ?? '',
      readBy: data['readBy'] is List
          ? (data['readBy'] as List).whereType<String>().toList()
          : const [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String id;
  final String title;
  final String body;

  /// 'ecommerce' o 'food'.
  final String module;
  final String orderId;
  final String status;
  final String cityId;
  final List<String> readBy;
  final DateTime createdAt;

  bool isReadBy(String uid) => readBy.contains(uid);

  AdminNotification markedReadBy(String uid) => isReadBy(uid)
      ? this
      : AdminNotification(
          id: id,
          title: title,
          body: body,
          module: module,
          orderId: orderId,
          status: status,
          cityId: cityId,
          readBy: [...readBy, uid],
          createdAt: createdAt,
        );

  String get moduleLabel => switch (module) {
        'food' => 'Gastronomía',
        'ecommerce' => 'Ecommerce',
        _ => 'Pedido',
      };
}
