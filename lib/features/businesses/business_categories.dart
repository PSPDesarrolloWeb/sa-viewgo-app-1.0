/// Nombre corto de cada categoría (`business.category`). Mismas claves que
/// CategoryService del panel web. Una clave desconocida se muestra como
/// "Otros".
const _categoryLabels = <String, String>{
  'agriculture_agroindustry': 'Agricultura',
  'food_drink': 'Alimentos',
  'automobiles_transportation': 'Automóviles',
  'beauty_personal_care': 'Belleza',
  'home_family': 'Bienestar',
  'shop_store': 'Tiendas',
  'construction_ironmongery': 'Construcción',
  'culture_art': 'Cultura',
  'sports_outdoors': 'Deportes',
  'education_training': 'Educación',
  'jobs_hr': 'RRHH',
  'entertainment_leisure': 'Ocio',
  'events_celebrations': 'Eventos',
  'finance_insurance': 'Finanzas',
  'home_gardening': 'Hogar',
  'government_legal': 'Legales',
  'pets_animals': 'Animales',
  'advertising_media': 'Publicidad',
  'fashion_accessories': 'Moda',
  'professional_services': 'Servicios profesionales',
  'technology_electronics': 'Tecnología',
  'tourism_accommodation': 'Turismo',
  'housing_real_estate': 'Inmobiliaria',
  'parking_service': 'Parking',
};

String categoryLabel(String key) => _categoryLabels[key] ?? 'Otros';
