// lib/core/agro/nutrition/nutrition_guide.dart
//
// GUÍA NUTRICIONAL AUDITADA por cultivo (Guía oficial del nuevo motor
// nutricional v0.4, §5, §9 y §10).
//
// Es la fuente de la recomendación. No la sonda. Una guía dice, para un
// cultivo, en qué etapas se abre la ventana de cada nutriente, qué fuentes y
// reglas 3R respalda, y qué rango de dosis (kg/ha por ventana, con su
// equivalente comercial) sostiene.
//
// AUTORIDAD SOBRE EL PERFIL (decisión de producto, 6 sep 2026): cuando un
// cultivo tiene guía curada, SOLO sus reglas abren ventanas. El perfil
// fenológico (`StageTargets`) sigue aportando el matiz de prioridad para las
// pantallas, pero ya no abre por su cuenta una ventana que la guía no
// contempla (p. ej. K en llenado de grano de cebada, o N en espigamiento de
// trigo, que el perfil heredado marcaba alto).
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
// Un rango de dosis vive en el código con su fuente y su estatus. Desde el
// 6 sep 2026 (decisión de producto) los rangos `proposed` SÍ se muestran,
// siempre como «orientativos» y con la fuente y el estatus a la vista; solo
// una guía `pending` calla. Lo que no cambia: la cifra nace de cultivo + etapa
// + guía + 3R y jamás de la lectura de la sonda (§10).
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/fertilizer_products.dart';
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

  /// Fracción del plan de temporada (en frutales, del plan ANUAL de la huerta)
  /// que corresponde a esta ventana, por nutriente (0..1). Con el plan produce
  /// el rango en kg/ha de la ventana.
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

  /// Copia con cambios. Lo usa el resolver del plan para producir reglas
  /// EFECTIVAS (share plegado, criticidad ajustada, notas añadidas) sin tocar
  /// la guía curada.
  StageNutritionRule copyWith({
    Set<String>? stageKeys,
    Set<AgroMetricKey>? windowNutrients,
    Map<AgroMetricKey, double>? seasonShare,
    bool? isCritical,
    String? timingEs,
    String? rationaleEs,
    List<String>? rulesEs,
    String? labelEs,
  }) {
    return StageNutritionRule(
      stageKeys: stageKeys ?? this.stageKeys,
      windowNutrients: windowNutrients ?? this.windowNutrients,
      seasonShare: seasonShare ?? this.seasonShare,
      isCritical: isCritical ?? this.isCritical,
      timingEs: timingEs ?? this.timingEs,
      rationaleEs: rationaleEs ?? this.rationaleEs,
      rulesEs: rulesEs ?? this.rulesEs,
      labelEs: labelEs ?? this.labelEs,
    );
  }

  /// Clave normalizada representativa de la regla (la primera declarada), para
  /// identificarla en el plan efectivo y en la línea de tiempo.
  String get primaryStageKey =>
      stageKeys.isEmpty ? '' : normalizeStageKey(stageKeys.first);

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

/// Qué tan defendible es concentrar el nitrógeno de la temporada en una sola
/// aplicación, según la literatura revisada (13 sep 2026; ver la nota de cada
/// guía). Es la clasificación BASE: la textura del suelo la modula en el
/// resolver del plan (arena escala hacia fraccionar; arcilla relaja).
enum NitrogenSplitRequirement {
  /// La aplicación única iguala al fraccionamiento (o lo prescribe la
  /// extensión): cebada maltera, avena, frijol, durazno.
  toleratesSingle,

  /// Fraccionar rinde algo más, pero la única no es un error en suelo pesado
  /// y dosis moderada: maíz, nogal, manzano, mango, aguacate, hoja.
  splitRecommended,

  /// La aplicación única es un error agronómico real (curva de absorción o
  /// tope por evento): trigo de riego, tomate, chile, cebolla, cítricos.
  splitRequired,

  /// Sin clasificación (sin investigación o sin plan de nitrógeno). El motor
  /// se comporta como siempre y no ofrece concentrar.
  unclassified,
}

extension NitrogenSplitRequirementX on NitrogenSplitRequirement {
  String get labelEs => switch (this) {
    NitrogenSplitRequirement.toleratesSingle => 'Tolera una sola aplicación',
    NitrogenSplitRequirement.splitRecommended => 'Conviene fraccionar',
    NitrogenSplitRequirement.splitRequired => 'Hay que fraccionar',
    NitrogenSplitRequirement.unclassified => 'Sin clasificar',
  };

  bool get isClassified => this != NitrogenSplitRequirement.unclassified;
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
    this.splitRequirement = NitrogenSplitRequirement.unclassified,
    this.minNitrogenPasses = 1,
    this.minNitrogenPassesCoarse,
    this.minNitrogenPassesFine,
    this.recommendedNitrogenPasses,
    this.maxSinglePassKgN,
    this.capEveryPass = false,
    this.singlePassStageKey,
    this.nitrogenPassPriority = const <String>[],
    this.splitNotesEs,
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

