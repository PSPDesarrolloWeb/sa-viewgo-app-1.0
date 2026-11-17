import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/alerts/admin_notification.dart';
import 'package:saviewgo/features/alerts/alerts_repository.dart';
import 'package:saviewgo/features/cities/cities_providers.dart';

final alertsRepositoryProvider =
    Provider<AlertsRepository>((_) => const AlertsRepository());

class AlertsState {
  const AlertsState({
    this.items = const [],
    this.loading = true,
    this.loadingMore = false,
    this.hasMore = false,
    this.error = false,
    this.moreError = false,
    this.marking = false,
  });

  final List<AdminNotification> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final bool error;
  final bool moreError;

  /// Hay un "marcar como leído" en curso.
  final bool marking;

  AlertsState copyWith({
    List<AdminNotification>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    bool? error,
    bool? moreError,
    bool? marking,
  }) {
    return AlertsState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      moreError: moreError ?? this.moreError,
      marking: marking ?? this.marking,
    );
  }
}

/// Bandeja de alertas (P2). Se carga al abrir la app, porque el contador
/// del bottom nav la necesita, y se vuelve a cargar al cambiar de ciudad.
final alertsProvider =
    NotifierProvider<AlertsNotifier, AlertsState>(AlertsNotifier.new);

class AlertsNotifier extends Notifier<AlertsState> {
  int _generation = 0;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _cityId;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  AlertsState build() {
    final cityAsync = ref.watch(scopeCityIdProvider);
    if (cityAsync.isLoading) return const AlertsState();

    _cityId = cityAsync.value;
    final generation = ++_generation;
    Future.microtask(() => _loadFirst(generation));
    return const AlertsState();
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    state = state.copyWith(error: false, moreError: false);
    await _loadFirst(generation, keepItems: true);
  }

  Future<void> _loadFirst(int generation, {bool keepItems = false}) async {
    if (!keepItems) state = const AlertsState();
    try {
      final page = await ref.read(alertsRepositoryProvider).fetchPage(cityId: _cityId);
      if (generation != _generation) return;
      _cursor = page.cursor;
      state = AlertsState(items: page.items, loading: false, hasMore: page.hasMore);
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
      final page = await ref
          .read(alertsRepositoryProvider)
          .fetchPage(cityId: _cityId, after: _cursor);
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

  /// Marca como leídos los avisos [ids] que aún no lo están. Devuelve false
  /// si falló (en ese caso la lista vuelve a como estaba).
  Future<bool> markRead(Iterable<String> ids) async {
    final uid = _uid;
    if (uid == null || state.marking) return true;

    final pending = state.items
        .where((n) => ids.contains(n.id) && !n.isReadBy(uid))
        .map((n) => n.id)
        .toList();
    if (pending.isEmpty) return true;

    final before = state.items;
    state = state.copyWith(
      marking: true,
      items: [for (final n in before) pending.contains(n.id) ? n.markedReadBy(uid) : n],
    );
    try {
      await ref.read(alertsRepositoryProvider).markRead(pending, uid);
      state = state.copyWith(marking: false);
      return true;
    } catch (_) {
      state = state.copyWith(marking: false, items: before);
      return false;
    }
  }

  Future<bool> markAllRead() {
    final uid = _uid;
    if (uid == null) return Future.value(true);
    return markRead(state.items.where((n) => !n.isReadBy(uid)).map((n) => n.id));
  }
}

/// Avisos sin leer entre los ya cargados (hasta 20 por página). Es el
/// número del bottom nav; no lee nada más.
final unreadAlertsCountProvider = Provider<int>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return 0;
  return ref.watch(alertsProvider).items.where((n) => !n.isReadBy(uid)).length;
});
