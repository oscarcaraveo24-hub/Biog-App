import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/spinach_profiles.dart';

enum SpinachNutritionGroup {
  generic,
  savoySummer,
  savoyWinter,
  smoothBaby,
  orientalBunching,
  processing,
}

/// Modificador nutricional por perfil de espinaca.
///
/// No crea recetas por SP: ajusta presion y lenguaje sobre una base
/// universal conservadora de hoja.
class SpinachNutritionModifier {
  const SpinachNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
  });

  final String profileId;
  final SpinachNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;

  bool get isGeneric => group == SpinachNutritionGroup.generic;
  bool get isBabyLeaf => group == SpinachNutritionGroup.smoothBaby;
  bool get isProcessing => group == SpinachNutritionGroup.processing;

  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = (stageKey ?? '').toLowerCase();
    final isEstablishment =
        stage.contains('establec') || stage.contains('germin');
    final isExpansion =
        stage.contains('expansion') || stage.contains('vegetativo');
    final isCommercial =
        stage.contains('madurez') || stage.contains('cosecha');
    final isLate = _isLateStageInternal(stage);

    if (isLate) {
      if (nutrient == AgroMetricKey.n) return -0.06;
      return 0.0;
    }

    if (nutrient == AgroMetricKey.p && isEstablishment) return 0.05;

    switch (group) {
      case SpinachNutritionGroup.generic:
        if (nutrient == AgroMetricKey.n && isCommercial) return -0.03;
        return 0.0;
      case SpinachNutritionGroup.savoySummer:
        if (nutrient == AgroMetricKey.k && isExpansion) return 0.04;
        if (nutrient == AgroMetricKey.n && isCommercial) return -0.04;
        return 0.0;
      case SpinachNutritionGroup.savoyWinter:
        if (nutrient == AgroMetricKey.p && isEstablishment) return 0.06;
        if (nutrient == AgroMetricKey.n && isCommercial) return -0.03;
        return 0.0;
      case SpinachNutritionGroup.smoothBaby:
        if (nutrient == AgroMetricKey.n && (isExpansion || isCommercial)) {
          return -0.05;
        }
        if (nutrient == AgroMetricKey.k && isCommercial) return 0.04;
        return 0.0;
      case SpinachNutritionGroup.orientalBunching:
        if (nutrient == AgroMetricKey.k && (isExpansion || isCommercial)) {
          return 0.04;
        }
        if (nutrient == AgroMetricKey.n && isCommercial) return -0.03;
        return 0.0;
      case SpinachNutritionGroup.processing:
        if (nutrient == AgroMetricKey.n && isExpansion) return 0.04;
        if (nutrient == AgroMetricKey.k && isCommercial) return 0.03;
        if (nutrient == AgroMetricKey.n && isCommercial) return -0.02;
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
    final isHarvest =
        stage.contains('madurez') || stage.contains('cosecha');
    final isLate = _isLateStageInternal(stage);

    if (isLate) {
      return 'Espinaca en cierre o espigado: no conviene empujar NPK. Cosecha si aun hay calidad, cierra ciclo y registra causa.';
    }

    switch (group) {
      case SpinachNutritionGroup.generic:
        return 'SP-GEN: guia conservadora de espinaca. Afina tipo despues sin perder historial.';
      case SpinachNutritionGroup.savoySummer:
        return 'Saboya verano-calor: cuidar agua, CE y K para turgencia; no subir N fuerte con calor.';
      case SpinachNutritionGroup.savoyWinter:
        return 'Saboya invierno: P temprano y drenaje importan; evitar saturacion en clima fresco.';
      case SpinachNutritionGroup.smoothBaby:
        if (isHarvest) {
          return 'Baby leaf: evitar N tardio y CE alta; manda la calidad visual, textura y anaquel.';
        }
        return 'Baby leaf: N fino y parejo, sin golpes; sensibilidad alta a nitratos y salinidad.';
      case SpinachNutritionGroup.orientalBunching:
        return 'Oriental/manojo: balance N/K para hoja erecta y turgente; no ablandar tejido antes del corte.';
      case SpinachNutritionGroup.processing:
        return 'Proceso/industria: biomasa uniforme solo si agua y CE estan estables; no convertirlo en receta cerrada.';
    }
  }

  String guideCaution(AgroMetricKey nutrient, String? stageKey) {
    final protectedNote = isProtected
        ? ' Protegido en v1 significa suelo bajo malla/invernadero/tunel; no hidroponia.'
        : '';
    return '${practicalCaution(nutrient, stageKey ?? '')}$protectedNote';
  }

  static bool _isLateStageInternal(String stage) {
    if (stage.contains('cosecha') || stage.contains('madurez')) {
      return stage.contains('perdida') ||
          stage.contains('espig') ||
          stage.contains('senesc');
    }
    return stage.contains('perdida') ||
        stage.contains('sobremadur') ||
        stage.contains('espig') ||
        stage.contains('bolting') ||
        stage.contains('senesc') ||
        stage.contains('cierre') ||
        stage.contains('late');
  }
}

