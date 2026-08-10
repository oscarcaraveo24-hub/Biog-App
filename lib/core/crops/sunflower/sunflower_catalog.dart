import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

/// Catálogo base del Girasol (primera ornamental ANUAL VERDADERA de BIO-G).
///
/// Solo metadata de catálogo: ids de perfil, etiquetas humanas y aliases. La
/// agronomía vive en `sunflower_universal_profile.dart`, el reloj anual en
/// `sunflower_engine.dart` y los riesgos/sanidad en `sunflower_risk_catalog.dart`
/// + `sunflower_syndromes.dart` (Documentos A/B/C del paquete Girasol GI v1).
///
/// Regla central del Girasol (Documento A §0, §8): es *Helianthus annuus*, una
/// anual verdadera en modo `annual_ornamental`. El motor se parece al de los
/// granos y al del Tulipán (fecha ancla → día → etapa), pero el final es
/// `cycle_complete` TERMINAL, no dormancia: la planta cierra su ciclo y una nueva
/// temporada exige una nueva siembra. No proyecta rendimiento ni cosecha.
const String kCropSunflower = 'crop_sunflower';

/// Id legacy/cropKey esperado del girasol. Alias de compatibilidad.
const String kSunflowerLegacy = 'sunflower';

/// Perfiles del girasol, en el ORDEN EN QUE SE MUESTRAN AL USUARIO (Documento A
/// §13.1). Los tipos concretos primero (gi_01 a gi_04) y **al final** la salida
/// "No sé / Girasol general". El perfil general/SKIP va SIEMPRE disponible y
/// NUNCA muestra al usuario la palabra "SKIP" ni el profileId. Sigue siendo el
/// `defaultProfileId`: si el usuario no elige, cae aquí.
const List<CropProfileEntry> sunflowerProfileEntries = <CropProfileEntry>[
  CropProfileEntry(
    id: kGi01TallGarden,
    label: 'Girasol alto de jardín',
    cropId: kCropSunflower,
    subtitle:
        'Girasol de porte alto con una flor dominante que puede necesitar '
        'soporte (girasol gigante, mammoth)',
    aliases: <String>[
      'GI-01',
      'GI01',
      'gi_01',
      'GS-04',
      'girasol alto',
      'girasol gigante',
      'girasol de jardin',
      'girasol de jardín',
      'girasol mammoth',
      'mammoth',
      'russian mammoth',
      'american giant',
      'skyscraper',
      'titan',
      'girasol cabeza grande',
    ],
  ),
  CropProfileEntry(
    id: kGi02CompactContainer,
    label: 'Girasol compacto para maceta',
    cropId: kCropSunflower,
    subtitle:
        'Girasol enano de porte bajo para maceta, patio, balcón o borde de '
        'jardín (girasol mini, compacto)',
    aliases: <String>[
      'GI-02',
      'GI02',
      'gi_02',
      'GS-03',
      'girasol enano',
      'girasol compacto',
      'girasol mini',
      'girasol para maceta',
      'dwarf sunflower',
      'sunspot',
      'teddy bear',
      'big smile',
      'pacino',
      'ballad',
      'miss sunshine',
    ],
  ),
  CropProfileEntry(
    id: kGi03BranchingOrnamental,
    label: 'Girasol ramificado ornamental',
    cropId: kCropSunflower,
    subtitle:
        'Girasol ramificado con varias flores por planta y floración más '
        'prolongada (girasol multiflor, bouquet)',
    aliases: <String>[
      'GI-03',
      'GI03',
      'gi_03',
      'GS-02',
      'girasol ramificado',
      'girasol multirama',
      'girasol multiflor',
      'girasol bouquet',
      'branching sunflower',
      'cut and come again',
      'autumn beauty',
      'belleza de otoño',
      'soraya',
      'moulin rouge',
      'lemon queen',
      'velvet queen',
    ],
  ),
  CropProfileEntry(
    id: kGi04CutFlowerSingleStem,
    label: 'Girasol de corte de tallo único',
    cropId: kCropSunflower,
    subtitle:
        'Girasol de una sola flor por tallo, con apertura pareja y corte '
        'temprano (girasol de corte, sin polen)',
    aliases: <String>[
      'GI-04',
      'GI04',
      'gi_04',
      'GS-01',
      'girasol de corte',
      'flor de corte',
      'girasol unifloral',
      'girasol de tallo unico',
      'girasol de tallo único',
      'single stem sunflower',
      'pollenless',
      'sin polen',
      'procut',
      'sunrich',
      'vincent',
      'sunbright',
    ],
  ),
  // ── SIEMPRE AL FINAL ──────────────────────────────────────────────────────
  // La salida "no sé" va hasta abajo, después de los tipos concretos. Sigue
  // siendo el defaultProfileId: si el usuario no elige, cae aquí.
  CropProfileEntry(
    id: kGiSkip,
    label: 'No sé / Girasol general',
    cropId: kCropSunflower,
    subtitle:
        'Perfil general y migrable del girasol, precisas si es alto, compacto, '
        'ramificado o de corte sin perder historial',
    aliases: <String>[
      'GI-SKIP',
      'GI_SKIP',
      'GISKIP',
      'GI-GEN',
      'GS-SKIP',
      'girasol',
      'girasol comun',
      'girasol común',
      'girasol general',
      'mirasol',
      'flor de sol',
      'no se que girasol es',
      'no sé qué girasol es',
    ],
  ),
];

/// Aliases de ENTRADA que NO son *Helianthus annuus* y NO deben mapear a
/// `crop_sunflower` (Documento A §7.3). Se excluyen del alta automática y
/// requieren confirmación explícita del usuario: son otras asteráceas, especies
/// perennes de *Helianthus*, o el objetivo agrícola de aceite/semilla (fuera del
/// alcance ornamental).
const List<String> sunflowerNotASunflowerRedirectAliases = <String>[
  'girasol mexicano',
  'girasol mexicano tithonia',
  'tithonia',
  'tithonia rotundifolia',
  'topinambur',
  'alcachofa de jerusalen',
  'alcachofa de jerusalén',
  'helianthus tuberosus',
  'maximilian sunflower',
  'girasol de maximiliano',
  'helianthus maximiliani',
  'swamp sunflower',
  'helianthus angustifolius',
  'false sunflower',
  'falsa girasol',
  'heliopsis',
  'alto oleico',
  'oleic sunflower',
  'girasol para aceite',
  'girasol de aceite',
  'hibrido linoleico',
  'híbrido linoleico',
  'girasol agricola',
  'girasol agrícola',
  'microgreens de girasol',
  'brotes de girasol',
  'germinado de girasol',
];

/// True si el alias corresponde a una planta llamada "girasol" que NO es
/// *Helianthus annuus* ornamental, o a un objetivo agrícola de semilla/aceite
/// (no debe mapear a crop_sunflower sin confirmación).
bool isNotASunflowerAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return sunflowerNotASunflowerRedirectAliases.contains(v);
}
