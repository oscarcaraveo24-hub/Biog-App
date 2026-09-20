// lib/core/agro/nutrition/nutrition_guide_catalog.dart
//
// CATÁLOGO DE GUÍAS NUTRICIONALES CURADAS (Guía v0.4, §5 y §34 «Auditoría de
// guías cultivo por cultivo»).
//
// Aquí se registran las guías que el equipo ya revisó o está revisando. Un
// cultivo sin guía NO queda sin motor: el perfil fenológico (`StageTargets`)
// sigue abriendo ventanas por prioridad; solo se pierde la capa de fuentes,
// plan de temporada y rangos. Y un rango `proposed` existe con su fuente para
// poder auditarlo, pero el agricultor no lo ve hasta que se marque `audited`.
//
// La tabla de guías vive en `nutrition_guides.dart` para que este archivo sea
// solo el punto de acceso.
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guides.dart';

class NutritionGuideCatalog {
  const NutritionGuideCatalog._();

  /// Guía curada del cultivo, o null si todavía no existe.
  static NutritionGuide? forCrop(String? cropKey) {
    final String key = _normalize(cropKey);
    if (key.isEmpty) return null;
    return kNutritionGuides[key] ?? kNutritionGuides[_aliases[key] ?? ''];
  }

  /// Cultivos con guía registrada (para la auditoría y las pruebas).
  static Iterable<String> get cropKeys => kNutritionGuides.keys;

  /// Clave canónica de guía para cualquier forma de nombrar el cultivo:
  /// `crop_avocado_tree`, `avocadoTree`, `aguacate` y `avocado_tree` dan todas
  /// `avocado_tree`. Sin guía registrada devuelve la clave normalizada tal
  /// cual, para que dos nombres iguales sigan comparando iguales.
  ///
  /// Es la comparación que deben usar la declaración de temporada y cualquier
  /// otro dato guardado con el id de cultivo de la app: la app guarda
  /// `crop_avocado_tree` y la guía se llama `avocado_tree`; comparar los
  /// textos crudos hacía que la respuesta del productor «no aplicara» nunca.
  static String canonicalKey(String? cropKey) {
    final String key = _normalize(cropKey);
    if (key.isEmpty) return '';
    if (kNutritionGuides.containsKey(key)) return key;
    return _aliases[key] ?? key;
  }

  static String _normalize(String? raw) {
    String k = (raw ?? '').trim().toLowerCase();
    if (k.startsWith('crop_')) k = k.substring(5);
    return k;
  }

  /// Nombres alternos que aparecen en contextos de cultivo antiguos, más el
  /// `CropKey.name` en minúsculas de los frutales (`appletree`) para que la
  /// guía resuelva venga de donde venga la clave.
  static const Map<String, String> _aliases = <String, String>{
    'maiz': 'maize',
    'maíz': 'maize',
    'corn': 'maize',
    'trigo': 'wheat',
    'cebada': 'barley',
    'avena': 'oat',
    'frijol': 'bean',
    'tomate': 'tomato',
    'jitomate': 'tomato',
    'chile': 'chili',
    'pepper': 'chili',
    'pepino': 'cucumber',
    'berenjena': 'eggplant',
    'calabaza': 'squash',
    'calabacita': 'squash',
    'lechuga': 'lettuce',
    'espinaca': 'spinach',
    'cebolla': 'onion',
    'ajo': 'garlic',
    'appletree': 'apple_tree',
    'manzano': 'apple_tree',
    'peartree': 'pear_tree',
    'peral': 'pear_tree',
    'peachtree': 'peach_tree',
    'durazno': 'peach_tree',
    'walnuttree': 'walnut_tree',
    'nogal': 'walnut_tree',
    'pistachiotree': 'pistachio_tree',
    'pistache': 'pistachio_tree',
    'orangetree': 'orange_tree',
    'naranjo': 'orange_tree',
    'lemontree': 'lemon_tree',
    'limonero': 'lemon_tree',
    'limon': 'lemon_tree',
    'mangotree': 'mango_tree',
    'mango': 'mango_tree',
    'avocadotree': 'avocado_tree',
    'aguacate': 'avocado_tree',
    'rosal': 'rose',
    'girasol': 'sunflower',
    'cempasuchil': 'marigold',
    'cempasúchil': 'marigold',
    'tulipan': 'tulip',
    'tulipán': 'tulip',
    'sabila': 'aloe',
    'sábila': 'aloe',
    'suculenta': 'succulent',
  };
}
