// lib/core/agro/nutrition/nutrition_types.dart
//
// Tipos del NUTRITION READINESS ENGINE (Guía oficial del nuevo motor
// nutricional v0.4, §9–§15) con la regla de producto que la completa:
//
//   «El agricultor NO registra que fertilizó. BIO-G lo detecta.»
//
// El motor responde una pregunta distinta a la del motor NPK anterior. Aquél
// preguntaba «¿cuánto nitrógeno hay en el suelo?» y contestaba con una lectura
// que la sonda no puede sostener. Éste pregunta: «¿qué manejo nutricional
// corresponde ahora, y qué parece haber ocurrido en la zona radicular?». La
// respuesta es una [NutritionDecision], que viaja al Panel, a la pantalla de
// nutrición, al EventEngine y a la bandeja de avisos exactamente como hoy
// viaja `IrrigationDecision`: una sola autoridad, sin segundas verdades
// deducidas por otra pantalla.
//
// TRES FUENTES, TRES PAPELES
//   · La guía y la etapa dicen QUÉ debería ocurrir (ventana nutricional).
//   · El sensor observa QUÉ parece haber ocurrido (firma de fertilización).
//   · El historial del sitio ayuda a comparar si esa respuesta es normal aquí.
//
// FRONTERA (Guía v0.4, §2 y §37): ningún tipo de este archivo transporta un
// diagnóstico químico. Las señales N/P/K de la sonda acompañan una firma como
// canal auxiliar de consistencia; nunca deciden por sí solas. Y no existe
// ningún campo «aplicación registrada por el productor»: un error humano al
// registrar descalibraría el sistema, así que esa entrada no existe.
import 'package:bio_g/core/agro/agro_types.dart';

/// Estado simplificado del manejo nutricional (Guía v0.4, §9).
enum NutritionState {
  /// Primera semana del sitio: BIO-G funciona, pero las comparaciones
  /// históricas fuertes todavía no. No bloquea ninguna función básica.
  learning,

  /// Sin ventana nutricional relevante. Se observan tendencias.
  monitor,

  /// Se aproxima una ventana de alta demanda, o la ventana está abierta pero
  /// las condiciones físicas no permiten aplicar todavía.
  prepare,

  /// La etapa abre una ventana de manejo nutricional y el sensor todavía no
  /// ha visto una respuesta compatible con fertilización. Aquí —y solo aquí—
  /// la app presenta la recomendación (con rango de dosis si la guía auditada
  /// lo sostiene) mientras observa el suelo para reconocer cuándo se atendió.
  actionWindow,

  /// Se detectó una firma compatible con fertilización y el sensor sigue la
  /// respuesta del sitio. La advertencia de ventana pendiente desaparece; no
  /// se empuja dosis mientras dura.
  responseWindow,
}

extension NutritionStateX on NutritionState {
  String get labelEs => switch (this) {
    NutritionState.learning => 'Aprendiendo la zona',
    NutritionState.monitor => 'Seguimiento',
    NutritionState.prepare => 'Preparación',
    NutritionState.actionWindow => 'Esta etapa necesita nutrición',
    NutritionState.responseWindow => 'Observando la respuesta del suelo',
  };

  /// Etiqueta corta para chips y tarjetas.
  String get tagEs => switch (this) {
    NutritionState.learning => 'Aprendiendo',
    NutritionState.monitor => 'Seguimiento',
    NutritionState.prepare => 'Prepara',
    NutritionState.actionWindow => 'Ventana',
    NutritionState.responseWindow => 'Respuesta',
  };

  bool get isActionWindow => this == NutritionState.actionWindow;
  bool get isResponseWindow => this == NutritionState.responseWindow;
}

/// Prioridad fenológica de un nutriente en la etapa actual.
///
/// Sale de la guía/perfil del cultivo (etapa → prioridad 0..1), no de la sonda.
enum NutritionPriority { low, medium, high }

extension NutritionPriorityX on NutritionPriority {
  String get labelEs => switch (this) {
    NutritionPriority.low => 'Baja',
    NutritionPriority.medium => 'Media',
    NutritionPriority.high => 'Alta',
  };

  int get rank => switch (this) {
    NutritionPriority.low => 0,
    NutritionPriority.medium => 1,
    NutritionPriority.high => 2,
  };

  /// Umbrales sobre la prioridad 0..1 del perfil. Son una decisión de producto
  /// (Guía v0.4, §38: «copys exactos de prioridades por etapa» quedan abiertos)
  /// y viven en un solo sitio para poder auditarlos.
  static NutritionPriority fromPriority01(double p) {
    if (p >= kHighPriorityThreshold01) return NutritionPriority.high;
    if (p >= kMediumPriorityThreshold01) return NutritionPriority.medium;
    return NutritionPriority.low;
  }

  /// A partir de aquí la etapa DEMANDA el nutriente: candidata a ventana.
  static const double kHighPriorityThreshold01 = 0.60;

  /// Entre este umbral y el alto, el nutriente importa pero no abre ventana.
  static const double kMediumPriorityThreshold01 = 0.35;

  /// A partir de aquí la ventana se considera AGRONÓMICAMENTE IMPORTANTE: si
  /// TERMINA sin evidencia suficiente de haber sido atendida, el resultado
  /// puede pesar en el score histórico, en el estado global del cultivo y en
  /// la proyección de rendimiento (Guía v0.4, §6 «Cuándo sí puede influir la
  /// nutrición»). Mientras está abierta no penaliza nada.
  static const double kCriticalPriorityThreshold01 = 0.75;
}

/// Prioridad de UN nutriente en la etapa actual, con su ventana y su porqué.
class NutrientStagePriority {
  const NutrientStagePriority({
    required this.nutrient,
    required this.priority,
    required this.priority01,
    required this.windowLabelEs,
    required this.rationaleEs,
    this.guidanceEs,
    this.isCriticalWindow = false,
  });

  final AgroMetricKey nutrient;
  final NutritionPriority priority;

