import 'dart:async';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/tree_profile_presentation.dart';
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
        readingAt: null,
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

    final String? scaleId = runtime.cropContext?.cultivationScaleId;

    final NutrientInterpretationResult nInterpretation =
        NutrientRecommendationEngine.interpret(
          nutrient: AgroMetricKey.n,
          rawPpm: live.n,
          cropKey: runtime.cropKeyName,
          stageKey: runtime.stageResult?.stageKey,
          profileId: runtime.profile?.id,
          varietyId: runtime.cropContext?.varietyId,
          varietyAlias: runtime.cropContext?.varietyAlias,
          calendarId: runtime.cropContext?.calendarTypeId,
          targets: runtime.targets,
          cultivationScaleId: scaleId,
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
          varietyId: runtime.cropContext?.varietyId,
          varietyAlias: runtime.cropContext?.varietyAlias,
          calendarId: runtime.cropContext?.calendarTypeId,
          targets: runtime.targets,
          cultivationScaleId: scaleId,
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
          varietyId: runtime.cropContext?.varietyId,
          varietyAlias: runtime.cropContext?.varietyAlias,
          calendarId: runtime.cropContext?.calendarTypeId,
          targets: runtime.targets,
          cultivationScaleId: scaleId,
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
    final MapEntry<String, String>? climateBanner = _buildClimateBanner(
      runtime: runtime,
      live: live,
    );

    return QuickReportData(
      deviceName: deviceName,
      lotLabel: lotLabel,
      cropLabel: runtime.cropLabel,
      profileLabel: profileLabel,
      stageLabel: runtime.stageLabel,
      daySinceSowing: runtime.stageResult?.daySinceSowing,
      generatedAt: now,
      readingAt: live.timestamp,
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
      recommendationTitle: _buildRecommendationTitle(
        top,
        cropKey: runtime.cropKeyName,
      ),
      recommendationBody: _buildRecommendationBody(top: top, runtime: runtime),
      climateBannerTitle: climateBanner?.key,
      climateBannerBody: climateBanner?.value,
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
    final String canonicalCrop = CropCatalog.canonicalCropKey(
      runtime.cropKeyName,
    );
    if (_isFruitTreeCrop(canonicalCrop)) {
      final String? profileToken =
          runtime.profile?.id ??
          runtime.cropContext?.profileId ??
          runtime.cropContext?.varietyId ??
          runtime.cropContext?.varietyAlias ??
          runtime.seed?.profileId ??
          runtime.seed?.varietyAlias;
      final profile = CropCatalog.profileByAny(canonicalCrop, profileToken);
      final String? resolvedProfileId = profile?.id ?? profileToken;
      final String? defaultProfileId =
          CropCatalog.cropById(canonicalCrop)?.defaultProfileId;

      if (resolvedProfileId == null || resolvedProfileId.trim().isEmpty) {
        return _fruitTreeGenericProfileLabel(canonicalCrop);
      }

      final normalized = resolvedProfileId.trim().toLowerCase();
      if (normalized == defaultProfileId || normalized.endsWith('_skip')) {
        return _fruitTreeGenericProfileLabel(canonicalCrop);
      }

      return TreeProfilePresentation.displayLabel(
        canonicalCrop,
        resolvedProfileId,
        fallbackLabel: profile?.label,
      );
    }

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
    if (runtime.hasConfiguredCrop) {
      return 'Configuración activa sin variedad definida';
    }

    return 'Sin perfil definido';
  }

  MapEntry<String, String>? _buildClimateBanner({
    required CropRuntimeSnapshot runtime,
    required BioGTelemetry live,
  }) {
    final List<BioGAlert> alerts = runtime.eval?.alerts ?? const <BioGAlert>[];
    final List<BioGAlert> environmentAlerts = alerts
        .where((BioGAlert alert) => _isEnvironmentAlert(alert.type))
        .toList();

    if (environmentAlerts.isNotEmpty) {
      environmentAlerts.sort((BioGAlert a, BioGAlert b) {
        final int bySeverity = _alertSeverityRank(
          b.severity,
        ).compareTo(_alertSeverityRank(a.severity));
        if (bySeverity != 0) return bySeverity;
        return b.timestamp.compareTo(a.timestamp);
      });

      final BioGAlert top = environmentAlerts.first;
      final String body = top.body.trim();
      if (body.isEmpty) return null;
      return MapEntry(
        top.title.trim().isEmpty ? 'Contexto ambiental' : top.title.trim(),
        body,
      );
    }

    final List<String> drivers = <String>[];

    if (live.airTempC >= 35) {
      drivers.add(
        'temperatura ambiente alta (${live.airTempC.toStringAsFixed(1)} °C)',
      );
    } else if (live.airTempC <= 5) {
      drivers.add(
        'temperatura ambiente baja (${live.airTempC.toStringAsFixed(1)} °C)',
      );
    }

    if (live.airHumidityPct >= 85) {
      drivers.add(
        'humedad ambiental elevada (${live.airHumidityPct.toStringAsFixed(1)} %)',
      );
    }

    if (live.soilMoisturePct <= 15) {
      drivers.add('suelo seco (${live.soilMoisturePct.toStringAsFixed(1)} %)');
    } else if (live.soilMoisturePct >= 80) {
      drivers.add(
        'suelo con humedad excesiva (${live.soilMoisturePct.toStringAsFixed(1)} %)',
      );
    }

    if (drivers.isEmpty) return null;

    final String title = live.airHumidityPct >= 85 && live.airTempC >= 28
        ? 'Ambiente favorable para presión sanitaria'
        : 'Contexto ambiental a vigilar';

    return MapEntry(
      title,
      'La lectura actual muestra ${_joinHumanList(drivers)}. Conviene interpretar la recomendación principal junto con estas condiciones antes de intervenir el lote.',
    );
  }

  bool _isEnvironmentAlert(BioGAlertType type) {
    switch (type) {
      case BioGAlertType.lowSoilMoisture:
      case BioGAlertType.highSoilMoisture:
      case BioGAlertType.tempExtreme:
      case BioGAlertType.airTempExtreme:
      case BioGAlertType.highHumidity:
        return true;
      case BioGAlertType.phOutOfRange:
      case BioGAlertType.ecOutOfRange:
      case BioGAlertType.sensorOffline:
      case BioGAlertType.stageEvent:
        return false;
    }
  }

  int _alertSeverityRank(BioGAlertSeverity severity) {
    switch (severity) {
      case BioGAlertSeverity.info:
        return 1;
      case BioGAlertSeverity.warning:
        return 2;
      case BioGAlertSeverity.critical:
        return 3;
    }
  }

  String _joinHumanList(List<String> values) {
    if (values.isEmpty) return '';
    if (values.length == 1) return values.first;
    if (values.length == 2) {
      return '${values.first} y ${values.last}';
    }

    final String head = values.sublist(0, values.length - 1).join(', ');
    return '$head y ${values.last}';
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

  bool _isFruitTreeCrop(String? cropKey) {
    final crop = CropCatalog.canonicalCropKey(cropKey).trim().toLowerCase();
    // Arboles frutales perennes (pepita + hueso/carozo + nuez).
    return crop == 'apple_tree' ||
        crop == 'crop_apple_tree' ||
        crop == 'manzano' ||
        crop == 'pear_tree' ||
        crop == 'crop_pear_tree' ||
        crop == 'pera' ||
        crop == 'peral' ||
        crop == 'peach_tree' ||
        crop == 'crop_peach_tree' ||
        crop == 'peach' ||
        crop == 'peachtree' ||
        crop == 'durazno' ||
        crop == 'duraznero' ||
        crop == 'melocoton' ||
        crop == 'melocotón' ||
        crop == 'melocotonero' ||
        crop == 'walnut_tree' ||
        crop == 'crop_walnut_tree' ||
        crop == 'walnut' ||
        crop == 'walnuttree' ||
        crop == 'nogal' ||
        crop == 'pecan' ||
        crop == 'nuez' ||
        crop == 'pistachio_tree' ||
        crop == 'crop_pistachio_tree' ||
        crop == 'pistachio' ||
        crop == 'pistachiotree' ||
        crop == 'pistache' ||
        crop == 'pistacho' ||
        crop == 'pistachero' ||
        crop == 'orange_tree' ||
        crop == 'crop_orange_tree' ||
        crop == 'orange' ||
        crop == 'orangetree' ||
        crop == 'naranjo' ||
        crop == 'naranja' ||
        crop == 'lemon_tree' ||
        crop == 'crop_lemon_tree' ||
        crop == 'lemontree' ||
        crop == 'lime_tree' ||
        crop == 'crop_lime_tree' ||
        crop == 'lemon' ||
        crop == 'lime' ||
        crop == 'limon' ||
        crop == 'limón' ||
        crop == 'limonero' ||
        crop == 'lima' ||
        crop == 'mango_tree' ||
        crop == 'crop_mango_tree' ||
        crop == 'mangotree' ||
        crop == 'crop_mango' ||
        crop == 'mango' ||
        crop == 'mangos' ||
        crop == 'mangifera' ||
        crop == 'mangifera_indica' ||
        crop == 'arbol_mango' ||
        crop == 'árbol_mango' ||
        crop == 'avocado_tree' ||
        crop == 'crop_avocado_tree' ||
        crop == 'avocadotree' ||
        crop == 'crop_avocado' ||
        crop == 'avocado' ||
        crop == 'avocados' ||
        crop == 'aguacate' ||
        crop == 'aguacates' ||
        crop == 'aguacatero' ||
        crop == 'palta' ||
        crop == 'palto' ||
        crop == 'persea' ||
        crop == 'persea_americana' ||
        crop == 'arbol_aguacate' ||
        crop == 'árbol_aguacate' ||
        crop == 'arbol de aguacate' ||
        crop == 'árbol de aguacate';
  }

  String _fruitTreeGenericProfileLabel(String cropKey) {
    return switch (CropCatalog.canonicalCropKey(cropKey)) {
      CropCatalog.appleTreeCropId => 'Manzano general',
      CropCatalog.pearTreeCropId => 'Pera general',
      CropCatalog.peachTreeCropId => 'Durazno general',
      CropCatalog.walnutTreeCropId => 'Nogal general',
      CropCatalog.pistachioTreeCropId => 'Pistache general',
      CropCatalog.orangeTreeCropId => 'Naranjo general',
      CropCatalog.lemonTreeCropId => 'Limón general',
      CropCatalog.mangoTreeCropId => 'Mango general',
      CropCatalog.avocadoTreeCropId => 'Aguacate general',
      _ => 'Perfil general',
    };
  }

  String _buildRecommendationTitle(
    NutrientInterpretationResult top, {
    required String? cropKey,
  }) {
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
        if (_isFruitTreeCrop(cropKey)) {
          return '$nutrientName alto útil';
        }
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

  List<double?> _normalizeDoubleList(List<double?> source) {
    final List<double?> values = List<double?>.from(source);

    if (values.length == _expectedHistoryPoints) return values;

    if (values.length > _expectedHistoryPoints) {
      return values.sublist(values.length - _expectedHistoryPoints);
    }

    final List<double?> normalized = List<double?>.filled(
      _expectedHistoryPoints,
      null,
    );

    final int start = _expectedHistoryPoints - values.length;
    for (int i = 0; i < values.length; i++) {
      normalized[start + i] = values[i];
    }

    return normalized;
  }
}
