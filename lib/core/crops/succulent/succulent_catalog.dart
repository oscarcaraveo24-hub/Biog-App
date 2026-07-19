import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base de la Suculenta ornamental (segunda ornamental oficial de
/// BIO-G, modo `establishment_maintenance`).
///
/// Solo contiene metadata de catálogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomía vive en `succulent_universal_profile.dart`, el ciclo en
/// `succulent_lifecycle.dart` y los riesgos en `succulent_risk_catalog.dart`
/// (Documentos A/B/C del paquete Suculenta SU v1.0).
///
/// Regla ornamental central (Doc A §0.2): la suculenta es una planta perenne no
/// cactácea con hojas y/o tallos carnosos. No usa fecha de siembra ni cosecha;
/// el eje es etapa (instalación → raíz → crecimiento → mantenimiento abierto).
/// El HARDWARE es la fuente de verdad para humedad, NPK, EC y temperatura.
const String kCropSucculent = 'crop_succulent';

/// Id legacy/cropKey esperado de la suculenta. Se conserva como alias de
/// compatibilidad (Doc A §0.2, §15).
const String kSucculentLegacy = 'succulent';

const String kSuSkip = 'su_skip';
const String kSucculentProfilePrefix = 'SU';
const String kSu01RosetteBrightLight = 'su_01_rosette_bright_light';
const String kSu02TrailingCascading = 'su_02_trailing_cascading';
const String kSu03BranchingWoody = 'su_03_branching_woody';
const String kSu04CompactFilteredLight = 'su_04_compact_filtered_light';

/// Perfiles de la suculenta, en el ORDEN EN QUE SE MUESTRAN AL USUARIO
/// (Doc A §3: orden visible obligatorio).
///
/// Primero los cuatro tipos concretos (SU-01 … SU-04) y **al final** la salida
/// "No sé / suculenta general". Un menú que abre con "No sé" invita a no elegir;
/// el general es la red de seguridad, no la primera opción.
///
/// El perfil general (`su_skip`) sigue siendo el `defaultProfileId` del cultivo:
/// si el usuario no elige, cae aquí. NUNCA se le muestra la palabra "SKIP" ni el
/// profileId (Doc A §2.1, §8).
const List<CropProfileEntry> succulentProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kSu01RosetteBrightLight,
    label: 'Suculenta de roseta',
    cropId: kCropSucculent,
    subtitle:
        'Hojas carnosas acomodadas desde el centro, como rosa de piedra. '
        'Pide mucha luz y drenaje libre; el agua atrapada en el centro es su '
        'mayor riesgo.',
    aliases: <String>[
      'SU-01',
      'SU01',
      'su_01',
      'echeveria',
      'echeveria elegans',
      'echeveria agavoides',
      'graptopetalum',
      'graptopetalum paraguayense',
      'pachyphytum',
      'graptoveria',
      'graptosedum',
      'rosa de piedra',
      'suculenta en forma de rosa',
      'planta fantasma',
      'sempervivum',
      'suculenta de roseta',
      'sedum de roseta',
      'kalanchoe de roseta',
    ],
  ),
  CropProfileEntry(
    id: kSu02TrailingCascading,
    label: 'Suculenta colgante',
    cropId: kCropSucculent,
    subtitle:
        'Tallos que caen de la maceta o avanzan sobre el sustrato. La maceta '
        'colgante puede secarse desigual: la corona sigue húmeda aunque las '
        'puntas se vean secas.',
    aliases: <String>[
      'SU-02',
      'SU02',
      'su_02',
      'sedum morganianum',
      'sedum burrito',
      'cola de burro',
      'cola de borrego',
      'curio rowleyanus',
      'senecio rowleyanus',
      'cadena de perlas',
      'collar de perlas',
      'rosario',
      'curio radicans',
      'senecio radicans',
      'cadena de bananas',
      'suculenta colgante',
      'suculenta de cascada',
      'suculenta rastrera',
    ],
  ),
  CropProfileEntry(
    id: kSu03BranchingWoody,
    label: 'Suculenta tipo jade o ramificada',
    cropId: kCropSucculent,
    subtitle:
        'Tallos gruesos con forma de arbusto pequeño. Tolera periodos secos, '
        'pero no el agua retenida; con la edad el tallo se pone leñoso y eso es '
        'normal.',
    aliases: <String>[
      'SU-03',
      'SU03',
      'su_03',
      'crassula ovata',
      'crassula',
      'arbol de jade',
      'árbol de jade',
      'planta de jade',
      'jade',
      'crassula arborescens',
      'portulacaria afra',
      'jade enano',
      'arbusto elefante',
      'suculenta arbustiva',
      'suculenta ramificada',
      'kalanchoe tomentosa',
      'aeonium arboreum',
      'cotyledon',
    ],
  ),
  CropProfileEntry(
    id: kSu04CompactFilteredLight,
    label: 'Suculenta compacta de luz filtrada',
    cropId: kCropSucculent,
    subtitle:
        'Roseta pequeña de hojas firmes, rayadas o con ventanas translúcidas. '
        'Mucha claridad sin sol fuerte; crece despacio y el sustrato debe '
        'secarse entre riegos.',
    aliases: <String>[
      'SU-04',
      'SU04',
      'su_04',
      'haworthia',
      'haworthiopsis',
      'haworthiopsis fasciata',
      'haworthiopsis attenuata',
      'planta cebra',
      'haworthia cebra',
      'gasteria',
      'tulista',
      'suculenta de ventana',
      'suculenta compacta',
      'suculenta compacta de sombra luminosa',
      'suculenta de luz filtrada',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kSuSkip,
    label: 'No sé / suculenta general',
    cropId: kCropSucculent,
    subtitle:
        'Perfil general y migrable: usaremos un manejo prudente y podrás elegir '
        'su forma después sin perder la fecha ni el historial.',
    aliases: <String>[
      'SU-SKIP',
      'SU_SKIP',
      'SUSKIP',
      'suculenta',
      'suculentas',
      'planta suculenta',
      'planta crasa',
      'crasa',
      'suculenta general',
      'otra suculenta',
      'no se que suculenta es',
      'no sé qué suculenta es',
      'suculenta sin identificar',
      'me la vendieron como suculenta',
      'suculenta desconocida',
    ],
  ),
];