  /// Prioridad 0..1 tal como la declara el perfil/guía para esta etapa.
  final double priority01;

  /// Ventana fisiológica en lenguaje del agricultor («Tramo fuerte de N»).
  final String windowLabelEs;

  /// Por qué importa este nutriente en esta etapa. Conocimiento fenológico
  /// conservado del catálogo (Guía v0.4, §5).
  final String rationaleEs;

  /// Guía corta del perfil, si existe.
  final String? guidanceEs;

  /// La etapa marca esta ventana como agronómicamente importante para este
  /// nutriente.
  final bool isCriticalWindow;

  /// Nombre corto: N, P o K.
  String get shortLabel => nutrient.shortLabel;

  /// Nombre largo: Nitrógeno, Fósforo, Potasio.
  String get labelEs => nutrient.labelEs;
}

/// Forma en la que se expresa un nutriente en una dosis.
///
/// Las guías mezclan formas —a veces en el mismo documento— y el factor entre
/// elemental y óxido es 2.291 para el fósforo y 1.205 para el potasio. Declarar
/// la forma junto al número es lo que evita el defecto que el planner de
/// frutales documenta en su cabecera.
enum NutrientForm { n, p2o5, k2o }

extension NutrientFormX on NutrientForm {
  String get labelEs => switch (this) {
    NutrientForm.n => 'N',
    NutrientForm.p2o5 => 'P₂O₅',
    NutrientForm.k2o => 'K₂O',
  };

  AgroMetricKey get nutrient => switch (this) {
    NutrientForm.n => AgroMetricKey.n,
    NutrientForm.p2o5 => AgroMetricKey.p,
    NutrientForm.k2o => AgroMetricKey.k,
  };
}

/// Unidad en la que se expresa un rango de dosis.
enum DoseUnit { kgPerHectare, gramsPerSquareMeter, gramsPerPlant, gramsPerPot }

extension DoseUnitX on DoseUnit {
  String get labelEs => switch (this) {
    DoseUnit.kgPerHectare => 'kg/ha',
    DoseUnit.gramsPerSquareMeter => 'g/m²',
    DoseUnit.gramsPerPlant => 'g por planta',
    DoseUnit.gramsPerPot => 'g por maceta',
  };
}

/// Rango orientativo de dosis que SÍ proviene de una guía (nunca de la sonda).
///
/// Es un rango y no una cifra exacta a propósito (Guía v0.4, §10: «una sola
/// cifra exacta con falsa precisión» no está permitida).
class NutritionDoseRange {
  const NutritionDoseRange({
    required this.min,
    required this.max,
    required this.form,
    required this.unit,
    required this.sourceEs,
    this.commercialEquivalentEs,
    this.transparencyEs,
  });

  final double min;
  final double max;
  final NutrientForm form;
  final DoseUnit unit;

  /// De dónde sale el rango (guía, coeficiente de extracción, etc.).
  final String sourceEs;

  /// Equivalente en producto comercial, si la guía lo sostiene
  /// («≈ 110–150 kg/ha de urea»).
  final String? commercialEquivalentEs;

  /// Frase que declara los supuestos del cálculo.
  final String? transparencyEs;

  String get labelEs {
    final String lo = _fmt(min);
    final String hi = _fmt(max);
    final String range = lo == hi ? lo : '$lo–$hi';
    return '$range ${unit.labelEs} de ${form.labelEs}';
  }

  static String _fmt(double v) {
    if (v >= 100) return v.round().toString();
    if (v >= 10) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}

/// Estatus de auditoría de una guía o de un rango.
///
/// La Guía v0.4 (§5) exige auditar las guías cultivo por cultivo antes de
/// confiar en ellas como autoridad. Un rango `proposed` existe en el código
/// con su fuente, pero **no se muestra al agricultor** hasta que alguien lo
/// marque `audited`.
enum GuideAuditStatus { audited, proposed, pending }

extension GuideAuditStatusX on GuideAuditStatus {
  String get labelEs => switch (this) {
    GuideAuditStatus.audited => 'Guía auditada',
    GuideAuditStatus.proposed => 'Guía propuesta, pendiente de auditoría',
    GuideAuditStatus.pending => 'Guía pendiente',
  };

  bool get canShowDose => this == GuideAuditStatus.audited;
}

/// Recomendación de manejo nutricional dentro de una ventana abierta.
///
/// Puede venir sin rango de dosis: entonces [doseUnavailableReasonEs] explica
/// por qué la app no emite una cifra todavía (Guía v0.4, §10: «pedir el mínimo
/// contexto necesario o explicar por qué no puede emitir una cifra; nunca
/// rellenar el hueco con NPK raw»).
class NutritionRecommendation {
  const NutritionRecommendation({
    required this.nutrient,
    required this.headlineEs,
    required this.detailEs,
    required this.audit,
    this.doseRange,
    this.doseUnavailableReasonEs,
    this.sourceOptionsEs = const <String>[],
    this.rulesEs = const <String>[],
    this.timingEs,
  });

  final AgroMetricKey nutrient;
  final String headlineEs;
  final String detailEs;
  final GuideAuditStatus audit;

  /// Rango de dosis defendible. Null cuando la guía no lo sostiene o no está
  /// auditada.
  final NutritionDoseRange? doseRange;

  /// Por qué no hay cifra (guía pendiente de auditoría, falta la cosecha
  /// esperada por árbol, falta la escala de cultivo…).
  final String? doseUnavailableReasonEs;

  /// Fuentes comerciales que la guía respalda para este nutriente/etapa.
  final List<String> sourceOptionsEs;

  /// Reglas 3R y restricciones: momento, lugar, fuente, condiciones.
  final List<String> rulesEs;

  /// Cuándo conviene aplicar dentro de la ventana («antes de V8»).
  final String? timingEs;