SpinachNutritionModifier resolveSpinachNutritionModifier({
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
  final canonical = _canonicalSpinachProfile(tokens, joined);
  final isProtected = _containsAny(joined, const <String>[
    'protegido',
    'invernadero',
    'malla',
    'casa sombra',
    'tunel',
    'tunnel',
    'protected',
  ]);

  if (canonical == kSp01) {
    return SpinachNutritionModifier(
      profileId: kSp01,
      group: SpinachNutritionGroup.savoySummer,
      labelEs: 'SP-01 Saboya / semi-saboya verano-calor',
      summaryEs: 'Agua y CE mandan; K sostiene turgencia y N debe controlarse con calor.',
      isProtected: isProtected,
    );
  }
  if (canonical == kSp02) {
    return SpinachNutritionModifier(
      profileId: kSp02,
      group: SpinachNutritionGroup.savoyWinter,
      labelEs: 'SP-02 Saboya / semi-saboya invierno',
      summaryEs: 'P temprano y raiz en clima fresco; evitar saturacion prolongada.',
      isProtected: isProtected,
    );
  }
  if (canonical == kSp03) {
    return SpinachNutritionModifier(
      profileId: kSp03,
      group: SpinachNutritionGroup.smoothBaby,
      labelEs: 'SP-03 Lisa / baby leaf / premium',
      summaryEs: 'Alta sensibilidad a calidad visual, nitratos y salinidad.',
      isProtected: isProtected,
    );
  }
  if (canonical == kSp04) {
    return SpinachNutritionModifier(
      profileId: kSp04,
      group: SpinachNutritionGroup.orientalBunching,
      labelEs: 'SP-04 Oriental / manojo erecta',
      summaryEs: 'Balance N/K para hoja erecta, turgente y limpia.',
      isProtected: isProtected,
    );
  }
  if (canonical == kSp05) {
    return SpinachNutritionModifier(
      profileId: kSp05,
      group: SpinachNutritionGroup.processing,
      labelEs: 'SP-05 Proceso / industria',
      summaryEs: 'Biomasa comercial uniforme, sin prometer rendimiento ni forzar N.',
      isProtected: isProtected,
    );
  }

  return SpinachNutritionModifier(
    profileId: kSpGen,
    group: SpinachNutritionGroup.generic,
    labelEs: 'SP-GEN Espinaca generica',
    summaryEs: 'Perfil conservador y migrable; no asume destino ni tipo.',
    isProtected: isProtected,
  );
}

String _canonicalSpinachProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalSpinachProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>['verano', 'calor', 'summer'])) {
    return kSp01;
  }
  if (_containsAny(joined, const <String>['invierno', 'dias cortos', 'winter'])) {
    return kSp02;
  }
  if (_containsAny(joined, const <String>['lisa', 'baby', 'smooth', 'premium'])) {
    return kSp03;
  }
  if (_containsAny(joined, const <String>['oriental', 'manojo', 'bunch'])) {
    return kSp04;
  }
  if (_containsAny(joined, const <String>['proceso', 'industria', 'processing'])) {
    return kSp05;
  }
  return kSpGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
