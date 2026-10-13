import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saviewgo/features/cities/city_model.dart';

/// P1 · Catálogo compartido: un solo listener sin autoDispose.
/// Se cobra la colección una vez por sesión más los cambios.
/// Recuerda invalidarlo al cerrar sesión.
final citiesProvider = StreamProvider<List<City>>((ref) {
  return FirebaseFirestore.instance
      .collection('city')
      .orderBy('name')
      .snapshots()
      .map((snap) => snap.docs.map(City.fromDoc).toList());
});