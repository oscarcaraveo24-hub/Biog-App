// lib/core/agro/agro_types.dart
import 'package:bio_g/models/biog_telemetry.dart';

/// Métricas que el motor interpreta.
enum AgroMetricKey { soilMoisture, soilTemp, ph, ec, resistance, n, p, k }

extension AgroMetricKeyX on AgroMetricKey {
  bool get isNutrient =>
      this == AgroMetricKey.n ||
      this == AgroMetricKey.p ||
      this == AgroMetricKey.k;

  String get labelEs {
    switch (this) {
      case AgroMetricKey.soilMoisture:
        return 'Humedad';
      case AgroMetricKey.soilTemp:
        return 'Temperatura';
      case AgroMetricKey.ph:
        return 'pH';
      case AgroMetricKey.ec:
        return 'CE';
      case AgroMetricKey.resistance:
        return 'Resistencia';
      case AgroMetricKey.n:
        return 'Nitrógeno';
      case AgroMetricKey.p:
        return 'Fósforo';
      case AgroMetricKey.k:
        return 'Potasio';
    }
  }

  String get shortLabel {
    switch (this) {
      case AgroMetricKey.soilMoisture:
        return 'Humedad';
      case AgroMetricKey.soilTemp:
        return 'Temp';
      case AgroMetricKey.ph:
        return 'pH';
      case AgroMetricKey.ec:
        return 'CE';
      case AgroMetricKey.resistance:
        return 'Resist';
      case AgroMetricKey.n:
        return 'N';
      case AgroMetricKey.p:
        return 'P';
      case AgroMetricKey.k:
        return 'K';
    }
  }

  String get defaultUnit {
    switch (this) {
      case AgroMetricKey.soilMoisture:
        return '%';
      case AgroMetricKey.soilTemp:
        return '°C';
      case AgroMetricKey.ph:
        return 'pH';
      case AgroMetricKey.ec:
        return 'mS/cm';
      case AgroMetricKey.resistance:
        return 'MPa';
      case AgroMetricKey.n:
      case AgroMetricKey.p:
      case AgroMetricKey.k:
        // Señal nativa de la sonda: sin unidad química en pantalla (Guía
        // v0.4, §8). «sensor» es lo que muestran los medidores.
        return 'sensor';
    }
  }
}

/// Banda de una condición FÍSICA del suelo (humedad, temperatura, pH, CE, RT).
///
/// N, P y K ya no tienen banda. Desde el NPK Interpretation Reset (Guía oficial
/// del nuevo motor nutricional v0.4, §4) esos tres canales viajan como
/// **señal nativa**: se guardan, se grafican y forman parte de una firma de
/// tendencia, pero ningún motor los clasifica como bajo/óptimo/alto/crítico.
/// El único valor que un canal nativo puede llevar aquí es [unknown], y no
/// significa «sin dato»: significa «sin diagnóstico». Ver
/// [AgroMetricEval.isNativeSignal].
enum AgroBand { low, optimal, high, critical, unknown }

extension AgroBandX on AgroBand {
  String get labelEs {
    switch (this) {
      case AgroBand.low:
        return 'Bajo';
      case AgroBand.optimal:
        return 'Óptimo';
      case AgroBand.high:
        return 'Alto';
      case AgroBand.critical:
        return 'Crítico';
      case AgroBand.unknown:
        return '—';
    }
  }

  bool get isKnown => this != AgroBand.unknown;
}

/// Cobertura de evidencia física del suelo: cuántas de las señales evaluables
/// llegaron con dato en esta lectura.
///
/// Existe porque «score» y «cobertura» son dos números distintos y antes eran
/// uno solo (Guía v0.4, §6 «Score y cobertura se separan»). Un canal ausente no
/// vale 0 ni 0.5: sale del denominador del score y se cuenta aquí, aparte, para
/// que el suelo no «empeore» porque un cable dejó de reportar y para que el
/// agricultor vea con cuánta evidencia se calculó el número que tiene enfrente:
/// «Condición del suelo 89 % · 4 de 5 señales».
///
/// Las cinco señales evaluables son las físicas: humedad, temperatura, pH, CE y
/// resistencia. N/P/K no entran ni al numerador ni al denominador.
class SoilSignalCoverage {
  const SoilSignalCoverage({
    required this.evaluable,
    required this.present,
    this.missing = const <AgroMetricKey>[],
  });

  /// Sin ninguna señal evaluada. Es el valor por omisión de una evaluación
  /// construida a mano (pruebas, respaldos), nunca el de un motor real.
  static const SoilSignalCoverage empty = SoilSignalCoverage(
    evaluable: 0,
    present: 0,
  );

  /// Señales que el motor sabe evaluar para este cultivo (normalmente 5).
  final int evaluable;

  /// Señales que llegaron con dato en esta lectura.
  final int present;

  /// Señales evaluables que no llegaron, para poder decir cuál falta.
  final List<AgroMetricKey> missing;

  bool get hasAnySignal => present > 0;

  bool get isComplete => evaluable > 0 && present >= evaluable;

