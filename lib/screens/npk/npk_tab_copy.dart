// lib/screens/npk/npk_tab_copy.dart
//
// COPY DE LA PESTAÑA N/P/K: lo que cada pestaña dice de SU nutriente, en
// lenguaje de campo (Guía oficial del nuevo motor nutricional v0.4, §17
// «UI/UX»; decisiones de producto del 7 sep 2026).
//
// Vive fuera del widget, sin Flutter, para que sea puro y se pueda probar
// contra las 32 guías curadas:
//   · titular   → «Aplica fósforo: establecimiento»
//   · dosis     → «30–60 kg/ha de P₂O₅ · ≈ 60–115 kg/ha de MAP»
//   · resumen   → cuándo, por qué y qué hace BIO-G mientras tanto
//   · chip      → «Importante en establecimiento», solo si la ventana pesa
//   · píldora   → «Estable» / «Calibrando» / «Al alza» / «A la baja» / «Sin señal»
//
// REGLAS DEL RESUMEN (Oscar, 7 sep 2026)
// -------------------------------------
//   1. Máximo [NpkTabCopy.kMaxSummaryWords] palabras. Si no cabe, se recorta
//      por frases enteras y en este orden: primero el recordatorio de BIO-G,
//      después las frases finales del porqué, al último el «cuándo». El
//      porqué nunca desaparece del todo.
//   2. Frases completas y amigables. Nada de «prioridad fenológica»,
//      «firma» ni «restitución»: eso vive en la hoja «Ver detalle».
//   3. Los nutrientes con todas sus letras: «fósforo», nunca «P» a secas
//      ([spellOutNutrients]). Las formas comerciales (P₂O₅, K₂O, MAP, urea)
//      se escriben como en la bolsa, porque así las compra el agricultor.
//   4. Siempre lleva el porqué de la decisión (la regla de la guía o, sin
//      guía, el perfil del cultivo), no solo la instrucción.
import 'dart:ui' show Color;

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';

/// Tono del bloque de acción: define el color del titular.
enum NpkTabTone { calm, action, wait, good }

/// Bloque de acción de una pestaña: titular, dosis, resumen y chip.
class NpkTabCopy {
  const NpkTabCopy({
    required this.headline,
    this.dose,
    this.summary,
    this.importance,
    this.tone = NpkTabTone.calm,
  });

  /// «Aplica fósforo: establecimiento», «Espera para aplicar nitrógeno»…
  final String headline;

  /// «30–60 kg/ha de P₂O₅ · ≈ 60–115 kg/ha de MAP». Null sin cifra.
  final String? dose;

  /// Resumen amigable, ≤ [kMaxSummaryWords] palabras. Null si no hay nada
  /// que decir.
  final String? summary;

  /// «Importante en establecimiento»: solo cuando la ventana de este
  /// nutriente pesa en la etapa (ventana importante o prioridad alta).
  final String? importance;

  final NpkTabTone tone;

  /// Tope de palabras del resumen (regla de producto, 7 sep 2026).
  static const int kMaxSummaryWords = 50;

  // ── Construcción ──────────────────────────────────────────────────────────

