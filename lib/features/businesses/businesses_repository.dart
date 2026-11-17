import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saviewgo/features/businesses/business_model.dart';
import 'package:saviewgo/shared/models/business_module.dart';
import 'package:saviewgo/shared/utils/text_normalize.dart';

/// Filtros de la lista de negocios.
class BusinessFilters {
  const BusinessFilters({this.query = '', this.active, this.module});

  /// Texto de búsqueda ya limpio (sin espacios en los bordes).
  final String query;

  /// true = solo activos, false = solo inactivos, null = todos.
  final bool? active;
  final BusinessModule? module;

  bool get isSearching => normalizeText(query).isNotEmpty;
  bool get hasFilters => active != null || module != null;

  BusinessFilters copyWith({
    String? query,
    Object? active = _keep,
    Object? module = _keep,
  }) {
    return BusinessFilters(
      query: query ?? this.query,
      active: identical(active, _keep) ? this.active : active as bool?,
      module: identical(module, _keep) ? this.module : module as BusinessModule?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is BusinessFilters &&
      other.query == query &&
      other.active == active &&
      other.module == module;

  @override
  int get hashCode => Object.hash(query, active, module);
}

const _keep = Object();

class BusinessPage {
  const BusinessPage({
    required this.items,
    required this.cursor,
    required this.hasMore,
  });

  final List<BusinessModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

/// Ficha: BusinessesRepository (lista de negocios del superadmin)
/// - Colección: business/{businessId}
/// - Documentos hoy: decenas · en 12 meses: cientos o más (crece)
/// - Tamaño: mediano (módulos, representante, límites)
/// - Cambios por día: pocos
/// - Quién lee: superadmin_global y superadmin_city (la lectura es pública)
/// - Pantallas: lista de Negocios y su detalle
/// - Tiempo real: no hace falta; se refresca con jalar hacia abajo
/// - Filtros y orden, en el servidor: ciudad (cityIds array-contains),
///   activo, módulo (modules.X.enabled); orden createdAt desc. Con texto de
///   búsqueda: prefijo de nameNormalized (sin los demás filtros, que se
///   aplican en el dispositivo a esos resultados).
/// - Patrón: P2 Lista paginada (`limit` + `startAfterDocument`) y P4 para
///   el detalle (un `get()` por negocio, sin listener).
/// - Índices: ver firestore.indexes.json (cityIds+createdAt, active+createdAt,
///   modules.X.enabled+createdAt, cityIds+nameNormalized). Se combinan entre
///   sí por fusión de índices.
class BusinessesRepository {
  const BusinessesRepository();

  static const pageSize = 20;

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection('business');

  /// [cityId] null = todas las ciudades.
  Future<BusinessPage> fetchPage({
    required String? cityId,
    required BusinessFilters filters,
    DocumentSnapshot<Map<String, dynamic>>? after,
  }) async {
    Query<Map<String, dynamic>> query = _col;

    if (cityId != null) {
      query = query.where('cityIds', arrayContains: cityId);
    }

    final normalized = normalizeText(filters.query);
    if (normalized.isNotEmpty) {
      // Búsqueda por prefijo del nombre normalizado.
      query = query
          .where('nameNormalized', isGreaterThanOrEqualTo: normalized)
          .where('nameNormalized', isLessThanOrEqualTo: '$normalized')
          .orderBy('nameNormalized');
    } else {
      if (filters.active != null) {
        query = query.where('active', isEqualTo: filters.active);
      }
      final module = filters.module;
      if (module != null) {
        query = query.where('modules.${module.key}.enabled', isEqualTo: true);
      }
      query = query.orderBy('createdAt', descending: true);
    }

    if (after != null) query = query.startAfterDocument(after);
    final snapshot = await query.limit(pageSize).get();

    var items = snapshot.docs
        .map((d) => BusinessModel.fromDoc(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList();

    // Con búsqueda, activo y módulo se aplican sobre la página recibida.
    if (normalized.isNotEmpty) {
      items = items.where((b) {
        if (filters.active != null && b.active != filters.active) return false;
        final module = filters.module;
        if (module != null &&
            !b.enabledModules.any((m) => m.module == module)) {
          return false;
        }
        return true;
      }).toList();
    }

    return BusinessPage(
      items: items,
      cursor: snapshot.docs.isEmpty
          ? after
          : snapshot.docs.last as DocumentSnapshot<Map<String, dynamic>>,
      hasMore: snapshot.docs.length == pageSize,
    );
  }

  /// Un negocio por id (1 lectura).
  Future<BusinessModel?> fetchById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BusinessModel.fromDoc(doc);
  }

  /// Sucursales del negocio (máximo 20, una consulta por detalle abierto).
  Future<List<BranchModel>> fetchBranches(String businessId) async {
    final snapshot = await _col
        .doc(businessId)
        .collection('branches')
        .orderBy('isMain', descending: true)
        .limit(20)
        .get();
    return snapshot.docs.map(BranchModel.fromDoc).toList();
  }
}
