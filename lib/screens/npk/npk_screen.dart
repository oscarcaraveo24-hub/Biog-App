// lib/screens/npk/npk_screen.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/npk/npk_gauge_card.dart';

enum InsightTone { ok, warn, bad }

class NpkScreen extends StatelessWidget {
  const NpkScreen({super.key});

  int _roundInt(double v) => v.isNaN ? 0 : v.round();

  double? _trendPctFromSeries(List<double> series) {
    if (series.length < 6) return null;

    double avg(List<double> xs) =>
        xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;

    final a = avg(series.sublist(series.length - 3));
    final b = avg(series.sublist(series.length - 6, series.length - 3));

    if (b.abs() < 0.0001) return null;
    return ((a - b) / b) * 100.0;
  }

  double _ppmCap(NpkChannel ch) {
    switch (ch) {
      case NpkChannel.n:
        return 120.0;
      case NpkChannel.p:
        return 80.0;
      case NpkChannel.k:
        return 140.0;
    }
  }

  int _indexToPpm(NpkChannel ch, double index0to100) {
    final cap = _ppmCap(ch);
    final v = (index0to100.clamp(0.0, 100.0) / 100.0) * cap;
    return v.round();
  }

  double _ppmToGauge01(NpkChannel ch, double ppm) {
    if (!ppm.isFinite) return 0.0;
    final cap = _ppmCap(ch);
    return (ppm / cap).clamp(0.0, 1.0);
  }

  String _bandLabelEs(_NpkBand b) {
    switch (b) {
      case _NpkBand.low:
        return 'Bajo';
      case _NpkBand.optimal:
        return 'Óptimo';
      case _NpkBand.high:
        return 'Alto';
      case _NpkBand.critical:
        return 'Crítico';
      case _NpkBand.unknown:
        return '—';
    }
  }

  _NpkBand _bandFromPpmUsingIndexRange({
    required NpkChannel ch,
    required double ppm,
    required AgroRange indexRange,
  }) {
    final cap = _ppmCap(ch);

    double t(double idx) => (idx.clamp(0.0, 100.0) / 100.0) * cap;

    final lowMax = t(indexRange.lowMax);
    final optMin = t(indexRange.optimalMin);
    final optMax = t(indexRange.optimalMax);
    final highMin = t(indexRange.highMin);

    if (!ppm.isFinite) return _NpkBand.unknown;

    if (ppm < lowMax) return _NpkBand.critical;
    if (ppm < optMin) return _NpkBand.low;
    if (ppm <= optMax) return _NpkBand.optimal;
    if (ppm <= highMin) return _NpkBand.high;
    return _NpkBand.critical;
  }

  int _ppmToPctForPainter({required NpkChannel ch, required int ppm}) {
    final cap = _ppmCap(ch);
    final pct = (ppm / cap) * 100.0;
    return pct.round().clamp(0, 100);
  }

