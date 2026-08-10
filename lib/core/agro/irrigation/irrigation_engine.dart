// lib/core/agro/irrigation/irrigation_engine.dart
//
// Motor de riego por veto.
//
// "Veto" y "§V1-A" son vocabulario de esta implementación, no del Documento
// Fundacional 2.1: ese documento no contiene la palabra veto ni umbrales de
// lluvia. Lo que sí fija, y es lo que este motor obedece, son sus §9.2 y §4.2:
//
//   - "No se generará una nueva recomendación basada en una lectura inválida."
//   - "Toda lectura fuera de los rangos físicamente posibles será rechazada
//      por el sistema antes de llegar al motor de interpretación."
//   - "Mostrar que el suelo está seco no es una recomendación: el productor ya
//      lo sabe. [...] El ahorro de agua no proviene de confirmar que la tierra
//      está seca, sino de evitar el riego que iba a ejecutarse sin necesidad."
//
// Los umbrales concretos (probabilidad de lluvia, milímetros, vigencia de la
// lectura) son decisiones de ingeniería de este archivo. El Fundacional no da
// cifras; si algún día las da, mandan ellas.
//
// Qué reemplaza: un `switch` de ocho líneas dentro del presentador del Panel,
// con la banda de humedad como única entrada, que producía la frase "Riega
// dentro de las próximas 24 horas" sin haber mirado nunca la lluvia, la
// vigencia de la lectura ni el suelo. Ese `switch` además daba esa misma orden,
// con severidad crítica, cuando el sensor de humedad simplemente no había
// enviado dato: el cero sintetizado caía por debajo del umbral bajo.
//
// Qué hace en su lugar: decide entre cinco estados con evidencia explícita,
// degrada la confianza en vez de fingir certeza, y declara lo que no sabe.
//
// Lo que NO hace, deliberadamente: calcular milímetros. Sin parámetros de
// suelo y validación de campo, una lámina sería precisión aparente sin base.
// El hueco está reservado en [IrrigationDepthEstimate] para V1-B.
//
// El motor es puro: sin red, sin disco, sin `BuildContext`. Determinista para
// una entrada dada, y por lo tanto probable caso por caso.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_inputs.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/traceability/engine_versions.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';

/// Posición de la humedad respecto al objetivo de la etapa.
enum _MoisturePosition { critical, below, within, above, saturated }

class IrrigationEngine {
  const IrrigationEngine();

  static const String version = BioGEngineVersions.irrigation;