  bool get hasDose => doseRange != null;
}

/// Resultado de comprobar si las condiciones físicas permiten aplicar.
///
/// Aplicar sobre suelo seco, encharcado o salino desperdicia producto y puede
/// dañar la raíz. El motor de nutrición no ordena regar ni corrige el suelo:
/// solo dice «todavía no» y por qué.
class NutritionConditionCheck {
  const NutritionConditionCheck({
    required this.allowsApplication,
    this.blockersEs = const <String>[],
    this.cautionsEs = const <String>[],
    this.evaluatedSignals = 0,
  });

  static const NutritionConditionCheck unknown = NutritionConditionCheck(
    allowsApplication: true,
    cautionsEs: <String>[
      'Sin lecturas físicas recientes: no se pudo comprobar humedad, sales ni '
          'temperatura antes de aplicar.',
    ],
  );

  /// True cuando ninguna condición física bloquea la aplicación.
  final bool allowsApplication;

  /// Condiciones que impiden aplicar ahora (suelo muy seco, saturado, sales
  /// altas…).
  final List<String> blockersEs;

  /// Advertencias que no bloquean pero conviene leer.
  final List<String> cautionsEs;

  /// Cuántas señales físicas se pudieron evaluar (0..5).
  final int evaluatedSignals;
}

// ═══════════════════════════════════════════════════════════════════════════
// FIRMA DE FERTILIZACIÓN DETECTADA
// ═══════════════════════════════════════════════════════════════════════════

/// Patrón temporal OBSERVADO en una firma de fertilización (Guía v0.4, §30
/// «Caso especial: urea»).
///
/// Nadie declara el producto: la forma de la respuesta es lo que se ve.
enum SignatureKind {
  /// Escalón de carga iónica en horas o 1–2 días: sales solubles (KCl,
  /// sulfatos, nitratos), fertirriego.
  ionicImmediate,

  /// Subida gradual a lo largo de días, sin escalón: compatible con urea
  /// (hidrólisis y nitrificación) o con liberación lenta. Se confirma con más
  /// cautela y necesita más días de observación.
  delayedGradual,

  /// Escalón inicial seguido de una segunda subida tardía o de varios saltos
  /// relacionados: mezclas, dosis partidas, fertirriego en pulsos.
  mixed,
}

extension SignatureKindX on SignatureKind {
  String get labelEs => switch (this) {
    SignatureKind.ionicImmediate => 'Respuesta iónica inmediata',
    SignatureKind.delayedGradual => 'Respuesta gradual (compatible con urea)',
    SignatureKind.mixed => 'Respuesta en varios pulsos',
  };

  /// Días que el sensor sigue la respuesta después del último salto antes de
  /// dar la ventana de respuesta por cerrada.
  ///
  /// Umbrales de arranque, marcados como pendientes de datos reales de eventos
  /// (Guía v0.4, §38).
  int get responseHorizonDays => switch (this) {
    SignatureKind.ionicImmediate => 5,
    SignatureKind.delayedGradual => 14,
    SignatureKind.mixed => 10,
  };
}

/// Qué hizo la humedad alrededor del salto de carga iónica.
///
/// Es la pieza que separa «fertilizó» de «solo regó»: un riego con agua sube
/// la conductividad aparente porque el suelo mojado conduce más, pero la carga
/// iónica normalizada por humedad no sube; un fertilizante la sube.
enum VwcContext {
  /// La humedad subió y la carga iónica normalizada también: fertirriego o
  /// fertilizante disuelto por el riego. Firma fuerte.
  fertigationLike,

  /// La humedad no cambió y la carga iónica normalizada subió: producto
  /// disuelto por la humedad existente o aplicado en solución con poca agua.
  dissolvedInPlace,

  /// La humedad subió, la conductividad bruta subió, pero la normalizada no:
  /// riego con agua sola. NO es firma de fertilización.
  waterOnly,

  /// La humedad bajó mientras la normalizada subía un poco: puede ser un
  /// artefacto del cociente CE/humedad en suelo secándose. Se descuenta.
  dryingArtifact,

  /// Sin lectura de humedad: no se puede separar riego de fertirriego. La
  /// confianza queda acotada.
  unknown,
}

extension VwcContextX on VwcContext {
  String get labelEs => switch (this) {
    VwcContext.fertigationLike => 'Compatible con fertirriego o riego tras aplicar',
    VwcContext.dissolvedInPlace => 'Producto disuelto con la humedad existente',
    VwcContext.waterOnly => 'Riego con agua sola (no cuenta como fertilización)',
    VwcContext.dryingArtifact => 'Suelo secándose: cambio descontado',
    VwcContext.unknown => 'Sin lectura de humedad para contextualizar',
  };
}

/// Firma compatible con fertilización detectada por el sensor dentro de una
/// ventana nutricional. Varios saltos relacionados dentro de la misma ventana
/// forman UNA firma, no varios eventos.
class FertilizationSignature {
  const FertilizationSignature({
    required this.startedAt,
    required this.lastJumpAt,
    required this.peakAt,
    required this.kind,
    required this.confidence01,
    required this.ecPeakMad,
    required this.vwcContext,
    this.jumpCount = 1,
    this.ecRawPeakMad,
    this.nFollowMad,
    this.pFollowMad,
    this.kFollowMad,
    this.vwcDeltaPct,
    this.evidenceEs = const <String>[],
  });

  /// Primer salto (o inicio de la subida gradual).
  final DateTime startedAt;

  /// Último salto relacionado dentro de la misma ventana.
  final DateTime lastJumpAt;

  /// Momento del máximo de carga iónica normalizada.
  final DateTime peakAt;

  final SignatureKind kind;

  /// Confianza 0..1 de que lo observado corresponde a una fertilización.
  final double confidence01;

  /// Máximo de la carga iónica NORMALIZADA POR HUMEDAD (o de la CE bruta si no
  /// hay humedad), en MAD sobre la referencia previa a la firma.
  final double ecPeakMad;

  /// Máximo de la CE bruta en MAD, para trazabilidad.
  final double? ecRawPeakMad;

  final VwcContext vwcContext;

