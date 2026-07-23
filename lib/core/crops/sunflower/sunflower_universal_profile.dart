import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';

/// Perfil universal agronómico del Girasol (Documento B).
///
/// MISMAS UNIDADES REALES que el resto de BIO-G (frijol, hortalizas, granos,
/// árboles, ornamentales). No negociable: dashboard, alertas y NPK comparan
/// contra estas unidades (Documento B §1.1).
///   - humedad     → % en la escala calibrada BIO-G (0..100)
///   - temperatura → °C
///   - pH          → pH
///   - EC          → mS/cm   (se evalúa internamente; NO sustituye Resistencia)
///   - resistencia → MPa
///   - N / P / K   → mg/kg   orientativos (rangos explícitos de suficiencia)
///
/// Doctrina del Girasol (Documento B §0.1, §0.2):
///   - el AGUA manda; el NPK acompaña, nunca ordena fertilizar;
///   - semilla y plántula son las etapas más sensibles a sales y costra;
///   - botón y floración son las más sensibles a déficit hídrico;
///   - el exceso de N es un riesgo estructural (tallo blando, vuelco);
///   - el pH se resuelve por PERFIL (contexto), no por etapa;
///   - la EC baja NO es defecto: `lowMax = -1` neutraliza falsas deficiencias
///     de la resistencia; para EC el `lowMax` conservador viene del Documento B;
///   - `cycle_complete` conserva una fila técnica, pero el motor terminal la
///     ignora (Documento B §0.2 regla 11, §4).
class SunflowerUniversalProfile {
  const SunflowerUniversalProfile._();

  /// Caps NPK congelados (Documento B §0.3, §11): N 130 · P 90 · K 300 mg/kg.
  /// Normalizan el gauge; NO son dosis ni recomendaciones de fertilización.
  static const double capN = 130.0;
  static const double capP = 90.0;
  static const double capK = 300.0;

  /// Rango legacy neutralizado para nIndex/pIndex/kIndex. El motor usa los
  /// rangos explícitos en mg/kg (`nSoilPpmRange`, …), no estos índices; nunca se
  /// muestran al usuario.
  static const AgroRange neutralLegacyNpk = AgroRange(
    lowMax: -1,
    optimalMin: 0,
    optimalMax: 100,
    highMin: 101,
  );

  // ── pH por perfil / contexto (Documento B §7). El pH NO cambia por etapa;
  // solo su peso. El contexto lo define el perfil. ────────────────────────────
  static const AgroRange phTallGarden = AgroRange(
    lowMax: 5.4,
    optimalMin: 6.0,
    optimalMax: 7.3,
    highMin: 8.0,
  );
  static const AgroRange phCompactContainer = AgroRange(
    lowMax: 4.9,
    optimalMin: 5.5,
    optimalMax: 6.5,
    highMin: 7.2,
  );
  static const AgroRange phBranchingOrnamental = AgroRange(
    lowMax: 5.0,
    optimalMin: 5.6,
    optimalMax: 6.8,
    highMin: 7.4,
  );
  static const AgroRange phCutFlower = AgroRange(
    lowMax: 5.3,
    optimalMin: 5.8,
    optimalMax: 7.2,
    highMin: 7.8,
  );
  static const AgroRange phGeneral = AgroRange(
    lowMax: 5.2,
    optimalMin: 5.8,
    optimalMax: 7.2,
    highMin: 7.8,
  );
}

