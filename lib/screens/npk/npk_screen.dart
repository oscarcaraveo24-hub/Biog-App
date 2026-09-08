// lib/screens/npk/npk_screen.dart
//
// PANTALLA DE NUTRICIÓN (Guía oficial del nuevo motor nutricional v0.4, §8,
// §9 y §17 «UI/UX»).
//
// Tres pestañas —Nitrógeno, Fósforo, Potasio— y en cada una UNA pantalla fija,
// sin scroll (decisión de producto, 6 sep 2026):
//   1. El dato crudo del sensor en mg/kg, como lo entrega la sonda 7-en-1
//      (registros N/P/K en mg/kg, 0–1999), con su tendencia en la escala del
//      propio sitio. Sin objetivo, sin «bajo/alto», sin dosis derivada.
//   2. Qué toca hacer con ESTE nutriente según el motor de nutrición
//      (`NutritionDecision`), en lenguaje de campo: «Aplica fósforo:
//      establecimiento» + la dosis orientativa de la guía + un resumen de
//      ≤ 50 palabras con el cuándo y el porqué (`NpkTabCopy`, en su propio
//      archivo para poder probarlo contra las 32 guías). Una sola autoridad;
//      aquí no se interpreta ninguna lectura.
//   3. Las cifras de la semana (ahora, promedio, variación) y un enlace al
//      detalle completo (por qué, evidencia, ventanas del ciclo).
//
// LO QUE YA NO EXISTE AQUÍ (y no debe volver): topes ppm por cultivo, rangos
// objetivo por etapa sobre la lectura, dosis calculadas desde la sonda,
// «Registrar aplicación», y copys técnicos en la pestaña (prioridad
// fenológica, firmas, «P» a secas): eso vive en la hoja de detalle.
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/screens/npk/npk_tab_copy.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/npk/npk_gauge_card.dart';

