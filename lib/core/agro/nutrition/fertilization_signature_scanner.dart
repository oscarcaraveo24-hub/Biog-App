// lib/core/agro/nutrition/fertilization_signature_scanner.dart
//
// DETECTOR DE FIRMAS DE FERTILIZACIÓN — barrido NO anclado (Guía oficial del
// nuevo motor nutricional v0.4, §12, §13, §30, §31, más la regla de producto:
// «el agricultor no registra que fertilizó; BIO-G lo detecta»).
//
// LO QUE SÍ AFIRMA: «dentro de esta ventana nutricional apareció una respuesta
// del suelo compatible con una fertilización, con confianza X».
// LO QUE NO AFIRMA JAMÁS: «el suelo tiene ahora X ppm de nitrógeno» (§12, §37).
//
// POR QUÉ NO BASTA MIRAR LA CE BRUTA
// ---------------------------------
// La sonda mide conductividad eléctrica APARENTE del suelo, y esa magnitud
// sube con el agua: un suelo mojado conduce más que el mismo suelo seco aunque
// no le hayan puesto nada. Un riego con agua sola produce un salto de CE bruta
// que un detector ingenuo tomaría por fertilización. Por eso el canal primario
// aquí es la CARGA IÓNICA NORMALIZADA POR HUMEDAD (CE / fracción volumétrica de
// agua): un riego la deja igual o la baja; un fertilizante disuelto la sube.
// La CE bruta se conserva como evidencia y para el caso sin sensor de humedad.
//
// POR QUÉ N/P/K NO CONFIRMAN
// --------------------------
// En la sonda 7-en-1 los canales N, P y K se derivan de la misma CE: no son
// evidencia independiente. Aquí entran como COMPROBACIÓN DE CONSISTENCIA: si
// la CE salta y los canales derivados no acompañan, el salto huele a artefacto
// de contacto; si acompañan, la firma es coherente. Nunca cuantifican.
//
// CÓMO LEE UNA FIRMA (multicanal y contextual)
// --------------------------------------------
//   1. Referencia robusta (mediana/MAD, §31) de las 72 h ANTERIORES a cada
//      lectura. Primero se detecta el escalón contra la referencia; después se
//      exige que se sostenga (una lectura aislada no es un evento).
//   2. Varios saltos relacionados dentro de la ventana forman UNA sola firma
//      (dosis partidas, fertirriego en pulsos, mezcla con componente tardío).
//   3. La humedad decide el contexto: fertirriego, disuelto en sitio, agua
//      sola (no cuenta), suelo secándose (se descuenta) o desconocido.
//   4. Sin escalón, se busca la SUBIDA GRADUAL de la urea (§30): la hidrólisis
//      y la nitrificación tardan días. Ausencia de salto el día 0 no significa
//      que no llegó.
//   5. El historial del sitio dice si la magnitud es normal para ESTE punto.
//
// UMBRALES: todos son constantes nombradas y están declarados como pendientes
// de datos reales de eventos (§38). Cambiarlos es subir `responseWindow` en
// `BioGEngineVersions`.
import 'dart:math' as math;

import 'package:bio_g/core/agro/nutrition/nutrition_types.dart';
import 'package:bio_g/core/agro/nutrition/site_learning.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Lo que el barrido necesita. Puro: no toca reloj, red ni disco.
class SignatureScanRequest {
  const SignatureScanRequest({
    required this.history,
    required this.windowStart,
    required this.now,
    this.observeUntil,
    this.siteTypicalEcPeakMad,
    this.isLearningSite = false,
    this.compensateEcTemperature = false,
  });

  /// Historial disponible del dispositivo. Puede (y debe) incluir lecturas
  /// anteriores a [windowStart]: la referencia de las primeras horas sale de
  /// ahí.
  final List<BioGTelemetry> history;

  /// Cuándo abrió la ventana nutricional que se barre.
  final DateTime windowStart;

  final DateTime now;

  /// Hasta cuándo se observa (fin de la ventana + gracia para respuestas
  /// tardías). Null = hasta [now].
  final DateTime? observeUntil;

  /// Respuesta habitual del sitio: mediana de `ecPeakMad` de firmas anteriores
  /// compatibles. Null si no hay historial comparable.
  final double? siteTypicalEcPeakMad;

  /// Sitio en su primera semana: referencias inmaduras, confianza acotada.
  final bool isLearningSite;

  /// Si la sonda entrega CE SIN compensar por temperatura, aquí se lleva a
  /// 25 °C (≈ 2 %/°C) cuando hay temperatura de suelo. El contrato del sensor
  /// (fase 3) declara si hace falta; por omisión se asume compensada.
  final bool compensateEcTemperature;
}

/// Resultado del barrido de una ventana.
class FertilizationSignatureScan {
  const FertilizationSignatureScan({
    required this.observability,
    required this.signatures,
    required this.readingsInRange,
    required this.usableReadings,
    required this.observedFraction,
    required this.usedMoistureNormalization,
    required this.summaryEs,
    this.baselineLessFraction = 0.0,
    this.evidenceEs = const <String>[],
  });

  final ScanObservability observability;

