import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';

/// Perfil universal agronómico del Cempasúchil (Documento B).
///
/// MISMAS UNIDADES REALES que el resto de BIO-G (frijol, hortalizas, granos,
/// árboles, ornamentales). No negociable: dashboard, alertas y NPK comparan
/// contra estas unidades (Documento B §1.1).
///   - humedad     → % en la escala operativa BIO-G (0..100)
///   - temperatura → °C de SUELO (no de aire)
///   - pH          → pH
///   - EC          → mS/cm   (se evalúa internamente; NO sustituye Resistencia)
///   - resistencia → MPa
///   - N / P / K   → mg/kg   orientativos (rangos explícitos de suficiencia)
///
/// Doctrina del Cempasúchil (Documento B §0):
///   - regla maestra: Humedad → Temperatura → EC → pH → Resistencia → NPK;
///   - NO es una planta de fertilización alta por defecto: el exceso de N
///     favorece follaje y puede retrasar o reducir la floración;
///   - germinación y emergencia son las etapas más sensibles a saturación,
///     sales, costra y frío;
///   - botón y floración son las más sensibles al déficit hídrico y al calor;
///   - el pH se resuelve por PERFIL/CONTEXTO, no por etapa; la etapa solo
///     cambia su peso (§7);
///   - la EC baja NO es defecto ni urgencia: `lowMax` conservador viene del
///     Documento B §8;
///   - resistencia usa `lowMax = -1` para no penalizar un medio "demasiado
///     suelto" (§9);
///   - luz y fotoperiodo NO son métricas de la sonda: no entran a StageWeights
///     (§19.1);
///   - `cycle_complete` conserva una fila técnica NEUTRALIZADA, y el motor
///     terminal la ignora (§0.2, §21, §24.3).
class MarigoldUniversalProfile {
  const MarigoldUniversalProfile._();

  /// Caps NPK congelados (Documento B §0, §10.4): N 110 · P 75 · K 280 mg/kg.
  /// Normalizan el gauge; NO son dosis ni recomendaciones de fertilización.
  /// Comparación interna (§10.5): el Girasol usa 130/90/300; el Cempasúchil
  /// baja N por su menor demanda de jardín y su riesgo de exceso vegetativo,
  /// baja P para que no se lea como "flor booster" y conserva K alto pero por
  /// debajo del Girasol.
  static const double capN = 110.0;
  static const double capP = 75.0;
  static const double capK = 280.0;

  /// Rango legacy neutralizado para nIndex/pIndex/kIndex. El motor usa los
  /// rangos explícitos en mg/kg (`nSoilPpmRange`, …), no estos índices; nunca
  /// se muestran al usuario.
  static const AgroRange neutralLegacyNpk = AgroRange(
    lowMax: -1,
    optimalMin: 0,
    optimalMax: 100,
    highMin: 101,
  );

  // ── pH por perfil / contexto (Documento B §7). El pH NO cambia por etapa;
  // solo su peso. El contexto describe el MEDIO y el perfil la ARQUITECTURA:
  // cuando se contradicen gana el contexto para pH, con caution, y el perfil no
  // se cambia (§7 regla de contexto). ──────────────────────────────────────────
  static const AgroRange phTraditionalField = AgroRange(
    lowMax: 5.3,
    optimalMin: 6.0,
    optimalMax: 7.5,
    highMin: 8.2,
  );
  static const AgroRange phTallCutFlower = AgroRange(
    lowMax: 5.5,
    optimalMin: 6.2,
    optimalMax: 7.5,
    highMin: 8.1,
  );
  static const AgroRange phCompactContainer = AgroRange(
    lowMax: 5.2,
    optimalMin: 5.8,
    optimalMax: 6.6,
    highMin: 7.3,
  );
  static const AgroRange phLandscapeBedding = AgroRange(
    lowMax: 5.3,
    optimalMin: 6.0,
    optimalMax: 7.3,
    highMin: 8.0,
  );
  static const AgroRange phGeneral = AgroRange(
    lowMax: 5.2,
    optimalMin: 5.8,
    optimalMax: 7.3,
    highMin: 8.0,
  );

  // ── Umbrales de aire (Documento B §18). NO sustituyen la temperatura de
  // suelo y NO representan temperaturas letales exactas. ──────────────────────
  static const double airFrostMaxC = 0.0;
  static const double airColdMaxC = 8.0;
  static const double airHeatMinC = 34.0;
  static const double airExtremeHeatMinC = 40.0;
  static const double airHumidityHighPct = 78.0;
  static const double airHumidityCriticalPct = 88.0;
}

