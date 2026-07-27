import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base del Nopal ornamental (octava ornamental oficial de BIO-G,
/// quinta del modo `establishment_maintenance`).
///
/// Solo contiene metadata de catálogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomía vive en `nopal_universal_profile.dart`, el ciclo en
/// `nopal_lifecycle.dart` y los riesgos en `nopal_risk_catalog.dart`
/// (Documentos A/B/C del paquete Nopal NO v1.0).
///
/// Identidad congelada (Doc A §0.1): `cropId = crop_nopal`, `CropKey = nopal`,
/// prefijo de perfil `NO`, nombre visible "Nopal". Sin fecha de siembra ni
/// cosecha; el eje es etapa (instalación → raíz → crecimiento → mantenimiento
/// abierto).
///
/// ALCANCE ORNAMENTAL (Doc A §0.3): BIO-G cuida la planta; el usuario decide
/// cuándo cortar una penca o retirar una tuna. Cortar NO es cosecha, NO reinicia
/// el ciclo y NO cambia el stageId. BIO-G no proyecta rendimiento de nopalito,
/// tuna, xoconostle, forraje ni cochinilla, y no certifica comestibilidad.
const String kCropNopal = 'crop_nopal';

/// Id legacy/cropKey esperado del nopal. Se conserva como alias de
/// compatibilidad (Doc A §2.1, §8.3): las fichas históricas usaban `orn_nopal`
/// y el prefijo `NP`. Los datos nuevos se persisten con `crop_nopal` y `NO`.
const String kNopalLegacy = 'orn_nopal';

const String kNopalSkip = 'no_skip';
const String kNopalProfilePrefix = 'NO';
const String kNopal01CompactClumpingContainer =
    'no_01_compact_clumping_container';
const String kNopal02UprightLargePadWarm = 'no_02_upright_large_pad_warm';
const String kNopal03DesertShrubSpinyLandscape =
    'no_03_desert_shrub_spiny_landscape';
const String kNopal04LowSpreadingColdHardy = 'no_04_low_spreading_cold_hardy';

/// Perfiles del nopal, en el ORDEN EN QUE SE MUESTRAN AL USUARIO
/// (Doc A §6: orden visible obligatorio).
///
/// Primero los cuatro tipos concretos (NO-01 … NO-04) y **al final** la salida
/// "No sé / nopal general". El general es la red de seguridad, no la primera
/// opción.
///
/// Los perfiles se separan por ARQUITECTURA (porte, tamaño de penca, patrón de
/// expansión y representatividad del sensor), NUNCA por maceta/jardín (eso es
/// `cultivationContext`), edad (eso es etapa), color, precio, número de espinas
/// ni finalidad alimentaria (Doc A §0.4, §5).
///
/// El perfil general (`no_skip`) sigue siendo el `defaultProfileId` del cultivo:
/// si el usuario no elige, cae aquí. NUNCA se le muestra la palabra "SKIP" ni el
/// profileId (Doc A §6.5).
const List<CropProfileEntry> nopalProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kNopal01CompactClumpingContainer,
    label: 'Nopal compacto o agrupado',
    cropId: kCropNopal,
    subtitle:
        'Pencas pequeñas o medianas que forman grupos; común en maceta y '
        'rocalla. Los puntos que parecen pelusa sueltan gloquidios: no lo '
        'toques con la mano.',
    aliases: <String>[
      'NO-01',
      'NO01',
      'no_01',
      'opuntia microdasys',
      'o. microdasys',
      'opuntia microdasys albispina',
      'opuntia microdasys pallida',
      'opuntia microdasys rufida',
      'opuntia rufida',
      'orejas de conejo',
      'oreja de conejo',
      'bunny ears',
      'bunny ears cactus',
      'rabbit ears cactus',
      'alas de ángel',
      'alas de angel',
      'angel wings cactus',
      'nopal cegador',
      'nopalillo cegador',
      'nopal mini',
      'nopal enano',
      'nopal compacto',
      'cactus de orejas',
      'orejas de mickey',
      'polka dot cactus',
    ],
  ),
  CropProfileEntry(
    id: kNopal02UprightLargePadWarm,
    label: 'Nopal alto o de penca grande',
    cropId: kCropNopal,
    subtitle:
        'Pencas amplias y porte erguido; común en jardín, maceta grande o '
        'cerco. Con el tamaño ganan importancia el anclaje y la raíz extendida: '
        'una sonda solo describe su zona.',
    aliases: <String>[
      'NO-02',
      'NO02',
      'no_02',
      'opuntia ficus-indica',
      'opuntia ficus indica',
      'o. ficus-indica',
      'nopal de castilla',
      'chumbera',
      'higuera de pala',
      'higo chumbo',
      'indian fig',
      'indian fig opuntia',
      'mission cactus',
      'nopal manso',
      'nopal sin espinas',
      'nopal de huerta',
      'nopal orejón',
      'nopal orejon',
      'nopal oreja de elefante',
      'opuntia cochenillifera',
      'nopalea cochenillifera',
      'opuntia monacantha',
      'nopal alto',
      'nopal grande',
      'nopal arborescente',
      'nopal de cerco',
      'cerco de nopal',
      'nopalera alta',
    ],
  ),
  CropProfileEntry(
    id: kNopal03DesertShrubSpinyLandscape,
    label: 'Nopal arbustivo de paisaje',
    cropId: kCropNopal,
    subtitle:
        'Forma matas amplias, con pencas medianas y espinas o color ornamental. '
        'El color morado puede ser estacional y no indica enfermedad.',
    aliases: <String>[
      'NO-03',
      'NO03',
      'no_03',
      'opuntia engelmannii',
      'o. engelmannii',
      'engelmann prickly pear',
      'desert prickly pear',
      'opuntia santa-rita',
      'opuntia santa rita',
      'o. santa-rita',
      'santa rita prickly pear',
      'nopal santa rita',
      'opuntia macrocentra',
      'o. macrocentra',
      'purple prickly pear',
      'opuntia phaeacantha',
      'o. phaeacantha',
      'brown-spine prickly pear',
      'tulip prickly pear',
      'nopal espinudo',
      'nopal de paisaje',
      'nopal de desierto',
      'nopal de jardín seco',
      'nopal de jardin seco',
      'nopal arbustivo',
      'nopal de mata',
    ],
  ),
  CropProfileEntry(
    id: kNopal04LowSpreadingColdHardy,
    label: 'Nopal bajo o rastrero',
    cropId: kCropNopal,
    subtitle:
        'Pencas cercanas al suelo que se extienden; algunas formas pasan '
        'inviernos fríos. El encogimiento y la postura baja en invierno pueden '
        'ser normales, no colapso.',
    aliases: <String>[
      'NO-04',
      'NO04',
      'no_04',
      'opuntia humifusa',
      'o. humifusa',
      'eastern prickly pear',
      'eastern prickly-pear',
      'low prickly pear',
      'opuntia mesacantha',
      'o. mesacantha',
      'southeastern prickly pear',
      'opuntia polyacantha',
      'o. polyacantha',
      'plains prickly pear',
      'opuntia fragilis',
      'o. fragilis',
      'brittle prickly pear',
      'fragile prickly pear',
      'opuntia macrorhiza',
      'o. macrorhiza',
      'opuntia aurea',
      'opuntia basilaris',
      'beavertail prickly pear',
      'nopal rastrero',
      'nopal bajo',
      'nopal extendido',
      'nopal tapizante',
      'nopal de suelo',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kNopalSkip,
    label: 'No sé / nopal general',
    cropId: kCropNopal,
    subtitle:
        'Perfil general y migrable: usaremos un manejo prudente y podrás elegir '
        'su forma después sin perder la fecha ni el historial.',
    aliases: <String>[
      'NO-SKIP',
      'NO_SKIP',
      'NOSKIP',
      'nopal',
      'nopales',
      'planta de nopal',
      'opuntia',
      'opuntia sp.',
      'opuntia spp.',
      'prickly pear',
      'cactus pear',
      'nopal ornamental',
      'otro nopal',
      'nopal general',
      'nopal sin identificar',
      'opuntia sin identificar',
      'no sé qué nopal es',
      'no se que nopal es',
      'me lo vendieron como nopal',
      'me regalaron una penca',
      'nopal heredado',
      'nopal rescatado',
    ],
  ),
];

