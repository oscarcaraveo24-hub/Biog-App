import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/onion_profiles.dart';

enum OnionNutritionGroup {
  generic,
  whiteShortDay,
  yellowShortDay,
  redShortDay,
  intermediateTransition,
  bunchingCambray,
}

/// Modificador nutricional por perfil de cebolla.
///
/// No crea recetas por ON: ajusta presion y lenguaje sobre una base
/// universal conservadora de bulbo. La regla central de cebolla es N
/// temprano con control y K para llenado/calidad, deteniendo N tarde.
class OnionNutritionModifier {
  const OnionNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
  });

  final String profileId;
  final OnionNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;

  bool get isGeneric => group == OnionNutritionGroup.generic;
  bool get isBunching => group == OnionNutritionGroup.bunchingCambray;
  bool get isIntermediate => group == OnionNutritionGroup.intermediateTransition;

  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = (stageKey ?? '').toLowerCase();
    final isEstablishment = stage.contains('germin') ||
        stage.contains('emergencia') ||
        stage.contains('establec');
    final isVegetative =
        stage.contains('vegetativo') || stage.contains('induccion');
    final isBulbFill = stage.contains('llenado') ||
        stage.contains('iniciobulbo') ||
        stage.contains('bulbo');
    final isLate = _isLateStageInternal(stage);

    if (isLate) {
      // Detener N tarde es regla de seguridad central de cebolla.
      if (nutrient == AgroMetricKey.n) return -0.08;
      return 0.0;
    }

    if (nutrient == AgroMetricKey.p && isEstablishment) return 0.05;

    switch (group) {
      case OnionNutritionGroup.generic:
        if (nutrient == AgroMetricKey.n && isBulbFill) return -0.04;
        if (nutrient == AgroMetricKey.k && isBulbFill) return 0.03;
        return 0.0;
      case OnionNutritionGroup.whiteShortDay:
        if (nutrient == AgroMetricKey.n && isBulbFill) return -0.05;
        if (nutrient == AgroMetricKey.k && isBulbFill) return 0.05;
        return 0.0;
      case OnionNutritionGroup.yellowShortDay:
        if (nutrient == AgroMetricKey.n && isBulbFill) return -0.04;
        if (nutrient == AgroMetricKey.k && isBulbFill) return 0.04;
        return 0.0;
      case OnionNutritionGroup.redShortDay:
        if (nutrient == AgroMetricKey.k && isBulbFill) return 0.05;
        if (nutrient == AgroMetricKey.n && isBulbFill) return -0.04;
        return 0.0;
      case OnionNutritionGroup.intermediateTransition:
        // Ciclo largo: mayor riesgo de N residual/tardio.
        if (nutrient == AgroMetricKey.n && (isBulbFill || isVegetative)) {
          return -0.03;
        }
        if (nutrient == AgroMetricKey.k && isBulbFill) return 0.04;
        return 0.0;
      case OnionNutritionGroup.bunchingCambray:
        // Cambray: N orientado a hoja/base tierna; no logica de bulbo seco.
        if (nutrient == AgroMetricKey.n && isVegetative) return 0.03;
        if (nutrient == AgroMetricKey.k && isBulbFill) return 0.02;
        return 0.0;
    }
  }

  double adjustStagePressure(
    double base, {
    required AgroMetricKey nutrient,
    required String? stageKey,
  }) {
    return (base + stagePressureDelta(nutrient, stageKey)).clamp(0.0, 1.0);
  }

  String practicalCaution(AgroMetricKey nutrient, String stageKey) {
    final stage = stageKey.toLowerCase();
    final isLate = _isLateStageInternal(stage);

    if (isLate) {
      return 'Cebolla en maduracion/cuello o espigado: no conviene empujar N. Protege curado, evita riego tardio y cierra ciclo registrando la causa.';
    }

    switch (group) {
      case OnionNutritionGroup.generic:
        return 'ON-GEN: guia conservadora de bulbo. N temprano con control, P de arranque, K para llenado; afina tipo y fotoperiodo despues sin perder historial.';
      case OnionNutritionGroup.whiteShortDay:
        return 'Blanca dia corto: cuida cuello sano y curado limpio; detener N a tiempo evita cuello grueso y mala conservacion.';
      case OnionNutritionGroup.yellowShortDay:
        return 'Amarilla/dorada dia corto: si es dulce/fresco cuida S y N tarde; el bulbo no se llena bien con deficit de agua o sales.';
      case OnionNutritionGroup.redShortDay:
        return 'Morada dia corto: K y agua pareja sostienen color y calidad; humedad irregular y curado deficiente bajan presentacion.';
      case OnionNutritionGroup.intermediateTransition:
        return 'Dia intermedio/transicion: ciclo largo, mas hoja no es mas bulbo. Controla N residual y maduracion para no atrasar cuello.';
      case OnionNutritionGroup.bunchingCambray:
        return 'Cambray/rama: el objetivo es manojo tierno hoja+base, no bulbo seco. N moderado hasta antes de cosecha; cuida calor y pudricion de base.';
    }
  }

  String guideCaution(AgroMetricKey nutrient, String? stageKey) {
    final protectedNote = isProtected
        ? ' Protegido en v1 significa suelo bajo malla/invernadero/tunel; no hidroponia.'
        : '';
    return '${practicalCaution(nutrient, stageKey ?? '')}$protectedNote';
  }

  static bool _isLateStageInternal(String stage) {
    return stage.contains('maduracion') ||
        stage.contains('cosecha') ||
        stage.contains('curado') ||
        stage.contains('espig') ||
        stage.contains('bolting') ||
        stage.contains('senesc') ||
        stage.contains('cierre') ||
        stage.contains('late') ||
        stage.contains('harvest');
  }
}