  /// Cuántos saltos relacionados agrupa esta firma.
  final int jumpCount;

  /// Canales nativos N/P/K en MAD sobre su propia referencia. Acompañan como
  /// comprobación de consistencia; no confirman ni cuantifican nada.
  final double? nFollowMad;
  final double? pFollowMad;
  final double? kFollowMad;

  /// Cambio de humedad volumétrica alrededor del primer salto (puntos de VWC).
  final double? vwcDeltaPct;

  /// Frases de evidencia («Carga iónica +4.2 MAD», «canal N acompañó»).
  final List<String> evidenceEs;

  /// A partir de aquí la firma se considera COMPATIBLE con fertilización: la
  /// ventana queda atendida y la advertencia pendiente desaparece.
  static const double kCompatibleConfidence01 = 0.60;

  /// Entre este umbral y el compatible hay un cambio que PODRÍA ser
  /// fertilización: se sigue observando sin cerrar la ventana.
  static const double kPossibleConfidence01 = 0.40;

  bool get isCompatible => confidence01 >= kCompatibleConfidence01;
  bool get isPossible =>
      confidence01 >= kPossibleConfidence01 && !isCompatible;

  /// Hasta cuándo se sigue la respuesta del sitio.
  DateTime get responseHorizonEndsAt =>
      lastJumpAt.add(Duration(days: kind.responseHorizonDays));

  bool isFollowingResponseAt(DateTime now) =>
      now.isBefore(responseHorizonEndsAt);

  /// Confianza en lenguaje del agricultor.
  String get confidenceLabelEs {
    if (confidence01 >= 0.80) return 'alta';
    if (isCompatible) return 'media';
    if (isPossible) return 'baja';
    return 'insuficiente';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'startedAt': startedAt.toUtc().toIso8601String(),
    'lastJumpAt': lastJumpAt.toUtc().toIso8601String(),
    'peakAt': peakAt.toUtc().toIso8601String(),
    'kind': kind.name,
    'confidence01': confidence01,
    'ecPeakMad': ecPeakMad,
    'ecRawPeakMad': ecRawPeakMad,
    'vwcContext': vwcContext.name,
    'jumpCount': jumpCount,
    'nFollowMad': nFollowMad,
    'pFollowMad': pFollowMad,
    'kFollowMad': kFollowMad,
    'vwcDeltaPct': vwcDeltaPct,
    'evidenceEs': evidenceEs,
  };

  static FertilizationSignature? tryFromJson(Map<String, dynamic> json) {
    final DateTime? started = _date(json['startedAt']);
    final DateTime? lastJump = _date(json['lastJumpAt']) ?? started;
    final DateTime? peak = _date(json['peakAt']) ?? started;
    final double? confidence = _num(json['confidence01']);
    final double? ecPeak = _num(json['ecPeakMad']);
    if (started == null ||
        lastJump == null ||
        peak == null ||
        confidence == null ||
        ecPeak == null) {
      return null;
    }
    return FertilizationSignature(
      startedAt: started,
      lastJumpAt: lastJump,
      peakAt: peak,
      kind: _enum(SignatureKind.values, json['kind']) ??
          SignatureKind.ionicImmediate,
      confidence01: confidence.clamp(0.0, 1.0),
      ecPeakMad: ecPeak,
      ecRawPeakMad: _num(json['ecRawPeakMad']),
      vwcContext:
          _enum(VwcContext.values, json['vwcContext']) ?? VwcContext.unknown,
      jumpCount: (_num(json['jumpCount']) ?? 1).round().clamp(1, 1 << 20),
      nFollowMad: _num(json['nFollowMad']),
      pFollowMad: _num(json['pFollowMad']),
      kFollowMad: _num(json['kFollowMad']),
      vwcDeltaPct: _num(json['vwcDeltaPct']),
      evidenceEs: _strings(json['evidenceEs']),
    );
  }
}

/// Qué tan observable fue la ventana: sin esto no se puede decir honestamente
/// «no hubo evidencia» (Guía v0.4, §6 «Protección importante»).
enum ScanObservability {
  /// Hubo lecturas de CE con humedad suficiente a lo largo de la ventana.
  ok,

  /// No hubo lecturas en la ventana (sonda apagada, sin transmisión).
  noReadings,

  /// El dispositivo no aporta CE.
  noEcChannel,

  /// La humedad estuvo por debajo de la puerta dura la mayor parte del tiempo:
  /// la CE no sirve para leer respuesta en suelo seco.
  tooDry,

  /// Hubo lecturas, pero sin referencia previa suficiente para comparar.
  insufficientBaseline,
}

extension ScanObservabilityX on ScanObservability {
  String get labelEs => switch (this) {
    ScanObservability.ok => 'Ventana observable',
    ScanObservability.noReadings => 'Sin lecturas en la ventana',
    ScanObservability.noEcChannel => 'Sin canal de CE',
    ScanObservability.tooDry => 'Suelo demasiado seco para leer CE',
    ScanObservability.insufficientBaseline => 'Sin referencia previa suficiente',
  };

  bool get isOk => this == ScanObservability.ok;
}

// ═══════════════════════════════════════════════════════════════════════════
// LIBRO DE VENTANAS NUTRICIONALES
// ═══════════════════════════════════════════════════════════════════════════

/// Resultado de una ventana nutricional. Lo decide BIO-G automáticamente; el
/// agricultor no confirma nada.
enum NutritionWindowOutcome {
  /// La ventana sigue abierta y el sensor observa. No penaliza.
  open,

  /// Se detectó una firma compatible con fertilización: ventana atendida con
  /// cierto nivel de confianza. Nunca penaliza.
  attendedDetected,

  /// La ventana terminó, fue observable, y no apareció evidencia suficiente de
  /// haber sido atendida. Si además era agronómicamente importante, pesa en el
  /// score histórico, el estado global y la proyección.
  unattended,

