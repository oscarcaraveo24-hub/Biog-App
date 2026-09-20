// lib/core/agro/nutrition/nutrition_season_declaration.dart
//
// DECLARACIÓN DE TEMPORADA: cómo va a fertilizar el productor este ciclo.
//
// Es la única cosa que el agricultor le dice al motor nutricional con la mano
// (decisión de producto, 13 sep 2026). No registra aplicaciones —eso lo sigue
// viendo el sensor—: declara una INTENCIÓN categórica («una sola vez», «dos
// veces», «tres o más» o, desde el 17 sep 2026, «ya fertilicé») que el
// resolver del plan usa para repartir el nitrógeno de la guía entre menos
// ventanas —las MEJORES según la prioridad agronómica de cada guía—, y para
// no exigir después una fertilización que el productor ya concentró o ya dio.
//
// Por qué categórica y por qué puede preguntarse tarde: el reporte binario de
// «¿fraccionaste o no?» es robusto al retraso (Banco Mundial, Wollburg et al.
// 2021; Beegle et al.); la cantidad en kg no lo es. Por eso aquí nunca viven
// kilos.
//
// Vive junto al libro de ventanas (misma base local), por temporada y
// dispositivo. Cambiar de temporada la deja atrás: la pregunta vuelve.

/// Cuántas aplicaciones de nitrógeno piensa dar el productor en la temporada.
enum NitrogenPassPlan {
  /// Todo el nitrógeno de la temporada en una sola pasada.
  single,

  /// Dos aplicaciones (p. ej. siembra + primer riego de auxilio).
  two,

  /// Tres o más: el plan de la guía tal cual.
  threeOrMore,

  /// Ya fertilizó (antes de instalar el Bio-G o antes de contestar) y no
  /// va a volver a aplicar nitrógeno esta temporada: ninguna ventana de N
  /// queda por delante; el sensor solo observa (decisión de producto,
  /// 17 sep 2026).
  alreadyDone,
}

extension NitrogenPassPlanX on NitrogenPassPlan {
  /// Identificador estable para persistencia.
  String get id => switch (this) {
    NitrogenPassPlan.single => 'single',
    NitrogenPassPlan.two => 'two',
    NitrogenPassPlan.threeOrMore => 'three_plus',
    NitrogenPassPlan.alreadyDone => 'already_done',
  };

  /// Número de pasadas que representa (3 para «tres o más», 0 para «ya
  /// fertilicé»).
  int get passes => switch (this) {
    NitrogenPassPlan.single => 1,
    NitrogenPassPlan.two => 2,
    NitrogenPassPlan.threeOrMore => 3,
    NitrogenPassPlan.alreadyDone => 0,
  };

  /// No quedan aplicaciones de nitrógeno por delante.
  bool get isAlreadyDone => this == NitrogenPassPlan.alreadyDone;

  String get labelEs => switch (this) {
    NitrogenPassPlan.single => 'Una sola vez',
    NitrogenPassPlan.two => 'Dos veces',
    NitrogenPassPlan.threeOrMore => 'Tres o más',
    NitrogenPassPlan.alreadyDone => 'Ya fertilicé',
  };

  /// Frase corta para la fila compacta («Fertilizas: una sola vez»).
  String get shortEs => switch (this) {
    NitrogenPassPlan.single => 'una sola vez',
    NitrogenPassPlan.two => 'dos veces',
    NitrogenPassPlan.threeOrMore => 'tres o más veces',
    NitrogenPassPlan.alreadyDone => 'ya fertilizaste',
  };

  static NitrogenPassPlan? fromId(String? raw) {
    final String v = (raw ?? '').trim().toLowerCase();
    for (final NitrogenPassPlan p in NitrogenPassPlan.values) {
      if (p.id == v || p.name.toLowerCase() == v) return p;
    }
    return switch (v) {
      '1' || 'one' || 'una' => NitrogenPassPlan.single,
      '2' || 'dos' => NitrogenPassPlan.two,
      '3' || 'three' || 'tres' || 'three_or_more' => NitrogenPassPlan.threeOrMore,
      '0' || 'done' || 'already' || 'ya' => NitrogenPassPlan.alreadyDone,
      _ => null,
    };
  }
}

/// De dónde salió la declaración (para trazabilidad, no para lógica).
class NutritionDeclarationSources {
  const NutritionDeclarationSources._();

  /// Tarjeta «¿Cómo vas a fertilizar esta temporada?» de la pantalla NPK.
  static const String npkCard = 'npk_card';

  /// Hoja disparada por el sensor al detectar la primera fertilización.
  static const String sensorSheet = 'sensor_sheet';

  /// «Cambiar» desde la línea de tiempo.
  static const String timeline = 'timeline';
}

/// Lo que el productor declaró para una temporada de un dispositivo.
class NutritionSeasonDeclaration {
  const NutritionSeasonDeclaration({
    required this.deviceId,
    required this.seasonKey,
    required this.cropKey,
    required this.passes,
    required this.declaredAt,
    this.sourceId = NutritionDeclarationSources.npkCard,
  });

  final String deviceId;

  /// Misma identidad que el libro de ventanas (`deviceId|cropKey|ancla`).
  final String seasonKey;
  final String cropKey;
  final NitrogenPassPlan passes;
  final DateTime declaredAt;
  final String sourceId;

  bool get isSinglePass => passes == NitrogenPassPlan.single;

  NutritionSeasonDeclaration copyWith({
    NitrogenPassPlan? passes,
    DateTime? declaredAt,
    String? sourceId,
  }) {
    return NutritionSeasonDeclaration(
      deviceId: deviceId,
      seasonKey: seasonKey,
      cropKey: cropKey,
      passes: passes ?? this.passes,
      declaredAt: declaredAt ?? this.declaredAt,
      sourceId: sourceId ?? this.sourceId,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'deviceId': deviceId,
    'seasonKey': seasonKey,
    'cropKey': cropKey,
    'passes': passes.id,
    'declaredAt': declaredAt.toUtc().toIso8601String(),
    'sourceId': sourceId,
  };

  static NutritionSeasonDeclaration? tryFromJson(Map<String, dynamic> json) {
    final String? deviceId = json['deviceId']?.toString();
    final String? seasonKey = json['seasonKey']?.toString();
    final String cropKey = json['cropKey']?.toString() ?? '';
    final NitrogenPassPlan? passes = NitrogenPassPlanX.fromId(
      json['passes']?.toString(),
    );
    final DateTime? declaredAt = DateTime.tryParse(
      json['declaredAt']?.toString() ?? '',
    )?.toLocal();
    if (deviceId == null || seasonKey == null || passes == null || declaredAt == null) {
      return null;
    }
    return NutritionSeasonDeclaration(
      deviceId: deviceId,
      seasonKey: seasonKey,
      cropKey: cropKey,
      passes: passes,
      declaredAt: declaredAt,
      sourceId: json['sourceId']?.toString() ?? NutritionDeclarationSources.npkCard,
    );
  }

  @override
  String toString() =>
      'NutritionSeasonDeclaration($deviceId, $seasonKey, ${passes.id}, $sourceId)';
}
