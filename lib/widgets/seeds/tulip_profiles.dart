// lib/widgets/seeds/tulip_profiles.dart
//
// Perfiles oficiales del Tulipán (Documento A §8). Cinco tipos funcionales +
// el perfil general `tu_skip`, que SIEMPRE va al final de la lista y NUNCA
// muestra su id interno al usuario.
//
// Cada perfil guarda su CALENDARIO (límites de fin de etapa, día absoluto
// desde el ancla). Las bandas son defaults de ingeniería derivados del
// Documento A §10.2/§10.4/§10.5 y deben validarse con datos reales. El modo
// de establecimiento por defecto de cada perfil determina su calendario:
// el forzado de interior parte de un bulbo YA preenfriado y por eso usa una
// ventana abreviada (no recorre 12–16 semanas de frío desde cero).

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';

// ─── IDs canónicos (Documento A §1.1, §8.1) ──────────────────────────────────

const String kTu01GardenExterior = 'tu_01_garden_exterior';
const String kTu02DecorativeContainer = 'tu_02_decorative_container';
const String kTu03ForcedIndoor = 'tu_03_forced_indoor';
const String kTu04CutFlower = 'tu_04_cut_flower';
const String kTu05SpecialPremium = 'tu_05_special_premium';
const String kTuSkip = 'tu_skip';

const String kTulipProfilePrefix = 'TU';

// ─── Perfiles ─────────────────────────────────────────────────────────────────

