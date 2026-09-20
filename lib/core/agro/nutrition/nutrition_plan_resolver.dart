// lib/core/agro/nutrition/nutrition_plan_resolver.dart
//
// RESOLVER DEL PLAN DE NITRÓGENO (decisión de producto, 13 sep 2026).
//
// Un solo lugar donde la guía curada se convierte en las ventanas EFECTIVAS
// de la temporada:
//
//     guía × textura del suelo × declaración del productor × libro → guía efectiva
//
// El motor de nutrición no sabe nada de esto: recibe la guía efectiva y sigue
// funcionando igual (`ruleForStage`, `windowDoseFor`, criticidad). Así el
// fraccionamiento declarado, el tope por pasada y la textura viven aquí y no
// regados por el motor.
//
// Lo que hace:
//   · Clasifica el suelo (grueso / medio / pesado) y con la clasificación de la
//     guía (`NitrogenSplitRequirement`) calcula el MÍNIMO de aplicaciones de N
//     defendible para este sitio.
//   · Ofrece las opciones «una sola vez / dos veces / tres o más / ya
//     fertilicé» con su habilitación y su razón, para la pantalla de la
//     pregunta en NPK.
//   · Si el productor declaró k pasadas, PLIEGA el reparto de N de la guía en
//     las k MEJORES ventanas según la prioridad agronómica de la guía
//     (`NutritionGuide.nitrogenPassPriority`, investigada cultivo por cultivo
//     el 17 sep 2026): «una sola vez» cae en la mejor ventana (maíz: V6–V8, no
//     la siembra), «dos veces» en las dos mejores, y así. El nitrógeno de cada
//     ventana sobrante se suma a la ventana conservada más cercana ANTES de
//     ella (la planta lo recibe antes de la demanda) o, si no hay ninguna
//     antes, a la primera que venga después. Las sobrantes dejan de abrir
//     ventana de N (sin ⚠, sin score).
//   · Con «ya fertilicé» no queda ninguna ventana de N por delante: todas se
//     pliegan; el sensor solo observa.
//   · Sin declaración, si la ventana anterior de N cerró con una respuesta
//     «mayor de lo habitual» del sitio, la siguiente se degrada a informativa
//     (no penaliza) y cambia de tono. Nunca afirma cantidad: la magnitud del
//     salto de CE no se convierte en kg (Guía v0.4, §37.5).
//
// Lo que NO hace: no registra aplicaciones, no lee la sonda, no cambia el plan
// de temporada en kg/ha ni las ventanas de P y K.
import 'dart:math' as math;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_guide_catalog.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';

/// Clase de textura para el fraccionamiento: lo que decide es cuánto nitrato
/// retiene el suelo entre la aplicación y la demanda (Clark et al. 2020:
/// arena > 4–10 % favorece fraccionar; arcilla > 34–37 % favorece la única).
enum SoilTextureClass { coarse, medium, fine, unknown }

extension SoilTextureClassX on SoilTextureClass {
  String get labelEs => switch (this) {
    SoilTextureClass.coarse => 'suelo ligero (arenoso)',
    SoilTextureClass.medium => 'suelo medio (franco)',
    SoilTextureClass.fine => 'suelo pesado (arcilloso)',
    SoilTextureClass.unknown => 'textura sin declarar',
  };

  static SoilTextureClass of(SoilTexture texture) => switch (texture) {
    SoilTexture.sandy ||
    SoilTexture.sandyLoam ||
    SoilTexture.pottingMix ||
    SoilTexture.pottingMixDraining => SoilTextureClass.coarse,
    SoilTexture.loam => SoilTextureClass.medium,
    SoilTexture.clayLoam || SoilTexture.clay => SoilTextureClass.fine,
    SoilTexture.unknown => SoilTextureClass.unknown,
  };
}

/// Una opción de la tarjeta «¿Cómo vas a fertilizar esta temporada?».
class NitrogenPassOption {
  const NitrogenPassOption({
    required this.plan,
    required this.enabled,
    required this.recommended,
    required this.helperEs,
    this.disabledReasonEs,
    this.warningEs,
  });

  final NitrogenPassPlan plan;

  /// Se puede elegir en este sitio (mínimo defendible y tope por pasada).
  final bool enabled;

  /// Lleva la ★: es lo que la guía recomienda.
  final bool recommended;

  /// Dónde caen las aplicaciones («al sembrar», «siembra y V6–V8»).
  final String helperEs;

  /// Por qué no se puede elegir (se muestra, no se esconde).
  final String? disabledReasonEs;

  /// Se puede, pero con esta salvedad.
  final String? warningEs;

