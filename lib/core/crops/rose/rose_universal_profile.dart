import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';

/// Perfil universal agronómico de la Rosa (Rosal) ornamental.
///
/// MISMAS UNIDADES REALES que el resto del ecosistema BIO-G (frijol, hortalizas,
/// granos, árboles, cactus). Esto NO es negociable: el dashboard, el motor de
/// alertas y la pantalla NPK comparan contra estas unidades.
///
///   - humedad     → % (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm   (igual que frijol)
///   - resistencia → MPa     (igual que frijol: 0.0–2.0)
///   - N / P / K   → mg/kg   (rangos explícitos de suficiencia de suelo)
///
/// Agronomía de la rosa (arbusto de flor, demanda media-alta en floración),
/// respetada dentro de las unidades reales:
///   - La floración manda con potasio: K es el nutriente clave cuando forma
///     botones y abre flor. Por eso su peso sube en esas etapas.
///   - En el brote (flush) el exceso de nitrógeno produce tejido blando y débil,
///     propenso a plagas y enfermedad. El N alto se castiga.
///   - En reposo pide mucha menos agua; frío con sustrato húmedo es el peor
///     riesgo para la raíz.
///   - En maceta y mini rosal se acumulan sales rápido: la EC debe vigilarse.
///   - El pH depende del contexto (maceta/vivero vs. suelo abierto) y el resolver
///     lo ajusta; por eso cada etapa guarda el rango de contexto por confirmar.
class RoseUniversalProfile {
  const RoseUniversalProfile._();

  /// Maceta / vivero: sustrato confinado, se acidifica y saliniza más rápido.
  static const AgroRange phPotNursery = AgroRange(
    lowMax: 5.2,
    optimalMin: 5.8,
    optimalMax: 6.5,
    highMin: 7.2,
  );

  /// Suelo mezclado / maceta grande / jardinera / cama de jardín.
  static const AgroRange phMixedSoilLargePot = AgroRange(
    lowMax: 5.3,
    optimalMin: 5.8,
    optimalMax: 6.8,
    highMin: 7.5,
  );

  /// Paisaje / suelo abierto: suelos más tamponados, tolera pH más alto.
  static const AgroRange phLandscapeGround = AgroRange(
    lowMax: 5.4,
    optimalMin: 6.0,
    optimalMax: 7.0,
    highMin: 7.7,
  );

  /// Contexto por confirmar: rango prudente e intermedio.
  static const AgroRange phUnknownContext = AgroRange(
    lowMax: 5.3,
    optimalMin: 5.8,
    optimalMax: 6.8,
    highMin: 7.5,
  );
}

/// Datos por etapa. Mismo patrón que `CactusUniversalProfile`.
class _RoseStageProfile {
  const _RoseStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ph,
    required this.ec,
    required this.resistance,
    required this.nPpm,
    required this.pPpm,
    required this.kPpm,
    required this.wMoisture,
    required this.wSoilTemp,
    required this.wPh,
    required this.wEc,
    required this.wResistance,
    required this.wN,
    required this.wP,
    required this.wK,
    required this.nWindowEs,
    required this.pWindowEs,
    required this.kWindowEs,
    required this.nGuidanceEs,
    required this.pGuidanceEs,
    required this.kGuidanceEs,
    required this.careNoteEs,
  });

  final AgroRange moisture;
  final AgroRange soilTemp;
  final AgroRange ph;
  final AgroRange ec;
  final AgroRange resistance;
  final AgroRange nPpm;
  final AgroRange pPpm;
  final AgroRange kPpm;
  final double wMoisture;
  final double wSoilTemp;
  final double wPh;
  final double wEc;
  final double wResistance;
  final double wN;
  final double wP;
  final double wK;
  final String nWindowEs;
  final String pWindowEs;
  final String kWindowEs;
  final String nGuidanceEs;
  final String pGuidanceEs;
  final String kGuidanceEs;
  final String careNoteEs;
}