  /// Punto de entrada único.
  IrrigationDecision decide(IrrigationEngineInput input) {
    final now = input.now;

    // ══════════════════════════════════════════════════════════════════════
    // 1) BLOQUEOS DE DATO
    //
    // Antes de razonar sobre agronomía hay que responder si el dato existe y
    // si todavía vale. Cualquier fallo aquí produce DATOS INSUFICIENTES, que
    // NO es una recomendación: es la ausencia de una, y así debe tratarse
    // aguas abajo.
    // ══════════════════════════════════════════════════════════════════════

    if (input.isGenericMode) {
      return _insufficient(
        input: input,
        reason: const IrrigationReason(
          code: IrrigationReasonCode.noCropConfigured,
          textEs:
              'No hay cultivo ni variedad seleccionada, así que no existe un '
              'objetivo de humedad contra el cual comparar.',
          isLimitation: true,
        ),
        headline: 'Configura el cultivo',
        detail:
            'El riego se calcula contra el objetivo de humedad de la etapa. '
            'Elige cultivo y variedad para activarlo.',
      );
    }

    if (!input.moisture.hasValue) {
      // ESTE es el caso que producía "Riego recomendado" crítico sobre un
      // sensor inexistente. Ahora se detiene aquí.
      return _insufficient(
        input: input,
        reason: const IrrigationReason(
          code: IrrigationReasonCode.moistureSensorAbsent,
          textEs:
              'El sensor no envió humedad del suelo en la última lectura. Un '
              'dato ausente no se interpreta como suelo seco.',
          isLimitation: true,
        ),
        headline: 'Sin lectura de humedad',
        detail:
            'No se recomienda riego sin dato de humedad. Revisa que el Bio-G '
            'esté encendido y con la sonda insertada.',
        requiresHumanReview: true,
      );
    }

    if (!input.moisture.isPhysicallyPlausible) {
      return _insufficient(
        input: input,
        reason: IrrigationReason(
          code: IrrigationReasonCode.moistureReadingImplausible,
          textEs:
              'La humedad reportada (${_fmt(input.moisture.percent)} %) está '
              'fuera del rango físicamente posible.',
        ),
        headline: 'Lectura fuera de rango',
        detail:
            'La sonda está entregando un valor imposible. Revisa la conexión '
            'y la calibración antes de tomar decisiones de riego.',
        requiresHumanReview: true,
      );
    }

    final readingAge = input.moisture.ageAt(now);

    if (readingAge == null) {
      return _insufficient(
        input: input,
        reason: const IrrigationReason(
          code: IrrigationReasonCode.moistureReadingStale,
          textEs:
              'La lectura no trae hora de medición, así que no se puede '
              'establecer su vigencia.',
          isLimitation: true,
        ),
        headline: 'Lectura sin hora',
        detail:
            'Sin saber cuándo se midió, la humedad no puede fundamentar una '
            'decisión de riego.',
        requiresHumanReview: true,
      );
    }

    if (readingAge > input.policy.readingMaxAge) {
      return _insufficient(
        input: input,
        reason: IrrigationReason(
          code: IrrigationReasonCode.moistureReadingStale,
          textEs:
              'La última lectura de humedad tiene ${_ageLabel(readingAge)} y '
              'el límite para decidir es '
              '${_ageLabel(input.policy.readingMaxAge)}.',
        ),
        headline: 'Lectura vencida',
        detail:
            'La humedad que se conoce ya no representa el estado actual del '
            'suelo. Espera una lectura nueva del Bio-G.',
        requiresHumanReview: true,
      );
    }

    final target = input.moistureTarget;
    if (target == null) {
      // Hay dato válido pero no hay contra qué compararlo. No es "datos
      // insuficientes" (el sensor funciona): es una configuración incompleta
      // que una persona debe resolver.
      return _build(
        input: input,
        action: IrrigationAction.revisar,
        urgency: IrrigationUrgency.low,
        reasons: const <IrrigationReason>[
          IrrigationReason(
            code: IrrigationReasonCode.noStageTarget,
            textEs:
                'No hay rango objetivo de humedad definido para la etapa '
                'actual del cultivo.',
            isLimitation: true,
          ),
        ],
        headline: 'Revisa la configuración del cultivo',
        detail:
            'La lectura es válida, pero falta el objetivo de humedad de esta '
            'etapa para poder decidir.',
        requiresHumanReview: true,
        readingAge: readingAge,
      );
    }

    // ══════════════════════════════════════════════════════════════════════
    // 2) POSICIÓN RESPECTO AL OBJETIVO
    // ══════════════════════════════════════════════════════════════════════

    final value = input.moisture.percent!;
    final position = _positionOf(value, target);

    // ══════════════════════════════════════════════════════════════════════
    // 3) LECTURA DEL CLIMA
    //
    // El clima es un veto, no un adorno. Aquí es donde deja de ser posible
    // que Ambiente anuncie lluvia mientras el Panel manda regar: ambos leen
    // el mismo snapshot.
    // ══════════════════════════════════════════════════════════════════════

    final weather = input.weather;
    final weatherUsable = weather.isUsableForDecisionAt(now);
    final weatherFreshness = weather.freshnessAt(now);

    final rain = weather.rain;
    final probNext24h = rain.maxProbNext24hPct;
    final expectedMm = rain.expectedNext24hMm;
    final observedLast24h = rain.observedLast24hMm;

    // El veto exige probabilidad ALTA y volumen suficiente a la vez. Un 80 %
    // de 0.2 mm no moja la zona radicular; vetar un riego por eso sería peor
    // que no mirar el clima.
    final rainVetoes =
        weatherUsable &&
        !input.isUnderCover &&
        probNext24h != null &&
        expectedMm != null &&
        probNext24h >= input.policy.rainVetoProbPct &&
        expectedMm >= input.policy.rainVetoMinMm;

    // Vigilar la lluvia solo tiene sentido si además puede aportar algo. Un
    // volumen previsto conocido y despreciable no justifica dejar el cultivo
    // en déficit; un volumen desconocido sí merece prudencia.
    final rainWorthWatching =
        weatherUsable &&
        !input.isUnderCover &&
        probNext24h != null &&
        probNext24h >= input.policy.rainWatchProbPct &&
        (expectedMm == null || expectedMm >= input.policy.rainWatchMinMm) &&
        !rainVetoes;

    final recentRainRelevant =
        weatherUsable &&
        !input.isUnderCover &&
        observedLast24h != null &&
        observedLast24h >= input.policy.recentRainRelevantMm;

    final recentIrrigation = _hasRecentIrrigation(input, now);

    // ══════════════════════════════════════════════════════════════════════
    // 4) DECISIÓN
    // ══════════════════════════════════════════════════════════════════════

    final reasons = <IrrigationReason>[];
    reasons.add(_positionReason(position, value, target, input.stageLabel));

    switch (position) {
      case _MoisturePosition.saturated:
        reasons.add(
          const IrrigationReason(
            code: IrrigationReasonCode.soilSaturated,
            textEs:
                'Con el suelo saturado, más agua desplaza el oxígeno de la '
                'zona radicular.',
          ),
        );
        return _build(
          input: input,
          action: IrrigationAction.noRegar,
          urgency: IrrigationUrgency.low,
          reasons: reasons,
          headline: 'No riegues: suelo saturado',
          detail:
              'La humedad está por encima del rango alto de la etapa. Deja '
              'drenar antes de volver a regar.',
          readingAge: readingAge,
          weatherFreshness: weatherFreshness,
          value: value,
        );

      case _MoisturePosition.above:
        return _build(
          input: input,
          action: IrrigationAction.noRegar,
          urgency: IrrigationUrgency.none,
          reasons: reasons,
          headline: 'No riegues por ahora',
          detail:
              'La humedad está por encima del objetivo de la etapa. El riego '
              'sería innecesario.',
          readingAge: readingAge,
          weatherFreshness: weatherFreshness,
          value: value,
        );

      case _MoisturePosition.within:
        // `rainWorthWatching` ya implica `probNext24h != null`: el análisis de
        // flujo de Dart propaga esa promoción a través del booleano.
        if (rainWorthWatching) {
          reasons.add(
            IrrigationReason(
              code: IrrigationReasonCode.rainExpectedLater,
              textEs:
                  'Hay $probNext24h % de probabilidad de lluvia en las '
                  'próximas 24 horas.',
            ),
          );
        }
        return _build(
          input: input,
          action: IrrigationAction.noRegar,
          urgency: IrrigationUrgency.none,
          reasons: reasons,
          headline: 'Humedad dentro del objetivo',
          detail: 'El suelo está en rango para la etapa actual. Solo monitorea.',
          readingAge: readingAge,
          weatherFreshness: weatherFreshness,
          value: value,
        );

      case _MoisturePosition.below:
      case _MoisturePosition.critical:
        return _decideOnDeficit(
          input: input,
          position: position,
          value: value,
          reasons: reasons,
          readingAge: readingAge,
          weatherUsable: weatherUsable,
          weatherFreshness: weatherFreshness,
          rainVetoes: rainVetoes,
          rainWorthWatching: rainWorthWatching,
          recentRainRelevant: recentRainRelevant,
          recentIrrigation: recentIrrigation,
          probNext24h: probNext24h,
          expectedMm: expectedMm,
          observedLast24h: observedLast24h,
        );
    }
  }