  _NpkStats _statsForChannel({
    required NpkChannel channel,
    required BioGTelemetry? live,
    required List<BioGTelemetry> history7d,
    required StageTargets? targets,
    required bool allowStageInterpretation,
  }) {
    double read(BioGTelemetry t) {
      return switch (channel) {
        NpkChannel.n => t.n.toDouble(),
        NpkChannel.p => t.p.toDouble(),
        NpkChannel.k => t.k.toDouble(),
      };
    }

    final level = live == null ? 0.0 : read(live);

    final sorted = [...history7d]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final series = sorted.map(read).map((v) => v < 0 ? 0.0 : v).toList();

    final avg7 = series.isEmpty
        ? 0.0
        : series.reduce((a, b) => a + b) / series.length;

    final minV = series.isEmpty ? 0.0 : series.reduce(math.min);
    final maxV = series.isEmpty ? 0.0 : series.reduce(math.max);

    final trendPct = _trendPctFromSeries(series);
    final gaugePercent = _ppmToGauge01(channel, level);

    final rIndex = (!allowStageInterpretation || targets == null)
        ? null
        : switch (channel) {
            NpkChannel.n => targets.nIndex,
            NpkChannel.p => targets.pIndex,
            NpkChannel.k => targets.kIndex,
          };

    final targetMinPpm = (rIndex == null)
        ? 0
        : _indexToPpm(channel, rIndex.optimalMin);

    final targetMaxPpm = (rIndex == null)
        ? 0
        : _indexToPpm(channel, rIndex.optimalMax);

    final capPpm = (rIndex == null)
        ? _ppmCap(channel).round()
        : _indexToPpm(channel, rIndex.highMin);

    final band = (rIndex == null)
        ? _NpkBand.unknown
        : _bandFromPpmUsingIndexRange(
            ch: channel,
            ppm: level,
            indexRange: rIndex,
          );

    final bandLabel = _bandLabelEs(band);

    final targetMinPctPainter = _ppmToPctForPainter(
      ch: channel,
      ppm: targetMinPpm,
    );
    final targetMaxPctPainter = _ppmToPctForPainter(
      ch: channel,
      ppm: targetMaxPpm,
    );

    return _NpkStats(
      levelPpm: _roundInt(level),
      avg7Ppm: _roundInt(avg7),
      rangeMin: _roundInt(minV),
      rangeMax: _roundInt(maxV),
      avgTrendPct: trendPct,
      gaugePercent: gaugePercent,
      capPpm: capPpm,
      targetMinPpm: targetMinPpm,
      targetMaxPpm: targetMaxPpm,
      targetMinPctPainter: targetMinPctPainter,
      targetMaxPctPainter: targetMaxPctPainter,
      band: band,
      bandLabel: bandLabel,
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
              color: Colors.black.withValues(alpha:0.65),
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
                child: Column(
                  children: [
                    const _NpkTabsCard(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<List<BioGTelemetry>>(
                        stream: store.watchHistory(const Duration(days: 7)),
                        builder: (context, snap) {
                          final history7d =
                              snap.data ?? const <BioGTelemetry>[];
                          final live = store.live;
                          final device = store.activeDevice;
                          final DeviceCropContext? cropContext =
                              store.activeCropContext;
                          final seed = store.activeSeed;

                          final runtime = CropRuntimeResolver.resolve(
                            device: device,
                            seed: seed,
                            cropContext: cropContext,
                            live: live,
                            alertsState: store.alertsState,
                            now: DateTime.now(),
                          );

                          final isPlanted = runtime.isPlanted;
                          final isPlanned = runtime.isPlanned;
                          final targets = runtime.targets;

                          final n = _statsForChannel(
                            channel: NpkChannel.n,
                            live: live,
                            history7d: history7d,
                            targets: targets,
                            allowStageInterpretation: isPlanted,
                          );

                          final p = _statsForChannel(
                            channel: NpkChannel.p,
                            live: live,
                            history7d: history7d,
                            targets: targets,
                            allowStageInterpretation: isPlanted,
                          );

                          final k = _statsForChannel(
                            channel: NpkChannel.k,
                            live: live,
                            history7d: history7d,
                            targets: targets,
                            allowStageInterpretation: isPlanted,
                          );

                          final stageLabel = isPlanted
                              ? 'Etapa: ${runtime.stageLabel}'
                              : isPlanned
                              ? 'Pre-siembra'
                              : 'Modo genérico';

                          final insightN = isPlanted
                              ? 'En esta etapa conviene ajustar N para sostener vigor.'
                              : isPlanned
                              ? 'Lectura general de N antes de siembra.'
                              : 'Lectura disponible sin cultivo asignado.';

                          final insightP = isPlanted
                              ? 'Mantén P disponible para raíz y energía.'
                              : isPlanned
                              ? 'Lectura general de P antes de siembra.'
                              : 'Lectura disponible sin cultivo asignado.';

                          final insightK = isPlanted
                              ? 'K estable ayuda mucho contra estrés hídrico.'
                              : isPlanned
                              ? 'Lectura general de K antes de siembra.'
                              : 'Lectura disponible sin cultivo asignado.';

                          final descN = isPlanted
                              ? 'El nitrógeno es esencial para el crecimiento vegetativo y el desarrollo del follaje. Una deficiencia puede causar hojas amarillentas y bajo vigor.'
                              : 'Lectura actual de nitrógeno del suelo. Asigna un cultivo para comparar contra objetivos por etapa.';

                          final descP = isPlanted
                              ? 'El fósforo favorece el desarrollo de raíces y la energía de la planta. En etapas tempranas es clave para un arranque fuerte.'
                              : 'Lectura actual de fósforo del suelo. Asigna un cultivo para comparar contra objetivos por etapa.';

                          final descK = isPlanted
                              ? 'El potasio ayuda a regular el balance hídrico, la resistencia al estrés y la calidad del cultivo. Un nivel estable mejora tolerancia a sequía.'
                              : 'Lectura actual de potasio del suelo. Asigna un cultivo para comparar contra objetivos por etapa.';

                          final statusN = isPlanted ? n.bandLabel : 'General';
                          final statusP = isPlanted ? p.bandLabel : 'General';
                          final statusK = isPlanted ? k.bandLabel : 'General';

                          return _NpkContentCardShell(
                            child: TabBarView(
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _NpkTabContent(
                                  channel: NpkChannel.n,
                                  percent: n.gaugePercent,
                                  title: 'Nitrógeno',
                                  description: descN,
                                  stageLabel: stageLabel,
                                  insight: insightN,
                                  tone: isPlanted
                                      ? InsightTone.warn
                                      : InsightTone.ok,
                                  targetMinPctPainter: n.targetMinPctPainter,
                                  targetMaxPctPainter: n.targetMaxPctPainter,
                                  targetMinPpm: n.targetMinPpm,
                                  targetMaxPpm: n.targetMaxPpm,
                                  levelPpm: n.levelPpm,
                                  avg7Ppm: n.avg7Ppm,
                                  rangeMin: n.rangeMin,
                                  rangeMax: n.rangeMax,
                                  avgTrendPct: n.avgTrendPct,
                                  statusLabel: statusN,
                                  showStageTargets: isPlanted,
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.p,
                                  percent: p.gaugePercent,
                                  title: 'Fósforo',
                                  description: descP,
                                  stageLabel: stageLabel,
                                  insight: insightP,
                                  tone: InsightTone.ok,
                                  targetMinPctPainter: p.targetMinPctPainter,
                                  targetMaxPctPainter: p.targetMaxPctPainter,
                                  targetMinPpm: p.targetMinPpm,
                                  targetMaxPpm: p.targetMaxPpm,
                                  levelPpm: p.levelPpm,
                                  avg7Ppm: p.avg7Ppm,
                                  rangeMin: p.rangeMin,
                                  rangeMax: p.rangeMax,
                                  avgTrendPct: p.avgTrendPct,
                                  statusLabel: statusP,
                                  showStageTargets: isPlanted,
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.k,
                                  percent: k.gaugePercent,
                                  title: 'Potasio',
                                  description: descK,
                                  stageLabel: stageLabel,
                                  insight: insightK,
                                  tone: InsightTone.ok,
                                  targetMinPctPainter: k.targetMinPctPainter,
                                  targetMaxPctPainter: k.targetMaxPctPainter,
                                  targetMinPpm: k.targetMinPpm,
                                  targetMaxPpm: k.targetMaxPpm,
                                  levelPpm: k.levelPpm,
                                  avg7Ppm: k.avg7Ppm,
                                  rangeMin: k.rangeMin,
                                  rangeMax: k.rangeMax,
                                  avgTrendPct: k.avgTrendPct,
                                  statusLabel: statusK,
                                  showStageTargets: isPlanted,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 12 + bottomPad),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _NpkBand { low, optimal, high, critical, unknown }

class _NpkStats {
  final int levelPpm;
  final int avg7Ppm;
  final int rangeMin;
  final int rangeMax;
  final double? avgTrendPct;
  final double gaugePercent;
  final int capPpm;
  final int targetMinPpm;
  final int targetMaxPpm;
  final int targetMinPctPainter;
  final int targetMaxPctPainter;
  final _NpkBand band;
  final String bandLabel;

  const _NpkStats({
    required this.levelPpm,
    required this.avg7Ppm,
    required this.rangeMin,
    required this.rangeMax,
    required this.avgTrendPct,
    required this.gaugePercent,
    required this.capPpm,
    required this.targetMinPpm,
    required this.targetMaxPpm,
    required this.targetMinPctPainter,
    required this.targetMaxPctPainter,
    required this.band,
    required this.bandLabel,
  });
}

class _NpkTabsCard extends StatelessWidget {
  const _NpkTabsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.10),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF3FAF6E).withValues(alpha:0.12),
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
              color: Colors.white.withValues(alpha:0.78),
              border: Border.all(color: Colors.white.withValues(alpha:0.92)),
            ),
            child: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF0E1A16).withValues(alpha:0.60),
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
            color: Colors.black.withValues(alpha:0.10),
            blurRadius: 34,
            offset: const Offset(0, 18),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: const Color(0xFF3FAF6E).withValues(alpha:0.12),
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
              color: Colors.white.withValues(alpha:0.86),
              border: Border.all(color: Colors.white.withValues(alpha:0.92)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _NpkTabContent extends StatelessWidget {
  final NpkChannel channel;
  final String title;
  final double percent;
  final String description;
  final String stageLabel;
  final String insight;
  final InsightTone tone;
  final int targetMinPctPainter;
  final int targetMaxPctPainter;
  final int targetMinPpm;
  final int targetMaxPpm;
  final int levelPpm;
  final int avg7Ppm;
  final int rangeMin;
  final int rangeMax;
  final double? avgTrendPct;
  final String statusLabel;
  final bool showStageTargets;

  const _NpkTabContent({
    required this.channel,
    required this.title,
    required this.percent,
    required this.description,
    required this.stageLabel,
    required this.insight,
    required this.tone,
    required this.targetMinPctPainter,
    required this.targetMaxPctPainter,
    required this.targetMinPpm,
    required this.targetMaxPpm,
    required this.levelPpm,
    required this.avg7Ppm,
    required this.rangeMin,
    required this.rangeMax,
    required this.statusLabel,
    required this.showStageTargets,
    this.avgTrendPct,
  });

  Color _accent() {
    switch (channel) {
      case NpkChannel.n:
        return const Color(0xFFB38A2E);
      case NpkChannel.p:
        return const Color(0xFF2FAF63);
      case NpkChannel.k:
        return const Color(0xFF2B7EBB);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha:0.60),
        border: Border.all(color: Colors.white.withValues(alpha:0.70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 300,
            child: NpkGaugeCard(
              channel: channel,
              percent: percent,
              title: title,
              description: description,
              showDescription: false,
              targetMin: targetMinPctPainter,
              targetMax: targetMaxPctPainter,
              statusLabel: statusLabel,
              centerValue: levelPpm,
              centerUnit: 'ppm',
            ),
          ),
          const SizedBox(height: 0),
          _TechWaveScanDivider(accent: accent),
          const SizedBox(height: 10),
          _StageInsightPill(
            accent: accent,
            headline: insight,
            stageLabel: stageLabel,
            tone: tone,
          ),
          const SizedBox(height: 8),
          _TargetLinePpm(
            accent: accent,
            minPpm: targetMinPpm,
            maxPpm: targetMaxPpm,
            showTargets: showStageTargets,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 25),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.30,
                    color: Colors.black.withValues(alpha:0.60),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  accent: accent,
                  value: '$levelPpm',
                  unit: 'ppm',
                  label: 'Nivel',
                ),
              ),
              Container(
                width: 1,
                height: 46,
                color: Colors.black.withValues(alpha:0.06),
              ),
              Expanded(
                child: _MiniMetric(
                  accent: accent,
                  value: '$avg7Ppm',
                  unit: 'ppm',
                  label: 'Promedio 7 días',
                  trendPct: avgTrendPct,
                ),
              ),
              Container(
                width: 1,
                height: 46,
                color: Colors.black.withValues(alpha:0.06),
              ),
              Expanded(
                child: _MiniMetric(
                  accent: accent,
                  value: '$rangeMin–$rangeMax',
                  unit: 'ppm',
                  label: 'Variación',
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        ? Colors.black.withValues(alpha:0.06)
        : tone == InsightTone.warn
        ? accent.withValues(alpha:0.10)
        : accent.withValues(alpha:0.08);

    final dot = tone == InsightTone.bad
        ? Colors.black.withValues(alpha:0.45)
        : tone == InsightTone.warn
        ? accent.withValues(alpha:0.95)
        : accent.withValues(alpha:0.90);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: bg,
        border: Border.all(color: Colors.white.withValues(alpha:0.70)),
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
                  color: dot.withValues(alpha:0.45),
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
                color: Colors.black.withValues(alpha:0.62),
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (stageLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha:0.55),
                border: Border.all(color: Colors.white.withValues(alpha:0.75)),
              ),
              child: Text(
                stageLabel,
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha:0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetLinePpm extends StatelessWidget {
  final Color accent;
  final int minPpm;
  final int maxPpm;
  final bool showTargets;

  const _TargetLinePpm({
    required this.accent,
    required this.minPpm,
    required this.maxPpm,
    required this.showTargets,
  });

  @override
  Widget build(BuildContext context) {
    final text = !showTargets || (minPpm == 0 && maxPpm == 0)
        ? 'Objetivo por etapa: no disponible'
        : 'Objetivo etapa: $minPpm–$maxPpm ppm';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.track_changes_rounded,
          size: 16,
          color: accent.withValues(alpha:0.70),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w900,
            color: Colors.black.withValues(alpha:0.55),
          ),
        ),
      ],
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
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) {
          return CustomPaint(
            painter: _TechWaveScanPainter(t: _c.value, accent: widget.accent),
          );
        },
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
      ..color = accent.withValues(alpha:0.70);

    final core = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = accent.withValues(alpha:0.96);

    canvas.drawPath(path, glow);
    canvas.drawPath(path, core);
  }

  @override
  bool shouldRepaint(covariant _TechWaveScanPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.accent != accent;
  }
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
                  color: Colors.black.withValues(alpha:0.42),
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
                color: trendColor.withValues(alpha:0.95),
              ),
              Text(
                '${up ? '+' : ''}${trendPct!.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: trendColor.withValues(alpha:0.95),
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
            color: accent.withValues(alpha:0.82),
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
          color: _brandMid.withValues(alpha:opacity),
        ),
      ),
    );
  }
}
