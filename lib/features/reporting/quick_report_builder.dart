import 'dart:async';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/history/history_series_builder.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/features/reporting/quick_report_data.dart';

class QuickReportBuilder {
  const QuickReportBuilder();

  static const int _expectedHistoryPoints = 7;

  Future<QuickReportData> build({
    required BioGStore store,
    required CropRuntimeSnapshot runtime,
    required DateTime now,
  }) async {
    final BioGDevice? device = runtime.device ?? store.activeDevice;
    final BioGTelemetry? live = runtime.live ?? store.live;

    final List<BioGTelemetry> history = await _safeReadHistory(store);
    final HistoryNpkSeriesSet historySeries = const HistorySeriesBuilder()
        .buildNpkSeries(range: HistoryRange.d7, telemetry: history, now: now);

    final String deviceName = _resolveDeviceName(device);
    final String? lotLabel = _resolveLotLabel(device);
    final String profileLabel = _resolveProfileLabel(runtime);

    if (live == null) {
      return QuickReportData(
        deviceName: deviceName,
        lotLabel: lotLabel,
        cropLabel: runtime.cropLabel,
        profileLabel: profileLabel,
        stageLabel: runtime.stageLabel,
        daySinceSowing: runtime.stageResult?.daySinceSowing,
        generatedAt: now,
        nValue: 0,
        pValue: 0,
        kValue: 0,
        nPercent: 0,
        pPercent: 0,
        kPercent: 0,
        nStatus: 'Sin lectura',
        pStatus: 'Sin lectura',
        kStatus: 'Sin lectura',
        historyLabels: _normalizeStringList(historySeries.labels),
        historyN: _normalizeDoubleList(historySeries.nValues),
        historyP: _normalizeDoubleList(historySeries.pValues),
        historyK: _normalizeDoubleList(historySeries.kValues),
        recommendationTitle: 'Sin lectura actual',
        recommendationBody:
            'No hay telemetría disponible en este momento para generar una recomendación confiable del lote.',
      );
    }

    final NutrientInterpretationResult nInterpretation =
        NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.n,
          rawPpm: live.n,
          cropKey: runtime.cropKeyName,
          stageKey: runtime.stageResult?.stageKey,
          profileId: runtime.profile?.id,
          targets: runtime.targets,
          ph: live.ph,
          ec: live.ec,
          soilMoisturePct: live.soilMoisturePct,
        );

