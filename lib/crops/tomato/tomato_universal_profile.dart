import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';

class TomatoUniversalProfile {
  const TomatoUniversalProfile({required this.byStage, required this.weights});

  final Map<TomatoStageKey, StageTargets> byStage;
  final Map<TomatoStageKey, StageWeights> weights;
}

// ── pH diferenciado por grupo de etapa ──────────────────────────
// Tomate: rango operativo amplio 5.8–7.2 (Perfil Universal v2).
// Algo más estrecho en floración/cuajado por absorción de Ca.
const AgroRange _tomatoPhEarly = AgroRange(
  lowMax: 5.4,
  optimalMin: 5.8,
  optimalMax: 7.0,
  highMin: 7.4,
);

const AgroRange _tomatoPhVeg = AgroRange(
  lowMax: 5.5,
  optimalMin: 5.8,
  optimalMax: 7.2,
  highMin: 7.6,
);

const AgroRange _tomatoPhFlowering = AgroRange(
  lowMax: 5.6,
  optimalMin: 6.0,
  optimalMax: 7.0,
  highMin: 7.2,
);

const AgroRange _tomatoPhLate = AgroRange(
  lowMax: 5.4,
  optimalMin: 5.8,
  optimalMax: 7.2,
  highMin: 7.6,
);

// ── EC ─────────────────────────────────────────────────────────
// Tomate tolera EC alta (>2.5 dS/m productivo), pero es MUY sensible en
// plántula y germinación. En llenado, EC sostenida mejora calidad pero
// reduce rendimiento si es excesiva.
const AgroRange _tomatoEcEarly = AgroRange(
  lowMax: 0.6,
  optimalMin: 0.8,
  optimalMax: 1.5,
  highMin: 2.2,
);

const AgroRange _tomatoEcVeg = AgroRange(
  lowMax: 0.8,
  optimalMin: 1.2,
  optimalMax: 2.2,
  highMin: 3.0,
);

const AgroRange _tomatoEcProd = AgroRange(
  lowMax: 1.0,
  optimalMin: 1.5,
  optimalMax: 2.8,
  highMin: 3.8,
);

const AgroRange _tomatoEcLate = AgroRange(
  lowMax: 0.8,
  optimalMin: 1.2,
  optimalMax: 2.5,
  highMin: 3.5,
);

// ── Resistencia (MPa) ─ compactación objetivo <2.0 MPa (PDF v2)
const AgroRange _tomatoResistance = AgroRange(
  lowMax: -1.0,
  optimalMin: 0.0,
  optimalMax: 1.5,
  highMin: 2.0,
);

// ── Temperaturas de suelo base 18–28 °C (Perfil Universal v2).
const AgroRange _tomatoSoilTempEarly = AgroRange(
  lowMax: 14,
  optimalMin: 18,
  optimalMax: 26,
  highMin: 30,
);

const AgroRange _tomatoSoilTempStd = AgroRange(
  lowMax: 14,
  optimalMin: 18,
  optimalMax: 28,
  highMin: 32,
);

