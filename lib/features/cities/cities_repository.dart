import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saviewgo/features/cities/city_model.dart';

/// Ficha: CitiesRepository
/// - Colección: city/{cityId}
/// - Documentos hoy: menos de 24 · tope teórico: 221 (cantones del Ecuador)
/// - Tamaño: pequeño · cambios por día: casi nunca
/// - Quién lee: superadmin_global y superadmin_city
/// - Pantallas: selector de ciudad, nombres de ciudad en el Resumen
/// - Tiempo real: no hace falta
/// - Filtros y orden: active == true, ordenado por name (en el servidor;
///   índice city: active ASC, name ASC ya declarado)
/// - Búsqueda: en memoria, por nombre, provincia, alias y keywords
/// - Patrón: P1 Catálogo compartido, en versión de lectura única: un solo
///   get() por sesión que queda en memoria.
class CitiesRepository {
  const CitiesRepository();

  /// Ciudades activas ordenadas por nombre. Cuesta 1 lectura por ciudad
  /// activa (1 si no hay ninguna).
  Future<List<CityModel>> fetchActive() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('city')
        .where('active', isEqualTo: true)
        .orderBy('name')
        .get();
    return snapshot.docs.map(CityModel.fromDoc).toList();
  }
}