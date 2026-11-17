import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/core/auth/auth_providers.dart';
import 'package:saviewgo/features/businesses/business_model.dart';
import 'package:saviewgo/features/businesses/businesses_repository.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';

final businessesRepositoryProvider =
    Provider<BusinessesRepository>((_) => const BusinessesRepository());

/// Filtros activos de la lista. Se reinician al cambiar de usuario.
final businessFiltersProvider =
    NotifierProvider<BusinessFiltersNotifier, BusinessFilters>(
        BusinessFiltersNotifier.new);

class BusinessFiltersNotifier extends Notifier<BusinessFilters> {
  @override
  BusinessFilters build() {
    ref.watch(firebaseUserProvider.select((u) => u.value?.uid));
    return const BusinessFilters();
  }

  void set(BusinessFilters filters) => state = filters;
}

/// Estado de la lista paginada.
class BusinessListState {
  const BusinessListState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error = false,
    this.moreError = false,
  });

  final List<BusinessModel> items;

  /// Primera página en curso.
  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  /// Falló la primera página.
  final bool error;

  /// Falló una página siguiente (se conserva lo ya cargado).
  final bool moreError;

  BusinessListState copyWith({
    List<BusinessModel>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    bool? error,
    bool? moreError,
  }) {
    return BusinessListState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      moreError: moreError ?? this.moreError,
    );
  }
}

/// Lista paginada (P2). Se vuelve a cargar sola cuando cambia la ciudad o
/// los filtros; `refresh()` la recarga a mano.
final businessListProvider =
    NotifierProvider<BusinessListNotifier, BusinessListState>(
        BusinessListNotifier.new);

class BusinessListNotifier extends Notifier<BusinessListState> {
  /// Cada recarga sube el número; una respuesta vieja se descarta.
  int _generation = 0;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _cityId;
  BusinessFilters _filters = const BusinessFilters();

  @override
  BusinessListState build() {
    final cityAsync = ref.watch(scopeCityIdProvider);
    final filters = ref.watch(businessFiltersProvider);

    // Aún no se conocen los claims: espera sin consultar.
    if (cityAsync.isLoading) return const BusinessListState();

    _cityId = cityAsync.value;
    _filters = filters;
    final generation = ++_generation;
    Future.microtask(() => _loadFirst(generation));
    return const BusinessListState();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(error: false, moreError: false);
    await _loadFirst(generation, keepItems: true);
  }

  Future<void> _loadFirst(int generation, {bool keepItems = false}) async {
    if (!keepItems) state = const BusinessListState();
    try {
      final page = await ref.read(businessesRepositoryProvider).fetchPage(
            cityId: _cityId,
            filters: _filters,
          );
      if (generation != _generation) return;
      _cursor = page.cursor;
      state = BusinessListState(
        items: page.items,
        loading: false,
        hasMore: page.hasMore,
      );
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(loading: false, error: state.items.isEmpty);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) return;
    final generation = _generation;
    state = state.copyWith(loadingMore: true, moreError: false);
    try {
      final page = await ref.read(businessesRepositoryProvider).fetchPage(
            cityId: _cityId,
            filters: _filters,
            after: _cursor,
          );
      if (generation != _generation) return;
      _cursor = page.cursor;
      state = state.copyWith(
        items: [...state.items, ...page.items],
        loadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (_) {
      if (generation != _generation) return;
      state = state.copyWith(loadingMore: false, moreError: true);
    }
  }
}

/// Detalle: un `get()` por negocio abierto. Se descarta al salir.
final businessDetailProvider =
    FutureProvider.autoDispose.family<BusinessModel?, String>((ref, id) {
  return ref.read(businessesRepositoryProvider).fetchById(id);
});

/// Sucursales del negocio abierto.
final businessBranchesProvider =
    FutureProvider.autoDispose.family<List<BranchModel>, String>((ref, id) {
  return ref.read(businessesRepositoryProvider).fetchBranches(id);
});