/// Datos por etapa. Mismo patrón que `RoseUniversalProfile` /
/// `TulipUniversalProfile`. Cada fila de pesos suma 1.00 (Documento B §13).
class _SunflowerStageProfile {
  const _SunflowerStageProfile({
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

// Targets, prioridades, pesos, ventanas y notas por etapa (Documento B §4–§17).
const Map<String, _SunflowerStageProfile> _sunflowerStageProfiles =
    <String, _SunflowerStageProfile>{
      SunflowerStageIds.sowing: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 24, optimalMin: 40, optimalMax: 70, highMin: 84),
        soilTemp: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 28, highMin: 35),
        ec: AgroRange(lowMax: 0.15, optimalMin: 0.35, optimalMax: 1.0, highMin: 1.6),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 40, highMin: 65),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 42, highMin: 65),
        kPpm: AgroRange(lowMax: 50, optimalMin: 85, optimalMax: 160, highMin: 220),
        nPriority: 0.15,
        pPriority: 0.65,
        kPriority: 0.35,
        wMoisture: 0.30,
        wSoilTemp: 0.17,
        wPh: 0.07,
        wEc: 0.11,
        wResistance: 0.18,
        wN: 0.05,
        wP: 0.07,
        wK: 0.05,
        nWindowEs: 'Arranque prudente',
        pWindowEs: 'Raíz y energía',
        kWindowEs: 'Soporte inicial',
        nGuidanceEs:
            'La semilla no necesita nitrógeno alto; el arranque lo lleva el fósforo.',
        pGuidanceEs:
            'El fósforo acompaña la raíz, pero una lectura baja no confirma una deficiencia.',
        kGuidanceEs: 'El potasio da un balance inicial mientras se instala la planta.',
        careNoteEs:
            'Mantén la zona de la semilla húmeda, no lodosa. Evita costra y '
            'fertilizante concentrado junto a la semilla.',
      ),
      SunflowerStageIds.germination: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 24, optimalMin: 42, optimalMax: 72, highMin: 86),
        soilTemp: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 28, highMin: 35),
        ec: AgroRange(lowMax: 0.15, optimalMin: 0.35, optimalMax: 1.0, highMin: 1.6),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
        nPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 40, highMin: 65),
        pPpm: AgroRange(lowMax: 10, optimalMin: 18, optimalMax: 42, highMin: 65),
        kPpm: AgroRange(lowMax: 50, optimalMin: 85, optimalMax: 160, highMin: 220),
        nPriority: 0.15,
        pPriority: 0.70,
        kPriority: 0.40,
        wMoisture: 0.32,
        wSoilTemp: 0.16,
        wPh: 0.06,
        wEc: 0.12,
        wResistance: 0.16,
        wN: 0.04,
        wP: 0.08,
        wK: 0.06,
        nWindowEs: 'Sin empuje',
        pWindowEs: 'Raíz y emergencia',
        kWindowEs: 'Balance osmótico',
        nGuidanceEs:
            'No empujes nitrógeno mientras la semilla es sensible a las sales.',
        pGuidanceEs:
            'El fósforo acompaña la raíz, pero una lectura baja no confirma una deficiencia.',
        kGuidanceEs: 'El potasio da un balance inicial mientras se instala la planta.',
        careNoteEs:
            'La semilla necesita humedad estable y temperatura templada. No dejes '
            'secar la capa de germinación ni la mantengas empapada.',
      ),
      SunflowerStageIds.emergence: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 22, optimalMin: 40, optimalMax: 70, highMin: 84),
        soilTemp: AgroRange(lowMax: 9, optimalMin: 16, optimalMax: 29, highMin: 35),
        ec: AgroRange(lowMax: 0.2, optimalMin: 0.4, optimalMax: 1.2, highMin: 1.8),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.0, highMin: 1.6),
        nPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 70),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 70),
        kPpm: AgroRange(lowMax: 60, optimalMin: 95, optimalMax: 170, highMin: 230),
        nPriority: 0.25,
        pPriority: 0.75,
        kPriority: 0.45,
        wMoisture: 0.31,
        wSoilTemp: 0.15,
        wPh: 0.06,
        wEc: 0.11,
        wResistance: 0.16,
        wN: 0.06,
        wP: 0.08,
        wK: 0.07,
        nWindowEs: 'Arranque moderado',
        pWindowEs: 'Implantación',
        kWindowEs: 'Firmeza inicial',
        nGuidanceEs:
            'Un arranque moderado basta; la plántula aún tiene poca raíz.',
        pGuidanceEs:
            'El fósforo acompaña la raíz, pero una lectura baja no confirma una deficiencia.',
        kGuidanceEs: 'El potasio da firmeza mientras la plántula se implanta.',
        careNoteEs:
            'La plántula todavía tiene poca raíz. Riega con cuidado, conserva '
            'drenaje y evita que el suelo se endurezca sobre ella.',
      ),
      SunflowerStageIds.earlyVegetativeGrowth: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 18, optimalMin: 34, optimalMax: 66, highMin: 80),
        soilTemp: AgroRange(lowMax: 10, optimalMin: 17, optimalMax: 30, highMin: 36),
        ec: AgroRange(lowMax: 0.25, optimalMin: 0.5, optimalMax: 1.5, highMin: 2.2),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.2, highMin: 1.8),
        nPpm: AgroRange(lowMax: 18, optimalMin: 28, optimalMax: 60, highMin: 90),
        pPpm: AgroRange(lowMax: 14, optimalMin: 22, optimalMax: 48, highMin: 75),
        kPpm: AgroRange(lowMax: 70, optimalMin: 110, optimalMax: 180, highMin: 240),
        nPriority: 0.55,
        pPriority: 0.65,
        kPriority: 0.55,
        wMoisture: 0.27,
        wSoilTemp: 0.13,
        wPh: 0.07,
        wEc: 0.11,
        wResistance: 0.13,
        wN: 0.12,
        wP: 0.08,
        wK: 0.09,
        nWindowEs: 'Formación de hojas',
        pWindowEs: 'Raíz activa',
        kWindowEs: 'Balance hídrico',
        nGuidanceEs: 'El nitrógeno acompaña las primeras hojas. Evita excesos.',
        pGuidanceEs: 'Revisa el pH y la humedad antes de interpretar el fósforo.',
        kGuidanceEs: 'El potasio orientativo participa en firmeza y manejo del agua.',
        careNoteEs:
            'La planta comienza a formar hojas y raíz profunda. Deja que el suelo '
            'respire entre riegos sin llevarla a marchitez repetida.',
      ),
      SunflowerStageIds.activeVegetativeGrowth: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 20, optimalMin: 36, optimalMax: 68, highMin: 82),
        soilTemp: AgroRange(lowMax: 11, optimalMin: 18, optimalMax: 30, highMin: 36),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.6, optimalMax: 1.8, highMin: 2.5),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.3, highMin: 1.9),
        nPpm: AgroRange(lowMax: 25, optimalMin: 40, optimalMax: 80, highMin: 110),
        pPpm: AgroRange(lowMax: 14, optimalMin: 22, optimalMax: 50, highMin: 80),
        kPpm: AgroRange(lowMax: 80, optimalMin: 120, optimalMax: 190, highMin: 255),
        nPriority: 0.85,
        pPriority: 0.55,
        kPriority: 0.70,
        wMoisture: 0.25,
        wSoilTemp: 0.12,
        wPh: 0.07,
        wEc: 0.10,
        wResistance: 0.11,
        wN: 0.16,
        wP: 0.08,
        wK: 0.11,
        nWindowEs: 'Máxima demanda vegetativa',
        pWindowEs: 'Soporte continuo',
        kWindowEs: 'Turgencia y estructura',
        nGuidanceEs: 'El nitrógeno acompaña hojas y tallo. Más no siempre es mejor.',
        pGuidanceEs: 'Revisa el pH y la humedad antes de interpretar el fósforo.',
        kGuidanceEs: 'El potasio orientativo participa en firmeza y manejo del agua.',
        careNoteEs:
            'El tallo y las hojas están creciendo con fuerza. Mantén agua estable '
            'y evita empujar solo follaje con demasiado nitrógeno.',
      ),
      SunflowerStageIds.stemElongation: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 22, optimalMin: 40, optimalMax: 72, highMin: 84),
        soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 29, highMin: 35),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.6, optimalMax: 1.8, highMin: 2.5),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.3, highMin: 1.9),
        nPpm: AgroRange(lowMax: 25, optimalMin: 40, optimalMax: 75, highMin: 100),
        pPpm: AgroRange(lowMax: 14, optimalMin: 22, optimalMax: 50, highMin: 80),
        kPpm: AgroRange(lowMax: 85, optimalMin: 125, optimalMax: 195, highMin: 260),
        nPriority: 0.85,
        pPriority: 0.45,
        kPriority: 0.80,
        wMoisture: 0.25,
        wSoilTemp: 0.12,
        wPh: 0.06,
        wEc: 0.10,
        wResistance: 0.13,
        wN: 0.15,
        wP: 0.07,
        wK: 0.12,
        nWindowEs: 'Tallo sin exceso',
        pWindowEs: 'Demanda moderada',
        kWindowEs: 'Firmeza del tallo',
        nGuidanceEs:
            'Demasiado nitrógeno puede volver el tallo blando y fácil de doblar.',
        pGuidanceEs: 'Revisa el pH y la humedad antes de interpretar el fósforo.',
        kGuidanceEs: 'El potasio orientativo participa en firmeza y manejo del agua.',
        careNoteEs:
            'El tallo gana altura y se vuelve más sensible al desbalance. Cuida '
            'agua, firmeza del suelo y exceso de nitrógeno; revisa soporte en '
            'plantas altas.',
      ),
      SunflowerStageIds.budFormation: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 26, optimalMin: 44, optimalMax: 76, highMin: 88),
        soilTemp: AgroRange(lowMax: 12, optimalMin: 18, optimalMax: 28, highMin: 34),
        ec: AgroRange(lowMax: 0.3, optimalMin: 0.6, optimalMax: 1.9, highMin: 2.6),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.3, highMin: 1.9),
        nPpm: AgroRange(lowMax: 22, optimalMin: 35, optimalMax: 70, highMin: 95),
        pPpm: AgroRange(lowMax: 14, optimalMin: 22, optimalMax: 50, highMin: 80),
        kPpm: AgroRange(lowMax: 90, optimalMin: 130, optimalMax: 200, highMin: 270),
        nPriority: 0.65,
        pPriority: 0.50,
        kPriority: 0.90,
        wMoisture: 0.30,
        wSoilTemp: 0.12,
        wPh: 0.06,
        wEc: 0.10,
        wResistance: 0.10,
        wN: 0.10,
        wP: 0.08,
        wK: 0.14,
        nWindowEs: 'Transición reproductiva',
        pWindowEs: 'Soporte moderado',
        kWindowEs: 'Ventana alta de K',
        nGuidanceEs: 'Mantén el nitrógeno contenido; el botón ya está en camino.',
        pGuidanceEs: 'Revisa el pH y la humedad antes de interpretar el fósforo.',
        kGuidanceEs:
            'El potasio orientativo cuida la firmeza del tallo y del botón; el agua manda.',
        careNoteEs:
            'El botón se está formando; una sequía fuerte aquí reduce la calidad '
            'floral. Evita cambios bruscos de humedad.',
      ),
      SunflowerStageIds.flowering: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 28, optimalMin: 46, optimalMax: 78, highMin: 90),
        soilTemp: AgroRange(lowMax: 13, optimalMin: 18, optimalMax: 27, highMin: 33),
        ec: AgroRange(lowMax: 0.25, optimalMin: 0.5, optimalMax: 1.7, highMin: 2.4),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 18, optimalMin: 30, optimalMax: 60, highMin: 85),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 75),
        kPpm: AgroRange(lowMax: 80, optimalMin: 120, optimalMax: 190, highMin: 255),
        nPriority: 0.45,
        pPriority: 0.40,
        kPriority: 0.85,
        wMoisture: 0.33,
        wSoilTemp: 0.13,
        wPh: 0.06,
        wEc: 0.10,
        wResistance: 0.09,
        wN: 0.07,
        wP: 0.07,
        wK: 0.15,
        nWindowEs: 'Evitar exceso vegetativo',
        pWindowEs: 'Demanda baja-moderada',
        kWindowEs: 'Agua y calidad floral',
        nGuidanceEs: 'En flor el nitrógeno baja; no busques más follaje.',
        pGuidanceEs: 'La demanda de fósforo ya bajó; evita corregir por rutina.',
        kGuidanceEs: 'Mantén equilibrio; el agua sigue siendo la prioridad.',
        careNoteEs:
            'La flor abierta es la ventana ornamental más delicada. Mantén '
            'humedad estable, evita calor con suelo seco y no fertilices por una '
            'sola lectura.',
      ),
      SunflowerStageIds.postBloom: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 18, optimalMin: 34, optimalMax: 64, highMin: 82),
        soilTemp: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 28, highMin: 35),
        ec: AgroRange(lowMax: 0.2, optimalMin: 0.4, optimalMax: 1.5, highMin: 2.2),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 12, optimalMin: 22, optimalMax: 50, highMin: 75),
        pPpm: AgroRange(lowMax: 10, optimalMin: 16, optimalMax: 40, highMin: 65),
        kPpm: AgroRange(lowMax: 60, optimalMin: 100, optimalMax: 170, highMin: 235),
        nPriority: 0.30,
        pPriority: 0.30,
        kPriority: 0.55,
        wMoisture: 0.30,
        wSoilTemp: 0.13,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.10,
        wN: 0.07,
        wP: 0.07,
        wK: 0.14,
        nWindowEs: 'Demanda descendente',
        pWindowEs: 'Demanda descendente',
        kWindowEs: 'Soporte residual',
        nGuidanceEs: 'La demanda de nitrógeno desciende con la flor.',
        pGuidanceEs: 'La demanda de fósforo ya bajó; evita corregir por rutina.',
        kGuidanceEs: 'El potasio sostiene la estructura mientras baja la demanda.',
        careNoteEs:
            'La flor envejece y la demanda de agua empieza a bajar. No confundas '
            'el envejecimiento normal con enfermedad.',
      ),
      SunflowerStageIds.senescence: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 10, optimalMin: 22, optimalMax: 50, highMin: 72),
        soilTemp: AgroRange(lowMax: 4, optimalMin: 10, optimalMax: 26, highMin: 34),
        ec: AgroRange(lowMax: 0.15, optimalMin: 0.3, optimalMax: 1.2, highMin: 1.9),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.5, highMin: 2.0),
        nPpm: AgroRange(lowMax: 5, optimalMin: 12, optimalMax: 35, highMin: 55),
        pPpm: AgroRange(lowMax: 5, optimalMin: 10, optimalMax: 30, highMin: 50),
        kPpm: AgroRange(lowMax: 40, optimalMin: 70, optimalMax: 140, highMin: 200),
        nPriority: 0.10,
        pPriority: 0.10,
        kPriority: 0.20,
        wMoisture: 0.22,
        wSoilTemp: 0.15,
        wPh: 0.08,
        wEc: 0.13,
        wResistance: 0.11,
        wN: 0.07,
        wP: 0.08,
        wK: 0.16,
        nWindowEs: 'Sin corrección activa',
        pWindowEs: 'Sin corrección activa',
        kWindowEs: 'Sin corrección activa',
        nGuidanceEs: 'No intentes detener el cierre natural con nitrógeno.',
        pGuidanceEs: 'La planta ya no responde al fósforo; no corrijas por rutina.',
        kGuidanceEs: 'No agregues potasio para revertir el cierre del ciclo.',
        careNoteEs:
            'La planta anual está cerrando su ciclo. No intentes reverdecerla con '
            'fertilizante; confirma que el amarillamiento sea gradual y general.',
      ),
      // Fila técnica: el motor terminal la ignora (Documento B §4, §0.2 regla
      // 11): sin alertas, prioridad NPK cero, sin consejos activos.
      SunflowerStageIds.cycleComplete: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 20, optimalMin: 38, optimalMax: 70, highMin: 84),
        soilTemp: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 30, highMin: 36),
        ec: AgroRange(lowMax: 0.2, optimalMin: 0.4, optimalMax: 1.6, highMin: 2.3),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 15, optimalMin: 25, optimalMax: 60, highMin: 90),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 70),
        kPpm: AgroRange(lowMax: 65, optimalMin: 100, optimalMax: 175, highMin: 240),
        nPriority: 0.0,
        pPriority: 0.0,
        kPriority: 0.0,
        wMoisture: 0.20,
        wSoilTemp: 0.16,
        wPh: 0.10,
        wEc: 0.15,
        wResistance: 0.13,
        wN: 0.08,
        wP: 0.08,
        wK: 0.10,
        nWindowEs: 'Cerrado',
        pWindowEs: 'Cerrado',
        kWindowEs: 'Cerrado',
        nGuidanceEs: 'El ciclo terminó; no hay manejo nutrimental activo.',
        pGuidanceEs: 'El ciclo terminó; no hay manejo nutrimental activo.',
        kGuidanceEs: 'El ciclo terminó; no hay manejo nutrimental activo.',
        careNoteEs:
            'El ciclo terminó. Conserva el registro en historial o inicia una '
            'nueva siembra; no sigas corrigiendo NPK.',
      ),
      // Banda conservadora por confirmar (Documento B §4, §17). Debe
      // auto-repararse cuando exista fecha y perfil.
      SunflowerStageIds.unknown: _SunflowerStageProfile(
        moisture: AgroRange(lowMax: 20, optimalMin: 38, optimalMax: 70, highMin: 84),
        soilTemp: AgroRange(lowMax: 8, optimalMin: 16, optimalMax: 30, highMin: 36),
        ec: AgroRange(lowMax: 0.2, optimalMin: 0.4, optimalMax: 1.6, highMin: 2.3),
        resistance: AgroRange(lowMax: -1.0, optimalMin: 0.0, optimalMax: 1.4, highMin: 2.0),
        nPpm: AgroRange(lowMax: 15, optimalMin: 25, optimalMax: 60, highMin: 90),
        pPpm: AgroRange(lowMax: 12, optimalMin: 20, optimalMax: 45, highMin: 70),
        kPpm: AgroRange(lowMax: 65, optimalMin: 100, optimalMax: 175, highMin: 240),
        nPriority: 0.45,
        pPriority: 0.45,
        kPriority: 0.55,
        wMoisture: 0.29,
        wSoilTemp: 0.14,
        wPh: 0.07,
        wEc: 0.12,
        wResistance: 0.13,
        wN: 0.08,
        wP: 0.07,
        wK: 0.10,
        nWindowEs: 'Revisión prudente',
        pWindowEs: 'Revisión prudente',
        kWindowEs: 'Revisión prudente',
        nGuidanceEs:
            'Confirma la fecha o el estado del Girasol para interpretar el nitrógeno.',
        pGuidanceEs: 'Confirma la etapa antes de interpretar el fósforo.',
        kGuidanceEs: 'Confirma la etapa antes de interpretar el potasio.',
        careNoteEs:
            'La etapa todavía no está confirmada. Usa recomendaciones '
            'conservadoras hasta resolver la fecha o el estado de la planta.',
      ),
    };

