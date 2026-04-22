import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/cucumber_models.dart';

class CucumberUniversalProfile {
  const CucumberUniversalProfile({
    required this.byStage,
    required this.weights,
  });

  final Map<CucumberStageKey, StageTargets> byStage;
  final Map<CucumberStageKey, StageWeights> weights;
}

// ── pH diferenciado por grupo de etapa ──────────────────────────
// Pepino: rango operativo 5.8–7.0 (Perfil Universal Pepino v1).
// Más estricto que tomate: cucurbitácea sensible a pH alto (clorosis).
const AgroRange _cucumberPhEarly = AgroRange(
  lowMax: 5.4,
  optimalMin: 5.8,
  optimalMax: 6.8,
  highMin: 7.2,
);

const AgroRange _cucumberPhVeg = AgroRange(
  lowMax: 5.5,
  optimalMin: 5.8,
  optimalMax: 7.0,
  highMin: 7.4,
);

const AgroRange _cucumberPhFlowering = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 6.8,
  highMin: 7.0,
);

const AgroRange _cucumberPhLate = AgroRange(
  lowMax: 5.4,
  optimalMin: 5.8,
  optimalMax: 7.0,
  highMin: 7.4,
);

// ── EC ─────────────────────────────────────────────────────────
// Pepino tolera EC media (1.5–2.5 dS/m productivo); MUY sensible en
// plántula y germinación. Por encima de 3.0 dS/m sostenido cae rendimiento
// y aparece amargor.
const AgroRange _cucumberEcEarly = AgroRange(
  lowMax: 0.5,
  optimalMin: 0.8,
  optimalMax: 1.4,
  highMin: 2.0,
);

const AgroRange _cucumberEcVeg = AgroRange(
  lowMax: 0.7,
  optimalMin: 1.0,
  optimalMax: 1.8,
  highMin: 2.5,
);

const AgroRange _cucumberEcProd = AgroRange(
  lowMax: 0.9,
  optimalMin: 1.4,
  optimalMax: 2.4,
  highMin: 3.2,
);

const AgroRange _cucumberEcLate = AgroRange(
  lowMax: 0.7,
  optimalMin: 1.0,
  optimalMax: 2.0,
  highMin: 2.8,
);

// ── Resistencia (MPa) ─ compactación objetivo <2.0 MPa.
// Cucurbitácea de raíz superficial, especialmente sensible a compactación.
const AgroRange _cucumberResistance = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.4,
  highMin: 1.8,
);

// ── Temperaturas de suelo: pepino más cálido que tomate.
// Germinación óptima 25–30 °C; veg/prod 20–28 °C.
const AgroRange _cucumberSoilTempEarly = AgroRange(
  lowMax: 16,
  optimalMin: 22,
  optimalMax: 28,
  highMin: 32,
);

const AgroRange _cucumberSoilTempStd = AgroRange(
  lowMax: 15,
  optimalMin: 20,
  optimalMax: 28,
  highMin: 32,
);

