import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saviewgo/features/transfers/transfer_item.dart';
import 'package:saviewgo/shared/utils/input_rules.dart';

/// Una fuente de transferencias: dónde se leen, cómo se validan y cómo se
/// rechazan. Cada flujo (pedidos, reservas, parking, eventos) tiene la suya.
///
/// Ficha común (los cinco flujos):
/// - Quién lee y escribe: superadmin_global y superadmin_city (solo su
///   `cityId`: la consulta lo filtra en el servidor y las reglas lo exigen)
/// - Pantalla: Transferencias (desde el Resumen y las Alertas)
/// - Tiempo real: no; se lee al entrar y al jalar hacia abajo
/// - Patrón: P2 Lista paginada (20 por página, `startAfterDocument`) y un
///   `get()` por comprobante abierto (P4). Los nombres que faltan (negocio,
///   evento) se leen en bloques de 30 con `whereIn`, sin N+1.
/// - Índices: los mismos que ya usa el panel web para cada bandeja.
abstract class TransferSource {
  const TransferSource();

  static const pageSize = 20;

  TransferKind get kind;

  /// Largo máximo y mínimo del motivo de rechazo.
  int get maxReason => 200;
  int get minReason => 1;

  /// Estado de Firestore que corresponde a cada bandeja.
  String statusValue(TransferBucket bucket);

  Future<TransferPage> fetchPage({
    required String? cityId,
    required TransferBucket bucket,
    DocumentSnapshot<Map<String, dynamic>>? after,
  });

  /// Comprobante del pago. Por defecto, el que viene en el mismo documento.
  Future<TransferReceipt?> fetchReceipt(TransferItem item) async {
    final url = item.receiptUrl;
    return url == null ? null : TransferReceipt(url: url, isPdf: item.receiptIsPdf);
  }

  Future<void> confirm(TransferItem item);
  Future<void> reject(TransferItem item, String reason);

  // ── Ayudas comunes ───────────────────────────────────────────────────

  FirebaseFirestore get db => FirebaseFirestore.instance;

  String get uid {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw StateError('sin-sesion');
    return uid;
  }

