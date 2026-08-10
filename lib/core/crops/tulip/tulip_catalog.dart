import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart';

/// Catálogo base del Tulipán (primera ornamental BULBOSA ESTACIONAL de BIO-G).
///
/// Solo metadata de catálogo: ids de perfil, etiquetas humanas y aliases. La
/// agronomía vive en `tulip_universal_profile.dart`, el reloj anual en
/// `tulip_engine.dart` y los riesgos/sanidad en `tulip_risk_catalog.dart` +
/// `tulip_syndromes.dart` (Documentos A/B/C del paquete Tulipán TU v1).
///
/// Regla central del Tulipán (Documento A §0, §1): es una geófita bulbosa
/// perenne en modo `seasonal_bulb`. El motor se parece al de los granos
/// (fecha ancla → día → etapa), pero el final es una DORMANCIA perenne, no
/// cosecha: el registro sobrevive al cierre y puede iniciar otra temporada.
const String kCropTulip = 'crop_tulip';

/// Id legacy/cropKey esperado del tulipán. Alias de compatibilidad.
const String kTulipLegacy = 'tulip';

/// Perfiles del tulipán, en el ORDEN EN QUE SE MUESTRAN AL USUARIO
/// (Documento A §8.1, §11.2). Los tipos concretos primero (TU-01 a TU-05) y
/// **al final** la salida "No sé / Tulipán general". El perfil general/SKIP
/// va SIEMPRE disponible y NUNCA muestra al usuario la palabra "SKIP" ni el
/// profileId. Sigue siendo el `defaultProfileId`: si el usuario no elige, cae
/// aquí.
const List<CropProfileEntry> tulipProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kTu01GardenExterior,
    label: 'Tulipán de jardín',
    cropId: kCropTulip,
    subtitle:
        'Tulipán para suelo exterior, en camas, bordes y macizos de temporada '
        '(tulipán de jardín, triumph)',
    aliases: <String>[
      'TU-01',
      'TU01',
      'tu_01',
      'TL-01',
      'tulipan de jardin',
      'tulipán de jardín',
      'tulipan clasico',
      'tulipan normal',
      'tulipan para suelo',
      'tulipan exterior',
      'tulipan de macizo',
      'triumph',
      'darwin hybrid',
      'fosteriana',
      'single early',
      'single late',
    ],
  ),
  CropProfileEntry(
    id: kTu02DecorativeContainer,
    label: 'Tulipán en maceta',
    cropId: kCropTulip,
    subtitle:
        'Tulipán cultivado en maceta o contenedor decorativo para patio, '
        'terraza o balcón',
    aliases: <String>[
      'TU-02',
      'TU02',
      'tu_02',
      'TL-02',
      'tulipan en maceta',
      'tulipán en maceta',
      'tulipan para patio',
      'tulipan decorativo',
      'tulipan en contenedor',
      'tulipan de balcon',
      'tulipán de balcón',
      'maceta de tulipanes',
    ],
  ),
  CropProfileEntry(
    id: kTu03ForcedIndoor,
    label: 'Tulipán forzado de interior',
    cropId: kCropTulip,
    subtitle:
        'Tulipán preenfriado o forzado en maceta para que florezca dentro de '
        'casa (tulipán de regalo, ya brotado)',
    aliases: <String>[
      'TU-03',
      'TU03',
      'tu_03',
      'TL-03',
      'tulipan de interior',
      'tulipan forzado',
      'tulipan preenfriado',
      'tulipan de refri',
      'tulipan para regalo',
      'tulipan ya brotado',
      'tulipan de supermercado',
    ],
  ),
  CropProfileEntry(
    id: kTu04CutFlower,
    label: 'Tulipán para flor de corte',
    cropId: kCropTulip,
    subtitle:
        'Tulipán de tallo largo y parejo para flor de corte, ramo y florería, '
        'con ventana de corte definida',
    aliases: <String>[
      'TU-04',
      'TU04',
      'tu_04',
      'TL-04',
      'tulipan para corte',
      'tulipan de floreria',
      'tulipán de florería',
      'tulipan de tallo largo',
      'tulipan de invernadero',
      'tulipan para ramo',
      'tulipan comercial',
    ],
  ),
  CropProfileEntry(
    id: kTu05SpecialPremium,
    label: 'Tulipán especial o premium',
    cropId: kCropTulip,
    subtitle:
        'Tulipán de flor grande o delicada, doble o tipo peonía, loro o con '
        'flecos (parrot, fringed)',
    aliases: <String>[
      'TU-05',
      'TU05',
      'tu_05',
      'TL-05',
      'tulipan doble',
      'tulipan peonia',
      'tulipán peonía',
      'tulipan loro',
      'parrot tulip',
      'tulipan con flecos',
      'fringed tulip',
      'tulipan lily-flowered',
      'tulipan viridiflora',
      'tulipan exotico',
      'tulipan premium',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kTuSkip,
    label: 'No sé / Tulipán general',
    cropId: kCropTulip,
    subtitle:
        'Perfil general y migrable para bulbos sin etiqueta, precisas si es de '
        'jardín, maceta o corte sin perder historial',
    aliases: <String>[
      'TU-SKIP',
      'TU_SKIP',
      'TUSKIP',
      'TL-GEN',
      'TU-GEN',
      'tulipan',
      'tulipán',
      'tulipanes',
      'bulbo de tulipan',
      'bulbo de tulipán',
      'tulipa',
      'tulipa spp',
      'otro tulipan',
      'no se que tulipan es',
      'no sé qué tulipán es',
      'tulipan general',
      'tulipán general',
    ],
  ),
];

/// Aliases de ENTRADA que NO son Tulipa y NO deben mapear a `crop_tulip`
/// (Documento A §18.2). Se excluyen del alta automática y requieren
/// confirmación explícita del usuario.
const List<String> tulipNotATulipRedirectAliases = <String>[
  'arbol de tulipan',
  'árbol de tulipán',
  'tulip tree',
  'liriodendron',
  'liriodendron tulipifera',
  'tulipan africano',
  'tulipán africano',
  'spathodea',
  'spathodea campanulata',
  'tulipan mexicano',
  'tulipán mexicano',
  'amarilis',
  'amaryllis',
  'narciso',
  'jacinto',
  'crocus',
  'lirio',
];

/// True si el alias corresponde a una planta llamada "tulipán" que NO es del
/// género Tulipa (no debe mapear a crop_tulip sin confirmación).
bool isTulipNotATulipAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return tulipNotATulipRedirectAliases.contains(v);
}
