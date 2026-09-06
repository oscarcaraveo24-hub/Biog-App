// lib/core/agro/nutrition/nutrition_guide.dart
//
// GUÍA NUTRICIONAL AUDITADA por cultivo (Guía oficial del nuevo motor
// nutricional v0.4, §5, §9 y §10).
//
// Es la fuente de la recomendación. No la sonda. Una guía dice, para un
// cultivo, en qué etapas se abre la ventana de cada nutriente, qué fuentes y
// reglas 3R respalda, y —solo si está auditada— qué rango de dosis sostiene.
//
// DOS CAPAS QUE SE SUMAN
// ----------------------
// 1. El PERFIL del cultivo (`StageTargets`): prioridad 0..1 por nutriente y
//    etapa, ventana en lenguaje del agricultor y guía corta. Existe para los 33
//    cultivos y es la base del motor desde el primer día.
// 2. La GUÍA CURADA (`NutritionGuide`, este archivo): fuentes citables, plan de
//    temporada en kg/ha, reglas por etapa, restricciones y estatus de
//    auditoría. Existe para los cultivos que ya pasaron —o están pasando— la
//    auditoría de guías (Guía v0.4, §34).
//
// REGLA DE VISIBILIDAD
// --------------------
// Un rango de dosis con `GuideAuditStatus.proposed` vive en el código con su
// fuente para que pueda revisarse, pero el agricultor NO lo ve. Solo una guía
// `audited` emite cifras. La app explica el hueco en vez de rellenarlo con la
// lectura de la sonda (§10).
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';

/// Fuente citable de una guía.
class GuideSource {
  const GuideSource({required this.labelEs, this.url, this.year});

  final String labelEs;
  final String? url;
  final int? year;

  String get citationEs => year == null ? labelEs : '$labelEs ($year)';
}

/// Plan de temporada de un nutriente: cuánto aporta el ciclo completo.
///
/// Siempre en la forma declarada (N elemental, P₂O₅, K₂O) y siempre como rango.
class SeasonNutrientPlan {
  const SeasonNutrientPlan({
    required this.form,
    required this.minKgPerHa,
    required this.maxKgPerHa,
    required this.sourceEs,
    this.audit = GuideAuditStatus.proposed,
    this.notesEs,
  });

  final NutrientForm form;
  final double minKgPerHa;
  final double maxKgPerHa;
  final String sourceEs;
  final GuideAuditStatus audit;
  final String? notesEs;

  AgroMetricKey get nutrient => form.nutrient;
}

/// Regla de una etapa (o grupo de etapas) para uno o más nutrientes.
class StageNutritionRule {
  const StageNutritionRule({
    required this.stageKeys,
    required this.windowNutrients,
    this.seasonShare = const <AgroMetricKey, double>{},
    this.isCritical = false,
    this.timingEs,
    this.rationaleEs,
    this.rulesEs = const <String>[],
    this.labelEs,
  });

  /// Claves de etapa (normalizadas en minúsculas, sin guiones bajos) a las que
  /// aplica la regla. Ver [matchesStage].
  final Set<String> stageKeys;

  /// Nutrientes cuya ventana de manejo se abre en estas etapas.
  final Set<AgroMetricKey> windowNutrients;

  /// Fracción del plan de temporada que corresponde a esta ventana, por
  /// nutriente (0..1). Con el plan auditado produce el rango de la ventana.
  final Map<AgroMetricKey, double> seasonShare;

  /// La ventana es agronómicamente importante: si TERMINA sin que el sensor
  /// haya visto una respuesta compatible con fertilización, el resultado puede
  /// pesar en el score histórico, el estado global y la proyección. Mientras
  /// está abierta no pesa nada; nadie registra nada a mano.
  final bool isCritical;

  /// Cuándo aplicar dentro de la ventana («antes de V8», «al trasplante»).
  final String? timingEs;

  /// Por qué importa aquí.
  final String? rationaleEs;

  /// Reglas 3R y restricciones específicas de esta ventana.
  final List<String> rulesEs;

  /// Nombre de la ventana para pantalla, si la guía lo prefiere al del perfil.
  final String? labelEs;

