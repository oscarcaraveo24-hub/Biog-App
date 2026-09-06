import 'package:bio_g/core/agro/agro_types.dart';

class StageTargets {
  const StageTargets({
    required this.moistureRaw,
    required this.soilTemp,
    required this.ph,
    required this.ec,
    required this.resistance,

    // Proxy fenologico de prioridad (ver nota en el campo):
    required this.nIndex,
    required this.pIndex,
    required this.kIndex,

    // Semantica NPK por etapa (prioridad, ventana, guia corta):
    this.nPriority,
    this.pPriority,
    this.kPriority,
    this.nWindowLabelEs,
    this.pWindowLabelEs,
    this.kWindowLabelEs,
    this.nShortGuidanceEs,
    this.pShortGuidanceEs,
    this.kShortGuidanceEs,
    this.nPlannerHintEs,
    this.pPlannerHintEs,
    this.kPlannerHintEs,
    this.nConfidence01,
    this.pConfidence01,
    this.kConfidence01,

    // Nutrientes secundarios (aditivos, opcionales).
    // Usados por cultivos que requieren sensibilidad explicita a Ca, Mg, S
    // (por ejemplo, hortalizas como tomate). No rompen calculos existentes.
    this.caPriority,
    this.mgPriority,
    this.sPriority,
    this.caShortGuidanceEs,
    this.mgShortGuidanceEs,
    this.sShortGuidanceEs,
  });

  /// ── OBSOLETO COMO FUENTE. Se sobrescribe en el runtime. ─────────────────
  ///
  /// Los cuatro números que cada perfil escribe aquí a mano **ya no llegan al
  /// motor**: `CropRuntimeResolver` sustituye esta banda por la que deriva de
  /// (textura del suelo + cultivo + etapa) antes de evaluar nada. Cambiar este
  /// campo en cualquiera de los archivos de perfil no tiene efecto sobre la
  /// humedad.
  ///
  /// Por qué se sobrescribe en vez de borrarse:
  ///
  /// · Los rangos de MACETA siguen siendo correctos, y son la referencia contra
  ///   la que se calibró el sustrato drenante. Borrarlos perdería ese ancla.
  /// · Los de suelo se conservan como historia hasta que el prototipo confirme
  ///   en campo las constantes de `SoilWaterScale`. Si hubiera que revertir, el
  ///   catálogo sigue completo.
  ///
  /// Por qué estaban mal: comparaban contenido volumétrico crudo contra números
  /// escritos a mano en una escala de sustrato de maceta. Un huerto de manzano
  /// en suelo franco perfectamente regado lee 28 % VWC y el catálogo pedía
  /// 60–80 %: la app habría dicho «riega» el 95 % del tiempo, para siempre, y
  /// la alarma de encharcamiento —con umbral en 90 %— era físicamente
  /// inalcanzable porque ningún suelo mineral del planeta llega ahí.
  ///
  /// Regla desde entonces: **nadie compara un VWC crudo contra un número
  /// escrito a mano.** Ver `lib/core/agro/water/soil_water_scale.dart`.
  final AgroRange moistureRaw;

  final AgroRange soilTemp;
  final AgroRange ph;
  final AgroRange ec;
  final AgroRange resistance;

  /// Índices fenológicos 0..100 heredados del primer motor.
  ///
  /// ── QUÉ SON HOY ─────────────────────────────────────────────────────────
  /// Un proxy de PRIORIDAD por etapa: el centro del rango, dividido entre 100,
  /// es la prioridad del nutriente cuando el perfil no declara `nPriority`
  /// explícito (ver [resolvedNPriority01]). Nada más.
  ///
  /// ── QUÉ YA NO SON ───────────────────────────────────────────────────────
  /// Hasta el NPK Interpretation Reset (Guía v0.4, §4) estos índices se
  /// traducían a mg/kg con un «techo» por cultivo (`NpkCaps`) y se comparaban
  /// contra la lectura cruda de la sonda para clasificarla y dosificar. Esa
  /// traducción **se eliminó del runtime junto con los techos y los rangos
  /// comparables de suelo (`nSoilPpmRange` y hermanos)**: la sonda 7-en-1
  /// deriva N/P/K de la conductividad y ningún número de este catálogo puede
  /// convertir esa señal en suficiencia química. Ningún motor lee estos
  /// rangos como objetivo; si alguien vuelve a hacerlo, está reabriendo el
  /// defecto que el reset cerró.
  final AgroRange nIndex;
  final AgroRange pIndex;
  final AgroRange kIndex;