const Map<String, TulipProfile> tulipProfiles = <String, TulipProfile>{
  // ── Tulipán de jardín (suelo exterior) ────────────────────────────────────
  // Calendario completo: plantación → 12–16 sem de enraizado + frío natural →
  // emergencia → hojas → tallo → botón → flor → recarga → senescencia →
  // dormancia. Temporada ~180–240 d (Documento A §10.2, §10.4).
  kTu01GardenExterior: TulipProfile(
    id: kTu01GardenExterior,
    label: 'Tulipán de jardín',
    useType: 'ornamental',
    tulipUseType: TulipUseType.gardenExterior,
    defaultEstablishmentMode: TulipEstablishmentMode.bulbPlanting,
    plantingEndDay: 7,
    rootingChillingEndDay: 105,
    emergenceEndDay: 119,
    vegetativeEndDay: 135,
    stemElongationEndDay: 145,
    budEndDay: 153,
    floweringEndDay: 168,
    rechargeEndDay: 210,
    senescenceEndDay: 225,
    floweringWindowDays: RangeInt(154, 168),
    perennializingHint: 'medium',
  ),

  // ── Tulipán en maceta (patio, terraza, contenedor) ────────────────────────
  // Menor volumen de raíz y temporada algo más corta (~170–230 d).
  kTu02DecorativeContainer: TulipProfile(
    id: kTu02DecorativeContainer,
    label: 'Tulipán en maceta',
    useType: 'ornamental',
    tulipUseType: TulipUseType.decorativeContainer,
    defaultEstablishmentMode: TulipEstablishmentMode.bulbPlanting,
    plantingEndDay: 6,
    rootingChillingEndDay: 98,
    emergenceEndDay: 111,
    vegetativeEndDay: 126,
    stemElongationEndDay: 135,
    budEndDay: 143,
    floweringEndDay: 158,
    rechargeEndDay: 196,
    senescenceEndDay: 210,
    floweringWindowDays: RangeInt(144, 158),
    perennializingHint: 'low',
  ),

  // ── Tulipán forzado de interior (preenfriado) ─────────────────────────────
  // El bulbo YA recibió frío: ventana ABREVIADA desde la activación
  // (Documento A §8.4, §10.5). No recorre 12–16 semanas ficticias. Florece
  // pocas semanas después de salir del frío. Temporada ~120–210 d.
  kTu03ForcedIndoor: TulipProfile(
    id: kTu03ForcedIndoor,
    label: 'Tulipán forzado de interior',
    useType: 'ornamental',
    tulipUseType: TulipUseType.forcedIndoor,
    defaultEstablishmentMode: TulipEstablishmentMode.prechilledActivation,
    plantingEndDay: 3,
    rootingChillingEndDay: 4,
    emergenceEndDay: 14,
    vegetativeEndDay: 22,
    stemElongationEndDay: 28,
    budEndDay: 38,
    floweringEndDay: 55,
    rechargeEndDay: 95,
    senescenceEndDay: 115,
    floweringWindowDays: RangeInt(39, 55),
    perennializingHint: 'low',
  ),

  // ── Tulipán para flor de corte ────────────────────────────────────────────
  // Ancla en el inicio del frío: el enfriamiento SÍ se cuenta. Prioriza tallo
  // largo y uniformidad; la etapa `flowering` contiene la ventana de corte.
  // SIN rendimiento económico (Documento A §8.5, §16).
  kTu04CutFlower: TulipProfile(
    id: kTu04CutFlower,
    label: 'Tulipán para flor de corte',
    useType: 'ornamental',
    tulipUseType: TulipUseType.cutFlower,
    defaultEstablishmentMode: TulipEstablishmentMode.coolingStart,
    plantingEndDay: 3,
    rootingChillingEndDay: 100,
    emergenceEndDay: 112,
    vegetativeEndDay: 124,
    stemElongationEndDay: 133,
    budEndDay: 141,
    floweringEndDay: 158,
    rechargeEndDay: 185,
    senescenceEndDay: 200,
    floweringWindowDays: RangeInt(142, 158),
    perennializingHint: 'low',
    supportsCutWindow: true,
  ),

  // ── Tulipán especial o premium (dobles, loro, con flecos) ─────────────────
  // Comparte ventanas amplias con jardín + modificadores de sensibilidad; no
  // números radicalmente distintos (Documento A §8.6). Temporada ~185–250 d.
  kTu05SpecialPremium: TulipProfile(
    id: kTu05SpecialPremium,
    label: 'Tulipán especial o premium',
    useType: 'ornamental',
    tulipUseType: TulipUseType.specialPremium,
    defaultEstablishmentMode: TulipEstablishmentMode.bulbPlanting,
    plantingEndDay: 7,
    rootingChillingEndDay: 108,
    emergenceEndDay: 122,
    vegetativeEndDay: 139,
    stemElongationEndDay: 149,
    budEndDay: 158,
    floweringEndDay: 175,
    rechargeEndDay: 220,
    senescenceEndDay: 236,
    floweringWindowDays: RangeInt(159, 175),
    perennializingHint: 'medium',
  ),

  // ── No sé / Tulipán general ───────────────────────────────────────────────
  // SIEMPRE al final. Calendario conservador tipo jardín, con baja confianza
  // (Documento A §8.7). El usuario puede precisar el tipo después sin perder
  // historial.
  kTuSkip: TulipProfile(
    id: kTuSkip,
    label: 'No sé / Tulipán general',
    useType: 'ornamental',
    tulipUseType: TulipUseType.generic,
    defaultEstablishmentMode: TulipEstablishmentMode.unknown,
    plantingEndDay: 7,
    rootingChillingEndDay: 105,
    emergenceEndDay: 119,
    vegetativeEndDay: 135,
    stemElongationEndDay: 145,
    budEndDay: 153,
    floweringEndDay: 168,
    rechargeEndDay: 208,
    senescenceEndDay: 224,
    floweringWindowDays: RangeInt(154, 168),
    perennializingHint: 'medium',
  ),
};

/// Orden de presentación en el wizard (Documento A §8.1, §11.2): tipos
/// concretos primero, `tu_skip` SIEMPRE al final.
const List<String> tulipProfileOrder = <String>[
  kTu01GardenExterior,
  kTu02DecorativeContainer,
  kTu03ForcedIndoor,
  kTu04CutFlower,
  kTu05SpecialPremium,
  kTuSkip,
];

// ─── Alias → ID canónico (Documento A §8.2–§8.7) ─────────────────────────────

