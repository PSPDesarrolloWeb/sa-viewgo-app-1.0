import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/orders/order_audit.dart';

/// Ficha: pedidos para auditoría (solo lectura)
/// - Colecciones: ecommerce-orders y food-orders; crecen sin tope
/// - Quién lee: superadmin_global y superadmin_city (su `cityId`: la
///   consulta lo filtra en el servidor y las reglas lo exigen)
/// - Pantalla: Pedidos (desde el Resumen). Sin escrituras: cancelar y
///   registrar reembolsos se hacen en el panel web.
/// - Tiempo real: no; se lee al entrar y al jalar hacia abajo
/// - Filtros y orden: cityId y status opcionales, createdAt desc. Índices
///   del contrato §12: `status+createdAt`, `cityId+createdAt`,
///   `cityId+status+createdAt`.
/// - Patrón: P2 Lista paginada (20 por página, `startAfterDocument`).
/// - Privacidad: no se leen datos de contacto ni la dirección de entrega
///   en la pantalla (el documento los trae, pero no se guardan en el
///   modelo ni se muestran).
class OrdersRepository {
  const OrdersRepository();

  static const pageSize = 20;

  Future<({List<AuditOrder> items, DocumentSnapshot<Map<String, dynamic>>? cursor, bool hasMore})>
      fetchPage({
    required OrderModuleKind module,
    required String? status,
    required String? cityId,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> q =
        FirebaseFirestore.instance.collection(module.collection);
    if (cityId != null) q = q.where('cityId', isEqualTo: cityId);
    if (status != null) q = q.where('status', isEqualTo: status);
    q = q.orderBy('createdAt', descending: true);
    if (after != null) q = q.startAfterDocument(after);

    final snapshot = await q.limit(pageSize).get();
    return (
      items: [for (final d in snapshot.docs) AuditOrder.fromDoc(module, d)],
      cursor: snapshot.docs.isEmpty ? after : snapshot.docs.last,
      hasMore: snapshot.docs.length == pageSize,
    );
  }
}

class OrderFilters {
  const OrderFilters({this.module = OrderModuleKind.ecommerce, this.status});

  final OrderModuleKind module;

  /// null = todos los estados.
  final String? status;

  @override
  bool operator ==(Object other) =>
      other is OrderFilters && other.module == module && other.status == status;

  @override
  int get hashCode => Object.hash(module, status);
}

final orderFiltersProvider =
    NotifierProvider<OrderFiltersNotifier, OrderFilters>(OrderFiltersNotifier.new);

class OrderFiltersNotifier extends Notifier<OrderFilters> {
  @override
  OrderFilters build() {
    ref.watch(firebaseUserProvider.select((u) => u.value?.uid));
    return const OrderFilters();
  }

  void setModule(OrderModuleKind module) =>
      state = OrderFilters(module: module, status: state.status);

  void setStatus(String? status) =>
      state = OrderFilters(module: state.module, status: status);
}

class OrdersState {
  const OrdersState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error = false,
    this.moreError = false,
  });

  final List<AuditOrder> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final bool error;
  final bool moreError;

  OrdersState copyWith({
    List<AuditOrder>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    bool? error,
    bool? moreError,
  }) {
    return OrdersState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      moreError: moreError ?? this.moreError,
    );
  }
}

final ordersProvider =
    NotifierProvider.autoDispose<OrdersNotifier, OrdersState>(OrdersNotifier.new);

class OrdersNotifier extends Notifier<OrdersState> {
  int _generation = 0;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _cityId;
  OrderFilters _filters = const OrderFilters();

  @override
  OrdersState build() {
    final cityAsync = ref.watch(scopeCityIdProvider);
    final filters = ref.watch(orderFiltersProvider);
    if (cityAsync.isLoading) return const OrdersState();

    _cityId = cityAsync.value;
    _filters = filters;
    final generation = ++_generation;
    Future.microtask(() => _loadFirst(generation));
    return const OrdersState();
  }

  bool _stale(int generation) => generation != _generation || !ref.mounted;

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(error: false, moreError: false);
    await _loadFirst(generation, keepItems: true);
  }

  Future<void> _loadFirst(int generation, {bool keepItems = false}) async {
    if (!keepItems) state = const OrdersState();
    try {
      final page = await const OrdersRepository().fetchPage(
        module: _filters.module,
        status: _filters.status,
        cityId: _cityId,
      );
      if (_stale(generation)) return;
      _cursor = page.cursor;
      state = OrdersState(items: page.items, loading: false, hasMore: page.hasMore);
    } catch (_) {
      if (_stale(generation)) return;
      state = state.copyWith(loading: false, error: state.items.isEmpty);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, moreError: false);
    try {
      final page = await const OrdersRepository().fetchPage(
        module: _filters.module,
        status: _filters.status,
        cityId: _cityId,
        after: _cursor,
      );
      if (_stale(generation)) return;
      _cursor = page.cursor;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        loadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (_) {
      if (_stale(generation)) return;
      state = state.copyWith(loadingMore: false, moreError: true);
    }
  }
}