// Los pesos de cada etapa suman 1.00 (igual que frijol, árbol y cactus).
const Map<String, _RoseStageProfile> _roseStageProfiles =
    <String, _RoseStageProfile>{
      // Recién plantado: la raíz aún no trabaja. Todo es agua y arraigo.
      RoseStageIds.installationEstablishment: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 18,
          optimalMin: 28,
          optimalMax: 68,
          highMin: 84,
        ),
        soilTemp: AgroRange(
          lowMax: 5,
          optimalMin: 12,
          optimalMax: 24,
          highMin: 34,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.3,
          optimalMin: 0.6,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(
          lowMax: 12,
          optimalMin: 22,
          optimalMax: 45,
          highMin: 70,
        ),
        pPpm: AgroRange(
          lowMax: 8,
          optimalMin: 15,
          optimalMax: 30,
          highMin: 48,
        ),
        kPpm: AgroRange(
          lowMax: 45,
          optimalMin: 75,
          optimalMax: 135,
          highMin: 185,
        ),
        wMoisture: 0.28,
        wSoilTemp: 0.14,
        wPh: 0.08,
        wEc: 0.10,
        wResistance: 0.14,
        wN: 0.09,
        wP: 0.08,
        wK: 0.09,
        nWindowEs: 'Sin demanda',
        pWindowEs: 'Apoyo a raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs:
            'Recién plantado: no empujes con nitrógeno; el tallo tierno no lo '
            'aprovecha y se pone débil.',
        pGuidanceEs: 'El fósforo acompaña el arraigo. Es lo que más ayuda ahora.',
        kGuidanceEs: 'El potasio da firmeza mientras la planta se afianza.',
        careNoteEs:
            'Recién plantado: manda el agua y el arraigo. Revisa que el sustrato '
            'drene y casi no fertilices.',
      ),
      // Echando raíz: sustrato suelto y agua pareja. El nitrógeno aún estorba.
      RoseStageIds.rootEstablishment: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 20,
          optimalMin: 30,
          optimalMax: 70,
          highMin: 86,
        ),
        soilTemp: AgroRange(
          lowMax: 6,
          optimalMin: 14,
          optimalMax: 25,
          highMin: 34,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.3,
          optimalMin: 0.6,
          optimalMax: 1.5,
          highMin: 2.1,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.0,
          highMin: 1.6,
        ),
        nPpm: AgroRange(
          lowMax: 14,
          optimalMin: 24,
          optimalMax: 50,
          highMin: 75,
        ),
        pPpm: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 34,
          highMin: 52,
        ),
        kPpm: AgroRange(
          lowMax: 50,
          optimalMin: 80,
          optimalMax: 145,
          highMin: 195,
        ),
        wMoisture: 0.29,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.10,
        wResistance: 0.14,
        wN: 0.08,
        wP: 0.09,
        wK: 0.09,
        nWindowEs: 'Demanda baja',
        pWindowEs: 'Ventana de raíz',
        kWindowEs: 'Apoyo a raíz',
        nGuidanceEs:
            'Echando raíz: el nitrógeno alto solo estorba, la raíz nueva no lo '
            'necesita todavía.',
        pGuidanceEs: 'Ventana buena para fósforo: la raíz nueva lo está usando.',
        kGuidanceEs:
            'El potasio ayuda a aguantar el estrés mientras agarra raíz.',
        careNoteEs:
            'Echando raíz: mantén agua pareja y sustrato suelto. La raíz necesita '
            'aire, no compactación.',
      ),
      // Brotando: entra el nitrógeno, pero el exceso da tejido blando.
      RoseStageIds.vegetativeFlush: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 22,
          optimalMin: 34,
          optimalMax: 72,
          highMin: 88,
        ),
        soilTemp: AgroRange(
          lowMax: 8,
          optimalMin: 16,
          optimalMax: 28,
          highMin: 36,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.4,
          optimalMin: 0.8,
          optimalMax: 1.8,
          highMin: 2.5,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 22,
          optimalMin: 38,
          optimalMax: 70,
          highMin: 95,
        ),
        pPpm: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 36,
          highMin: 55,
        ),
        kPpm: AgroRange(
          lowMax: 65,
          optimalMin: 105,
          optimalMax: 175,
          highMin: 225,
        ),
        wMoisture: 0.23,
        wSoilTemp: 0.12,
        wPh: 0.07,
        wEc: 0.10,
        wResistance: 0.09,
        wN: 0.16,
        wP: 0.09,
        wK: 0.14,
        nWindowEs: 'Impulso de brote',
        pWindowEs: 'Demanda moderada',
        kWindowEs: 'Soporte de crecimiento',
        nGuidanceEs:
            'Brotando: el nitrógeno impulsa el brote, pero de más da tejido '
            'blando y débil.',
        pGuidanceEs:
            'El fósforo acompaña el crecimiento, sin ser la prioridad de esta '
            'etapa.',
        kGuidanceEs:
            'El potasio sostiene el crecimiento y le da firmeza al brote nuevo.',
        careNoteEs:
            'Brotando: alimenta el brote sin excederte en nitrógeno; el exceso '
            'da ramas aguadas y con plagas.',
      ),
      // Formando botones: sube el potasio; define la calidad de la flor.
      RoseStageIds.budFormation: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 24,
          optimalMin: 38,
          optimalMax: 74,
          highMin: 90,
        ),
        soilTemp: AgroRange(
          lowMax: 9,
          optimalMin: 16,
          optimalMax: 27,
          highMin: 34,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.5,
          optimalMin: 0.9,
          optimalMax: 2.0,
          highMin: 2.6,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 18,
          optimalMin: 32,
          optimalMax: 62,
          highMin: 88,
        ),
        pPpm: AgroRange(
          lowMax: 12,
          optimalMin: 20,
          optimalMax: 40,
          highMin: 60,
        ),
        kPpm: AgroRange(
          lowMax: 75,
          optimalMin: 120,
          optimalMax: 195,
          highMin: 245,
        ),
        wMoisture: 0.25,
        wSoilTemp: 0.14,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.07,
        wN: 0.11,
        wP: 0.10,
        wK: 0.16,
        nWindowEs: 'Demanda moderada',
        pWindowEs: 'Apoyo a botón',
        kWindowEs: 'Alta demanda de K',
        nGuidanceEs:
            'Formando botones: mantén el nitrógeno moderado, sin empujar hoja de '
            'más.',
        pGuidanceEs:
            'El fósforo apoya la formación del botón. Buen momento para él.',
        kGuidanceEs:
            'El potasio manda al formar botones: más flores y de mejor calidad.',
        careNoteEs:
            'Formando botones: sube el potasio y mantén el agua pareja para que '
            'cuajen bien.',
      ),
      // En floración: el potasio manda. No empujar con nitrógeno.
      RoseStageIds.flowering: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 24,
          optimalMin: 38,
          optimalMax: 76,
          highMin: 90,
        ),
        soilTemp: AgroRange(
          lowMax: 9,
          optimalMin: 16,
          optimalMax: 26,
          highMin: 33,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.4,
          optimalMin: 0.8,
          optimalMax: 1.8,
          highMin: 2.5,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 16,
          optimalMin: 28,
          optimalMax: 55,
          highMin: 82,
        ),
        pPpm: AgroRange(
          lowMax: 10,
          optimalMin: 18,
          optimalMax: 36,
          highMin: 55,
        ),
        kPpm: AgroRange(
          lowMax: 70,
          optimalMin: 115,
          optimalMax: 190,
          highMin: 240,
        ),
        wMoisture: 0.27,
        wSoilTemp: 0.15,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.06,
        wN: 0.09,
        wP: 0.08,
        wK: 0.18,
        nWindowEs: 'Mantener, no empujar',
        pWindowEs: 'Demanda baja',
        kWindowEs: 'Nutriente clave',
        nGuidanceEs:
            'En floración: mantén el nitrógeno, no lo empujes; ya no busca hoja '
            'nueva.',
        pGuidanceEs: 'El fósforo baja de prioridad durante la floración.',
        kGuidanceEs:
            'El potasio es el nutriente clave de la rosa en flor: color, firmeza '
            'y aguante.',
        careNoteEs:
            'En floración: el potasio manda. Riega parejo y no fuerces con '
            'nitrógeno.',
      ),
      // Después de floración: recuperar fuerza con N y K parejos.
      RoseStageIds.postBloomRecovery: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 20,
          optimalMin: 32,
          optimalMax: 70,
          highMin: 86,
        ),
        soilTemp: AgroRange(
          lowMax: 7,
          optimalMin: 14,
          optimalMax: 27,
          highMin: 35,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.3,
          optimalMin: 0.6,
          optimalMax: 1.5,
          highMin: 2.2,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.4,
          highMin: 2.0,
        ),
        nPpm: AgroRange(
          lowMax: 18,
          optimalMin: 32,
          optimalMax: 62,
          highMin: 88,
        ),
        pPpm: AgroRange(
          lowMax: 8,
          optimalMin: 15,
          optimalMax: 32,
          highMin: 50,
        ),
        kPpm: AgroRange(
          lowMax: 60,
          optimalMin: 100,
          optimalMax: 170,
          highMin: 220,
        ),
        wMoisture: 0.24,
        wSoilTemp: 0.12,
        wPh: 0.07,
        wEc: 0.11,
        wResistance: 0.08,
        wN: 0.15,
        wP: 0.08,
        wK: 0.15,
        nWindowEs: 'Recuperación',
        pWindowEs: 'Demanda baja',
        kWindowEs: 'Recuperación',
        nGuidanceEs:
            'Después de floración: el nitrógeno ayuda a que se reponga y '
            'rebrote.',
        pGuidanceEs: 'El fósforo pasa a segundo plano en la recuperación.',
        kGuidanceEs:
            'El potasio acompaña al nitrógeno para recuperar fuerza tras la '
            'flor.',
        careNoteEs:
            'Después de floración: ayúdala a reponerse con nitrógeno y potasio '
            'parejos, sin exagerar.',
      ),
      // En reposo: mucha menos agua. Frío con humedad es el peor riesgo.
      RoseStageIds.rest: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 14,
          optimalMin: 24,
          optimalMax: 58,
          highMin: 76,
        ),
        soilTemp: AgroRange(
          lowMax: 0,
          optimalMin: 4,
          optimalMax: 16,
          highMin: 26,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.2,
          optimalMin: 0.4,
          optimalMax: 1.0,
          highMin: 1.8,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.5,
          highMin: 2.1,
        ),
        nPpm: AgroRange(
          lowMax: 8,
          optimalMin: 14,
          optimalMax: 32,
          highMin: 55,
        ),
        pPpm: AgroRange(
          lowMax: 5,
          optimalMin: 10,
          optimalMax: 24,
          highMin: 40,
        ),
        kPpm: AgroRange(
          lowMax: 35,
          optimalMin: 60,
          optimalMax: 120,
          highMin: 175,
        ),
        wMoisture: 0.26,
        wSoilTemp: 0.22,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.10,
        wN: 0.07,
        wP: 0.06,
        wK: 0.10,
        nWindowEs: 'Sin demanda activa',
        pWindowEs: 'Sin demanda activa',
        kWindowEs: 'Reserva',
        nGuidanceEs:
            'En reposo: no fertilices con nitrógeno; la planta no lo va a usar.',
        pGuidanceEs: 'En reposo el fósforo no es prioridad.',
        kGuidanceEs:
            'Un poco de potasio ayuda a resistir el frío durante el reposo.',
        careNoteEs:
            'En reposo: riega mucho menos y cuida el frío con humedad, que es lo '
            'más peligroso para la raíz.',
      ),
      // Etapa por confirmar: targets amplios y prudentes.
      RoseStageIds.unknown: _RoseStageProfile(
        moisture: AgroRange(
          lowMax: 20,
          optimalMin: 32,
          optimalMax: 70,
          highMin: 86,
        ),
        soilTemp: AgroRange(
          lowMax: 6,
          optimalMin: 14,
          optimalMax: 27,
          highMin: 35,
        ),
        ph: RoseUniversalProfile.phUnknownContext,
        ec: AgroRange(
          lowMax: 0.3,
          optimalMin: 0.6,
          optimalMax: 1.5,
          highMin: 2.2,
        ),
        resistance: AgroRange(
          lowMax: -1.0,
          optimalMin: 0.0,
          optimalMax: 1.3,
          highMin: 1.9,
        ),
        nPpm: AgroRange(
          lowMax: 16,
          optimalMin: 28,
          optimalMax: 55,
          highMin: 82,
        ),
        pPpm: AgroRange(
          lowMax: 8,
          optimalMin: 15,
          optimalMax: 32,
          highMin: 50,
        ),
        kPpm: AgroRange(
          lowMax: 55,
          optimalMin: 90,
          optimalMax: 160,
          highMin: 210,
        ),
        wMoisture: 0.26,
        wSoilTemp: 0.15,
        wPh: 0.07,
        wEc: 0.11,
        wResistance: 0.11,
        wN: 0.10,
        wP: 0.08,
        wK: 0.12,
        nWindowEs: 'Demanda moderada',
        pWindowEs: 'Mantenimiento',
        kWindowEs: 'Mantenimiento',
        nGuidanceEs: 'Nitrógeno moderado mientras se confirma la etapa.',
        pGuidanceEs: 'Fósforo de mantenimiento mientras se confirma la etapa.',
        kGuidanceEs: 'Potasio de mantenimiento mientras se confirma la etapa.',
        careNoteEs:
            'Etapa por confirmar: cuida el agua y el drenaje; en maceta o mini '
            'rosal vigila que no se acumule sal.',
      ),
    };