  // ── Déficit: el caso que realmente importa ────────────────────────────────

  IrrigationDecision _decideOnDeficit({
    required IrrigationEngineInput input,
    required _MoisturePosition position,
    required double value,
    required List<IrrigationReason> reasons,
    required Duration readingAge,
    required bool weatherUsable,
    required WeatherFreshness weatherFreshness,
    required bool rainVetoes,
    required bool rainWorthWatching,
    required bool recentRainRelevant,
    required bool recentIrrigation,
    required int? probNext24h,
    required double? expectedMm,
    required double? observedLast24h,
  }) {
    final isCritical = position == _MoisturePosition.critical;

    // 4.1 Contradicción sensor vs. clima.
    //
    // Llovió de verdad y el sensor sigue marcando déficit crítico. Puede ser
    // sonda descalibrada, mal insertada, o un suelo con infiltración muy
    // rápida. Sea lo que sea, no es momento de dar una orden automática.
    if (recentRainRelevant && isCritical) {
      reasons.add(
        IrrigationReason(
          code: IrrigationReasonCode.sensorWeatherConflict,
          textEs:
              'Se registraron ${_fmt(observedLast24h)} mm de lluvia en las '
              'últimas 24 horas, pero el sensor sigue marcando humedad '
              'crítica.',
        ),
      );
      return _build(
        input: input,
        action: IrrigationAction.revisar,
        urgency: IrrigationUrgency.high,
        reasons: reasons,
        headline: 'Revisa: el sensor y el clima no coinciden',
        detail:
            'Llovió lo suficiente como para que la humedad hubiera subido. '
            'Comprueba la sonda antes de regar.',
        requiresHumanReview: true,
        readingAge: readingAge,
        weatherFreshness: weatherFreshness,
        value: value,
      );
    }

    // 4.2 Veto por lluvia.
    if (rainVetoes && probNext24h != null && expectedMm != null) {
      reasons.add(
        IrrigationReason(
          code: IrrigationReasonCode.rainExpectedSoon,
          textEs:
              'Se esperan ${_fmt(expectedMm)} mm de lluvia en las próximas 24 '
              'horas, con $probNext24h % de probabilidad.',
        ),
      );
      return _build(
        input: input,
        action: IrrigationAction.esperar,
        urgency: isCritical ? IrrigationUrgency.medium : IrrigationUrgency.low,
        reasons: reasons,
        headline: 'Espera: se espera lluvia',
        detail:
            'Hay déficit, pero la lluvia prevista puede cubrir parte de la '
            'necesidad. Vuelve a evaluar después del pronóstico.',
        readingAge: readingAge,
        weatherFreshness: weatherFreshness,
        value: value,
      );
    }

    // 4.3 Riego reciente: el suelo puede no haberse equilibrado todavía.
    if (recentIrrigation && !isCritical) {
      reasons.add(
        IrrigationReason(
          code: IrrigationReasonCode.recentIrrigationLogged,
          textEs:
              'Registraste un riego hace menos de '
              '${_ageLabel(input.policy.recentIrrigationWindow)}.',
        ),
      );
      return _build(
        input: input,
        action: IrrigationAction.esperar,
        urgency: IrrigationUrgency.low,
        reasons: reasons,
        headline: 'Espera: riego reciente',
        detail:
            'El agua del último riego todavía se está redistribuyendo en el '
            'perfil. Vuelve a medir antes de repetir.',
        readingAge: readingAge,
        weatherFreshness: weatherFreshness,
        value: value,
      );
    }

    // 4.4 Sin clima utilizable.
    if (!weatherUsable) {
      reasons.add(
        IrrigationReason(
          code: input.weather.isUnavailable
              ? IrrigationReasonCode.weatherUnavailable
              : IrrigationReasonCode.weatherStale,
          textEs: input.weather.isUnavailable
              ? 'No hay pronóstico disponible para esta parcela, así que no se '
                    'puede descartar lluvia próxima.'
              : 'El pronóstico disponible está vencido '
                    '(${input.weather.freshnessLabelEs(input.now)}).',
          isLimitation: true,
        ),
      );

      if (isCritical) {
        // Déficit crítico sin clima: se riega igual. Dejar la planta en estrés
        // severo por una lluvia que quizá no llegue es el peor de los dos
        // errores. Pero se dice claramente que se decidió a ciegas.
        return _build(
          input: input,
          action: IrrigationAction.regar,
          urgency: IrrigationUrgency.high,
          reasons: reasons,
          headline: 'Riega: humedad crítica',
          detail:
              'El déficit es severo. No se pudo consultar el pronóstico, así '
              'que revisa el cielo antes de aplicar.',
          readingAge: readingAge,
          weatherFreshness: weatherFreshness,
          value: value,
        );
      }

      // Déficit moderado sin clima: no hay base para elegir entre regar y
      // esperar. Se pide criterio humano en vez de adivinar.
      return _build(
        input: input,
        action: IrrigationAction.revisar,
        urgency: IrrigationUrgency.medium,
        reasons: reasons,
        headline: 'Revisa: falta el pronóstico',
        detail:
            'Hay déficit moderado, pero sin clima no se puede saber si '
            'conviene regar o esperar la lluvia.',
        requiresHumanReview: true,
        readingAge: readingAge,
        weatherFreshness: weatherFreshness,
        value: value,
      );
    }

    // 4.5 Lluvia probable pero insuficiente para vetar, con déficit moderado.
    if (rainWorthWatching && !isCritical && probNext24h != null) {
      reasons.add(
        IrrigationReason(
          code: IrrigationReasonCode.rainExpectedLater,
          textEs:
              'Hay $probNext24h % de probabilidad de lluvia, pero el volumen '
              'previsto (${_fmt(expectedMm)} mm) no cubriría la necesidad.',
        ),
      );
      return _build(
        input: input,
        action: IrrigationAction.esperar,
        urgency: IrrigationUrgency.low,
        reasons: reasons,
        headline: 'Espera y vuelve a evaluar',
        detail:
            'El déficit es moderado y hay lluvia posible. Conviene esperar a '
            'que el pronóstico se defina.',
        readingAge: readingAge,
        weatherFreshness: weatherFreshness,
        value: value,
      );
    }

    // 4.6 Regar: déficit confirmado, lectura vigente, sin lluvia que lo cubra.
    reasons.add(
      IrrigationReason(
        code: IrrigationReasonCode.noRainExpected,
        textEs: probNext24h == null
            ? 'El pronóstico no reporta lluvia relevante en las próximas 24 '
                  'horas.'
            : 'Solo hay $probNext24h % de probabilidad de lluvia en las '
                  'próximas 24 horas.',
      ),
    );

    return _build(
      input: input,
      action: IrrigationAction.regar,
      urgency: isCritical ? IrrigationUrgency.critical : IrrigationUrgency.medium,
      reasons: reasons,
      headline: isCritical ? 'Riega ahora: humedad crítica' : 'Riega hoy',
      detail: isCritical
          ? 'La humedad está por debajo del umbral crítico de la etapa y el '
                'pronóstico no aporta agua suficiente.'
          : 'Hay déficit respecto al objetivo de la etapa y no se espera '
                'lluvia que lo cubra.',
      readingAge: readingAge,
      weatherFreshness: weatherFreshness,
      value: value,
    );
  }