/// Aliases que NO deciden un perfil por sí solos (Doc A §8.4).
///
/// Describen contexto, color, uso o finalidad, no arquitectura. Van a `no_skip`
/// o requieren pregunta visual. NUNCA se mapean en silencio a NO-01…NO-04: un
/// "nopal de maceta" puede ser compacto, rastrero o una ficus-indica joven.
const List<String> nopalAmbiguousProfileAliases = <String>[
  'nopal común',
  'nopal comun',
  'nopal criollo',
  'nopal tradicional',
  'nopal silvestre',
  'nopal de jardín',
  'nopal de jardin',
  'nopal de maceta',
  'nopal de patio',
  'nopal morado',
  'nopal blanco',
  'nopal pelón',
  'nopal pelon',
  'nopal decorativo',
  'nopal decorativo pequeño',
  'nopal decorativo pequeno',
  'nopal de colección',
  'nopal de coleccion',
  'nopal crestado',
  'microdasys cristata',
  'nopal de cerro',
  'nopal de coyote',
  'nopal duraznillo',
  'nopal cardón',
  'nopal cardon',
  'nopal tapón',
  'nopal tapon',
  'opuntia streptacantha',
  'opuntia leucotricha',
  'opuntia robusta',
  'opuntia erinacea',
  'hardy prickly pear',
  'nopal resistente al frío',
  'nopal resistente al frio',
  'nopal de invierno',
  'nopal italiano',
  'penca',
];

/// Nombres de finalidad PRODUCTIVA (Doc A §4.6). No están fuera de alcance por
/// la planta, sino por el objetivo: BIO-G v1 solo continúa si el seguimiento es
/// ornamental. Requieren la pregunta "¿ornamental o producción?" antes de
/// resolver perfil, y nunca infieren comestibilidad.
const List<String> nopalProductiveIntentAliases = <String>[
  'tuna',
  'tunas',
  'xoconostle',
  'nopalito',
  'nopalitos',
  'nopal verdura',
  'nopal forrajero',
  'nopal de cochinilla',
  'nopal de tuna',
  'penca para comer',
];

