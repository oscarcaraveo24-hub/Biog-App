import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/garlic_profiles.dart';

enum GarlicNutritionGroup {
  generic,
  whitePearl,
  jaspeadoCalera,
  purple,
  creoleRegional,
  chineseKorean,
}

/// Modificador nutricional por perfil de ajo.
///
/// No crea recetas por AG: ajusta presion y lenguaje sobre una base universal
/// conservadora. La regla central es N temprano con control, P por analisis al
/// arranque, K para diferenciacion/llenado, y detener N tarde.
class GarlicNutritionModifier {
  const GarlicNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
  });

  final String profileId;
  final GarlicNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;

  bool get isGeneric => group == GarlicNutritionGroup.generic;

  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = (stageKey ?? '').toLowerCase();
    final isEstablishment = stage.contains('plant') ||
        stage.contains('clove') ||
        stage.contains('diente') ||
        stage.contains('emerg') ||
        stage.contains('establec');
    final isVegetative =
        stage.contains('veget') || stage.contains('foliar');
    final isVernalization =
        stage.contains('vernal') || stage.contains('frio') || stage.contains('cold');
    final isBulb = stage.contains('diferenci') ||
        stage.contains('llenado') ||
        stage.contains('bulb') ||
        stage.contains('bulbo') ||
        stage.contains('fill');
    final isLate = _isLateStageInternal(stage);

    if (isLate) {
      if (nutrient == AgroMetricKey.n) return -0.12;
      if (nutrient == AgroMetricKey.k) return -0.02;
      return 0.0;
    }

    if (nutrient == AgroMetricKey.p && isEstablishment) return 0.06;
    if (nutrient == AgroMetricKey.n && isVegetative) return 0.03;

    if (isVernalization) {
      if (nutrient == AgroMetricKey.n) return -0.04;
      if (nutrient == AgroMetricKey.k) return 0.03;
      return 0.0;
    }

    if (isBulb) {
      if (nutrient == AgroMetricKey.n) return -0.08;
      if (nutrient == AgroMetricKey.k) return 0.06;
    }

    switch (group) {
      case GarlicNutritionGroup.generic:
        return 0.0;
      case GarlicNutritionGroup.whitePearl:
        if (nutrient == AgroMetricKey.k && isBulb) return 0.02;
        return 0.0;
      case GarlicNutritionGroup.jaspeadoCalera:
        if (nutrient == AgroMetricKey.n && (isBulb || isVernalization)) {
          return -0.03;
        }
        if (nutrient == AgroMetricKey.k && isBulb) return 0.03;
        return 0.0;
      case GarlicNutritionGroup.purple:
        if (nutrient == AgroMetricKey.n && (isBulb || isVernalization)) {
          return -0.04;
        }
        if (nutrient == AgroMetricKey.k && isBulb) return 0.03;
        return 0.0;
      case GarlicNutritionGroup.creoleRegional:
        if (nutrient == AgroMetricKey.n && isBulb) return -0.04;
        return 0.0;
      case GarlicNutritionGroup.chineseKorean:
        if (nutrient == AgroMetricKey.n && isBulb) return -0.04;
        if (nutrient == AgroMetricKey.k && isBulb) return 0.02;
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
    final isVernalization =
        stage.contains('vernal') || stage.contains('frio') || stage.contains('cold');

    if (isLate) {
      return 'Ajo en maduracion/cosecha/curado o con escapo: no conviene empujar N. Protege curado, descarte y almacenamiento; registra causa.';
    }
    if (isVernalization) {
      return 'Vernalizacion en ajo: el frio manda. NPK no corrige frio insuficiente; usa la lectura como balance, no como rescate.';
    }

    switch (group) {
      case GarlicNutritionGroup.generic:
        return 'AG-GEN: guia conservadora. N temprano con control, P de arranque por analisis, K en bulbo; afina perfil sin perder historial.';
      case GarlicNutritionGroup.whitePearl:
        return 'Blanco/Perla: cuida calibre, maduracion y curado. N tardio sube riesgo de tejido blando y pudriciones.';
      case GarlicNutritionGroup.jaspeadoCalera:
        return 'Jaspeado/Calera: alto potencial solo con frio, diente sano, CE baja y curado limpio; K no compensa salinidad.';
      case GarlicNutritionGroup.purple:
        return 'Morado: sensible a frio, calor y curado; prioriza calidad visual, piel y descarte comercial.';
      case GarlicNutritionGroup.creoleRegional:
        return 'Criollo/regional: cuida semilla propia, sanidad de diente y uniformidad; no sobrerreacciones a una lectura aislada.';
      case GarlicNutritionGroup.chineseKorean:
        return 'Chino/Coreano: verifica trazabilidad, adaptacion y sanidad del diente; maneja N tarde con prudencia.';
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
        stage.contains('matur') ||
        stage.contains('cosecha') ||
        stage.contains('harvest') ||
        stage.contains('curado') ||
        stage.contains('curing') ||
        stage.contains('escapo') ||
        stage.contains('canuto') ||
        stage.contains('broom') ||
        stage.contains('escobete') ||
        stage.contains('scape') ||
        stage.contains('senesc') ||
        stage.contains('cierre') ||
        stage.contains('late');
  }
}

