import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';
import 'package:saviewgo/features/transfers/transfer_item.dart';
import 'package:saviewgo/features/transfers/transfers_repository.dart';

class TransferFilters {
  const TransferFilters({
    this.kind = TransferKind.ecommerce,
    this.bucket = TransferBucket.toValidate,
  });

  final TransferKind kind;
  final TransferBucket bucket;

  TransferFilters copyWith({TransferKind? kind, TransferBucket? bucket}) =>
      TransferFilters(kind: kind ?? this.kind, bucket: bucket ?? this.bucket);

  @override
  bool operator ==(Object other) =>
      other is TransferFilters && other.kind == kind && other.bucket == bucket;

  @override
  int get hashCode => Object.hash(kind, bucket);
}

final transferFiltersProvider =
    NotifierProvider<TransferFiltersNotifier, TransferFilters>(
        TransferFiltersNotifier.new);

class TransferFiltersNotifier extends Notifier<TransferFilters> {
  @override
  TransferFilters build() {
    ref.watch(firebaseUserProvider.select((u) => u.value?.uid));
    return const TransferFilters();
  }

  void set(TransferFilters filters) => state = filters;
}

class TransfersState {
  const TransfersState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error = false,
    this.moreError = false,
    this.busyIds = const {},
  });

  final List<TransferItem> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final bool error;
  final bool moreError;

  /// Pagos con una acción en curso: no admiten una segunda a la vez.
  final Set<String> busyIds;

  TransfersState copyWith({
    List<TransferItem>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    bool? error,
    bool? moreError,
    Set<String>? busyIds,
  }) {
    return TransfersState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      moreError: moreError ?? this.moreError,
      busyIds: busyIds ?? this.busyIds,
    );
  }
}

/// Lista paginada de transferencias (P2). Se vuelve a cargar al cambiar
/// de ciudad, flujo o bandeja. Se descarta al salir de la pantalla.
final transfersProvider =
    NotifierProvider.autoDispose<TransfersNotifier, TransfersState>(
        TransfersNotifier.new);

class TransfersNotifier extends Notifier<TransfersState> {
  int _generation = 0;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _cityId;
  TransferFilters _filters = const TransferFilters();

  TransferSource get _source => transferSourceFor(_filters.kind);

  @override
  TransfersState build() {
    final cityAsync = ref.watch(scopeCityIdProvider);
    final filters = ref.watch(transferFiltersProvider);
    if (cityAsync.isLoading) return const TransfersState();

    _cityId = cityAsync.value;
    _filters = filters;
    final generation = ++_generation;
    Future.microtask(() => _loadFirst(generation));
    return const TransfersState();
  }

  bool _stale(int generation) => generation != _generation || !ref.mounted;

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(error: false, moreError: false);
    await _loadFirst(generation, keepItems: true);
  }

  Future<void> _loadFirst(int generation, {bool keepItems = false}) async {
    if (!keepItems) state = const TransfersState();
    try {
      final page = await _source.fetchPage(cityId: _cityId, bucket: _filters.bucket);
      if (_stale(generation)) return;
      _cursor = page.cursor;
      state = TransfersState(items: page.items, loading: false, hasMore: page.hasMore);
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
      final page = await _source.fetchPage(
        cityId: _cityId,
        bucket: _filters.bucket,
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

  /// Valida el pago. Devuelve null si salió bien, o el mensaje de error.
  Future<String?> confirm(TransferItem item) =>
      _run(item, () => transferSourceFor(item.kind).confirm(item));

  Future<String?> reject(TransferItem item, String reason) =>
      _run(item, () => transferSourceFor(item.kind).reject(item, reason));

  Future<String?> _run(TransferItem item, Future<void> Function() action) async {
    if (state.busyIds.contains(item.id)) return 'Ya hay una acción en curso.';
    state = state.copyWith(busyIds: {...state.busyIds, item.id});
    try {
      await action();
      if (ref.mounted) {
        // Ya no pertenece a esta bandeja: sale de la lista.
        state = state.copyWith(items: state.items.where((o) => o != item).toList());
      }
      return null;
    } on TransferException catch (e) {
      return e.message;
    } on FirebaseException catch (e) {
      return e.code == 'permission-denied'
          ? 'No tienes permiso para esta operación.'
          : 'No se pudo actualizar. Puede haber cambiado de estado: actualiza la lista.';
    } catch (_) {
      return 'No se pudo actualizar. Actualiza la lista e inténtalo de nuevo.';
    } finally {
      if (ref.mounted) {
        state = state.copyWith(
          busyIds: state.busyIds.where((id) => id != item.id).toSet(),
        );
      }
    }
  }
}

/// Comprobante del pago abierto (hasta 1 lectura).
final transferReceiptProvider =
    FutureProvider.autoDispose.family<TransferReceipt?, TransferItem>((ref, item) {
  return transferSourceFor(item.kind).fetchReceipt(item);
});