/// Datos por etapa. Mismo patrón que `SunflowerUniversalProfile` /
/// `RoseUniversalProfile`. Cada fila de pesos suma 1.00 (Documento B §14).
class _MarigoldStageProfile {
  const _MarigoldStageProfile({
    required this.moisture,
    required this.soilTemp,
    required this.ec,
    required this.resistance,
    required this.nPpm,
    required this.pPpm,
    required this.kPpm,
    required this.nPriority,
    required this.pPriority,
    required this.kPriority,
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
  final AgroRange ec;
  final AgroRange resistance;
  final AgroRange nPpm;
  final AgroRange pPpm;
  final AgroRange kPpm;
  final double nPriority;
  final double pPriority;
  final double kPriority;
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

// Targets, prioridades, pesos, ventanas y notas por etapa (Documento B §5–§21).
const Map<String, _MarigoldStageProfile> _marigoldStageProfiles =
    <String, _MarigoldStageProfile>{
      MarigoldStageIds.sowing: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 26, optimalMin: 44, optimalMax: 72, highMin: 85),
        soilTemp: AgroRange(lowMax: 14, optimalMin: 20, optimalMax: 27, highMin: 33),
        ec: AgroRange(lowMax: 0.15, optimalMin: 0.3, optimalMax: 0.9, highMin: 1.5),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 0.9, highMin: 1.5),
        nPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 50),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 32, highMin: 50),
        kPpm: AgroRange(lowMax: 35, optimalMin: 60, optimalMax: 130, highMin: 180),
        nPriority: 0.15,
        pPriority: 0.60,
        kPriority: 0.35,
        wMoisture: 0.31,
        wSoilTemp: 0.17,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.17,
        wN: 0.04,
        wP: 0.07,
        wK: 0.06,
        nWindowEs: 'Sin empuje',
        pWindowEs: 'Arranque y raíz',
        kWindowEs: 'Balance inicial',
        nGuidanceEs:
            'La semilla no necesita nitrógeno alto. Una concentración elevada junto a la semilla aumenta el riesgo de sales y no acelera la emergencia.',
        pGuidanceEs:
            'El fósforo acompaña el arranque radicular, pero una lectura baja de la sonda no demuestra una deficiencia ni define una dosis.',
        kGuidanceEs:
            'El potasio aporta balance osmótico inicial; no compensa una cama endurecida, salina o saturada.',
        careNoteEs:
            'Mantén húmeda la zona de siembra sin convertirla en lodo. Conserva '
            'una superficie suelta, drenaje libre y sales bajas.',
      ),
      MarigoldStageIds.germination: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 28, optimalMin: 46, optimalMax: 74, highMin: 86),
        soilTemp: AgroRange(lowMax: 14, optimalMin: 20, optimalMax: 27, highMin: 33),
        ec: AgroRange(lowMax: 0.15, optimalMin: 0.3, optimalMax: 0.9, highMin: 1.5),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 0.9, highMin: 1.5),
        nPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 30, highMin: 50),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 32, highMin: 50),
        kPpm: AgroRange(lowMax: 35, optimalMin: 60, optimalMax: 130, highMin: 180),
        nPriority: 0.12,
        pPriority: 0.65,
        kPriority: 0.38,
        wMoisture: 0.33,
        wSoilTemp: 0.16,
        wPh: 0.05,
        wEc: 0.13,
        wResistance: 0.16,
        wN: 0.03,
        wP: 0.08,
        wK: 0.06,
        nWindowEs: 'Sin demanda fuerte',
        pWindowEs: 'Radícula y energía',
        kWindowEs: 'Balance osmótico',
        nGuidanceEs:
            'La germinación depende primero de agua, temperatura y contacto con el medio. No empujes nitrógeno en esta ventana.',
        pGuidanceEs:
            'El fósforo acompaña la raíz nueva; la prioridad sigue siendo humedad estable y baja salinidad.',
        kGuidanceEs:
            'El potasio no debe dominar mientras la radícula apenas emerge.',
        careNoteEs:
            'La radícula necesita humedad continua y aire. Evita secado '
            'superficial prolongado, saturación y fertilizante concentrado.',
      ),
      MarigoldStageIds.emergence: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 24, optimalMin: 42, optimalMax: 72, highMin: 84),
        soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 27, highMin: 33),
        ec: AgroRange(lowMax: 0.2, optimalMin: 0.4, optimalMax: 1.2, highMin: 1.8),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 38, highMin: 60),
        pPpm: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 36, highMin: 55),
        kPpm: AgroRange(lowMax: 45, optimalMin: 75, optimalMax: 150, highMin: 210),
        nPriority: 0.30,
        pPriority: 0.65,
        kPriority: 0.45,
        wMoisture: 0.32,
        wSoilTemp: 0.15,
        wPh: 0.05,
        wEc: 0.12,
        wResistance: 0.16,
        wN: 0.05,
        wP: 0.08,
        wK: 0.07,
        nWindowEs: 'Arranque prudente',
        pWindowEs: 'Implantación',
        kWindowEs: 'Firmeza inicial',
        nGuidanceEs:
            'La plántula tiene poca raíz. El nitrógeno puede acompañar, pero no debe superar la prioridad del agua y la aireación.',
        pGuidanceEs:
            'El fósforo conserva una prioridad relativa moderada durante la implantación.',
        kGuidanceEs:
            'El potasio acompaña la regulación de agua mientras se abren los cotiledones y las primeras hojas.',
        careNoteEs:
            'Evita que la superficie forme costra. La plántula necesita humedad '
            'uniforme, buena luz y ventilación sin encharcamiento.',
      ),
      MarigoldStageIds.earlyVegetativeGrowth: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 20, optimalMin: 36, optimalMax: 68, highMin: 82),
        soilTemp: AgroRange(lowMax: 11, optimalMin: 17, optimalMax: 29, highMin: 35),
        ec: AgroRange(lowMax: 0.25, optimalMin: 0.5, optimalMax: 1.5, highMin: 2.2),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.1, highMin: 1.7),
        nPpm: AgroRange(lowMax: 15, optimalMin: 25, optimalMax: 52, highMin: 80),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 40, highMin: 60),
        kPpm: AgroRange(lowMax: 55, optimalMin: 90, optimalMax: 175, highMin: 230),
        nPriority: 0.55,
        pPriority: 0.60,
        kPriority: 0.50,
        wMoisture: 0.28,
        wSoilTemp: 0.13,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.13,
        wN: 0.11,
        wP: 0.09,
        wK: 0.09,
        nWindowEs: 'Crecimiento moderado',
        pWindowEs: 'Raíz y expansión',
        kWindowEs: 'Turgencia y estructura',
        nGuidanceEs:
            'El nitrógeno ya gana utilidad para hojas y ramificación, pero el exceso adelgaza el tejido y puede retrasar la transición floral.',
        pGuidanceEs:
            'El fósforo acompaña raíz y energía; no debe presentarse como una orden de fertilización.',
        kGuidanceEs:
            'El potasio acompaña turgencia y tolerancia al estrés mientras aumenta el área foliar.',
        careNoteEs:
            'Deja que la raíz explore un medio suelto. Mantén humedad regular, '
            'sin riegos repetidos cuando la zona sigue mojada.',
      ),
      MarigoldStageIds.activeVegetativeGrowth: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 18, optimalMin: 34, optimalMax: 66, highMin: 80),
        soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 30, highMin: 36),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.6, optimalMax: 1.8, highMin: 2.6),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.3, highMin: 1.9),
        nPpm: AgroRange(lowMax: 20, optimalMin: 35, optimalMax: 68, highMin: 100),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 65),
        kPpm: AgroRange(lowMax: 65, optimalMin: 110, optimalMax: 200, highMin: 250),
        nPriority: 0.90,
        pPriority: 0.50,
        kPriority: 0.65,
        wMoisture: 0.25,
        wSoilTemp: 0.11,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.10,
        wN: 0.16,
        wP: 0.10,
        wK: 0.11,
        nWindowEs: 'Demanda vegetativa activa',
        pWindowEs: 'Demanda moderada',
        kWindowEs: 'Estructura y balance',
        nGuidanceEs:
            'El nitrógeno tiene su mayor utilidad relativa durante la expansión vegetativa. El exceso, sin embargo, favorece mucho follaje, retraso floral y tallos blandos.',
        pGuidanceEs:
            'El fósforo acompaña metabolismo y raíz; no domina el score.',
        kGuidanceEs:
            'El potasio ayuda a regular agua y sostener tejido en expansión.',
        careNoteEs:
            'Busca crecimiento firme, no crecimiento forzado. Revisa agua, '
            'sales y luz antes de interpretar una lectura NPK baja.',
      ),
      MarigoldStageIds.stemElongation: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 18, optimalMin: 34, optimalMax: 66, highMin: 80),
        soilTemp: AgroRange(lowMax: 13, optimalMin: 19, optimalMax: 30, highMin: 36),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.6, optimalMax: 1.8, highMin: 2.6),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 18, optimalMin: 30, optimalMax: 62, highMin: 90),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 65),
        kPpm: AgroRange(lowMax: 70, optimalMin: 115, optimalMax: 210, highMin: 260),
        nPriority: 0.70,
        pPriority: 0.45,
        kPriority: 0.80,
        wMoisture: 0.24,
        wSoilTemp: 0.11,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.12,
        wN: 0.14,
        wP: 0.10,
        wK: 0.12,
        nWindowEs: 'Estructura sin exceso',
        pWindowEs: 'Continuidad metabólica',
        kWindowEs: 'Firmeza del tallo',
        nGuidanceEs:
            'El nitrógeno mantiene crecimiento, pero una carga alta eleva el riesgo de elongación débil y retraso de botones.',
        pGuidanceEs: 'El fósforo permanece en una ventana moderada.',
        kGuidanceEs:
            'El potasio gana valor relativo para firmeza y regulación hídrica, especialmente en perfiles altos.',
        careNoteEs:
            'Conserva humedad estable y evita exceso de nitrógeno. En plantas '
            'altas, el anclaje y la resistencia del suelo se vuelven más '
            'importantes.',
      ),
      MarigoldStageIds.budFormation: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 22, optimalMin: 40, optimalMax: 70, highMin: 82),
        soilTemp: AgroRange(lowMax: 13, optimalMin: 18, optimalMax: 29, highMin: 34),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.7, optimalMax: 2.0, highMin: 2.8),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 14, optimalMin: 24, optimalMax: 50, highMin: 75),
        pPpm: AgroRange(lowMax: 14, optimalMin: 24, optimalMax: 50, highMin: 70),
        kPpm: AgroRange(lowMax: 75, optimalMin: 125, optimalMax: 220, highMin: 270),
        nPriority: 0.45,
        pPriority: 0.55,
        kPriority: 0.90,
        wMoisture: 0.28,
        wSoilTemp: 0.12,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.08,
        wN: 0.10,
        wP: 0.10,
        wK: 0.14,
        nWindowEs: 'Reducir empuje vegetativo',
        pWindowEs: 'Botón y energía',
        kWindowEs: 'Alta prioridad relativa',
        nGuidanceEs:
            'El nitrógeno deja de ser el protagonista. Una concentración alta puede mantener follaje a costa de la arquitectura floral.',
        pGuidanceEs:
            'El fósforo acompaña la formación de botones, pero una lectura aislada no autoriza una corrección fuerte.',
        kGuidanceEs:
            'El potasio alcanza alta prioridad relativa por regulación de agua, firmeza y desarrollo floral.',
        careNoteEs:
            'El botón es sensible a sequedad, calor y sales. Mantén humedad '
            'regular y evita cambios bruscos de manejo.',
      ),
      MarigoldStageIds.flowering: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 22, optimalMin: 40, optimalMax: 70, highMin: 82),
        soilTemp: AgroRange(lowMax: 12, optimalMin: 17, optimalMax: 28, highMin: 33),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.7, optimalMax: 2.0, highMin: 2.8),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 70),
        pPpm: AgroRange(lowMax: 12, optimalMin: 22, optimalMax: 48, highMin: 68),
        kPpm: AgroRange(lowMax: 75, optimalMin: 125, optimalMax: 220, highMin: 270),
        nPriority: 0.35,
        pPriority: 0.45,
        kPriority: 0.90,
        wMoisture: 0.30,
        wSoilTemp: 0.12,
        wPh: 0.06,
        wEc: 0.13,
        wResistance: 0.07,
        wN: 0.08,
        wP: 0.09,
        wK: 0.15,
        nWindowEs: 'Mantenimiento bajo',
        pWindowEs: 'Demanda moderada',
        kWindowEs: 'Flor y duración',
        nGuidanceEs:
            'Durante la floración, el exceso de nitrógeno ya no mejora la prioridad ornamental y puede aumentar tejido blando.',
        pGuidanceEs:
            'El fósforo acompaña la actividad reproductiva, sin convertirse en receta.',
        kGuidanceEs:
            'El potasio conserva el mayor peso nutrimental relativo durante la apertura y permanencia floral.',
        careNoteEs:
            'Evita déficit hídrico, calor sostenido y humedad persistente sobre '
            'flores. No riegues por calendario si la zona sigue húmeda.',
      ),
      MarigoldStageIds.postBloom: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 16, optimalMin: 30, optimalMax: 60, highMin: 76),
        soilTemp: AgroRange(lowMax: 10, optimalMin: 15, optimalMax: 27, highMin: 33),
        ec: AgroRange(lowMax: 0.25, optimalMin: 0.5, optimalMax: 1.6, highMin: 2.4),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.1),
        nPpm: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 38, highMin: 60),
        pPpm: AgroRange(lowMax: 8, optimalMin: 14, optimalMax: 34, highMin: 55),
        kPpm: AgroRange(lowMax: 50, optimalMin: 85, optimalMax: 170, highMin: 230),
        nPriority: 0.25,
        pPriority: 0.25,
        kPriority: 0.55,
        wMoisture: 0.27,
        wSoilTemp: 0.12,
        wPh: 0.07,
        wEc: 0.13,
        wResistance: 0.09,
        wN: 0.08,
        wP: 0.08,
        wK: 0.16,
        nWindowEs: 'Demanda descendente',
        pWindowEs: 'Demanda baja',
        kWindowEs: 'Sostén residual',
        nGuidanceEs:
            'La demanda de nitrógeno desciende. No intentes devolver la planta al vegetativo con una lectura aislada.',
        pGuidanceEs:
            'El fósforo tiene baja prioridad una vez que domina el envejecimiento floral.',
        kGuidanceEs:
            'El potasio conserva una prioridad relativa moderada para el tejido que sigue activo.',
        careNoteEs:
            'Ajusta el agua a la menor actividad. Una flor seca no obliga a '
            'cerrar el ciclo si todavía hay botones y tejido verde activo.',
      ),
      MarigoldStageIds.senescence: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 10, optimalMin: 20, optimalMax: 48, highMin: 68),
        soilTemp: AgroRange(lowMax: 6, optimalMin: 12, optimalMax: 24, highMin: 31),
        ec: AgroRange(lowMax: 0.15, optimalMin: 0.3, optimalMax: 1.2, highMin: 2.0),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.6, highMin: 2.2),
        nPpm: AgroRange(lowMax: 6, optimalMin: 10, optimalMax: 26, highMin: 45),
        pPpm: AgroRange(lowMax: 5, optimalMin: 9, optimalMax: 24, highMin: 40),
        kPpm: AgroRange(lowMax: 30, optimalMin: 50, optimalMax: 120, highMin: 180),
        nPriority: 0.10,
        pPriority: 0.10,
        kPriority: 0.20,
        wMoisture: 0.27,
        wSoilTemp: 0.16,
        wPh: 0.07,
        wEc: 0.13,
        wResistance: 0.10,
        wN: 0.06,
        wP: 0.06,
        wK: 0.15,
        nWindowEs: 'Sin empuje',
        pWindowEs: 'Baja prioridad',
        kWindowEs: 'Actividad residual',
        nGuidanceEs:
            'La anual está cerrando el ciclo. No se debe empujar follaje nuevo con nitrógeno.',
        pGuidanceEs:
            'El fósforo pierde prioridad agronómica en la salida del ciclo.',
        kGuidanceEs: 'El potasio se mantiene informativo, no prescriptivo.',
        careNoteEs:
            'Reduce expectativas de crecimiento. Confirma que el declive sea '
            'general antes de tratarlo como senescencia y no como daño '
            'localizado.',
      ),
      // Fila técnica NEUTRALIZADA: el motor terminal la ignora (Documento B
      // §21, §24.3): sin alertas, prioridad NPK cero, sin consejos activos.
      MarigoldStageIds.cycleComplete: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 100, highMin: 101),
        soilTemp: AgroRange(lowMax: -100, optimalMin: -50, optimalMax: 80, highMin: 100),
        ec: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 100, highMin: 101),
        resistance: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 10, highMin: 11),
        nPpm: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 110, highMin: 111),
        pPpm: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 75, highMin: 76),
        kPpm: AgroRange(lowMax: -1, optimalMin: 0, optimalMax: 280, highMin: 281),
        nPriority: 0.0,
        pPriority: 0.0,
        kPriority: 0.0,
        wMoisture: 0.25,
        wSoilTemp: 0.18,
        wPh: 0.07,
        wEc: 0.14,
        wResistance: 0.10,
        wN: 0.06,
        wP: 0.06,
        wK: 0.14,
        nWindowEs: 'Terminal',
        pWindowEs: 'Terminal',
        kWindowEs: 'Terminal',
        // El Documento B §21 redacta este mensaje en clave interna ("la fila
        // existe solo para seguridad del contrato"). Aquí se conserva su
        // significado en lenguaje visible: `nShortGuidanceEs` puede pintarse en
        // la tarjeta de NPK y no debe mostrarle jerga de implementación a la
        // persona.
        nGuidanceEs:
            'El ciclo terminó; el motor terminal ignora las recomendaciones de '
            'NPK.',
        pGuidanceEs: 'Sin recomendación activa.',
        kGuidanceEs: 'Sin recomendación activa.',
        careNoteEs:
            'Este Cempasúchil terminó su ciclo. Para cultivar otro, registra '
            'una nueva siembra.',
      ),
      // Banda conservadora por confirmar (Documento B §21). Debe auto-repararse
      // cuando exista fecha y perfil; NUNCA hereda una etapa del Girasol.
      MarigoldStageIds.unknown: _MarigoldStageProfile(
        moisture: AgroRange(lowMax: 18, optimalMin: 34, optimalMax: 66, highMin: 82),
        soilTemp: AgroRange(lowMax: 11, optimalMin: 17, optimalMax: 29, highMin: 35),
        ec: AgroRange(lowMax: 0.25, optimalMin: 0.5, optimalMax: 1.6, highMin: 2.4),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.3, highMin: 2.0),
        nPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 70),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 40, highMin: 60),
        kPpm: AgroRange(lowMax: 55, optimalMin: 90, optimalMax: 180, highMin: 240),
        nPriority: 0.40,
        pPriority: 0.40,
        kPriority: 0.50,
        wMoisture: 0.30,
        wSoilTemp: 0.14,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.12,
        wN: 0.08,
        wP: 0.08,
        wK: 0.10,
        nWindowEs: 'Revisión prudente',
        pWindowEs: 'Revisión prudente',
        kWindowEs: 'Revisión prudente',
        nGuidanceEs:
            'Sin etapa confirmada, el nitrógeno no puede escalar a una acción fuerte.',
        pGuidanceEs:
            'Confirma etapa, humedad, pH y EC antes de interpretar fósforo.',
        kGuidanceEs:
            'El potasio se mantiene visible con prioridad moderada-baja.',
        careNoteEs:
            'Confirma la fecha o el estado visible. Mientras tanto, BIO-G usa '
            'bandas amplias y mensajes conservadores.',
      ),
    };