  // ── Fraccionamiento del nitrógeno (13 sep 2026) ───────────────────────
  //
  // Estos campos alimentan al resolver del plan cuando el productor declara
  // cómo va a fertilizar. Ninguno cambia la guía por sí solo.

  /// Clasificación base de la aplicación única. Ver [NitrogenSplitRequirement].
  final NitrogenSplitRequirement splitRequirement;

  /// Mínimo de aplicaciones de N defendible en suelo medio (1 = la única es
  /// válida). Debajo de esto el resolver no pliega el plan.
  final int minNitrogenPasses;

  /// Mínimo en suelo de textura gruesa (arenoso, franco-arenoso, sustrato).
  /// Null = [minNitrogenPasses] + 1.
  final int? minNitrogenPassesCoarse;

  /// Mínimo en suelo pesado (arcilloso, franco-arcilloso), cuando la
  /// literatura lo relaja: maíz y nogal en arcilla >35–40 % admiten una sola
  /// aplicación (Clark et al. 2020; Cruz-Alvarez et al. 2020, Jiménez, Chih.).
  /// Null = [minNitrogenPasses].
  final int? minNitrogenPassesFine;

  /// Número de pasadas que la guía recomienda (★ en la tarjeta). Null = las
  /// ventanas de N que declara el plan.
  final int? recommendedNitrogenPasses;

  /// Tope de N elemental (kg/ha) que una sola pasada no debe superar según la
  /// fuente citada (cebolla: 112 kg/ha, PNW 546). Null = sin tope citable.
  final double? maxSinglePassKgN;

  /// El tope [maxSinglePassKgN] vale para CADA aplicación de la temporada
  /// (PNW 546 / CDFA en cebolla y ajo: «ninguna aplicación debe pasar de 100
  /// lb N/acre»), y por eso el resolver también lo revisa en «dos veces»
  /// (17 sep 2026). Con `false` el tope solo habla de la aplicación única
  /// (lechuga y espinaca: el tope viene de la dosis de arranque y no de las
  /// coberteras).
  final bool capEveryPass;

  /// Etapa donde debe caer la aplicación única cuando la literatura la ubica
  /// en un punto concreto distinto de la primera ventana de N (frijol: en
  /// vegetativo, no a la siembra). Null = primera ventana de N. Desde el
  /// 17 sep 2026 manda [nitrogenPassPriority]; esto queda como respaldo
  /// cuando la lista está vacía.
  final String? singlePassStageKey;

  /// PRIORIDAD AGRONÓMICA de las ventanas de nitrógeno para un plan
  /// concentrado (decisión de producto, 17 sep 2026; investigación por
  /// cultivo con fuentes primarias, ver la nota de cada guía): claves de
  /// etapa de las reglas que reparten N, de la MÁS a la MENOS importante.
  /// Con «una sola vez» todo el N cae en la primera; con «dos veces» en las
  /// dos primeras (en orden fenológico), y así. Las ventanas de N que no
  /// aparezcan van después, en su orden fenológico. Vacía = orden fenológico
  /// (o [singlePassStageKey] para la única).
  final List<String> nitrogenPassPriority;

  /// Resumen citable de la evidencia sobre fraccionamiento, para pantalla.
  final String? splitNotesEs;

  /// Copia de la guía con otras reglas por etapa. Es lo que devuelve el
  /// resolver del plan: la misma guía, con las ventanas EFECTIVAS.
  NutritionGuide copyWithStageRules(List<StageNutritionRule> rules) {
    return NutritionGuide(
      cropKey: cropKey,
      cropLabelEs: cropLabelEs,
      auditStatus: auditStatus,
      sources: sources,
      seasonPlan: seasonPlan,
      stageRules: rules,
      sourceOptionsEs: sourceOptionsEs,
      generalRulesEs: generalRulesEs,
      notesEs: notesEs,
      splitRequirement: splitRequirement,
      minNitrogenPasses: minNitrogenPasses,
      minNitrogenPassesCoarse: minNitrogenPassesCoarse,
      minNitrogenPassesFine: minNitrogenPassesFine,
      recommendedNitrogenPasses: recommendedNitrogenPasses,
      maxSinglePassKgN: maxSinglePassKgN,
      capEveryPass: capEveryPass,
      singlePassStageKey: singlePassStageKey,
      nitrogenPassPriority: nitrogenPassPriority,
      splitNotesEs: splitNotesEs,
    );
  }

  /// Reglas que reparten nitrógeno (share > 0), en el orden fenológico
  /// declarado. Son las «ventanas de N» de la temporada.
  List<StageNutritionRule> get nitrogenWindowRules => stageRules
      .where((StageNutritionRule r) => (r.seasonShare[AgroMetricKey.n] ?? 0) > 0)
      .toList(growable: false);

  /// Cuántas aplicaciones de N declara el plan de la guía.
  int get nitrogenPassCount => nitrogenWindowRules.length;

