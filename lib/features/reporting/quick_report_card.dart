import 'package:flutter/material.dart';

import 'package:bio_g/features/reporting/quick_report_data.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/history/history_npk_chart_card.dart'
    show HistoryNpkChartCard;
import 'package:bio_g/widgets/npk/npk_gauge_card.dart'
    show NpkChannel, NpkGaugeCard;
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class QuickReportCard extends StatelessWidget {
  final QuickReportData data;
  final double width;
  final double height;

  const QuickReportCard({
    super.key,
    required this.data,
    this.width = 1080,
    this.height = 1600,
  });

  @override
  Widget build(BuildContext context) {
    final String generatedText = _formatGeneratedAt(data.generatedAt);
    final String cropLine = _buildCropLine(data);
    final String stageLine = _buildStageLine(data);

    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(42),
            gradient: BioGTheme.softBackground,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 48,
                offset: const Offset(0, 26),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(42),
            child: Stack(
              children: <Widget>[
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.white.withValues(alpha: 0.82),
                          const Color(0xFFF7FBF8),
                          const Color(0xFFF1F7F4),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -120,
                  right: -80,
                  child: _SoftGlow(
                    size: 320,
                    color: BioGTheme.brandTop.withValues(alpha: 0.12),
                  ),
                ),
                Positioned(
                  bottom: -120,
                  left: -70,
                  child: _SoftGlow(
                    size: 300,
                    color: BioGTheme.teal.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(38, 38, 38, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _QuickReportHeader(
                        lotOrDevice: data.displayLotOrDevice,
                        deviceName: data.deviceName,
                        generatedText: generatedText,
                      ),
                      const SizedBox(height: 20),
                      _SectionShell(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              cropLine,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: BioGTheme.ink,
                                height: 1.0,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              stageLine,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: BioGTheme.charcoal.withValues(
                                  alpha: 0.78,
                                ),
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _InfoPill(
                                    label: 'Cultivo',
                                    value: data.cropLabel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoPill(
                                    label: 'Perfil',
                                    value: data.profileLabel,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _InfoPill(
                                    label: 'Etapa',
                                    value: data.stageLabel,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionShell(
                        padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const _SectionTitle(
                              title: 'Lectura nutricional actual',
                              subtitle: 'Resumen rápido NPK del lote',
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              height: 350,
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _GaugeWrap(
                                      child: NpkGaugeCard(
                                        channel: NpkChannel.n,
                                        percent: data.nPercent,
                                        title: 'Nitrógeno',
                                        description: 'Estado actual del N',
                                        statusLabel: data.nStatus,
                                        centerValue: data.nValue.round(),
                                        centerUnit: 'ppm',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _GaugeWrap(
                                      child: NpkGaugeCard(
                                        channel: NpkChannel.p,
                                        percent: data.pPercent,
                                        title: 'Fósforo',
                                        description: 'Estado actual del P',
                                        statusLabel: data.pStatus,
                                        centerValue: data.pValue.round(),
                                        centerUnit: 'ppm',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _GaugeWrap(
                                      child: NpkGaugeCard(
                                        channel: NpkChannel.k,
                                        percent: data.kPercent,
                                        title: 'Potasio',
                                        description: 'Estado actual del K',
                                        statusLabel: data.kStatus,
                                        centerValue: data.kValue.round(),
                                        centerUnit: 'ppm',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: _SectionShell(
                          padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const _SectionTitle(
                                title: 'Historial NPK · 7 días',
                                subtitle: 'Tendencia reciente del lote',
                              ),
                              const SizedBox(height: 14),
                              Expanded(
                                child: HistoryNpkChartCard(
                                  title: 'Comportamiento reciente',
                                  labels: data.historyLabels,
                                  nValues: data.historyN,
                                  pValues: data.historyP,
                                  kValues: data.historyK,
                                  lastReadingText: generatedText,
                                  liveN: data.nValue,
                                  liveP: data.pValue,
                                  liveK: data.kValue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _SectionShell(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const _SectionTitle(
                              title: 'Recomendación principal',
                              subtitle: 'Acción sugerida por BIO-G',
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                18,
                                18,
                                18,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: <Color>[
                                    BioGTheme.brandTop.withValues(alpha: 0.10),
                                    BioGTheme.brandMid.withValues(alpha: 0.07),
                                    Colors.white.withValues(alpha: 0.75),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.92),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    data.recommendationTitle,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: BioGTheme.ink,
                                      height: 1.0,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    data.recommendationBody,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: BioGTheme.charcoal.withValues(
                                        alpha: 0.78,
                                      ),
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (data.hasClimateBanner) ...<Widget>[
                        const SizedBox(height: 18),
                        _ClimateBanner(
                          title:
                              data.climateBannerTitle?.trim().isNotEmpty == true
                              ? data.climateBannerTitle!.trim()
                              : 'Clima inteligente',
                          body:
                              data.climateBannerBody?.trim().isNotEmpty == true
                              ? data.climateBannerBody!.trim()
                              : 'Hay una observación climática relevante para esta recomendación.',
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        'Reporte rápido BIO-G · Compartible con ingeniero agrónomo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: BioGTheme.charcoal.withValues(alpha: 0.42),
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildCropLine(QuickReportData data) {
    final String crop = data.cropLabel.trim();
    final String profile = data.profileLabel.trim();

    if (profile.isEmpty) return crop;
    return '$crop · $profile';
  }

  String _buildStageLine(QuickReportData data) {
    final String base = data.stageLabel.trim();
    final int? day = data.daySinceSowing;

    if (day == null) return base;
    return '$base · Día $day desde siembra';
  }

  String _formatGeneratedAt(DateTime dateTime) {
    const List<String> months = <String>[
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final int hour24 = dateTime.hour;
    final int hour12 = hour24 == 0 ? 12 : (hour24 > 12 ? hour24 - 12 : hour24);
    final String minute = dateTime.minute.toString().padLeft(2, '0');
    final String suffix = hour24 >= 12 ? 'pm' : 'am';

    return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year} · $hour12:$minute $suffix';
  }
}

class _QuickReportHeader extends StatelessWidget {
  final String lotOrDevice;
  final String deviceName;
  final String generatedText;

  const _QuickReportHeader({
    required this.lotOrDevice,
    required this.deviceName,
    required this.generatedText,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionShell(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: BioGTheme.brandGradient,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: BioGTheme.brandTop.withValues(alpha: 0.22),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, size: 34, color: Colors.white),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'BIO-G · Reporte del lote',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: BioGTheme.ink,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  lotOrDevice,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: BioGTheme.charcoal.withValues(alpha: 0.82),
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dispositivo: $deviceName',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BioGTheme.charcoal.withValues(alpha: 0.54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.76),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.98)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  'Generado',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: BioGTheme.charcoal.withValues(alpha: 0.46),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  generatedText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: BioGTheme.ink,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;

  const _SectionShell({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 20, 24, 20),
  });

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 28,
      padding: padding,
      backgroundColor: Colors.white.withValues(alpha: 0.82),
      borderColor: Colors.white.withValues(alpha: 0.95),
      boxShadows: <BoxShadow>[
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 30,
          offset: const Offset(0, 16),
        ),
        BoxShadow(
          color: BioGTheme.brandTop.withValues(alpha: 0.05),
          blurRadius: 50,
          offset: const Offset(0, 24),
        ),
      ],
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: BioGTheme.ink,
                  height: 1.0,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: BioGTheme.charcoal.withValues(alpha: 0.52),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;

  const _InfoPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.62),
        border: Border.all(color: Colors.white.withValues(alpha: 0.92)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BioGTheme.charcoal.withValues(alpha: 0.42),
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: BioGTheme.ink,
              height: 1.1,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugeWrap extends StatelessWidget {
  final Widget child;

  const _GaugeWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.white.withValues(alpha: 0.50),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
      ),
      child: child,
    );
  }
}

class _ClimateBanner extends StatelessWidget {
  final String title;
  final String body;

  const _ClimateBanner({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFF7C65F).withValues(alpha: 0.20),
            const Color(0xFFF0A35E).withValues(alpha: 0.12),
            Colors.white.withValues(alpha: 0.78),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.94)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFFF0A35E).withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFF5B74F).withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: Color(0xFFAF6E1B),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: BioGTheme.ink,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: BioGTheme.charcoal.withValues(alpha: 0.74),
                    height: 1.3,
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

class _SoftGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _SoftGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: <BoxShadow>[
            BoxShadow(color: color, blurRadius: 80, spreadRadius: 20),
          ],
        ),
      ),
    );
  }
}