_MarigoldStageProfile _profileForStage(String? stageId) {
  final id = normalizeMarigoldStageId(stageId);
  return _marigoldStageProfiles[id] ??
      _marigoldStageProfiles[MarigoldStageIds.unknown]!;
}

// ── Contexto de cultivo por perfil (Documento B §7, §15) ─────────────────────
enum MarigoldAgroContext {
  traditionalField,
  tallCutFlower,
  compactContainer,
  landscapeBedding,
  general,
}

MarigoldAgroContext marigoldAgroContextForProfile(String? profileId) {
  switch (profileId?.trim().toLowerCase()) {
    case kCs01TraditionalField:
      return MarigoldAgroContext.traditionalField;
    case kCs02TallCutFlower:
      return MarigoldAgroContext.tallCutFlower;
    case kCs03CompactContainer:
      return MarigoldAgroContext.compactContainer;
    case kCs04LandscapeBedding:
      return MarigoldAgroContext.landscapeBedding;
    case kCsSkip:
    default:
      return MarigoldAgroContext.general;
  }
}

AgroRange _phForContext(MarigoldAgroContext ctx) {
  switch (ctx) {
    case MarigoldAgroContext.traditionalField:
      return MarigoldUniversalProfile.phTraditionalField;
    case MarigoldAgroContext.tallCutFlower:
      return MarigoldUniversalProfile.phTallCutFlower;
    case MarigoldAgroContext.compactContainer:
      return MarigoldUniversalProfile.phCompactContainer;
    case MarigoldAgroContext.landscapeBedding:
      return MarigoldUniversalProfile.phLandscapeBedding;
    case MarigoldAgroContext.general:
      return MarigoldUniversalProfile.phGeneral;
  }
}