  // ── Construcción de la decisión ───────────────────────────────────────────

  IrrigationDecision _build({
    required IrrigationEngineInput input,
    required IrrigationAction action,
    required IrrigationUrgency urgency,
    required List<IrrigationReason> reasons,
    required String headline,
    required String detail,
    Duration? readingAge,
    WeatherFreshness? weatherFreshness,
    double? value,
    bool requiresHumanReview = false,
  }) {
    final allReasons = <IrrigationReason>[...reasons];

    // Limitaciones declaradas. El Fundacional exige decirlas, no esconderlas.
    if (input.soil.isEmpty) {
      allReasons.add(
        const IrrigationReason(
          code: IrrigationReasonCode.soilProfileMissing,
          textEs:
              'No hay perfil de suelo capturado, así que la recomendación es '
              'de decisión y no de lámina en milímetros.',
          isLimitation: true,
        ),
      );
    }

    if (input.weather.et0Source == Et0Source.hargreavesLocal) {
      allReasons.add(
        const IrrigationReason(
          code: IrrigationReasonCode.et0Imprecise,
          textEs:
              'La evapotranspiración es una estimación local, no el cálculo '
              'completo del proveedor.',
          isLimitation: true,
        ),
      );
    }

    final confidence = _confidence(
      input: input,
      action: action,
      readingAge: readingAge,
      weatherFreshness: weatherFreshness,
    );

    // Una acción por debajo del mínimo de confianza no se emite como orden:
    // se degrada a revisión humana. Es la regla que impide que el sistema
    // suene seguro cuando no lo está.
    var finalAction = action;
    var finalHeadline = headline;
    var finalDetail = detail;
    var finalReview = requiresHumanReview;

    if (action == IrrigationAction.regar &&
        confidence < input.policy.minConfidenceToRecommend) {
      finalAction = IrrigationAction.revisar;
      finalHeadline = 'Revisa antes de regar';
      finalDetail =
          'Hay indicios de déficit, pero la evidencia disponible no alcanza '
          'para recomendarlo con seguridad.';
      finalReview = true;
    }

    final requiresConfirmation =
        finalAction == IrrigationAction.revisar ||
        (finalAction == IrrigationAction.regar &&
            confidence < input.policy.confirmationConfidenceThreshold);

    return IrrigationDecision(
      action: finalAction,
      urgency: urgency,
      confidence01: confidence,
      reasons: List<IrrigationReason>.unmodifiable(allReasons),
      headlineEs: finalHeadline,
      detailEs: finalDetail,
      decidedAt: input.now,
      validUntil: _validUntil(input, readingAge),
      requiresHumanReview: finalReview,
      requiresConfirmation: requiresConfirmation,
      engineVersion: version,
      weather: input.weather,
      moisturePct: value ?? input.moisture.percent,
      moistureBandName: input.moistureBand?.name,
      stageKey: input.stageKey,
      stageLabel: input.stageLabel,
      evidence: _evidence(input, readingAge, value),
    );
  }