OnionNutritionModifier resolveOnionNutritionModifier({
  String? profileId,
  String? varietyId,
  String? alias,
  String? calendarId,
}) {
  final tokens = <String?>[profileId, varietyId, alias, calendarId]
      .whereType<String>()
      .map((value) => value.trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
  final joined = tokens.join(' ');
  final canonical = _canonicalOnionProfile(tokens, joined);
  final isProtected = _containsAny(joined, const <String>[
    'protegido',
    'invernadero',
    'malla',
    'casa sombra',
    'tunel',
    'tunnel',
    'protected',
  ]);

  if (canonical == kOn01) {
    return OnionNutritionModifier(
      profileId: kOn01,
      group: OnionNutritionGroup.whiteShortDay,
      labelEs: 'ON-01 Cebolla blanca grano/bola',
      summaryEs:
          'N temprano con control y detener tarde; K para calibre; cuello sano y curado limpio mandan calidad.',
      isProtected: isProtected,
    );
  }
  if (canonical == kOn02) {
    return OnionNutritionModifier(
      profileId: kOn02,
      group: OnionNutritionGroup.yellowShortDay,
      labelEs: 'ON-02 Cebolla amarilla/dorada',
      summaryEs:
          'Alto volumen o dulce segun material; cuida agua y CE en llenado y no empujes N tarde.',
      isProtected: isProtected,
    );
  }
  if (canonical == kOn03) {
    return OnionNutritionModifier(
      profileId: kOn03,
      group: OnionNutritionGroup.redShortDay,
      labelEs: 'ON-03 Cebolla morada',
      summaryEs:
          'Color y piel sensibles a humedad irregular y curado; K y agua pareja sostienen calidad visual.',
      isProtected: isProtected,
    );
  }
  if (canonical == kOn04) {
    return OnionNutritionModifier(
      profileId: kOn04,
      group: OnionNutritionGroup.intermediateTransition,
      labelEs: 'ON-04 Cebolla de transicion / dia intermedio',
      summaryEs:
          'Ciclo largo con buen potencial de calibre; vigila N residual y maduracion para cuello sano.',
      isProtected: isProtected,
    );
  }
  if (canonical == kOn05) {
    return OnionNutritionModifier(
      profileId: kOn05,
      group: OnionNutritionGroup.bunchingCambray,
      labelEs: 'ON-05 Cebolla en rama / cambray',
      summaryEs:
          'Objetivo manojo tierno hoja+base; N moderado hasta cosecha; no aplicar logica de bulbo seco.',
      isProtected: isProtected,
    );
  }

  return OnionNutritionModifier(
    profileId: kOnGen,
    group: OnionNutritionGroup.generic,
    labelEs: 'ON-GEN Cebolla generica',
    summaryEs: 'Perfil conservador y migrable; no asume color, fotoperiodo ni destino.',
    isProtected: isProtected,
  );
}

String _canonicalOnionProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalOnionProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>['blanca', 'white', 'grano', 'bola'])) {
    return kOn01;
  }
  if (_containsAny(joined, const <String>['amarilla', 'dorada', 'yellow'])) {
    return kOn02;
  }
  if (_containsAny(joined, const <String>['morada', 'roja', 'red', 'purple'])) {
    return kOn03;
  }
  if (_containsAny(joined,
      const <String>['intermedio', 'transicion', 'altiplano', 'intermediate'])) {
    return kOn04;
  }
  if (_containsAny(joined,
      const <String>['cambray', 'rama', 'manojo', 'cebollin', 'bunch', 'scallion'])) {
    return kOn05;
  }
  return kOnGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