const Map<String, String> _tulipProfileAliasToCanonical = <String, String>{
  // Legacy de las fichas técnicas (Documento A §1.1).
  'tl-01': kTu01GardenExterior,
  'tl_01': kTu01GardenExterior,
  'tl-02': kTu02DecorativeContainer,
  'tl_02': kTu02DecorativeContainer,
  'tl-03': kTu03ForcedIndoor,
  'tl_03': kTu03ForcedIndoor,
  'tl-04': kTu04CutFlower,
  'tl_04': kTu04CutFlower,
  'tl-05': kTu05SpecialPremium,
  'tl_05': kTu05SpecialPremium,
  'tl-gen': kTuSkip,
  'tl_gen': kTuSkip,
  'tu-gen': kTuSkip,
  'tu_gen': kTuSkip,

  // tu_01 Tulipán de jardín
  'tu-01': kTu01GardenExterior,
  'tu_01': kTu01GardenExterior,
  'tulipan de jardin': kTu01GardenExterior,
  'tulipán de jardín': kTu01GardenExterior,
  'tulipan clasico': kTu01GardenExterior,
  'tulipán clásico': kTu01GardenExterior,
  'tulipan normal': kTu01GardenExterior,
  'tulipan para suelo': kTu01GardenExterior,
  'tulipan exterior': kTu01GardenExterior,
  'tulipan de macizo': kTu01GardenExterior,
  'triumph': kTu01GardenExterior,
  'darwin hybrid': kTu01GardenExterior,
  'fosteriana': kTu01GardenExterior,
  'single early': kTu01GardenExterior,
  'single late': kTu01GardenExterior,

  // tu_02 Tulipán en maceta
  'tu-02': kTu02DecorativeContainer,
  'tu_02': kTu02DecorativeContainer,
  'tulipan en maceta': kTu02DecorativeContainer,
  'tulipán en maceta': kTu02DecorativeContainer,
  'tulipan para patio': kTu02DecorativeContainer,
  'tulipan decorativo': kTu02DecorativeContainer,
  'tulipan en contenedor': kTu02DecorativeContainer,
  'tulipan de balcon': kTu02DecorativeContainer,
  'tulipán de balcón': kTu02DecorativeContainer,
  'maceta de tulipanes': kTu02DecorativeContainer,

  // tu_03 Tulipán forzado de interior
  'tu-03': kTu03ForcedIndoor,
  'tu_03': kTu03ForcedIndoor,
  'tulipan de interior': kTu03ForcedIndoor,
  'tulipan forzado': kTu03ForcedIndoor,
  'tulipan preenfriado': kTu03ForcedIndoor,
  'tulipan de refri': kTu03ForcedIndoor,
  'tulipan para regalo': kTu03ForcedIndoor,
  'tulipan ya brotado': kTu03ForcedIndoor,
  'tulipan de supermercado': kTu03ForcedIndoor,

  // tu_04 Tulipán para flor de corte
  'tu-04': kTu04CutFlower,
  'tu_04': kTu04CutFlower,
  'tulipan para corte': kTu04CutFlower,
  'tulipan de floreria': kTu04CutFlower,
  'tulipán de florería': kTu04CutFlower,
  'tulipan de tallo largo': kTu04CutFlower,
  'tulipan de invernadero': kTu04CutFlower,
  'tulipan para ramo': kTu04CutFlower,
  'tulipan comercial': kTu04CutFlower,

  // tu_05 Tulipán especial o premium
  'tu-05': kTu05SpecialPremium,
  'tu_05': kTu05SpecialPremium,
  'tulipan doble': kTu05SpecialPremium,
  'tulipan peonia': kTu05SpecialPremium,
  'tulipán peonía': kTu05SpecialPremium,
  'tulipan loro': kTu05SpecialPremium,
  'parrot tulip': kTu05SpecialPremium,
  'tulipan con flecos': kTu05SpecialPremium,
  'fringed tulip': kTu05SpecialPremium,
  'tulipan lily-flowered': kTu05SpecialPremium,
  'tulipan viridiflora': kTu05SpecialPremium,
  'tulipan exotico': kTu05SpecialPremium,
  'tulipán exótico': kTu05SpecialPremium,
  'tulipan premium': kTu05SpecialPremium,

  // tu_skip Tulipán general
  'tu-skip': kTuSkip,
  'tuskip': kTuSkip,
  'tulipan': kTuSkip,
  'tulipanes': kTuSkip,
  'bulbo de tulipan': kTuSkip,
  'bulbo de tulipán': kTuSkip,
  'tulipa': kTuSkip,
  'tulipa spp': kTuSkip,
  'otro tulipan': kTuSkip,
  'otro tulipán': kTuSkip,
  'no se que tulipan es': kTuSkip,
  'no sé qué tulipán es': kTuSkip,
  'tulipan general': kTuSkip,
  'tulipán general': kTuSkip,
};

/// Resuelve el ID canónico del perfil de Tulipán a partir de texto libre.
String? resolveCanonicalTulipProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (tulipProfiles.containsKey(normalized)) return normalized;
  return _tulipProfileAliasToCanonical[normalized];
}
