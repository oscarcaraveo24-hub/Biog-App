import 'dart:async';

import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
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

    // La nutrición del informe es la misma decisión que ve el Panel: una sola
    // autoridad (Guía v0.4, §9). Aquí no se interpreta ninguna lectura N/P/K;
    // los canales nativos se imprimen como señal y tendencia, en la escala del
    // propio sitio (§8).
    final NutritionDecision? decision = runtime.isPlanted && !runtime.isGuideMode
        ? store.nutritionDecisionAt(now)
        : null;

    final List<double> nSeries = _nativeSeries(history, (t) => t.hasNitrogenData ? t.n : null);
    final List<double> pSeries = _nativeSeries(history, (t) => t.hasPhosphorusData ? t.p : null);
    final List<double> kSeries = _nativeSeries(history, (t) => t.hasPotassiumData ? t.k : null);

    final MapEntry<String, String>? climateBanner = _buildClimateBanner(
      runtime: runtime,
      live: live,
    );
    final MapEntry<String, String> recommendation = _buildNutritionRecommendation(
      decision: decision,
      runtime: runtime,
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
      nValue: live.hasNitrogenData ? live.n : 0,
      pValue: live.hasPhosphorusData ? live.p : 0,
      kValue: live.hasPotassiumData ? live.k : 0,
      nPercent: _siteScaledPercent(live.hasNitrogenData ? live.n : null, nSeries),
      pPercent: _siteScaledPercent(live.hasPhosphorusData ? live.p : null, pSeries),
      kPercent: _siteScaledPercent(live.hasPotassiumData ? live.k : null, kSeries),
      nStatus: live.hasNitrogenData ? _trendStatus(nSeries) : '—',
      pStatus: live.hasPhosphorusData ? _trendStatus(pSeries) : '—',
      kStatus: live.hasPotassiumData ? _trendStatus(kSeries) : '—',
      historyLabels: _normalizeStringList(historySeries.labels),
      historyN: _normalizeDoubleList(historySeries.nValues),
      historyP: _normalizeDoubleList(historySeries.pValues),
      historyK: _normalizeDoubleList(historySeries.kValues),
      recommendationTitle: recommendation.key,
      recommendationBody: recommendation.value,
      climateBannerTitle: climateBanner?.key,
      climateBannerBody: climateBanner?.value,
    );
  }

  /// Serie de 7 días de un canal nativo, solo con lo que la sonda midió.
  static List<double> _nativeSeries(
    List<BioGTelemetry> history,
    double? Function(BioGTelemetry) pick,
  ) {
    final List<BioGTelemetry> sorted = <BioGTelemetry>[...history]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final List<double> out = <double>[];
    for (final BioGTelemetry t in sorted) {
      final double? v = pick(t);
      if (v != null && v.isFinite) out.add(v < 0 ? 0.0 : v);
    }
    return out;
  }

  /// Posición del anillo en la escala del PROPIO sitio (máximo reciente ×
  /// 1.15). Sin tope por cultivo ni objetivo: la sonda no sostiene «bajo/alto».
  static double _siteScaledPercent(double? level, List<double> series) {
    if (level == null || !level.isFinite) return 0.0;
    double maxV = level;
    for (final double v in series) {
      if (v > maxV) maxV = v;
    }
    final double scale = maxV * 1.15 < 10.0 ? 10.0 : maxV * 1.15;
    return (level / scale).clamp(0.0, 1.0);
  }

  /// Tendencia de la señal nativa: 3 últimas lecturas contra las 3 anteriores.
  static String _trendStatus(List<double> series) {
    if (series.length < 6) return 'Señal nativa';
    double avg(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
    final double a = avg(series.sublist(series.length - 3));
    final double b = avg(series.sublist(series.length - 6, series.length - 3));
    if (b.abs() < 0.0001) return 'Señal nativa';
    final double pct = ((a - b) / b) * 100.0;
    if (pct > 4) return 'Subiendo';
    if (pct < -4) return 'Bajando';
    return 'Estable';
  }

  MapEntry<String, String> _buildNutritionRecommendation({
    required NutritionDecision? decision,
    required CropRuntimeSnapshot runtime,
  }) {
    if (decision != null) {
      final StringBuffer body = StringBuffer(decision.detailEs.trim());
      final NutritionRecommendation? rec = decision.recommendation;
      if (rec != null && rec.doseRange != null) {
        body.write(' Rango orientativo: ${rec.doseRange!.labelEs}.');
        if (rec.doseRange!.commercialEquivalentEs != null) {
          body.write(' ${rec.doseRange!.commercialEquivalentEs}.');
        }
      }
      final NutritionWindowRecord? unattended = decision.recentlyUnattendedWindow;
      if (unattended != null && decision.state != NutritionState.monitor) {
        body.write(
          ' La ventana de ${unattended.nutrientsLabelEs} en '
          '«${unattended.stageLabelEs}» terminó sin evidencia suficiente de '
          'haber sido atendida.',
        );
      }
      return MapEntry(decision.headlineEs, body.toString());
    }
    if (runtime.isGuideMode) {
      return const MapEntry(
        'Nutrición sin interpretar',
        'En guía general no hay cultivo declarado: sin etapa no hay ventana de '
            'manejo nutricional. Las señales N/P/K se imprimen como tendencia.',
      );
    }
    if (runtime.isPlanned) {
      return const MapEntry(
        'Lote en preparación',
        'El lote está en preparación. La ventana de manejo nutricional se abre '
            'con la etapa, después de la siembra.',
      );
    }
    if (runtime.isGenericMode) {
      return const MapEntry(
        'Configura el cultivo',
        'El lote está en modo genérico. Con un cultivo configurado BIO-G abre '
            'ventanas de manejo por etapa y observa la respuesta del suelo.',
      );
    }
    return const MapEntry(
      'Sin evaluación nutricional vigente',
      'BIO-G no tenía una decisión de nutrición vigente al generar este informe. '
          'Abre el Panel para recalcularla con la etapa y el historial.',
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
    // Ornamentales (cactus, suculenta…): el perfil ES la identidad visible. El
    // reporte comparte plantilla con el resto de cultivos y NO lleva rendimiento.
    if (isEstablishmentMaintenanceCrop(cropId: canonicalCrop)) {
      final token =
          runtime.cropContext?.profileId ??
          runtime.profile?.id ??
          runtime.seed?.profileId;
      return CropCatalog.profileByAny(canonicalCrop, token)?.label ??
          ornamentalGeneralProfileLabel(canonicalCrop);
    }
    // Tulipán (seasonal_bulb): el perfil ES la identidad visible, como las
    // ornamentales. El reporte comparte plantilla y NO lleva rendimiento.
    if (isSeasonalBulbCrop(cropId: canonicalCrop)) {
      final token =
          runtime.cropContext?.profileId ??
          runtime.profile?.id ??
          runtime.seed?.profileId;
      return CropCatalog.profileByAny(canonicalCrop, token)?.label ??
          seasonalBulbGeneralProfileLabel(canonicalCrop);
    }
    // Girasol (annual_ornamental): el perfil ES la identidad visible. El reporte
    // comparte plantilla y NO lleva rendimiento.
    if (isAnnualOrnamentalCrop(cropId: canonicalCrop)) {
      final token =
          runtime.cropContext?.profileId ??
          runtime.profile?.id ??
          runtime.seed?.profileId;
      return CropCatalog.profileByAny(canonicalCrop, token)?.label ??
          annualOrnamentalGeneralProfileLabel(canonicalCrop);
    }
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
      final String? defaultProfileId = CropCatalog.cropById(
        canonicalCrop,
      )?.defaultProfileId;

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

    // Cada canal se lee SOLO si su bandera de presencia lo permite. Sin esto,
    // un informe para un equipo sin sensor de aire imprimía «temperatura
    // ambiente baja (0.0 °C)» —indistinguible de una helada real— y un equipo
    // sin sonda de humedad imprimía «suelo seco (0.0 %)».
    if (live.hasAirTempData) {
      if (live.airTempC >= 35) {
        drivers.add(
          'temperatura ambiente alta (${live.airTempC.toStringAsFixed(1)} °C)',
        );
      } else if (live.airTempC <= 5) {
        drivers.add(
          'temperatura ambiente baja (${live.airTempC.toStringAsFixed(1)} °C)',
        );
      }
    }

    if (live.hasAirHumidityData && live.airHumidityPct >= 85) {
      drivers.add(
        'humedad ambiental elevada (${live.airHumidityPct.toStringAsFixed(1)} %)',
      );
    }

    // Umbrales derivados de la textura del suelo, no absolutos.
    //
    // Antes eran `<= 15` y `>= 80`. El primero llamaba «seco» a un suelo
    // arenoso con 15 %, que está POR ENCIMA de su capacidad de campo (12) —o
    // sea, un suelo que está drenando—. El segundo era rama muerta: 80 % no lo
    // alcanza ningún suelo mineral (la saturación máxima de la tabla es 53) ni
    // el sustrato drenante (78). En dos años nadie vio ese aviso.
    if (live.hasSoilMoistureData) {
      final band = runtime.resolvedMoisture?.range;
      final secoMax = band?.lowMax ?? 15;
      final excesoMin = band?.highMin ?? 80;
      if (live.soilMoisturePct <= secoMax) {
        drivers.add('suelo seco (${live.soilMoisturePct.toStringAsFixed(1)} %)');
      } else if (live.soilMoisturePct >= excesoMin) {
        drivers.add(
          'suelo con humedad excesiva (${live.soilMoisturePct.toStringAsFixed(1)} %)',
        );
      }
    }

    if (drivers.isEmpty) return null;

    final String title =
        live.hasAirHumidityData &&
            live.hasAirTempData &&
            live.airHumidityPct >= 85 &&
            live.airTempC >= 28
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
