// lib/widgets/seeds/marigold_profiles.dart
//
// Perfiles oficiales del Cempasúchil (Documento A §6, §12). Cuatro tipos
// funcionales + el perfil general `cs_skip`, que SIEMPRE va al final de la
// lista y NUNCA muestra su id interno ni la palabra "SKIP" al usuario
// (Documento A §2.1, §6.5).
//
// Cada perfil guarda su CALENDARIO como límites de FIN de etapa (día absoluto
// desde la fecha ancla / siembra). Las bandas son las ventanas nominales del
// Documento A §12: son defaults operativos de ingeniería, NO una promesa
// biológica exacta ni un calendario obligatorio de Día de Muertos (§12, §13.5).
//
// Un perfil existe solo si cambia arquitectura, porte, ramificación, contexto
// radicular, duración del ciclo, duración de la ventana floral o sensibilidad
// al día corto (§5). Nunca por color, número de pétalos, tamaño de flor
// aislado, precio, marca, fecha cultural ni por la palabra "africano"
// (§0.2 corrección 4, §0.4).

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';

// ─── IDs canónicos (Documento A §0.4, §17.3) ─────────────────────────────────

const String kCs01TraditionalField = 'cs_01_traditional_field';
const String kCs02TallCutFlower = 'cs_02_tall_cut_flower';
const String kCs03CompactContainer = 'cs_03_compact_container';
const String kCs04LandscapeBedding = 'cs_04_landscape_bedding';
const String kCsSkip = 'cs_skip';

const String kMarigoldProfilePrefix = 'CS';

// ─── Perfiles ─────────────────────────────────────────────────────────────────

