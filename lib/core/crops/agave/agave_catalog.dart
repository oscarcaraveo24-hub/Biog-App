import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base del Maguey / Agave ornamental (cuarta ornamental oficial de
/// BIO-G, modo `establishment_maintenance`).
///
/// Solo contiene metadata de catálogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomía vive en `agave_universal_profile.dart`, el ciclo en
/// `agave_lifecycle.dart` y los riesgos en `agave_risk_catalog.dart`
/// (Documentos A/B/C del paquete Maguey MG v1.0).
///
/// Identidad congelada (Doc A §0.2, §21): `cropId = crop_agave`,
/// `CropKey = agave`, prefijo de perfil `MG`, nombre visible "Maguey". Sin fecha
/// de siembra ni cosecha; el eje es etapa (instalación → raíz → crecimiento →
/// mantenimiento abierto). BIO-G da seguimiento de la planta, NO certifica
/// especie, denominación de origen ni fecha de jima.
const String kCropAgave = 'crop_agave';

/// Id legacy/cropKey esperado del maguey. Se conserva como alias de
/// compatibilidad (Doc A §0.2).
const String kAgaveLegacy = 'agave';

const String kAgaveSkip = 'mg_skip';
const String kAgaveProfilePrefix = 'MG';
const String kAgave01CompactSculptural = 'mg_01_compact_sculptural';
const String kAgave02LargeSpinyLandscape = 'mg_02_large_spiny_landscape';
const String kAgave03BlueNarrowField = 'mg_03_blue_narrow_field';
const String kAgave04SoftSpinelessWarm = 'mg_04_soft_spineless_warm';

/// Perfiles del maguey, en el ORDEN EN QUE SE MUESTRAN AL USUARIO
/// (Doc A §4: orden visible obligatorio).
///
/// Primero los cuatro tipos concretos (MG-01 … MG-04) y **al final** la salida
/// "No sé / maguey general". El general es la red de seguridad, no la primera
/// opción; nunca se antepone "tequilero" ni se induce un destino productivo.
///
/// El perfil general (`mg_skip`) sigue siendo el `defaultProfileId` del cultivo:
/// si el usuario no elige, cae aquí. NUNCA se le muestra la palabra "SKIP" ni el
/// profileId (Doc A §3.1, §4).
const List<CropProfileEntry> agaveProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kAgave01CompactSculptural,
    label: 'Maguey compacto',
    cropId: kCropAgave,
    subtitle:
        'Roseta pequeña o mediana, rígida y de crecimiento lento. Pide '
        'excelente salida de agua; el tamaño reducido no significa que sea '
        'joven.',
    aliases: <String>[
      'MG-01',
      'MG01',
      'mg_01',
      'maguey compacto',
      'agave compacto',
      'agave de colección',
      'maguey de rocalla',
      'agave reina victoria',
      'agave victoriae-reginae',
      'agave parryi',
      'agave parryi truncata',
      'agave potatorum',
      'agave isthmensis',
      'agave titanota',
      'agave parrasana',
      'maguey de maceta',
      'agave geométrico',
      'agave enano',
      'agave mini',
    ],
  ),
  CropProfileEntry(
    id: kAgave02LargeSpinyLandscape,
    label: 'Maguey grande de paisaje',
    cropId: kCropAgave,
    subtitle:
        'Roseta amplia, hojas fuertes y mucho espacio de crecimiento. Con el '
        'porte ganan importancia el anclaje y dejar espacio libre alrededor de '
        'las puntas.',
    aliases: <String>[
      'MG-02',
      'MG02',
      'mg_02',
      'maguey grande',
      'agave grande',
      'maguey de paisaje',
      'maguey de jardín',
      'maguey americano',
      'agave americana',
      'century plant',
      'planta del siglo',
      'agave salmiana',
      'agave mapisaga',
      'agave ovatifolia',
      'maguey ancho',
      'maguey de lindero',
      'maguey de metepantle',
    ],
  ),
  CropProfileEntry(
    id: kAgave03BlueNarrowField,
    label: 'Maguey azul o de hoja angosta',
    cropId: kCropAgave,
    subtitle:
        'Hojas largas y estrechas, común en campo y paisaje. El color azul no '
        'confirma especie; BIO-G acompaña la planta, no certifica tequila ni '
        'jima.',
    aliases: <String>[
      'MG-03',
      'MG03',
      'mg_03',
      'agave tequilana',
      'agave tequilana weber',
      'agave tequilana weber variedad azul',
      'agave azul',
      'blue weber',
      'weber azul',
      'agave angustifolia',
      'agave fourcroydes',
      'agave sisalana',
      'maguey de hoja angosta',
      'agave de hoja angosta',
    ],
  ),
  CropProfileEntry(
    id: kAgave04SoftSpinelessWarm,
    label: 'Maguey de hoja suave',
    cropId: kCropAgave,
    subtitle:
        'Hojas flexibles o casi sin espinas; más sensible al frío fuerte. Sin '
        'espinas no significa sin punta ni riesgo en todas las formas.',
    aliases: <String>[
      'MG-04',
      'MG04',
      'mg_04',
      'maguey de hoja suave',
      'agave suave',
      'agave sin espinas',
      'agave cola de zorro',
      'cola de zorro',
      'agave attenuata',
      'agave desmettiana',
      'agave geminiflora',
      'agave bracteosa',
      'agave ornamental suave',
      'agave de sombra',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kAgaveSkip,
    label: 'No sé / maguey general',
    cropId: kCropAgave,
    subtitle:
        'Perfil general y migrable: usaremos un manejo prudente y podrás elegir '
        'su forma después sin perder la fecha ni el historial.',
    aliases: <String>[
      'MG-SKIP',
      'MG_SKIP',
      'MGSKIP',
      'maguey',
      'agave',
      'planta de maguey',
      'planta de agave',
      'otro maguey',
      'otro agave',
      'maguey general',
      'agave general',
      'maguey sin identificar',
      'agave sin identificar',
      'no sé qué maguey es',
      'no se que maguey es',
      'me lo vendieron como maguey',
      'me lo vendieron como agave',
    ],
  ),
];