  static NpkTabCopy build({
    required AgroMetricKey nutrient,
    required NutritionDecision? decision,
    required bool isGuide,
    required bool isPlanned,
    required bool hasLive,
    required NutrientTrend trend,
  }) {
    final String name = nutrient.labelEs.toLowerCase();
    final String capName = nutrient.labelEs;

    if (isGuide) {
      return NpkTabCopy(
        headline: 'Sin cultivo asignado',
        summary: summarize(
          lead: <String>[
            'Asigna un cultivo y BIO-G te dirá cuándo y cuánto $name aplicar, '
                'con el porqué de cada ventana.',
          ],
        ),
      );
    }
    if (isPlanned) {
      return NpkTabCopy(
        headline: 'Referencia antes de sembrar',
        summary: summarize(
          lead: <String>[
            'Por ahora solo ves la lectura del sensor.',
            'Al sembrar, BIO-G te dirá cuándo y cuánto $name aplicar según la '
                'guía de tu cultivo.',
          ],
        ),
      );
    }
    final NutritionDecision? d = decision;
    if (d == null) {
      return NpkTabCopy(
        headline: '$capName en seguimiento',
        summary: summarize(
          lead: <String>[
            'BIO-G está cargando la memoria de tu suelo; en un momento te dice '
                'qué toca con el $name.',
          ],
        ),
      );
    }

    final NutritionRecommendation? rec = recommendationFor(d, nutrient);
    if (rec != null) {
      final NutritionDoseRange? range = rec.doseFor(nutrient);
      final String? dose = range == null ? null : doseLine(range);
      final bool focus = rec.coversNutrient(nutrient);
      switch (rec.kind) {
        case NutritionRecommendationKind.apply:
          return NpkTabCopy(
            headline: rec.headlineForNutrient(nutrient),
            dose: dose,
            importance: importanceFor(d, nutrient, rec),
            tone: NpkTabTone.action,
            summary: summarize(
              lead: <String>[
                if (range != null && range.isConditional)
                  _sentence(range.conditionEs)!,
                if (!focus) 'Va junto con la aplicación principal de esta etapa.',
                if (range == null)
                  'La cantidad: según la etiqueta del producto o tu asesor.',
              ],
              when: rec.timingEs,
              why: rec.rationaleEs,
              tail: d.window?.signature != null
                  ? 'BIO-G ya ve un cambio en el suelo y lo está confirmando.'
                  : 'Cuando apliques no registres nada: BIO-G lo detecta.',
            ),
          );
        case NutritionRecommendationKind.prepare:
          final String blocker = d.conditions.blockersEs.isEmpty
              ? 'El suelo todavía no está listo para recibir fertilizante.'
              : firstSentence(d.conditions.blockersEs.first);
          return NpkTabCopy(
            headline: focus
                ? 'Espera para aplicar $name'
                : 'Acompaña con $name, pero espera',
            dose: dose,
            importance: importanceFor(d, nutrient, rec),
            tone: NpkTabTone.wait,
            summary: summarize(
              lead: <String>[blocker],
              why: rec.rationaleEs,
              tail: 'BIO-G te avisa cuando el suelo esté listo.',
            ),
          );
        case NutritionRecommendationKind.upcoming:
          final int? days = rec.inDays;
          final String stage = (rec.stageLabelEs ?? '').trim();
          final String entering = days == null
              ? 'Se acerca la ventana de $name.'
              : stage.isEmpty
              ? 'En unos ${_days(days)} se abre la ventana de $name.'
              : 'En unos ${_days(days)} entra «$stage» y se abre la ventana '
                    'de $name.';
          return NpkTabCopy(
            headline: rec.headlineForNutrient(nutrient),
            dose: dose,
            tone: NpkTabTone.action,
            summary: summarize(
              lead: <String>[entering],
              why: rec.rationaleEs,
              tail: 'Ten el producto listo; cuando apliques no registres '
                  'nada, BIO-G lo detecta.',
            ),
          );
      }
    }

    if (d.state == NutritionState.responseWindow) {
      return NpkTabCopy(
        headline: 'Fertilización detectada',
        tone: NpkTabTone.good,
        summary: summarize(
          lead: <String>[
            'BIO-G vio en el suelo un cambio compatible con una fertilización '
                'y está siguiendo la respuesta.',
            'No tienes que registrar nada.',
          ],
        ),
      );
    }
    if (d.state == NutritionState.learning) {
      final int? left = d.learningDaysLeft;
      return NpkTabCopy(
        headline: 'Conociendo tu suelo',
        summary: summarize(
          lead: <String>[
            'Son los primeros días del sensor en esta zona: BIO-G está '
                'aprendiendo cómo se comporta tu suelo antes de leer '
                'tendencias.',
            if (left != null && left > 0)
              'En ${_days(left)} la tendencia será confiable.',
          ],
        ),
      );
    }

    // La etapa quedó plegada por el plan del productor: su nitrógeno va en
    // otra pasada (o ya lo dio). Se dice con esas palabras, antes de mirar
    // el libro: una ventana plegada puede haber cerrado «sin evidencia» sin
    // pesar, y eso no es un reproche que mostrar (17 sep 2026).
    final String? planNote = d.planNoteEs;
    if (nutrient == AgroMetricKey.n && planNote != null) {
      return NpkTabCopy(
        headline: d.isNitrogenAlreadyDone
            ? 'Nitrógeno ya aplicado'
            : 'Sin nitrógeno en esta etapa',
        tone: d.isNitrogenAlreadyDone ? NpkTabTone.good : NpkTabTone.calm,
        summary: summarize(
          lead: <String>[
            planNote,
            'Si eso cambió, ajusta tu plan con el icono de ajustes de esta '
                'pantalla.',
            trendSentence(nutrient, trend, hasLive: hasLive),
          ],
          tail: d.nextWindowNoteEs,
        ),
      );
    }

    final NutritionWindowRecord? window = d.window;
    if (window != null &&
        window.outcome == NutritionWindowOutcome.attendedDetected &&
        window.nutrients.contains(nutrient)) {
      return NpkTabCopy(
        headline: '$capName atendido en esta etapa',
        tone: NpkTabTone.good,
        summary: summarize(
          lead: <String>[
            'El suelo ya respondió a la fertilización de esta ventana, así '
                'que BIO-G no pide más $name por ahora.',
          ],
          tail: d.nextWindowNoteEs,
        ),
      );
    }
    final NutritionWindowRecord? unattended = d.recentlyUnattendedWindow;
    if (unattended != null && unattended.nutrients.contains(nutrient)) {
      return NpkTabCopy(
        headline: 'Ventana de $name cerrada sin evidencia',
        tone: NpkTabTone.wait,
        summary: summarize(
          lead: <String>[
            'La ventana «${unattended.displayLabelEs}» terminó sin que la '
                'sonda viera una respuesta compatible con fertilización.',
            'No es seguro que no aplicaste: el producto pudo quedar fuera del '
                'alcance de la sonda o llegar con poca agua.',
          ],
          tail: d.nextWindowNoteEs,
        ),
      );
    }

    // Sin ventana para este nutriente: por qué no toca ahora (la guía), hacia
    // dónde va la señal y cuándo vuelve a tocar. Si la etapa quedó plegada
    // por el plan de nitrógeno, la nota de cierre habla de nitrógeno: para
    // fósforo y potasio vale más la del perfil de la etapa.
    return NpkTabCopy(
      headline: 'Sin aplicar $name por ahora',
      summary: summarize(
        lead: <String>[
          (planNote == null ? d.closedWindowNoteEs : null) ?? _stageNote(d, nutrient),
          trendSentence(nutrient, trend, hasLive: hasLive),
        ],
        tail: d.nextWindowNoteEs,
      ),
    );
  }