/// Etapas "vivas" (siembra → senescencia): reciben los ajustes de contenedor.
/// `cycle_complete` y `unknown` quedan fuera (Documento B §15 regla 7).
const Set<String> _liveStageIds = <String>{
  MarigoldStageIds.sowing,
  MarigoldStageIds.germination,
  MarigoldStageIds.emergence,
  MarigoldStageIds.earlyVegetativeGrowth,
  MarigoldStageIds.activeVegetativeGrowth,
  MarigoldStageIds.stemElongation,
  MarigoldStageIds.budFormation,
  MarigoldStageIds.flowering,
  MarigoldStageIds.postBloom,
  MarigoldStageIds.senescence,
};

/// Etapas donde el perfil de corte refuerza el peso del potasio (Documento B
/// §15 CS-02).
const Set<String> _stemToFloweringIds = <String>{
  MarigoldStageIds.stemElongation,
  MarigoldStageIds.budFormation,
  MarigoldStageIds.flowering,
};

/// Targets base de sensor por etapa, en unidades reales (sin modificadores de
/// perfil). Usa pH general por defecto.
StageTargets resolveMarigoldTargets(String? stageId) {
  final p = _profileForStage(stageId);
  return _buildTargets(p, MarigoldUniversalProfile.phGeneral);
}

