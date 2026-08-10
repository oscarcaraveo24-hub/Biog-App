import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';

/// Catálogo base del Cempasúchil (segunda ornamental ANUAL VERDADERA de BIO-G,
/// después del Girasol).
///
/// Solo metadata de catálogo: ids de perfil, etiquetas humanas y aliases. La
/// agronomía vive en `marigold_universal_profile.dart`, el reloj anual en
/// `marigold_engine.dart` y los riesgos/sanidad en `marigold_risk_catalog.dart`
/// + `marigold_syndromes.dart` (Documentos A/B/C del paquete Cempasúchil CS v1).
///
/// Regla central del Cempasúchil (Documento A §0.1, §0.3): es *Tagetes erecta*
/// L., una anual verdadera en modo `annual_ornamental`. El motor se parece al
/// del Girasol y al de los granos (fecha ancla → día → etapa), pero el final es
/// `cycle_complete` TERMINAL: la planta cierra su ciclo y una nueva temporada
/// exige una nueva siembra. No proyecta rendimiento, manojos, tallos ni cosecha,
/// y NO programa automáticamente para el 1 y 2 de noviembre (§4.3).
const String kCropMarigold = 'crop_marigold';

/// Id legacy/cropKey esperado del cempasúchil. Alias de compatibilidad.
const String kMarigoldLegacy = 'marigold';