  /// Las ventanas de N ordenadas por PRIORIDAD agronómica para un plan
  /// concentrado ([nitrogenPassPriority]): primero las listadas, en ese
  /// orden; después las que la lista no menciona, en orden fenológico. Con
  /// la lista vacía manda [singlePassStageKey] (si lo hay) y luego el orden
  /// fenológico, que es lo que hacía el resolver antes del 17 sep 2026.
  List<StageNutritionRule> get nitrogenRulesByPriority {
    final List<StageNutritionRule> rules = nitrogenWindowRules;
    if (rules.isEmpty) return rules;
    final List<String> hints = <String>[
      ...nitrogenPassPriority,
      if (nitrogenPassPriority.isEmpty && singlePassStageKey != null)
        singlePassStageKey!,
    ];
    final List<StageNutritionRule> out = <StageNutritionRule>[];
    for (final String hint in hints) {
      for (final StageNutritionRule r in rules) {
        if (!out.contains(r) && r.matchesStage(hint)) {
          out.add(r);
          break;
        }
      }
    }
    for (final StageNutritionRule r in rules) {
      if (!out.contains(r)) out.add(r);
    }
    return List<StageNutritionRule>.unmodifiable(out);
  }

  /// Índice de la regla que coincide con la etapa, o −1.
  int ruleIndexFor(String? stageKey) => _ruleIndexFor(stageKey);

  StageNutritionRule? ruleForStage(String? stageKey) {
    for (final StageNutritionRule r in stageRules) {
      if (r.matchesStage(stageKey)) return r;
    }
    return null;
  }

  /// Próxima regla con ventana para [nutrient] a partir de la etapa actual,
  /// según el orden declarado en [stageRules]. Null si la etapa actual no
  /// está en la guía: sin posición no hay «siguiente».
  StageNutritionRule? nextWindowRuleAfter(String? stageKey, AgroMetricKey nutrient) {
    final int idx = _ruleIndexFor(stageKey);
    if (idx < 0) return null;
    for (int i = idx + 1; i < stageRules.length; i++) {
      if (stageRules[i].windowNutrients.contains(nutrient)) return stageRules[i];
    }
    return null;
  }

  /// Próxima regla que abre ventana de cualquier nutriente después de la
  /// etapa actual (para decir «la próxima ventana es…»). Null si la etapa
  /// actual no está en la guía.
  StageNutritionRule? nextWindowRuleAfterAny(String? stageKey) {
    final int idx = _ruleIndexFor(stageKey);
    if (idx < 0) return null;
    for (int i = idx + 1; i < stageRules.length; i++) {
      if (stageRules[i].windowNutrients.isNotEmpty) return stageRules[i];
    }
    return null;
  }

  int _ruleIndexFor(String? stageKey) {
    for (int i = 0; i < stageRules.length; i++) {
      if (stageRules[i].matchesStage(stageKey)) return i;
    }
    return -1;
  }

  /// La guía declara un plan de temporada en kg/ha (cereales, hortalizas y
  /// frutales en producción). Ornamentales y plantas de baja demanda no.
  bool get hasSeasonPlan => seasonPlan.isNotEmpty;

  /// Rango de dosis de [nutrient] en la etapa [stageKey], o null si el plan
  /// no existe, la guía calla (`pending`) o la regla no reparte ese nutriente
  /// en esa etapa. Cubre tanto los nutrientes que abren ventana como los de
  /// acompañamiento (reparto sin ventana). Sirve igual para la etapa actual
  /// y para la que se acerca.
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

    final double minKg = plan.minKgPerHa * share;
    final double maxKg = plan.maxKgPerHa * share;
    if (maxKg <= 0) return null;
    final GuideAuditStatus effective =
        plan.audit == GuideAuditStatus.audited && auditStatus == GuideAuditStatus.audited
        ? GuideAuditStatus.audited
        : GuideAuditStatus.proposed;
    final String? notes = plan.notesEs?.trim();
    return NutritionDoseRange(
      min: minKg,
      max: maxKg,
      form: plan.form,
      unit: DoseUnit.kgPerHectare,
      sourceEs: plan.sourceEs,
      commercialEquivalentEs: FertilizerProducts.equivalentEs(
        form: plan.form,
        minKg: minKg,
        maxKg: maxKg,
        sourceOptionsEs: sourceOptionsEs[nutrient] ?? const <String>[],
      ),
      // Un plan con mínimo 0 dice que el nutriente puede no hacer falta: la
      // única forma honesta de mostrarlo es como condición.
      conditionEs: plan.minKgPerHa <= 0
          ? 'solo si tu análisis de suelo sale bajo en '
                '${nutrient.labelEs.toLowerCase()}'
          : null,
      transparencyEs:
          'Rango orientativo de la guía de $cropLabelEs (${effective.doseQualifierEs}; '
          'fuente: ${plan.sourceEs}): ${_pct(share)} del plan de temporada '
          '(${plan.minKgPerHa.round()}–${plan.maxKgPerHa.round()} kg/ha de '
          '${plan.form.labelEs}) para esta ventana. Ajústalo con tu análisis de '
          'suelo y tu meta de rendimiento.'
          '${notes == null || notes.isEmpty ? '' : ' Nota de la guía: $notes'}',
    );
  }

  static String _pct(double share) => '${(share * 100).round()} %';
}
