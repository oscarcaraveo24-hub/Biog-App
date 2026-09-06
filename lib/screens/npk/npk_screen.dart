// lib/screens/npk/npk_screen.dart
//
// PANTALLA DE NUTRICIÓN (Guía oficial del nuevo motor nutricional v0.4, §8,
// §9 y §17 «UI/UX»).
//
// Tres cosas, en este orden, y nada más:
//   1. Qué decidió el motor de nutrición (`NutritionDecision`): qué necesita la
//      etapa, qué observa la sonda, cómo respondió el suelo. Una sola
//      autoridad; aquí no se interpreta ninguna lectura.
//   2. Las señales nativas N/P/K de la sonda como TENDENCIA, en la escala del
//      propio sitio: sin objetivo, sin «bajo/alto», sin dosis derivada.
//   3. La nota que acompaña siempre a esas señales: son datos nativos del
//      sensor, derivados de la conductividad; no equivalen a un análisis de
//      laboratorio.
//
// LO QUE YA NO EXISTE AQUÍ (y no debe volver): topes ppm por cultivo, rangos
// objetivo por etapa sobre la lectura, dosis calculadas desde la sonda,
// «Registrar aplicación». El agricultor no registra nada: la sonda observa.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/npk/npk_gauge_card.dart';

enum InsightTone { ok, warn, bad }

/// Nota obligatoria junto a cualquier señal nativa N/P/K (Guía v0.4, §8).
const String kNativeSignalNoteEs =
    'Datos nativos del sensor utilizados para seguimiento de tendencias. No '
    'equivalen a un análisis de laboratorio.';

class NpkScreen extends StatefulWidget {
  const NpkScreen({super.key});

  @override
  State<NpkScreen> createState() => _NpkScreenState();
}