  /// Fracción 0..1 de evidencia disponible.
  double get coverage01 =>
      evaluable <= 0 ? 0.0 : (present / evaluable).clamp(0.0, 1.0);

  /// «4 de 5 señales», listo para pantalla.
  String get labelEs {
    if (evaluable <= 0) return 'Sin señales evaluables';
    return '$present de $evaluable señales';
  }

  /// Nombres cortos de lo que falta: «pH, CE».
  String get missingLabelEs =>
      missing.map((AgroMetricKey k) => k.shortLabel).join(', ');
}

class AgroRange {
  const AgroRange({
    required this.lowMax,
    required this.optimalMin,
    required this.optimalMax,
    required this.highMin,
  });

  final double lowMax;
  final double optimalMin;
  final double optimalMax;
  final double highMin;
}

/// Evaluación de UNA métrica dentro de la capa de interpretación física.
///
/// Esta clase es capa 2 de las tres que ordenan BIO-G (Guía v0.4, §2): dato
/// crudo → **interpretación física** → agronomía y decisión. Por eso aquí solo
/// cabe lo que se puede afirmar del suelo con la sonda: banda, puntaje y valor.
/// Lo que antes viajaba en esta misma clase —etiqueta de prioridad, dosis,
/// equivalente comercial, justificación, presión fenológica— era capa 3
/// disfrazada de capa 2, y salió del runtime con el NPK Interpretation Reset.
/// El manejo nutricional vive ahora en `NutritionDecision`
/// (`lib/core/agro/nutrition/`), que responde otra pregunta y tiene otro
/// contrato.
class AgroMetricEval {
  const AgroMetricEval({
    required this.band,
    required this.score01,
    required this.labelEs,
    this.value,
    this.isNativeSignal = false,
  });

  /// Canal N, P o K tal como lo reporta la sonda: **señal nativa**.
  ///
  /// La banda queda en [AgroBand.unknown] a propósito y NO significa «sin dato»
  /// —[value] trae la lectura si la hubo—: significa que este número no se
  /// clasifica. La sonda 7-en-1 deriva N/P/K de la conductividad, no los mide
  /// químicamente, y compararlos contra un objetivo de cultivo fabricaba
  /// diagnósticos («N bajo», «P crítico») que el hardware no sostiene.
  ///
  /// Dónde SÍ sirve la señal: historial, tendencias dentro del mismo sitio y
  /// respuesta temporal alrededor de un riego o una fertilización (Guía v0.4,
  /// §3, §12). Eso lo lee el motor nutricional desde el historial, no desde
  /// esta evaluación puntual.
  ///
  /// `hasData` en falso produce `value == null`; con dato, el valor crudo en
  /// mg/kg nominales de la sonda.
  factory AgroMetricEval.nativeSignal({
    required double? value,
    required bool hasData,
  }) {
    final bool present = hasData && value != null && value.isFinite;
    return AgroMetricEval(
      band: AgroBand.unknown,
      score01: 0.0,
      labelEs: present ? 'Tendencia del sensor' : AgroBand.unknown.labelEs,
      value: present ? value : null,
      isNativeSignal: true,
    );
  }

  final AgroBand band;

  /// Puntaje 0..1 de la condición física. Para una señal nativa es 0.0 y no se
  /// usa: N/P/K tienen peso cero en el score por decisión, no por descuido.
  final double score01;

  final String labelEs;
  final double? value;

  /// True para N/P/K. Ver [AgroMetricEval.nativeSignal].
  final bool isNativeSignal;

  /// Hay lectura de la sonda para este canal (banda conocida, o señal nativa
  /// con valor). Una banda `unknown` de un canal físico significa que el
  /// sensor no reportó; en una señal nativa la banda siempre es `unknown`, así
  /// que ahí la verdad está en el valor.
  bool get hasData => isNativeSignal ? value != null : band.isKnown;

  AgroMetricEval copyWith({
    AgroBand? band,
    double? score01,
    String? labelEs,
    double? value,
    bool? isNativeSignal,
  }) {
    return AgroMetricEval(
      band: band ?? this.band,
      score01: score01 ?? this.score01,
      labelEs: labelEs ?? this.labelEs,
      value: value ?? this.value,
      isNativeSignal: isNativeSignal ?? this.isNativeSignal,
    );
  }
}

/// Resultado de un motor de score: condición física del suelo + alertas.
///
/// El score nutricional (`nutrientPriorityScore01`) y su «tipo de score
/// primario» desaparecieron con el reset: N/P/K crudos no forman puntaje
/// alguno. Si alguna vez existe un número de «manejo nutricional», saldrá de
/// `NutritionDecision`, con otra semántica, y no volverá a mezclarse con la
/// condición del suelo en el mismo denominador.
class AgroEvalResult {
  const AgroEvalResult({
    required this.soilControlScore01,
    required this.metrics,
    required this.alerts,
    required this.suggestedAlertKeys,
    this.soilCoverage = SoilSignalCoverage.empty,
  });