// Nota de modelado:
// - nPriority/pPriority/kPriority expresan presion fisiologica por etapa.
// - nSoilPpmRange/pSoilPpmRange/kSoilPpmRange son la referencia comparable
//   real del suelo para NPK screen, planner y motores compartidos.
// - nIndex/pIndex/kIndex se conservan como capa legacy de compatibilidad.
const TomatoUniversalProfile tomatoUniversalV1 = TomatoUniversalProfile(
  byStage: {
    // =========================
    // GERMINACIÓN
    // (Usualmente en vivero; se modela defensivo porque el arranque vía
    //  siembra directa cae aquí.)
    // =========================
    TomatoStageKey.germinacion: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 30,
        optimalMin: 55,
        optimalMax: 80,
        highMin: 90,
      ),
      soilTemp: _tomatoSoilTempEarly,
      ph: _tomatoPhEarly,
      ec: _tomatoEcEarly,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 20,
        optimalMin: 25,
        optimalMax: 45,
        highMin: 55,
      ),
      pIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 80,
        highMin: 90,
      ),
      kIndex: AgroRange(
        lowMax: 30,
        optimalMin: 40,
        optimalMax: 60,
        highMin: 70,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 26,
        optimalMin: 33,
        optimalMax: 59,
        highMin: 72,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 41,
        optimalMin: 50,
        optimalMax: 72,
        highMin: 81,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 60,
        optimalMin: 80,
        optimalMax: 120,
        highMin: 140,
      ),
      nPriority: 0.22,
      pPriority: 0.78,
      kPriority: 0.30,
      caPriority: 0.40,
      mgPriority: 0.30,
      sPriority: 0.25,
      nWindowLabelEs: 'Arranque prudente de N',
      pWindowLabelEs: 'Enraizamiento inicial',
      kWindowLabelEs: 'Soporte inicial de K',
      nShortGuidanceEs:
          'En germinación, N no empuja; un exceso puede afectar emergencia.',
      pShortGuidanceEs:
          'P aporta energía al sistema radicular que se está formando.',
      kShortGuidanceEs: 'K solo de base, sin empujar.',
      caShortGuidanceEs:
          'Ca de base; pared celular y estructura aún no son críticos.',
      mgShortGuidanceEs: 'Mg acompaña balance básico.',
      sShortGuidanceEs: 'S en niveles de mantenimiento.',
      nConfidence01: 0.70,
      pConfidence01: 0.84,
      kConfidence01: 0.68,
    ),

    // =========================
    // ESTABLECIMIENTO
    // =========================
    TomatoStageKey.establecimiento: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 32,
        optimalMin: 55,
        optimalMax: 80,
        highMin: 90,
      ),
      soilTemp: _tomatoSoilTempEarly,
      ph: _tomatoPhEarly,
      ec: _tomatoEcEarly,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 25,
        optimalMin: 32,
        optimalMax: 50,
        highMin: 60,
      ),
      pIndex: AgroRange(
        lowMax: 48,
        optimalMin: 58,
        optimalMax: 82,
        highMin: 92,
      ),
      kIndex: AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 33,
        optimalMin: 42,
        optimalMax: 65,
        highMin: 78,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 43,
        optimalMin: 52,
        optimalMax: 74,
        highMin: 83,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 70,
        optimalMin: 84,
        optimalMax: 124,
        highMin: 144,
      ),
      nPriority: 0.42,
      pPriority: 0.80,
      kPriority: 0.40,
      caPriority: 0.55,
      mgPriority: 0.40,
      sPriority: 0.30,
      nWindowLabelEs: 'Soporte moderado de N',
      pWindowLabelEs: 'Raíces y anclaje',
      kWindowLabelEs: 'Apoyo inicial de K',
      nShortGuidanceEs:
          'N sube a soporte, pero sin forzar: la prioridad es radical.',
      pShortGuidanceEs:
          'P es la columna aquí: fósforo starter y colocación correcta.',
      kShortGuidanceEs: 'K acompaña balance fisiológico.',
      caShortGuidanceEs:
          'Ca empieza a pedirse: pared celular y estrés de trasplante.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis del follaje inicial.',
      sShortGuidanceEs: 'S en soporte base.',
      nConfidence01: 0.76,
      pConfidence01: 0.86,
      kConfidence01: 0.72,
    ),

    // =========================
    // VEGETATIVO
    // =========================
    TomatoStageKey.vegetativo: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 32,
        optimalMin: 55,
        optimalMax: 80,
        highMin: 90,
      ),
      soilTemp: _tomatoSoilTempStd,
      ph: _tomatoPhVeg,
      ec: _tomatoEcVeg,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 35,
        optimalMin: 45,
        optimalMax: 68,
        highMin: 78,
      ),
      pIndex: AgroRange(
        lowMax: 42,
        optimalMin: 52,
        optimalMax: 75,
        highMin: 85,
      ),
      kIndex: AgroRange(
        lowMax: 45,
        optimalMin: 55,
        optimalMax: 75,
        highMin: 85,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 46,
        optimalMin: 59,
        optimalMax: 88,
        highMin: 101,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 38,
        optimalMin: 47,
        optimalMax: 68,
        highMin: 77,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 90,
        optimalMin: 110,
        optimalMax: 150,
        highMin: 170,
      ),
      nPriority: 0.72,
      pPriority: 0.52,
      kPriority: 0.55,
      caPriority: 0.60,
      mgPriority: 0.50,
      sPriority: 0.40,
      nWindowLabelEs: 'Demanda alta de N',
      pWindowLabelEs: 'Soporte de P',
      kWindowLabelEs: 'Balance hídrico y estructura',
      nShortGuidanceEs:
          'N empuja fuerte; vigilar no inducir exceso vegetativo.',
      pShortGuidanceEs: 'P pasa a soporte: seguir cubriendo sin forzar.',
      kShortGuidanceEs: 'K acompaña balance hídrico y estructura.',
      caShortGuidanceEs: 'Ca sostiene arquitectura y prepara floración.',
      mgShortGuidanceEs: 'Mg activo en fotosíntesis y color.',
      sShortGuidanceEs: 'S en soporte regular.',
      nPlannerHintEs:
          'Vigilar balance N/K y no disparar vegetativo desbalanceado.',
      pPlannerHintEs: 'Corregir P solo si la lectura realmente queda corta.',
      kPlannerHintEs: 'K sube gradualmente hacia fase reproductiva.',
      nConfidence01: 0.82,
      pConfidence01: 0.78,
      kConfidence01: 0.78,
    ),

    // =========================
    // FLORACIÓN
    // =========================
    TomatoStageKey.floracion: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 36,
        optimalMin: 58,
        optimalMax: 80,
        highMin: 88,
      ),
      soilTemp: _tomatoSoilTempStd,
      ph: _tomatoPhFlowering,
      ec: _tomatoEcProd,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 32,
        optimalMin: 40,
        optimalMax: 62,
        highMin: 72,
      ),
      pIndex: AgroRange(
        lowMax: 42,
        optimalMin: 50,
        optimalMax: 72,
        highMin: 82,
      ),
      kIndex: AgroRange(
        lowMax: 50,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 90,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 42,
        optimalMin: 52,
        optimalMax: 81,
        highMin: 94,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 38,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 74,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 100,
        optimalMin: 120,
        optimalMax: 164,
        highMin: 180,
      ),
      nPriority: 0.62,
      pPriority: 0.48,
      kPriority: 0.72,
      caPriority: 0.80,
      mgPriority: 0.58,
      sPriority: 0.42,
      nWindowLabelEs: 'N en balance reproductivo',
      pWindowLabelEs: 'Energía reproductiva',
      kWindowLabelEs: 'Soporte fuerte de K',
      nShortGuidanceEs: 'N se modera: exceso arruina floración y cuajado.',
      pShortGuidanceEs: 'P en soporte, sin empujar de rutina.',
      kShortGuidanceEs: 'K gana mucho peso: calidad de fruto y translocación.',
      caShortGuidanceEs:
          'Ca CRÍTICO: relación directa con BER. Mantener disponibilidad constante.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis intensa de floración.',
      sShortGuidanceEs: 'S soporta síntesis proteica y aromática.',
      nPlannerHintEs:
          'Bajar N si hay lectura alta; priorizar equilibrio sobre empuje.',
      pPlannerHintEs: 'Solo pagar P si la lectura lo justifica.',
      kPlannerHintEs:
          'Subir K con humedad estable para evitar estrés osmótico.',
      nConfidence01: 0.86,
      pConfidence01: 0.78,
      kConfidence01: 0.86,
    ),

    // =========================
    // CUAJADO
    // =========================
    TomatoStageKey.cuajado: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 38,
        optimalMin: 60,
        optimalMax: 82,
        highMin: 88,
      ),
      soilTemp: _tomatoSoilTempStd,
      ph: _tomatoPhFlowering,
      ec: _tomatoEcProd,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 30,
        optimalMin: 38,
        optimalMax: 58,
        highMin: 68,
      ),
      pIndex: AgroRange(
        lowMax: 40,
        optimalMin: 48,
        optimalMax: 70,
        highMin: 80,
      ),
      kIndex: AgroRange(
        lowMax: 55,
        optimalMin: 65,
        optimalMax: 85,
        highMin: 92,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 39,
        optimalMin: 49,
        optimalMax: 75,
        highMin: 88,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 36,
        optimalMin: 43,
        optimalMax: 63,
        highMin: 72,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 110,
        optimalMin: 130,
        optimalMax: 170,
        highMin: 184,
      ),
      nPriority: 0.58,
      pPriority: 0.44,
      kPriority: 0.82,
      caPriority: 0.90,
      mgPriority: 0.60,
      sPriority: 0.42,
      nWindowLabelEs: 'N moderado para no desequilibrar',
      pWindowLabelEs: 'Soporte fisiológico',
      kWindowLabelEs: 'Demanda fuerte de K',
      nShortGuidanceEs:
          'N bajo control: desequilibrio aquí se paga en aborto floral.',
      pShortGuidanceEs: 'P solo si la lectura queda muy corta.',
      kShortGuidanceEs: 'K pico: cuajado y translocación fuerte.',
      caShortGuidanceEs:
          'Ca ALTÍSIMO: cada fallo en Ca + humedad = BER garantizado.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis intensa.',
      sShortGuidanceEs: 'S soporta calidad de pared y aromas.',
      nPlannerHintEs: 'No meter pulsos altos de N en cuajado activo.',
      pPlannerHintEs: 'P más bien de mantenimiento, no empuje.',
      kPlannerHintEs:
          'Si K cae, corregir con prioridad — costo de no hacerlo es alto.',
      nConfidence01: 0.88,
      pConfidence01: 0.74,
      kConfidence01: 0.90,
    ),

    // =========================
    // LLENADO
    // =========================
    TomatoStageKey.llenado: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 36,
        optimalMin: 58,
        optimalMax: 80,
        highMin: 86,
      ),
      soilTemp: _tomatoSoilTempStd,
      ph: _tomatoPhVeg,
      ec: _tomatoEcProd,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 25,
        optimalMin: 32,
        optimalMax: 52,
        highMin: 62,
      ),
      pIndex: AgroRange(
        lowMax: 38,
        optimalMin: 45,
        optimalMax: 65,
        highMin: 75,
      ),
      kIndex: AgroRange(
        lowMax: 58,
        optimalMin: 68,
        optimalMax: 88,
        highMin: 95,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 33,
        optimalMin: 42,
        optimalMax: 68,
        highMin: 81,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 34,
        optimalMin: 41,
        optimalMax: 59,
        highMin: 68,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 116,
        optimalMin: 136,
        optimalMax: 176,
        highMin: 190,
      ),
      nPriority: 0.48,
      pPriority: 0.38,
      kPriority: 0.88,
      caPriority: 0.80,
      mgPriority: 0.62,
      sPriority: 0.40,
      nWindowLabelEs: 'N en descenso',
      pWindowLabelEs: 'Soporte final de P',
      kWindowLabelEs: 'K dominante',
      nShortGuidanceEs:
          'N baja progresivamente: favorece llenado sin exceso vegetativo.',
      pShortGuidanceEs: 'P en soporte; raro que sea cuello aquí.',
      kShortGuidanceEs: 'K dominante: dulzor, firmeza y color de fruto.',
      caShortGuidanceEs: 'Ca sigue clave para evitar blossom-end rot tardío.',
      mgShortGuidanceEs: 'Mg clave en color y fotosíntesis sostenida.',
      sShortGuidanceEs: 'S soporta calidad y aroma.',
      nPlannerHintEs: 'Si N viene alto, moderar — más no es mejor en llenado.',
      pPlannerHintEs: 'P solo como soporte, raramente correctivo.',
      kPlannerHintEs: 'Si K viene bajo, priorizar corrección ya.',
      nConfidence01: 0.84,
      pConfidence01: 0.72,
      kConfidence01: 0.90,
    ),

    // =========================
    // COSECHA PROGRESIVA
    // =========================
    TomatoStageKey.cosechaProgresiva: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 34,
        optimalMin: 55,
        optimalMax: 76,
        highMin: 84,
      ),
      soilTemp: _tomatoSoilTempStd,
      ph: _tomatoPhVeg,
      ec: _tomatoEcProd,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 22,
        optimalMin: 30,
        optimalMax: 50,
        highMin: 60,
      ),
      pIndex: AgroRange(
        lowMax: 35,
        optimalMin: 42,
        optimalMax: 62,
        highMin: 72,
      ),
      kIndex: AgroRange(
        lowMax: 58,
        optimalMin: 68,
        optimalMax: 88,
        highMin: 95,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 29,
        optimalMin: 39,
        optimalMax: 65,
        highMin: 78,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 32,
        optimalMin: 38,
        optimalMax: 56,
        highMin: 65,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 116,
        optimalMin: 136,
        optimalMax: 176,
        highMin: 190,
      ),
      nPriority: 0.46,
      pPriority: 0.36,
      kPriority: 0.85,
      caPriority: 0.75,
      mgPriority: 0.58,
      sPriority: 0.38,
      nWindowLabelEs: 'N de mantenimiento',
      pWindowLabelEs: 'P de mantenimiento',
      kWindowLabelEs: 'K sostenido (calidad)',
      nShortGuidanceEs: 'N sostiene floración superior sin inducir exceso.',
      pShortGuidanceEs: 'P solo si lectura muy corta.',
      kShortGuidanceEs: 'K sostenido: calidad de fruta en cosecha continua.',
      caShortGuidanceEs: 'Ca clave para evitar rajado y BER de frutos tardíos.',
      mgShortGuidanceEs: 'Mg sostiene fotosíntesis de planta indeterminada.',
      sShortGuidanceEs: 'S soporta aroma y calidad postcosecha.',
      nPlannerHintEs: 'Equilibrar N a demanda de racimos superiores.',
      pPlannerHintEs: 'P de soporte; no correctivo.',
      kPlannerHintEs: 'Sostener K sin pulsos bruscos para evitar rajado.',
      nConfidence01: 0.80,
      pConfidence01: 0.68,
      kConfidence01: 0.86,
    ),

    // =========================
    // FIN DE CICLO
    // =========================
    TomatoStageKey.finCiclo: StageTargets(
      moistureRaw: AgroRange(
        lowMax: 20,
        optimalMin: 38,
        optimalMax: 60,
        highMin: 75,
      ),
      soilTemp: _tomatoSoilTempStd,
      ph: _tomatoPhLate,
      ec: _tomatoEcLate,
      resistance: _tomatoResistance,
      nIndex: AgroRange(
        lowMax: 15,
        optimalMin: 20,
        optimalMax: 40,
        highMin: 50,
      ),
      pIndex: AgroRange(
        lowMax: 25,
        optimalMin: 32,
        optimalMax: 55,
        highMin: 65,
      ),
      kIndex: AgroRange(
        lowMax: 40,
        optimalMin: 48,
        optimalMax: 70,
        highMin: 80,
      ),
      nSoilPpmRange: AgroRange(
        lowMax: 20,
        optimalMin: 26,
        optimalMax: 52,
        highMin: 65,
      ),
      pSoilPpmRange: AgroRange(
        lowMax: 23,
        optimalMin: 29,
        optimalMax: 50,
        highMin: 59,
      ),
      kSoilPpmRange: AgroRange(
        lowMax: 80,
        optimalMin: 96,
        optimalMax: 140,
        highMin: 160,
      ),
      nPriority: 0.22,
      pPriority: 0.20,
      kPriority: 0.35,
      caPriority: 0.30,
      mgPriority: 0.28,
      sPriority: 0.22,
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
  weights: {
    TomatoStageKey.germinacion: StageWeights(
      moisture: 0.32,
      soilTemp: 0.08,
      resistance: 0.14,
      ph: 0.12,
      ec: 0.14,
      npk: 0.20,
    ),
    TomatoStageKey.establecimiento: StageWeights(
      moisture: 0.30,
      soilTemp: 0.08,
      resistance: 0.14,
      ph: 0.12,
      ec: 0.12,
      npk: 0.24,
    ),
    TomatoStageKey.vegetativo: StageWeights(
      moisture: 0.26,
      soilTemp: 0.06,
      resistance: 0.10,
      ph: 0.10,
      ec: 0.12,
      npk: 0.36,
    ),
    TomatoStageKey.floracion: StageWeights(
      moisture: 0.30,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.10,
      ec: 0.12,
      npk: 0.34,
    ),
    TomatoStageKey.cuajado: StageWeights(
      moisture: 0.32,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.14,
      npk: 0.34,
    ),
    TomatoStageKey.llenado: StageWeights(
      moisture: 0.30,
      soilTemp: 0.06,
      resistance: 0.06,
      ph: 0.08,
      ec: 0.14,
      npk: 0.36,
    ),
    TomatoStageKey.cosechaProgresiva: StageWeights(
      moisture: 0.28,
      soilTemp: 0.06,
      resistance: 0.08,
      ph: 0.08,
      ec: 0.14,
      npk: 0.36,
    ),
    TomatoStageKey.finCiclo: StageWeights(
      moisture: 0.22,
      soilTemp: 0.06,
      resistance: 0.14,
      ph: 0.14,
      ec: 0.14,
      npk: 0.30,
    ),
  },
);
