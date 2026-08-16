// lib/screens/npk/npk_screen.dart
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_recommendation_engine.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_runtime_resolver.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/npk/npk_gauge_card.dart';

enum InsightTone { ok, warn, bad }

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
  // Lo que había: `stream: store.watchHistory(const Duration(days: 7))`
  // directamente en el `build`. `BioGStore.watchHistory` delega en
  // `HybridBioGRepository.watchHistory`, que declara su `StreamController`
  // como variable LOCAL y devuelve `out.stream`: **objeto nuevo en cada
  // llamada**. `StreamBuilder.didUpdateWidget` compara por identidad
  // (`oldWidget.stream != widget.stream`), así que veía un stream distinto
  // cada vez y hacía `_unsubscribe()` + `_subscribe()`.
  //
  // El coste real de esa resuscripción, medido en la cadena completa:
  //   onCancel  → `_maybeStopDevice` CANCELA el timer de refresco cloud.
  //   onListen  → `_startDevice` + `_startHistory`
  //             → `_emitLocalHistory` → `TelemetryLocalStorage.loadWindow`
  //             → una query SQLite + hasta **2000 `jsonDecode`** síncronos
  //               en el isolate de UI (el tope es `defaultCap = 2000`).
  //
  // Y esto ocurría en CADA notificación del store —hay 20 `notifyListeners()`
  // en `BioGStore`, y con un BioG simulado (`SensorSimulator(tick: 1 s)`) son
  // ~2 por segundo—. Ese es el bloqueo de hilo principal que el logcat del
  // Xiaomi reporta como `Skipped 173 frames`.
  //
  // Efecto secundario que también desaparece: al reiniciarse el timer de
  // polling en cada build, el refresco cloud de 10 minutos NUNCA llegaba a
  // dispararse mientras esta pantalla estuviera abierta.
  //
  // Por qué se cachea aquí y no en el store: el store es propiedad de otro
  // frente de trabajo. Cachear en el `State` da el mismo resultado y no toca
  // nada compartido.
  Stream<List<BioGTelemetry>>? _history7dStream;

  /// Claves de la suscripción vigente. El stream se vuelve a pedir **solo**
  /// si cambia el store o el dispositivo del que cuelga la telemetría.
  BioGStore? _boundStore;
  String? _boundTelemetryDeviceId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ojo: este método se ejecuta en CADA `notifyListeners()` del store,
    // porque `BioGScope` es un `InheritedNotifier` y esta pantalla depende de
    // él. Sin la guarda de abajo, cachear aquí no arreglaría nada: volvería a
    // pedir un stream nuevo con la misma frecuencia que antes.
    final store = BioGScope.of(context);

    // Se usa `telemetryDeviceId` —y no `activeDevice.id`— porque es
    // exactamente la clave sobre la que el repositorio enlaza el historial.
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

  // No hace falta `dispose`: este State no crea controladores ni
  // suscripciones propias. La única suscripción al stream la abre y la cierra
  // el `StreamBuilder`, que se desmonta con la pantalla y dispara el
  // `onCancel` del controlador del repositorio.

  AgroMetricKey _metricKeyFor(NpkChannel ch) {
    switch (ch) {
      case NpkChannel.n:
        return AgroMetricKey.n;
      case NpkChannel.p:
        return AgroMetricKey.p;
      case NpkChannel.k:
        return AgroMetricKey.k;
    }
  }

  int _roundInt(double v) => v.isNaN ? 0 : v.round();

  bool _isFruitTreeCrop(String? cropKey) {
    final crop = CropCatalog.canonicalCropKey(cropKey).trim().toLowerCase();
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
        crop == 'árbol_aguacate';
  }

  double? _trendPctFromSeries(List<double> series) {
    if (series.length < 6) return null;

    double avg(List<double> xs) =>
        xs.isEmpty ? 0.0 : xs.reduce((a, b) => a + b) / xs.length;

    final a = avg(series.sublist(series.length - 3));
    final b = avg(series.sublist(series.length - 6, series.length - 3));

    if (b.abs() < 0.0001) return null;
    return ((a - b) / b) * 100.0;
  }

  double _ppmCap(NpkChannel ch, {required String? cropKey}) {
    return NpkCaps.forCropMetric(
      cropKey: cropKey,
      metricKey: _metricKeyFor(ch),
    );
  }

  double _ppmToGauge01(NpkChannel ch, double ppm, {required String? cropKey}) {
    if (!ppm.isFinite) return 0.0;
    final cap = _ppmCap(ch, cropKey: cropKey);
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

  InsightTone _toneForNutrient({
    required AgroMetricEval? evalMetric,
    required NutrientInterpretationResult? interpretation,
    required String? cropKey,
  }) {
    return _toneForPriorityLabel(
      evalMetric?.priorityLabel ?? interpretation?.label,
      cropKey: cropKey,
    );
  }

  InsightTone _toneForPriorityLabel(
    NutrientPriorityLabel? label, {
    required String? cropKey,
  }) {
    if (_isFruitTreeCrop(cropKey) &&
        label == NutrientPriorityLabel.possibleExcess) {
      return InsightTone.ok;
    }

    switch (label) {
      case NutrientPriorityLabel.actionRecommended:
      case NutrientPriorityLabel.highPriority:
        return InsightTone.warn;
      case NutrientPriorityLabel.possibleExcess:
      case NutrientPriorityLabel.reviewAccumulation:
      case NutrientPriorityLabel.reviewManagement:
        return InsightTone.bad;
      case NutrientPriorityLabel.mediumPriority:
      case NutrientPriorityLabel.lowPriority:
      case NutrientPriorityLabel.noPriority:
      case NutrientPriorityLabel.unknown:
      case null:
        return InsightTone.ok;
    }
  }

  _NpkBand _bandFromAgroBand(AgroBand band) {
    switch (band) {
      case AgroBand.low:
        return _NpkBand.low;
      case AgroBand.optimal:
        return _NpkBand.optimal;
      case AgroBand.high:
        return _NpkBand.high;
      case AgroBand.critical:
        return _NpkBand.critical;
      case AgroBand.unknown:
        return _NpkBand.unknown;
    }
  }

  _NpkBand _bandFromPpmUsingComparableRange({
    required double ppm,
    required AgroRange comparableRange,
  }) {
    if (!ppm.isFinite) return _NpkBand.unknown;

    if (ppm < comparableRange.lowMax) return _NpkBand.critical;
    if (ppm < comparableRange.optimalMin) return _NpkBand.low;
    if (ppm <= comparableRange.optimalMax) return _NpkBand.optimal;
    if (ppm <= comparableRange.highMin) return _NpkBand.high;
    return _NpkBand.critical;
  }

  int _ppmToPctForPainter({
    required NpkChannel ch,
    required int ppm,
    required String? cropKey,
  }) {
    final cap = _ppmCap(ch, cropKey: cropKey);
    final pct = (ppm / cap) * 100.0;
    return pct.round().clamp(0, 100);
  }

  String? _resolveCultivationScaleId(DeviceCropContext? cropContext) {
    if (cropContext == null) return null;
    final v = cropContext.cultivationScaleId;
    return (v != null && v.trim().isNotEmpty) ? v.trim() : null;
  }

  /// practicalRecommendation ya puede venir fusionada con doseGuideEs.
  /// Aquí limpiamos la parte repetida para que la UI no la pinte dos veces.
  String _cleanMergedActionText(String? actionText, String? doseGuideText) {
    var text = (actionText ?? '').trim();
    final dose = (doseGuideText ?? '').trim();

    if (text.isEmpty) return text;
    if (dose.isEmpty) return text;

    final normalizedText = text.replaceAll('\r\n', '\n');
    final normalizedDose = dose.replaceAll('\r\n', '\n');

    if (normalizedText.contains('\n\n$normalizedDose')) {
      text = normalizedText.replaceFirst('\n\n$normalizedDose', '').trim();
    } else if (normalizedText.contains(normalizedDose)) {
      text = normalizedText.replaceFirst(normalizedDose, '').trim();
    }

    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    return text;
  }

  /// O3 · Recibe la serie YA ordenada y saneada, y la tendencia YA calculada.
  ///
  /// Antes este método ordenaba el historial por su cuenta
  /// (`[...history7d]..sort(...)`) y se le llamaba **seis** veces por build:
  /// tres para obtener solo `avgTrendPct` (los antiguos `nBase`/`pBase`/
  /// `kBase`) y otras tres para el resultado definitivo. Con hasta 2000
  /// lecturas en ventana eso eran 6 copias de lista, ~131.400 llamadas a
  /// `DateTime.compareTo` y 24.000 dobles boxeados por build.
  ///
  /// Ahora el orden y las tres series se calculan una sola vez en el `build`
  /// y este método pasa a ser puramente aritmético. El resultado es idéntico:
  /// `List.sort` de Dart es determinista, así que ordenar una vez y reutilizar
  /// produce exactamente la misma secuencia que ordenar seis veces la misma
  /// lista.
  _NpkStats _statsForChannel({
    required NpkChannel channel,
    required BioGTelemetry? live,
    required List<double> series,
    required double? trendPct,
    required StageTargets? targets,
    required bool allowStageInterpretation,
    required String? cropKey,
    AgroMetricEval? evalMetric,
    NutrientInterpretationResult? interpretation,
  }) {
    final level = live == null
        ? 0.0
        : switch (channel) {
            NpkChannel.n => live.n.toDouble(),
            NpkChannel.p => live.p.toDouble(),
            NpkChannel.k => live.k.toDouble(),
          };

    final avg7 = series.isEmpty
        ? 0.0
        : series.reduce((a, b) => a + b) / series.length;

    final minV = series.isEmpty ? 0.0 : series.reduce(math.min);
    final maxV = series.isEmpty ? 0.0 : series.reduce(math.max);

    final gaugePercent = _ppmToGauge01(channel, level, cropKey: cropKey);

    final comparableRange = (!allowStageInterpretation || targets == null)
        ? null
        : NutrientTargetRangeResolver.comparableRange(
            nutrient: _metricKeyFor(channel),
            cropKey: cropKey,
            targets: targets,
          );

    final targetMinPpm = comparableRange == null
        ? null
        : comparableRange.optimalMin.round();

    final targetMaxPpm = comparableRange == null
        ? null
        : comparableRange.optimalMax.round();

    final capPpm = _ppmCap(channel, cropKey: cropKey).round();

    final _NpkBand band = evalMetric != null
        ? _bandFromAgroBand(evalMetric.band)
        : (comparableRange == null)
        ? _NpkBand.unknown
        : _bandFromPpmUsingComparableRange(
            ppm: level,
            comparableRange: comparableRange,
          );

    final priorityLabel = evalMetric?.priorityLabel ?? interpretation?.label;

    final String bandLabel =
        evalMetric?.labelEs ?? interpretation?.labelEs ?? _bandLabelEs(band);

    final bool hideShadow =
        priorityLabel == NutrientPriorityLabel.noPriority ||
        priorityLabel == NutrientPriorityLabel.lowPriority;

    final targetMinPctPainter =
        (allowStageInterpretation && !hideShadow && targetMinPpm != null)
        ? _ppmToPctForPainter(ch: channel, ppm: targetMinPpm, cropKey: cropKey)
        : null;
    final targetMaxPctPainter =
        (allowStageInterpretation && !hideShadow && targetMaxPpm != null)
        ? _ppmToPctForPainter(ch: channel, ppm: targetMaxPpm, cropKey: cropKey)
        : null;

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
                child: Column(
                  children: [
                    const _NpkTabsCard(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: StreamBuilder<List<BioGTelemetry>>(
                        // O1 · Instancia cacheada en `didChangeDependencies`.
                        // Nunca `store.watchHistory(...)` aquí: devolvería un
                        // stream nuevo por build y forzaría la resuscripción
                        // completa del pipeline (query SQLite + hasta 2000
                        // `jsonDecode`) en cada notificación del store.
                        stream: _history7dStream,
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

                          // MODO GUÍA GENERAL.
                          //
                          // En el runtime la guía SÍ cuenta como plantada: por
                          // eso el Panel puede etiquetar humedad, pH,
                          // temperatura y compactación. Pero esta pantalla es
                          // la de nutrición, y ahí no hay nada que interpretar:
                          // sin saber qué planta es ni en qué etapa va, no hay
                          // ventana de demanda de N, P o K.
                          //
                          // Se degrada aquí, en un solo sitio, en vez de
                          // acordarse del modo guía en las veinte ramas de
                          // abajo. Con esto la pantalla entera cae en los
                          // textos de "sin cultivo", que es exactamente lo
                          // correcto: la lectura se muestra, la lectura
                          // agronómica no se inventa.
                          final bool isGuide = runtime.isGuideMode;
                          final isPlanted = runtime.isPlanted && !isGuide;
                          final isPlanned = runtime.isPlanned;
                          final targets = runtime.targets;
                          final eval = runtime.eval;
                          final nEvalMetric = eval?.metrics[AgroMetricKey.n];
                          final pEvalMetric = eval?.metrics[AgroMetricKey.p];
                          final kEvalMetric = eval?.metrics[AgroMetricKey.k];
                          final stageKey = runtime.stageResult?.stageKey;
                          // Los pesos de etapa NO están cableados en esta
                          // pantalla, y decirlo así es más honesto que el
                          // código que había.
                          //
                          // Lo que había: `_resolveRuntimeWeights(dynamic
                          // runtime)` leía `runtime.weights` por despacho
                          // dinámico dentro de un `catch (_) {}` vacío.
                          // `CropRuntimeSnapshot` no tiene un miembro
                          // `weights`: ni campo, ni getter, ni extensión. Esa
                          // llamada lanzaba `NoSuchMethodError` en CADA build,
                          // el `catch` se lo tragaba en silencio y la función
                          // devolvía siempre null. Aparentaba resolver algo
                          // que nunca resolvió.
                          //
                          // Por qué se deja en null en vez de hacerlo
                          // funcionar: que los pesos llegaran de verdad al
                          // motor cambiaría las recomendaciones que hoy ve el
                          // agricultor. Eso es funcionalidad nueva y no entra
                          // en esta corrección. El comportamiento en runtime
                          // es idéntico al actual; lo que desaparece es la
                          // excepción por build.
                          //
                          // DEUDA PENDIENTE: pasar los pesos por etapa al
                          // motor de nutrición desde esta pantalla.
                          const StageWeights? weights = null;
                          final cultivationScaleId = _resolveCultivationScaleId(
                            cropContext,
                          );

                          NutrientInterpretationResult?
                          interpretNutrientFallback({
                            required AgroMetricKey nutrient,
                            required double rawPpm,
                            required bool hasData,
                            required double? trendPct,
                            required AgroMetricEval? evalMetric,
                          }) {
                            if (!isPlanted || live == null) return null;
                            // Sin sonda de ese canal no hay dato, y ausencia no
                            // es cero: un 0 crudo sale de `interpret` como
                            // `actionRecommended`, la peor etiqueta de
                            // deficiencia. Devolver null es lo correcto: los
                            // consumidores de abajo ya tratan el nulo.
                            if (!hasData) return null;
                            // Se calcula SIEMPRE, no sólo como respaldo: es
                            // la única interpretación que recibe la escala
                            // de cultivo y por tanto la unidad correcta.
                            return NutrientRecommendationEngine.interpret(
                              nutrient: nutrient,
                              rawPpm: rawPpm,
                              cropKey: runtime.cropKeyName,
                              stageKey: stageKey,
                              profileId: runtime.profile?.id,
                              varietyId: cropContext?.varietyId,
                              varietyAlias: cropContext?.varietyAlias,
                              calendarId: cropContext?.calendarTypeId,
                              targets: targets,
                              weights: weights,
                              cultivationScaleId: cultivationScaleId,
                              ph: live.ph,
                              ec: live.ec,
                              soilMoisturePct: live.hasSoilMoistureData ? live.soilMoisturePct : null,
                              trendPct: trendPct,
                            );
                          }

                          // ─────────────────────────────────────────────────
                          // O3 · Una sola ordenación del historial por build.
                          // ─────────────────────────────────────────────────
                          //
                          // Antes se llamaba seis veces a `_statsForChannel`
                          // y cada llamada hacía su propio
                          // `[...history7d]..sort(...)`. Con la ventana llena
                          // (`TelemetryLocalStorage.defaultCap = 2000`) eso
                          // era, POR BUILD: 6 copias de lista (12.000
                          // referencias), 6 ordenaciones ≈ **131.400 llamadas
                          // a `DateTime.compareTo`** y 12 pasadas
                          // `map/toList` ≈ 24.000 dobles boxeados. A ~2
                          // builds/s con BioG simulado, ~264.000
                          // comparaciones por segundo en el hilo de UI.
                          //
                          // Ahora: 1 copia, 1 ordenación, 1 pasada que llena
                          // las tres series. El orden resultante es el mismo
                          // —`List.sort` de Dart es determinista— así que
                          // todas las cifras derivadas salen idénticas.
                          final sortedHistory = [...history7d]
                            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

                          final nSeries = <double>[];
                          final pSeries = <double>[];
                          final kSeries = <double>[];
                          for (final t in sortedHistory) {
                            // Mismo saneo que hacía el `.map()` anterior:
                            // los negativos se recortan a 0. NaN no cumple
                            // `< 0` y pasa tal cual, igual que antes.
                            final nv = t.n.toDouble();
                            final pv = t.p.toDouble();
                            final kv = t.k.toDouble();
                            nSeries.add(nv < 0 ? 0.0 : nv);
                            pSeries.add(pv < 0 ? 0.0 : pv);
                            kSeries.add(kv < 0 ? 0.0 : kv);
                          }

                          // La tendencia era el ÚNICO dato que se sacaba de
                          // los antiguos `nBase`/`pBase`/`kBase`: alimentaba
                          // a `interpret` y volvía a calcularse igual en la
                          // segunda ronda. Se calcula una vez y se usa en los
                          // dos sitios; el valor es el mismo porque
                          // `_trendPctFromSeries` es pura y la serie es la
                          // misma.
                          final nTrendPct = _trendPctFromSeries(nSeries);
                          final pTrendPct = _trendPctFromSeries(pSeries);
                          final kTrendPct = _trendPctFromSeries(kSeries);

                          final nInterpretation = live == null
                              ? null
                              : interpretNutrientFallback(
                                  nutrient: AgroMetricKey.n,
                                  rawPpm: live.n.toDouble(),
                                  hasData: live.hasNitrogenData,
                                  trendPct: nTrendPct,
                                  evalMetric: nEvalMetric,
                                );

                          final pInterpretation = live == null
                              ? null
                              : interpretNutrientFallback(
                                  nutrient: AgroMetricKey.p,
                                  rawPpm: live.p.toDouble(),
                                  hasData: live.hasPhosphorusData,
                                  trendPct: pTrendPct,
                                  evalMetric: pEvalMetric,
                                );

                          final kInterpretation = live == null
                              ? null
                              : interpretNutrientFallback(
                                  nutrient: AgroMetricKey.k,
                                  rawPpm: live.k.toDouble(),
                                  hasData: live.hasPotassiumData,
                                  trendPct: kTrendPct,
                                  evalMetric: kEvalMetric,
                                );

                          final n = _statsForChannel(
                            channel: NpkChannel.n,
                            live: live,
                            series: nSeries,
                            trendPct: nTrendPct,
                            targets: targets,
                            allowStageInterpretation: isPlanted,
                            cropKey: runtime.cropKeyName,
                            evalMetric: nEvalMetric,
                            interpretation: nInterpretation,
                          );

                          final p = _statsForChannel(
                            channel: NpkChannel.p,
                            live: live,
                            series: pSeries,
                            trendPct: pTrendPct,
                            targets: targets,
                            allowStageInterpretation: isPlanted,
                            cropKey: runtime.cropKeyName,
                            evalMetric: pEvalMetric,
                            interpretation: pInterpretation,
                          );

                          final k = _statsForChannel(
                            channel: NpkChannel.k,
                            live: live,
                            series: kSeries,
                            trendPct: kTrendPct,
                            targets: targets,
                            allowStageInterpretation: isPlanted,
                            cropKey: runtime.cropKeyName,
                            evalMetric: kEvalMetric,
                            interpretation: kInterpretation,
                          );

                          final stageLabel = isPlanted
                              ? 'Etapa: ${runtime.stageLabel}'
                              : isPlanned
                              ? 'Pre-siembra'
                              : isGuide
                              ? 'Guía general'
                              : 'Modo genérico';

                          final nDoseGuide =
                              nInterpretation?.doseGuideEs ??
                                    nEvalMetric?.doseGuideEs;
                          final pDoseGuide =
                              pInterpretation?.doseGuideEs ??
                                    pEvalMetric?.doseGuideEs;
                          final kDoseGuide =
                              kInterpretation?.doseGuideEs ??
                                    kEvalMetric?.doseGuideEs;

                          final nFertilizerEquivalent =
                              nInterpretation?.fertilizerEquivalentEs ??
                                    nEvalMetric?.fertilizerEquivalentEs;
                          final pFertilizerEquivalent =
                              pInterpretation?.fertilizerEquivalentEs ??
                                    pEvalMetric?.fertilizerEquivalentEs;
                          final kFertilizerEquivalent =
                              kInterpretation?.fertilizerEquivalentEs ??
                                    kEvalMetric?.fertilizerEquivalentEs;

                          // Lenguaje de NPK: estimación, no medición absoluta.
                          //
                          // Estos textos decían 'Lectura real de N/P/K'. El
                          // sensor NPK de Bio-G es aproximado (±10 %): sirve
                          // para leer tendencias y decidir, no para afirmar el
                          // contenido exacto del suelo. Llamarlo "real" era
                          // prometer una precisión que el hardware no da.
                          //
                          // Lo que NO se hace aquí, a propósito: mandar al
                          // agricultor al laboratorio, hablar de validación
                          // pendiente o sugerir que el dato no es confiable.
                          // El dato es útil y se presenta como lo que es: una
                          // estimación por sensor. La honestidad está en la
                          // palabra "estimado", no en anular la herramienta.
                          final insightN = isPlanted
                              ? (nEvalMetric?.shortRecommendationEs ??
                                    nInterpretation?.shortRecommendation ??
                                    'Nitrógeno disponible estimado por sensor.')
                              : isPlanned
                              ? 'Nitrógeno disponible estimado en pre-siembra.'
                              : 'Lectura disponible sin cultivo asignado.';

                          final insightP = isPlanted
                              ? (pEvalMetric?.shortRecommendationEs ??
                                    pInterpretation?.shortRecommendation ??
                                    'Fósforo disponible estimado por sensor.')
                              : isPlanned
                              ? 'Fósforo disponible estimado en pre-siembra.'
                              : 'Lectura disponible sin cultivo asignado.';

                          final insightK = isPlanted
                              ? (kEvalMetric?.shortRecommendationEs ??
                                    kInterpretation?.shortRecommendation ??
                                    'Potasio disponible estimado por sensor.')
                              : isPlanned
                              ? 'Potasio disponible estimado en pre-siembra.'
                              : 'Lectura disponible sin cultivo asignado.';

                          final descN = isPlanted
                              ? (nEvalMetric?.justificationEs ??
                                    nInterpretation?.justification ??
                                    'Nitrógeno disponible estimado por sensor.')
                              : 'Nitrógeno disponible estimado por sensor. Asigna un cultivo para convertirlo en recomendación nutricional.';

                          final descP = isPlanted
                              ? (pEvalMetric?.justificationEs ??
                                    pInterpretation?.justification ??
                                    'Fósforo disponible estimado por sensor.')
                              : 'Fósforo disponible estimado por sensor. Asigna un cultivo para convertirlo en recomendación nutricional.';

                          final descK = isPlanted
                              ? (kEvalMetric?.justificationEs ??
                                    kInterpretation?.justification ??
                                    'Potasio disponible estimado por sensor.')
                              : 'Potasio disponible estimado por sensor. Asigna un cultivo para convertirlo en recomendación nutricional.';

                          final actionNRaw = isPlanted
                              ? (nInterpretation?.practicalRecommendation ??
                                    nEvalMetric?.practicalRecommendationEs ??
                                    'Revisa el plan nutricional del lote.')
                              : isPlanned
                              ? 'Úsalo como línea base antes de sembrar.'
                              : 'Configura un cultivo para ver prioridad nutricional.';

                          final actionPRaw = isPlanted
                              ? (pInterpretation?.practicalRecommendation ??
                                    pEvalMetric?.practicalRecommendationEs ??
                                    'Revisa el plan nutricional del lote.')
                              : isPlanned
                              ? 'Úsalo como línea base antes de sembrar.'
                              : 'Configura un cultivo para ver prioridad nutricional.';

                          final actionKRaw = isPlanted
                              ? (kInterpretation?.practicalRecommendation ??
                                    kEvalMetric?.practicalRecommendationEs ??
                                    'Revisa el plan nutricional del lote.')
                              : isPlanned
                              ? 'Úsalo como línea base antes de sembrar.'
                              : 'Configura un cultivo para ver prioridad nutricional.';

                          final actionN = _cleanMergedActionText(
                            actionNRaw,
                            nDoseGuide,
                          );
                          final actionP = _cleanMergedActionText(
                            actionPRaw,
                            pDoseGuide,
                          );
                          final actionK = _cleanMergedActionText(
                            actionKRaw,
                            kDoseGuide,
                          );

                          final windowN = isPlanted
                              ? (nEvalMetric?.demandWindowLabelEs ??
                                    nInterpretation?.demandWindowLabel ??
                                    'Ventana activa')
                              : isPlanned
                              ? 'Pre-siembra'
                              : 'Sin cultivo';

                          final windowP = isPlanted
                              ? (pEvalMetric?.demandWindowLabelEs ??
                                    pInterpretation?.demandWindowLabel ??
                                    'Ventana activa')
                              : isPlanned
                              ? 'Pre-siembra'
                              : 'Sin cultivo';

                          final windowK = isPlanted
                              ? (kEvalMetric?.demandWindowLabelEs ??
                                    kInterpretation?.demandWindowLabel ??
                                    'Ventana activa')
                              : isPlanned
                              ? 'Pre-siembra'
                              : 'Sin cultivo';

                          // Chip dentro del gauge. Decía 'Lectura real', que
                          // es una promesa que el sensor NPK no sostiene: su
                          // salida es una estimación útil para seguir
                          // tendencias, no una medición de laboratorio.
                          // 'Estimado' dice la verdad, cabe en el mismo pill
                          // (es más corto) y mantiene el registro de las otras
                          // etiquetas de banda.
                          final statusN = isPlanted
                              ? n.bandLabel
                              : 'Estimado';
                          final statusP = isPlanted
                              ? p.bandLabel
                              : 'Estimado';
                          final statusK = isPlanted
                              ? k.bandLabel
                              : 'Estimado';

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
                                  tone: _toneForNutrient(
                                          evalMetric: nEvalMetric,
                                          interpretation: nInterpretation,
                                          cropKey: runtime.cropKeyName,
                                        ),
                                  windowLabel: windowN,
                                  actionText: actionN,
                                  doseGuideText: nDoseGuide,
                                  fertilizerEquivalentText:
                                      nFertilizerEquivalent,
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
                                  capPpm: n.capPpm,
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.p,
                                  percent: p.gaugePercent,
                                  title: 'Fósforo',
                                  description: descP,
                                  stageLabel: stageLabel,
                                  insight: insightP,
                                  tone: _toneForNutrient(
                                          evalMetric: pEvalMetric,
                                          interpretation: pInterpretation,
                                          cropKey: runtime.cropKeyName,
                                        ),
                                  windowLabel: windowP,
                                  actionText: actionP,
                                  doseGuideText: pDoseGuide,
                                  fertilizerEquivalentText:
                                      pFertilizerEquivalent,
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
                                  capPpm: p.capPpm,
                                ),
                                _NpkTabContent(
                                  channel: NpkChannel.k,
                                  percent: k.gaugePercent,
                                  title: 'Potasio',
                                  description: descK,
                                  stageLabel: stageLabel,
                                  insight: insightK,
                                  tone: _toneForNutrient(
                                          evalMetric: kEvalMetric,
                                          interpretation: kInterpretation,
                                          cropKey: runtime.cropKeyName,
                                        ),
                                  windowLabel: windowK,
                                  actionText: actionK,
                                  doseGuideText: kDoseGuide,
                                  fertilizerEquivalentText:
                                      kFertilizerEquivalent,
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
                                  capPpm: k.capPpm,
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
  final int? targetMinPpm;
  final int? targetMaxPpm;
  final int? targetMinPctPainter;
  final int? targetMaxPctPainter;
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
  final NpkChannel channel;
  final String title;
  final double percent;
  final String description;
  final String stageLabel;
  final String insight;
  final InsightTone tone;
  final int? targetMinPctPainter;
  final int? targetMaxPctPainter;
  final int? targetMinPpm;
  final int? targetMaxPpm;
  final int levelPpm;
  final int avg7Ppm;
  final int rangeMin;
  final int rangeMax;
  final double? avgTrendPct;
  final String statusLabel;
  final bool showStageTargets;
  final String windowLabel;
  final String actionText;
  final String? doseGuideText;
  final String? fertilizerEquivalentText;
  final int capPpm;

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
    required this.windowLabel,
    required this.actionText,
    this.doseGuideText,
    this.fertilizerEquivalentText,
    this.avgTrendPct,
    required this.capPpm,
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
                          percent: percent,
                          title: title,
                          description: description,
                          showDescription: false,
                          targetMin: targetMinPctPainter,
                          targetMax: targetMaxPctPainter,
                          statusLabel: statusLabel,
                          centerValue: levelPpm,
                          centerUnit: 'mg/kg',
                          cropCapPpm: capPpm.toDouble(),
                        ),
                      ),
                      const SizedBox(height: 2),
                      _TechWaveScanDivider(accent: accent),
                      const SizedBox(height: 8),
                      _StageInsightPill(
                        accent: accent,
                        headline: insight,
                        stageLabel: stageLabel,
                        tone: tone,
                      ),
                      const SizedBox(height: 6),
                      _TargetLinePpm(
                        accent: accent,
                        minPpm: targetMinPpm,
                        maxPpm: targetMaxPpm,
                        showTargets: showStageTargets,
                        windowLabel: windowLabel,
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                        child: Column(
                          children: [
                            Text(
                              actionText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13.2,
                                fontWeight: FontWeight.w900,
                                height: 1.28,
                                color: Colors.black.withValues(alpha: 0.68),
                              ),
                            ),
                            if ((doseGuideText ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                doseGuideText!.trim(),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12.2,
                                  fontWeight: FontWeight.w900,
                                  height: 1.24,
                                  color: accent.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                            if ((fertilizerEquivalentText ?? '')
                                .trim()
                                .isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                fertilizerEquivalentText!.trim(),
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
                          value: '$levelPpm',
                          unit: 'mg/kg',
                          label: 'Nivel',
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
                          value: '$avg7Ppm',
                          unit: 'mg/kg',
                          label: 'Promedio 7 días',
                          trendPct: avgTrendPct,
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
                          value: '$rangeMin–$rangeMax',
                          unit: 'mg/kg',
                          label: 'Variación',
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

class _TargetLinePpm extends StatelessWidget {
  final Color accent;
  final int? minPpm;
  final int? maxPpm;
  final bool showTargets;
  final String windowLabel;

  const _TargetLinePpm({
    required this.accent,
    required this.minPpm,
    required this.maxPpm,
    required this.showTargets,
    required this.windowLabel,
  });

  @override
  Widget build(BuildContext context) {
    final hasTargets = showTargets && minPpm != null && maxPpm != null;
    final text = windowLabel.isEmpty
        ? (hasTargets
              ? 'Objetivo etapa: $minPpm–$maxPpm mg/kg'
              : 'Ventana actual: no disponible')
        : (hasTargets
              ? 'Ventana actual: $windowLabel · Objetivo: $minPpm–$maxPpm mg/kg'
              : 'Ventana actual: $windowLabel');

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
      // ───────────────────────────────────────────────────────────────────
      // O2 · Aislar este repintado del resto de la pestaña.
      // ───────────────────────────────────────────────────────────────────
      //
      // El controlador de arriba hace `repeat()` y no para nunca: marca este
      // `CustomPaint` como sucio 60 veces por segundo. Sin frontera de
      // repintado, `markNeedsPaint` subía hasta la frontera de la página del
      // `PageView`, que contiene TAMBIÉN el gauge. Y al repintar una capa,
      // `RenderCustomPaint.paint()` NO consulta `shouldRepaint`: llama a
      // `painter.paint()` siempre. Resultado: `_NpkGaugePainter` se ejecutaba
      // 60 veces por segundo aunque su valor no cambiara, con sus 4
      // `MaskFilter.blur`, 21 `drawLine`, 6 `TextPainter().layout()` (=360
      // maquetados de texto por segundo) y un `SweepGradient.createShader()`.
      //
      // Con la frontera, la capa de este divisor se rasteriza sola y el resto
      // de la tarjeta reutiliza su capa cacheada.
      //
      // No cambia un píxel: `RepaintBoundary` no recorta. El halo del glow
      // (`MaskFilter.blur` σ30) desborda de sobra estos 28 dp, y sigue
      // pintándose igual — el rectángulo de la capa es una pista de culling,
      // no un clip, y Skia/Impeller conservan las órdenes de dibujo cuyos
      // límites (ya inflados por el desenfoque) intersecan la capa.
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
