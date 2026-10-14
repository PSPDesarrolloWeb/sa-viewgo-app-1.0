import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saviewgo/shared/utils/text_normalize.dart';

/// Documento `city/{cityId}`. Equivale a ICity del panel web
/// (city.interface.ts).
///
/// IDENTIFICADORES (no mezclarlos):
///  - id:   id del documento. Identificador canónico para todo lo que
///          referencia una ciudad: business.cityIds, sucursales, topic de
///          notificaciones y el claim `city` del superadmin_city.
///  - key:  código interno de ViewGo. Uso administrativo; no es referencia.
///  - slug: solo para URLs.
///  - name: solo para mostrar.
class CityModel {
  const CityModel({
    required this.id,
    required this.key,
    required this.name,
    required this.slug,
    required this.province,
    required this.active,
    this.keywords = const [],
    this.aliases = const [],
    this.location,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String key;
  final String name;
  final String slug;
  final String province;
  final bool active;

  /// Etiquetas de búsqueda dentro de la app (ej. "capital", "andina").
  final List<String> keywords;

  /// Nombres alternativos reales (ej. "San Miguel de Ibarra").
  final List<String> aliases;

  final GeoPoint? location;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory CityModel.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const {};
    List<String> strings(Object? value) =>
        value is List ? value.whereType<String>().toList() : const [];

    return CityModel(
      id: doc.id,
      key: data['key'] as String? ?? '',
      name: data['name'] as String? ?? '',
      slug: data['slug'] as String? ?? '',
      province: data['province'] as String? ?? '',
      active: data['active'] as bool? ?? false,
      keywords: strings(data['keywords']),
      aliases: strings(data['aliases']),
      location: data['location'] as GeoPoint?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Búsqueda en el selector: nombre, provincia, alias y keywords, sin
  /// importar tildes ni mayúsculas.
  bool matchesSearch(String query) {
    final q = normalizeText(query);
    if (q.isEmpty) return true;
    return [name, province, ...aliases, ...keywords]
        .any((value) => normalizeText(value).contains(q));
  }
}

extension CityListX on List<CityModel> {
  /// Ciudad por id, o null si no está en la lista.
  CityModel? byId(String? id) {
    if (id == null) return null;
    for (final city in this) {
      if (city.id == id) return city;
    }
    return null;
  }
}