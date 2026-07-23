import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';

/// Catálogo base del Rosal (primera ornamental de floración recurrente de BIO-G).
///
/// Solo contiene metadata de catálogo: ids de perfil, etiquetas humanas y
/// aliases. La agronomía vive en `rose_universal_profile.dart`, el ciclo en
/// `rose_lifecycle.dart` y los riesgos/sanidad en `rose_risk_catalog.dart`
/// (Documentos A/B/C del paquete Rosal RO v1).
///
/// Regla central del Rosal (Doc A §0.1, §3): es una planta leñosa perenne en
/// modo `recurring_bloom`. NO tiene cosecha, rendimiento ni etapa terminal.
/// Tras el establecimiento, la etapa NO se infiere por fecha: entra en un ciclo
/// recurrente (brote → botón → floración → post-floración → reposo) que el
/// usuario confirma de forma visual. El HARDWARE es la fuente de verdad para
/// humedad, NPK, EC y temperatura.
const String kCropRose = 'crop_rose';

/// Id legacy/cropKey esperado del rosal. Conservado como alias de compatibilidad
/// (Doc A §0.4, §17.6).
const String kRoseLegacy = 'rose';

const String kRoSkip = 'ro_skip';
const String kRoseProfilePrefix = 'RO';
const String kRo01MiniatureContainer = 'ro_01_miniature_container';
const String kRo02LargeFloweredBush = 'ro_02_large_flowered_bush';
const String kRo03ClusteredLandscape = 'ro_03_clustered_landscape';
const String kRo04RepeatClimber = 'ro_04_repeat_climber';

/// Perfiles del rosal, en el ORDEN EN QUE SE MUESTRAN AL USUARIO.
///
/// El orden importa: primero los tipos concretos (RO-01 a RO-04, el orden
/// canónico del doc A §6) y **al final** la salida "No sé / rosal general".
/// El perfil general/SKIP va SIEMPRE disponible y NUNCA muestra al usuario la
/// palabra "SKIP" ni el profileId (Doc A §6.5). Sigue siendo el
/// `defaultProfileId` del cultivo: si el usuario no elige, cae aquí.
const List<CropProfileEntry> roseProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kRo01MiniatureContainer,
    label: 'Rosal mini o de maceta',
    cropId: kCropRose,
    subtitle:
        'Compacto, pequeño o cultivado en una maceta reducida. Raíz confinada, '
        'se seca más rápido y acumula más sales; sensible a lapsos de riego.',
    aliases: <String>[
      'RO-01',
      'RO01',
      'ro_01',
      'rosal mini',
      'rosal de maceta',
      'rosal miniatura',
      'rosa miniatura',
      'rosa de maceta',
      'mini rose',
      'miniature rose',
      'miniflora',
      'patio rose',
      // Compatibilidad: id provisional previo.
      'rose_mini',
      'RS-04',
    ],
  ),
  CropProfileEntry(
    id: kRo02LargeFloweredBush,
    label: 'Rosal de flor grande',
    cropId: kCropRose,
    subtitle:
        'Flores grandes, normalmente sobre tallos largos o erguidos. Oleadas de '
        'floración marcadas; la pérdida de botón afecta mucho el objetivo '
        'ornamental.',
    aliases: <String>[
      'RO-02',
      'RO02',
      'ro_02',
      'rosal de flor grande',
      'rosa de tallo largo',
      'hybrid tea',
      'té híbrido',
      'te hibrido',
      'grandiflora',
      'rosa de corte',
      'RS-02',
    ],
  ),
  CropProfileEntry(
    id: kRo03ClusteredLandscape,
    label: 'Rosal de flores en racimo o de jardín',
    cropId: kCropRose,
    subtitle:
        'Arbusto ramificado, muchas flores o uso en cama y paisaje. Floración '
        'abundante y casi continua; coexisten botones, flores y flores agotadas.',
    aliases: <String>[
      'RO-03',
      'RO03',
      'ro_03',
      'rosal de racimo',
      'rosal de jardin',
      'rosal de jardín',
      'floribunda',
      'polyantha',
      'poliantha',
      'landscape rose',
      'rosal de paisaje',
      'rosal arbustivo',
      'shrub rose',
      'knock out',
      // Compatibilidad: id provisional previo.
      'rose_jardin',
      'RS-01',
      'RS-03',
    ],
  ),
  CropProfileEntry(
    id: kRo04RepeatClimber,
    label: 'Rosal trepador',
    cropId: kCropRose,
    subtitle:
        'Cañas largas guiadas sobre muro, reja, arco o pérgola. El soporte es '
        'parte de su estado; debe florecer varias veces para entrar en este '
        'perfil.',
    aliases: <String>[
      'RO-04',
      'RO04',
      'ro_04',
      'rosal trepador',
      'rosa trepadora',
      'climbing rose',
      'climber',
      'rosal de pergola',
      'rosal de pérgola',
      'RS-05',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kRoSkip,
    label: 'No sé / rosal general',
    cropId: kCropRose,
    subtitle:
        'Perfil general y migrable del rosal: puedes precisar mini, flor grande, '
        'racimo o trepador después sin perder historial.',
    aliases: <String>[
      'RO-SKIP',
      'RO_SKIP',
      'ROSKIP',
      'rosal',
      'rosal general',
      'rosa',
      'rosales',
      'no se que rosal es',
      'no sé qué rosal es',
      'otro rosal',
      'rosal desconocido',
      'rosal sin identificar',
      // Compatibilidad de entrada: id provisional previo.
      'rose_generic',
      'RS-SKIP',
    ],
  ),
];

/// Aliases de ENTRADA que NO deben mapear silenciosamente a un Rosal: plantas
/// con "rosa" en el nombre que NO son del género Rosa (Doc A §1.3). Se reservan
/// para sus propios cultivos o quedan fuera de v1.
const List<String> roseNotARoseRedirectAliases = <String>[
  'rosa del desierto',
  'adenium',
  'adenium obesum',
  'rosa de jerico',
  'rosa de jericó',
  'rosa de navidad',
  'helleborus',
  'rosa de piedra',
  'echeveria',
  'portulaca',
  'rosa musgo',
  'rosa de siria',
  'hibiscus',
  'rosa de jamaica',
  'rosa de china',
  'jamaica',
  'primula',
  'primrose',
  'begonia',
  'peonia',
  'peonía',
];

/// Aliases de ENTRADA de rosales de floración ÚNICA (no recurrente). En v1 el
/// modo `recurring_bloom` cubre solo rosales que rebrotan; un rambler de
/// floración única se atiende como rosal general con aviso (Doc A §6.4, §17.4).
const List<String> roseOnceBloomingConfirmAliases = <String>[
  'rambler',
  'rambling rose',
  'rosal sarmentoso',
  'rosal liana',
  'rosa banksiae',
  'banksiae',
  'rosal antiguo trepador',
];

/// True si el alias corresponde a una planta llamada "rosa" que NO es del género
/// Rosa (no debe mapear a crop_rose).
bool isRoseNotARoseAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return roseNotARoseRedirectAliases.contains(v);
}

/// True si el alias corresponde a un rosal de floración única a confirmar.
bool isRoseOnceBloomingAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return roseOnceBloomingConfirmAliases.contains(v);
}