const Map<String, MarigoldProfile> marigoldProfiles = <String, MarigoldProfile>{
  // ── Cempasúchil tradicional de campo (Documento A §6.1, §12.1) ───────────
  // Planta ramificada de campo, surco o cama; material criollo o selección
  // regional. Calendario medio-largo (~126 d) y respuesta fotoperiódica no
  // uniforme. Una sonda describe una zona del surco, no toda la parcela.
  kCs01TraditionalField: MarigoldProfile(
    id: kCs01TraditionalField,
    label: 'Cempasúchil tradicional de campo',
    useType: 'ornamental',
    marigoldUseType: MarigoldUseType.traditionalField,
    defaultEstablishmentMode: MarigoldEstablishmentMode.directSowing,
    sowingEndDay: 0,
    germinationEndDay: 5,
    emergenceEndDay: 9,
    earlyVegetativeEndDay: 22,
    activeVegetativeEndDay: 43,
    stemElongationEndDay: 60,
    budFormationEndDay: 75,
    floweringEndDay: 100,
    postBloomEndDay: 112,
    senescenceEndDay: 125,
    floweringWindowDays: RangeInt(76, 100),
    transplantAgeOffsetDays: 24,
    sensorLocalCaution: true,
  ),

  // ── Cempasúchil alto de corte (Documento A §6.2, §12.2) ──────────────────
  // Tallos largos y firmes para arreglos, ramos o guirnaldas. Calendario medio
  // (~112 d), compatible con materiales comerciales de 65–95 d a flor. El día
  // corto temprano puede adelantar la floración con tallo más corto. Cortar una
  // flor NO termina el ciclo: `supportsHarvest` sigue apagado (§6.2).
  kCs02TallCutFlower: MarigoldProfile(
    id: kCs02TallCutFlower,
    label: 'Cempasúchil alto de corte',
    useType: 'ornamental',
    marigoldUseType: MarigoldUseType.tallCutFlower,
    defaultEstablishmentMode: MarigoldEstablishmentMode.directSowing,
    sowingEndDay: 0,
    germinationEndDay: 4,
    emergenceEndDay: 8,
    earlyVegetativeEndDay: 20,
    activeVegetativeEndDay: 38,
    stemElongationEndDay: 55,
    budFormationEndDay: 68,
    floweringEndDay: 88,
    postBloomEndDay: 99,
    senescenceEndDay: 111,
    floweringWindowDays: RangeInt(69, 88),
    transplantAgeOffsetDays: 21,
    sensorLocalCaution: true,
  ),

  // ── Cempasúchil compacto para maceta (Documento A §6.3, §12.3) ───────────
  // Porte bajo y redondeado, raíz restringida por recipiente, ciclo más corto
  // (~99 d). "Tomando porte" significa consolidar su forma compacta, no
  // hacerse alta (§10.6). Es el único perfil donde la sonda representa una
  // fracción grande del volumen radicular (Documento B §3.2).
  kCs03CompactContainer: MarigoldProfile(
    id: kCs03CompactContainer,
    label: 'Cempasúchil compacto para maceta',
    useType: 'ornamental',
    marigoldUseType: MarigoldUseType.compactContainer,
    defaultEstablishmentMode: MarigoldEstablishmentMode.directSowing,
    sowingEndDay: 0,
    germinationEndDay: 4,
    emergenceEndDay: 7,
    earlyVegetativeEndDay: 18,
    activeVegetativeEndDay: 30,
    stemElongationEndDay: 38,
    budFormationEndDay: 48,
    floweringEndDay: 72,
    postBloomEndDay: 85,
    senescenceEndDay: 98,
    floweringWindowDays: RangeInt(49, 72),
    transplantAgeOffsetDays: 18,
  ),

  // ── Cempasúchil para cama o paisaje (Documento A §6.4, §12.4) ────────────
  // Porte intermedio, ramificación uniforme y floración de masa. Ventana floral
  // prolongada (61–92) con apertura escalonada DENTRO del mismo ciclo: NO es
  // recurring_bloom (§6.4, §12.4).
  kCs04LandscapeBedding: MarigoldProfile(
    id: kCs04LandscapeBedding,
    label: 'Cempasúchil para cama o paisaje',
    useType: 'ornamental',
    marigoldUseType: MarigoldUseType.landscapeBedding,
    defaultEstablishmentMode: MarigoldEstablishmentMode.directSowing,
    sowingEndDay: 0,
    germinationEndDay: 5,
    emergenceEndDay: 8,
    earlyVegetativeEndDay: 20,
    activeVegetativeEndDay: 36,
    stemElongationEndDay: 48,
    budFormationEndDay: 60,
    floweringEndDay: 92,
    postBloomEndDay: 105,
    senescenceEndDay: 118,
    floweringWindowDays: RangeInt(61, 92),
    transplantAgeOffsetDays: 21,
    sensorLocalCaution: true,
  ),

  // ── No sé / Cempasúchil general ──────────────────────────────────────────
  // SIEMPRE al final (Documento A §6.5, §15.2). Calendario medio y conservador
  // (~121 d). No asume altura, contexto, color, respuesta fotoperiódica ni
  // fecha cultural. El usuario puede precisar el tipo después sin perder
  // historial (§7 reglas de compatibilidad).
  kCsSkip: MarigoldProfile(
    id: kCsSkip,
    label: 'No sé / Cempasúchil general',
    useType: 'ornamental',
    marigoldUseType: MarigoldUseType.generic,
    defaultEstablishmentMode: MarigoldEstablishmentMode.unknown,
    sowingEndDay: 0,
    germinationEndDay: 5,
    emergenceEndDay: 9,
    earlyVegetativeEndDay: 22,
    activeVegetativeEndDay: 40,
    stemElongationEndDay: 53,
    budFormationEndDay: 66,
    floweringEndDay: 92,
    postBloomEndDay: 106,
    senescenceEndDay: 120,
    floweringWindowDays: RangeInt(67, 92),
    transplantAgeOffsetDays: 21,
    sensorLocalCaution: true,
    limitNpkPriorityToReview: true,
  ),
};

/// Orden de presentación en el wizard (Documento A §6, §15.2): tipos concretos
/// primero, `cs_skip` SIEMPRE al final.
const List<String> marigoldProfileOrder = <String>[
  kCs01TraditionalField,
  kCs02TallCutFlower,
  kCs03CompactContainer,
  kCs04LandscapeBedding,
  kCsSkip,
];

// ─── Alias → ID canónico (Documento A §6, §7, §8) ────────────────────────────
//
// Incluye la migración de los códigos legacy CS-* / CS-GEN (§2.1). Los aliases
// AMBIGUOS de §8.2 ("criollo", "flor de muerto", "flor grande", "en maceta",
// "africano"…) NO se listan aquí a propósito: resuelven al perfil general por
// la vía del cropId o exigen una pregunta de arquitectura, nunca fuerzan un
// porte concreto (§6.1 regla, §6.2 regla, §6.3 regla, §6.4 regla).