  /// Firmas encontradas, de mayor a menor confianza.
  final List<FertilizationSignature> signatures;

  /// Lecturas de cualquier tipo dentro del rango barrido.
  final int readingsInRange;

  /// Lecturas con CE utilizable (humedad por encima de la puerta dura).
  final int usableReadings;

  /// Fracción 0..1 del tiempo barrido con lecturas utilizables.
  final double observedFraction;

  /// True si el canal primario fue la carga iónica normalizada por humedad.
  final bool usedMoistureNormalization;

  /// Fracción 0..1 de las lecturas utilizables que NO tenían una referencia
  /// previa suficiente (72 h con al menos [RobustStats.minCount] lecturas y
  /// [FertilizationSignatureScanner.minBaselineSpan] de extensión). Una sonda
  /// recién instalada empieza con esta fracción alta: no puede juzgar
  /// ausencia contra una referencia que todavía no existe.
  final double baselineLessFraction;

  final String summaryEs;
  final List<String> evidenceEs;

  FertilizationSignature? get best =>
      signatures.isEmpty ? null : signatures.first;

  bool get hasCompatibleSignature => best?.isCompatible ?? false;
  bool get hasPossibleSignature => best?.isPossible ?? false;

  /// La ventana fue lo bastante observable para afirmar honestamente «no hubo
  /// evidencia». Sin esto, el cierre es inconcluso y no penaliza (§6).
  bool get canJudgeAbsence =>
      observability.isOk &&
      observedFraction >= FertilizationSignatureScanner.minObservedFraction &&
      usableReadings >= FertilizationSignatureScanner.minUsableReadings &&
      baselineLessFraction <=
          FertilizationSignatureScanner.maxBaselineLessFraction;
}

class FertilizationSignatureScanner {
  const FertilizationSignatureScanner._();

  // ── Umbrales (pendientes de datos reales, Guía v0.4 §38) ──────────────────

  /// Horas de referencia antes de cada lectura.
  static const Duration baselineSpan = Duration(hours: 72);

  /// Margen inmediatamente anterior que no entra a la referencia.
  static const Duration baselineGuard = Duration(minutes: 30);

  /// Puerta dura de humedad: por debajo la CE no se usa para nada nutrimental.
  static const double vwcHardGatePct = 20.0;

  /// MAD a partir de las cuales una lectura se considera elevada.
  static const double minorMad = 2.0;

  /// MAD a partir de las cuales el salto se considera fuerte.
  static const double strongMad = 4.0;

  /// Cuánto debe sostenerse un salto para ser evento y no ruido.
  static const Duration sustainSpan = Duration(hours: 24);

  /// Fracción de lecturas elevadas dentro de [sustainSpan] para confirmar.
  static const double sustainFraction = 0.5;

  /// Dos lecturas elevadas dentro de este plazo son el MISMO salto.
  static const Duration sameJumpSpan = Duration(hours: 24);

  /// Saltos separados por menos de esto pertenecen a la misma firma.
  static const Duration groupingSpan = Duration(days: 10);

  /// Cambio de humedad (puntos de VWC) que se lee como «entró agua».
  static const double vwcRisePts = 2.0;

  /// Caída de humedad que se lee como «suelo secándose».
  static const double vwcDropPts = 3.0;

  /// Tamaño del cubo para medir cobertura temporal.
  static const Duration coverageBin = Duration(hours: 6);

  /// Cobertura mínima para poder juzgar ausencia de evidencia.
  static const double minObservedFraction = 0.5;

  /// Lecturas utilizables mínimas para poder juzgar ausencia de evidencia.
  static const int minUsableReadings = 24;

  /// Extensión mínima (primera a última lectura) de una referencia para que
  /// cuente como tal: seis lecturas en una hora no son «las 72 h previas».
  static const Duration minBaselineSpan = Duration(hours: 24);

  /// Fracción máxima de lecturas sin referencia para poder juzgar ausencia:
  /// por encima, la ventana se observó pero sin contra qué comparar.
  static const double maxBaselineLessFraction = 0.25;

  /// Ventana corta previa a una lectura para medir la FORMA del cambio.
  static const Duration localJumpSpan = Duration(hours: 6);

  /// Fracción de la elevación total que debe haber ocurrido dentro de
  /// [localJumpSpan] para que la lectura cuente como escalón. Un fertirriego
  /// sube de golpe (≈100 %); una subida gradual de urea reparte la elevación
  /// en días y no pasa de un tercio.
  static const double minLocalJumpFraction = 0.5;

  /// Días mínimos de ventana para buscar la subida gradual de la urea.
  static const int gradualMinDays = 4;

  /// Confianza máxima de una firma gradual (nunca tan segura como un escalón).
  static const double gradualMaxConfidence = 0.75;

  /// Confianza máxima de una firma cuyo sostenimiento aún no se pudo comprobar
  /// (salto en las últimas horas): puede ser «posible», nunca «compatible».
  static const double provisionalMaxConfidence = 0.59;

