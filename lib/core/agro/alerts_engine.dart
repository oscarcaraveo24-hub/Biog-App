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

    final cropLc = crop.toLowerCase();
    final isMaize = cropLc.contains('maíz') ||
        cropLc.contains('maiz') ||
        cropLc.contains('corn') ||
        cropLc.contains('maize');
    final stageLc = stage.toLowerCase();

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