  String get labelEs => plan.labelEs;
}

/// Resultado del resolver: la guía efectiva y todo lo que la pantalla necesita
/// para explicarla.
class NutritionPlanResolution {
  const NutritionPlanResolution({
    required this.baseGuide,
    required this.guide,
    required this.texture,
    required this.textureClass,
    required this.declaration,
    required this.options,
    required this.planPasses,
    required this.effectiveMinPasses,
    required this.declarationApplied,
    this.foldedStageKeys = const <String>{},
    this.keptStageKeys = const <String>[],
    this.keptWindowLabelsEs = const <String>[],
    this.planNoteEs,
    this.demotedStageKey,
    this.reasonsEs = const <String>[],
  });

  /// Sin guía no hay plan que resolver: todo pasa tal cual.
  static const NutritionPlanResolution none = NutritionPlanResolution(
    baseGuide: null,
    guide: null,
    texture: SoilTexture.unknown,
    textureClass: SoilTextureClass.unknown,
    declaration: null,
    options: <NitrogenPassOption>[],
    planPasses: 0,
    effectiveMinPasses: 1,
    declarationApplied: false,
  );

  /// La guía curada, intacta.
  final NutritionGuide? baseGuide;

  /// La guía con las ventanas efectivas. Es la que consume el motor.
  final NutritionGuide? guide;

  final SoilTexture texture;
  final SoilTextureClass textureClass;
  final NutritionSeasonDeclaration? declaration;

  /// Opciones de la tarjeta, en orden: una sola vez, dos veces, tres o más y,
  /// siempre al final, «ya fertilicé». Solo incluye las de número que aplican
  /// al plan (un plan de 2 ventanas no ofrece «tres o más»).
  final List<NitrogenPassOption> options;

  /// Ventanas de N que declara la guía curada.
  final int planPasses;

  /// Mínimo de aplicaciones de N defendible en este sitio (guía × textura).
  final int effectiveMinPasses;

  /// La declaración existía, aplicaba a esta temporada y se plegó el plan.
  final bool declarationApplied;

  /// Claves normalizadas (`primaryStageKey`) de las reglas que dejaron de
  /// abrir ventana de N por el plegado. La línea de tiempo ya no las pinta
  /// como fertilizaciones (17 sep 2026): el productor ve exactamente las
  /// pasadas que declaró.
  final Set<String> foldedStageKeys;

  /// Claves normalizadas de las ventanas de N que CONSERVA el plan efectivo,
  /// en orden fenológico (con declaración aplicada: las k mejores; sin ella,
  /// todas las de la guía). Vacía con «ya fertilicé».
  final List<String> keptStageKeys;

  /// Nombres de esas ventanas («Segunda fertilización (V6–V8)»), en el mismo
  /// orden, para la pregunta y el copy de NPK.
  final List<String> keptWindowLabelsEs;

  /// Una frase para la pestaña de nitrógeno cuando la etapa actual quedó
  /// plegada («Según tu plan (una sola vez), el nitrógeno va en «Segunda
  /// fertilización (V6–V8)».»). Null sin plegado.
  final String? planNoteEs;

  /// Regla degradada a informativa por la respuesta «mayor de lo habitual» de
  /// la ventana anterior (sin declaración).
  final String? demotedStageKey;

  /// Trazabilidad para `NutritionDecision.reasons`.
  final List<String> reasonsEs;

  bool get hasGuide => guide != null;

  /// El productor declaró «ya fertilicé» y aplica: no queda nitrógeno por
  /// delante esta temporada.
  bool get isAlreadyDone =>
      declarationApplied && (declaration?.passes.isAlreadyDone ?? false);

  /// Hay algo que decidir: al menos dos opciones de NÚMERO de pasadas
  /// habilitadas («ya fertilicé» siempre está, pero por sí sola no justifica
  /// preguntar: la pregunta existe para repartir el plan a la forma de
  /// trabajar del productor).
  bool get canDeclare =>
      options
          .where((NitrogenPassOption o) => o.enabled && !o.plan.isAlreadyDone)
          .length >=
      2;

  NitrogenPassOption? get recommendedOption {
    for (final NitrogenPassOption o in options) {
      if (o.recommended) return o;
    }
    return null;
  }

  NitrogenPassOption? optionFor(NitrogenPassPlan plan) {
    for (final NitrogenPassOption o in options) {
      if (o.plan == plan) return o;
    }
    return null;
  }

  /// La opción vigente: la declarada si aplica, si no la recomendada.
  NitrogenPassOption? get activeOption {
    final NutritionSeasonDeclaration? d = declaration;
    if (d != null && declarationApplied) return optionFor(d.passes);
    return recommendedOption;
  }
}