    final NutrientInterpretationResult pInterpretation =
        NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.p,
          rawPpm: live.p,
          cropKey: runtime.cropKeyName,
          stageKey: runtime.stageResult?.stageKey,
          profileId: runtime.profile?.id,
          targets: runtime.targets,
          ph: live.ph,
          ec: live.ec,
          soilMoisturePct: live.soilMoisturePct,
        );

    final NutrientInterpretationResult kInterpretation =
        NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.k,
          rawPpm: live.k,
          cropKey: runtime.cropKeyName,
          stageKey: runtime.stageResult?.stageKey,
          profileId: runtime.profile?.id,
          targets: runtime.targets,
          ph: live.ph,
          ec: live.ec,
          soilMoisturePct: live.soilMoisturePct,
        );

    final List<NutrientInterpretationResult> ordered =
        <NutrientInterpretationResult>[
          nInterpretation,
          pInterpretation,
          kInterpretation,
        ]..sort((a, b) => b.priorityScore01.compareTo(a.priorityScore01));

    final NutrientInterpretationResult top = ordered.first;

    return QuickReportData(
      deviceName: deviceName,
      lotLabel: lotLabel,
      cropLabel: runtime.cropLabel,
      profileLabel: profileLabel,
      stageLabel: runtime.stageLabel,
      daySinceSowing: runtime.stageResult?.daySinceSowing,
      generatedAt: now,
      nValue: live.n,
      pValue: live.p,
      kValue: live.k,
      nPercent: _normalizeNpkPercent(
        cropKey: runtime.cropKeyName,
        metricKey: AgroMetricKey.n,
        value: live.n,
      ),
      pPercent: _normalizeNpkPercent(
        cropKey: runtime.cropKeyName,
        metricKey: AgroMetricKey.p,
        value: live.p,
      ),
      kPercent: _normalizeNpkPercent(
        cropKey: runtime.cropKeyName,
        metricKey: AgroMetricKey.k,
        value: live.k,
      ),
      nStatus: nInterpretation.labelEs,
      pStatus: pInterpretation.labelEs,
      kStatus: kInterpretation.labelEs,
      historyLabels: _normalizeStringList(historySeries.labels),
      historyN: _normalizeDoubleList(historySeries.nValues),
      historyP: _normalizeDoubleList(historySeries.pValues),
      historyK: _normalizeDoubleList(historySeries.kValues),
      recommendationTitle: _buildRecommendationTitle(top),
      recommendationBody: _buildRecommendationBody(top: top, runtime: runtime),
    );
  }

  Future<List<BioGTelemetry>> _safeReadHistory(BioGStore store) async {
    try {
      final List<BioGTelemetry> history = await store
          .watchHistory(const Duration(days: 7))
          .first;
      return history;
    } catch (_) {
      return const <BioGTelemetry>[];
    }
  }

  String _resolveDeviceName(BioGDevice? device) {
    final String fromName = device?.name.trim() ?? '';
    if (fromName.isNotEmpty) return fromName;

    final String fromLocation = device?.locationName.trim() ?? '';
    if (fromLocation.isNotEmpty) return fromLocation;

    return 'BioG';
  }

  String? _resolveLotLabel(BioGDevice? device) {
    final String fromLocation = device?.locationName.trim() ?? '';
    if (fromLocation.isNotEmpty) return fromLocation;
    return null;
  }

  String _resolveProfileLabel(CropRuntimeSnapshot runtime) {
    final String varietyAlias =
        (runtime.cropContext?.varietyAlias ?? runtime.seed?.varietyAlias ?? '')
            .trim();
    if (varietyAlias.isNotEmpty && varietyAlias.toLowerCase() != 'generic') {
      return varietyAlias;
    }

    final String profileLabel = runtime.profile?.label.trim() ?? '';
    if (profileLabel.isNotEmpty) return profileLabel;

    if (runtime.isGenericMode) return 'Perfil genérico';
    if (runtime.isPlanned) return 'Configuración planeada';

    return 'Perfil activo';
  }

  double _normalizeNpkPercent({
    required String? cropKey,
    required AgroMetricKey metricKey,
    required double value,
  }) {
    final double cap = NpkCaps.forCropMetric(
      cropKey: cropKey,
      metricKey: metricKey,
    );

    if (cap <= 0) return 0.0;
    return (value / cap).clamp(0.0, 1.0);
  }

  String _buildRecommendationTitle(NutrientInterpretationResult top) {
    final String nutrientName = top.nutrient.labelEs;

    switch (top.label) {
      case NutrientPriorityLabel.noPriority:
        return 'Nutrición estable';
      case NutrientPriorityLabel.lowPriority:
        return 'Vigilar $nutrientName';
      case NutrientPriorityLabel.mediumPriority:
        return 'Atención en $nutrientName';
      case NutrientPriorityLabel.highPriority:
        return 'Falta $nutrientName';
      case NutrientPriorityLabel.reviewManagement:
        return 'Ajustar dosis de $nutrientName';
      case NutrientPriorityLabel.actionRecommended:
        return 'Urge aplicar $nutrientName';
      case NutrientPriorityLabel.possibleExcess:
        return 'Pausar $nutrientName';
      case NutrientPriorityLabel.reviewAccumulation:
        return 'Revisar exceso de $nutrientName';
      case NutrientPriorityLabel.unknown:
        return 'Revisar nutrición';
    }
  }

  String _buildRecommendationBody({
    required NutrientInterpretationResult top,
    required CropRuntimeSnapshot runtime,
  }) {
    final String doseGuide = (top.doseGuideEs ?? '').trim();
    final String practical = top.practicalRecommendation.trim();
    final String shortRec = top.shortRecommendation.trim();

    if (doseGuide.isNotEmpty) {
      return doseGuide;
    }

    if (practical.isNotEmpty) {
      return practical;
    }

    if (shortRec.isNotEmpty) {
      return shortRec;
    }

    if (runtime.isPlanned) {
      return 'El lote está en preparación. Mantén seguimiento de suelo y afina la estrategia antes de la siembra.';
    }

    if (runtime.isGenericMode) {
      return 'El lote está en modo genérico. Configurar el cultivo mejorará la precisión de la recomendación.';
    }

    return 'Se recomienda revisar la nutrición actual del lote antes de la siguiente intervención.';
  }

  List<String> _normalizeStringList(List<String> source) {
    final List<String> values = List<String>.from(source);

    if (values.length == _expectedHistoryPoints) return values;

    if (values.length > _expectedHistoryPoints) {
      return values.sublist(values.length - _expectedHistoryPoints);
    }

    final List<String> normalized = List<String>.filled(
      _expectedHistoryPoints,
      '',
    );

    final int start = _expectedHistoryPoints - values.length;
    for (int i = 0; i < values.length; i++) {
      normalized[start + i] = values[i];
    }

    return normalized;
  }

  List<double> _normalizeDoubleList(List<double> source) {
    final List<double> values = List<double>.from(source);

    if (values.length == _expectedHistoryPoints) return values;

    if (values.length > _expectedHistoryPoints) {
      return values.sublist(values.length - _expectedHistoryPoints);
    }

    final List<double> normalized = List<double>.filled(
      _expectedHistoryPoints,
      0.0,
    );

    final int start = _expectedHistoryPoints - values.length;
    for (int i = 0; i < values.length; i++) {
      normalized[start + i] = values[i];
    }

    return normalized;
  }
}