/// Targets ajustados por el contexto de cultivo que implica el perfil
/// (Documento B §7 pH + §15 deltas cuantitativos). No se duplica una tabla
/// completa por perfil: se parte de la base y se aplican deltas. El orden final
/// `lowMax <= optimalMin <= optimalMax <= highMin` se conserva (§15 regla 7).
///
/// `cultivationContextId` es OPCIONAL y solo afecta al pH (Documento B §7 regla
/// de contexto): un `pot`/`nursery` puede estrechar una banda de campo al rango
/// de contenedor, pero el perfil NO se cambia y `open_ground` nunca hereda el
/// pH de maceta solo porque la planta sea compacta. El runtime v1 no persiste
/// este dato todavía; cuando exista, basta con pasarlo aquí.
StageTargets resolveMarigoldTargetsForProfile(
  String? stageId, {
  required String? profileId,
  String? cultivationContextId,
}) {
  final id = normalizeMarigoldStageId(stageId);
  final p = _profileForStage(id);
  final ctx = marigoldAgroContextForProfile(profileId);

  AgroRange moisture = p.moisture;
  AgroRange soilTemp = p.soilTemp;
  AgroRange ec = p.ec;
  AgroRange resistance = p.resistance;
  AgroRange nPpm = p.nPpm;
  AgroRange pPpm = p.pPpm;
  AgroRange kPpm = p.kPpm;

  final bool live = _liveStageIds.contains(id);
  final cultivation = marigoldCultivationContextFromId(cultivationContextId);
  final bool containerMedium = marigoldContextIsContainer(cultivation);
  final bool applyContainerDeltas =
      live && (ctx == MarigoldAgroContext.compactContainer || containerMedium);

  // Maceta / vivero (Documento B §15 CS-03, §23.1): se seca y se satura
  // rápido, acumula sales y confina la raíz.
  if (applyContainerDeltas) {
    moisture = _shift(moisture, lowMax: 1, highMin: -4);
    ec = _shift(ec, optMax: -0.20, highMin: -0.30);
  }

  // CS-01/CS-02/CS-04/CS-SKIP no aplican deltas cuantitativos de target: sus
  // ajustes son de pH, de severidad y de peso (Documento B §15).

  return _buildTargets(
    p,
    _phForContextAndMedium(ctx, cultivation),
    moisture: moisture,
    soilTemp: soilTemp,
    ec: ec,
    resistance: resistance,
    nPpm: nPpm,
    pPpm: pPpm,
    kPpm: kPpm,
    limitNpkPriority:
        ctx == MarigoldAgroContext.general ||
        id == MarigoldStageIds.unknown,
  );
}