  /// Nueva semantica:
  /// presion / prioridad por etapa para cada nutriente (0..1).
  ///
  /// Si vienen nulos, el engine puede derivarlos desde los indices legacy.
  final double? nPriority;
  final double? pPriority;
  final double? kPriority;

  /// Etiquetas de ventana fisiologica por nutriente.
  ///
  /// Ejemplos:
  /// - "Ventana de arranque"
  /// - "Alta demanda de N"
  /// - "Llenado y balance"
  final String? nWindowLabelEs;
  final String? pWindowLabelEs;
  final String? kWindowLabelEs;

  /// Guia corta visible en cards, resumen o NPK screen.
  final String? nShortGuidanceEs;
  final String? pShortGuidanceEs;
  final String? kShortGuidanceEs;

  /// Hint para el planner / logica posterior de fertilizacion.
  ///
  /// Ejemplos:
  /// - "Evaluar complemento si no se cubrio base"
  /// - "Favorecer aplicacion de arranque"
  /// - "Vigilar particion y balance"
  final String? nPlannerHintEs;
  final String? pPlannerHintEs;
  final String? kPlannerHintEs;

  /// Confianza del dato/modelado por nutriente.
  final double? nConfidence01;
  final double? pConfidence01;
  final double? kConfidence01;

  /// Prioridad/presion por etapa (0..1) para nutrientes secundarios.
  final double? caPriority;
  final double? mgPriority;
  final double? sPriority;

  /// Guia corta opcional para nutrientes secundarios.
  final String? caShortGuidanceEs;
  final String? mgShortGuidanceEs;
  final String? sShortGuidanceEs;

  /// Prioridad efectiva de N, con fallback legacy.
  double get resolvedNPriority01 =>
      _clamp01(nPriority ?? _legacyRangeToPriority(nIndex));

  /// Prioridad efectiva de P, con fallback legacy.
  double get resolvedPPriority01 =>
      _clamp01(pPriority ?? _legacyRangeToPriority(pIndex));

  /// Prioridad efectiva de K, con fallback legacy.
  double get resolvedKPriority01 =>
      _clamp01(kPriority ?? _legacyRangeToPriority(kIndex));

  /// Devuelve la prioridad efectiva para la metrica dada.
  double resolvedPriorityFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return resolvedNPriority01;
      case AgroMetricKey.p:
        return resolvedPPriority01;
      case AgroMetricKey.k:
        return resolvedKPriority01;
      default:
        return 0.0;
    }
  }

  /// Devuelve el label de ventana si existe.
  String? windowLabelFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return nWindowLabelEs;
      case AgroMetricKey.p:
        return pWindowLabelEs;
      case AgroMetricKey.k:
        return kWindowLabelEs;
      default:
        return null;
    }
  }

  /// Devuelve la guia corta si existe.
  String? shortGuidanceFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return nShortGuidanceEs;
      case AgroMetricKey.p:
        return pShortGuidanceEs;
      case AgroMetricKey.k:
        return kShortGuidanceEs;
      default:
        return null;
    }
  }

  /// Devuelve el planner hint si existe.
  String? plannerHintFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return nPlannerHintEs;
      case AgroMetricKey.p:
        return pPlannerHintEs;
      case AgroMetricKey.k:
        return kPlannerHintEs;
      default:
        return null;
    }
  }

  /// Devuelve la confianza si existe.
  double? confidenceFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return nConfidence01;
      case AgroMetricKey.p:
        return pConfidence01;
      case AgroMetricKey.k:
        return kConfidence01;
      default:
        return null;
    }
  }

  StageTargets copyWith({
    AgroRange? moistureRaw,
    AgroRange? soilTemp,
    AgroRange? ph,
    AgroRange? ec,
    AgroRange? resistance,
    AgroRange? nIndex,
    AgroRange? pIndex,
    AgroRange? kIndex,
    double? nPriority,
    double? pPriority,
    double? kPriority,
    String? nWindowLabelEs,
    String? pWindowLabelEs,
    String? kWindowLabelEs,
    String? nShortGuidanceEs,
    String? pShortGuidanceEs,
    String? kShortGuidanceEs,
    String? nPlannerHintEs,
    String? pPlannerHintEs,
    String? kPlannerHintEs,
    double? nConfidence01,
    double? pConfidence01,
    double? kConfidence01,
    double? caPriority,
    double? mgPriority,
    double? sPriority,
    String? caShortGuidanceEs,
    String? mgShortGuidanceEs,
    String? sShortGuidanceEs,
  }) {
    return StageTargets(
      moistureRaw: moistureRaw ?? this.moistureRaw,
      soilTemp: soilTemp ?? this.soilTemp,
      ph: ph ?? this.ph,
      ec: ec ?? this.ec,
      resistance: resistance ?? this.resistance,
      nIndex: nIndex ?? this.nIndex,
      pIndex: pIndex ?? this.pIndex,
      kIndex: kIndex ?? this.kIndex,
      nPriority: nPriority ?? this.nPriority,
      pPriority: pPriority ?? this.pPriority,
      kPriority: kPriority ?? this.kPriority,
      nWindowLabelEs: nWindowLabelEs ?? this.nWindowLabelEs,
      pWindowLabelEs: pWindowLabelEs ?? this.pWindowLabelEs,
      kWindowLabelEs: kWindowLabelEs ?? this.kWindowLabelEs,
      nShortGuidanceEs: nShortGuidanceEs ?? this.nShortGuidanceEs,
      pShortGuidanceEs: pShortGuidanceEs ?? this.pShortGuidanceEs,
      kShortGuidanceEs: kShortGuidanceEs ?? this.kShortGuidanceEs,
      nPlannerHintEs: nPlannerHintEs ?? this.nPlannerHintEs,
      pPlannerHintEs: pPlannerHintEs ?? this.pPlannerHintEs,
      kPlannerHintEs: kPlannerHintEs ?? this.kPlannerHintEs,
      nConfidence01: nConfidence01 ?? this.nConfidence01,
      pConfidence01: pConfidence01 ?? this.pConfidence01,
      kConfidence01: kConfidence01 ?? this.kConfidence01,
      caPriority: caPriority ?? this.caPriority,
      mgPriority: mgPriority ?? this.mgPriority,
      sPriority: sPriority ?? this.sPriority,
      caShortGuidanceEs: caShortGuidanceEs ?? this.caShortGuidanceEs,
      mgShortGuidanceEs: mgShortGuidanceEs ?? this.mgShortGuidanceEs,
      sShortGuidanceEs: sShortGuidanceEs ?? this.sShortGuidanceEs,
    );
  }

  /// Helper de migracion suave:
  /// convierte el "centro" del rango legacy a una senal simple 0..1
  /// de presion/prioridad por etapa.
  ///
  /// No significa suficiencia del suelo.
  static double _legacyRangeToPriority(AgroRange range) {
    final center = (range.optimalMin + range.optimalMax) / 2.0;
    return _clamp01(center / 100.0);
  }

  static double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }
}