  /// Recomendación vigente si dice algo de este nutriente: es foco de la
  /// ventana (una ventana puede abrir N, P y K a la vez: «fertilización de
  /// fondo») o lleva dosis de acompañamiento («acompaña con K₂O …»).
  static NutritionRecommendation? recommendationFor(
    NutritionDecision decision,
    AgroMetricKey nutrient,
  ) {
    final NutritionRecommendation? rec = decision.recommendation;
    if (rec == null || !rec.mentionsNutrient(nutrient)) return null;
    return rec;
  }

  /// «Importante en establecimiento» cuando la ventana abierta de este
  /// nutriente es importante (su cierre sin evidencia pesa) o la etapa lo
  /// marca en prioridad alta. Null en los demás casos: sin ventana abierta,
  /// un «importante» junto a «sin aplicar por ahora» solo confundiría.
  static String? importanceFor(
    NutritionDecision decision,
    AgroMetricKey nutrient,
    NutritionRecommendation rec,
  ) {
    if (rec.kind == NutritionRecommendationKind.upcoming) return null;
    final bool focus = rec.coversNutrient(nutrient);
    final bool criticalWindow = focus && (decision.window?.isCritical ?? false);
    NutrientStagePriority? priority;
    for (final NutrientStagePriority p in decision.priorities) {
      if (p.nutrient == nutrient) priority = p;
    }
    final bool highPriority =
        priority != null &&
        (priority.isCriticalWindow ||
            priority.priority == NutritionPriority.high);
    if (!criticalWindow && !highPriority) return null;
    final String stage = (rec.stageLabelEs ?? decision.stageLabelEs ?? '')
        .trim();
    return stage.isEmpty
        ? 'Importante en esta etapa'
        : 'Importante en ${lowerFirst(stage)}';
  }

  /// «El nitrógeno importa en «Vegetativo» (…), pero la guía no abre ventana
  /// ahora.» o «En «Cosecha» el nitrógeno no está en demanda.»
  static String _stageNote(NutritionDecision d, AgroMetricKey nutrient) {
    final String name = nutrient.labelEs.toLowerCase();
    final String stage = (d.stageLabelEs ?? '').trim();
    NutrientStagePriority? p;
    for (final NutrientStagePriority x in d.priorities) {
      if (x.nutrient == nutrient) p = x;
    }
    final String where = stage.isEmpty ? 'esta etapa' : '«$stage»';
    if (p != null && p.priority != NutritionPriority.low) {
      final String why = p.rationaleEs.trim();
      return why.isEmpty
          ? 'El $name importa en $where, pero no hay ventana de aplicación '
                'abierta.'
          : 'El $name importa en $where (${lowerFirst(_stripDot(why))}), pero '
                'no hay ventana de aplicación abierta.';
    }
    return 'En $where el $name no está en demanda.';
  }