/// pH efectivo: el perfil describe la arquitectura y el contexto el medio.
/// Cuando el medio confirmado es un contenedor, gana la banda estrecha de
/// maceta (Documento B §7 regla de contexto). `open_ground` NO impone la banda
/// de campo sobre un perfil compacto: el compacto ya usa su propia banda.
AgroRange _phForContextAndMedium(
  MarigoldAgroContext ctx,
  MarigoldCultivationContext cultivation,
) {
  if (marigoldContextIsContainer(cultivation)) {
    return MarigoldUniversalProfile.phCompactContainer;
  }
  return _phForContext(ctx);
}

/// Pesos del AgroScore por etapa (Documento B §14). Cada fila base suma 1.00.
/// Dos perfiles ajustan pesos y RENORMALIZAN (Documento B §15):
///   - CS-02 (alto de corte): peso de K ×1.05 en tallo, botón y floración;
///   - CS-03 (compacto de maceta): pesos NPK activos ×0.95.
/// El resto usa la fila base sin tocar.
StageWeights resolveMarigoldStageWeights(String? stageId, {String? profileId}) {
  final id = normalizeMarigoldStageId(stageId);
  final p = _profileForStage(id);
  final ctx = marigoldAgroContextForProfile(profileId);

  double wMoisture = p.wMoisture;
  double wSoilTemp = p.wSoilTemp;
  double wPh = p.wPh;
  double wEc = p.wEc;
  double wResistance = p.wResistance;
  double wN = p.wN;
  double wP = p.wP;
  double wK = p.wK;

  final bool live = _liveStageIds.contains(id);

  if (live && ctx == MarigoldAgroContext.tallCutFlower &&
      _stemToFloweringIds.contains(id)) {
    wK *= 1.05;
  } else if (live && ctx == MarigoldAgroContext.compactContainer) {
    wN *= 0.95;
    wP *= 0.95;
    wK *= 0.95;
  }

  // Renormalizar a 1.00 (Documento B §15 regla 6, §26.2).
  final sum = wMoisture + wSoilTemp + wPh + wEc + wResistance + wN + wP + wK;
  if (sum > 0 && (sum - 1.0).abs() > 1e-9) {
    wMoisture /= sum;
    wSoilTemp /= sum;
    wPh /= sum;
    wEc /= sum;
    wResistance /= sum;
    wN /= sum;
    wP /= sum;
    wK /= sum;
  }

  return StageWeights(
    moisture: wMoisture,
    soilTemp: wSoilTemp,
    resistance: wResistance,
    ph: wPh,
    ec: wEc,
    n: wN,
    p: wP,
    k: wK,
  );
}

