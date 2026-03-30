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

    // Nueva semántica NPK:
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
  });

  final AgroRange moistureRaw;
  final AgroRange soilTemp;
  final AgroRange ph;
  final AgroRange ec;
  final AgroRange resistance;

  /// Legacy:
  /// Estos campos existían como índices interpretativos 0..100 orientados
  /// a “estado/target” y hoy se mantienen para no romper el proyecto.
  ///
  /// Nueva lectura recomendada:
  /// usarlos temporalmente como proxy de presión / prioridad por etapa,
  /// NO como “ppm óptimos universales”.
  final AgroRange nIndex;
  final AgroRange pIndex;
  final AgroRange kIndex;

  /// Nueva semántica:
  /// presión / prioridad por etapa para cada nutriente (0..1).
  ///
  /// Si vienen nulos, el engine puede derivarlos desde los índices legacy.
  final double? nPriority;
  final double? pPriority;
  final double? kPriority;

  /// Etiquetas de ventana fisiológica por nutriente.
  ///
  /// Ejemplos:
  /// - "Ventana de arranque"
  /// - "Alta demanda de N"
  /// - "Llenado y balance"
  final String? nWindowLabelEs;
  final String? pWindowLabelEs;
  final String? kWindowLabelEs;

  /// Guía corta visible en cards, resumen o NPK screen.
  final String? nShortGuidanceEs;
  final String? pShortGuidanceEs;
  final String? kShortGuidanceEs;

  /// Hint para el planner / lógica posterior de fertilización.
  ///
  /// Ejemplos:
  /// - "Evaluar complemento si no se cubrió base"
  /// - "Favorecer aplicación de arranque"
  /// - "Vigilar partición y balance"
  final String? nPlannerHintEs;
  final String? pPlannerHintEs;
  final String? kPlannerHintEs;

  /// Confianza del dato/modelado por nutriente.
  final double? nConfidence01;
  final double? pConfidence01;
  final double? kConfidence01;

  /// Prioridad efectiva de N, con fallback legacy.
  double get resolvedNPriority01 =>
      _clamp01(nPriority ?? _legacyRangeToPriority(nIndex));

  /// Prioridad efectiva de P, con fallback legacy.
  double get resolvedPPriority01 =>
      _clamp01(pPriority ?? _legacyRangeToPriority(pIndex));

  /// Prioridad efectiva de K, con fallback legacy.
  double get resolvedKPriority01 =>
      _clamp01(kPriority ?? _legacyRangeToPriority(kIndex));

  /// Devuelve la prioridad efectiva para la métrica dada.
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

  /// Devuelve la guía corta si existe.
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

  /// Helper de migración suave:
  /// convierte el "centro" del rango legacy a una señal simple 0..1
  /// de presión/prioridad por etapa.
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
  /// Si [n], [p] y [k] vienen nulos, este valor se reparte automáticamente
  /// entre los tres nutrientes para mantener compatibilidad.
  final double? npk;

  /// Pesos explícitos por nutriente.
  ///
  /// En el nuevo motor, estos pesan la prioridad/urgencia interpretada,
  /// no un supuesto “estado óptimo”.
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