  /// Confianza máxima sin humedad utilizable: la CE bruta sube con el agua
  /// (un riego fuerte que lleve el suelo del 20 % al 40 % de VWC puede
  /// duplicarla), así que sin normalizar NUNCA se declara «compatible». Una
  /// firma así queda en «posible»: la ventana cierra inconclusa y no penaliza,
  /// pero tampoco se da por atendida (Guía v0.4 §37.5).
  static const double noMoistureMaxConfidence = 0.59;

  /// Percentil del post-evento que se compara contra la referencia. El 90 % y
  /// no el máximo: un solo pico de ruido no debe declarar respuesta.
  static const double postPercentile = 0.90;

  /// Barre la ventana y devuelve lo que el sensor parece haber visto.
  static FertilizationSignatureScan scan(SignatureScanRequest r) {
    final DateTime scanStart = r.windowStart;
    final DateTime limit = r.observeUntil ?? r.now;
    final DateTime scanEnd = limit.isBefore(r.now) ? limit : r.now;

    final List<BioGTelemetry> sorted = r.history
        .where((BioGTelemetry t) => !t.timestamp.isAfter(scanEnd))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final List<BioGTelemetry> inRange = sorted
        .where((BioGTelemetry t) => !t.timestamp.isBefore(scanStart))
        .toList();

    if (inRange.isEmpty) {
      return _empty(
        ScanObservability.noReadings,
        'No hubo lecturas de la sonda durante la ventana: no se puede decir '
        'qué ocurrió en la zona de raíces.',
      );
    }
    final List<BioGTelemetry> withEc =
        inRange.where((BioGTelemetry t) => t.hasEcData).toList();
    if (withEc.isEmpty) {
      return _empty(
        ScanObservability.noEcChannel,
        'El dispositivo no aportó conductividad eléctrica en la ventana: sin '
        'CE no se puede observar una respuesta a fertilización.',
      );
    }

    // ¿Normalizamos por humedad? Solo si la gran mayoría de las lecturas de CE
    // traen humedad; mezclar cociente y CE bruta en una misma serie sería
    // comparar peras con manzanas.
    final int withVwc = withEc.where((t) => t.hasSoilMoistureData).length;
    final bool normalize = withVwc >= (withEc.length * 0.8).ceil();

    final List<_Sample> all = <_Sample>[];
    for (final BioGTelemetry t in sorted) {
      final _Sample? s = _sample(t, normalize: normalize, request: r);
      if (s != null) all.add(s);
    }
    final List<_Sample> usable =
        all.where((_Sample s) => !s.ts.isBefore(scanStart)).toList();

    if (usable.length < math.max(3, withEc.length ~/ 3)) {
      return FertilizationSignatureScan(
        observability: ScanObservability.tooDry,
        signatures: const <FertilizationSignature>[],
        readingsInRange: inRange.length,
        usableReadings: usable.length,
        observedFraction: _coverage(usable, scanStart, scanEnd),
        usedMoistureNormalization: normalize,
        summaryEs:
            'El suelo estuvo por debajo de ${vwcHardGatePct.round()} % de '
            'humedad la mayor parte de la ventana: en seco la CE no sirve para '
            'leer una respuesta. Con riego, la sonda podrá observar lo que llegó '
            'a la raíz.',
      );
    }

    final double coverage = _coverage(usable, scanStart, scanEnd);

    // ── 1. Saltos sostenidos ──────────────────────────────────────────────────
    final List<_Onset> onsets = <_Onset>[];
    int withoutBaseline = 0;
    _Onset? previous;
    for (final _Sample s in usable) {
      final RobustStats? base = _baselineBefore(all, s.ts, (x) => x.primary);
      if (base == null || !base.isUsable) {
        withoutBaseline++;
        continue;
      }
      final double z = base.z(s.primary);
      if (z < minorMad) continue;

      // Forma del cambio: un escalón concentra la elevación en las últimas
      // horas; una subida gradual (urea) la reparte en días y, aunque acabe
      // superando la referencia, NO es un salto: la busca el paso 3.
      if (!_isStepShaped(all, s, base)) continue;

      // ¿Es el mismo salto que el anterior, o su meseta?
      if (previous != null) {
        final Duration sincePrev = s.ts.difference(previous.at);
        if (sincePrev <= sameJumpSpan) continue;
        final RobustStats? plateau = _statsBetween(
          all,
          previous.at.add(const Duration(hours: 6)),
          s.ts.subtract(baselineGuard),
          (x) => x.primary,
        );
        if (plateau != null && plateau.isUsable) {
          if (plateau.z(s.primary) < minorMad) continue; // meseta, no salto
        } else if (sincePrev <= baselineSpan) {
          // Sin meseta medible y todavía dentro de la referencia contaminada:
          // se trata como el mismo salto.
          continue;
        }
      }

      // Sostenimiento: el salto debe seguir ahí en las horas siguientes.
      final List<_Sample> following = all
          .where(
            (x) =>
                x.ts.isAfter(s.ts) &&
                !x.ts.isAfter(s.ts.add(sustainSpan)) &&
                !x.ts.isAfter(scanEnd),
          )
          .toList();
      bool provisional = false;
      double sustained;
      if (following.length >= 2) {
        final int elevated =
            following.where((x) => base.z(x.primary) >= minorMad).length;
        sustained = elevated / following.length;
        if (sustained < sustainFraction) continue; // pico aislado
      } else if (following.isEmpty) {
        // Salto en las últimas horas: todavía no se puede comprobar.
        if (scanEnd.difference(s.ts) > sustainSpan) continue; // hueco: no fiable
        provisional = true;
        sustained = 0.5;
      } else {
        sustained = base.z(following.first.primary) >= minorMad ? 1.0 : 0.0;
        if (sustained == 0.0) continue;
      }

      final _Onset onset = _Onset(
        at: s.ts,
        z: z,
        base: base,
        sustained: sustained,
        provisional: provisional,
      );
      onsets.add(onset);
      previous = onset;
    }

    // ── 2. Agrupar saltos relacionados en firmas ──────────────────────────────
    final List<List<_Onset>> groups = <List<_Onset>>[];
    for (final _Onset o in onsets) {
      if (groups.isNotEmpty &&
          o.at.difference(groups.last.last.at) <= groupingSpan) {
        groups.last.add(o);
      } else {
        groups.add(<_Onset>[o]);
      }
    }

    final List<FertilizationSignature> signatures = <FertilizationSignature>[];
    for (final List<_Onset> g in groups) {
      final FertilizationSignature? sig = _buildStepSignature(
        group: g,
        all: all,
        scanEnd: scanEnd,
        request: r,
        normalize: normalize,
      );
      if (sig != null) signatures.add(sig);
    }

    // ── 3. Sin escalón compatible: ¿subida gradual (urea)? ────────────────────
    final bool anyCompatible = signatures.any((s) => s.isCompatible);
    if (!anyCompatible &&
        scanEnd.difference(scanStart).inDays >= gradualMinDays &&
        coverage >= 0.4) {
      final FertilizationSignature? gradual = _buildGradualSignature(
        all: all,
        scanStart: scanStart,
        scanEnd: scanEnd,
        request: r,
        normalize: normalize,
      );
      if (gradual != null) signatures.add(gradual);
    }

    signatures.sort((a, b) => b.confidence01.compareTo(a.confidence01));

    final double baselineLess =
        usable.isEmpty ? 1.0 : (withoutBaseline / usable.length).clamp(0.0, 1.0);
    final ScanObservability observability =
        (signatures.isEmpty && baselineLess > maxBaselineLessFraction)
            ? ScanObservability.insufficientBaseline
            : ScanObservability.ok;

    final List<String> evidence = <String>[
      'Lecturas en la ventana: ${inRange.length}; utilizables para CE: '
          '${usable.length}; cobertura temporal ${(coverage * 100).round()} %.',
      normalize
          ? 'Las sales se leyeron descontando el agua de riego, para no confundir '
              'un riego con una fertilización.'
          : 'Sin lectura de humedad suficiente: las sales se leyeron sin descontar '
              'el agua, así que un riego con agua sola podría parecer fertilización.',
      if (r.siteTypicalEcPeakMad != null)
        'BIO-G ya conoce la respuesta habitual de este sitio y la usa para '
            'comparar la magnitud.',
      if (baselineLess > 0)
        'Lecturas sin referencia previa suficiente: '
            '${(baselineLess * 100).round()} %.',
    ];

    return FertilizationSignatureScan(
      observability: observability,
      signatures: List<FertilizationSignature>.unmodifiable(signatures),
      readingsInRange: inRange.length,
      usableReadings: usable.length,
      observedFraction: coverage,
      usedMoistureNormalization: normalize,
      baselineLessFraction: baselineLess,
      summaryEs: _summary(signatures, observability, coverage),
      evidenceEs: evidence,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FIRMA POR ESCALÓN
  // ═════════════════════════════════════════════════════════════════════════

  static FertilizationSignature? _buildStepSignature({
    required List<_Onset> group,
    required List<_Sample> all,
    required DateTime scanEnd,
    required SignatureScanRequest request,
    required bool normalize,
  }) {
    if (group.isEmpty) return null;
    final _Onset first = group.first;
    final _Onset last = group.last;
    final RobustStats base = first.base;

    // Horizonte de respuesta provisional (el tipo se decide abajo).
    final SignatureKind kind = group.length >= 2
        ? SignatureKind.mixed
        : SignatureKind.ionicImmediate;
    final DateTime horizonEnd =
        last.at.add(Duration(days: kind.responseHorizonDays));
    final DateTime postEnd = horizonEnd.isBefore(scanEnd) ? horizonEnd : scanEnd;
    final List<_Sample> post = all
        .where((s) => !s.ts.isBefore(first.at) && !s.ts.isAfter(postEnd))
        .toList();
    if (post.isEmpty) return null;

    // Magnitud: percentil 90 del post contra la referencia PRE-firma.
    final double ecPeakMad = _percentileZ(post.map((s) => s.primary), base);
    _Sample peak = post.first;
    for (final _Sample s in post) {
      if (s.primary > peak.primary) peak = s;
    }

    // CE bruta, para trazabilidad y para el test de «agua sola».
    final RobustStats? rawBase = _baselineBefore(all, first.at, (x) => x.ecRaw);
    final double? ecRawPeakMad = rawBase == null || !rawBase.isUsable
        ? null
        : _percentileZ(post.map((s) => s.ecRaw), rawBase);

    // Canales derivados: acompañan, no confirman.
    final double? nZ = _channelZ(all, first.at, post, (s) => s.n);
    final double? pZ = _channelZ(all, first.at, post, (s) => s.p);
    final double? kZ = _channelZ(all, first.at, post, (s) => s.k);

    // Humedad alrededor del primer salto.
    final double? vwcDelta = _vwcDelta(all, first.at);
    final VwcContext context = _vwcContext(
      normalize: normalize,
      vwcDelta: vwcDelta,
      zNorm: ecPeakMad,
      zRaw: ecRawPeakMad,
    );

    final double sustained =
        group.map((o) => o.sustained).reduce(math.max).clamp(0.0, 1.0);
    final bool provisional = group.every((o) => o.provisional);

    final double confidence = _confidence(
      ecScore: _ecScore(ecPeakMad),
      sustained: sustained,
      context: context,
      nZ: nZ,
      pZ: pZ,
      kZ: kZ,
      typical: request.siteTypicalEcPeakMad,
      peak: ecPeakMad,
      learning: request.isLearningSite,
      provisional: provisional,
      normalize: normalize,
      maxConfidence: 1.0,
    );

    // Evidencia en lenguaje de campo: qué se vio y cuándo. Las magnitudes
    // estadísticas (MAD) viven en los campos numéricos de la firma, no en el
    // texto que lee el agricultor.
    final List<String> evidence = <String>[
      '${_magnitudeEs(ecPeakMad)} de las sales en la zona de raíces '
          '${normalize ? 'una vez descontada el agua de riego' : '(sin descontar el agua: no hubo lectura de humedad suficiente)'}, '
          'sostenida en ${post.length} lecturas después del primer salto.',
      'Primer salto el ${_fmtDateTime(first.at)}'
          '${group.length > 1 ? '; ${group.length} aportes relacionados leídos como una sola aplicación (último: ${_fmtDateTime(last.at)}).' : '.'}',
      if (vwcDelta != null)
        'Humedad del suelo ${vwcDelta >= 0 ? '+' : ''}${vwcDelta.toStringAsFixed(1)} '
            'puntos alrededor del salto: ${context.labelEs.toLowerCase()}.',
      if (vwcDelta == null) 'Humedad del suelo: ${context.labelEs.toLowerCase()}.',
      _followLine('N', nZ),
      _followLine('P', pZ),
      _followLine('K', kZ),
      if (provisional)
        'El salto es de las últimas horas: falta comprobar que se sostiene.',
      if (request.isLearningSite)
        'Sitio en aprendizaje: la referencia todavía es joven; confianza acotada.',
    ].where((String s) => s.isNotEmpty).toList();

    return FertilizationSignature(
      startedAt: first.at,
      lastJumpAt: last.at,
      peakAt: peak.ts,
      kind: kind,
      confidence01: confidence,
      ecPeakMad: ecPeakMad,
      ecRawPeakMad: ecRawPeakMad,
      vwcContext: context,
      jumpCount: group.length,
      nFollowMad: nZ,
      pFollowMad: pZ,
      kFollowMad: kZ,
      vwcDeltaPct: vwcDelta,
      evidenceEs: evidence,
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // FIRMA GRADUAL (UREA)
  // ═════════════════════════════════════════════════════════════════════════

  static FertilizationSignature? _buildGradualSignature({
    required List<_Sample> all,
    required DateTime scanStart,
    required DateTime scanEnd,
    required SignatureScanRequest request,
    required bool normalize,
  }) {
    // Referencia: 72 h antes de la ventana + primeras 48 h de la ventana.
    final RobustStats? ref = _statsBetween(
      all,
      scanStart.subtract(baselineSpan),
      scanStart.add(const Duration(hours: 48)),
      (s) => s.primary,
    );
    if (ref == null || !ref.isUsable) return null;

    final DateTime tailStart = scanEnd.subtract(const Duration(hours: 48));
    if (!tailStart.isAfter(scanStart.add(const Duration(hours: 48)))) {
      return null;
    }
    final List<_Sample> tail =
        all.where((s) => !s.ts.isBefore(tailStart) && !s.ts.isAfter(scanEnd)).toList();
    if (tail.length < 3) return null;

    final RobustStats? tailStats =
        RobustStats.fromValues(tail.map((s) => s.primary));
    if (tailStats == null) return null;
    final double zGradual = ref.z(tailStats.median);
    if (zGradual < minorMad) return null;

    // Tendencia: el tramo medio debe quedar entre la referencia y la cola
    // (subida progresiva, no un escalón tardío que ya habría visto el paso 1).
    final DateTime midStart = scanStart.add(const Duration(hours: 48));
    final RobustStats? mid = _statsBetween(all, midStart, tailStart, (s) => s.primary);
    if (mid != null && mid.count >= 3) {
      final double zMid = ref.z(mid.median);
      if (zMid < 0.5 || zMid > zGradual + 1.0) return null;
    }

    // Humedad: si el régimen de riego cambió, la subida está confundida.
    final RobustStats? vwcRef = _statsBetween(
      all,
      scanStart.subtract(baselineSpan),
      scanStart.add(const Duration(hours: 48)),
      (s) => s.vwc,
    );
    final RobustStats? vwcTail = RobustStats.fromValues(
      tail.where((s) => s.vwc != null).map((s) => s.vwc!),
    );
    double? vwcDelta;
    if (vwcRef != null && vwcTail != null) {
      vwcDelta = vwcTail.median - vwcRef.median;
    }
    final VwcContext context = !normalize
        ? VwcContext.unknown
        : (vwcDelta == null
            ? VwcContext.unknown
            : (vwcDelta >= 4.0
                ? VwcContext.fertigationLike
                : (vwcDelta <= -vwcDropPts
                    ? VwcContext.dryingArtifact
                    : VwcContext.dissolvedInPlace)));

    // Canales derivados, mismo método.
    double? gradualChannel(double? Function(_Sample) pick) {
      final RobustStats? cRef = _statsBetween(
        all,
        scanStart.subtract(baselineSpan),
        scanStart.add(const Duration(hours: 48)),
        pick,
      );
      final RobustStats? cTail = RobustStats.fromValues(
        tail.map(pick).whereType<double>(),
      );
      if (cRef == null || !cRef.isUsable || cTail == null) return null;
      return cRef.z(cTail.median);
    }

    final double? nZ = gradualChannel((s) => s.n);
    final double? pZ = gradualChannel((s) => s.p);
    final double? kZ = gradualChannel((s) => s.k);

    // Inicio: primera lectura desde la que el tramo siguiente ya va por
    // encima de la referencia.
    DateTime startedAt = midStart;
    for (final _Sample s in all) {
      if (s.ts.isBefore(midStart) || s.ts.isAfter(tailStart)) continue;
      final RobustStats? next = _statsBetween(
        all,
        s.ts,
        s.ts.add(const Duration(hours: 24)),
        (x) => x.primary,
      );
      if (next != null && next.count >= 2 && ref.z(next.median) >= 1.0) {
        startedAt = s.ts;
        break;
      }
    }
    _Sample peak = tail.first;
    for (final _Sample s in tail) {
      if (s.primary > peak.primary) peak = s;
    }

    final double confidence = _confidence(
      ecScore: _ecScore(zGradual) * 0.6 + 0.1,
      sustained: 1.0,
      context: context,
      nZ: nZ,
      pZ: pZ,
      kZ: kZ,
      typical: request.siteTypicalEcPeakMad,
      peak: zGradual,
      learning: request.isLearningSite,
      provisional: false,
      normalize: normalize,
      maxConfidence: gradualMaxConfidence,
    );

    return FertilizationSignature(
      startedAt: startedAt,
      lastJumpAt: startedAt,
      peakAt: peak.ts,
      kind: SignatureKind.delayedGradual,
      confidence01: confidence,
      ecPeakMad: zGradual,
      vwcContext: context,
      nFollowMad: nZ,
      pFollowMad: pZ,
      kFollowMad: kZ,
      vwcDeltaPct: vwcDelta,
      evidenceEs: <String>[
        '${_magnitudeEs(zGradual)} gradual de las sales en la zona de raíces a lo '
            'largo de varios días, sin un salto brusco: es el patrón de la urea '
            'y de otras fuentes de liberación lenta.',
        if (vwcDelta != null)
          'Humedad del suelo ${vwcDelta >= 0 ? '+' : ''}${vwcDelta.toStringAsFixed(1)} '
              'puntos entre inicio y final: ${context.labelEs.toLowerCase()}.',
        _followLine('N', nZ),
        _followLine('P', pZ),
        _followLine('K', kZ),
        'Una subida gradual nunca alcanza confianza alta por sí sola: el sitio '
            'necesita más ventanas para conocer su patrón.',
      ].where((String s) => s.isNotEmpty).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // CONFIANZA
  // ═════════════════════════════════════════════════════════════════════════

  /// 0 en [minorMad], 1 en [strongMad].
  static double _ecScore(double z) =>
      ((z - minorMad) / (strongMad - minorMad)).clamp(0.0, 1.0);

  /// Combinación ponderada. Pesos: CE 0.50 · humedad 0.15 · N 0.15 · P 0.05 ·
  /// K 0.05 · historial 0.10. Multiplicadores: agua sola ×0.3, secándose
  /// ×0.6, aprendizaje ×0.85. Topes: provisional, sin humedad, gradual.
  static double _confidence({
    required double ecScore,
    required double sustained,
    required VwcContext context,
    required double? nZ,
    required double? pZ,
    required double? kZ,
    required double? typical,
    required double peak,
    required bool learning,
    required bool provisional,
    required bool normalize,
    required double maxConfidence,
  }) {
    final double vwcScore = switch (context) {
      VwcContext.fertigationLike => 1.0,
      VwcContext.dissolvedInPlace => 0.8,
      VwcContext.unknown => 0.4,
      VwcContext.dryingArtifact => 0.2,
      VwcContext.waterOnly => 0.0,
    };
    double follow(double? z) =>
        z == null ? 0.3 : ((z - 1.0) / 2.0).clamp(0.0, 1.0);
    final double history = typical == null || typical <= 0
        ? 0.5
        : (peak / typical).clamp(0.0, 1.0);

    double c = 0.50 * ecScore * (0.6 + 0.4 * sustained) +
        0.15 * vwcScore +
        0.15 * follow(nZ) +
        0.05 * follow(pZ) +
        0.05 * follow(kZ) +
        0.10 * history;

    if (context == VwcContext.waterOnly) c *= 0.3;
    if (context == VwcContext.dryingArtifact) c *= 0.6;
    if (learning) c *= 0.85;
    if (provisional) c = math.min(c, provisionalMaxConfidence);
    if (!normalize) c = math.min(c, noMoistureMaxConfidence);
    return c.clamp(0.0, maxConfidence);
  }

  static VwcContext _vwcContext({
    required bool normalize,
    required double? vwcDelta,
    required double zNorm,
    required double? zRaw,
  }) {
    if (!normalize || vwcDelta == null) return VwcContext.unknown;
    if (vwcDelta >= vwcRisePts) {
      // Entró agua. Si la CE bruta subió mucho más que la normalizada, fue
      // el agua la que subió la conductividad: riego solo.
      if (zRaw != null && zRaw > 0 && zNorm < 0.5 * zRaw) {
        return VwcContext.waterOnly;
      }
      return VwcContext.fertigationLike;
    }
    if (vwcDelta <= -vwcDropPts) return VwcContext.dryingArtifact;
    return VwcContext.dissolvedInPlace;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // UTILIDADES ESTADÍSTICAS
  // ═════════════════════════════════════════════════════════════════════════

  static _Sample? _sample(
    BioGTelemetry t, {
    required bool normalize,
    required SignatureScanRequest request,
  }) {
    if (!t.hasEcData) return null;
    double ec = t.ec;
    if (request.compensateEcTemperature && t.hasSoilTempData) {
      final double factor = 1.0 + 0.02 * (t.soilTempC - 25.0);
      if (factor > 0.2) ec = ec / factor;
    }
    final double? vwc = t.hasSoilMoistureData ? t.soilMoisturePct : null;
    if (vwc != null && vwc < vwcHardGatePct) return null; // puerta dura
    final double primary;
    if (normalize) {
      if (vwc == null) return null;
      primary = ec / math.max(vwc / 100.0, 0.01);
    } else {
      primary = ec;
    }
    return _Sample(
      ts: t.timestamp,
      primary: primary,
      ecRaw: ec,
      vwc: vwc,
      n: t.hasNitrogenData ? t.n : null,
      p: t.hasPhosphorusData ? t.p : null,
      k: t.hasPotassiumData ? t.k : null,
    );
  }

  /// Referencia de las 72 h previas a [at] (menos el margen de guarda). Exige
  /// que las lecturas cubran al menos [minBaselineSpan]: seis lecturas de la
  /// última hora no describen «lo normal» del sitio.
  static RobustStats? _baselineBefore(
    List<_Sample> all,
    DateTime at,
    double? Function(_Sample) pick,
  ) {
    return _statsBetween(
      all,
      at.subtract(baselineSpan),
      at.subtract(baselineGuard),
      pick,
      minSpan: minBaselineSpan,
    );
  }

  static RobustStats? _statsBetween(
    List<_Sample> all,
    DateTime from,
    DateTime to,
    double? Function(_Sample) pick, {
    Duration? minSpan,
  }) {
    if (!to.isAfter(from)) return null;
    final List<double> values = <double>[];
    DateTime? first;
    DateTime? last;
    for (final _Sample s in all) {
      if (s.ts.isBefore(from)) continue;
      if (s.ts.isAfter(to)) break;
      final double? v = pick(s);
      if (v != null && v.isFinite) {
        values.add(v);
        first ??= s.ts;
        last = s.ts;
      }
    }
    if (minSpan != null &&
        (first == null || last == null || last.difference(first) < minSpan)) {
      return null;
    }
    return RobustStats.fromValues(values);
  }

  /// ¿La elevación de [s] sobre [base] ocurrió de golpe? Compara la lectura
  /// con la mediana de las [localJumpSpan] horas inmediatamente anteriores:
  /// si al menos [minLocalJumpFraction] de la elevación total es reciente, es
  /// un escalón. Sin lecturas locales (hueco de datos) no se puede negar la
  /// forma y se acepta.
  static bool _isStepShaped(List<_Sample> all, _Sample s, RobustStats base) {
    final double total = s.primary - base.median;
    if (total <= 0) return false;
    final RobustStats? local = _statsBetween(
      all,
      s.ts.subtract(localJumpSpan).subtract(baselineGuard),
      s.ts.subtract(baselineGuard),
      (x) => x.primary,
    );
    if (local == null || local.count == 0) return true;
    final double recent = s.primary - local.median;
    return recent >= minLocalJumpFraction * total;
  }

  static double _percentileZ(Iterable<double> values, RobustStats base) {
    final List<double> sorted = values.where((v) => v.isFinite).toList()..sort();
    if (sorted.isEmpty) return 0.0;
    final int idx = ((sorted.length - 1) * postPercentile).round().clamp(
      0,
      sorted.length - 1,
    );
    return base.z(sorted[idx]);
  }

  static double? _channelZ(
    List<_Sample> all,
    DateTime at,
    List<_Sample> post,
    double? Function(_Sample) pick,
  ) {
    final RobustStats? base = _baselineBefore(all, at, pick);
    if (base == null || !base.isUsable) return null;
    final List<double> values = post.map(pick).whereType<double>().toList();
    if (values.isEmpty) return null;
    return _percentileZ(values, base);
  }

  static double? _vwcDelta(List<_Sample> all, DateTime at) {
    final RobustStats? base = _baselineBefore(all, at, (s) => s.vwc);
    if (base == null || !base.isUsable) return null;
    final List<double> after = all
        .where((s) => !s.ts.isBefore(at) && !s.ts.isAfter(at.add(sustainSpan)))
        .map((s) => s.vwc)
        .whereType<double>()
        .toList()
      ..sort();
    if (after.isEmpty) return null;
    final int idx = ((after.length - 1) * postPercentile).round().clamp(
      0,
      after.length - 1,
    );
    return after[idx] - base.median;
  }

  /// Fracción de cubos de [coverageBin] con al menos una lectura utilizable.
  static double _coverage(List<_Sample> usable, DateTime from, DateTime to) {
    final int totalMs = to.difference(from).inMilliseconds;
    if (totalMs <= 0) return usable.isEmpty ? 0.0 : 1.0;
    final int bins = math.max(1, (totalMs / coverageBin.inMilliseconds).ceil());
    final Set<int> covered = <int>{};
    for (final _Sample s in usable) {
      final int idx =
          s.ts.difference(from).inMilliseconds ~/ coverageBin.inMilliseconds;
      covered.add(idx.clamp(0, bins - 1));
    }
    return (covered.length / bins).clamp(0.0, 1.0);
  }

  static FertilizationSignatureScan _empty(
    ScanObservability obs,
    String summary,
  ) {
    return FertilizationSignatureScan(
      observability: obs,
      signatures: const <FertilizationSignature>[],
      readingsInRange: 0,
      usableReadings: 0,
      observedFraction: 0.0,
      usedMoistureNormalization: false,
      summaryEs: summary,
    );
  }

  static String _summary(
    List<FertilizationSignature> signatures,
    ScanObservability obs,
    double coverage,
  ) {
    if (signatures.isNotEmpty) {
      final FertilizationSignature b = signatures.first;
      if (b.isCompatible) {
        return 'Respuesta compatible con fertilización detectada '
            '(confianza ${b.confidenceLabelEs}, ${b.kind.labelEs.toLowerCase()}).';
      }
      if (b.isPossible) {
        return 'Hay un cambio en la zona de raíces que podría corresponder a '
            'una fertilización; hacen falta más lecturas para confirmarlo.';
      }
    }
    if (obs == ScanObservability.insufficientBaseline) {
      return 'Hay lecturas, pero sin referencia previa suficiente para '
          'comparar: la sonda necesita unos días de historial en este punto.';
    }
    if (coverage < minObservedFraction) {
      return 'Sin respuesta compatible con fertilización hasta ahora, con '
          'huecos de observación (${(coverage * 100).round()} % de cobertura).';
    }
    return 'Sin respuesta compatible con fertilización hasta ahora.';
  }

  static String _followLine(String channel, double? z) {
    if (z == null) return '';
    final String name = switch (channel) {
      'N' => 'nitrógeno',
      'P' => 'fósforo',
      _ => 'potasio',
    };
    return z >= 1.0
        ? 'La señal de $name acompañó la subida.'
        : 'La señal de $name no acompañó la subida (se toma como consistencia, no como confirmación).';
  }

  /// «Subida fuerte» / «Subida clara» / «Subida leve» según la magnitud en
  /// MAD, para no mostrar estadística al agricultor.
  static String _magnitudeEs(double z) {
    if (z >= strongMad * 2) return 'Subida fuerte';
    if (z >= strongMad) return 'Subida clara';
    return 'Subida leve';
  }

  static String _fmtDateTime(DateTime d) {
    final String dd = d.day.toString().padLeft(2, '0');
    final String mm = d.month.toString().padLeft(2, '0');
    final String hh = d.hour.toString().padLeft(2, '0');
    final String mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mi';
  }
}

class _Sample {
  const _Sample({
    required this.ts,
    required this.primary,
    required this.ecRaw,
    this.vwc,
    this.n,
    this.p,
    this.k,
  });

  final DateTime ts;

  /// Carga iónica normalizada por humedad, o CE bruta si no se normaliza.
  final double primary;
  final double ecRaw;
  final double? vwc;
  final double? n;
  final double? p;
  final double? k;
}

class _Onset {
  const _Onset({
    required this.at,
    required this.z,
    required this.base,
    required this.sustained,
    required this.provisional,
  });

  final DateTime at;
  final double z;
  final RobustStats base;
  final double sustained;
  final bool provisional;
}