/// Perfiles del cempasúchil, en el ORDEN EN QUE SE MUESTRAN AL USUARIO
/// (Documento A §6, §15.2). Los tipos concretos primero (cs_01 a cs_04) y **al
/// final** la salida "No sé / Cempasúchil general". El perfil general/SKIP va
/// SIEMPRE disponible y NUNCA muestra al usuario la palabra "SKIP" ni el
/// profileId. Sigue siendo el `defaultProfileId`: si el usuario no elige, cae
/// aquí.
const List<CropProfileEntry> marigoldProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kCs01TraditionalField,
    label: 'Cempasúchil tradicional de campo',
    cropId: kCropMarigold,
    subtitle:
        'Planta ramificada de campo o cama, común para ofrenda, manojo y venta '
        'de temporada (flor de muerto)',
    aliases: <String>[
      'CS-01',
      'CS01',
      'cs_01',
      'cempasúchil tradicional',
      'cempasuchil tradicional',
      'cempoalxóchitl tradicional',
      'cempoalxochitl tradicional',
      'flor de muerto tradicional',
      'cempasúchil criollo de campo',
      'flor para ofrenda',
      'cempasúchil para manojo',
      'cempasúchil de surco',
      'cempasúchil de chinampa',
      'cempasúchil de temporada',
      'traditional Mexican marigold',
      'Aztec marigold tradicional',
    ],
  ),
  CropProfileEntry(
    id: kCs02TallCutFlower,
    label: 'Cempasúchil alto de corte',
    cropId: kCropMarigold,
    subtitle:
        'Cempasúchil de tallos largos y firmes para flor de corte, ramos, '
        'arreglos y guirnaldas',
    aliases: <String>[
      'CS-02',
      'CS02',
      'cs_02',
      'cempasúchil de corte',
      'cempasuchil de corte',
      'flor de corte',
      'cempasúchil de tallo largo',
      'marigold de corte',
      'cut flower marigold',
      'African marigold cut flower',
      'American marigold cut flower',
      'long stem marigold',
      'Xochi',
      'Xochi Orange',
      'COCO',
      'COCO Gold',
      'COCO Yellow',
      'COCO Deep Orange',
      'Giant Orange',
      'Giant Yellow',
      'White Swan',
      'Nosento',
    ],
  ),
  CropProfileEntry(
    id: kCs03CompactContainer,
    label: 'Cempasúchil compacto para maceta',
    cropId: kCropMarigold,
    subtitle:
        'Cempasúchil enano de porte bajo y redondeado para maceta, patio, '
        'balcón o decoración de casa',
    aliases: <String>[
      'CS-03',
      'CS03',
      'cs_03',
      'cempasúchil enano',
      'cempasuchil enano',
      'cempasúchil compacto',
      'cempasúchil de maceta',
      'cempasúchil para maceta',
      'cempasúchil mini',
      'marigold compacto',
      'African marigold dwarf',
      'American marigold dwarf',
      'Proud Mari',
      'Inca II compacto',
      'Antigua compacto',
      'Discovery compacto',
    ],
  ),
  CropProfileEntry(
    id: kCs04LandscapeBedding,
    label: 'Cempasúchil para cama o paisaje',
    cropId: kCropMarigold,
    subtitle:
        'Porte intermedio de ramificación pareja y floración de masa para '
        'camas, parques y camellones',
    aliases: <String>[
      'CS-04',
      'CS04',
      'cs_04',
      'cempasúchil paisajístico',
      'cempasuchil paisajistico',
      'cempasúchil para cama',
      'cempasúchil de camellón',
      'cempasúchil de parque',
      'marigold bedding',
      'African marigold landscape',
      'Marvel II',
      'Marvel',
      'Taishan',
      'Bali',
      'cama urbana',
      'floración de masa',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí. "African
  // marigold", "Mexican marigold" y "flor de muerto" resuelven AQUÍ, nunca a un
  // porte específico (Documento A §6.5).
  CropProfileEntry(
    id: kCsSkip,
    label: 'No sé / Cempasúchil general',
    cropId: kCropMarigold,
    // Subtítulo literal del Documento A §6.5. El texto largo de UX ("puedes
    // cambiar el tipo sin perder el historial") es un mensaje aparte de la
    // pantalla, no el subtítulo de la opción del wizard.
    subtitle:
        'Perfil general y migrable del cempasúchil, precisas el tipo de planta '
        'o semilla después sin perder historial',
    aliases: <String>[
      'CS-SKIP',
      'CS_SKIP',
      'CSSKIP',
      'CS-GEN',
      'CS_GEN',
      'cempasúchil',
      'cempasuchil',
      'sempasúchil',
      'sempasuchil',
      'zempasúchil',
      'zempasuchil',
      'cempoalxóchitl',
      'cempoalxochitl',
      'cempaxúchitl',
      'cempaxuchitl',
      'flor de muerto',
      'flor de muertos',
      'flor de veinte pétalos',
      'flor de veinte petalos',
      'Tagetes erecta',
      'T. erecta',
      'Aztec marigold',
      'Mexican marigold',
      'African marigold',
      'American marigold',
      'otro cempasúchil',
      'cempasúchil general',
      'no sé qué cempasúchil es',
      'no se que cempasuchil es',
      'semilla de cempasúchil',
    ],
  ),
];

/// Aliases de ENTRADA que NO son *Tagetes erecta* ornamental y NO deben mapear
/// a `crop_marigold` (Documento A §4.4, §4.5, §8.3). Se excluyen del alta
/// automática y requieren confirmación explícita del usuario: son otras
/// especies de *Tagetes* con arquitectura y ciclo distintos, u otras plantas
/// llamadas "marigold" en inglés que ni siquiera pertenecen al género.
const List<String> marigoldNotAMarigoldRedirectAliases = <String>[
  // Otras especies de Tagetes (§4.4).
  'french marigold',
  'tagetes patula',
  'clavel de moro',
  'copete',
  'damasquina',
  'signet marigold',
  'tagetes tenuifolia',
  'mexican mint marigold',
  'tagetes lucida',
  'pericon',
  'pericón',
  'yauhtli',
  'estragon mexicano',
  'estragón mexicano',
  'wild marigold',
  'tagetes minuta',
  'huacatay',
  'chinchilla',
  'mexican bush marigold',
  'tagetes lemmonii',
  // "Marigolds" que no son Tagetes (§4.5).
  'pot marigold',
  'calendula officinalis',
  'caléndula',
  'calendula',
  'marsh marigold',
  'caltha palustris',
  'desert marigold',
  'baileya multiradiata',
  'corn marigold',
  'glebionis segetum',
];

/// True si el alias corresponde a una planta llamada "marigold" o "tagete" que
/// NO es *Tagetes erecta* ornamental (no debe mapear a crop_marigold sin
/// confirmación, Documento A §4.4, §4.5, §18.2).
bool isNotAMarigoldAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return marigoldNotAMarigoldRedirectAliases.contains(v);
}

/// La palabra "Tagetes" sola NO identifica especie (Documento A §4.4 regla).
/// El wizard debe preguntar: "¿Es la flor alta o mediana de cabezuela grande
/// usada como cempasúchil, o es un tagete pequeño de borde?". Si el usuario no
/// sabe, NO se fuerza `crop_marigold` solo por el género.
const List<String> marigoldGenusOnlyAliases = <String>[
  'tagetes',
  'tagete',
  'tagetes spp',
  'tagetes spp.',
  'tagetes sp',
  'tagetes sp.',
];

/// True cuando el texto solo nombra el GÉNERO y exige confirmación de especie
/// antes de dar de alta un Cempasúchil (Documento A §4.4, §18.2).
bool isMarigoldGenusOnlyAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return marigoldGenusOnlyAliases.contains(v);
}