  /// Condición física del suelo, 0..1, calculada SOLO con las señales físicas
  /// que llegaron con dato. Ver [SoilSignalCoverage].
  final double soilControlScore01;

  /// Con cuánta evidencia se calculó [soilControlScore01].
  final SoilSignalCoverage soilCoverage;

  final Map<AgroMetricKey, AgroMetricEval> metrics;
  final List<BioGAlert> alerts;
  final List<String> suggestedAlertKeys;

  AgroMetricEval? metricOf(AgroMetricKey key) => metrics[key];
  AgroMetricEval? get nitrogen => metrics[AgroMetricKey.n];
  AgroMetricEval? get phosphorus => metrics[AgroMetricKey.p];
  AgroMetricEval? get potassium => metrics[AgroMetricKey.k];

  /// True cuando el score se calculó sin ninguna señal física: en ese caso
  /// [soilControlScore01] vale 0.0 por construcción y NO debe pintarse como
  /// «0 % de salud». Las pantallas muestran «sin datos».
  bool get hasSoilEvidence => soilCoverage.hasAnySignal;

  AgroEvalResult copyWith({
    double? soilControlScore01,
    SoilSignalCoverage? soilCoverage,
    Map<AgroMetricKey, AgroMetricEval>? metrics,
    List<BioGAlert>? alerts,
    List<String>? suggestedAlertKeys,
  }) {
    return AgroEvalResult(
      soilControlScore01: soilControlScore01 ?? this.soilControlScore01,
      soilCoverage: soilCoverage ?? this.soilCoverage,
      metrics: metrics ?? this.metrics,
      alerts: alerts ?? this.alerts,
      suggestedAlertKeys: suggestedAlertKeys ?? this.suggestedAlertKeys,
    );
  }
}

/// Calibración de escalas relativas.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// LA HUMEDAD YA NO ESTÁ AQUÍ, Y NO ES UN OLVIDO
/// ─────────────────────────────────────────────────────────────────────────────
///
/// `moistureDryRaw` y `moistureWetRaw` se **borraron**. Convertían el contenido
/// volumétrico en un índice relativo 0–100 con dos puntos aire/agua, y eso
/// corresponde a otra clase de sonda: la capacitiva analógica barata. El sensor
/// que monta el prototipo entrega contenido volumétrico ya calibrado de
/// fábrica, y el contrato de datos crudos lo dice literalmente: *la humedad no
/// necesita calibración de usuario*.
///
/// Verificado antes de borrarlas: el tipo tenía dos consumidores y **cero
/// productores**. Nadie instanciaba una `Calibration` en toda la app ni en las
/// pruebas, y no existía pantalla para hacerlo.
///
/// Se borran en vez de dejarlas dormidas porque un condicional que nadie puede
/// activar hoy pero que alguien activará dentro de seis meses es peor que
/// ninguno: para entonces nadie recordará por qué estaba ahí. Y el efecto sería
/// que el motor de riego leyera 25 % como 25 % mientras el de puntuación leyera
/// ese mismo 25 % como 58 % relativo, y el Panel dijera una cosa mientras
/// Recomendaciones dice otra, sobre la misma lectura, en la misma pantalla.
///
/// Las escalas de N, P, K y resistencia se conservan: esas SÍ son índices
/// relativos por naturaleza.
class Calibration {
  const Calibration({
    this.nMinRaw,
    this.nMaxRaw,
    this.pMinRaw,
    this.pMaxRaw,
    this.kMinRaw,
    this.kMaxRaw,
    this.resistanceMinRaw,
    this.resistanceMaxRaw,
  });

  final double? nMinRaw;
  final double? nMaxRaw;
  final double? pMinRaw;
  final double? pMaxRaw;
  final double? kMinRaw;
  final double? kMaxRaw;
  final double? resistanceMinRaw;
  final double? resistanceMaxRaw;
}

class AlertsState {
  const AlertsState({this.lastByType = const {}, this.lastByKey = const {}});

  /// Última emisión por tipo de alerta. Se conserva por compatibilidad.
  final Map<BioGAlertType, DateTime> lastByType;

  /// Última emisión por par (tipo, severidad).
  ///
  /// El anti-spam se decide con este mapa y no con [lastByType]: con la cubeta
  /// por tipo, una alerta de "humedad baja" (warning) silenciaba durante todo
  /// el cooldown a la "humedad crítica" que llegaba después — justo la que
  /// nunca hay que callar.
  final Map<String, DateTime> lastByKey;

  /// Clave de cooldown para un par tipo/severidad.
  static String cooldownKey(BioGAlertType type, BioGAlertSeverity severity) =>
      '${type.name}|${severity.name}';

  AlertsState copyWith({
    Map<BioGAlertType, DateTime>? lastByType,
    Map<String, DateTime>? lastByKey,
  }) => AlertsState(
    lastByType: lastByType ?? this.lastByType,
    lastByKey: lastByKey ?? this.lastByKey,
  );
}

class AlertsBuildResult {
  const AlertsBuildResult({required this.alerts, required this.state});
  final List<BioGAlert> alerts;
  final AlertsState state;
}