_SunflowerStageProfile _profileForStage(String? stageId) {
  final id = normalizeSunflowerStageId(stageId);
  return _sunflowerStageProfiles[id] ??
      _sunflowerStageProfiles[SunflowerStageIds.unknown]!;
}

// ── Contexto de cultivo por perfil (Documento B §7, §15) ─────────────────────
enum _SunflowerContext { tallGarden, compactContainer, branching, cutFlower, general }

_SunflowerContext _contextForProfile(String? profileId) {
  switch (profileId?.trim().toLowerCase()) {
    case kGi01TallGarden:
      return _SunflowerContext.tallGarden;
    case kGi02CompactContainer:
      return _SunflowerContext.compactContainer;
    case kGi03BranchingOrnamental:
      return _SunflowerContext.branching;
    case kGi04CutFlowerSingleStem:
      return _SunflowerContext.cutFlower;
    case kGiSkip:
    default:
      return _SunflowerContext.general;
  }
}

AgroRange _phForContext(_SunflowerContext ctx) {
  switch (ctx) {
    case _SunflowerContext.tallGarden:
      return SunflowerUniversalProfile.phTallGarden;
    case _SunflowerContext.compactContainer:
      return SunflowerUniversalProfile.phCompactContainer;
    case _SunflowerContext.branching:
      return SunflowerUniversalProfile.phBranchingOrnamental;
    case _SunflowerContext.cutFlower:
      return SunflowerUniversalProfile.phCutFlower;
    case _SunflowerContext.general:
      return SunflowerUniversalProfile.phGeneral;
  }
}