_RoseStageProfile _profileForStage(String? stageId) {
  final id = normalizeRoseStageId(stageId);
  return _roseStageProfiles[id] ?? _roseStageProfiles[RoseStageIds.unknown]!;
}

/// Targets de sensor por etapa, en unidades reales.
StageTargets resolveRoseTargets(
  String? stageId, {
  String? cultivationContextId,
}) {
  final p = _profileForStage(stageId);
  return StageTargets(
    moistureRaw: p.moisture,
    soilTemp: p.soilTemp,
    ph: _rosePhForContext(cultivationContextId, fallback: p.ph),
    ec: p.ec,
    resistance: p.resistance,
    // Índices legacy: se conservan por compatibilidad del contrato compartido.
    // Los rangos que MANDAN son los explícitos en mg/kg.
    nIndex: p.nPpm,
    pIndex: p.pPpm,
    kIndex: p.kPpm,
    nSoilPpmRange: p.nPpm,
    pSoilPpmRange: p.pPpm,
    kSoilPpmRange: p.kPpm,
    nWindowLabelEs: p.nWindowEs,
    pWindowLabelEs: p.pWindowEs,
    kWindowLabelEs: p.kWindowEs,
    nShortGuidanceEs: p.nGuidanceEs,
    pShortGuidanceEs: p.pGuidanceEs,
    kShortGuidanceEs: p.kGuidanceEs,
  );
}