  Future<TransferPage> paged({
    required Query<Map<String, dynamic>> query,
    required DocumentSnapshot<Map<String, dynamic>>? after,
    required Future<List<TransferItem>> Function(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    ) build,
  }) async {
    var q = query;
    if (after != null) q = q.startAfterDocument(after);
    final snapshot = await q.limit(pageSize).get();
    return TransferPage(
      items: await build(snapshot.docs),
      cursor: snapshot.docs.isEmpty ? after : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  /// Un campo de texto por documento, leído en bloques de 30 ids.
  Future<Map<String, Map<String, dynamic>>> docsByIds(
    String collection,
    Iterable<String> ids,
  ) async {
    final unique = ids.where((id) => id.isNotEmpty).toSet().toList();
    final found = <String, Map<String, dynamic>>{};
    for (var i = 0; i < unique.length; i += 30) {
      final chunk = unique.sublist(i, i + 30 > unique.length ? unique.length : i + 30);
      // Los nombres solo adornan la lista: si las reglas rechazan la
      // consulta (ej. un evento no publicado visto por un superadmin de
      // ciudad), la lista se muestra igual con un nombre genérico.
      try {
        final snap = await db
            .collection(collection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        for (final d in snap.docs) {
          found[d.id] = d.data();
        }
      } on FirebaseException {
        continue;
      }
    }
    return found;
  }

  String cleanedReason(String reason) {
    final clean = cleanReason(reason);
    if (clean.length < minReason || clean.length > maxReason) {
      throw const TransferException('El motivo no es válido.');
    }
    return clean;
  }
}

String _str(Object? v) => v is String ? v : '';
double _money(Object? v) => v is num ? v.toDouble() : 0;
DateTime? _date(Object? v) => v is Timestamp ? v.toDate() : null;
String _usd(double v) => '\$${v.toStringAsFixed(2)}';

String _dateTime(DateTime? d) {
  if (d == null) return '';
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
}

bool _isPdf(Map? receipt) {
  final path = _str(receipt?['path']).toLowerCase();
  final url = _str(receipt?['url']).toLowerCase().split('?').first;
  return path.endsWith('.pdf') || url.endsWith('.pdf');
}

// ── Pedidos de ecommerce y food (contrato_pedidos.md §8) ───────────────

class OrderTransferSource extends TransferSource {
  const OrderTransferSource(this.kind);

  @override
  final TransferKind kind;

  String get _collection => kind == TransferKind.food ? 'food-orders' : 'ecommerce-orders';

  @override
  String statusValue(TransferBucket b) => switch (b) {
        TransferBucket.toValidate => 'payment_received',
        TransferBucket.approved => 'payment_succeeded',
        TransferBucket.rejected => 'payment_rejected',
      };

  DocumentReference<Map<String, dynamic>> _ref(String id) =>
      db.collection(_collection).doc(id);

  @override
  Future<TransferPage> fetchPage({
    required String? cityId,
    required TransferBucket bucket,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) {
    Query<Map<String, dynamic>> q = db.collection(_collection);
    if (cityId != null) q = q.where('cityId', isEqualTo: cityId);
    q = q
        .where('paymentMethod', isEqualTo: 'transfer')
        .where('status', isEqualTo: statusValue(bucket))
        .orderBy('createdAt', descending: true);

    return paged(
      query: q,
      after: after,
      build: (docs) async => [
        for (final d in docs) _item(d.id, d.data(), bucket == TransferBucket.toValidate),
      ],
    );
  }

  TransferItem _item(String id, Map<String, dynamic> data, bool pending) {
    final number = _str(data['orderNumber']).isEmpty ? id : _str(data['orderNumber']);
    final total = _money(data['total']);
    final appeals = (data['paymentAppeals'] as num?)?.toInt() ?? 0;
    final delivery = switch (_str(data['deliveryType'])) {
      'pickup' => 'Retiro en tienda',
      'delivery' => 'Delivery inmediato',
      'scheduled' => 'Entrega programada',
      _ => '—',
    };
    final rejection = data['paymentRejection'];

    return TransferItem(
      kind: kind,
      id: id,
      title: number,
      subtitle: [_str(data['businessName']), _str(data['clientName'])]
          .where((s) => s.isNotEmpty)
          .join(' · '),
      amount: total,
      cityId: _str(data['cityId']),
      createdAt: _date(data['createdAt']),
      canResolve: _str(data['status']) == 'payment_received',
      confirmText:
          '¿Verificaste en el banco la transferencia de ${_usd(total)} ($number)?',
      rejectionReason: rejection is Map ? _str(rejection['reason']) : null,
      lines: [
        ('Productos', _usd(_money(data['subtotal']))),
        if (_money(data['deliveryCost']) > 0) ('Envío', _usd(_money(data['deliveryCost']))),
        if (_money(data['serviceFee']) > 0) ('Servicio', _usd(_money(data['serviceFee']))),
        ('Entrega', delivery),
        if (_str(data['clientName']).isNotEmpty) ('Cliente', _str(data['clientName'])),
        if (_str(data['clientPhone']).isNotEmpty) ('Teléfono', _str(data['clientPhone'])),
        if (appeals > 0) ('Apelaciones', '$appeals de 2'),
      ],
    );
  }

  /// El comprobante de un pedido es privado: `private/payment`, 1 lectura.
  @override
  Future<TransferReceipt?> fetchReceipt(TransferItem item) async {
    final doc = await _ref(item.id).collection('private').doc('payment').get();
    final receipt = doc.data()?['receipt'];
    if (receipt is! Map || receipt['url'] is! String) return null;
    return TransferReceipt(url: receipt['url'] as String, isPdf: _isPdf(receipt));
  }

  @override
  Future<void> confirm(TransferItem item) {
    return _ref(item.id).update({
      'status': 'payment_succeeded',
      'confirmedBy': uid,
      'confirmedAt': FieldValue.serverTimestamp(),
      'statusHistory': FieldValue.arrayUnion([
        {'status': 'payment_succeeded', 'timestamp': Timestamp.now()},
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reject(TransferItem item, String reason) {
    final clean = cleanedReason(reason);
    return _ref(item.id).update({
      'status': 'payment_rejected',
      'paymentRejection': {
        'reason': clean,
        'at': FieldValue.serverTimestamp(),
        'by': uid,
      },
      'statusHistory': FieldValue.arrayUnion([
        {'status': 'payment_rejected', 'timestamp': Timestamp.now(), 'note': clean},
      ]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ── Reservas de servicios (contrato_reservas.md §5) ────────────────────

class BookingTransferSource extends TransferSource {
  const BookingTransferSource();

  @override
  TransferKind get kind => TransferKind.bookings;

  @override
  String statusValue(TransferBucket b) => switch (b) {
        TransferBucket.toValidate => 'pending',
        TransferBucket.approved => 'confirmed',
        TransferBucket.rejected => 'cancelled',
      };

  @override
  Future<TransferPage> fetchPage({
    required String? cityId,
    required TransferBucket bucket,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) {
    Query<Map<String, dynamic>> q = db.collection('activitiesBookings');
    if (cityId != null) q = q.where('cityId', isEqualTo: cityId);
    q = q
        .where('paymentMethod', isEqualTo: 'transfer')
        .where('status', isEqualTo: statusValue(bucket))
        .orderBy('createdAt', descending: true);

    return paged(
      query: q,
      after: after,
      build: (docs) async => [for (final d in docs) _item(d.id, d.data())],
    );
  }

  TransferItem _item(String id, Map<String, dynamic> data) {
    final slot = data['slot'] is Map ? data['slot'] as Map : const {};
    final amount = _money(data['paidAmount'] ?? data['amount']);
    final number = _str(data['orderNumber']).isEmpty ? id : _str(data['orderNumber']);
    final pending = _str(data['status']) == 'pending';
    final hold = _date(data['holdExpiresAt']);
    final expired = pending && hold != null && hold.isBefore(DateTime.now());
    final receipt = data['receipt'] is Map ? data['receipt'] as Map : null;
    final reason = data['rejectionReason'] is String
        ? _str(data['rejectionReason'])
        : (data['cancellation'] is Map ? _str((data['cancellation'] as Map)['reason']) : '');
    final resource = data['resourceId'] is String ? data['resourceId'] as String : null;

    return TransferItem(
      kind: kind,
      id: id,
      title: number,
      subtitle: [_str(data['businessName']), _str(data['activityName'])]
          .where((s) => s.isNotEmpty)
          .join(' · '),
      amount: amount,
      cityId: _str(data['cityId']),
      createdAt: _date(data['createdAt']),
      canResolve: pending,
      confirmText:
          '¿Verificaste en el banco la transferencia de ${_usd(amount)} ($number)?',
      receiptUrl: receipt == null ? null : _str(receipt['url']),
      receiptIsPdf: _isPdf(receipt),
      rejectionReason: reason.isEmpty ? null : reason,
      warning: expired
          ? 'El plazo de pago venció. Si otra persona tomó el horario, rechaza esta reserva.'
          : null,
      lines: [
        if (_str(data['activityName']).isNotEmpty) ('Actividad', _str(data['activityName'])),
        if (_str(slot['date']).isNotEmpty)
          ('Horario', '${_str(slot['date'])} ${_str(slot['startTime'])}–${_str(slot['endTime'])}'),
        if (_str(data['clientName']).isNotEmpty) ('Cliente', _str(data['clientName'])),
        if (_str(data['clientPhone']).isNotEmpty) ('Teléfono', _str(data['clientPhone'])),
        if (hold != null && pending) ('Plazo hasta', _dateTime(hold)),
      ],
      extra: {
        // Mismo id determinístico que usa la app de clientes.
        'lockId': '${_str(data['businessId'])}_${_str(data['activityId'])}_'
            '${resource ?? 'any'}_${_str(slot['date'])}_${_str(slot['startTime'])}',
      },
    );
  }

  /// Confirma en una transacción: la reserva pasa a `confirmed` y el
  /// candado del horario a definitivo (sin `expiresAt`).
  @override
  Future<void> confirm(TransferItem item) {
    final booking = db.collection('activitiesBookings').doc(item.id);
    final lock = db.collection('activitiesAvailability').doc(item.extra['lockId'] as String);
    final by = uid;

    return db.runTransaction((tx) async {
      final snap = await tx.get(booking);
      final lockSnap = await tx.get(lock);
      final data = snap.data();
      if (data == null || data['status'] != 'pending') {
        throw const TransferException('La reserva cambió de estado. Actualiza la lista.');
      }
      if (!lockSnap.exists || lockSnap.data()?['bookingId'] != item.id) {
        throw const TransferException(
          'Otra reserva ya tomó este horario porque el plazo venció. Rechaza esta reserva.',
        );
      }
      tx.update(booking, {
        'status': 'confirmed',
        'paymentStatus': 'paid',
        'confirmedBy': by,
        'confirmedAt': FieldValue.serverTimestamp(),
        'statusHistory': [
          ...((data['statusHistory'] as List?) ?? const []),
          {'status': 'confirmed', 'timestamp': Timestamp.now()},
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.update(lock, {'expiresAt': FieldValue.delete()});
    });
  }

  @override
  Future<void> reject(TransferItem item, String reason) {
    final clean = cleanedReason(reason);
    final booking = db.collection('activitiesBookings').doc(item.id);
    final lock = db.collection('activitiesAvailability').doc(item.extra['lockId'] as String);
    final by = uid;

    return db.runTransaction((tx) async {
      final snap = await tx.get(booking);
      final lockSnap = await tx.get(lock);
      final data = snap.data();
      if (data == null || data['status'] != 'pending') {
        throw const TransferException('La reserva cambió de estado. Actualiza la lista.');
      }
      tx.update(booking, {
        'status': 'cancelled',
        'rejectionReason': clean,
        'cancellation': {
          'cancelledBy': 'system',
          'reason': clean,
          'cancelledAt': Timestamp.now(),
        },
        'confirmedBy': by,
        'confirmedAt': FieldValue.serverTimestamp(),
        'statusHistory': [
          ...((data['statusHistory'] as List?) ?? const []),
          {'status': 'cancelled', 'timestamp': Timestamp.now()},
        ],
        'updatedAt': FieldValue.serverTimestamp(),
      });
      // Se libera el horario solo si sigue siendo de esta reserva.
      if (lockSnap.exists && lockSnap.data()?['bookingId'] == item.id) {
        tx.delete(lock);
      }
    });
  }
}

// ── Reservas de parking (contrato_qr.md, «Reservas de parking») ────────

class ParkingTransferSource extends TransferSource {
  const ParkingTransferSource();

  @override
  TransferKind get kind => TransferKind.parking;

  @override
  String statusValue(TransferBucket b) => switch (b) {
        TransferBucket.toValidate => 'pending_payment',
        TransferBucket.approved => 'paid',
        TransferBucket.rejected => 'rejected',
      };

  @override
  Future<TransferPage> fetchPage({
    required String? cityId,
    required TransferBucket bucket,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) {
    Query<Map<String, dynamic>> q = db.collection('parking_reservations');
    if (cityId != null) q = q.where('cityId', isEqualTo: cityId);
    q = q
        .where('status', isEqualTo: statusValue(bucket))
        .orderBy('createdAt', descending: true);

    return paged(
      query: q,
      after: after,
      build: (docs) async {
        final names = await docsByIds(
          'business',
          docs.map((d) => _str(d.data()['businessId'])),
        );
        return [
          for (final d in docs)
            _item(d.id, d.data(), _str(names[_str(d.data()['businessId'])]?['name'])),
        ];
      },
    );
  }

  TransferItem _item(String id, Map<String, dynamic> data, String business) {
    final plate = _str(data['plateId']);
    final amount = _money(data['amount']);
    final receipt = data['receipt'] is Map ? data['receipt'] as Map : null;
    final reason = _str(data['rejectionReason']);

    return TransferItem(
      kind: kind,
      id: id,
      title: 'Placa $plate',
      subtitle: business,
      amount: amount,
      cityId: _str(data['cityId']),
      createdAt: _date(data['createdAt']),
      canResolve: _str(data['status']) == 'pending_payment',
      confirmText:
          '¿Verificaste en el banco la transferencia de ${_usd(amount)} (placa $plate)?',
      receiptUrl: receipt == null ? null : _str(receipt['url']),
      receiptIsPdf: _isPdf(receipt),
      rejectionReason: reason.isEmpty ? null : reason,
      lines: [
        if (business.isNotEmpty) ('Negocio', business),
        ('Placa', plate),
        if (_date(data['expiresAt']) != null) ('Vence', _dateTime(_date(data['expiresAt']))),
      ],
    );
  }

  @override
  Future<void> confirm(TransferItem item) {
    return db.collection('parking_reservations').doc(item.id).update({
      'status': 'paid',
      'confirmedBy': uid,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> reject(TransferItem item, String reason) {
    final clean = cleanedReason(reason);
    return db.collection('parking_reservations').doc(item.id).update({
      'status': 'rejected',
      'rejectionReason': clean,
      'confirmedBy': uid,
      'confirmedAt': FieldValue.serverTimestamp(),
    });
  }
}

// ── Pagos de tickets de eventos (contrato_eventos.md §5) ───────────────

class EventTransferSource extends TransferSource {
  const EventTransferSource();

  @override
  TransferKind get kind => TransferKind.events;

  @override
  int get maxReason => 300;

  @override
  int get minReason => 3;

  @override
  String statusValue(TransferBucket b) => switch (b) {
        TransferBucket.toValidate => 'pending',
        TransferBucket.approved => 'paid',
        TransferBucket.rejected => 'rejected',
      };

  @override
  Future<TransferPage> fetchPage({
    required String? cityId,
    required TransferBucket bucket,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) {
    Query<Map<String, dynamic>> q = db.collection('event-orders');
    if (cityId != null) q = q.where('cityId', isEqualTo: cityId);
    q = q
        .where('status', isEqualTo: statusValue(bucket))
        .orderBy('createdAt', descending: true);

    return paged(
      query: q,
      after: after,
      build: (docs) async {
        final events = await docsByIds(
          'event',
          docs.map((d) => _str(d.data()['eventId'])),
        );
        return [
          for (final d in docs) _item(d.id, d.data(), events[_str(d.data()['eventId'])]),
        ];
      },
    );
  }

  TransferItem _item(String id, Map<String, dynamic> data, Map<String, dynamic>? event) {
    final items = data['items'];
    final first = items is List && items.isNotEmpty && items.first is Map
        ? items.first as Map
        : const {};
    final types = event?['ticketTypes'];
    final typeIndex = first['typeIndex'];
    final typeName = types is List && typeIndex is int && typeIndex >= 0 && typeIndex < types.length
        ? _str((types[typeIndex] as Map?)?['name'])
        : '';
    final qty = (first['qty'] as num?)?.toInt() ?? 0;
    final total = _money(data['total']);
    final free = _str(data['paymentMethod']) == 'free';
    final client = _str(data['clientName']);
    final title = _str(event?['title']).isEmpty ? 'Evento' : _str(event?['title']);
    final receipt = data['receipt'] is Map ? data['receipt'] as Map : null;
    final reason = _str(data['rejectionReason']);

    return TransferItem(
      kind: kind,
      id: id,
      title: title,
      subtitle: [client, '$qty ticket${qty == 1 ? '' : 's'}']
          .where((s) => s.isNotEmpty)
          .join(' · '),
      amount: total,
      cityId: _str(data['cityId']),
      createdAt: _date(data['createdAt']),
      canResolve: _str(data['status']) == 'pending',
      confirmText: free
          ? '¿Aprobar $qty ticket(s) gratuito(s) para $client?'
          : '¿Verificaste en el banco la transferencia de ${_usd(total)} de $client? '
              'Se emitirán $qty ticket(s).',
      receiptUrl: receipt == null ? null : _str(receipt['url']),
      receiptIsPdf: _isPdf(receipt),
      rejectionReason: reason.isEmpty ? null : reason,
      lines: [
        ('Evento', title),
        if (typeName.isNotEmpty) ('Ticket', typeName),
        ('Cantidad', '$qty'),
        if (client.isNotEmpty) ('Cliente', client),
        if (_str(data['clientPhone']).isNotEmpty) ('Teléfono', _str(data['clientPhone'])),
        ('Pago', free ? 'Gratuito (sin comprobante)' : 'Transferencia'),
      ],
    );
  }

  /// Aprobar firma y emite los tickets, una sola vez por orden, en la
  /// función `issueEventTickets` (necesita el secreto de firma).
  @override
  Future<void> confirm(TransferItem item) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('issueEventTickets')
          .call<Object?>({'orderId': item.id});
    } on FirebaseFunctionsException catch (e) {
      throw TransferException(switch (e.code) {
        'resource-exhausted' => 'No hay cupo para esta cantidad. Rechaza la orden con el motivo.',
        'failed-precondition' => 'La orden o el evento cambiaron. Actualiza la lista.',
        'permission-denied' => 'No tienes permiso para esta orden.',
        _ => 'Revisa tu conexión e inténtalo de nuevo.',
      });
    }
  }

  @override
  Future<void> reject(TransferItem item, String reason) {
    final clean = cleanedReason(reason);
    return db.collection('event-orders').doc(item.id).update({
      'status': 'rejected',
      'rejectionReason': clean,
      'reviewedBy': uid,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// La fuente de cada flujo.
TransferSource transferSourceFor(TransferKind kind) => switch (kind) {
      TransferKind.ecommerce => const OrderTransferSource(TransferKind.ecommerce),
      TransferKind.food => const OrderTransferSource(TransferKind.food),
      TransferKind.bookings => const BookingTransferSource(),
      TransferKind.parking => const ParkingTransferSource(),
      TransferKind.events => const EventTransferSource(),
    };
