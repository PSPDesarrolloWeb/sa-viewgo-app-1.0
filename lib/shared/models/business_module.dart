import 'package:flutter/material.dart';
import 'package:saviewgo/core/theme/colors.dart';

/// Módulos de un negocio (`business.modules.{key}`), con el nombre y el
/// color de categoría que usa todo ViewGo.
enum BusinessModule {
  food('food', 'Gastronomía', AppColors.quaternary),
  ecommerce('ecommerce', 'Ecommerce', AppColors.tertiary),
  services('services', 'Servicios', AppColors.quinary),
  parking('parking', 'Parking', AppColors.senary),
  events('events', 'Eventos', AppColors.septenary);

  const BusinessModule(this.key, this.label, this.color);

  /// Clave en Firestore.
  final String key;
  final String label;
  final Color color;

  static BusinessModule? fromKey(String key) {
    for (final m in values) {
      if (m.key == key) return m;
    }
    return null;
  }
}