  /// «La señal de nitrógeno viene al alza.» Sin cifras: las trae la fila de
  /// abajo.
  static String trendSentence(
    AgroMetricKey nutrient,
    NutrientTrend trend, {
    required bool hasLive,
  }) {
    final String n = nutrient.labelEs.toLowerCase();
    if (!hasLive) return 'Ahora mismo no llega señal del sensor.';
    return switch (trend.trend) {
      NativeTrend.rising => 'La señal de $n viene al alza.',
      NativeTrend.falling => 'La señal de $n viene a la baja.',
      NativeTrend.stable => 'La señal de $n se mantiene estable.',
      NativeTrend.unknown => 'BIO-G sigue reuniendo lecturas de $n.',
    };
  }

  /// «40–80 kg/ha de P₂O₅ · ≈ 75–155 kg/ha de MAP».
  static String doseLine(NutritionDoseRange r) {
    final String? eq = r.commercialEquivalentEs;
    return eq == null || eq.trim().isEmpty ? r.labelEs : '${r.labelEs} · $eq';
  }

  // ── Resumen ───────────────────────────────────────────────────────────────

  /// Arma el resumen y lo deja en ≤ [kMaxSummaryWords] palabras.
  ///
  /// [lead] son frases cortas que van primero (condición, aviso); [when] el
  /// momento de la guía; [why] el porqué; [tail] el recordatorio de BIO-G.
  /// Recorte, en orden: tail → frases finales de why → when → frases finales
  /// de lead → corte duro de why. Todo pasa por [spellOutNutrients].
  static String? summarize({
    List<String?> lead = const <String?>[],
    String? when,
    String? why,
    String? tail,
  }) {
    final List<String> head = <String>[
      for (final String? s in lead) ?_sentence(s),
    ];
    String? whenS = _sentence(when);
    List<String> whyS = _sentences(why);
    String? tailS = _sentence(tail);

    String compose() => <String>[
      ...head,
      ?whenS,
      ...whyS,
      ?tailS,
    ].join(' ');

    String text = compose();
    if (wordCount(text) > kMaxSummaryWords) {
      tailS = null;
      text = compose();
    }
    while (wordCount(text) > kMaxSummaryWords && whyS.length > 1) {
      whyS = whyS.sublist(0, whyS.length - 1);
      text = compose();
    }
    if (wordCount(text) > kMaxSummaryWords && whenS != null) {
      whenS = null;
      text = compose();
    }
    while (wordCount(text) > kMaxSummaryWords && head.length > 1) {
      head.removeLast();
      text = compose();
    }
    if (wordCount(text) > kMaxSummaryWords) {
      text = _hardCut(text, kMaxSummaryWords);
    }
    final String out = spellOutNutrients(text).trim();
    return out.isEmpty ? null : out;
  }

  /// Palabras de un texto: fichas con al menos una letra o un dígito («·» y
  /// «≈» no cuentan).
  static int wordCount(String text) => text
      .split(RegExp(r'\s+'))
      .where((String t) => RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(t))
      .length;

  /// «N», «P» y «K» sueltas → nitrógeno, fósforo y potasio. No toca P₂O₅,
  /// K₂O, NPK, MAP, KCl ni V6: solo la letra aislada. Al inicio de una frase
  /// va con mayúscula.
  static String spellOutNutrients(String text) {
    return text.replaceAllMapped(_bareNutrient, (Match m) {
      final String before = m.group(1)!;
      final String name = switch (m.group(2)!) {
        'N' => 'nitrógeno',
        'P' => 'fósforo',
        _ => 'potasio',
      };
      final bool sentenceStart = _isSentenceStart(text, m.start + before.length);
      return '$before${sentenceStart ? _capitalize(name) : name}';
    });
  }

  /// Letra N/P/K que no forma parte de una palabra, una fórmula (P₂O₅, K₂O)
  /// ni una sigla (NPK, MAP, KCl).
  static final RegExp _bareNutrient = RegExp(
    r'(^|[^\p{L}\p{N}_₀-₉])([NPK])(?![\p{L}\p{N}_₀-₉])',
    unicode: true,
  );