const Map<String, String> _marigoldProfileAliasToCanonical = <String, String>{
  // Legacy CS-0x / cs0x.
  'cs-01': kCs01TraditionalField,
  'cs01': kCs01TraditionalField,
  'cs-02': kCs02TallCutFlower,
  'cs02': kCs02TallCutFlower,
  'cs-03': kCs03CompactContainer,
  'cs03': kCs03CompactContainer,
  'cs-04': kCs04LandscapeBedding,
  'cs04': kCs04LandscapeBedding,
  'cs-skip': kCsSkip,
  'cs_skip': kCsSkip,
  'csskip': kCsSkip,
  'cs-gen': kCsSkip,
  'cs_gen': kCsSkip,
  'csgen': kCsSkip,

  // cs_01 tradicional de campo (Documento A §6.1).
  'cempasuchil tradicional de campo': kCs01TraditionalField,
  'cempasúchil tradicional de campo': kCs01TraditionalField,
  'cempasuchil tradicional': kCs01TraditionalField,
  'cempasúchil tradicional': kCs01TraditionalField,
  'cempoalxochitl tradicional': kCs01TraditionalField,
  'cempoalxóchitl tradicional': kCs01TraditionalField,
  'flor de muerto tradicional': kCs01TraditionalField,
  'cempasuchil criollo de campo': kCs01TraditionalField,
  'cempasúchil criollo de campo': kCs01TraditionalField,
  'flor para ofrenda': kCs01TraditionalField,
  'cempasuchil para manojo': kCs01TraditionalField,
  'cempasúchil para manojo': kCs01TraditionalField,
  'cempasuchil de surco': kCs01TraditionalField,
  'cempasúchil de surco': kCs01TraditionalField,
  'cempasuchil de chinampa': kCs01TraditionalField,
  'cempasúchil de chinampa': kCs01TraditionalField,
  'cempasuchil de temporada': kCs01TraditionalField,
  'cempasúchil de temporada': kCs01TraditionalField,
  'para dia de muertos': kCs01TraditionalField,
  'para día de muertos': kCs01TraditionalField,
  'traditional mexican marigold': kCs01TraditionalField,
  'aztec marigold tradicional': kCs01TraditionalField,

  // cs_02 alto de corte (Documento A §6.2).
  'cempasuchil alto de corte': kCs02TallCutFlower,
  'cempasúchil alto de corte': kCs02TallCutFlower,
  'cempasuchil de corte': kCs02TallCutFlower,
  'cempasúchil de corte': kCs02TallCutFlower,
  'flor de corte': kCs02TallCutFlower,
  'cempasuchil de tallo largo': kCs02TallCutFlower,
  'cempasúchil de tallo largo': kCs02TallCutFlower,
  'marigold de corte': kCs02TallCutFlower,
  'cut flower marigold': kCs02TallCutFlower,
  'african marigold cut flower': kCs02TallCutFlower,
  'american marigold cut flower': kCs02TallCutFlower,
  'long stem marigold': kCs02TallCutFlower,
  'xochi': kCs02TallCutFlower,
  'xochi orange': kCs02TallCutFlower,
  'coco': kCs02TallCutFlower,
  'coco marigold': kCs02TallCutFlower,
  'coco gold': kCs02TallCutFlower,
  'coco yellow': kCs02TallCutFlower,
  'coco deep orange': kCs02TallCutFlower,
  'giant orange': kCs02TallCutFlower,
  'giant yellow': kCs02TallCutFlower,
  'white swan': kCs02TallCutFlower,
  'nosento': kCs02TallCutFlower,

  // cs_03 compacto para maceta (Documento A §6.3).
  'cempasuchil compacto para maceta': kCs03CompactContainer,
  'cempasúchil compacto para maceta': kCs03CompactContainer,
  'cempasuchil enano': kCs03CompactContainer,
  'cempasúchil enano': kCs03CompactContainer,
  'cempasuchil compacto': kCs03CompactContainer,
  'cempasúchil compacto': kCs03CompactContainer,
  'cempasuchil de maceta': kCs03CompactContainer,
  'cempasúchil de maceta': kCs03CompactContainer,
  'cempasuchil para maceta': kCs03CompactContainer,
  'cempasúchil para maceta': kCs03CompactContainer,
  'cempasuchil mini': kCs03CompactContainer,
  'cempasúchil mini': kCs03CompactContainer,
  'marigold compacto': kCs03CompactContainer,
  'african marigold dwarf': kCs03CompactContainer,
  'american marigold dwarf': kCs03CompactContainer,
  'proud mari': kCs03CompactContainer,
  'inca ii compacto': kCs03CompactContainer,
  'antigua compacto': kCs03CompactContainer,
  'discovery compacto': kCs03CompactContainer,

  // cs_04 cama o paisaje (Documento A §6.4).
  'cempasuchil para cama o paisaje': kCs04LandscapeBedding,
  'cempasúchil para cama o paisaje': kCs04LandscapeBedding,
  'cempasuchil paisajistico': kCs04LandscapeBedding,
  'cempasúchil paisajístico': kCs04LandscapeBedding,
  'cempasuchil para cama': kCs04LandscapeBedding,
  'cempasúchil para cama': kCs04LandscapeBedding,
  'cempasuchil de camellon': kCs04LandscapeBedding,
  'cempasúchil de camellón': kCs04LandscapeBedding,
  'cempasuchil de parque': kCs04LandscapeBedding,
  'cempasúchil de parque': kCs04LandscapeBedding,
  'marigold bedding': kCs04LandscapeBedding,
  'african marigold landscape': kCs04LandscapeBedding,
  'marvel': kCs04LandscapeBedding,
  'marvel ii': kCs04LandscapeBedding,
  'taishan': kCs04LandscapeBedding,
  'bali': kCs04LandscapeBedding,
  'cama urbana': kCs04LandscapeBedding,
  'floracion de masa': kCs04LandscapeBedding,
  'floración de masa': kCs04LandscapeBedding,

  // cs_skip general (Documento A §6.5). "African marigold", "Mexican marigold"
  // y "flor de muerto" resuelven AQUÍ, nunca a un porte específico.
  'cempasuchil': kCsSkip,
  'cempasúchil': kCsSkip,
  'sempasuchil': kCsSkip,
  'sempasúchil': kCsSkip,
  'zempasuchil': kCsSkip,
  'zempasúchil': kCsSkip,
  'cempoalxochitl': kCsSkip,
  'cempoalxóchitl': kCsSkip,
  'cempaxuchitl': kCsSkip,
  'cempaxúchitl': kCsSkip,
  'flor de muerto': kCsSkip,
  'flor de muertos': kCsSkip,
  'flor de veinte petalos': kCsSkip,
  'flor de veinte pétalos': kCsSkip,
  'tagetes erecta': kCsSkip,
  't. erecta': kCsSkip,
  'aztec marigold': kCsSkip,
  'mexican marigold': kCsSkip,
  'african marigold': kCsSkip,
  'american marigold': kCsSkip,
  'otro cempasuchil': kCsSkip,
  'otro cempasúchil': kCsSkip,
  'cempasuchil general': kCsSkip,
  'cempasúchil general': kCsSkip,
  'no se que cempasuchil es': kCsSkip,
  'no sé qué cempasúchil es': kCsSkip,
  'semilla de cempasuchil': kCsSkip,
  'semilla de cempasúchil': kCsSkip,
};