/// Renglón discreto junto a las señales N/P/K (Guía v0.4, §8). Vive en
/// `nutrition_types.dart` para que sea el mismo en toda la app.
const String kNativeSignalNoteEs = kNativeSignalDisclaimerEs;

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
    // La memoria nutricional (libro de ventanas, historial) se carga fuera
    // del frame; cuando termina, la cabecera debe repintarse.
    _boundStore?.nutrition.removeListener(_onNutritionChanged);
    store.nutrition.addListener(_onNutritionChanged);
    _boundStore = store;
    _boundTelemetryDeviceId = telemetryDeviceId;
    _history7dStream = store.watchHistory(const Duration(days: 7));
  }

  void _onNutritionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _boundStore?.nutrition.removeListener(_onNutritionChanged);
    super.dispose();
  }

  AgroMetricKey _metricKeyFor(NpkChannel ch) => switch (ch) {
    NpkChannel.n => AgroMetricKey.n,
    NpkChannel.p => AgroMetricKey.p,
    NpkChannel.k => AgroMetricKey.k,
  };

  int _roundInt(double v) => v.isNaN ? 0 : v.round();

  /// Tendencia con el MISMO cálculo que el motor de nutrición (últimas 48 h
  /// contra los días previos, medianas), para que Panel y pantalla digan lo
  /// mismo.
  NutrientTrend _trendFor(
    AgroMetricKey nutrient,
    List<({DateTime at, double value})> samples,
    DateTime now,
  ) => NutrientTrend.compute(nutrient: nutrient, samples: samples, now: now);

  /// La del motor si ya sabe algo; si no (memoria aún cargando), la que se
  /// calcula aquí con los 7 días de la pantalla.
  NutrientTrend _preferKnown(
    NutrientTrend? fromDecision,
    NutrientTrend Function() fallback,
  ) {
    if (fromDecision != null && fromDecision.trend.isKnown) return fromDecision;
    return fallback();
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
    required NutrientTrend trend,
  }) {
    final bool hasLive = live != null &&
        switch (channel) {
          NpkChannel.n => live.hasNitrogenData,
          NpkChannel.p => live.hasPhosphorusData,
          NpkChannel.k => live.hasPotassiumData,
        };
    // El analizador promueve `live` a través de `hasLive` (Dart 3.x).
    final double level = !hasLive
        ? double.nan
        : switch (channel) {
            NpkChannel.n => live.n.toDouble(),
            NpkChannel.p => live.p.toDouble(),
            NpkChannel.k => live.k.toDouble(),
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
      trend: trend,
      gaugePercent: gaugePercent,
      scale: scale,
    );
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

                    // La decisión sale del coordinador del store (pura y
                    // memoizada: segura en build); si aún no cargó su memoria,
                    // vale la última publicada. Si no hay ninguna, la pantalla
                    // lo dice.
                    final NutritionDecision? decision = isPlanted
                        ? (store.nutrition.decisionFor(runtime, now: now) ??
                              store.nutritionDecisionAt(now))
                        : null;

                    // Una sola ordenación del historial por build.
                    final sortedHistory = [...history7d]
                      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
                    final nSeries = <double>[];
                    final pSeries = <double>[];
                    final kSeries = <double>[];
                    final nSamples = <({DateTime at, double value})>[];
                    final pSamples = <({DateTime at, double value})>[];
                    final kSamples = <({DateTime at, double value})>[];
                    for (final t in sortedHistory) {
                      // Solo lo que la sonda midió: ausencia no es cero.
                      if (t.hasNitrogenData) {
                        final double v = math.max(0.0, t.n.toDouble());
                        nSeries.add(v);
                        nSamples.add((at: t.timestamp, value: v));
                      }
                      if (t.hasPhosphorusData) {
                        final double v = math.max(0.0, t.p.toDouble());
                        pSeries.add(v);
                        pSamples.add((at: t.timestamp, value: v));
                      }
                      if (t.hasPotassiumData) {
                        final double v = math.max(0.0, t.k.toDouble());
                        kSeries.add(v);
                        kSamples.add((at: t.timestamp, value: v));
                      }
                    }

                    // Si el motor ya calculó la tendencia, se reutiliza tal
                    // cual; si no (sin decisión vigente), se calcula igual.
                    final n = _statsForChannel(
                      channel: NpkChannel.n,
                      live: live,
                      series: nSeries,
                      trend: _preferKnown(
                        decision?.trendFor(AgroMetricKey.n),
                        () => _trendFor(AgroMetricKey.n, nSamples, now),
                      ),
                    );
                    final p = _statsForChannel(
                      channel: NpkChannel.p,
                      live: live,
                      series: pSeries,
                      trend: _preferKnown(
                        decision?.trendFor(AgroMetricKey.p),
                        () => _trendFor(AgroMetricKey.p, pSamples, now),
                      ),
                    );
                    final k = _statsForChannel(
                      channel: NpkChannel.k,
                      live: live,
                      series: kSeries,
                      trend: _preferKnown(
                        decision?.trendFor(AgroMetricKey.k),
                        () => _trendFor(AgroMetricKey.k, kSamples, now),
                      ),
                    );

                    final _NpkContext ctx = _NpkContext(
                      isPlanned: isPlanned,
                      isGuide: isGuide,
                      decision: decision,
                    );

                    // Arriba, las tres pestañas (como siempre); la decisión
                    // del motor vive dentro de cada pestaña, en lenguaje de
                    // campo, y su detalle completo en la hoja «Ver detalle».
                    return Column(
                      children: [
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
                                  ctx: ctx,
                                  nutrient: _metricKeyFor(NpkChannel.n),
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.p,
                                  title: 'Fósforo',
                                  stats: p,
                                  ctx: ctx,
                                  nutrient: _metricKeyFor(NpkChannel.p),
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.k,
                                  title: 'Potasio',
                                  stats: k,
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

/// Contexto compartido por las tres pestañas.
class _NpkContext {
  const _NpkContext({
    required this.isPlanned,
    required this.isGuide,
    required this.decision,
  });

  final bool isPlanned;
  final bool isGuide;
  final NutritionDecision? decision;
}

class _NpkStats {
  final bool hasLive;
  final int level;
  final int? avg7;
  final int? rangeMin;
  final int? rangeMax;

  /// Tendencia de 7 días con el vocabulario del motor.
  final NutrientTrend trend;
  final double gaugePercent;

  /// Escala del sitio (máximo reciente × 1.15).
  final double scale;

  const _NpkStats({
    required this.hasLive,
    required this.level,
    required this.avg7,
    required this.rangeMin,
    required this.rangeMax,
    required this.trend,
    required this.gaugePercent,
    required this.scale,
  });

  double? get avgTrendPct => trend.changePct;
}

// ═══════════════════════════════════════════════════════════════════════════
// CABECERA: LA DECISIÓN
// ═══════════════════════════════════════════════════════════════════════════

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
                    // Una línea por nutriente de la ventana, con su
                    // equivalente comercial y su condición si la tiene;
                    // después, los de acompañamiento.
                    for (final NutrientDose dose in rec.focusDoses)
                      'Dosis orientativa · ${dose.lineEs}',
                    for (final NutrientDose dose in rec.companionDoses)
                      'Acompaña con · ${dose.lineEs}',
                    for (final NutrientDose dose in rec.doses)
                      if (dose.range.transparencyEs != null)
                        dose.range.transparencyEs!,
                    if (rec.doses.isEmpty && rec.doseRange != null)
                      'Dosis orientativa · ${rec.doseRange!.labelEs}'
                          '${rec.doseRange!.commercialEquivalentEs == null ? '' : ' (${rec.doseRange!.commercialEquivalentEs})'}',
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
                      '«${w.displayLabelEs}» (${w.nutrientsLabelEs}): '
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
    required this.ctx,
    required this.nutrient,
  });

  final NpkChannel channel;
  final String title;
  final _NpkStats stats;
  final _NpkContext ctx;
  final AgroMetricKey nutrient;

  /// Unidad con la que la sonda 7-en-1 entrega N, P y K (registros Modbus
  /// 0x1E–0x20: 0–1999 mg/kg). Se muestra tal cual, sin convertir.
  static const String _unit = 'mg/kg';

  Color _accent() => switch (channel) {
    NpkChannel.n => const Color(0xFFB38A2E),
    NpkChannel.p => const Color(0xFF2FAF63),
    NpkChannel.k => const Color(0xFF2B7EBB),
  };

  @override
  Widget build(BuildContext context) {
    final accent = _accent();
    final NutritionDecision? d = ctx.decision;
    final NpkTabCopy copy = NpkTabCopy.build(
      nutrient: nutrient,
      decision: d,
      isGuide: ctx.isGuide,
      isPlanned: ctx.isPlanned,
      hasLive: stats.hasLive,
      trend: stats.trend,
    );
    final NpkTrendPill pill = NpkTrendPill.resolve(
      hasLive: stats.hasLive,
      trend: stats.trend,
      decision: d,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.60),
        border: Border.all(color: Colors.white.withValues(alpha: 0.70)),
      ),
      // Pantalla fija: el arco toma el alto que sobra después del bloque de
      // acción y de la fila de cifras (los dos con líneas acotadas), así que
      // nunca hay scroll ni desbordamiento; en un teléfono chico el arco se
      // hace más pequeño, no el texto.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: NpkGaugeCard(
              channel: channel,
              percent: stats.gaugePercent,
              title: title,
              description: '',
              showDescription: false,
              // Sin objetivo: la sonda no sostiene «bajo/alto».
              targetMin: null,
              targetMax: null,
              statusLabel: pill.label,
              statusColor: pill.color,
              centerValue: stats.level,
              centerUnit: stats.hasLive ? _unit : '—',
              scaleMax: stats.scale,
            ),
          ),
          Text(
            'Dato crudo del sensor',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.black.withValues(alpha: 0.38),
            ),
          ),
          const SizedBox(height: 4),
          _TechWaveScanDivider(accent: accent),
          const SizedBox(height: 8),
          _ActionBlock(
            accent: accent,
            copy: copy,
            onDetail: d == null
                ? null
                : () => _NutritionDetailSheet.show(context, d),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  accent: accent,
                  value: stats.hasLive ? '${stats.level}' : '--',
                  unit: _unit,
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
                  unit: _unit,
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
                  unit: _unit,
                  label: 'Variación 7 días',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// El bloque de acción de la pestaña: chip de importancia, titular, dosis y
/// resumen (≤ 50 palabras), con líneas acotadas para que la pantalla siga
/// fija, y un enlace discreto al detalle. El texto lo arma `NpkTabCopy`.
class _ActionBlock extends StatelessWidget {
  const _ActionBlock({
    required this.accent,
    required this.copy,
    required this.onDetail,
  });

  final Color accent;
  final NpkTabCopy copy;
  final VoidCallback? onDetail;

  Color _toneColor() => switch (copy.tone) {
    NpkTabTone.calm => Colors.black.withValues(alpha: 0.70),
    NpkTabTone.action => const Color(0xFF0E1A16),
    NpkTabTone.wait => const Color(0xFFB38A2E),
    NpkTabTone.good => const Color(0xFF2E7D5A),
  };

  @override
  Widget build(BuildContext context) {
    final String? importance = copy.importance;
    final String? dose = copy.dose;
    final String? summary = copy.summary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          if (importance != null && importance.trim().isNotEmpty) ...[
            _ImportanceChip(label: importance, accent: accent),
            const SizedBox(height: 6),
          ],
          Text(
            copy.headline,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.2,
              color: _toneColor(),
            ),
          ),
          if (dose != null && dose.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              dose,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.6,
                fontWeight: FontWeight.w900,
                height: 1.24,
                color: accent.withValues(alpha: 0.92),
              ),
            ),
          ],
          if (summary != null && summary.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              summary,
              textAlign: TextAlign.center,
              // 50 palabras caben en ~7 líneas a este cuerpo; el tope de
              // palabras vive en `NpkTabCopy.kMaxSummaryWords` y aquí solo
              // hay una red de seguridad para que la pantalla siga fija.
              maxLines: 7,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w700,
                height: 1.28,
                color: Colors.black.withValues(alpha: 0.60),
              ),
            ),
          ],
          if (onDetail != null) ...[
            const SizedBox(height: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onDetail,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ver detalle',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: accent.withValues(alpha: 0.9),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 16, color: accent),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// «Importante en establecimiento»: la ventana de este nutriente pesa en la
/// etapa. Chip pequeño en el color del nutriente, arriba del titular.
class _ImportanceChip extends StatelessWidget {
  const _ImportanceChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.priority_high_rounded, size: 12, color: accent),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
                color: accent,
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
          builder: (_, _) => CustomPaint(
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