/// Aliases de ENTRADA que NO deben mapear silenciosamente a un perfil SU: son
/// cultivos que BIO-G modela (o modelará) por separado (Doc A §1.4, §4.4).
const List<String> succulentCactusRedirectAliases = <String>[
  'cactus',
  'cactacea',
  'cactácea',
  'cactaceae',
  'cactus de navidad',
  'schlumbergera',
  'rhipsalis',
  'epiphyllum',
  'euphorbia cactus',
];

const List<String> succulentNopalRedirectAliases = <String>[
  'nopal',
  'opuntia',
  'orejas de conejo',
];

// Redirección a `crop_aloe` (tercera ornamental). Se amplió al integrar la
// sábila (Doc A §10): sin estos aliases, un usuario que escriba "aloe
// arborescens" en el flujo de suculenta quedaría con targets de suculenta en
// lugar de ser redirigido a Sábila.
const List<String> succulentAloeRedirectAliases = <String>[
  'sabila',
  'sábila',
  'zabila',
  'zábila',
  'aloe',
  'aloe vera',
  'aloe barbadensis',
  'barbadensis miller',
  'aloe arborescens',
  'aloe maculata',
  'aloe saponaria',
  'aloe brevifolia',
  'sábila pulpo',
  'sábila jabonera',
  'sábila cebra',
  'aloe sp.',
  'aloe hybrid',
];

const List<String> succulentAgaveRedirectAliases = <String>[
  'maguey',
  'agave',
];

/// Grupos diferidos: requieren ficha especializada y NO entran a un perfil SU
/// v1 (Doc A §1.5, §4.4). Se permite `su_skip` solo con advertencia.
const List<String> succulentDeferredGroupAliases = <String>[
  'lithops',
  'conophytum',
  'piedra viva',
  'piedras vivas',
  'pleiospilos',
  'adenium',
  'rosa del desierto',
  'sansevieria',
  'lengua de suegra',
  'hoya',
  'dischidia',
  'peperomia',
  'euphorbia',
];

bool _matchesAlias(String? raw, List<String> aliases) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return aliases.contains(v);
}

/// True si el alias corresponde a un cactus (redirige a `crop_cactus`).
bool isSucculentCactusAlias(String? raw) =>
    _matchesAlias(raw, succulentCactusRedirectAliases);

/// True si el alias corresponde a nopal/Opuntia (redirige a `crop_nopal`).
bool isSucculentNopalAlias(String? raw) =>
    _matchesAlias(raw, succulentNopalRedirectAliases);

/// True si el alias corresponde a sábila/Aloe (redirige a `crop_aloe`).
bool isSucculentAloeAlias(String? raw) =>
    _matchesAlias(raw, succulentAloeRedirectAliases);

/// True si el alias corresponde a maguey/Agave (redirige a `crop_agave`).
bool isSucculentAgaveAlias(String? raw) =>
    _matchesAlias(raw, succulentAgaveRedirectAliases);

/// True si el alias pertenece a un grupo diferido (Lithops, caudiciformes,
/// epífitas suculentas, Sansevieria, Peperomia…). No se le asigna un perfil
/// específico en silencio.
bool isSucculentDeferredGroupAlias(String? raw) =>
    _matchesAlias(raw, succulentDeferredGroupAliases);

/// True si el alias debe redirigirse a OTRO cultivo de BIO-G.
bool isSucculentRedirectAlias(String? raw) =>
    isSucculentCactusAlias(raw) ||
    isSucculentNopalAlias(raw) ||
    isSucculentAloeAlias(raw) ||
    isSucculentAgaveAlias(raw);