/// Aliases de ENTRADA que NO deben mapear silenciosamente a un perfil MG: son
/// cultivos que BIO-G modela (o modelará) por separado (Doc A §2.5, §5.5).
const List<String> agaveAloeRedirectAliases = <String>[
  'sabila',
  'sábila',
  'zabila',
  'zábila',
  'aloe',
  'aloe vera',
  'acíbar',
  'acibar',
];

const List<String> agaveNopalRedirectAliases = <String>[
  'nopal',
  'opuntia',
  'penca de nopal',
];

const List<String> agaveCactusRedirectAliases = <String>[
  'cactus',
  'cactacea',
  'cactácea',
  'cactaceae',
  'biznaga',
  'órgano',
  'organo',
  'pitaya',
];

const List<String> agaveSucculentRedirectAliases = <String>[
  'suculenta',
  'crasa',
  'haworthia',
  'gasteria',
];

/// Grupos fuera del género o fuera de alcance (Doc A §2.5, §5.5). Parecerse a un
/// agave no basta: NO se resuelven por nombre a un perfil MG. Requieren ficha
/// especializada o quedan fuera de v1.
const List<String> agaveDeferredGroupAliases = <String>[
  'yuca',
  'izote',
  'yucca',
  'sotol',
  'dasylirion',
  'sereque',
  'nolina',
  'beaucarnea',
  'pata de elefante',
  'furcraea',
  'beschorneria',
  'dracaena',
  'sansevieria',
  'lengua de suegra',
  'cycas',
  'mangave',
  'manfreda',
  'polianthes',
  'nardo',
  'pita',
  'cabuya',
  'fique',
];

bool _matchesAlias(String? raw, List<String> aliases) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return aliases.contains(v);
}

/// True si el alias corresponde a sábila/Aloe (redirige a `crop_aloe`).
bool isAgaveAloeAlias(String? raw) =>
    _matchesAlias(raw, agaveAloeRedirectAliases);

/// True si el alias corresponde a nopal/Opuntia (redirige a `crop_nopal`).
bool isAgaveNopalAlias(String? raw) =>
    _matchesAlias(raw, agaveNopalRedirectAliases);

/// True si el alias corresponde a un cactus (redirige a `crop_cactus`).
bool isAgaveCactusAlias(String? raw) =>
    _matchesAlias(raw, agaveCactusRedirectAliases);

/// True si el alias corresponde a una suculenta no Agave (redirige a
/// `crop_succulent`).
bool isAgaveSucculentAlias(String? raw) =>
    _matchesAlias(raw, agaveSucculentRedirectAliases);

/// True si el alias pertenece a un grupo fuera de alcance (Yucca, sotol,
/// Beaucarnea, Furcraea, Sansevieria, Mangave…). No se le asigna un perfil MG en
/// silencio (Doc A §5.5, §5.6).
bool isAgaveDeferredGroupAlias(String? raw) =>
    _matchesAlias(raw, agaveDeferredGroupAliases);

/// True si el alias debe redirigirse a OTRO cultivo de BIO-G.
bool isAgaveRedirectAlias(String? raw) =>
    isAgaveAloeAlias(raw) ||
    isAgaveNopalAlias(raw) ||
    isAgaveCactusAlias(raw) ||
    isAgaveSucculentAlias(raw);