/// Opuntioides DIFERIDOS (Doc A §4.4): segmentos cilíndricos o arquitecturas
/// tropicales que NO deben entrar en silencio a un perfil NO. Requieren ficha
/// propia en el futuro.
const List<String> nopalDeferredGroupAliases = <String>[
  'cylindropuntia',
  'cholla',
  'cardenche',
  'austrocylindropuntia',
  'tephrocactus',
  'brasiliopuntia',
  'consolea',
  'tacinga',
];

/// Aliases de ENTRADA que NO deben mapear a un perfil NO: son cultivos que BIO-G
/// ya modela por separado (Doc A §4.5, §8.6). Parecerse a un nopal no basta.
const List<String> nopalAgaveRedirectAliases = <String>[
  'maguey',
  'magueyes',
  'agave',
  'agaves',
];

const List<String> nopalAloeRedirectAliases = <String>[
  'sabila',
  'sábila',
  'zabila',
  'zábila',
  'aloe',
  'aloe vera',
];

const List<String> nopalCactusRedirectAliases = <String>[
  'cactus',
  'cactacea',
  'cactácea',
  'cactaceae',
  'biznaga',
  'cactus barril',
  'cactus columnar',
  'órgano',
  'organo',
];

const List<String> nopalSucculentRedirectAliases = <String>[
  'suculenta',
  'crasa',
  'echeveria',
  'crassula',
  'haworthia',
];

/// Cactáceas epífitas o trepadoras fuera de alcance (Doc A §4.5). No son nopal
/// aunque compartan familia.
const List<String> nopalOutOfScopeCactusAliases = <String>[
  'pitahaya',
  'pitaya',
  'fruta del dragón',
  'fruta del dragon',
  'dragon fruit',
  'hylocereus',
  'selenicereus',
  'epiphyllum',
  'rhipsalis',
  'schlumbergera',
  'cactus de navidad',
];

bool _matchesAlias(String? raw, List<String> aliases) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return aliases.contains(v);
}

/// True si el alias corresponde a maguey/agave (redirige a `crop_agave`).
bool isNopalAgaveAlias(String? raw) =>
    _matchesAlias(raw, nopalAgaveRedirectAliases);

/// True si el alias corresponde a sábila/Aloe (redirige a `crop_aloe`).
bool isNopalAloeAlias(String? raw) =>
    _matchesAlias(raw, nopalAloeRedirectAliases);

/// True si el alias corresponde a un cactus globoso/columnar (redirige a
/// `crop_cactus`).
bool isNopalCactusAlias(String? raw) =>
    _matchesAlias(raw, nopalCactusRedirectAliases);

/// True si el alias corresponde a una suculenta no cactácea (redirige a
/// `crop_succulent`).
bool isNopalSucculentAlias(String? raw) =>
    _matchesAlias(raw, nopalSucculentRedirectAliases);

/// True si el alias es una cactácea epífita/trepadora fuera de Nopal v1.
bool isNopalOutOfScopeCactusAlias(String? raw) =>
    _matchesAlias(raw, nopalOutOfScopeCactusAliases);

/// True si el alias pertenece a un opuntioide diferido (cholla, cardenche,
/// Tephrocactus…). No se le asigna un perfil NO en silencio (Doc A §4.4).
bool isNopalDeferredGroupAlias(String? raw) =>
    _matchesAlias(raw, nopalDeferredGroupAliases);

/// True si el alias describe una finalidad productiva (tuna, nopalito,
/// xoconostle, forraje, cochinilla). Requiere preguntar el objetivo antes de
/// continuar (Doc A §4.6).
bool isNopalProductiveIntentAlias(String? raw) =>
    _matchesAlias(raw, nopalProductiveIntentAliases);

/// True si el alias NO alcanza para decidir un perfil concreto (Doc A §8.4):
/// describe contexto, color o uso, no arquitectura. Debe caer en `no_skip`.
bool isNopalAmbiguousProfileAlias(String? raw) =>
    _matchesAlias(raw, nopalAmbiguousProfileAliases);

/// True si el alias debe redirigirse a OTRO cultivo de BIO-G.
bool isNopalRedirectAlias(String? raw) =>
    isNopalAgaveAlias(raw) ||
    isNopalAloeAlias(raw) ||
    isNopalCactusAlias(raw) ||
    isNopalSucculentAlias(raw);

/// Pregunta desambiguadora de la palabra "penca" (Doc A §4.5). La misma palabra
/// se usa para nopal y para maguey; no se resuelve por el nombre.
const String kNopalPencaDisambiguationQuestion =
    '¿Tiene paletas planas unidas entre sí o una roseta de hojas largas?';

/// Pregunta de finalidad (Doc A §4.6). En v1 solo continúa el seguimiento
/// ornamental.
const String kNopalPurposeQuestion =
    '¿Quieres dar seguimiento a la planta como ornamental o a su producción?';
