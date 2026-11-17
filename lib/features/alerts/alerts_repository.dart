import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saviewgo/features/alerts/admin_notification.dart';

class AlertsPage {
  const AlertsPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<AdminNotification> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

/// Ficha: AlertsRepository
/// - Colección: adminNotifications/{id}
/// - Documentos hoy: pocos · en 12 meses: miles (uno por transferencia)
/// - Tamaño: pequeño · cambios por día: decenas · solo escribe la función
///   de pedidos; el cliente únicamente agrega su uid a `readBy`.
/// - Quién lee: superadmin_global (todo) y superadmin_city (su `cityId`;
///   las reglas lo exigen, la consulta lo filtra en el servidor)
/// - Pantallas: Alertas y el contador del bottom nav
/// - Tiempo real: no; se lee al abrir la app y al jalar hacia abajo
/// - Filtros y orden: cityId (opcional) y createdAt desc, índice
///   `cityId + createdAt` ya declarado
/// - Patrón: P2 Lista paginada (`limit` + `startAfterDocument`)
class AlertsRepository {
  const AlertsRepository();

  static const pageSize = 20;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('adminNotifications');

  Future<AlertsPage> fetchPage({
    required String? cityId,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> query = _col;
    if (cityId != null) query = query.where('cityId', isEqualTo: cityId);
    query = query.orderBy('createdAt', descending: true);
    if (after != null) query = query.startAfterDocument(after);

    final snapshot = await query.limit(pageSize).get();
    return AlertsPage(
      items: snapshot.docs.map(AdminNotification.fromDoc).toList(),
      cursor: snapshot.docs.isEmpty ? after : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  /// Agrega [uid] a `readBy` de cada aviso, en un solo lote. Las reglas
  /// exigen que sea exactamente un uid más y que no esté ya.
  Future<void> markRead(Iterable<String> ids, String uid) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {
        'readBy': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
  }
}