  /// La ventana terminó sin evidencia, pero tampoco fue observable de forma
  /// suficiente (pocas lecturas, huecos largos). No penaliza: ausencia de
  /// señal no es prueba de ausencia de manejo.
  inconclusive,

  /// La ventana no se pudo comparar: sin CE, suelo demasiado seco, sin
  /// referencia, o sitio recién instalado/reubicado. No penaliza.
  notComparable,
}

extension NutritionWindowOutcomeX on NutritionWindowOutcome {
  String get labelEs => switch (this) {
    NutritionWindowOutcome.open => 'Ventana abierta',
    NutritionWindowOutcome.attendedDetected =>
      'Atendida: respuesta compatible con fertilización detectada',
    NutritionWindowOutcome.unattended =>
      'Sin evidencia suficiente de haber sido atendida',
    NutritionWindowOutcome.inconclusive => 'Inconclusa: observación insuficiente',
    NutritionWindowOutcome.notComparable => 'No comparable',
  };

  bool get isOpen => this == NutritionWindowOutcome.open;
  bool get isAttended => this == NutritionWindowOutcome.attendedDetected;
  bool get isClosed => !isOpen;
}

/// Una ventana nutricional del ciclo, con lo que el sensor vio en ella.
///
/// Se persiste (libro de ventanas) para que el resultado sobreviva al cambio
/// de etapa y pueda pesar en el score histórico y en la proyección.
class NutritionWindowRecord {
  const NutritionWindowRecord({
    required this.id,
    required this.seasonKey,
    required this.deviceId,
    required this.cropKey,
    required this.stageKey,
    required this.stageLabelEs,
    required this.nutrients,
    required this.isCritical,
    required this.openedAt,
    required this.outcome,
    this.closedAt,
    this.resolvedAt,
    this.signature,
    this.observability,
    this.observedFraction,
    this.responseVerdict,
    this.evidenceEs = const <String>[],
    this.epochId,
  });

  /// Identidad estable: temporada + etapa + nutrientes. Reconciliar la misma
  /// ventana mil veces produce una sola fila.
  final String id;

  /// `deviceId|cropKey|fechaDeSiembra`: acota el libro a un ciclo de cultivo.
  final String seasonKey;

  final String deviceId;
  final String cropKey;
  final String stageKey;
  final String stageLabelEs;

  /// Nutrientes que la etapa demanda en esta ventana (alta prioridad).
  final List<AgroMetricKey> nutrients;

  /// Ventana agronómicamente importante (prioridad crítica o regla de guía).
  final bool isCritical;

  /// Cuándo abrió (inicio de la etapa, o cuando BIO-G la pudo observar).
  final DateTime openedAt;

  /// Cuándo terminó la etapa (null mientras la etapa sigue).
  final DateTime? closedAt;

  /// Cuándo se decidió el resultado final (null mientras está abierta o en
  /// gracia de observación).
  final DateTime? resolvedAt;

  final NutritionWindowOutcome outcome;

  /// Firma detectada, si la hubo.
  final FertilizationSignature? signature;

  /// Observabilidad de la ventana al último barrido.
  final ScanObservability? observability;

  /// Fracción 0..1 del tiempo de ventana con lecturas utilizables.
  final double? observedFraction;

  /// Comparación de la respuesta con lo habitual del sitio, cuando cerró la
  /// ventana de respuesta.
  final ResponseVerdict? responseVerdict;

  final List<String> evidenceEs;

  /// Época de instalación en la que se observó. Una reubicación cambia el
  /// sitio: las ventanas de otra época no se comparan como el mismo punto.
  final String? epochId;

  /// Esta ventana pesa en el estado general: terminó sin evidencia Y era
  /// importante. Es la ÚNICA vía por la que la nutrición baja un score.
  bool get penalizes =>
      outcome == NutritionWindowOutcome.unattended && isCritical;

  bool get isOpen => outcome.isOpen;

  /// La firma sigue dentro de su horizonte de respuesta en [now].
  bool isFollowingResponseAt(DateTime now) =>
      signature != null && signature!.isFollowingResponseAt(now);

  String get nutrientsLabelEs =>
      nutrients.map((AgroMetricKey k) => k.shortLabel).join(', ');

  static String buildId({
    required String seasonKey,
    required String stageKey,
    required List<AgroMetricKey> nutrients,
  }) {
    final List<String> names = nutrients.map((k) => k.name).toList()..sort();
    return '$seasonKey|$stageKey|${names.join('+')}';
  }

