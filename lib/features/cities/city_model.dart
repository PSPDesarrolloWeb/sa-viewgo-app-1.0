import 'package:cloud_firestore/cloud_firestore.dart';

/// Versión mínima del modelo; se reemplaza por la versión con freezed
/// cuando se construya el servicio completo de ciudades.
class City {
  const City({
    required this.id,
    required this.name,
    required this.province,
    required this.active,
  });

  factory City.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return City(
      id: doc.id,
      name: data['name'] as String? ?? '',
      province: data['province'] as String? ?? '',
      active: data['active'] as bool? ?? false,
    );
  }

  final String id;
  final String name;
  final String province;
  final bool active;
}