  IrrigationDecision _insufficient({
    required IrrigationEngineInput input,
    required IrrigationReason reason,
    required String headline,
    required String detail,
    bool requiresHumanReview = false,
  }) {
    return IrrigationDecision(
      action: IrrigationAction.datosInsuficientes,
      urgency: IrrigationUrgency.none,
      confidence01: 0.0,
      reasons: List<IrrigationReason>.unmodifiable(<IrrigationReason>[reason]),
      headlineEs: headline,
      detailEs: detail,
      decidedAt: input.now,
      validUntil: null,
      requiresHumanReview: requiresHumanReview,
      requiresConfirmation: false,
      engineVersion: version,
      weather: input.weather,
      moisturePct: input.moisture.hasValue ? input.moisture.percent : null,
      moistureBandName: input.moistureBand?.name,
      stageKey: input.stageKey,
      stageLabel: input.stageLabel,
      evidence: _evidence(input, input.moisture.ageAt(input.now), null),
    );
  }

  // ── Confianza ─────────────────────────────────────────────────────────────

  /// Arranca en 1.0 y baja por cada cosa que el sistema no sabe con certeza.
  /// Nunca sube: no hay bonificaciones, solo penalizaciones honestas.
  double _confidence({
    required IrrigationEngineInput input,
    required IrrigationAction action,
    Duration? readingAge,
    WeatherFreshness? weatherFreshness,
  }) {
    var confidence = 1.0;

    // Antigüedad de la lectura: sin penalización hasta el ideal, y de ahí
    // creciendo linealmente hasta el máximo permitido.
    if (readingAge != null) {
      final ideal = input.policy.readingIdealAge.inSeconds;
      final max = input.policy.readingMaxAge.inSeconds;
      if (max > ideal && readingAge.inSeconds > ideal) {
        final over = (readingAge.inSeconds - ideal) / (max - ideal);
        confidence -= 0.25 * over.clamp(0.0, 1.0);
      }
    } else {
      confidence -= 0.25;
    }

    // Clima. Pesa distinto según si la acción dependía de él: negar el riego
    // por lluvia exige más certeza que constatar que el suelo está en rango.
    final weatherMatters =
        action == IrrigationAction.regar ||
        action == IrrigationAction.esperar;

    if (input.weather.isUnavailable) {
      confidence -= weatherMatters ? 0.30 : 0.10;
    } else if (weatherFreshness != null) {
      final penalty = weatherFreshness.confidencePenalty;
      confidence -= penalty * (weatherMatters ? 1.0 : 0.4);
    }

    if (!input.moisture.isCalibrated) confidence -= 0.10;
    if (input.soil.isEmpty) confidence -= 0.05;

    return confidence.clamp(0.0, 1.0);
  }