class StageWeights {
  const StageWeights({
    required this.moisture,
    required this.soilTemp,
    required this.resistance,
    required this.ph,
    required this.ec,
    this.npk,
    this.n,
    this.p,
    this.k,
  });

  final double moisture;
  final double soilTemp;
  final double resistance;
  final double ph;
  final double ec;

  /// Peso combinado de N/P/K heredado del primer motor.
  ///
  /// **Sin efecto en el score desde el NPK Interpretation Reset.** Las señales
  /// N/P/K de la sonda son nativas (derivadas de la conductividad) y tienen
  /// peso cero en la condición del suelo por decisión (Guía v0.4, §6). El
  /// campo se conserva en el catálogo para no reescribir 40 perfiles en la
  /// misma cirugía; `SoilConditionScore` no lo lee. La auditoría de guías
  /// decidirá si se retira del catálogo o se reinterpreta como peso de
  /// prioridad nutricional dentro de `NutritionDecision`.
  final double? npk;

  /// Pesos explícitos por nutriente. Misma situación que [npk].
  final double? n;
  final double? p;
  final double? k;

  double get nutrientN => n ?? _legacySplit;
  double get nutrientP => p ?? _legacySplit;
  double get nutrientK => k ?? _legacySplit;

  double get _legacySplit => (npk ?? 0.0) / 3.0;

  double get nutrientsSum => nutrientN + nutrientP + nutrientK;

  /// Suma de los pesos de las cinco señales físicas: lo único que pondera la
  /// condición del suelo. Ver `SoilConditionScore`.
  double get soilSum => moisture + soilTemp + resistance + ph + ec;

  /// Suma de todos los pesos declarados, nutrientes incluidos. Se conserva por
  /// compatibilidad con perfiles y pruebas; el score NO la usa.
  double get sum => soilSum + nutrientsSum;

  double weightFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.soilMoisture:
        return moisture;
      case AgroMetricKey.soilTemp:
        return soilTemp;
      case AgroMetricKey.resistance:
        return resistance;
      case AgroMetricKey.ph:
        return ph;
      case AgroMetricKey.ec:
        return ec;
      case AgroMetricKey.n:
        return nutrientN;
      case AgroMetricKey.p:
        return nutrientP;
      case AgroMetricKey.k:
        return nutrientK;
    }
  }
}