GarlicNutritionModifier resolveGarlicNutritionModifier({
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
  final canonical = _canonicalGarlicProfile(tokens, joined);
  final isProtected = _containsAny(joined, const <String>[
    'protegido',
    'invernadero',
    'malla',
    'casa sombra',
    'tunel',
    'tunnel',
    'protected',
  ]);

  if (canonical == kAg01) {
    return GarlicNutritionModifier(
      profileId: kAg01,
      group: GarlicNutritionGroup.whitePearl,
      labelEs: 'AG-01 Ajo blanco / Perla',
      summaryEs:
          'N temprano con control; K para bulbo; curado limpio define rendimiento comercial.',
      isProtected: isProtected,
    );
  }
  if (canonical == kAg02) {
    return GarlicNutritionModifier(
      profileId: kAg02,
      group: GarlicNutritionGroup.jaspeadoCalera,
      labelEs: 'AG-02 Ajo jaspeado / Calera',
      summaryEs:
          'Alto potencial condicionado por frio, diente sano, baja salinidad y curado.',
      isProtected: isProtected,
    );
  }
  if (canonical == kAg03) {
    return GarlicNutritionModifier(
      profileId: kAg03,
      group: GarlicNutritionGroup.purple,
      labelEs: 'AG-03 Ajo morado',
      summaryEs:
          'Color y calidad sensibles a frio, calor, salinidad y curado deficiente.',
      isProtected: isProtected,
    );
  }
  if (canonical == kAg04) {
    return GarlicNutritionModifier(
      profileId: kAg04,
      group: GarlicNutritionGroup.creoleRegional,
      labelEs: 'AG-04 Ajo criollo / regional',
      summaryEs:
          'Semilla local y sanidad del diente mueven stand y rendimiento mas que una correccion tardia.',
      isProtected: isProtected,
    );
  }
  if (canonical == kAg05) {
    return GarlicNutritionModifier(
      profileId: kAg05,
      group: GarlicNutritionGroup.chineseKorean,
      labelEs: 'AG-05 Ajo chino / coreano',
      summaryEs:
          'Perfil prudente por trazabilidad/adaptacion; vigilar N tardio, sanidad y curado.',
      isProtected: isProtected,
    );
  }

  return GarlicNutritionModifier(
    profileId: kAgGen,
    group: GarlicNutritionGroup.generic,
    labelEs: 'AG-GEN Ajo generico',
    summaryEs: 'Perfil conservador y migrable; no asume tipo comercial.',
    isProtected: isProtected,
  );
}

String _canonicalGarlicProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalGarlicProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>[
    'blanco',
    'perla',
    'orion',
    'san marqueno',
    'diamante',
    'egipto',
  ])) {
    return kAg01;
  }
  if (_containsAny(joined, const <String>[
    'jaspeado',
    'calera',
    'rayado',
    'cezac',
    'barretero',
    'inifap',
    'tacatzcuaro',
    'tinguindin',
  ])) {
    return kAg02;
  }
  if (_containsAny(joined, const <String>['morado', 'purple'])) return kAg03;
  if (_containsAny(joined, const <String>['criollo regional', 'ajo criollo'])) {
    return kAg04;
  }
  if (_containsAny(joined, const <String>['chino', 'coreano', 'cedel'])) {
    return kAg05;
  }
  return kAgGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