  static bool _isSentenceStart(String text, int at) {
    final String before = text.substring(0, at).trimRight();
    return before.isEmpty || RegExp(r'[.!?]$').hasMatch(before);
  }

  /// Primera frase de un texto largo (bloqueos, reglas).
  static String firstSentence(String text) {
    final String t = text.trim();
    final int cut = t.indexOf(RegExp(r'[.;]\s'));
    final String first = cut < 0 ? t : t.substring(0, cut + 1);
    if (first.endsWith(';')) return '${first.substring(0, first.length - 1)}.';
    return first.endsWith('.') ? first : '$first.';
  }

  /// Baja la inicial salvo en siglas («MAP», «V6») y nombres propios de
  /// una letra.
  static String lowerFirst(String s) {
    if (s.length < 2) return s;
    final String second = s[1];
    final bool secondIsLowerLetter =
        second.toLowerCase() == second && second.toUpperCase() != second;
    if (!secondIsLowerLetter) return s;
    return s[0].toLowerCase() + s.substring(1);
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _stripDot(String s) =>
      s.endsWith('.') ? s.substring(0, s.length - 1) : s;

  /// Frase limpia: recortada, con mayúscula inicial y punto final. Null si
  /// no hay texto.
  static String? _sentence(String? raw) {
    String t = (raw ?? '').trim();
    if (t.isEmpty) return null;
    if (t.endsWith(';') || t.endsWith(',')) t = t.substring(0, t.length - 1);
    if (!RegExp(r'[.!?…]$').hasMatch(t)) t = '$t.';
    return _capitalize(t);
  }

  /// Parte un texto en frases limpias (por «. », «; »).
  static List<String> _sentences(String? raw) {
    final String t = (raw ?? '').trim();
    if (t.isEmpty) return const <String>[];
    return <String>[
      for (final String s in t.split(RegExp(r'(?<=[.!?;])\s+')))
        if (_sentence(s) != null) _sentence(s)!,
    ];
  }

  /// Corte duro a [max] palabras, con puntos suspensivos. Último recurso:
  /// solo entra si una sola frase pasa del tope.
  static String _hardCut(String text, int max) {
    final List<String> tokens = text.split(RegExp(r'\s+'));
    final List<String> out = <String>[];
    int words = 0;
    for (final String t in tokens) {
      if (RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(t)) {
        if (words == max) break;
        words++;
      }
      out.add(t);
    }
    final String cut = out.join(' ').replaceAll(RegExp(r'[,;:]$'), '');
    return cut.endsWith('.') ? cut : '$cut…';
  }

  static String _days(int n) => n == 1 ? '1 día' : '$n días';
}

/// Píldora del arco: hacia dónde va la señal, con color según el estado.
///
/// Regla de producto (Oscar, 7 sep 2026): nada de «Sin tendencia aún» en
/// gris. Mientras el sitio aprende se dice «Calibrando»; si ya pasó el
/// aprendizaje y la señal no se mueve, «Estable».
class NpkTrendPill {
  const NpkTrendPill({required this.label, required this.color});

  final String label;
  final Color color;

  static const Color rising = Color(0xFF1F7FA8);
  static const Color falling = Color(0xFFB9761A);
  static const Color stable = Color(0xFF2E7D5A);
  static const Color calibrating = Color(0xFF4C63B6);
  static const Color noSignal = Color(0xFF5B6470);

  static NpkTrendPill resolve({
    required bool hasLive,
    required NutrientTrend trend,
    required NutritionDecision? decision,
  }) {
    if (!hasLive) {
      return const NpkTrendPill(label: 'Sin señal', color: noSignal);
    }
    switch (trend.trend) {
      case NativeTrend.rising:
        return const NpkTrendPill(label: 'Al alza', color: rising);
      case NativeTrend.falling:
        return const NpkTrendPill(label: 'A la baja', color: falling);
      case NativeTrend.stable:
        return const NpkTrendPill(label: 'Estable', color: stable);
      case NativeTrend.unknown:
        final bool learning =
            decision != null &&
            (decision.state == NutritionState.learning ||
                decision.isLearningSite);
        final bool fewSamples =
            trend.samples < NutrientTrend.kMinSamplesPerSide * 2;
        if (learning || fewSamples) {
          return const NpkTrendPill(label: 'Calibrando', color: calibrating);
        }
        return const NpkTrendPill(label: 'Estable', color: stable);
    }
  }
}
