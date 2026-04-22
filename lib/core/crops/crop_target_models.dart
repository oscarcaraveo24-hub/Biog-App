import 'package:bio_g/core/agro/agro_types.dart';

class StageTargets {
  const StageTargets({
    required this.moistureRaw,
    required this.soilTemp,
    required this.ph,
    required this.ec,
    required this.resistance,

    // Legacy / compatibilidad:
    required this.nIndex,
    required this.pIndex,
    required this.kIndex,

    // Targets comparables de suelo (mg/kg / ppm).
    this.nSoilPpmRange,
    this.pSoilPpmRange,
    this.kSoilPpmRange,

    // Nueva semantica NPK:
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

  final AgroRange moistureRaw;
  final AgroRange soilTemp;
  final AgroRange ph;
  final AgroRange ec;
  final AgroRange resistance;

  /// Legacy:
  /// Estos campos existian como indices interpretativos 0..100 orientados
  /// a "estado/target" y hoy se mantienen para no romper el proyecto.
  ///
  /// Nueva lectura recomendada:
  /// usarlos temporalmente como proxy de presion / prioridad por etapa,
  /// NO como "ppm optimos universales".
  final AgroRange nIndex;
  final AgroRange pIndex;
  final AgroRange kIndex;

  /// Rangos comparables reales del suelo para N/P/K, en mg/kg (ppm).
  ///
  /// Cuando existen, el motor debe usar estos targets para comparar lectura
  /// actual vs suficiencia de la etapa, sin traducir desde caps.
  final AgroRange? nSoilPpmRange;
  final AgroRange? pSoilPpmRange;
  final AgroRange? kSoilPpmRange;

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

  /// Devuelve el rango comparable explicito de suelo (mg/kg) si existe.
  AgroRange? soilPpmRangeFor(AgroMetricKey key) {
    switch (key) {
      case AgroMetricKey.n:
        return nSoilPpmRange;
      case AgroMetricKey.p:
        return pSoilPpmRange;
      case AgroMetricKey.k:
        return kSoilPpmRange;
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
    AgroRange? nSoilPpmRange,
    AgroRange? pSoilPpmRange,
    AgroRange? kSoilPpmRange,
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
      nSoilPpmRange: nSoilPpmRange ?? this.nSoilPpmRange,
      pSoilPpmRange: pSoilPpmRange ?? this.pSoilPpmRange,
      kSoilPpmRange: kSoilPpmRange ?? this.kSoilPpmRange,
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

  /// Peso legacy combinado para NPK.
  ///
  /// Si [n], [p] y [k] vienen nulos, este valor se reparte automaticamente
  /// entre los tres nutrientes para mantener compatibilidad.
  final double? npk;

  /// Pesos explicitos por nutriente.
  ///
  /// En el nuevo motor, estos pesan la prioridad/urgencia interpretada,
  /// no un supuesto "estado optimo".
  final double? n;
  final double? p;
  final double? k;

  double get nutrientN => n ?? _legacySplit;
  double get nutrientP => p ?? _legacySplit;
  double get nutrientK => k ?? _legacySplit;

  double get _legacySplit => (npk ?? 0.0) / 3.0;

  double get nutrientsSum => nutrientN + nutrientP + nutrientK;

  double get sum => moisture + soilTemp + resistance + ph + ec + nutrientsSum;

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