/// Nota corta de cuidado por etapa (Documento B §21).
String marigoldStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;

/// Prioridad NPK "cruda" declarada por la etapa, útil para pruebas y para la
/// UI de NPK. No sustituye a `StageTargets.resolved*Priority01`.
({double n, double p, double k}) marigoldStageNpkPriority(String? stageId) {
  final s = _profileForStage(stageId);
  return (n: s.nPriority, p: s.pPriority, k: s.kPriority);
}

// ── Helpers de construcción/ajuste ───────────────────────────────────────────

StageTargets _buildTargets(
  _MarigoldStageProfile p,
  AgroRange ph, {
  AgroRange? moisture,
  AgroRange? soilTemp,
  AgroRange? ec,
  AgroRange? resistance,
  AgroRange? nPpm,
  AgroRange? pPpm,
  AgroRange? kPpm,
  bool limitNpkPriority = false,
}) {
  // `cs_skip` y la etapa por confirmar limitan la prioridad NPK a lenguaje de
  // REVISIÓN: ninguna lectura aislada escala a "acción recomendada"
  // (Documento B §15 CS-SKIP, §20.1). El techo 0.5 evita que el motor de
  // nutrición promueva una prioridad alta desde un contexto no confirmado.
  double cap(double value) => limitNpkPriority ? math.min(value, 0.5) : value;

  return StageTargets(
    moistureRaw: moisture ?? p.moisture,
    soilTemp: soilTemp ?? p.soilTemp,
    ph: ph,
    ec: ec ?? p.ec,
    resistance: resistance ?? p.resistance,
    // Índices legacy neutralizados: el motor usa los rangos explícitos en mg/kg.
    nIndex: MarigoldUniversalProfile.neutralLegacyNpk,
    pIndex: MarigoldUniversalProfile.neutralLegacyNpk,
    kIndex: MarigoldUniversalProfile.neutralLegacyNpk,
    nSoilPpmRange: nPpm ?? p.nPpm,
    pSoilPpmRange: pPpm ?? p.pPpm,
    kSoilPpmRange: kPpm ?? p.kPpm,
    nPriority: cap(p.nPriority),
    pPriority: cap(p.pPriority),
    kPriority: cap(p.kPriority),
    nWindowLabelEs: p.nWindowEs,
    pWindowLabelEs: p.pWindowEs,
    kWindowLabelEs: p.kWindowEs,
    nShortGuidanceEs: p.nGuidanceEs,
    pShortGuidanceEs: p.pGuidanceEs,
    kShortGuidanceEs: p.kGuidanceEs,
  );
}

/// Desplaza una banda por deltas conservando el orden
/// `lowMax <= optimalMin <= optimalMax <= highMin`.
AgroRange _shift(
  AgroRange r, {
  double lowMax = 0,
  double optMin = 0,
  double optMax = 0,
  double highMin = 0,
}) {
  final newOptMin = r.optimalMin + optMin;
  final newOptMax = math.max(newOptMin, r.optimalMax + optMax);
  final newHighMin = math.max(newOptMax, r.highMin + highMin);
  final newLowMax = math.min(r.lowMax + lowMax, newOptMin);
  return AgroRange(
    lowMax: newLowMax,
    optimalMin: newOptMin,
    optimalMax: newOptMax,
    highMin: newHighMin,
  );
}