// Notas de modelado:
// - nPriority/pPriority/kPriority expresan presión fisiológica por etapa
//   según Guía Universal Pepino (relación N:K que evoluciona 1:0.7 en
//   vegetativo → 1:1 en floración → 1:2 en cuajado/llenado → 1:1.5 en
//   cosecha sostenida).
// - nSoilPpmRange/pSoilPpmRange/kSoilPpmRange son la referencia comparable
//   real del suelo (mg/kg) para NPK screen, planner y motores compartidos.
// - nIndex/pIndex/kIndex se conservan como capa legacy de compatibilidad.
const CucumberUniversalProfile cucumberUniversalV1 = CucumberUniversalProfile(
  byStage: {
    // =========================
    // GERMINACIÓN
    // =========================
    CucumberStageKey.germinacion: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 35,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 90,
      ),
      soilTemp: _cucumberSoilTempEarly,
      ph: _cucumberPhEarly,
      ec: _cucumberEcEarly,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 18,
        optimalMin: 22,
        optimalMax: 40,
        highMin: 50,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 80,
        highMin: 90,
      ),
      kIndex: AgroRange(
        lowMax: 28,
        optimalMin: 35,
        optimalMax: 55,
        highMin: 65,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 22,
        optimalMin: 28,
        optimalMax: 50,
        highMin: 60,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 40,
        optimalMin: 50,
        optimalMax: 70,
        highMin: 80,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 55,
        optimalMin: 75,
        optimalMax: 115,
        highMin: 135,
      ),
      nPriority: 0.20,
      pPriority: 0.78,
      kPriority: 0.28,
      caPriority: 0.35,
      mgPriority: 0.28,
      sPriority: 0.22,
      nWindowLabelEs: 'Arranque prudente de N',
      pWindowLabelEs: 'Enraizamiento inicial',
      kWindowLabelEs: 'Soporte mínimo de K',
      nShortGuidanceEs:
          'En germinación, N no empuja; un exceso afecta emergencia.',
      pShortGuidanceEs:
          'P aporta energía a un sistema radicular superficial en formación.',
      kShortGuidanceEs: 'K solo de base.',
      caShortGuidanceEs: 'Ca de base; estructura aún no es crítica.',
      mgShortGuidanceEs: 'Mg en mantenimiento.',
      sShortGuidanceEs: 'S en mantenimiento.',
      nConfidence01: 0.70,
      pConfidence01: 0.84,
      kConfidence01: 0.66,
    ),

    // =========================
    // ESTABLECIMIENTO
    // =========================
    CucumberStageKey.establecimiento: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 38,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 90,
      ),
      soilTemp: _cucumberSoilTempEarly,
      ph: _cucumberPhEarly,
      ec: _cucumberEcEarly,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 24,
        optimalMin: 30,
        optimalMax: 48,
        highMin: 58,
      ),
      pIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 82,
        highMin: 92,
      ),
      kIndex: AgroRange(
        lowMax: 32,
        optimalMin: 40,
        optimalMax: 58,
        highMin: 68,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 30,
        optimalMin: 38,
        optimalMax: 60,
        highMin: 72,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 42,
        optimalMin: 52,
        optimalMax: 74,
        highMin: 84,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 65,
        optimalMin: 80,
        optimalMax: 120,
        highMin: 140,
      ),
      nPriority: 0.40,
      pPriority: 0.82,
      kPriority: 0.38,
      caPriority: 0.50,
      mgPriority: 0.38,
      sPriority: 0.28,
      nWindowLabelEs: 'Soporte moderado de N',
      pWindowLabelEs: 'Raíces y anclaje',
      kWindowLabelEs: 'Apoyo inicial de K',
      nShortGuidanceEs:
          'N sube a soporte sin forzar: prioridad es desarrollo radical.',
      pShortGuidanceEs:
          'P starter es la columna aquí. Cucurbitácea responde fuerte a P de arranque.',
      kShortGuidanceEs: 'K acompaña balance fisiológico.',
      caShortGuidanceEs: 'Ca empieza a importar para pared celular.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis del primer follaje.',
      sShortGuidanceEs: 'S en soporte base.',
      nConfidence01: 0.76,
      pConfidence01: 0.86,
      kConfidence01: 0.72,
    ),

    // =========================
    // VEGETATIVO (relación N:K ≈ 1:0.7)
    // =========================
    CucumberStageKey.vegetativo: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 38,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 90,
      ),
      soilTemp: _cucumberSoilTempStd,
      ph: _cucumberPhVeg,
      ec: _cucumberEcVeg,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 38,
        optimalMin: 48,
        optimalMax: 70,
        highMin: 80,
      ),
      pIndex: AgroRange(
        lowMax: 40,
        optimalMin: 50,
        optimalMax: 72,
        highMin: 82,
      ),
      kIndex: AgroRange(
        lowMax: 42,
        optimalMin: 52,
        optimalMax: 72,
        highMin: 82,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 50,
        optimalMin: 65,
        optimalMax: 95,
        highMin: 110,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 36,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 80,
        optimalMin: 100,
        optimalMax: 140,
        highMin: 160,
      ),
      nPriority: 0.78,
      pPriority: 0.50,
      kPriority: 0.55,
      caPriority: 0.55,
      mgPriority: 0.48,
      sPriority: 0.38,
      nWindowLabelEs: 'Demanda alta de N (guía y follaje)',
      pWindowLabelEs: 'Soporte de P',
      kWindowLabelEs: 'Balance hídrico y estructura',
      nShortGuidanceEs:
          'N empuja crecimiento de guía y hojas; vigilar exceso vegetativo.',
      pShortGuidanceEs: 'P pasa a soporte: cubrir sin forzar.',
      kShortGuidanceEs: 'K acompaña balance hídrico, preparando floración.',
      caShortGuidanceEs: 'Ca sostiene pared celular y arquitectura.',
      mgShortGuidanceEs: 'Mg muy activo: hoja de pepino es exigente en Mg.',
      sShortGuidanceEs: 'S en soporte regular.',
      nPlannerHintEs:
          'Mantener N alto pero no disparar; relación N:K ≈ 1:0.7 en esta fase.',
      pPlannerHintEs: 'Corregir P solo si la lectura realmente queda corta.',
      kPlannerHintEs: 'K sube gradualmente hacia fase reproductiva.',
      nConfidence01: 0.84,
      pConfidence01: 0.78,
      kConfidence01: 0.78,
    ),

    // =========================
    // FLORACIÓN (relación N:K ≈ 1:1)
    // =========================
    CucumberStageKey.floracion: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 42,
        optimalMin: 62,
        optimalMax: 82,
        highMin: 88,
      ),
      soilTemp: _cucumberSoilTempStd,
      ph: _cucumberPhFlowering,
      ec: _cucumberEcProd,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      pIndex: AgroRange(
        lowMax: 40,
        optimalMin: 48,
        optimalMax: 70,
        highMin: 80,
      ),
      kIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 80,
        highMin: 88,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 45,
        optimalMin: 58,
        optimalMax: 88,
        highMin: 100,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 95,
        optimalMin: 115,
        optimalMax: 160,
        highMin: 180,
      ),
      nPriority: 0.65,
      pPriority: 0.46,
      kPriority: 0.72,
      caPriority: 0.65,
      mgPriority: 0.55,
      sPriority: 0.40,
      nWindowLabelEs: 'N en balance reproductivo',
      pWindowLabelEs: 'Energía reproductiva',
      kWindowLabelEs: 'Soporte fuerte de K',
      nShortGuidanceEs:
          'N se modera: exceso induce vegetatividad y aborto floral.',
      pShortGuidanceEs: 'P en soporte, sin empujar.',
      kShortGuidanceEs:
          'K gana peso: relación N:K ≈ 1:1 sostenida con humedad estable.',
      caShortGuidanceEs:
          'Ca importante para pared celular del fruto en formación.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis intensa.',
      sShortGuidanceEs: 'S soporta calidad y aroma.',
      nPlannerHintEs:
          'Bajar N si lectura alta; el desbalance se paga en aborto floral.',
      pPlannerHintEs: 'Solo pagar P si lectura lo justifica.',
      kPlannerHintEs:
          'Subir K con humedad estable; cucurbitácea sensible a osmótico.',
      nConfidence01: 0.86,
      pConfidence01: 0.78,
      kConfidence01: 0.86,
    ),

    // =========================
    // CUAJADO (relación N:K ≈ 1:2)
    // =========================
    CucumberStageKey.cuajado: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 45,
        optimalMin: 65,
        optimalMax: 84,
        highMin: 90,
      ),
      soilTemp: _cucumberSoilTempStd,
      ph: _cucumberPhFlowering,
      ec: _cucumberEcProd,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 32,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      pIndex: AgroRange(
        lowMax: 38,
        optimalMin: 45,
        optimalMax: 68,
        highMin: 78,
      ),
      kIndex: AgroRange(
        lowMax: 55,
        optimalMin: 68,
        optimalMax: 88,
        highMin: 95,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 40,
        optimalMin: 50,
        optimalMax: 78,
        highMin: 92,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 32,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 110,
        optimalMin: 135,
        optimalMax: 180,
        highMin: 200,
      ),
      nPriority: 0.55,
      pPriority: 0.42,
      kPriority: 0.85,
      caPriority: 0.72,
      mgPriority: 0.62,
      sPriority: 0.42,
      nWindowLabelEs: 'N moderado para no desequilibrar',
      pWindowLabelEs: 'Soporte fisiológico',
      kWindowLabelEs: 'Demanda fuerte de K (1:2)',
      nShortGuidanceEs:
          'N bajo control: exceso induce aborto y vegetatividad descontrolada.',
      pShortGuidanceEs: 'P solo si lectura queda muy corta.',
      kShortGuidanceEs:
          'K pico: relación N:K objetivo ≈ 1:2 para cuajado uniforme.',
      caShortGuidanceEs:
          'Ca clave para evitar deformación y BER en cucurbitáceas.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis intensa de planta cargada.',
      sShortGuidanceEs: 'S soporta calidad de pared.',
      nPlannerHintEs: 'No meter pulsos altos de N en cuajado activo.',
      pPlannerHintEs: 'P más bien de mantenimiento, no empuje.',
      kPlannerHintEs: 'Si K cae, corregir con prioridad.',
      nConfidence01: 0.88,
      pConfidence01: 0.74,
      kConfidence01: 0.90,
    ),

    // =========================
    // LLENADO (relación N:K ≈ 1:2 sostenida)
    // =========================
    CucumberStageKey.llenado: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 45,
        optimalMin: 65,
        optimalMax: 82,
        highMin: 88,
      ),
      soilTemp: _cucumberSoilTempStd,
      ph: _cucumberPhVeg,
      ec: _cucumberEcProd,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 28,
        optimalMin: 35,
        optimalMax: 55,
        highMin: 65,
      ),
      pIndex: AgroRange(
        lowMax: 36,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      kIndex: AgroRange(
        lowMax: 58,
        optimalMin: 70,
        optimalMax: 90,
        highMin: 96,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 70,
        highMin: 82,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 30,
        optimalMin: 38,
        optimalMax: 56,
        highMin: 65,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 115,
        optimalMin: 140,
        optimalMax: 185,
        highMin: 205,
      ),
      nPriority: 0.48,
      pPriority: 0.36,
      kPriority: 0.90,
      caPriority: 0.65,
      mgPriority: 0.62,
      sPriority: 0.40,
      nWindowLabelEs: 'N en descenso',
      pWindowLabelEs: 'Soporte final de P',
      kWindowLabelEs: 'K dominante (calidad)',
      nShortGuidanceEs:
          'N baja progresivamente: favorece llenado sin exceso vegetativo.',
      pShortGuidanceEs: 'P en soporte; raro que sea cuello aquí.',
      kShortGuidanceEs:
          'K dominante: turgencia, color verde uniforme y calidad de fruto.',
      caShortGuidanceEs: 'Ca clave para evitar puntas blandas y deformación.',
      mgShortGuidanceEs: 'Mg sostiene clorofila y color de hoja/fruto.',
      sShortGuidanceEs: 'S soporta aroma y calidad.',
      nPlannerHintEs: 'Si N viene alto, moderar — más no es mejor en llenado.',
      pPlannerHintEs: 'P como soporte, raramente correctivo.',
      kPlannerHintEs: 'Si K viene bajo, priorizar corrección ya.',
      nConfidence01: 0.84,
      pConfidence01: 0.72,
      kConfidence01: 0.90,
    ),

    // =========================
    // COSECHA PROGRESIVA (relación N:K ≈ 1:1.5)
    // =========================
    CucumberStageKey.cosechaProgresiva: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 42,
        optimalMin: 60,
        optimalMax: 80,
        highMin: 86,
      ),
      soilTemp: _cucumberSoilTempStd,
      ph: _cucumberPhVeg,
      ec: _cucumberEcProd,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 26,
        optimalMin: 34,
        optimalMax: 54,
        highMin: 64,
      ),
      pIndex: AgroRange(
        lowMax: 32,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      kIndex: AgroRange(
        lowMax: 55,
        optimalMin: 66,
        optimalMax: 86,
        highMin: 94,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 32,
        optimalMin: 42,
        optimalMax: 68,
        highMin: 80,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 28,
        optimalMin: 36,
        optimalMax: 54,
        highMin: 62,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 110,
        optimalMin: 135,
        optimalMax: 178,
        highMin: 195,
      ),
      nPriority: 0.50,
      pPriority: 0.34,
      kPriority: 0.85,
      caPriority: 0.60,
      mgPriority: 0.58,
      sPriority: 0.38,
      nWindowLabelEs: 'N de mantenimiento (sostener guía superior)',
      pWindowLabelEs: 'P de mantenimiento',
      kWindowLabelEs: 'K sostenido (calidad continua)',
      nShortGuidanceEs:
          'N sostiene crecimiento de nudos superiores sin disparar exceso.',
      pShortGuidanceEs: 'P solo si lectura muy corta.',
      kShortGuidanceEs:
          'K sostenido: relación N:K ≈ 1:1.5 para cosecha cada 2-3 días.',
      caShortGuidanceEs:
          'Ca clave para evitar deformación y mantener calidad postcosecha.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis de planta indeterminada.',
      sShortGuidanceEs: 'S soporta aroma y calidad postcosecha.',
      nPlannerHintEs: 'Equilibrar N a demanda de nudos productivos superiores.',
      pPlannerHintEs: 'P de soporte; no correctivo.',
      kPlannerHintEs:
          'Sostener K sin pulsos bruscos para evitar deformidad/amargor.',
      nConfidence01: 0.80,
      pConfidence01: 0.68,
      kConfidence01: 0.86,
    ),

    // =========================
    // FIN DE CICLO
    // =========================
    CucumberStageKey.finCiclo: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 22,
        optimalMin: 38,
        optimalMax: 60,
        highMin: 75,
      ),
      soilTemp: _cucumberSoilTempStd,
      ph: _cucumberPhLate,
      ec: _cucumberEcLate,
      resistance: _cucumberResistance,
      nIndex: AgroRange(
        lowMax: 14,
        optimalMin: 20,
        optimalMax: 40,
        highMin: 50,
      ),
      pIndex: AgroRange(
        lowMax: 22,
        optimalMin: 30,
        optimalMax: 52,
        highMin: 62,
      ),
      kIndex: AgroRange(
        lowMax: 38,
        optimalMin: 46,
        optimalMax: 68,
        highMin: 78,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 18,
        optimalMin: 24,
        optimalMax: 50,
        highMin: 62,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 22,
        optimalMin: 28,
        optimalMax: 48,
        highMin: 58,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 75,
        optimalMin: 92,
        optimalMax: 135,
        highMin: 155,
      ),
      nPriority: 0.20,
      pPriority: 0.18,
      kPriority: 0.32,
      caPriority: 0.25,
      mgPriority: 0.25,
      sPriority: 0.20,
      nWindowLabelEs: 'Cierre de ciclo de N',
      pWindowLabelEs: 'Cierre de ciclo de P',
      kWindowLabelEs: 'Cierre de ciclo de K',
      nShortGuidanceEs: 'Intervención mínima; leer para el próximo ciclo.',
      pShortGuidanceEs: 'P sirve de aprendizaje, no de corrección.',
      kShortGuidanceEs: 'K termina de soportar cosecha residual.',
      caShortGuidanceEs:
          'Ca en lectura para balance, no para corrección tardía.',
      mgShortGuidanceEs: 'Mg en mantenimiento.',
      sShortGuidanceEs: 'S en mantenimiento.',
      nPlannerHintEs: 'Documentar y ajustar siguiente plan; no corregir tarde.',
      pPlannerHintEs: 'Usar lectura para el próximo arranque.',
      kPlannerHintEs: 'Usar lectura para trazabilidad de plan.',
      nConfidence01: 0.66,
      pConfidence01: 0.62,
      kConfidence01: 0.68,
    ),
  },

  // ── Pesos para ring de control del suelo ──────────────────────
  // Pepino: humedad pesa más que en tomate (cucurbitácea muy hídrica),
  // EC pesa más en producción (susceptible a salinidad sostenida).
  weights: {
    CucumberStageKey.germinacion: StageWeights(
      moisture: 0.34,
      soilTemp: 0.10,
      resistance: 0.12,
      ph: 0.12,
      ec: 0.14,
      npk: 0.18,
    ),
    CucumberStageKey.establecimiento: StageWeights(
      moisture: 0.32,
      soilTemp: 0.10,
      resistance: 0.12,
      ph: 0.12,
      ec: 0.12,
      npk: 0.22,
    ),
    CucumberStageKey.vegetativo: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.10,
      ph: 0.10,
      ec: 0.12,
      npk: 0.34,
    ),
    CucumberStageKey.floracion: StageWeights(
      moisture: 0.32,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.10,
      ec: 0.12,
      npk: 0.32,
    ),
    CucumberStageKey.cuajado: StageWeights(
      moisture: 0.34,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.14,
      npk: 0.32,
    ),
    CucumberStageKey.llenado: StageWeights(
      moisture: 0.32,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.14,
      npk: 0.34,
    ),
    CucumberStageKey.cosechaProgresiva: StageWeights(
      moisture: 0.30,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.14,
      npk: 0.34,
    ),
    CucumberStageKey.finCiclo: StageWeights(
      moisture: 0.22,
      soilTemp: 0.06,
      resistance: 0.14,
      ph: 0.14,
      ec: 0.14,
      npk: 0.30,
    ),
  },
);