// Etapas "vivas" (siembra → senescencia): reciben los ajustes de contenedor.
// `cycle_complete` y `unknown` quedan fuera.
const Set<String> _liveStageIds = <String>{
  SunflowerStageIds.sowing,
  SunflowerStageIds.germination,
  SunflowerStageIds.emergence,
  SunflowerStageIds.earlyVegetativeGrowth,
  SunflowerStageIds.activeVegetativeGrowth,
  SunflowerStageIds.stemElongation,
  SunflowerStageIds.budFormation,
  SunflowerStageIds.flowering,
  SunflowerStageIds.postBloom,
  SunflowerStageIds.senescence,
};
const Set<String> _budFloweringIds = <String>{
  SunflowerStageIds.budFormation,
  SunflowerStageIds.flowering,
};
const Set<String> _activeToBudIds = <String>{
  SunflowerStageIds.activeVegetativeGrowth,
  SunflowerStageIds.stemElongation,
  SunflowerStageIds.budFormation,
};
const Set<String> _activeToFloweringIds = <String>{
  SunflowerStageIds.activeVegetativeGrowth,
  SunflowerStageIds.stemElongation,
  SunflowerStageIds.budFormation,
  SunflowerStageIds.flowering,
};
const Set<String> _stemToFloweringIds = <String>{
  SunflowerStageIds.stemElongation,
  SunflowerStageIds.budFormation,
  SunflowerStageIds.flowering,
};