/// Targets ajustados por el contexto de cultivo que el perfil implica. RO-04
/// (trepadora reflorescente) se maneja como paisaje por defecto.
StageTargets resolveRoseTargetsForProfile(
  String? stageId, {
  required String? profileId,
}) {
  final cultivationContextId = switch (profileId?.trim().toLowerCase()) {
    kRo01MiniatureContainer => 'pot',
    kRo02LargeFloweredBush => 'mixed',
    kRo03ClusteredLandscape => 'landscape',
    kRo04RepeatClimber => 'landscape',
    _ => 'unknown',
  };
  return resolveRoseTargets(
    stageId,
    cultivationContextId: cultivationContextId,
  );
}

AgroRange _rosePhForContext(String? contextId, {required AgroRange fallback}) {
  return switch (contextId?.trim().toLowerCase()) {
    'pot' || 'nursery' => RoseUniversalProfile.phPotNursery,
    'mixed' || 'planter' || 'garden_bed' =>
      RoseUniversalProfile.phMixedSoilLargePot,
    'landscape' || 'open_ground' => RoseUniversalProfile.phLandscapeGround,
    'unknown' => RoseUniversalProfile.phUnknownContext,
    _ => fallback,
  };
}

/// Pesos del AgroScore por etapa. Cada fila suma 1.00.
StageWeights resolveRoseStageWeights(String? stageId, {String? profileId}) {
  final p = _profileForStage(stageId);
  return StageWeights(
    moisture: p.wMoisture,
    soilTemp: p.wSoilTemp,
    resistance: p.wResistance,
    ph: p.wPh,
    ec: p.wEc,
    n: p.wN,
    p: p.wP,
    k: p.wK,
  );
}

/// Nota corta de cuidado por etapa, en lenguaje de agricultor.
String roseStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;