  DateTime? _validUntil(IrrigationEngineInput input, Duration? readingAge) {
    if (readingAge == null) return null;

    // La decisión no puede sobrevivir a la lectura que la fundamenta.
    final readingRemaining = input.policy.readingMaxAge - readingAge;
    if (readingRemaining.isNegative) return input.now;

    final window = readingRemaining < input.policy.decisionValidity
        ? readingRemaining
        : input.policy.decisionValidity;

    return input.now.add(window);
  }

  Map<String, Object?> _evidence(
    IrrigationEngineInput input,
    Duration? readingAge,
    double? value,
  ) {
    return <String, Object?>{
      'deviceId': input.deviceId,
      'cropId': input.cropId,
      'stageKey': input.stageKey,
      'moisturePct': value ?? input.moisture.percent,
      'moisturePresent': input.moisture.isPresent,
      'moistureCalibrated': input.moisture.isCalibrated,
      'moistureMeasuredAt': input.moisture.measuredAt?.toUtc().toIso8601String(),
      'moistureAgeMinutes': readingAge?.inMinutes,
      'target': input.moistureTarget == null
          ? null
          : <String, Object?>{
              'lowMax': input.moistureTarget!.lowMax,
              'optimalMin': input.moistureTarget!.optimalMin,
              'optimalMax': input.moistureTarget!.optimalMax,
              'highMin': input.moistureTarget!.highMin,
            },
      'soil': input.soil.toJson(),
      'underCover': input.isUnderCover,
      'lastIrrigationAt': input.lastIrrigationAt?.toUtc().toIso8601String(),
      'weather': input.weather.toEvidenceJson(),
      'policy': <String, Object?>{
        'readingMaxAgeHours': input.policy.readingMaxAge.inHours,
        'rainVetoProbPct': input.policy.rainVetoProbPct,
        'rainVetoMinMm': input.policy.rainVetoMinMm,
      },
    };
  }