class NutritionWindowPlanResolver {
  const NutritionWindowPlanResolver._();

  /// Regla de incorporación que acompaña a toda dosis concentrada. En suelos
  /// calcáreos y alcalinos con urea en superficie la pérdida promedio es del
  /// 20 % y llega al 60 % en 24 días sin riego posterior (MSU EB0208; Engel
  /// et al. 2011; Holcomb et al. 2011); 11 mm de riego inmediato la deja
  /// por debajo del 5 %.
  static const String incorporationRuleEs =
      'Con toda la dosis en una pasada, riega o incorpora en las 24 h '
      'siguientes: en superficie y en suelo calcáreo se pierde hasta la mitad '
      'del nitrógeno.';

  static NutritionPlanResolution resolve({
    required NutritionGuide? guide,
    SoilTexture texture = SoilTexture.unknown,
    NutritionSeasonDeclaration? declaration,
    List<NutritionWindowRecord> windows = const <NutritionWindowRecord>[],
    String? seasonKey,
    String? currentStageKey,
  }) {
    if (guide == null) return NutritionPlanResolution.none;

    final SoilTextureClass textureClass = SoilTextureClassX.of(texture);
    final List<StageNutritionRule> nRules = guide.nitrogenWindowRules;
    final int planPasses = nRules.length;
    final SeasonNutrientPlan? nPlan = guide.seasonPlan[AgroMetricKey.n];

    // Sin clasificación o sin plan de N no hay nada que ofrecer ni plegar.
    if (!guide.splitRequirement.isClassified || nPlan == null || planPasses == 0) {
      return NutritionPlanResolution(
        baseGuide: guide,
        guide: guide,
        texture: texture,
        textureClass: textureClass,
        declaration: declaration,
        options: const <NitrogenPassOption>[],
        planPasses: planPasses,
        effectiveMinPasses: guide.minNitrogenPasses,
        declarationApplied: false,
        keptStageKeys: _keys(nRules),
        keptWindowLabelsEs: _labels(nRules),
      );
    }

    // El mínimo defendible nunca rebasa las ventanas que el plan declara:
    // exigir 3 pasadas a una guía de 2 dejaría la tarjeta sin opción válida.
    final int effectiveMin = math.min(
      _effectiveMinPasses(guide, textureClass),
      planPasses,
    );
    final List<NitrogenPassOption> options = _buildOptions(
      guide: guide,
      nRules: nRules,
      nPlan: nPlan,
      textureClass: textureClass,
      effectiveMin: effectiveMin,
    );

    final List<String> reasons = <String>[];

    // ── Declaración del productor ────────────────────────────────────────
    final NutritionSeasonDeclaration? d = declaration;
    // La declaración guarda el id de cultivo de la app (`crop_avocado_tree`)
    // y la guía se llama por su clave (`avocado_tree`): se comparan en
    // canónico, nunca los textos crudos.
    final bool declarationMatches = d != null &&
        (seasonKey == null || d.seasonKey == seasonKey) &&
        (d.cropKey.isEmpty ||
            NutritionGuideCatalog.canonicalKey(d.cropKey) ==
                NutritionGuideCatalog.canonicalKey(guide.cropKey));
    if (d != null && declarationMatches) {
      final NitrogenPassOption? chosen = _find(options, d.passes);
      if (chosen != null && chosen.enabled) {
        final _Folded folded = _fold(
          guide: guide,
          nRules: nRules,
          passes: d.passes,
          chosen: chosen,
        );
        if (d.passes.isAlreadyDone) {
          reasons.add(
            'Según tu declaración (ya fertilizaste), no queda ninguna ventana '
            'de nitrógeno esta temporada: '
            '${planPasses == 1 ? 'la única ventana de la guía se cierra' : 'las $planPasses ventanas de la guía se cierran'} '
            'sin pesar en el estado general; el sensor sigue observando el '
            'suelo.',
          );
        } else if (folded.changed) {
          reasons.add(
            'Plan ajustado a tu declaración (${d.passes.shortEs}): el '
            'nitrógeno de la temporada se reparte en '
            '${d.passes.passes == 1 ? 'una sola ventana' : '${d.passes.passes} ventanas'} '
            '(${_quoteList(folded.keptLabels)}) en vez de $planPasses, según '
            'la prioridad agronómica de la guía de ${guide.cropLabelEs}; las '
            'demás quedan sin ventana de nitrógeno y no pesan en el estado '
            'general.',
          );
        } else {
          reasons.add(
            'Tu declaración (${d.passes.shortEs}) coincide con el plan de la '
            'guía: sin cambios.',
          );
        }
        return NutritionPlanResolution(
          baseGuide: guide,
          guide: folded.changed ? guide.copyWithStageRules(folded.rules) : guide,
          texture: texture,
          textureClass: textureClass,
          declaration: d,
          options: options,
          planPasses: planPasses,
          effectiveMinPasses: effectiveMin,
          declarationApplied: true,
          foldedStageKeys: folded.foldedKeys,
          keptStageKeys: folded.keptKeys,
          keptWindowLabelsEs: folded.keptLabels,
          planNoteEs: folded.changed ? folded.planNoteEs : null,
          reasonsEs: reasons,
        );
      }
      reasons.add(
        'Tu declaración (${d.passes.shortEs}) ya no aplica en este sitio '
        '(${chosen?.disabledReasonEs ?? 'opción no disponible'}); se sigue '
        'el plan de la guía.',
      );
    }

    // ── Sin declaración: tono según la respuesta anterior ────────────────
    final _Demotion? demotion = _demoteAfterGreaterResponse(
      guide: guide,
      nRules: nRules,
      windows: windows,
      seasonKey: seasonKey,
      currentStageKey: currentStageKey,
    );
    if (demotion != null) {
      reasons.add(
        'La ventana «${demotion.previousLabelEs}» cerró con una respuesta '
        'mayor de lo habitual en este sitio: la ventana «${demotion.labelEs}» '
        'se muestra como orientativa y no pesa en el estado general. BIO-G no '
        'convierte la magnitud en kilos.',
      );
      return NutritionPlanResolution(
        baseGuide: guide,
        guide: guide.copyWithStageRules(demotion.rules),
        texture: texture,
        textureClass: textureClass,
        declaration: declarationMatches ? d : null,
        options: options,
        planPasses: planPasses,
        effectiveMinPasses: effectiveMin,
        declarationApplied: false,
        keptStageKeys: _keys(nRules),
        keptWindowLabelsEs: _labels(nRules),
        demotedStageKey: demotion.stageKey,
        reasonsEs: reasons,
      );
    }

    return NutritionPlanResolution(
      baseGuide: guide,
      guide: guide,
      texture: texture,
      textureClass: textureClass,
      declaration: declarationMatches ? d : null,
      options: options,
      planPasses: planPasses,
      effectiveMinPasses: effectiveMin,
      declarationApplied: false,
      keptStageKeys: _keys(nRules),
      keptWindowLabelsEs: _labels(nRules),
      reasonsEs: reasons,
    );
  }

