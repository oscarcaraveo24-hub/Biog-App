// lib/core/agro/alerts_engine.dart
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AlertsEngine {
  static const Duration defaultCooldown = Duration(minutes: 60);

  /// [severityBump] controla el ajuste de severidad por etapa crítica:
  ///   0 = sin ajuste (etapa normal)
  ///   1 = parcial (info → warning)
  ///   2 = completo (info → warning, warning → critical)
  ///
  /// [isGuide] activa los textos del MODO GUÍA GENERAL. Los cuerpos normales
  /// interpolan cultivo y etapa ("para maíz en floración"); en guía no hay ni
  /// uno ni otra, y las plantillas de siempre acabarían diciendo "para tu
  /// cultivo en etapa etapa actual" o nombrando patologías de un cultivo que
  /// el sistema no conoce. Con la bandera en true se sirven versiones sin
  /// etapa y sin diagnóstico específico. Por defecto false: ningún motor
  /// existente cambia de comportamiento.
  static AlertsBuildResult buildFromSuggestedKeys({
    required String deviceId,
    required DateTime now,
    required int severityBump,
    required List<String> suggestedKeys,
    required AlertsState prev,
    Duration cooldown = defaultCooldown,
    String? cropLabel,
    String? stageLabel,
    bool isGuide = false,
  }) {
    final out = <BioGAlert>[];
    final nextMap = Map<BioGAlertType, DateTime>.from(prev.lastByType);
    final nextKeyMap = Map<String, DateTime>.from(prev.lastByKey);
    final crop = cropLabel ?? 'tu cultivo';
    final stage = stageLabel ?? 'etapa actual';

    for (final k in suggestedKeys) {
      final mapped = _mapKeyToAlert(
        k,
        crop: crop,
        stage: stage,
        isGuide: isGuide,
      );
      if (mapped == null) continue;

      final type = mapped.type;
      var severity = mapped.severity;

      if (severityBump >= 2) {
        severity = _bumpSeverity(severity);
      } else if (severityBump == 1) {
        if (severity == BioGAlertSeverity.info) {
          severity = BioGAlertSeverity.warning;
        }
      }

      // El cooldown se evalúa por (tipo + severidad): una alerta leve previa
      // no puede silenciar a la crítica que llega después.
      final cooldownKey = AlertsState.cooldownKey(type, severity);
      final last = nextKeyMap[cooldownKey];
      final canEmit = (last == null) || now.difference(last) >= cooldown;
      if (!canEmit) continue;

      final id = '${deviceId}_${type.name}_${now.millisecondsSinceEpoch}';

      out.add(
        BioGAlert(
          id: id,
          deviceId: deviceId,
          type: type,
          severity: severity,
          title: mapped.title,
          body: mapped.body,
          timestamp: now,
        ),
      );

      nextMap[type] = now;
      nextKeyMap[cooldownKey] = now;
    }

    return AlertsBuildResult(
      alerts: out,
      state: prev.copyWith(lastByType: nextMap, lastByKey: nextKeyMap),
    );
  }

  /// Plantillas del MODO GUÍA GENERAL.
  ///
  /// Mismos tipos y mismas severidades que las plantillas normales — un aviso
  /// de helada no puede pesar distinto según cómo se configuró el cultivo—,
  /// pero con dos reglas de redacción:
  ///
  ///   1. **No se nombra la etapa.** No hay fenología en guía; escribir "en
  ///      etapa actual" es ruido, y "en floración" sería una invención.
  ///   2. **No se nombra la patología ni la enmienda concreta.** "Favorece
  ///      roya, antracnosis y tizón" es un diagnóstico que exige saber qué
  ///      planta hay sembrada. Se describe la condición medida y se deja la
  ///      interpretación al agricultor, que sí sabe qué plantó.
  ///
  /// Solo cubre las claves que el motor de guía puede emitir: las cinco
  /// críticas de suelo y las seis ambientales. Devuelve null para el resto.
  static _AlertTemplate? _guideAlert(String key, {required String crop}) {
    switch (key) {
      // ── Suelo (solo críticas: ver GuideAgroScoreEngine) ──
      case 'soilMoisture.critical':
        return _AlertTemplate(
          type: BioGAlertType.lowSoilMoisture,
          severity: BioGAlertSeverity.critical,
          title: 'Humedad crítica',
          // Sin orden de riego: esa solo la emite IrrigationEngine, que es
          // quien ve el pronóstico.
          body:
              'La humedad del suelo está muy por debajo del rango general '
              'para plantas de campo. Revisa la recomendación de riego en el '
              'Panel.',
        );
      // Clave exclusiva de la guía: el otro lado de `soilMoisture.critical`.
      // El vocabulario del catálogo no distingue sequía de encharcamiento
      // dentro de "crítico", y aquí sí hace falta.
      case 'soilMoisture.saturated':
        return _AlertTemplate(
          type: BioGAlertType.highSoilMoisture,
          severity: BioGAlertSeverity.critical,
          title: 'Suelo encharcado',
          body:
              'La humedad del suelo está muy por encima del rango general. '
              'Con la raíz sin aire empiezan las pudriciones. Revisa drenaje '
              'y suspende el riego.',
        );
      case 'soilTemp.critical':
        return _AlertTemplate(
          type: BioGAlertType.tempExtreme,
          severity: BioGAlertSeverity.warning,
          title: 'Temperatura de suelo extrema',
          body:
              'La temperatura del suelo está fuera del rango que tolera la '
              'mayoría de las plantas. Las raíces pueden sufrir estrés '
              'térmico y absorber peor.',
        );
      case 'ph.critical':
        return _AlertTemplate(
          type: BioGAlertType.phOutOfRange,
          severity: BioGAlertSeverity.warning,
          title: 'pH fuera de rango',
          body:
              'El pH del suelo está fuera del rango general (5.8 – 7.2). '
              'Fuera de esa ventana varios nutrientes quedan bloqueados '
              'aunque estén presentes en el suelo.',
        );
      case 'ec.critical':
        return _AlertTemplate(
          type: BioGAlertType.ecOutOfRange,
          severity: BioGAlertSeverity.warning,
          title: 'Conductividad eléctrica fuera de rango',
          body:
              'La CE está fuera del rango general. Si es alta, la salinidad '
              'puede dañar las raíces. Si es baja, hay pocos nutrientes '
              'disueltos.',
        );
      case 'resistance.critical':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Suelo compactado',
          body:
              'La resistencia a la penetración es alta. Las raíces pueden no '
              'expandirse bien. Evalúa subsoleo o laboreo.',
        );

      // ── Ambiental ──
      // Estas sí son físicas y valen para cualquier planta: el agua se
      // congela a 0 °C sin preguntar qué hay sembrado arriba.
      case 'airTemp.frost':
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.critical,
          title: 'Riesgo de helada',
          body:
              'La temperatura ambiental está cerca o bajo 0 °C. Salvo que '
              '$crop resista el frío, evalúa protección anti-helada.',
        );
      case 'airTemp.cold':
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.warning,
          title: 'Temperatura ambiental baja',
          body:
              'La temperatura ambiental es baja. El crecimiento se ralentiza '
              'y puede haber daño por frío.',
        );
      case 'airTemp.heat':
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.warning,
          title: 'Golpe de calor',
          body:
              'La temperatura ambiental supera los 35 °C. Si $crop está en '
              'floración, el polen puede perder viabilidad.',
        );
      case 'airTemp.extreme_heat':
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.critical,
          title: 'Calor extremo',
          body:
              'La temperatura ambiental supera los 40 °C. Riesgo de '
              'quemaduras foliares y estrés severo en casi cualquier planta '
              'de campo.',
        );
      case 'airHumidity.high':
        return _AlertTemplate(
          type: BioGAlertType.highHumidity,
          severity: BioGAlertSeverity.warning,
          title: 'Humedad relativa alta',
          body:
              'La HR es alta (>80%). La humedad sostenida sobre el follaje '
              'favorece hongos. Revisa ventilación y mojado de hoja.',
        );
      case 'airHumidity.critical':
        return _AlertTemplate(
          type: BioGAlertType.highHumidity,
          severity: BioGAlertSeverity.critical,
          title: 'Humedad relativa muy alta',
          body:
              'La HR está por arriba del 90%. El follaje pasa horas mojado y '
              'el riesgo de enfermedad fúngica sube mucho. Prioriza '
              'ventilación y drenaje.',
        );
    }

    return null;
  }

  static BioGAlertSeverity _bumpSeverity(BioGAlertSeverity s) {
    switch (s) {
      case BioGAlertSeverity.info:
        return BioGAlertSeverity.warning;
      case BioGAlertSeverity.warning:
        return BioGAlertSeverity.critical;
      case BioGAlertSeverity.critical:
        return BioGAlertSeverity.critical;
    }
  }

  static _AlertTemplate? _mapKeyToAlert(
    String key, {
    required String crop,
    required String stage,
    bool isGuide = false,
  }) {
    if (isGuide) {
      final _AlertTemplate? guideTemplate = _guideAlert(key, crop: crop);
      if (guideTemplate != null) return guideTemplate;
      // Sin plantilla de guía se cae al catálogo normal a propósito: es
      // preferible un texto con "etapa actual" de más que perder el aviso.
    }

    final nutrientPriorityMatch = RegExp(
      r'^npk\.(n|p|k)\.(action|review|high_priority|medium_priority|possible_excess|review_accumulation)$',
    ).firstMatch(key);

    if (nutrientPriorityMatch != null) {
      return _nutrientPriorityAlert(
        nutrientCode: nutrientPriorityMatch.group(1)!,
        stateCode: nutrientPriorityMatch.group(2)!,
        crop: crop,
        stage: stage,
      );
    }

    final isLettuce = _isLettuceCrop(crop);

    if (key == 'stage.fallback') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Etapa estimada por respaldo',
        body:
            'BIO-G no pudo mapear con precisión la etapa del cultivo y usó '
            'una etapa de respaldo para $crop. Conviene revisar configuración '
            'de perfil, variedad y fecha de siembra.',
      );
    }
    if (key == 'stage.unknown') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Etapa no interpretada',
        body:
            'BIO-G no pudo interpretar la etapa actual de $crop. Revisa '
            'configuración del cultivo y datos disponibles para evitar '
            'diagnósticos incompletos.',
      );
    }

    // ── Humedad ──
    if (key == 'soilMoisture.critical') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.lowSoilMoisture,
          severity: BioGAlertSeverity.critical,
          title: 'Déficit hídrico crítico en lechuga',
          body:
              'La humedad disponible está muy baja para lechuga en $stage. '
              'La hoja pierde turgencia rápido y sube el riesgo de amargor '
              'o espigado; revisa riego hoy y evita oscilaciones fuertes.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.lowSoilMoisture,
        severity: BioGAlertSeverity.critical,
        title: 'Humedad crítica',
        // Describe el riesgo y remite al Panel; no ordena regar.
        // La orden de riego solo puede salir de IrrigationEngine, que es el
        // único que ve el pronóstico. Este texto llega al informe rápido, y
        // antes podía imprimir "riego inmediato" en el mismo PDF donde el
        // motor había decidido esperar por lluvia.
        body:
            'La humedad del suelo está muy por debajo del mínimo requerido '
            'para $crop en etapa $stage. Riesgo de estrés hídrico severo: '
            'revisa la recomendación de riego en el Panel.',
      );
    }
    if (key == 'soilMoisture.low') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.lowSoilMoisture,
          severity: BioGAlertSeverity.warning,
          title: 'Humedad baja en lechuga',
          body:
              'La humedad está por debajo de lo conveniente para lechuga en '
              '$stage. Mantener agua estable ayuda a sostener turgencia, '
              'calidad de hoja y ventana comercial.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.lowSoilMoisture,
        severity: BioGAlertSeverity.warning,
        title: 'Humedad baja',
        // Igual que en la crítica: sin orden ni plazo de riego. El plazo lo
        // fija el motor, que sabe si viene lluvia.
        body:
            'La humedad del suelo está por debajo del rango óptimo para '
            '$crop en $stage. Revisa la recomendación de riego en el Panel.',
      );
    }
    if (key == 'soilMoisture.high') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.highSoilMoisture,
          severity: BioGAlertSeverity.warning,
          title: 'Saturación en zona de raíz',
          body:
              'La humedad está por arriba del rango para lechuga. Suspende '
              'riegos largos, revisa drenaje y vigila anoxia, chupadera o '
              'pudrición basal.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.highSoilMoisture,
        severity: BioGAlertSeverity.warning,
        title: 'Humedad excesiva',
        body:
            'La humedad del suelo está por arriba del rango para $crop. '
            'Suspende el riego y vigila posible anoxia radicular o '
            'pudrición de raíz.',
      );
    }

    // ── pH ──
    if (key == 'ph.critical') {
      return _AlertTemplate(
        type: BioGAlertType.phOutOfRange,
        severity: BioGAlertSeverity.warning,
        title: 'pH fuera de rango',
        body:
            'El pH del suelo se aleja del rango ideal para $crop en $stage. '
            'Esto puede bloquear la absorción de nutrientes clave como '
            'fósforo y micronutrientes. Revisa enmiendas.',
      );
    }
    if (key == 'ph.low') {
      return _AlertTemplate(
        type: BioGAlertType.phOutOfRange,
        severity: BioGAlertSeverity.info,
        title: 'pH ligeramente bajo',
        body:
            'El pH tiende a ser ácido para $crop. Monitorea en las '
            'próximas lecturas.',
      );
    }
    if (key == 'ph.high') {
      return _AlertTemplate(
        type: BioGAlertType.phOutOfRange,
        severity: BioGAlertSeverity.info,
        title: 'pH ligeramente alto',
        body:
            'El pH tiende a ser alcalino para $crop. El hierro y zinc '
            'pueden verse limitados.',
      );
    }

    // ── EC ──
    if (key == 'ec.critical') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.ecOutOfRange,
          severity: BioGAlertSeverity.warning,
          title: 'Salinidad crítica para lechuga',
          body:
              'La CE está en zona de riesgo para lechuga en $stage. La '
              'salinidad reduce turgencia y calidad; confirma lectura, '
              'revisa agua de riego, drenaje y acumulación antes de corregir.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.ecOutOfRange,
        severity: BioGAlertSeverity.warning,
        title: 'Conductividad eléctrica fuera de rango',
        body:
            'La CE está fuera de rango para $crop en $stage. Si es alta, '
            'la salinidad puede dañar las raíces. Si es baja, los '
            'nutrientes disueltos son insuficientes.',
      );
    }
    if (key == 'ec.low') {
      return _AlertTemplate(
        type: BioGAlertType.ecOutOfRange,
        severity: BioGAlertSeverity.info,
        title: 'CE ligeramente baja',
        body: 'La conductividad es baja para $crop. Revisa fertilización.',
      );
    }
    if (key == 'ec.high') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.ecOutOfRange,
          severity: BioGAlertSeverity.info,
          title: 'Salinidad en observación',
          body:
              'La CE empieza a ser alta para lechuga. Vigila turgencia, '
              'bordes secos y uniformidad, sobre todo si se acerca la cosecha.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.ecOutOfRange,
        severity: BioGAlertSeverity.info,
        title: 'CE ligeramente alta',
        body: 'La conductividad es alta para $crop. Vigila salinidad.',
      );
    }

    // ── Temperatura de suelo ──
    if (key == 'soilTemp.critical') {
      if (isLettuce) {
        final germination = stage.toLowerCase().contains('germin');
        return _AlertTemplate(
          type: BioGAlertType.tempExtreme,
          severity: BioGAlertSeverity.warning,
          title: germination
              ? 'Riesgo de termoinhibición'
              : 'Temperatura de suelo crítica',
          body: germination
              ? 'El suelo está demasiado caliente para germinar lechuga. '
                    'Arriba de 26-28 °C puede frenarse la emergencia; revisa '
                    'fecha, sombra, humedad y hora de siembra.'
              : 'La temperatura del suelo está fuera del rango seguro para '
                    'lechuga en $stage. La raíz superficial puede estresarse y '
                    'perder capacidad de absorción.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.tempExtreme,
        severity: BioGAlertSeverity.warning,
        title: 'Temperatura de suelo extrema',
        body:
            'La temperatura del suelo está fuera del rango seguro para '
            '$crop en $stage. Las raíces pueden sufrir estrés térmico '
            'y reducir su capacidad de absorción.',
      );
    }
    if (key == 'soilTemp.low') {
      return _AlertTemplate(
        type: BioGAlertType.tempExtreme,
        severity: BioGAlertSeverity.info,
        title: 'Suelo frío',
        body:
            'La temperatura del suelo es baja para $crop. La actividad '
            'microbiana y absorción de nutrientes se ralentizan.',
      );
    }
    if (key == 'soilTemp.high') {
      if (isLettuce) {
        final germination = stage.toLowerCase().contains('germin');
        return _AlertTemplate(
          type: BioGAlertType.tempExtreme,
          severity: BioGAlertSeverity.info,
          title: germination
              ? 'Suelo caliente para germinación'
              : 'Suelo caliente para lechuga',
          body: germination
              ? 'La temperatura del suelo se acerca a zona de termoinhibición '
                    'en lechuga. Mantén humedad uniforme y evita sembrar en '
                    'las horas más calientes.'
              : 'La temperatura del suelo es alta para lechuga. Vigila '
                    'turgencia y raíz; sombreo ligero, cobertura o riego bien '
                    'programado pueden reducir el estrés.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.tempExtreme,
        severity: BioGAlertSeverity.info,
        title: 'Suelo caliente',
        body:
            'La temperatura del suelo es alta para $crop. Considera '
            'acolchado (mulch) para proteger las raíces.',
      );
    }

    // ── Resistencia / compactación ──
    if (key == 'resistance.critical') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Compactación en cama de lechuga',
          body:
              'La resistencia del suelo es alta para una raíz superficial. '
              'Revisa costra, drenaje e infiltración; evita labores agresivas '
              'si el cultivo ya está establecido.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Suelo compactado',
        body:
            'La resistencia a la penetración es alta. Las raíces de '
            '$crop pueden no expandirse correctamente en $stage. '
            'Evalúa subsoleo o laboreo.',
      );
    }
    if (key == 'resistance.low') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Buena estructura de suelo',
        body:
            'La resistencia es baja — buena penetración radicular para '
            '$crop.',
      );
    }


    // ── Temperatura ambiental ──
    if (key == 'airTemp.frost') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.critical,
          title: 'Riesgo de helada en lechuga',
          body:
              'La temperatura ambiental está cerca o bajo 0 °C. En lechuga '
              'puede quemar hoja y perder calidad comercial; evalúa cobertura '
              'o protección anti-helada según el lote.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.airTempExtreme,
        severity: BioGAlertSeverity.critical,
        title: 'Riesgo de helada',
        body:
            'La temperatura ambiental está cerca o bajo 0 °C. Para $crop '
            'en $stage esto puede ser devastador — especialmente en '
            'espigamiento y floración. Evalúa protección anti-helada.',
      );
    }
    if (key == 'airTemp.cold') {
      return _AlertTemplate(
        type: BioGAlertType.airTempExtreme,
        severity: BioGAlertSeverity.warning,
        title: 'Temperatura ambiental baja',
        body:
            'La temperatura ambiental es baja para $crop en $stage. '
            'El crecimiento se ralentiza y puede haber daño por frío.',
      );
    }
    if (key == 'airTemp.heat') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.warning,
          title: 'Calor alto para lechuga',
          body:
              'La temperatura está por arriba del rango fresco de lechuga en '
              '$stage. Vigila turgencia, amargor y tallo central; estabiliza '
              'riego, sombra o ventilación.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.airTempExtreme,
        severity: BioGAlertSeverity.warning,
        title: 'Golpe de calor',
        body:
            'La temperatura ambiental es alta para $crop en $stage. '
            'En etapas reproductivas, el polen puede perder viabilidad '
            'y reducir la fecundación.',
      );
    }
    if (key == 'airTemp.extreme_heat') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.airTempExtreme,
          severity: BioGAlertSeverity.critical,
          title: 'Calor crítico para lechuga',
          body:
              'La temperatura supera el límite seguro para lechuga. En '
              '$stage puede acelerar espigado, amargor y pérdida rápida de '
              'calidad; revisa cosecha temprana si ya está comercial.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.airTempExtreme,
        severity: BioGAlertSeverity.critical,
        title: 'Calor extremo',
        body:
            'La temperatura ambiental excede los límites seguros para '
            '$crop. Riesgo de aborto floral, quemaduras foliares y '
            'estrés severo.',
      );
    }

    // ── Humedad relativa ──
    if (key == 'airHumidity.high') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.highHumidity,
          severity: BioGAlertSeverity.warning,
          title: 'HR alta en lechuga',
          body:
              'La humedad relativa alta favorece mildiu velloso, Botrytis y '
              'tip burn en lechuga. Revisa ventilación, mojado foliar y hojas '
              'internas antes de que avance el foco.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.highHumidity,
        severity: BioGAlertSeverity.warning,
        title: 'Humedad relativa alta',
        body:
            'La HR es alta (>80%). Para $crop en $stage, esto favorece '
            'enfermedades fúngicas como roya, antracnosis y tizón. '
            'Vigila follaje y considera aplicación preventiva.',
      );
    }
    if (key == 'airHumidity.critical') {
      if (isLettuce) {
        return _AlertTemplate(
          type: BioGAlertType.highHumidity,
          severity: BioGAlertSeverity.critical,
          title: 'HR muy alta en lechuga',
          body:
              'La HR está en zona crítica para lechuga. Hay riesgo alto de '
              'mildiu velloso, moho gris, pudriciones y pérdida de calidad; '
              'prioriza ventilación, drenaje y revisión de focos.',
        );
      }
      return _AlertTemplate(
        type: BioGAlertType.highHumidity,
        severity: BioGAlertSeverity.critical,
        title: 'Humedad relativa muy alta',
        body:
            'La HR supera 90%. Condiciones ideales para patógenos en '
            '$crop. Riesgo alto de enfermedades foliares y de espiga.',
      );
    }

    // ── Lechuga: espigado / bolting (evento de falla) y ventana de
    // cosecha. Lenguaje de hortaliza de hoja: calidad y oportunidad. ──
    if (key == 'lettuce.bolting_critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.critical,
        title: 'Riesgo crítico de espigado',
        body:
            'El calor y el estrés acumulado están empujando la lechuga '
            'hacia el espigado en $stage. Si el tallo central ya se '
            'alarga, cosecha cuanto antes: el amargor y la pérdida de '
            'calidad avanzan rápido.',
      );
    }
    if (key == 'lettuce.bolting_warning') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Riesgo de espigado',
        body:
            'El calor y el estrés pueden adelantar el espigado de la '
            'lechuga en $stage. Revisa si el tallo central empieza a '
            'alargarse y estabiliza el riego, la sombra o la ventilación.',
      );
    }
    if (key == 'lettuce.harvest_urgent') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Conviene cosechar pronto',
        body:
            'La lechuga está en ventana de cosecha y el calor o el '
            'estrés pueden acortarla. Revisa el campo y corta en cuanto '
            'la firmeza, el color y la turgencia sean buenos.',
      );
    }
    if (key == 'lettuce.harvest_window') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Lechuga en ventana de cosecha',
        body:
            'Tu lechuga parece estar en su punto comercial. Es buen '
            'momento para revisar firmeza, color y turgencia, y cortar '
            'en la ventana óptima.',
      );
    }
    if (key == 'lettuce.harvest_review') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Revisa el campo: cosecha cercana',
        body:
            'La lechuga se acerca a su ventana comercial. Revisa el '
            'campo en los próximos días para no pasarte del punto '
            'óptimo de cosecha.',
      );
    }
    if (key == 'lettuce.harvest_past') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Ventana de cosecha pasada',
        body:
            'La lechuga puede haber pasado su punto óptimo. La calidad '
            'baja rápido en sobre-madurez: revisa cosecha o cierre del '
            'ciclo cuanto antes.',
      );
    }

    if (key == 'spinach.bolting_critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.critical,
        title: 'Espigado critico en espinaca',
        body:
            'La espinaca esta entrando en espigado durante $stage. Si aparece '
            'tallo floral, la calidad baja aunque la planta siga creciendo: '
            'cosecha de inmediato si aun sirve o cierra el ciclo.',
      );
    }
    if (key == 'spinach.bolting_warning') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Riesgo de espigado en espinaca',
        body:
            'Calor, edad o estres pueden adelantar el espigado de la espinaca '
            'en $stage. Revisa el tallo central y estabiliza riego, sombra o '
            'ventilacion antes de perder calidad.',
      );
    }
    if (key == 'spinach.foliar_disease_risk') {
      return _AlertTemplate(
        type: BioGAlertType.highHumidity,
        severity: BioGAlertSeverity.warning,
        title: 'Ambiente favorable a mildiu/manchas',
        body:
            'La humedad alta y el dosel mojado favorecen mildiu, Botrytis y '
            'manchas foliares en espinaca. Revisa el enves de las hojas y la '
            'ventilacion; la hoja es el producto comercial.',
      );
    }
    if (key == 'spinach.salinity_critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.critical,
        title: 'Salinidad critica para calidad de hoja',
        body:
            'La CE esta muy alta para espinaca. Puede bajar turgencia y calidad '
            'visual; no subas fertilizante sin revisar agua, bulbo humedo y '
            'posible lavado tecnico.',
      );
    }
    if (key == 'spinach.salinity_warning') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Salinidad en observacion',
        body:
            'La CE puede empezar a afectar turgencia y calidad de hoja. En '
            'espinaca, primero revisa agua y salinidad antes de aumentar NPK.',
      );
    }
    if (key == 'spinach.harvest_urgent') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Conviene cosechar espinaca pronto',
        body:
            'La espinaca esta en ventana de corte y el calor, manchas o '
            'espigado pueden acortarla. Revisa turgencia, limpieza de hoja y '
            'corta en cuanto la calidad sea buena.',
      );
    }
    if (key == 'spinach.harvest_window') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Espinaca en ventana de cosecha',
        body:
            'La hoja parece estar en punto comercial. Revisa turgencia, color, '
            'minador, mildiu y pulgon antes de retrasar el corte.',
      );
    }
    if (key == 'spinach.harvest_review') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Revisa el campo: corte cercano',
        body:
            'La espinaca se acerca a su ventana comercial. Revisa el lote en '
            'los proximos dias para no perder calidad por calor o espigado.',
      );
    }
    if (key == 'spinach.harvest_past') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Calidad de espinaca en descenso',
        body:
            'La espinaca puede haber pasado su punto. Revisa cosecha, cierre '
            'del ciclo y registra si hubo calor, HR alta o riego irregular.',
      );
    }

    if (key == 'onion.bolting_critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.critical,
        title: 'Espigado en cebolla',
        body:
            'La cebolla muestra o esta entrando en espigado durante $stage. El '
            'tallo floral es perdida de calidad para bulbo: decide cosecha o '
            'cierre y registra la causa (frio, edad, variedad, estres).',
      );
    }
    if (key == 'onion.bolting_warning') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Riesgo de espigado en cebolla',
        body:
            'El frio en planta grande puede adelantar espigado en $stage. '
            'Revisa el tallo central; si aparece, la prioridad ya no es hacer '
            'mas hoja sino evaluar cosecha y descarte.',
      );
    }
    if (key == 'onion.foliar_disease_risk') {
      return _AlertTemplate(
        type: BioGAlertType.highHumidity,
        severity: BioGAlertSeverity.warning,
        title: 'Ambiente favorable a mildiu/manchas',
        body:
            'La humedad alta y el dosel mojado favorecen mildiu, Botrytis, '
            'mancha purpura y Stemphylium en cebolla. Revisa hojas y pliegues; '
            'la hoja es la fabrica que llena el bulbo.',
      );
    }
    if (key == 'onion.salinity_critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.critical,
        title: 'Salinidad critica para la cebolla',
        body:
            'La CE esta muy alta y la cebolla es sensible a sales. Puede bajar '
            'stand y calibre; no subas fertilizante sin revisar agua, drenaje '
            'y lavado tecnico.',
      );
    }
    if (key == 'onion.salinity_warning') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Salinidad en observacion',
        body:
            'La CE puede empezar a limitar absorcion de agua y calibre del '
            'bulbo. En cebolla, primero revisa agua y salinidad antes de subir '
            'NPK.',
      );
    }
    if (key == 'onion.photoperiod_watch') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'El fotoperiodo manda en la bulbificacion',
        body:
            'La cebolla esta en induccion: si el tipo no corresponde al dia de '
            'la zona puede haber mucha hoja y poco bulbo. Mas fertilizante no '
            'corrige un fotoperiodo equivocado; confirma variedad/perfil.',
      );
    }
    if (key == 'onion.neck_curing_risk') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Cuidado con cuello y curado',
        body:
            'En maduracion, la humedad alta o el N/riego tardio pueden dejar '
            'cuello grueso o humedo y subir pudriciones de cuello. Detener N, '
            'bajar riego y proteger el secado del cuello.',
      );
    }
    if (key == 'onion.harvest_urgent') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Conviene avanzar la cosecha de cebolla',
        body:
            'La cebolla esta madurando y el calor o la humedad pueden danar '
            'cuello y curado. Revisa avance de cuello, evita riego tardio y '
            'cosecha por madurez real, no solo por fecha.',
      );
    }
    if (key == 'onion.harvest_window') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Cebolla en maduracion / cosecha',
        body:
            'El bulbo parece estar madurando. Revisa caida y secado de cuello, '
            'suspende riego cuando corresponda y prepara cosecha y curado sin '
            'golpes ni sol excesivo.',
      );
    }
    if (key == 'onion.harvest_review') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Revisa el campo: cosecha cercana',
        body:
            'La cebolla se acerca a su ventana de maduracion. Revisa el lote en '
            'los proximos dias para no cosechar inmadura ni dejar pasar el '
            'punto del bulbo.',
      );
    }
    if (key == 'onion.harvest_past') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Cebolla espigada / fuera de punto',
        body:
            'La cebolla puede haber espigado o pasado su punto comercial. '
            'Evalua cosecha/cierre y registra si hubo frio, calor, N tardio o '
              'riego irregular para el siguiente ciclo.',
      );
    }

    if (key == 'garlic.vernalization_watch') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Vigila vernalizacion en ajo',
        body:
            'El ajo en $stage depende del frio acumulado para diferenciar '
            'dientes. Si falto frio, mas NPK no corrige el potencial; revisa '
            'fecha, perfil, temperatura y uniformidad del lote.',
      );
    }
    if (key == 'garlic.scape_critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.critical,
        title: 'Escapo / canuto en ajo',
        body:
            'El ajo muestra un evento compatible con escapo, canuto o '
            'escobeteado en $stage. Evalua descarte, cosecha o cierre, y '
            'registra frio, estres, variedad y N tardio.',
      );
    }
    if (key == 'garlic.scape_warning') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Riesgo de escobeteado',
        body:
            'Las condiciones pueden favorecer escapo/canutos en ajo durante '
            '$stage. Revisa tallo central, vigor excesivo, frio irregular, '
            'agua y N tardio antes de ajustar fertilizacion.',
      );
    }
    if (key == 'garlic.foliar_disease_risk') {
      return _AlertTemplate(
        type: BioGAlertType.highHumidity,
        severity: BioGAlertSeverity.warning,
        title: 'Ambiente favorable a roya/mildiu',
        body:
            'Humedad alta y hoja mojada favorecen roya, mildiu, Botrytis, '
            'mancha purpura y Stemphylium en ajo. Revisa hojas, cuello y '
            'ventilacion; no recomienda ingredientes activos.',
      );
    }
    if (key == 'garlic.salinity_critical') {
      return _AlertTemplate(
        type: BioGAlertType.ecOutOfRange,
        severity: BioGAlertSeverity.critical,
        title: 'Salinidad critica para ajo',
        body:
            'La CE esta muy alta para ajo. Puede bajar raiz, absorcion, '
            'calibre, curado y rendimiento comercial; no subas fertilizante '
            'sin revisar agua, drenaje y acumulacion de sales.',
      );
    }
    if (key == 'garlic.salinity_warning') {
      return _AlertTemplate(
        type: BioGAlertType.ecOutOfRange,
        severity: BioGAlertSeverity.warning,
        title: 'Salinidad en observacion',
        body:
            'La CE puede empezar a limitar absorcion de agua, calibre y '
            'curado del ajo. Primero revisa agua y salinidad antes de subir NPK.',
      );
    }
    if (key == 'garlic.curing_risk') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Cuidado con maduracion y curado',
        body:
            'En ajo, humedad alta, riego o N tardio pueden dejar cuello/bulbo '
            'mal curado y subir pudriciones o brotacion en almacenamiento. '
            'Revisa secado, ventilacion y descarte.',
      );
    }
    if (key == 'garlic.harvest_urgent') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Conviene revisar cosecha de ajo',
        body:
            'El ajo esta entrando a ventana de cosecha y el calor, humedad o '
            'sanidad pueden acortarla. Revisa madurez real, cuello, bulbo, '
            'descarte y curado antes de retrasar.',
      );
    }
    if (key == 'garlic.harvest_window') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Ajo en maduracion / cosecha',
        body:
            'El ajo parece estar en ventana de maduracion. Revisa piel, '
            'dientes, cuello, sanidad de bulbo y prepara curado sin golpes ni '
            'sol excesivo.',
      );
    }
    if (key == 'garlic.harvest_review') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Revisa el campo: cosecha cercana',
        body:
            'El ajo se acerca a su ventana comercial. Revisa el lote en los '
            'proximos dias para no cosechar inmaduro ni pasar el punto de curado.',
      );
    }
    if (key == 'garlic.harvest_past') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Ajo fuera de punto',
        body:
            'El ajo puede haber pasado su punto comercial o de curado. Evalua '
            'cosecha/cierre y registra frio, calor, N tardio, riego, salinidad '
            'o sanidad para el siguiente ciclo.',
      );
    }

    return null;
  }

  static _AlertTemplate _nutrientPriorityAlert({
    required String nutrientCode,
    required String stateCode,
    required String crop,
    required String stage,
  }) {
    final nutrientName = switch (nutrientCode) {
      'n' => 'nitrógeno',
      'p' => 'fósforo',
      'k' => 'potasio',
      _ => 'nutriente',
    };

    final shortName = switch (nutrientCode) {
      'n' => 'N',
      'p' => 'P',
      'k' => 'K',
      _ => 'NPK',
    };

    final cropLc = crop.toLowerCase();
    final isMaize = cropLc.contains('maíz') ||
        cropLc.contains('maiz') ||
        cropLc.contains('corn') ||
        cropLc.contains('maize');
    final isLettuce = _isLettuceCrop(crop);
    final isSpinach = _isSpinachCrop(crop);
    final isOnion = _isOnionCrop(crop);
    final isGarlic = _isGarlicCrop(crop);
    final stageLc = stage.toLowerCase();

    if (isLettuce) {
      return _lettuceNutrientPriorityAlert(
        nutrientCode: nutrientCode,
        stateCode: stateCode,
        nutrientName: nutrientName,
        shortName: shortName,
        crop: crop,
        stage: stage,
      );
    }
    if (isOnion) {
      return _onionNutrientPriorityAlert(
        nutrientCode: nutrientCode,
        stateCode: stateCode,
        nutrientName: nutrientName,
        shortName: shortName,
        crop: crop,
        stage: stage,
      );
    }
    if (isGarlic) {
      return _garlicNutrientPriorityAlert(
        nutrientCode: nutrientCode,
        stateCode: stateCode,
        nutrientName: nutrientName,
        shortName: shortName,
        crop: crop,
        stage: stage,
      );
    }
    if (isSpinach) {
      return _spinachNutrientPriorityAlert(
        nutrientCode: nutrientCode,
        stateCode: stateCode,
        nutrientName: nutrientName,
        shortName: shortName,
        crop: crop,
        stage: stage,
      );
    }

    final nutrientWhy = _nutrientWhy(
      nutrientCode: nutrientCode,
      isMaize: isMaize,
      stageLc: stageLc,
      cropLc: cropLc,
    );

    switch (stateCode) {
      case 'action':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: '¡Urge aplicar $nutrientName!',
          body:
              'El cultivo de $crop en $stage necesita $shortName ya. '
              '$nutrientWhy Conviene corregir ahora para no perder '
              'rendimiento.',
        );
      case 'review':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revisa tu manejo de $nutrientName',
          body:
              'Algo no cuadra con $shortName en $crop durante $stage. '
              '$nutrientWhy Revisa qué aplicaste, cuándo y en qué dosis '
              'antes de agregar más.',
        );
      case 'high_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Falta $nutrientName en el cultivo',
          body:
              'El $crop en $stage necesita más $shortName. '
              '$nutrientWhy Conviene actuar pronto para no afectar '
              'el rendimiento.',
        );
      case 'medium_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: '$nutrientName va bajando',
          body:
              'El nivel de $shortName en $crop durante $stage empieza a '
              'bajar. $nutrientWhy Vigila y prepara la aplicación si '
              'la tendencia continúa.',
        );
      case 'possible_excess':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: '$nutrientName de más en la tierra',
          body:
              'El nivel de $shortName en $crop está por encima de lo que '
              'la planta necesita. Pausa la aplicación y revisa el balance '
              'con los otros nutrientes antes de agregar más.',
        );
      case 'review_accumulation':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Exceso de $nutrientName detectado',
          body:
              'BIO-G detecta que el nivel de $shortName en $crop está muy '
              'alto. Frena la aplicación de este nutriente para no dañar '
              'el suelo ni bloquear otros elementos.',
        );
      default:
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Evento nutricional',
          body: 'Se detectó un evento nutricional en $crop para $stage.',
        );
    }
  }

  static _AlertTemplate _lettuceNutrientPriorityAlert({
    required String nutrientCode,
    required String stateCode,
    required String nutrientName,
    required String shortName,
    required String crop,
    required String stage,
  }) {
    final role = _lettuceNutrientRole(nutrientCode, stage);

    switch (stateCode) {
      case 'action':
      case 'high_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revisa $shortName en lechuga',
          body:
              'La lectura sugiere posible déficit de $shortName en $crop '
              'durante $stage. $role BIO-G v1 lo maneja como riesgo de '
              'desequilibrio: confirma historial, humedad, pH y CE antes de '
              'ajustar el manejo.',
        );
      case 'review':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revisión de $nutrientName',
          body:
              'Algo no cuadra con $shortName en $crop durante $stage. $role '
              'Revisa qué se aplicó, cuándo y cómo viene el agua antes de '
              'agregar más.',
        );
      case 'medium_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: '$shortName en observación',
          body:
              'El $shortName empieza a alejarse del rango esperado para '
              'lechuga en $stage. $role Vigila la tendencia y confirma en '
              'campo antes de cambiar el plan.',
        );
      case 'possible_excess':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Posible exceso de $shortName',
          body:
              'El $shortName aparece por encima de lo conveniente para '
              'lechuga. $role Pausa aportes de ese nutriente y revisa el '
              'balance con agua, pH y CE.',
        );
      case 'review_accumulation':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Acumulación de $shortName',
          body:
              'BIO-G detecta acumulación de $shortName en lechuga. $role Usa '
              'la lectura para ajustar manejo y evitar empujar tejido blando '
              'cerca de cosecha.',
        );
      default:
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Evento nutricional en lechuga',
          body:
              'Se detectó un evento NPK en lechuga para $stage. BIO-G lo '
              'interpreta como señal de balance, no como receta de dosis.',
        );
    }
  }

  static _AlertTemplate _spinachNutrientPriorityAlert({
    required String nutrientCode,
    required String stateCode,
    required String nutrientName,
    required String shortName,
    required String crop,
    required String stage,
  }) {
    final role = _spinachNutrientRole(nutrientCode, stage);

    switch (stateCode) {
      case 'action':
      case 'high_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revisa $shortName en espinaca',
          body:
              'La lectura sugiere posible deficit de $shortName en $crop '
              'durante $stage. $role BIO-G v1 lo maneja como riesgo de '
              'desequilibrio: confirma agua, pH, CE y etapa antes de ajustar.',
        );
      case 'review':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revision de $nutrientName',
          body:
              'Algo no cuadra con $shortName en espinaca durante $stage. $role '
              'Antes de subir fertilizante, revisa si la humedad es estable.',
        );
      case 'medium_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: '$shortName en observacion',
          body:
              'El $shortName empieza a alejarse del rango esperado para '
              'espinaca en $stage. $role Vigila tendencia y confirma en campo.',
        );
      case 'possible_excess':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Posible exceso de $shortName',
          body:
              'El $shortName aparece por encima de lo conveniente para '
              'espinaca. $role Pausa aportes de ese nutriente y revisa CE, '
              'agua y proximidad de cosecha.',
        );
      case 'review_accumulation':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Acumulacion de $shortName',
          body:
              'BIO-G detecta acumulacion de $shortName en espinaca. $role Usa '
              'la lectura para evitar hoja blanda, nitratos o golpes salinos.',
        );
      default:
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Evento nutricional en espinaca',
          body:
              'Se detecto un evento NPK en espinaca para $stage. BIO-G lo '
              'interpreta como balance de riesgo, no como receta de dosis.',
        );
    }
  }

  static String _spinachNutrientRole(String nutrientCode, String stage) {
    final stageLc = stage.toLowerCase();
    final nearHarvest = stageLc.contains('madurez') ||
        stageLc.contains('cosecha') ||
        stageLc.contains('perdida') ||
        stageLc.contains('espig') ||
        stageLc.contains('senesc');
    final early = stageLc.contains('germin') ||
        stageLc.contains('establec') ||
        stageLc.contains('emerg');

    switch (nutrientCode) {
      case 'n':
        if (nearHarvest) {
          return 'En espinaca, el N tardio puede ablandar hoja, subir nitratos '
              'y reducir vida de anaquel.';
        }
        return 'El N sostiene expansion foliar, pero con agua irregular o CE '
            'alta puede parecer solucion y empeorar calidad.';
      case 'p':
        if (early) {
          return 'El P pesa mas al establecimiento porque apoya raiz temprana '
              'en un cultivo de ciclo corto.';
        }
        return 'El P pasa a soporte; no desplaza la prioridad de agua, CE y '
            'temperatura.';
      case 'k':
        if (nearHarvest) {
          return 'El K apoya turgencia y calidad de hoja, siempre que la CE no '
              'se vuelva limitante.';
        }
        return 'El K ayuda a turgencia y balance hidrico en expansion foliar.';
      default:
        return 'Este nutriente se interpreta por etapa y contexto del lote.';
    }
  }

  static String _lettuceNutrientRole(String nutrientCode, String stage) {
    final stageLc = stage.toLowerCase();
    final nearHarvest = stageLc.contains('cabeza') ||
        stageLc.contains('compact') ||
        stageLc.contains('cosecha') ||
        stageLc.contains('madur') ||
        stageLc.contains('senesc');

    switch (nutrientCode) {
      case 'n':
        if (nearHarvest) {
          return 'En lechuga, el N tardío puede ablandar hoja, favorecer '
              'Botrytis y acortar vida de anaquel.';
        }
        return 'El N sostiene expansión foliar, pero los pulsos fuertes '
            'pueden producir tejido blando y más presión sanitaria.';
      case 'p':
        return 'El P pesa sobre todo en establecimiento por raíz, energía y '
            'uniformidad; tarde conviene usar la lectura para planear.';
      case 'k':
        return 'El K ayuda a sostener turgencia, calidad de hoja y respuesta '
            'al estrés hídrico.';
      default:
        return 'En lechuga la nutrición se interpreta por balance y etapa.';
    }
  }

  static String _nutrientWhy({
    required String nutrientCode,
    required bool isMaize,
    required String stageLc,
    required String cropLc,
  }) {
    final earlyStage = stageLc.contains('germin') ||
        stageLc.contains('emerg') ||
        stageLc.contains('tempr') ||
        stageLc.contains('early');
    final peakNitrogenStage = stageLc.contains('media') ||
        stageLc.contains('avanz') ||
        stageLc.contains('espig') ||
        stageLc.contains('tass');
    final reproductiveStage = stageLc.contains('flor') ||
        stageLc.contains('llen') ||
        stageLc.contains('grain') ||
        stageLc.contains('madur');
    final tilleringStage = stageLc.contains('macol') ||
        stageLc.contains('tiller');

    if (isMaize) {
      return _maizeWhy(nutrientCode, earlyStage, peakNitrogenStage, reproductiveStage);
    }

    final isWheat = cropLc.contains('trigo') || cropLc.contains('wheat');
    final isBarley = cropLc.contains('cebada') || cropLc.contains('barley');
    final isOat = cropLc.contains('avena') || cropLc.contains('oat');
    final isBean = cropLc.contains('frijol') || cropLc.contains('bean') ||
        cropLc.contains('legum');

    if (isBean) {
      return _beanWhy(nutrientCode, earlyStage, reproductiveStage);
    }
    if (isBarley) {
      return _barleyWhy(nutrientCode, earlyStage, tilleringStage, reproductiveStage);
    }
    if (isWheat) {
      return _wheatWhy(nutrientCode, earlyStage, tilleringStage, reproductiveStage);
    }
    if (isOat) {
      return _oatWhy(nutrientCode, earlyStage, tilleringStage, reproductiveStage);
    }

    return _genericCropWhy(nutrientCode, earlyStage, reproductiveStage);
  }

  static String _maizeWhy(String n, bool early, bool peak, bool repro) {
    switch (n) {
      case 'n':
        if (early) return 'En maíz, solo una fracción menor del N total se usa antes de V6, así que lo crítico es no llegar corto al tramo que viene.';
        if (peak) return 'En maíz, la mayor captura de N ocurre desde V6 hacia espigamiento y floración, por eso esta lectura pesa mucho más aquí.';
        if (repro) return 'En maíz, todavía hay demanda de N cerca de floración y llenado temprano, aunque la utilidad de corregir cae cuando el ciclo ya viene muy avanzado.';
        return 'En cierre de ciclo, el N sirve más para trazabilidad y aprendizaje del siguiente plan que para empujar tarde por rutina.';
      case 'p':
        if (early) return 'El P pesa más al arranque por su relación con raíces, energía y uniformidad; la respuesta suele ser más probable en suelos bajos en P, fríos o con residuo alto.';
        return 'En maíz, el P sigue importando, pero normalmente su mejor retorno está en llegar bien colocado desde arranque y no en sobrecorregir tarde.';
      case 'k':
        if (repro || peak) return 'En maíz, K ayuda a sostener agua, tallo y estabilidad fisiológica, especialmente cuando sube el estrés térmico o hídrico.';
        return 'K acompaña balance fisiológico durante todo el ciclo y puede volverse limitante antes en suelos arenosos o de baja CEC.';
      default:
        return 'Este nutriente merece seguimiento según etapa y contexto del lote.';
    }
  }

  static String _beanWhy(String n, bool early, bool repro) {
    switch (n) {
      case 'n':
        if (early) return 'El frijol fija N del aire vía nódulos, pero al arranque aún no tiene esa capacidad — un déficit temprano frena el establecimiento.';
        if (repro) return 'En floración y llenado de vaina, el frijol necesita N para formar proteína. Si los nódulos no alcanzan, el rendimiento baja.';
        return 'El frijol depende de fijación biológica para N; un exceso externo puede inhibir la nodulación y ser contraproducente.';
      case 'p':
        if (early) return 'El P es vital para que el frijol nodule bien desde el arranque. Sin P suficiente, la fijación biológica de N se reduce.';
        return 'El frijol sigue usando P para energía y llenado de vaina, pero la ventana óptima de aplicación es al inicio del ciclo.';
      case 'k':
        if (repro) return 'K ayuda al frijol a regular agua y resistir estrés durante floración y llenado, donde la planta es más vulnerable.';
        return 'K aporta resistencia general al frijol y mejora calidad de grano, pero su demanda principal es en etapa reproductiva.';
      default:
        return 'Este nutriente influye en el rendimiento del frijol según la etapa del cultivo.';
    }
  }

  static String _barleyWhy(String n, bool early, bool tillering, bool repro) {
    switch (n) {
      case 'n':
        if (early || tillering) return 'En cebada, el N define el número de macollos y espigas. Aplicar justo en macollamiento maximiza el potencial de rendimiento.';
        if (repro) return 'En cebada, aplicar N tarde puede subir la proteína del grano — en cebada maltera esto causa rechazo. Mucho cuidado aquí.';
        return 'En cebada, el N tardío suele ser contraproducente, especialmente si es para malta. Mejor planear bien el siguiente ciclo.';
      case 'p':
        if (early) return 'P al arranque ayuda a la cebada a enraizar fuerte y establecer macollos uniformes desde temprano.';
        return 'El P en cebada tiene su mayor retorno al inicio del ciclo. Corregir tarde rara vez se justifica.';
      case 'k':
        if (repro) return 'K ayuda a la cebada a mantener tallo firme y resistir acame, especialmente cuando viene la espiga pesada.';
        return 'K contribuye a la resistencia del tallo y calidad del grano en cebada durante todo el ciclo.';
      default:
        return 'Este nutriente influye en el rendimiento de la cebada según la etapa fenológica.';
    }
  }

  static String _wheatWhy(String n, bool early, bool tillering, bool repro) {
    switch (n) {
      case 'n':
        if (early || tillering) return 'En trigo, el N durante macollamiento define cuántas espigas se forman. Es la ventana más crítica para aplicar.';
        if (repro) return 'En trigo, N cerca de espigamiento todavía puede mejorar proteína del grano, pero con riesgo de acame si se excede.';
        return 'En trigo, corregir N muy tarde tiene poco impacto en rendimiento. Mejor documentar para planear el siguiente ciclo.';
      case 'p':
        if (early) return 'P al arranque ayuda al trigo a desarrollar raíces fuertes y macollamiento vigoroso desde temprano.';
        return 'En trigo, el P rinde más cuando se coloca bien desde siembra. Aplicar tarde es menos eficiente.';
      case 'k':
        if (repro) return 'K ayuda al trigo a mantener turgencia y resistir estrés hídrico y térmico durante llenado de grano.';
        return 'K en trigo acompaña la firmeza del tallo y calidad de grano, con mayor impacto en suelos ligeros.';
      default:
        return 'Este nutriente influye en el rendimiento del trigo según la etapa fenológica.';
    }
  }

  static String _oatWhy(String n, bool early, bool tillering, bool repro) {
    switch (n) {
      case 'n':
        if (early || tillering) return 'En avena, N durante macollamiento impulsa la formación de panículas. Es donde más retorno tiene la aplicación.';
        if (repro) return 'En avena, N cerca de espigamiento puede mejorar proteína pero aumenta riesgo de acame si el tallo no es fuerte.';
        return 'En avena, el N tardío rara vez compensa. Mejor registrar la lectura para ajustar el plan del siguiente ciclo.';
      case 'p':
        if (early) return 'P al arranque favorece el enraizamiento y vigor temprano de la avena, especialmente en suelos fríos.';
        return 'En avena, P tiene su mejor momento al inicio. La corrección tardía no suele justificarse económicamente.';
      case 'k':
        if (repro) return 'K ayuda a la avena a resistir estrés y mantener calidad de grano durante llenado, sobre todo en suelos arenosos.';
        return 'K en avena contribuye a la salud general del cultivo y resistencia al acame durante todo el ciclo.';
      default:
        return 'Este nutriente influye en el rendimiento de la avena según la etapa fenológica.';
    }
  }

  static String _genericCropWhy(String n, bool early, bool repro) {
    switch (n) {
      case 'n':
        if (early) return 'Al arranque, el N define el vigor inicial y capacidad fotosintética del cultivo.';
        if (repro) return 'En etapa reproductiva, la demanda de N se enfoca en llenado y calidad. Corregir tarde pierde eficiencia.';
        return 'El N acompaña el crecimiento vegetativo; su impacto varía según la etapa en que se aplique.';
      case 'p':
        if (early) return 'P al arranque fortalece raíces y energía celular, con mayor respuesta en suelos deficientes.';
        return 'El P tiene su mejor ventana de aplicación al inicio del ciclo.';
      case 'k':
        if (repro) return 'K ayuda a regular agua y resistir estrés en la etapa más sensible del cultivo.';
        return 'K contribuye al balance fisiológico y resistencia general del cultivo.';
      default:
        return 'Este nutriente merece seguimiento según etapa y contexto del lote.';
    }
  }

  static bool _isLettuceCrop(String crop) {
    final value = crop.toLowerCase();
    return value.contains('lechuga') ||
        value.contains('lettuce') ||
        value.contains('crop_lettuce');
  }

  static bool _isSpinachCrop(String crop) {
    final value = crop.toLowerCase();
    return value.contains('espinaca') ||
        value.contains('spinach') ||
        value.contains('crop_spinach');
  }

  static bool _isOnionCrop(String crop) {
    final value = crop.toLowerCase();
    return value.contains('cebolla') ||
        value.contains('onion') ||
        value.contains('crop_onion');
  }

  static bool _isGarlicCrop(String crop) {
    final value = crop.toLowerCase();
    return value.contains('ajo') ||
        value.contains('garlic') ||
        value.contains('crop_garlic');
  }

  static _AlertTemplate _onionNutrientPriorityAlert({
    required String nutrientCode,
    required String stateCode,
    required String nutrientName,
    required String shortName,
    required String crop,
    required String stage,
  }) {
    final role = _onionNutrientRole(nutrientCode, stage);

    switch (stateCode) {
      case 'action':
      case 'high_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revisa $shortName en cebolla',
          body:
              'La lectura sugiere posible deficit de $shortName en $crop '
              'durante $stage. $role BIO-G v1 lo maneja como riesgo de '
              'desequilibrio: confirma agua, pH, CE, etapa y fotoperiodo antes '
              'de ajustar.',
        );
      case 'review':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revision de $nutrientName',
          body:
              'Algo no cuadra con $shortName en cebolla durante $stage. $role '
              'Antes de subir fertilizante, revisa si la humedad es estable y '
              'la CE esta en rango.',
        );
      case 'medium_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: '$shortName en observacion',
          body:
              'El $shortName empieza a alejarse del rango esperado para '
              'cebolla en $stage. $role Vigila tendencia y confirma en campo.',
        );
      case 'possible_excess':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Posible exceso de $shortName',
          body:
              'El $shortName aparece por encima de lo conveniente para '
              'cebolla. $role Pausa aportes de ese nutriente y revisa CE, agua '
              'y proximidad de maduracion.',
        );
      case 'review_accumulation':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Acumulacion de $shortName',
          body:
              'BIO-G detecta acumulacion de $shortName en cebolla. $role Usa '
              'la lectura para evitar cuello grueso, golpes salinos o mala '
              'conservacion.',
        );
      default:
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Evento nutricional en cebolla',
          body:
              'Se detecto un evento NPK en cebolla para $stage. BIO-G lo '
              'interpreta como balance de riesgo, no como receta de dosis.',
        );
    }
  }

  static String _onionNutrientRole(String nutrientCode, String stage) {
    final stageLc = stage.toLowerCase();
    final nearHarvest = stageLc.contains('madur') ||
        stageLc.contains('cosecha') ||
        stageLc.contains('cuello') ||
        stageLc.contains('espig') ||
        stageLc.contains('senesc');
    final bulb = stageLc.contains('llenado') ||
        stageLc.contains('bulbo') ||
        stageLc.contains('induccion');
    final early = stageLc.contains('germin') ||
        stageLc.contains('establec') ||
        stageLc.contains('emerg');

    switch (nutrientCode) {
      case 'n':
        if (nearHarvest || bulb) {
          return 'En cebolla, el N tarde engruesa cuello, retrasa madurez y '
              'empeora la conservacion del bulbo.';
        }
        return 'El N construye hoja (la fabrica del bulbo), pero el exceso o '
            'el N tardio penalizan calidad y maduracion.';
      case 'p':
        if (early) {
          return 'El P pesa al establecimiento porque apoya la raiz '
              'superficial, sobre todo en suelo frio o alcalino.';
        }
        return 'El P pasa a soporte; no desplaza la prioridad de agua, CE, '
            'fotoperiodo y temperatura.';
      case 'k':
        if (bulb || nearHarvest) {
          return 'El K es el nutriente del bulbo: sostiene agua, turgencia, '
              'calibre y firmeza, siempre que la CE no se vuelva limitante.';
        }
        return 'El K prepara turgencia y reservas para el llenado del bulbo.';
      default:
        return 'Este nutriente se interpreta por etapa, fotoperiodo y contexto '
            'del lote.';
    }
  }

  static _AlertTemplate _garlicNutrientPriorityAlert({
    required String nutrientCode,
    required String stateCode,
    required String nutrientName,
    required String shortName,
    required String crop,
    required String stage,
  }) {
    final role = _garlicNutrientRole(nutrientCode, stage);

    switch (stateCode) {
      case 'action':
      case 'high_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revisa $shortName en ajo',
          body:
              'La lectura sugiere posible deficit de $shortName en $crop '
              'durante $stage. $role BIO-G v1 lo maneja como riesgo de '
              'desequilibrio: confirma agua, pH, CE, etapa, vernalizacion y '
              'diente-semilla antes de ajustar.',
        );
      case 'review':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Revision de $nutrientName',
          body:
              'Algo no cuadra con $shortName en ajo durante $stage. $role '
              'Antes de subir fertilizante, revisa si hay salinidad, anoxia, '
              'frio insuficiente o sanidad de bulbo.',
        );
      case 'medium_priority':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: '$shortName en observacion',
          body:
              'El $shortName empieza a alejarse del rango esperado para ajo '
              'en $stage. $role Vigila tendencia y confirma en campo.',
        );
      case 'possible_excess':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.warning,
          title: 'Posible exceso de $shortName',
          body:
              'El $shortName aparece por encima de lo conveniente para ajo. '
              '$role Pausa aportes de ese nutriente y revisa CE, agua, etapa, '
              'maduracion y curado.',
        );
      case 'review_accumulation':
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Acumulacion de $shortName',
          body:
              'BIO-G detecta acumulacion de $shortName en ajo. $role Usa la '
              'lectura para evitar golpes salinos, vigor tardio, mala '
              'maduracion o curado deficiente.',
        );
      default:
        return _AlertTemplate(
          type: BioGAlertType.stageEvent,
          severity: BioGAlertSeverity.info,
          title: 'Evento nutricional en ajo',
          body:
              'Se detecto un evento NPK en ajo para $stage. BIO-G lo '
              'interpreta como balance de riesgo, no como receta de dosis.',
        );
    }
  }

  static String _garlicNutrientRole(String nutrientCode, String stage) {
    final stageLc = stage.toLowerCase();
    final nearHarvest = stageLc.contains('madur') ||
        stageLc.contains('cosecha') ||
        stageLc.contains('harvest') ||
        stageLc.contains('curado') ||
        stageLc.contains('curing') ||
        stageLc.contains('escapo') ||
        stageLc.contains('canuto') ||
        stageLc.contains('escobete') ||
        stageLc.contains('senesc');
    final vernalization = stageLc.contains('vernal') ||
        stageLc.contains('frio') ||
        stageLc.contains('cold');
    final bulb = stageLc.contains('diferenci') ||
        stageLc.contains('llenado') ||
        stageLc.contains('bulbo') ||
        stageLc.contains('bulb');
    final early = stageLc.contains('plant') ||
        stageLc.contains('diente') ||
        stageLc.contains('establec') ||
        stageLc.contains('emerg');

    switch (nutrientCode) {
      case 'n':
        if (nearHarvest || bulb || vernalization) {
          return 'En ajo, el N tardio o durante frio/bulbo puede favorecer '
              'vigor excesivo, escobeteado/canutos, mala maduracion, '
              'pudriciones y mal curado; no corrige vernalizacion.';
        }
        return 'El N temprano sostiene hoja, pero debe bajar antes de bulbo y '
            'curado para proteger calidad comercial.';
      case 'p':
        if (early) {
          return 'El P pesa al establecimiento porque apoya raiz del '
              'diente-semilla; debe validarse con analisis de suelo y pH.';
        }
        return 'El P pasa a soporte; no desplaza la prioridad de agua, CE, '
            'frio acumulado y sanidad de raiz/bulbo.';
      case 'k':
        if (bulb || vernalization || nearHarvest) {
          return 'El K apoya diferenciacion, llenado, firmeza y calidad de '
              'bulbo, siempre que la CE y el agua no sean limitantes.';
        }
        return 'El K prepara reservas para bulbo; no compensa salinidad, anoxia '
            'ni diente-semilla de mala calidad.';
      default:
        return 'Este nutriente se interpreta por etapa, frio, agua, CE y '
            'contexto del lote.';
    }
  }
}

class _AlertTemplate {
  const _AlertTemplate({
    required this.type,
    required this.severity,
    required this.title,
    required this.body,
  });

  final BioGAlertType type;
  final BioGAlertSeverity severity;
  final String title;
  final String body;
}