  // ── Auxiliares ────────────────────────────────────────────────────────────

  _MoisturePosition _positionOf(double value, AgroRange target) {
    // Los rangos del catálogo pueden venir con los límites cruzados si alguien
    // los editó a mano; se normalizan igual que hace el motor de score.
    final lowMax = target.lowMax < target.optimalMin
        ? target.lowMax
        : target.optimalMin;
    final optMin = target.lowMax > target.optimalMin
        ? target.lowMax
        : target.optimalMin;
    final optMax = target.optimalMax > optMin ? target.optimalMax : optMin;
    final highMin = target.highMin > optMax ? target.highMin : optMax;

    if (value >= highMin) return _MoisturePosition.saturated;
    if (value > optMax) return _MoisturePosition.above;
    if (value >= optMin) return _MoisturePosition.within;
    if (value >= lowMax) return _MoisturePosition.below;
    return _MoisturePosition.critical;
  }

  IrrigationReason _positionReason(
    _MoisturePosition position,
    double value,
    AgroRange target,
    String? stageLabel,
  ) {
    final stage = (stageLabel == null || stageLabel.trim().isEmpty)
        ? 'la etapa actual'
        : stageLabel.trim().toLowerCase();
    final v = _fmt(value);
    final opt = '${_fmt(target.optimalMin)}–${_fmt(target.optimalMax)} %';

    switch (position) {
      case _MoisturePosition.critical:
        return IrrigationReason(
          code: IrrigationReasonCode.moistureCritical,
          textEs:
              'La humedad ($v %) está por debajo del umbral crítico para '
              '$stage. El objetivo es $opt.',
        );
      case _MoisturePosition.below:
        return IrrigationReason(
          code: IrrigationReasonCode.moistureBelowTarget,
          textEs:
              'La humedad ($v %) está por debajo del objetivo de $stage '
              '($opt).',
        );
      case _MoisturePosition.within:
        return IrrigationReason(
          code: IrrigationReasonCode.moistureWithinTarget,
          textEs: 'La humedad ($v %) está dentro del objetivo de $stage ($opt).',
        );
      case _MoisturePosition.above:
        return IrrigationReason(
          code: IrrigationReasonCode.moistureAboveTarget,
          textEs:
              'La humedad ($v %) está por encima del objetivo de $stage '
              '($opt).',
        );
      case _MoisturePosition.saturated:
        return IrrigationReason(
          code: IrrigationReasonCode.soilSaturated,
          textEs:
              'La humedad ($v %) alcanza el rango de saturación para $stage.',
        );
    }
  }

  bool _hasRecentIrrigation(IrrigationEngineInput input, DateTime now) {
    final last = input.lastIrrigationAt;
    if (last == null) return false;
    final since = now.toUtc().difference(last.toUtc());
    if (since.isNegative) return false;
    return since <= input.policy.recentIrrigationWindow;
  }

  static String _fmt(double? value) {
    if (value == null) return '—';
    if (!value.isFinite) return '—';
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(1);
  }

  static String _ageLabel(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    if (d.inHours < 48) return '${d.inHours} h';
    return '${d.inDays} días';
  }
}