  NutritionWindowRecord copyWith({
    NutritionWindowOutcome? outcome,
    DateTime? closedAt,
    DateTime? resolvedAt,
    FertilizationSignature? signature,
    bool clearSignature = false,
    ScanObservability? observability,
    double? observedFraction,
    ResponseVerdict? responseVerdict,
    List<String>? evidenceEs,
    bool? isCritical,
    List<AgroMetricKey>? nutrients,
    String? stageLabelEs,
    String? epochId,
    bool reopen = false,
  }) {
    return NutritionWindowRecord(
      id: id,
      seasonKey: seasonKey,
      deviceId: deviceId,
      cropKey: cropKey,
      stageKey: stageKey,
      stageLabelEs: stageLabelEs ?? this.stageLabelEs,
      nutrients: nutrients ?? this.nutrients,
      isCritical: isCritical ?? this.isCritical,
      openedAt: openedAt,
      outcome: outcome ?? (reopen ? NutritionWindowOutcome.open : this.outcome),
      closedAt: reopen ? null : (closedAt ?? this.closedAt),
      resolvedAt: reopen ? null : (resolvedAt ?? this.resolvedAt),
      signature: clearSignature ? null : (signature ?? this.signature),
      observability: observability ?? this.observability,
      observedFraction: observedFraction ?? this.observedFraction,
      responseVerdict: responseVerdict ?? this.responseVerdict,
      evidenceEs: evidenceEs ?? this.evidenceEs,
      epochId: epochId ?? this.epochId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'seasonKey': seasonKey,
    'deviceId': deviceId,
    'cropKey': cropKey,
    'stageKey': stageKey,
    'stageLabelEs': stageLabelEs,
    'nutrients': nutrients.map((k) => k.name).toList(),
    'isCritical': isCritical,
    'openedAt': openedAt.toUtc().toIso8601String(),
    'closedAt': closedAt?.toUtc().toIso8601String(),
    'resolvedAt': resolvedAt?.toUtc().toIso8601String(),
    'outcome': outcome.name,
    'signature': signature?.toJson(),
    'observability': observability?.name,
    'observedFraction': observedFraction,
    'responseVerdict': responseVerdict?.name,
    'evidenceEs': evidenceEs,
    'epochId': epochId,
  };

  static NutritionWindowRecord? tryFromJson(Map<String, dynamic> json) {
    final String? id = json['id']?.toString();
    final String? seasonKey = json['seasonKey']?.toString();
    final String? deviceId = json['deviceId']?.toString();
    final String? cropKey = json['cropKey']?.toString();
    final String? stageKey = json['stageKey']?.toString();
    final DateTime? openedAt = _date(json['openedAt']);
    if (id == null ||
        seasonKey == null ||
        deviceId == null ||
        cropKey == null ||
        stageKey == null ||
        openedAt == null) {
      return null;
    }
    final List<AgroMetricKey> nutrients = <AgroMetricKey>[];
    for (final String name in _strings(json['nutrients'])) {
      final AgroMetricKey? k = _enum(AgroMetricKey.values, name);
      if (k != null) nutrients.add(k);
    }
    final Object? sig = json['signature'];
    return NutritionWindowRecord(
      id: id,
      seasonKey: seasonKey,
      deviceId: deviceId,
      cropKey: cropKey,
      stageKey: stageKey,
      stageLabelEs: json['stageLabelEs']?.toString() ?? stageKey,
      nutrients: nutrients,
      isCritical: json['isCritical'] == true,
      openedAt: openedAt,
      closedAt: _date(json['closedAt']),
      resolvedAt: _date(json['resolvedAt']),
      outcome: _enum(NutritionWindowOutcome.values, json['outcome']) ??
          NutritionWindowOutcome.open,
      signature: sig is Map
          ? FertilizationSignature.tryFromJson(
              Map<String, dynamic>.from(sig),
            )
          : null,
      observability: _enum(ScanObservability.values, json['observability']),
      observedFraction: _num(json['observedFraction']),
      responseVerdict: _enum(ResponseVerdict.values, json['responseVerdict']),
      evidenceEs: _strings(json['evidenceEs']),
      epochId: json['epochId']?.toString(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// RESPUESTA DEL SITIO
// ═══════════════════════════════════════════════════════════════════════════

/// Comparación de la respuesta detectada con lo habitual del sitio (Guía
/// v0.4, §15).
enum ResponseVerdict {
  /// La firma sigue dentro de su horizonte de respuesta.
  pending,

  /// Respuesta compatible con fertilización, dentro de lo habitual del sitio
  /// (o sin historial con el que comparar).
  compatible,

  /// Hubo respuesta, pero menor de lo habitual en este sitio.
  minor,

  /// Respuesta claramente mayor que el patrón habitual del sitio.
  greater,

  /// No se puede comparar con el sitio: sin referencia, sin humedad
  /// suficiente, sin CE o ubicación cambiada.
  notComparable,
}

extension ResponseVerdictX on ResponseVerdict {
  String get labelEs => switch (this) {
    ResponseVerdict.pending => 'Observando la respuesta',
    ResponseVerdict.compatible => 'Respuesta compatible con fertilización',
    ResponseVerdict.minor => 'Respuesta menor de lo habitual',
    ResponseVerdict.greater => 'Respuesta mayor de lo habitual',
    ResponseVerdict.notComparable => 'No comparable',
  };

  bool get isFinal => this != ResponseVerdict.pending;
}

/// Evaluación de la respuesta del sitio a una firma detectada.
class NutritionResponseEvaluation {
  const NutritionResponseEvaluation({
    required this.verdict,
    required this.signature,
    required this.summaryEs,
    this.daysSinceDetection,
    this.typicalEcPeakMad,
    this.evidenceEs = const <String>[],
  });

  final ResponseVerdict verdict;
  final FertilizationSignature signature;
  final String summaryEs;
  final int? daysSinceDetection;

  /// Respuesta habitual del sitio (mediana de firmas anteriores), si existe.
  final double? typicalEcPeakMad;

  final List<String> evidenceEs;
}

// ═══════════════════════════════════════════════════════════════════════════
// TENDENCIA DE LOS CANALES NATIVOS
// ═══════════════════════════════════════════════════════════════════════════

/// Dirección de la señal nativa de un nutriente en los últimos días.
///
/// Es la ÚNICA lectura que la app hace de N/P/K: hacia dónde va la señal,
/// nunca cuánto hay (Guía v0.4, §2 y §8). Todas las pantallas —Panel, pantalla
/// de nutrición, Historial, informes, eventos— usan este vocabulario.
enum NativeTrend { rising, stable, falling, unknown }

extension NativeTrendX on NativeTrend {
  String get labelEs => switch (this) {
    NativeTrend.rising => 'Al alza',
    NativeTrend.stable => 'Estable',
    NativeTrend.falling => 'A la baja',
    NativeTrend.unknown => 'Sin tendencia aún',
  };

  bool get isKnown => this != NativeTrend.unknown;
  bool get isMoving => this == NativeTrend.rising || this == NativeTrend.falling;
}

/// Tendencia reciente de un canal nativo (N, P o K).
class NutrientTrend {
  const NutrientTrend({
    required this.nutrient,
    required this.trend,
    this.changePct,
    this.samples = 0,
    this.spanDays = 7,
  });

  final AgroMetricKey nutrient;
  final NativeTrend trend;

  /// Cambio relativo (%) de la mediana reciente contra la mediana previa.
  /// Null cuando no hubo lecturas suficientes.
  final double? changePct;

  /// Lecturas con las que se calculó.
  final int samples;

  /// Ventana temporal comparada, en días.
  final int spanDays;

  /// Umbral de cambio relativo a partir del cual la señal «se mueve».
  static const double kMovingThresholdPct = 8.0;

  /// Lecturas mínimas por lado (reciente / previo) para hablar de tendencia.
  static const int kMinSamplesPerSide = 3;

  String get labelEs => nutrient.labelEs;

  /// «N», «P», «K».
  String get symbolEs => switch (nutrient) {
    AgroMetricKey.n => 'N',
    AgroMetricKey.p => 'P',
    AgroMetricKey.k => 'K',
    _ => nutrient.name.toUpperCase(),
  };

  /// «N al alza», «P estable», «K a la baja», «N sin tendencia aún».
  String get chipEs => '$symbolEs ${trend.labelEs.toLowerCase()}';

  /// Frase completa para encabezados: «Tendencia al alza en nitrógeno».
  String get sentenceEs {
    final String n = nutrient.labelEs.toLowerCase();
    return switch (trend) {
      NativeTrend.rising => 'Tendencia al alza en $n',
      NativeTrend.falling => 'Tendencia a la baja en $n',
      NativeTrend.stable => '$labelEs estable',
      NativeTrend.unknown => 'Sin tendencia de $n todavía',
    };
  }

  /// Detalle con la magnitud, para la pantalla de nutrición.
  String get detailEs {
    final String n = nutrient.labelEs.toLowerCase();
    final String pct = changePct == null
        ? ''
        : ' (${changePct! >= 0 ? '+' : ''}${changePct!.round()} % en $spanDays días)';
    return switch (trend) {
      NativeTrend.rising => 'La señal de $n viene subiendo$pct.',
      NativeTrend.falling => 'La señal de $n viene bajando$pct.',
      NativeTrend.stable => 'La señal de $n se mantiene estable$pct.',
      NativeTrend.unknown =>
        'Todavía no hay lecturas suficientes para hablar de tendencia de $n.',
    };
  }

  /// Calcula la tendencia comparando la mediana de las últimas 48 h contra la
  /// mediana de los días previos dentro de [spanDays]. Puro.
  static NutrientTrend compute({
    required AgroMetricKey nutrient,
    required List<({DateTime at, double value})> samples,
    required DateTime now,
    int spanDays = 7,
  }) {
    final DateTime from = now.subtract(Duration(days: spanDays));
    final DateTime split = now.subtract(const Duration(hours: 48));
    final List<double> recent = <double>[];
    final List<double> previous = <double>[];
    for (final ({DateTime at, double value}) s in samples) {
      if (s.at.isBefore(from) || s.at.isAfter(now) || !s.value.isFinite) continue;
      (s.at.isBefore(split) ? previous : recent).add(s.value);
    }
    final int total = recent.length + previous.length;
    if (recent.length < kMinSamplesPerSide || previous.length < kMinSamplesPerSide) {
      return NutrientTrend(
        nutrient: nutrient,
        trend: NativeTrend.unknown,
        samples: total,
        spanDays: spanDays,
      );
    }
    final double a = _median(recent);
    final double b = _median(previous);
    final double base = b.abs() < 1e-6 ? 1e-6 : b.abs();
    final double pct = (a - b) / base * 100.0;
    final NativeTrend t = pct >= kMovingThresholdPct
        ? NativeTrend.rising
        : (pct <= -kMovingThresholdPct ? NativeTrend.falling : NativeTrend.stable);
    return NutrientTrend(
      nutrient: nutrient,
      trend: t,
      changePct: pct,
      samples: total,
      spanDays: spanDays,
    );
  }

  static double _median(List<double> values) {
    final List<double> v = List<double>.of(values)..sort();
    final int n = v.length;
    return n.isOdd ? v[n ~/ 2] : (v[n ~/ 2 - 1] + v[n ~/ 2]) / 2.0;
  }
}

/// Texto pequeño que acompaña a cualquier lectura N/P/K: un solo renglón,
/// discreto, y el mismo en toda la app.
const String kNativeSignalDisclaimerEs =
    'Tendencia del sensor · orientativa, no sustituye un análisis de suelo';

// ═══════════════════════════════════════════════════════════════════════════
// DECISIÓN
// ═══════════════════════════════════════════════════════════════════════════

/// La decisión del motor de nutrición. Autoridad única del manejo nutricional.
class NutritionDecision {
  const NutritionDecision({
    required this.state,
    required this.decidedAt,
    required this.headlineEs,
    required this.detailEs,
    required this.priorities,
    required this.conditions,
    required this.engineVersion,
    this.cropKey,
    this.cropLabel,
    this.stageKey,
    this.stageLabelEs,
    this.recommendation,
    this.response,
    this.window,
    this.seasonWindows = const <NutritionWindowRecord>[],
    this.awaitingEvidence = false,
    this.unattendedCriticalWindows = 0,
    this.scoreFactor = 1.0,
    this.recentlyUnattendedWindow,
    this.isLearningSite = false,
    this.learningDaysLeft,
    this.upcomingWindowLabelEs,
    this.upcomingWindowInDays,
    this.trends = const <NutrientTrend>[],
    this.reasons = const <String>[],
    this.limitations = const <String>[],
    this.guideAudit = GuideAuditStatus.pending,
  });

  final NutritionState state;
  final DateTime decidedAt;

  /// Titular para la tarjeta del Panel.
  final String headlineEs;

  /// Detalle para la tarjeta del Panel y la pantalla de nutrición.
  final String detailEs;

  final String? cropKey;
  final String? cropLabel;
  final String? stageKey;
  final String? stageLabelEs;

  /// Prioridad por nutriente en la etapa actual, ordenada de mayor a menor.
  final List<NutrientStagePriority> priorities;

  /// Recomendación concreta, solo en ventana de acción (o en preparación, sin
  /// dosis, para que el productor sepa qué viene).
  final NutritionRecommendation? recommendation;

  /// Condiciones físicas al momento de decidir.
  final NutritionConditionCheck conditions;

  /// Evaluación de la respuesta cuando hay una firma detectada.
  final NutritionResponseEvaluation? response;

  /// Ventana nutricional de la etapa actual, tal como quedó en el libro tras
  /// esta evaluación (null si la etapa no abre ventana).
  final NutritionWindowRecord? window;

  /// Libro de ventanas del ciclo, de la más antigua a la más reciente, para
  /// la pantalla de nutrición y los reportes.
  final List<NutritionWindowRecord> seasonWindows;

  /// Hay una ventana importante abierta y el sensor todavía no ha visto una
  /// respuesta compatible. NO penaliza nada: es la fase «esta etapa necesita
  /// nutrición; estoy observando la respuesta del suelo».
  final bool awaitingEvidence;

  /// Ventanas importantes del ciclo que TERMINARON sin evidencia suficiente.
  final int unattendedCriticalWindows;

  /// Factor ≤ 1.0 que el Panel aplica al estado general del suelo y la
  /// proyección al de rendimiento. Solo baja de 1.0 por
  /// [unattendedCriticalWindows]; nunca por una ventana abierta, nunca porque
  /// «N no subió» (Guía v0.4, §6). Su peso exacto es una decisión abierta
  /// (§38) y vive en un solo sitio: `NutritionWindowLedger`.
  final double scoreFactor;

  /// Ventana que acaba de cerrar sin evidencia (para el copy de los primeros
  /// días tras el cierre).
  final NutritionWindowRecord? recentlyUnattendedWindow;

  /// El sitio está en su primera semana.
  final bool isLearningSite;
  final int? learningDaysLeft;

  /// Próxima ventana de alta demanda, cuando se aproxima.
  final String? upcomingWindowLabelEs;
  final int? upcomingWindowInDays;

  /// Tendencia reciente de cada canal nativo (N, P, K), en ese orden.
  final List<NutrientTrend> trends;

  /// Trazabilidad: por qué se decidió esto.
  final List<String> reasons;

  /// Trazabilidad: qué no se pudo saber.
  final List<String> limitations;

  /// Estatus de auditoría de la guía que respaldó la decisión.
  final GuideAuditStatus guideAudit;

  final String engineVersion;

  bool get hasRecommendation => recommendation != null;

  bool get hasOpenWindow =>
      state == NutritionState.actionWindow ||
      state == NutritionState.prepare;

  /// Firma detectada en la ventana actual, si la hay.
  FertilizationSignature? get signature => window?.signature;

  bool get hasDetectedSignature => signature != null && signature!.isCompatible;

  /// Prioridad más alta de la etapa (la primera de la lista ordenada).
  NutrientStagePriority? get topPriority =>
      priorities.isEmpty ? null : priorities.first;

  /// Etiqueta corta para pantalla, afinada a lo que el agricultor debe leer
  /// de un vistazo: «Atendida» cuando el sensor ya vio la respuesta, «Sin
  /// evidencia» los días siguientes a un cierre sin ella, «Estable» en
  /// seguimiento tranquilo; en los demás estados, la del estado.
  String get tagEs {
    if (state != NutritionState.monitor) return state.tagEs;
    if (window?.outcome == NutritionWindowOutcome.attendedDetected) {
      return 'Atendida';
    }
    if (recentlyUnattendedWindow != null) return 'Sin evidencia';
    return 'Estable';
  }

  NutrientTrend? trendFor(AgroMetricKey nutrient) {
    for (final NutrientTrend t in trends) {
      if (t.nutrient == nutrient) return t;
    }
    return null;
  }

  /// «N al alza · P estable · K estable». Vacío sin tendencias conocidas.
  String get trendSummaryEs {
    final List<String> parts = <String>[
      for (final NutrientTrend t in trends)
        if (t.trend.isKnown) t.chipEs,
    ];
    return parts.join(' · ');
  }

  /// La tendencia que más importa ahora: un nutriente que se mueve y además
  /// pesa en la etapa (prioridad media o alta). Null si nada se mueve.
  NutrientTrend? get notableTrend {
    for (final NutrientStagePriority p in priorities) {
      if (p.priority == NutritionPriority.low) continue;
      final NutrientTrend? t = trendFor(p.nutrient);
      if (t != null && t.trend.isMoving) return t;
    }
    for (final NutrientTrend t in trends) {
      if (t.trend.isMoving) return t;
    }
    return null;
  }

  /// Identidad estable de la decisión: qué se decidió, no cuándo.
  ///
  /// Misma regla que `BioGStore.irrigationDecisionKey`: el Panel recalcula en
  /// cada reconstrucción y pone la hora del momento; comparar por hora daría
  /// «cambió» siempre y abriría un bucle registro → aviso → rebuild.
  String get identityKey {
    final String rec = recommendation?.nutrient.name ?? '-';
    final String resp = response?.verdict.name ?? '-';
    final String win = window?.outcome.name ?? '-';
    final String recent = recentlyUnattendedWindow?.id ?? '-';
    return '${state.name}|$rec|$resp|$win|$awaitingEvidence|'
        '$unattendedCriticalWindows|$recent|${stageKey ?? '-'}';
  }
}

// ── Utilidades de (de)serialización ──────────────────────────────────────────

DateTime? _date(Object? raw) {
  if (raw == null) return null;
  return DateTime.tryParse(raw.toString())?.toLocal();
}

double? _num(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw == null) return null;
  return double.tryParse(raw.toString());
}

T? _enum<T extends Enum>(List<T> values, Object? raw) {
  if (raw == null) return null;
  final String name = raw.toString();
  for (final T v in values) {
    if (v.name == name) return v;
  }
  return null;
}

List<String> _strings(Object? raw) {
  if (raw is! List) return const <String>[];
  return raw.map((Object? e) => e.toString()).toList();
}