class _NpkScreenState extends State<NpkScreen> {
  // ───────────────────────────────────────────────────────────────────────────
  // O1 · El stream del historial se resuelve UNA vez, no en cada `build`.
  // ───────────────────────────────────────────────────────────────────────────
  //
  // `BioGStore.watchHistory` devuelve un stream NUEVO en cada llamada y
  // `StreamBuilder` compara por identidad: pedirlo en el `build` forzaba la
  // resuscripción completa (query SQLite + hasta 2000 `jsonDecode`) en cada
  // notificación del store. Ver el historial de este archivo para la medición.
  Stream<List<BioGTelemetry>>? _history7dStream;
  BioGStore? _boundStore;
  String? _boundTelemetryDeviceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = BioGScope.of(context);
    final telemetryDeviceId = store.activeDevice?.telemetryDeviceId;
    final bool sameBinding =
        _history7dStream != null &&
        identical(store, _boundStore) &&
        telemetryDeviceId == _boundTelemetryDeviceId;
    if (sameBinding) return;
    _boundStore = store;
    _boundTelemetryDeviceId = telemetryDeviceId;
    _history7dStream = store.watchHistory(const Duration(days: 7));
  }

  AgroMetricKey _metricKeyFor(NpkChannel ch) => switch (ch) {
    NpkChannel.n => AgroMetricKey.n,
    NpkChannel.p => AgroMetricKey.p,
    NpkChannel.k => AgroMetricKey.k,
  };

  int _roundInt(double v) => v.isNaN ? 0 : v.round();

  /// Tendencia: promedio de las 3 últimas lecturas contra las 3 anteriores.
  double? _trendPctFromSeries(List<double> series) {
    if (series.length < 6) return null;
    double avg(List<double> xs) =>
        xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;
    final a = avg(series.sublist(series.length - 3));
    final b = avg(series.sublist(series.length - 6, series.length - 3));
    if (b.abs() < 0.0001) return null;
    return ((a - b) / b) * 100.0;
  }

  /// Estadística de la señal nativa en la ESCALA DEL SITIO.
  ///
  /// El arco no se compara contra un tope por cultivo ni contra un objetivo:
  /// se escala al máximo reciente del propio punto, para que lo que se vea sea
  /// «dónde está hoy respecto a su propia semana». Sin objetivo no hay banda.
  _NpkStats _statsForChannel({
    required NpkChannel channel,
    required BioGTelemetry? live,
    required List<double> series,
    required double? trendPct,
  }) {
    final bool hasLive = live != null &&
        switch (channel) {
          NpkChannel.n => live.hasNitrogenData,
          NpkChannel.p => live.hasPhosphorusData,
          NpkChannel.k => live.hasPotassiumData,
        };
    final double level = !hasLive
        ? double.nan
        : switch (channel) {
            NpkChannel.n => live!.n.toDouble(),
            NpkChannel.p => live!.p.toDouble(),
            NpkChannel.k => live!.k.toDouble(),
          };

    final double avg7 = series.isEmpty
        ? double.nan
        : series.reduce((a, b) => a + b) / series.length;
    final double minV = series.isEmpty ? double.nan : series.reduce(math.min);
    final double maxV = series.isEmpty ? double.nan : series.reduce(math.max);

    // Escala del sitio: 15 % por encima del máximo reciente, con un piso para
    // que una serie plana en cero no divida entre cero.
    final double siteMax = <double>[
      if (maxV.isFinite) maxV,
      if (level.isFinite) level,
    ].fold<double>(0.0, math.max);
    final double scale = math.max(10.0, siteMax * 1.15);
    final double gaugePercent = level.isFinite
        ? (level / scale).clamp(0.0, 1.0)
        : 0.0;

    return _NpkStats(
      hasLive: level.isFinite,
      level: _roundInt(level.isFinite ? level : 0.0),
      avg7: avg7.isFinite ? _roundInt(avg7) : null,
      rangeMin: minV.isFinite ? _roundInt(minV) : null,
      rangeMax: maxV.isFinite ? _roundInt(maxV) : null,
      avgTrendPct: trendPct,
      gaugePercent: gaugePercent,
      scale: scale,
    );
  }

  String _trendLabel(double? trendPct, {required bool hasLive}) {
    if (!hasLive) return 'Sin señal';
    if (trendPct == null) return 'Señal nativa';
    if (trendPct > 4) return 'Subiendo';
    if (trendPct < -4) return 'Bajando';
    return 'Estable';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    final store = BioGScope.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.black.withValues(alpha: 0.65),
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Stack(
          children: [
            const _NpkSoftBackground(),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                child: StreamBuilder<List<BioGTelemetry>>(
                  stream: _history7dStream,
                  builder: (context, snap) {
                    final history7d = snap.data ?? const <BioGTelemetry>[];
                    final live = store.live;
                    final device = store.activeDevice;
                    final DeviceCropContext? cropContext =
                        store.activeCropContext;
                    final seed = store.activeSeed;
                    final DateTime now = DateTime.now();

                    final runtime = CropRuntimeResolver.resolve(
                      device: device,
                      seed: seed,
                      cropContext: cropContext,
                      live: live,
                      alertsState: store.alertsState,
                      now: now,
                    );

                    // MODO GUÍA GENERAL: la lectura se muestra, la lectura
                    // agronómica no se inventa (sin cultivo no hay ventana).
                    final bool isGuide = runtime.isGuideMode;
                    final bool isPlanted = runtime.isPlanted && !isGuide;
                    final bool isPlanned = runtime.isPlanned;

                    // La decisión la publica el Panel; aquí solo se lee. Si no
                    // hay decisión vigente, la pantalla lo dice.
                    final NutritionDecision? decision = isPlanted
                        ? store.nutritionDecisionAt(now)
                        : null;

                    // Una sola ordenación del historial por build.
                    final sortedHistory = [...history7d]
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                    final nSeries = <double>[];
                    final pSeries = <double>[];
                    final kSeries = <double>[];
                    for (final t in sortedHistory) {
                      // Solo lo que la sonda midió: ausencia no es cero.
                      if (t.hasNitrogenData) nSeries.add(math.max(0.0, t.n.toDouble()));
                      if (t.hasPhosphorusData) pSeries.add(math.max(0.0, t.p.toDouble()));
                      if (t.hasPotassiumData) kSeries.add(math.max(0.0, t.k.toDouble()));
                    }

                    final n = _statsForChannel(
                      channel: NpkChannel.n,
                      live: live,
                      series: nSeries,
                      trendPct: _trendPctFromSeries(nSeries),
                    );
                    final p = _statsForChannel(
                      channel: NpkChannel.p,
                      live: live,
                      series: pSeries,
                      trendPct: _trendPctFromSeries(pSeries),
                    );
                    final k = _statsForChannel(
                      channel: NpkChannel.k,
                      live: live,
                      series: kSeries,
                      trendPct: _trendPctFromSeries(kSeries),
                    );

                    final String stageLabel = isPlanted
                        ? 'Etapa: ${runtime.stageLabel}'
                        : isPlanned
                        ? 'Pre-siembra'
                        : isGuide
                        ? 'Guía general'
                        : 'Modo genérico';

                    final _NpkContext ctx = _NpkContext(
                      isPlanted: isPlanted,
                      isPlanned: isPlanned,
                      isGuide: isGuide,
                      stageLabel: stageLabel,
                      decision: decision,
                    );

                    return Column(
                      children: [
                        _NutritionDecisionCard(ctx: ctx),
                        const SizedBox(height: 10),
                        const _NpkTabsCard(),
                        const SizedBox(height: 10),
                        Expanded(
                          child: _NpkContentCardShell(
                            child: TabBarView(
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _NpkTabContent(
                                  channel: NpkChannel.n,
                                  title: 'Nitrógeno',
                                  stats: n,
                                  statusLabel: _trendLabel(
                                    n.avgTrendPct,
                                    hasLive: n.hasLive,
                                  ),
                                  ctx: ctx,
                                  nutrient: _metricKeyFor(NpkChannel.n),
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.p,
                                  title: 'Fósforo',
                                  stats: p,
                                  statusLabel: _trendLabel(
                                    p.avgTrendPct,
                                    hasLive: p.hasLive,
                                  ),
                                  ctx: ctx,
                                  nutrient: _metricKeyFor(NpkChannel.p),
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.k,
                                  title: 'Potasio',
                                  stats: k,
                                  statusLabel: _trendLabel(
                                    k.avgTrendPct,
                                    hasLive: k.hasLive,
                                  ),
                                  ctx: ctx,
                                  nutrient: _metricKeyFor(NpkChannel.k),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12 + bottomPad),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contexto compartido por la cabecera y las tres pestañas.
class _NpkContext {
  const _NpkContext({
    required this.isPlanted,
    required this.isPlanned,
    required this.isGuide,
    required this.stageLabel,
    required this.decision,
  });

  final bool isPlanted;
  final bool isPlanned;
  final bool isGuide;
  final String stageLabel;
  final NutritionDecision? decision;

  NutrientStagePriority? priorityFor(AgroMetricKey nutrient) {
    final d = decision;
    if (d == null) return null;
    for (final NutrientStagePriority p in d.priorities) {
      if (p.nutrient == nutrient) return p;
    }
    return null;
  }

  /// Recomendación vigente si es para este nutriente.
  NutritionRecommendation? recommendationFor(AgroMetricKey nutrient) {
    final rec = decision?.recommendation;
    if (rec == null || rec.nutrient != nutrient) return null;
    return rec;
  }
}

class _NpkStats {
  final bool hasLive;
  final int level;
  final int? avg7;
  final int? rangeMin;
  final int? rangeMax;
  final double? avgTrendPct;
  final double gaugePercent;

  /// Escala del sitio (máximo reciente × 1.15).
  final double scale;

  const _NpkStats({
    required this.hasLive,
    required this.level,
    required this.avg7,
    required this.rangeMin,
    required this.rangeMax,
    required this.avgTrendPct,
    required this.gaugePercent,
    required this.scale,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA: LA DECISIÓN
// ═══════════════════════════════════════════════════════════════════════════

class _NutritionDecisionCard extends StatelessWidget {
  const _NutritionDecisionCard({required this.ctx});

  final _NpkContext ctx;

  static const Color _green = Color(0xFF2E7D5A);
  static const Color _amber = Color(0xFFB38A2E);
  static const Color _red = Color(0xFFC0533F);
  static const Color _slate = Color(0xFF5F6F69);

  Color _accent(NutritionDecision? d) {
    if (d == null) return _slate;
    if (d.recentlyUnattendedWindow != null) return _red;
    return switch (d.state) {
      NutritionState.actionWindow => _amber,
      NutritionState.prepare => _amber,
      NutritionState.responseWindow => _green,
      NutritionState.monitor => _green,
      NutritionState.learning => _slate,
    };
  }

  ({String tag, String headline, String detail}) _copy() {
    final d = ctx.decision;
    if (d != null) {
      return (tag: d.state.tagEs, headline: d.headlineEs, detail: d.detailEs);
    }
    if (ctx.isGuide) {
      return (
        tag: 'Guía',
        headline: 'Nutrición sin interpretar',
        detail:
            'Sin saber qué cultivo es ni en qué etapa va no hay ventana de N, '
            'P o K que abrir. Las señales de abajo se muestran como tendencia.',
      );
    }
    if (ctx.isPlanned) {
      return (
        tag: 'Pre-siembra',
        headline: 'La nutrición se evalúa al sembrar',
        detail:
            'Cuando registres la siembra, BIO-G abrirá las ventanas de manejo '
            'según la etapa y observará la respuesta del suelo.',
      );
    }
    if (ctx.isPlanted) {
      return (
        tag: '—',
        headline: 'Sin evaluación nutricional todavía',
        detail:
            'El Panel calcula la decisión de nutrición con la etapa y el '
            'historial. Vuelve al Panel un momento y regresa.',
      );
    }
    return (
      tag: 'Genérico',
      headline: 'Asigna un cultivo para ver la nutrición',
      detail:
          'Sin cultivo no hay etapa, y sin etapa no hay ventana de manejo. Las '
          'señales nativas N/P/K se muestran como tendencia.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = ctx.decision;
    final accent = _accent(d);
    final copy = _copy();
    final List<String> chips = <String>[
      if (d != null && d.window != null)
        'Ventana ${d.window!.nutrientsLabelEs}: ${_outcomeShort(d.window!)}',
      if (d != null && d.unattendedCriticalWindows > 0)
        '${d.unattendedCriticalWindows} sin evidencia este ciclo',
      if (d != null && d.isLearningSite)
        'Aprendiendo la zona${d.learningDaysLeft == null ? '' : ' · ${d.learningDaysLeft} d'}',
      if (d != null && d.hasDetectedSignature)
        'Firma detectada · confianza ${d.signature!.confidenceLabelEs}',
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: d == null ? null : () => _NutritionDetailSheet.show(context, d),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 22,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: accent.withValues(alpha: 0.12),
              blurRadius: 60,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.86),
                border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        margin: const EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.45),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          copy.headline,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                            color: Color(0xFF0E1A16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Pill(text: copy.tag, color: accent),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    copy.detail,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.6,
                      fontWeight: FontWeight.w600,
                      height: 1.32,
                      color: Colors.black.withValues(alpha: 0.64),
                    ),
                  ),
                  if (chips.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final String c in chips)
                          _Pill(text: c, color: accent, subtle: true),
                      ],
                    ),
                  ],
                  if (d != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Ver por qué y evidencia',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: accent.withValues(alpha: 0.9),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 16, color: accent),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _outcomeShort(NutritionWindowRecord w) => switch (w.outcome) {
    NutritionWindowOutcome.open => 'observando',
    NutritionWindowOutcome.attendedDetected => 'atendida',
    NutritionWindowOutcome.unattended => 'sin evidencia',
    NutritionWindowOutcome.inconclusive => 'inconclusa',
    NutritionWindowOutcome.notComparable => 'no comparable',
  };
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, this.subtle = false});

  final String text;
  final Color color;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: subtle ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: subtle ? 0.14 : 0.20)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: subtle ? 10.8 : 11.2,
          fontWeight: FontWeight.w900,
          color: color.withValues(alpha: subtle ? 0.85 : 1.0),
        ),
      ),
    );
  }
}

/// Hoja con el detalle completo de la decisión: razones, evidencia de la
/// firma, condiciones, libro de ventanas del ciclo y limitaciones.
class _NutritionDetailSheet extends StatelessWidget {
  const _NutritionDetailSheet({required this.decision});

  final NutritionDecision decision;

  static Future<void> show(BuildContext context, NutritionDecision d) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NutritionDetailSheet(decision: d),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = decision;
    final NutritionResponseEvaluation? response = d.response;
    final NutritionRecommendation? rec = d.recommendation;

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF6FAF8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                d.headlineEs,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A16),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                d.detailEs,
                style: TextStyle(
                  fontSize: 13.2,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: Colors.black.withValues(alpha: 0.68),
                ),
              ),
              _Section(
                title: 'Prioridad de la etapa',
                lines: [
                  for (final NutrientStagePriority p in d.priorities)
                    '${p.labelEs}: ${p.priority.labelEs.toLowerCase()}'
                        '${p.isCriticalWindow ? ' · ventana importante' : ''} — '
                        '${p.windowLabelEs}',
                ],
              ),
              if (rec != null)
                _Section(
                  title: 'Recomendación',
                  lines: [
                    rec.headlineEs,
                    if (rec.doseRange != null)
                      'Rango orientativo: ${rec.doseRange!.labelEs}'
                          '${rec.doseRange!.commercialEquivalentEs == null ? '' : ' (${rec.doseRange!.commercialEquivalentEs})'}',
                    if (rec.doseRange?.transparencyEs != null)
                      rec.doseRange!.transparencyEs!,
                    if (rec.doseUnavailableReasonEs != null)
                      rec.doseUnavailableReasonEs!,
                    if (rec.timingEs != null) 'Momento: ${rec.timingEs}',
                    if (rec.sourceOptionsEs.isNotEmpty)
                      'Fuentes: ${rec.sourceOptionsEs.join(' · ')}',
                    ...rec.rulesEs,
                  ],
                ),
              if (response != null)
                _Section(
                  title: 'Respuesta del suelo',
                  lines: [response.summaryEs, ...response.evidenceEs],
                )
              else if (d.window?.signature != null)
                _Section(
                  title: 'Cambio en observación',
                  lines: d.window!.signature!.evidenceEs,
                ),
              if (d.conditions.blockersEs.isNotEmpty ||
                  d.conditions.cautionsEs.isNotEmpty)
                _Section(
                  title: 'Condiciones del suelo',
                  lines: [...d.conditions.blockersEs, ...d.conditions.cautionsEs],
                ),
              if (d.seasonWindows.isNotEmpty)
                _Section(
                  title: 'Ventanas de este ciclo',
                  lines: [
                    for (final NutritionWindowRecord w in d.seasonWindows)
                      '«${w.stageLabelEs}» (${w.nutrientsLabelEs}): '
                          '${w.outcome.labelEs.toLowerCase()}'
                          '${w.signature != null && w.signature!.isCompatible ? ' · confianza ${w.signature!.confidenceLabelEs}' : ''}'
                          '${w.penalizes ? ' · pesa en el score' : ''}',
                  ],
                ),
              _Section(title: 'Por qué', lines: d.reasons),
              if (d.limitations.isNotEmpty)
                _Section(title: 'Qué no se pudo saber', lines: d.limitations),
              const SizedBox(height: 10),
              Text(
                '${d.guideAudit.labelEs} · motor ${d.engineVersion} · '
                'evaluado ${_fmtDateTime(d.decidedAt)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                kNativeSignalNoteEs,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: Colors.black.withValues(alpha: 0.42),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _fmtDateTime(DateTime d) {
    final String dd = d.day.toString().padLeft(2, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mi';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final List<String> clean =
        lines.map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (clean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2E7D5A),
            ),
          ),
          const SizedBox(height: 6),
          for (final String line in clean)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: TextStyle(
                        fontSize: 12.6,
                        height: 1.32,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PESTAÑAS
// ═══════════════════════════════════════════════════════════════════════════

class _NpkTabsCard extends StatelessWidget {
  const _NpkTabsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF3FAF6E).withValues(alpha: 0.12),
            blurRadius: 70,
            offset: const Offset(0, 34),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.78),
              border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(
                0xFF0E1A16,
              ).withValues(alpha: 0.60),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF40BB5F),
                    Color(0xFF3FAF6E),
                    Color.fromARGB(137, 43, 126, 101),
                  ],
                ),
              ),
              tabs: const [
                Tab(text: 'Nitrógeno'),
                Tab(text: 'Fósforo'),
                Tab(text: 'Potasio'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NpkContentCardShell extends StatelessWidget {
  final Widget child;
  const _NpkContentCardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 34,
            offset: const Offset(0, 18),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF3FAF6E).withValues(alpha: 0.12),
            blurRadius: 90,
            offset: const Offset(0, 46),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.86),
              border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NpkTabContent extends StatelessWidget {
  const _NpkTabContent({
    required this.channel,
    required this.title,
    required this.stats,
    required this.statusLabel,
    required this.ctx,
    required this.nutrient,
  });

  final NpkChannel channel;
  final String title;
  final _NpkStats stats;
  final String statusLabel;
  final _NpkContext ctx;
  final AgroMetricKey nutrient;

  Color _accent() => switch (channel) {
    NpkChannel.n => const Color(0xFFB38A2E),
    NpkChannel.p => const Color(0xFF2FAF63),
    NpkChannel.k => const Color(0xFF2B7EBB),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final NutrientStagePriority? priority = ctx.priorityFor(nutrient);
    final NutritionRecommendation? rec = ctx.recommendationFor(nutrient);
    final NutritionDecision? d = ctx.decision;
    final String nutrientName = nutrient.labelEs.toLowerCase();

    // Pill de etapa: la prioridad fenológica, nunca la lectura.
    final String insight;
    final InsightTone tone;
    if (priority != null) {
      insight = priority.isCriticalWindow
          ? 'Prioridad ${priority.priority.labelEs.toLowerCase()} · ventana importante'
          : 'Prioridad ${priority.priority.labelEs.toLowerCase()} en esta etapa';
      tone = priority.priority == NutritionPriority.high
          ? InsightTone.warn
          : InsightTone.ok;
    } else if (ctx.isPlanned) {
      insight = 'Prioridad disponible al sembrar';
      tone = InsightTone.ok;
    } else if (ctx.isGuide) {
      insight = 'Sin cultivo declarado: sin prioridad';
      tone = InsightTone.ok;
    } else {
      insight = 'Sin evaluación de etapa';
      tone = InsightTone.ok;
    }

    final String windowLine = priority != null
        ? 'Ventana: ${priority.windowLabelEs}'
        : ctx.isPlanned
        ? 'Ventana: se abre con la etapa, después de sembrar'
        : 'Ventana: sin cultivo no hay ventana';

    // Acción: la recomendación si es para este nutriente; si no, el porqué de
    // la prioridad. Nunca «aplica X por la lectura».
    final String action;
    if (rec != null) {
      action = rec.headlineEs;
    } else if (d != null && d.state == NutritionState.responseWindow) {
      action = 'Respuesta compatible con fertilización detectada. Estoy '
          'observando la respuesta del suelo; no hace falta que registres nada.';
    } else if (priority != null) {
      action = priority.priority == NutritionPriority.high
          ? 'La etapa demanda $nutrientName; la ventana la lleva la tarjeta de arriba.'
          : 'Sin ventana de aplicación de $nutrientName en esta etapa.';
    } else if (ctx.isPlanned) {
      action = 'Úsalo como línea base antes de sembrar.';
    } else {
      action = 'Configura un cultivo para ver la prioridad nutricional.';
    }

    final String? dose = rec?.doseRange?.labelEs;
    final String? doseNote = rec?.doseRange?.commercialEquivalentEs ??
        rec?.doseUnavailableReasonEs;

    final String description = priority?.rationaleEs.trim().isNotEmpty == true
        ? priority!.rationaleEs.trim()
        : ctx.isPlanned
        ? 'Señal nativa de $nutrientName en pre-siembra: sirve como referencia '
              'del punto antes de arrancar el ciclo.'
        : 'Señal nativa de $nutrientName. Asigna un cultivo para que la etapa '
              'diga cuándo importa.';

    final String trendText = _trendSentence(stats, nutrientName);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.60),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 286,
                        child: NpkGaugeCard(
                          channel: channel,
                          percent: stats.gaugePercent,
                          title: '$title · señal nativa',
                          description: description,
                          showDescription: false,
                          // Sin objetivo: la sonda no sostiene «bajo/alto».
                          targetMin: null,
                          targetMax: null,
                          statusLabel: statusLabel,
                          centerValue: stats.level,
                          centerUnit: stats.hasLive ? 'nativo' : '—',
                          cropCapPpm: stats.scale,
                        ),
                      ),
                      const SizedBox(height: 2),
                      _TechWaveScanDivider(accent: accent),
                      const SizedBox(height: 8),
                      _StageInsightPill(
                        accent: accent,
                        headline: insight,
                        stageLabel: ctx.stageLabel,
                        tone: tone,
                      ),
                      const SizedBox(height: 6),
                      _WindowLine(accent: accent, text: windowLine),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Column(
                          children: [
                            Text(
                              action,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.2,
                                fontWeight: FontWeight.w900,
                                height: 1.28,
                                color: Colors.black.withValues(alpha: 0.68),
                              ),
                            ),
                            if (dose != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Rango orientativo: $dose',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w900,
                                  height: 1.24,
                                  color: accent.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                            if ((doseNote ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                doseNote!.trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w800,
                                  height: 1.20,
                                  color: Colors.black.withValues(alpha: 0.54),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              description,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w700,
                                height: 1.30,
                                color: Colors.black.withValues(alpha: 0.58),
                              ),
                            ),
                            if (trendText.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                trendText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w700,
                                  height: 1.28,
                                  color: Colors.black.withValues(alpha: 0.50),
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              kNativeSignalNoteEs,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w700,
                                height: 1.28,
                                color: Colors.black.withValues(alpha: 0.40),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniMetric(
                          accent: accent,
                          value: stats.hasLive ? '${stats.level}' : '--',
                          unit: 'nativo',
                          label: 'Ahora',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 46,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      Expanded(
                        child: _MiniMetric(
                          accent: accent,
                          value: stats.avg7 == null ? '--' : '${stats.avg7}',
                          unit: 'nativo',
                          label: 'Promedio 7 días',
                          trendPct: stats.avgTrendPct,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 46,
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                      Expanded(
                        child: _MiniMetric(
                          accent: accent,
                          value: stats.rangeMin == null || stats.rangeMax == null
                              ? '--'
                              : '${stats.rangeMin}–${stats.rangeMax}',
                          unit: 'nativo',
                          label: 'Variación 7 días',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  static String _trendSentence(_NpkStats s, String nutrientName) {
    if (s.rangeMin == null || s.rangeMax == null) return '';
    final String trend = s.avgTrendPct == null
        ? ''
        : ' (tendencia ${s.avgTrendPct! >= 0 ? '+' : ''}${s.avgTrendPct!.toStringAsFixed(1)} %)';
    return 'En 7 días la señal nativa de $nutrientName se movió entre '
        '${s.rangeMin} y ${s.rangeMax}$trend. Un salto sostenido junto con la '
        'CE es lo que BIO-G lee como respuesta a una fertilización.';
  }
}

class _StageInsightPill extends StatelessWidget {
  final Color accent;
  final String headline;
  final String stageLabel;
  final InsightTone tone;

  const _StageInsightPill({
    required this.accent,
    required this.headline,
    required this.stageLabel,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final bg = tone == InsightTone.bad
        ? Colors.black.withValues(alpha: 0.06)
        : tone == InsightTone.warn
        ? accent.withValues(alpha: 0.10)
        : accent.withValues(alpha: 0.08);
    final dot = tone == InsightTone.bad
        ? Colors.black.withValues(alpha: 0.45)
        : tone == InsightTone.warn
        ? accent.withValues(alpha: 0.95)
        : accent.withValues(alpha: 0.90);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bg,
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dot,
              boxShadow: [
                BoxShadow(
                  color: dot.withValues(alpha: 0.45),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              headline,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
                height: 1.15,
                color: Colors.black.withValues(alpha: 0.62),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (stageLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.55),
                border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
              ),
              child: Text(
                stageLabel,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Línea de ventana fisiológica. Sustituye a la antigua línea de «objetivo
/// N–M mg/kg»: aquí no hay objetivo sobre la lectura, hay una ventana de la
/// etapa.
class _WindowLine extends StatelessWidget {
  const _WindowLine({required this.accent, required this.text});

  final Color accent;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Icons.timeline_rounded,
              size: 16,
              color: accent.withValues(alpha: 0.70),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TechWaveScanDivider extends StatefulWidget {
  final Color accent;
  const _TechWaveScanDivider({required this.accent});

  @override
  State<_TechWaveScanDivider> createState() => _TechWaveScanDividerState();
}

class _TechWaveScanDividerState extends State<_TechWaveScanDivider>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      width: double.infinity,
      // O2 · Frontera de repintado: el controlador hace `repeat()` y sin ella
      // el gauge se repintaba 60 veces por segundo.
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(
            painter: _TechWaveScanPainter(t: _c.value, accent: widget.accent),
          ),
        ),
      ),
    );
  }
}

class _TechWaveScanPainter extends CustomPainter {
  final double t;
  final Color accent;
  _TechWaveScanPainter({required this.t, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final amp = 7.2;
    final freq = 2.0;
    final phase = t * math.pi * 2;

    final path = Path();
    for (int i = 0; i <= 160; i++) {
      final x = w * (i / 160);
      final y = midY + math.sin((x / w) * (math.pi * 2 * freq) + phase) * amp;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30)
      ..color = accent.withValues(alpha: 0.70);
    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha: 0.96);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, core);
  }

  @override
  bool shouldRepaint(covariant _TechWaveScanPainter old) =>
      old.t != t || old.accent != accent;
}

class _MiniMetric extends StatelessWidget {
  final Color accent;
  final String value;
  final String unit;
  final String label;
  final double? trendPct;

  const _MiniMetric({
    required this.accent,
    required this.value,
    required this.unit,
    required this.label,
    this.trendPct,
  });

  static const Color _trendUp = Color(0xFF2FAF63);
  static const Color _trendDown = Color(0xFFE55B5B);

  @override
  Widget build(BuildContext context) {
    final hasTrend = trendPct != null;
    final up = (trendPct ?? 0) >= 0;
    final trendColor = up ? _trendUp : _trendDown;

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF0E1A16),
              fontWeight: FontWeight.w900,
              fontSize: 21,
              height: 1.0,
            ),
            children: [
              TextSpan(text: value),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.0,
                  color: Colors.black.withValues(alpha: 0.42),
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (hasTrend)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up
                    ? Icons.arrow_drop_up_rounded
                    : Icons.arrow_drop_down_rounded,
                size: 18,
                color: trendColor.withValues(alpha: 0.95),
              ),
              Text(
                '${up ? '+' : ''}${trendPct!.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: trendColor.withValues(alpha: 0.95),
                  height: 1.0,
                ),
              ),
            ],
          )
        else
          const SizedBox(height: 14),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10.8,
            fontWeight: FontWeight.w900,
            color: accent.withValues(alpha: 0.82),
            height: 1.05,
          ),
        ),
      ],
    );
  }
}

class _NpkSoftBackground extends StatelessWidget {
  const _NpkSoftBackground();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6FAF8), Color(0xFFEFF6F2), Color(0xFFF6FAF8)],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(size: 260, opacity: 0.18),
          ),
          Positioned(
            top: 160,
            right: -110,
            child: _GlowBlob(size: 300, opacity: 0.14),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowBlob(size: 340, opacity: 0.16),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final double opacity;
  const _GlowBlob({required this.size, required this.opacity});
  static const Color _brandMid = Color(0xFF3FAF6E);
  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _brandMid.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
