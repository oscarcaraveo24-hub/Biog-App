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

    // ── Nitrógeno ──
    if (key == 'npk.n.critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Nitrógeno fuera de rango',
        body:
            'El nitrógeno disponible está fuera del rango esperado para '
            '$crop en $stage. Es el nutriente más demandado en etapas '
            'vegetativas — verifica la dosificación de fertilizante '
            'nitrogenado.',
      );
    }
    if (key == 'npk.n.low') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Nitrógeno bajo',
        body:
            'El N disponible es bajo para $crop. Esto puede causar '
            'hojas amarillentas y menor crecimiento.',
      );
    }
    if (key == 'npk.n.high') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Nitrógeno alto',
        body:
            'El N disponible es alto para $crop. Exceso puede causar '
            'crecimiento vegetativo excesivo y retrasar madurez.',
      );
    }

    // ── Fósforo ──
    if (key == 'npk.p.critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Fósforo fuera de rango',
        body:
            'El fósforo disponible está fuera de rango para $crop en '
            '$stage. Es esencial para el desarrollo radicular y la '
            'floración. Revisa aplicación de fosfato.',
      );
    }
    if (key == 'npk.p.low') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Fósforo bajo',
        body:
            'El P disponible es bajo para $crop. Puede limitar el '
            'enraizamiento y la fijación de fruto.',
      );
    }
    if (key == 'npk.p.high') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Fósforo alto',
        body:
            'El P disponible es alto para $crop. Exceso puede bloquear '
            'absorción de zinc y hierro.',
      );
    }

    // ── Potasio ──
    if (key == 'npk.k.critical') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.warning,
        title: 'Potasio fuera de rango',
        body:
            'El potasio disponible está fuera de rango para $crop en '
            '$stage. Es clave para el transporte de azúcares y la '
            'resistencia a enfermedades.',
      );
    }
    if (key == 'npk.k.low') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Potasio bajo',
        body:
            'El K disponible es bajo para $crop. Puede debilitar la '
            'resistencia a plagas y afectar calidad de grano.',
      );
    }
    if (key == 'npk.k.high') {
      return _AlertTemplate(
        type: BioGAlertType.stageEvent,
        severity: BioGAlertSeverity.info,
        title: 'Potasio alto',
        body:
            'El K disponible es alto para $crop. Puede interferir con '
            'absorción de calcio y magnesio.',
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