/// Targets base de sensor por etapa, en unidades reales (sin modificadores de
/// perfil). Usa pH general por defecto.
StageTargets resolveSunflowerTargets(String? stageId) {
  final p = _profileForStage(stageId);
  return _buildTargets(p, SunflowerUniversalProfile.phGeneral);
}

/// Targets ajustados por el contexto de cultivo que implica el perfil
/// (Documento B §7 pH + §15 modificadores). No se duplica una tabla completa
/// por perfil: se parte de la base y se aplican deltas. El orden final
/// `lowMax <= optimalMin <= optimalMax <= highMin` se conserva (Documento B
/// §15.6).
StageTargets resolveSunflowerTargetsForProfile(
  String? stageId, {
  required String? profileId,
}) {
  final id = normalizeSunflowerStageId(stageId);
  final p = _profileForStage(id);
  final ctx = _contextForProfile(profileId);

  AgroRange moisture = p.moisture;
  AgroRange soilTemp = p.soilTemp;
  AgroRange ec = p.ec;
  AgroRange resistance = p.resistance;
  AgroRange nPpm = p.nPpm;
  AgroRange pPpm = p.pPpm;
  AgroRange kPpm = p.kPpm;

  final bool live = _liveStageIds.contains(id);

  switch (ctx) {
    case _SunflowerContext.tallGarden:
    case _SunflowerContext.general:
      // Solo pH y castigos/mensajes; sin modificar físicas del sustrato.
      break;
    case _SunflowerContext.compactContainer:
      // Maceta compacta (Documento B §15.2): se seca y se satura rápido, se
      // calienta, acumula sales y confina la raíz.
      if (live) {
        moisture = _shift(moisture, lowMax: 2, optMin: 3, optMax: 2, highMin: -2);
        soilTemp = _shift(soilTemp, optMax: -2, highMin: -2);
        ec = _shift(ec, optMax: -0.10, highMin: -0.20);
        resistance = _capResistanceHighMin(
          _shift(resistance, optMax: -0.20, highMin: -0.20),
          1.4,
        );
        nPpm = _reduceHighMin(nPpm, 10);
        pPpm = _reduceHighMin(pPpm, 5);
        kPpm = _reduceHighMin(kPpm, 15);
      }
      break;
    case _SunflowerContext.branching:
      // Ramificado (Documento B §15.3): protege una floración escalonada con
      // más superficie foliar.
      if (_budFloweringIds.contains(id)) {
        moisture = _shift(moisture, lowMax: 2, optMin: 2, optMax: 1);
      }
      if (_activeToBudIds.contains(id)) {
        nPpm = _shift(nPpm, optMin: 5);
      }
      if (_activeToFloweringIds.contains(id)) {
        kPpm = _shift(kPpm, optMin: 10);
      }
      break;
    case _SunflowerContext.cutFlower:
      // Corte unifloral (Documento B §15.4): estabilidad de tallo y
      // uniformidad, sin banda más húmeda de forma indiscriminada.
      if (_stemToFloweringIds.contains(id)) {
        moisture = _shift(moisture, optMin: 2, optMax: -2);
        nPpm = _reduceHighMin(nPpm, 10);
        kPpm = _shift(kPpm, optMin: 5);
      }
      break;
  }

  return _buildTargets(
    p,
    _phForContext(ctx),
    moisture: moisture,
    soilTemp: soilTemp,
    ec: ec,
    resistance: resistance,
    nPpm: nPpm,
    pPpm: pPpm,
    kPpm: kPpm,
  );
}