  static List<String> _keys(List<StageNutritionRule> rules) =>
      List<String>.unmodifiable(rules.map((StageNutritionRule r) => r.primaryStageKey));

  static List<String> _labels(List<StageNutritionRule> rules) =>
      List<String>.unmodifiable(rules.map(_windowLabel));

  /// «Segunda fertilización (V6–V8)» o, sin nombre, la clave de etapa.
  static String _windowLabel(StageNutritionRule r) {
    final String label = (r.labelEs ?? '').trim();
    if (label.isNotEmpty) return label;
    return r.stageKeys.isEmpty ? 'la etapa' : r.stageKeys.first;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // MÍNIMO DEFENDIBLE Y OPCIONES
  // ═══════════════════════════════════════════════════════════════════════

  static int _effectiveMinPasses(NutritionGuide guide, SoilTextureClass tc) {
    final int base = guide.minNitrogenPasses < 1 ? 1 : guide.minNitrogenPasses;
    return switch (tc) {
      SoilTextureClass.coarse => guide.minNitrogenPassesCoarse ?? (base + 1),
      SoilTextureClass.fine => guide.minNitrogenPassesFine ?? base,
      SoilTextureClass.medium || SoilTextureClass.unknown => base,
    };
  }

  static NitrogenPassPlan _planFor(int passes) => passes <= 1
      ? NitrogenPassPlan.single
      : passes == 2
          ? NitrogenPassPlan.two
          : NitrogenPassPlan.threeOrMore;

  static List<NitrogenPassOption> _buildOptions({
    required NutritionGuide guide,
    required List<StageNutritionRule> nRules,
    required SeasonNutrientPlan nPlan,
    required SoilTextureClass textureClass,
    required int effectiveMin,
  }) {
    final int n = nRules.length;
    final NitrogenPassPlan recommended = _planFor(
      guide.recommendedNitrogenPasses ?? n,
    );
    final double? cap = guide.maxSinglePassKgN;
    final String crop = guide.cropLabelEs;
    final bool coarseEscalated = textureClass == SoilTextureClass.coarse &&
        effectiveMin > (guide.minNitrogenPasses < 1 ? 1 : guide.minNitrogenPasses);
    final bool fineRelaxed = textureClass == SoilTextureClass.fine &&
        guide.minNitrogenPassesFine != null &&
        guide.minNitrogenPassesFine! < guide.minNitrogenPasses;

    String minReason(int needed) {
      final String base = coarseEscalated
          ? 'En tu ${textureClass.labelEs} el nitrógeno se lava: la guía de '
              '$crop pide al menos $needed aplicaciones.'
          : 'La guía de $crop pide al menos $needed aplicaciones de '
              'nitrógeno: la curva de absorción no cabe en menos.';
      return base;
    }

    final List<NitrogenPassOption> out = <NitrogenPassOption>[];

    // ── Una sola vez ─────────────────────────────────────────────────────
    {
      final StageNutritionRule target = _singlePassTarget(guide, nRules);
      String? disabled;
      String? warning;
      if (effectiveMin > 1) {
        disabled = minReason(effectiveMin);
      } else if (n > 1 && cap != null && nPlan.minKgPerHa > cap) {
        disabled =
            'La guía de $crop no admite todo el nitrógeno en una pasada: '
            'ninguna aplicación debe pasar de ${_kg(cap)} kg N/ha y el plan '
            'necesita ${_kg(nPlan.minKgPerHa)}–${_kg(nPlan.maxKgPerHa)}.';
      } else {
        final List<String> warnings = <String>[];
        if (cap != null && nPlan.maxKgPerHa > cap) {
          warnings.add('No pases de ${_kg(cap)} kg N/ha en una sola pasada.');
        }
        if (guide.splitRequirement == NitrogenSplitRequirement.splitRecommended) {
          if (fineRelaxed) {
            warnings.add(
              'Tu suelo pesado retiene el nitrógeno: aquí la aplicación '
              'única es defendible.',
            );
          } else {
            warnings.add(
              'Con riegos pesados o lluvia fuerte parte del nitrógeno se '
              'pierde; si puedes, fracciona.',
            );
          }
        }
        if (warnings.isNotEmpty) warning = warnings.join(' ');
      }
      out.add(
        NitrogenPassOption(
          plan: NitrogenPassPlan.single,
          enabled: disabled == null,
          recommended: recommended == NitrogenPassPlan.single,
          helperEs: _ruleShortEs(target),
          disabledReasonEs: disabled,
          warningEs: warning,
        ),
      );
    }

    // ── Dos veces ────────────────────────────────────────────────────────
    if (n >= 2) {
      String? disabled;
      String? warning;
      final List<StageNutritionRule> pair = _keptRules(guide, nRules, 2);
      // La pasada que concentra el N de las ventanas plegadas tampoco debe
      // rebasar el tope por aplicación cuando la guía lo fija para CADA pasada
      // (cebolla y ajo: 112 kg N/ha, PNW 546 / CDFA): con el plan al máximo
      // se avisa; si ni al mínimo cabe, no se ofrece.
      final double? passCap = guide.capEveryPass ? cap : null;
      final double biggest = n > 2 ? _maxKeptShare(nRules, pair) : 0.0;
      if (effectiveMin > 2) {
        disabled = minReason(effectiveMin);
      } else if (passCap != null && biggest * nPlan.minKgPerHa > passCap) {
        disabled =
            'La guía de $crop no admite el nitrógeno en solo dos pasadas: '
            'ninguna aplicación debe pasar de ${_kg(passCap)} kg N/ha y la mayor '
            'llegaría a ${_kg(biggest * nPlan.minKgPerHa)}.';
      } else if (passCap != null && biggest * nPlan.maxKgPerHa > passCap) {
        warning =
            'No pases de ${_kg(passCap)} kg N/ha en una sola pasada: con el plan '
            'completo la aplicación grande llegaría a '
            '${_kg(biggest * nPlan.maxKgPerHa)}; quédate en la parte baja del '
            'plan o reparte esa pasada en dos.';
      }
      out.add(
        NitrogenPassOption(
          plan: NitrogenPassPlan.two,
          enabled: disabled == null,
          recommended: recommended == NitrogenPassPlan.two,
          helperEs: '${_ruleShortEs(pair[0])} y ${_ruleShortEs(pair[1])}',
          disabledReasonEs: disabled,
          warningEs: warning,
        ),
      );
    }

    // ── Tres o más ───────────────────────────────────────────────────────
    if (n >= 3) {
      out.add(
        NitrogenPassOption(
          plan: NitrogenPassPlan.threeOrMore,
          enabled: true,
          recommended: recommended == NitrogenPassPlan.threeOrMore,
          helperEs: 'el plan completo de la guía ($n aplicaciones)',
        ),
      );
    }

    // ── Ya fertilicé ─────────────────────────────────────────────────────
    // Siempre disponible: quien ya dio su nitrógeno (antes de instalar el
    // Bio-G o antes de contestar) y no va a volver a aplicar no debe recibir
    // avisos de «aplica» ni un «sin evidencia» por lo que ya hizo.
    out.add(
      const NitrogenPassOption(
        plan: NitrogenPassPlan.alreadyDone,
        enabled: true,
        recommended: false,
        helperEs: 'sin más nitrógeno este ciclo; BIO-G solo observa el suelo',
      ),
    );
    return out;
  }

  /// Ventana donde cae la aplicación única: la primera de la prioridad
  /// agronómica de la guía (`nitrogenPassPriority`; respaldo:
  /// `singlePassStageKey`, y si no, la primera ventana de N).
  static StageNutritionRule _singlePassTarget(
    NutritionGuide guide,
    List<StageNutritionRule> nRules,
  ) => _keptRules(guide, nRules, 1).first;

  /// Las [k] ventanas de N que conserva un plan de k pasadas: las k primeras
  /// de la prioridad agronómica, devueltas en ORDEN FENOLÓGICO (el de la
  /// guía). Con k ≥ n, todas.
  static List<StageNutritionRule> _keptRules(
    NutritionGuide guide,
    List<StageNutritionRule> nRules,
    int k,
  ) {
    if (k >= nRules.length) return nRules;
    final List<StageNutritionRule> byPriority = guide.nitrogenRulesByPriority;
    final Set<StageNutritionRule> chosen = byPriority.take(k).toSet();
    return nRules.where(chosen.contains).toList(growable: false);
  }

  /// Mayor fracción del plan de N que concentraría una de las ventanas
  /// conservadas ([keep], en orden fenológico) tras plegar las demás con la
  /// misma regla de reparto de [_fold]: cada ventana plegada suma su N a la
  /// conservada más cercana antes de ella o, si no hay, a la primera después.
  static double _maxKeptShare(
    List<StageNutritionRule> nRules,
    List<StageNutritionRule> keep,
  ) {
    if (keep.isEmpty) return 0.0;
    final Set<StageNutritionRule> keepSet = keep.toSet();
    final Map<StageNutritionRule, double> total = <StageNutritionRule, double>{
      for (final StageNutritionRule r in keep)
        r: r.seasonShare[AgroMetricKey.n] ?? 0.0,
    };
    for (int i = 0; i < nRules.length; i++) {
      final StageNutritionRule r = nRules[i];
      if (keepSet.contains(r)) continue;
      final StageNutritionRule? target = _foldTarget(nRules, keepSet, i);
      if (target == null) continue;
      total[target] = (total[target] ?? 0.0) + (r.seasonShare[AgroMetricKey.n] ?? 0.0);
    }
    double max = 0.0;
    for (final double v in total.values) {
      if (v > max) max = v;
    }
    return max > 1.0 ? 1.0 : max;
  }

  /// Ventana conservada que absorbe el N de la plegada [i]: la conservada más
  /// cercana ANTES de ella (la planta lo recibe antes de la demanda) o, si no
  /// hay ninguna antes, la primera conservada después.
  static StageNutritionRule? _foldTarget(
    List<StageNutritionRule> nRules,
    Set<StageNutritionRule> keepSet,
    int i,
  ) {
    for (int j = i - 1; j >= 0; j--) {
      if (keepSet.contains(nRules[j])) return nRules[j];
    }
    for (int j = i + 1; j < nRules.length; j++) {
      if (keepSet.contains(nRules[j])) return nRules[j];
    }
    return null;
  }

  static String _ruleShortEs(StageNutritionRule r) => _lowerFirst(_windowLabel(r));

  // ═══════════════════════════════════════════════════════════════════════
  // PLEGADO
  // ═══════════════════════════════════════════════════════════════════════

  static _Folded _fold({
    required NutritionGuide guide,
    required List<StageNutritionRule> nRules,
    required NitrogenPassPlan passes,
    required NitrogenPassOption chosen,
  }) {
    final int n = nRules.length;
    final int k = passes.passes;
    if (!passes.isAlreadyDone && (passes == NitrogenPassPlan.threeOrMore || k >= n)) {
      return _Folded(
        rules: guide.stageRules,
        foldedKeys: const <String>{},
        keptKeys: _keys(nRules),
        keptLabels: _labels(nRules),
        changed: false,
      );
    }

    // Reglas que conservan ventana de N (las k mejores según la prioridad
    // agronómica de la guía), en orden fenológico. Con «ya fertilicé»,
    // ninguna.
    final List<StageNutritionRule> keep = passes.isAlreadyDone
        ? const <StageNutritionRule>[]
        : _keptRules(guide, nRules, k);
    final Set<StageNutritionRule> keepSet = keep.toSet();

    // Reparto: el N de cada ventana plegada va a la ventana conservada más
    // cercana ANTES de ella (la planta lo recibe antes de la demanda); si no
    // hay ninguna antes, a la primera conservada después. Maíz «dos veces»:
    // V10–V12 → V6–V8 (1/3 + 2/3); «una sola vez» en V6–V8: fondo → V6–V8.
    final Map<StageNutritionRule, double> extra = <StageNutritionRule, double>{};
    final Map<StageNutritionRule, List<StageNutritionRule>> absorbedFrom =
        <StageNutritionRule, List<StageNutritionRule>>{};
    final Set<String> foldedKeys = <String>{};
    for (int i = 0; i < nRules.length; i++) {
      final StageNutritionRule r = nRules[i];
      if (keepSet.contains(r)) continue;
      foldedKeys.add(r.primaryStageKey);
      if (keep.isEmpty) continue;
      final StageNutritionRule? target = _foldTarget(nRules, keepSet, i);
      if (target == null) continue;
      extra[target] = (extra[target] ?? 0.0) + (r.seasonShare[AgroMetricKey.n] ?? 0.0);
      absorbedFrom.putIfAbsent(target, () => <StageNutritionRule>[]).add(r);
    }

    final List<String> keptLabels = _labels(keep);
    final String planNote = passes.isAlreadyDone
        ? 'Según tu plan, ya fertilizaste con nitrógeno esta temporada: no '
            'queda ninguna aplicación por hacer y BIO-G solo observa el suelo.'
        : 'Según tu plan (${passes.shortEs}), el nitrógeno de '
            '${guide.cropLabelEs} va en ${_quoteList(keptLabels)}.';

    final List<StageNutritionRule> out = <StageNutritionRule>[];
    for (final StageNutritionRule r in guide.stageRules) {
      if (keepSet.contains(r)) {
        final double add = extra[r] ?? 0.0;
        if (add <= 0.0) {
          out.add(r);
          continue;
        }
        // Normaliza a 1.0: en anuales el plan suma 1 y en frutales el
        // reparto anual también suma 1 para N.
        double share = (r.seasonShare[AgroMetricKey.n] ?? 0.0) + add;
        if (share > 1.0) share = 1.0;
        final Map<AgroMetricKey, double> shares = Map<AgroMetricKey, double>.of(
          r.seasonShare,
        )..[AgroMetricKey.n] = share;
        final List<String> rules = <String>[
          incorporationRuleEs,
          if (chosen.warningEs != null) chosen.warningEs!,
          ...r.rulesEs,
        ];
        final String what = k == 1
            ? 'aquí va todo el nitrógeno de la temporada'
            : 'aquí va también el nitrógeno de '
                '${_quoteList(_labels(absorbedFrom[r] ?? const <StageNutritionRule>[]))}';
        out.add(
          r.copyWith(
            windowNutrients: <AgroMetricKey>{...r.windowNutrients, AgroMetricKey.n},
            seasonShare: shares,
            rationaleEs: 'Según tu plan (${passes.shortEs}), $what. '
                '${(r.rationaleEs ?? '').trim()}'.trim(),
            rulesEs: rules,
          ),
        );
        continue;
      }
      if (!foldedKeys.contains(r.primaryStageKey)) {
        out.add(r);
        continue;
      }
      // Regla plegada: deja de repartir N y de abrir su ventana de N.
      final Map<AgroMetricKey, double> share = Map<AgroMetricKey, double>.of(
        r.seasonShare,
      )..remove(AgroMetricKey.n);
      final Set<AgroMetricKey> nutrients = <AgroMetricKey>{...r.windowNutrients}
        ..remove(AgroMetricKey.n);
      out.add(
        r.copyWith(
          windowNutrients: nutrients,
          seasonShare: share,
          isCritical: nutrients.isEmpty ? false : r.isCritical,
          rationaleEs: '$planNote Aquí no toca aplicar nitrógeno; el sensor '
              'sigue observando el suelo.',
        ),
      );
    }
    return _Folded(
      rules: out,
      foldedKeys: foldedKeys,
      keptKeys: _keys(keep),
      keptLabels: keptLabels,
      planNoteEs: planNote,
      changed: true,
    );
  }

  /// «Segunda fertilización (V6–V8)» / «Fondo y V6–V8» / «A, B y C», con
  /// comillas angulares.
  static String _quoteList(List<String> labels) {
    final List<String> q = labels.map((String l) => '«$l»').toList();
    if (q.isEmpty) return 'ninguna ventana';
    if (q.length == 1) return q.single;
    return '${q.sublist(0, q.length - 1).join(', ')} y ${q.last}';
  }

  // ═══════════════════════════════════════════════════════════════════════
  // TONO TRAS UNA RESPUESTA MAYOR DE LO HABITUAL
  // ═══════════════════════════════════════════════════════════════════════

  static _Demotion? _demoteAfterGreaterResponse({
    required NutritionGuide guide,
    required List<StageNutritionRule> nRules,
    required List<NutritionWindowRecord> windows,
    required String? seasonKey,
    required String? currentStageKey,
  }) {
    if (nRules.length < 2 || windows.isEmpty) return null;
    final String current = StageNutritionRule.normalizeStageKey(currentStageKey);
    if (current.isEmpty) return null;

    // Regla actual: solo se degrada una ventana de N que esté abierta ahora.
    final int currentIdx = guide.ruleIndexFor(currentStageKey);
    if (currentIdx < 0) return null;
    final StageNutritionRule currentRule = guide.stageRules[currentIdx];
    if (!currentRule.windowNutrients.contains(AgroMetricKey.n)) return null;

    // Ventana de N anterior (en el orden de la guía) atendida con respuesta
    // «mayor», en esta temporada.
    NutritionWindowRecord? greater;
    int greaterIdx = -1;
    for (final NutritionWindowRecord w in windows) {
      if (seasonKey != null && w.seasonKey != seasonKey) continue;
      if (w.outcome != NutritionWindowOutcome.attendedDetected) continue;
      if (w.responseVerdict != ResponseVerdict.greater) continue;
      if (!w.nutrients.contains(AgroMetricKey.n)) continue;
      final int idx = guide.ruleIndexFor(w.stageKey);
      if (idx < 0 || idx >= currentIdx) continue;
      if (idx > greaterIdx) {
        greaterIdx = idx;
        greater = w;
      }
    }
    if (greater == null) return null;

    // Solo la SIGUIENTE ventana de N después de la «mayor»: entre ambas no
    // debe haber otra ventana de N.
    for (int i = greaterIdx + 1; i < currentIdx; i++) {
      if (guide.stageRules[i].windowNutrients.contains(AgroMetricKey.n)) {
        return null;
      }
    }

    final List<StageNutritionRule> out = <StageNutritionRule>[];
    for (int i = 0; i < guide.stageRules.length; i++) {
      final StageNutritionRule r = guide.stageRules[i];
      if (i != currentIdx) {
        out.add(r);
        continue;
      }
      out.add(
        r.copyWith(
          isCritical: false,
          rationaleEs:
              'La aplicación anterior dio una respuesta mayor de lo habitual '
              'en este sitio. Si concentraste el nitrógeno, esta ventana puede '
              'ser menor o innecesaria; si fraccionaste, aquí va la siguiente. '
              '${(r.rationaleEs ?? '').trim()}'.trim(),
          rulesEs: <String>[
            'Ajusta la dosis a lo que ya aplicaste: BIO-G no mide kilos, '
                'solo vio que el suelo respondió más de lo habitual.',
            ...r.rulesEs,
          ],
        ),
      );
    }
    return _Demotion(
      rules: out,
      stageKey: currentRule.primaryStageKey,
      labelEs: currentRule.labelEs ?? currentStageKey ?? 'esta ventana',
      previousLabelEs: greater.displayLabelEs,
    );
  }

  static NitrogenPassOption? _find(List<NitrogenPassOption> options, NitrogenPassPlan p) {
    for (final NitrogenPassOption o in options) {
      if (o.plan == p) return o;
    }
    return null;
  }

  static String _kg(double v) => v.round().toString();

  static String _lowerFirst(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);
}

class _Folded {
  const _Folded({
    required this.rules,
    required this.foldedKeys,
    required this.keptKeys,
    required this.keptLabels,
    required this.changed,
    this.planNoteEs,
  });
  final List<StageNutritionRule> rules;
  final Set<String> foldedKeys;
  final List<String> keptKeys;
  final List<String> keptLabels;
  final String? planNoteEs;
  final bool changed;
}

class _Demotion {
  const _Demotion({
    required this.rules,
    required this.stageKey,
    required this.labelEs,
    required this.previousLabelEs,
  });
  final List<StageNutritionRule> rules;
  final String stageKey;
  final String labelEs;
  final String previousLabelEs;
}