  bool matchesStage(String? stageKey) {
    final String norm = normalizeStageKey(stageKey);
    if (norm.isEmpty) return false;
    for (final String k in stageKeys) {
      if (normalizeStageKey(k) == norm) return true;
    }
    return false;
  }

  /// Normaliza `vegEarly`, `veg_early`, `VEG-EARLY` → `vegearly`.
  static String normalizeStageKey(String? raw) => (raw ?? '')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[\s_\-]+'), '');
}

/// Guía nutricional curada de un cultivo.
class NutritionGuide {
  const NutritionGuide({
    required this.cropKey,
    required this.cropLabelEs,
    required this.auditStatus,
    this.sources = const <GuideSource>[],
    this.seasonPlan = const <AgroMetricKey, SeasonNutrientPlan>{},
    this.stageRules = const <StageNutritionRule>[],
    this.sourceOptionsEs = const <AgroMetricKey, List<String>>{},
    this.generalRulesEs = const <String>[],
    this.notesEs,
    this.usesTreeRestitution = false,
  });

  final String cropKey;
  final String cropLabelEs;
  final GuideAuditStatus auditStatus;
  final List<GuideSource> sources;

  /// Plan de temporada por nutriente. Vacío cuando la guía no lo declara.
  final Map<AgroMetricKey, SeasonNutrientPlan> seasonPlan;

  /// Reglas por etapa. La primera que coincide con la etapa actual manda.
  final List<StageNutritionRule> stageRules;

  /// Fuentes comerciales respaldadas por nutriente.
  final Map<AgroMetricKey, List<String>> sourceOptionsEs;

  /// Reglas 3R y restricciones generales del cultivo.
  final List<String> generalRulesEs;

  final String? notesEs;

  /// Frutales: la dosis sale de `TreeRestitutionPlanner` (extracción ×
  /// cosecha esperada), no de un plan de temporada en kg/ha.
  final bool usesTreeRestitution;

  StageNutritionRule? ruleForStage(String? stageKey) {
    for (final StageNutritionRule r in stageRules) {
      if (r.matchesStage(stageKey)) return r;
    }
    return null;
  }

  /// Próxima regla con ventana para [nutrient] a partir de la etapa actual,
  /// según el orden declarado en [stageRules].
  StageNutritionRule? nextWindowRuleAfter(String? stageKey, AgroMetricKey nutrient) {
    int idx = -1;
    for (int i = 0; i < stageRules.length; i++) {
      if (stageRules[i].matchesStage(stageKey)) {
        idx = i;
        break;
      }
    }
    for (int i = idx + 1; i < stageRules.length; i++) {
      if (stageRules[i].windowNutrients.contains(nutrient)) return stageRules[i];
    }
    return null;
  }

  /// Rango de dosis de la ventana actual para [nutrient], o null si el plan no
  /// existe, no está auditado o la regla no reparte ese nutriente aquí.
  NutritionDoseRange? windowDoseFor({
    required AgroMetricKey nutrient,
    required String? stageKey,
  }) {
    final SeasonNutrientPlan? plan = seasonPlan[nutrient];
    if (plan == null || !plan.audit.canShowDose || !auditStatus.canShowDose) {
      return null;
    }
    final StageNutritionRule? rule = ruleForStage(stageKey);
    final double? share = rule?.seasonShare[nutrient];
    if (rule == null || share == null || share <= 0) return null;

    return NutritionDoseRange(
      min: plan.minKgPerHa * share,
      max: plan.maxKgPerHa * share,
      form: plan.form,
      unit: DoseUnit.kgPerHectare,
      sourceEs: plan.sourceEs,
      transparencyEs:
          'Rango de la guía de $cropLabelEs: ${_pct(share)} del plan de temporada '
          '(${plan.minKgPerHa.round()}–${plan.maxKgPerHa.round()} kg/ha de '
          '${plan.form.labelEs}) para esta ventana. Es orientativo: ajústalo con '
          'tu análisis de suelo y tu meta de rendimiento.',
    );
  }

  static String _pct(double share) => '${(share * 100).round()} %';
}