/// Pesos del AgroScore por etapa (Documento B §13). Cada fila suma 1.00. El
/// Girasol no aplica modificadores de peso por perfil: los ajustes de perfil son
/// de target y de castigo, no de peso.
StageWeights resolveSunflowerStageWeights(String? stageId, {String? profileId}) {
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

/// Nota corta de cuidado por etapa (Documento B §17).
String sunflowerStageCareNoteEs(String? stageId) =>
    _profileForStage(stageId).careNoteEs;

// ── Helpers de construcción/ajuste ───────────────────────────────────────────

StageTargets _buildTargets(
  _SunflowerStageProfile p,
  AgroRange ph, {
  AgroRange? moisture,
  AgroRange? soilTemp,
  AgroRange? ec,
  AgroRange? resistance,
  AgroRange? nPpm,
  AgroRange? pPpm,
  AgroRange? kPpm,
}) {
  return StageTargets(
    moistureRaw: moisture ?? p.moisture,
    soilTemp: soilTemp ?? p.soilTemp,
    ph: ph,
    ec: ec ?? p.ec,
    resistance: resistance ?? p.resistance,
    // Índices legacy neutralizados: el motor usa los rangos explícitos en mg/kg.
    nIndex: SunflowerUniversalProfile.neutralLegacyNpk,
    pIndex: SunflowerUniversalProfile.neutralLegacyNpk,
    kIndex: SunflowerUniversalProfile.neutralLegacyNpk,
    nSoilPpmRange: nPpm ?? p.nPpm,
    pSoilPpmRange: pPpm ?? p.pPpm,
    kSoilPpmRange: kPpm ?? p.kPpm,
    nPriority: p.nPriority,
    pPriority: p.pPriority,
    kPriority: p.kPriority,
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

/// Reduce el `highMin` de un rango de nutriente (cap de maceta), sin bajar por
/// debajo del `optimalMax`.
AgroRange _reduceHighMin(AgroRange r, double delta) {
  final newHighMin = math.max(r.optimalMax, r.highMin - delta);
  return AgroRange(
    lowMax: r.lowMax,
    optimalMin: r.optimalMin,
    optimalMax: r.optimalMax,
    highMin: newHighMin,
  );
}

/// Piso de `highMin` de resistencia en maceta (Documento B §9.4): nunca por
/// debajo de 1.4 MPa, para no producir rangos inválidos.
AgroRange _capResistanceHighMin(AgroRange r, double floor) {
  final newHighMin = math.max(math.max(r.optimalMax, floor), r.highMin);
  return AgroRange(
    lowMax: r.lowMax,
    optimalMin: r.optimalMin,
    optimalMax: r.optimalMax,
    highMin: newHighMin,
  );
}
