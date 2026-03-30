// lib/core/agro/alerts_engine.dart
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AlertsEngine {
  static const Duration defaultCooldown = Duration(minutes: 60);

  /// [severityBump] controla el ajuste de severidad por etapa crítica:
  ///   0 = sin ajuste (etapa normal)
  ///   1 = parcial (info → warning)
  ///   2 = completo (info → warning, warning → critical)
  static AlertsBuildResult buildFromSuggestedKeys({
    required String deviceId,
    required DateTime now,
    required int severityBump,
    required List<String> suggestedKeys,
    required AlertsState prev,
    Duration cooldown = defaultCooldown,
    String? cropLabel,
    String? stageLabel,
  }) {
    final out = <BioGAlert>[];
    final nextMap = Map<BioGAlertType, DateTime>.from(prev.lastByType);
    final crop = cropLabel ?? 'tu cultivo';
    final stage = stageLabel ?? 'etapa actual';

    for (final k in suggestedKeys) {
      final mapped = _mapKeyToAlert(k, crop: crop, stage: stage);
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

      final last = nextMap[type];
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
    }

    return AlertsBuildResult(
      alerts: out,
      state: prev.copyWith(lastByType: nextMap),
    );
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
  }) {
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
      return _AlertTemplate(
        type: BioGAlertType.lowSoilMoisture,
        severity: BioGAlertSeverity.critical,
        title: 'Humedad crítica',
        body:
            'La humedad del suelo está muy por debajo del mínimo requerido '
            'para $crop en etapa $stage. Se recomienda riego inmediato para '
            'evitar estrés hídrico severo.',
      );
    }
    if (key == 'soilMoisture.low') {
      return _AlertTemplate(
        type: BioGAlertType.lowSoilMoisture,
        severity: BioGAlertSeverity.warning,
        title: 'Humedad baja',
        body:
            'La humedad del suelo está por debajo del rango óptimo para '
            '$crop en $stage. Considera programar riego en las próximas '
            '24 horas.',
      );
    }
    if (key == 'soilMoisture.high') {
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
      return _AlertTemplate(
        type: BioGAlertType.ecOutOfRange,
        severity: BioGAlertSeverity.info,
        title: 'CE ligeramente alta',
        body: 'La conductividad es alta para $crop. Vigila salinidad.',
      );
    }

    // ── Temperatura de suelo ──
    if (key == 'soilTemp.critical') {
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
      return _AlertTemplate(
        type: BioGAlertType.highHumidity,
        severity: BioGAlertSeverity.critical,
        title: 'Humedad relativa muy alta',
        body:
            'La HR supera 90%. Condiciones ideales para patógenos en '
            '$crop. Riesgo alto de enfermedades foliares y de espiga.',
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

    final isMaize = crop.toLowerCase().contains('maíz') ||
        crop.toLowerCase().contains('maiz') ||
        crop.toLowerCase().contains('corn') ||
        crop.toLowerCase().contains('maize');
    final stageLc = stage.toLowerCase();

    final nutrientWhy = _nutrientWhy(
      nutrientCode: nutrientCode,
      isMaize: isMaize,
      stageLc: stageLc,
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

  static String _nutrientWhy({
    required String nutrientCode,
    required bool isMaize,
    required String stageLc,
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

    if (!isMaize) {
      return 'Este nutriente puede cambiar de prioridad según etapa y contexto del cultivo.';
    }

    switch (nutrientCode) {
      case 'n':
        if (earlyStage) {
          return 'En maíz, solo una fracción menor del N total se usa antes de V6, así que lo crítico es no llegar corto al tramo que viene.';
        }
        if (peakNitrogenStage) {
          return 'En maíz, la mayor captura de N ocurre desde V6 hacia espigamiento y floración, por eso esta lectura pesa mucho más aquí.';
        }
        if (reproductiveStage) {
          return 'En maíz, todavía hay demanda de N cerca de floración y llenado temprano, aunque la utilidad de corregir cae cuando el ciclo ya viene muy avanzado.';
        }
        return 'En cierre de ciclo, el N sirve más para trazabilidad y aprendizaje del siguiente plan que para empujar tarde por rutina.';
      case 'p':
        if (earlyStage) {
          return 'El P pesa más al arranque por su relación con raíces, energía y uniformidad; la respuesta suele ser más probable en suelos bajos en P, fríos o con residuo alto.';
        }
        return 'En maíz, el P sigue importando, pero normalmente su mejor retorno está en llegar bien colocado desde arranque y no en sobrecorregir tarde.';
      case 'k':
        if (reproductiveStage || peakNitrogenStage) {
          return 'En maíz, K ayuda a sostener agua, tallo y estabilidad fisiológica, especialmente cuando sube el estrés térmico o hídrico.';
        }
        return 'K acompaña balance fisiológico durante todo el ciclo y puede volverse limitante antes en suelos arenosos o de baja CEC.';
      default:
        return 'Este nutriente merece seguimiento según etapa y contexto del lote.';
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