/// Resuelve el ID canónico del perfil de Cempasúchil a partir de texto libre.
/// Devuelve null cuando el alias no corresponde a ningún perfil: el llamador
/// cae a `cs_skip`, NUNCA a un perfil de otro cultivo.
String? resolveCanonicalMarigoldProfileId(String raw) {
  final normalized = raw.trim().toLowerCase();
  if (normalized.isEmpty) return null;
  if (marigoldProfiles.containsKey(normalized)) return normalized;
  return _marigoldProfileAliasToCanonical[normalized];
}

/// Aliases AMBIGUOS (Documento A §8.2): describen color, tamaño, contexto o
/// procedencia, pero NO la arquitectura. No deben forzar un perfil concreto:
/// el wizard debe preguntar por porte o caer en `cs_skip`.
const List<String> marigoldAmbiguousProfileAliases = <String>[
  'criollo',
  'semilla criolla',
  'semilla regional',
  'cempasuchil criollo',
  'cempasúchil criollo',
  'cempasuchil mexicano',
  'cempasúchil mexicano',
  'manojo',
  'marigold',
  'flor grande',
  'marigold gigante',
  'gigante',
  'africano',
  'africano alto',
  'africano intermedio',
  'bolota grande',
  'en maceta',
  'cempasuchil en maceta',
  'cempasúchil en maceta',
  'flor grande en maceta',
  'inca ii',
  'inca',
  'antigua',
  'proud',
  'discovery',
  'para jardin',
  'para jardín',
  'para parque',
  'paisajistico',
  'paisajístico',
  'intermedio',
  'para ofrenda',
  'amarillo',
  'naranja',
  'doble',
  'hibrido',
  'híbrido',
  'semilla importada',
];

/// True cuando el texto solo describe color, tamaño, contexto o marca y por
/// tanto NO alcanza para elegir un perfil (Documento A §8.2). El llamador debe
/// preguntar por arquitectura o usar `cs_skip`.
bool isAmbiguousMarigoldProfileAlias(String? raw) {
  final v = raw?.trim().toLowerCase();
  if (v == null || v.isEmpty) return false;
  return marigoldAmbiguousProfileAliases.contains(v);
}
