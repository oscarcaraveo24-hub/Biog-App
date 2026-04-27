import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/eggplant_profiles.dart';

enum EggplantNutritionGroup { generic, longPurple, ovalRound, striped, white }

class EggplantNutritionModifier {
  const EggplantNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
  });

  final String profileId;
  final EggplantNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;

  bool get isGeneric => group == EggplantNutritionGroup.generic;
  bool get isVisualQualitySensitive =>
      group == EggplantNutritionGroup.striped ||
      group == EggplantNutritionGroup.white;
  bool get isFruitSizeSensitive =>
      group == EggplantNutritionGroup.ovalRound ||
      group == EggplantNutritionGroup.longPurple;

  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = (stageKey ?? '').toLowerCase();
    final isVegetative =
        stage.contains('vegetativo') || stage.contains('vegetative');
    final isCritical =
        stage.contains('flor') ||
        stage.contains('cuaj') ||
        stage.contains('amarre') ||
        stage.contains('fruitset');
    final isFilling = stage.contains('llen') || stage.contains('fill');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate =
        stage.contains('senesc') ||
        stage.contains('fin') ||
        stage.contains('late');
    final isProduction = isCritical || isFilling || isHarvest;

    switch (group) {
      case EggplantNutritionGroup.generic:
        if (nutrient == AgroMetricKey.n && isProduction) return -0.02;
        return 0.0;
      case EggplantNutritionGroup.longPurple:
        if (nutrient == AgroMetricKey.k && isProduction) return 0.04;
        if (nutrient == AgroMetricKey.n && isLate) return -0.03;
        return 0.0;
      case EggplantNutritionGroup.ovalRound:
        if (nutrient == AgroMetricKey.k && isProduction) return 0.05;
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest)) {
          return -0.02;
        }
        return 0.0;
      case EggplantNutritionGroup.striped:
      case EggplantNutritionGroup.white:
        if (nutrient == AgroMetricKey.k && isProduction) return 0.04;
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest || isLate)) {
          return -0.04;
        }
        if (nutrient == AgroMetricKey.p && (isCritical || isVegetative)) {
          return 0.01;
        }
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
    final isCritical =
        stage.contains('flor') ||
        stage.contains('cuaj') ||
        stage.contains('amarre') ||
        stage.contains('fruitset');
    final isFillingOrHarvest =
        stage.contains('llen') ||
        stage.contains('fill') ||
        stage.contains('progresiv') ||
        stage.contains('harvest');

    switch (group) {
      case EggplantNutritionGroup.generic:
        return 'BE-GEN: usa una lectura conservadora; no asumas alto rendimiento ni fruto especial hasta migrar a un tipo.';
      case EggplantNutritionGroup.longPurple:
        return 'Berenjena larga: base comercial normal; sostener K, Ca/Mg y riego uniforme desde floracion.';
      case EggplantNutritionGroup.ovalRound:
        return 'Berenjena oval/bola: cuida tamano y uniformidad; K y Ca/Mg pesan fuerte en fruto.';
      case EggplantNutritionGroup.striped:
        if (nutrient == AgroMetricKey.n && isFillingOrHarvest) {
          return 'Berenjena rayada/listada: evita N tardio alto; la calidad visual castiga manchas y fruto blando.';
        }
        return 'Berenjena rayada/listada: mas peso a calidad visual; evita CE alta, estres y humedad que marque fruta.';
      case EggplantNutritionGroup.white:
        if (isCritical || isFillingOrHarvest) {
          return 'Berenjena blanca: fruto muy visible; riego uniforme, CE baja y balance K-Ca-Mg reducen rechazo por manchas.';
        }
        return 'Berenjena blanca: cuida manchas, sol y fitotoxicidad desde etapas tempranas.';
    }
  }

  String guideCaution(AgroMetricKey nutrient, String? stageKey) {
    final base = practicalCaution(nutrient, stageKey ?? '');
    final protectedNote = isProtected
        ? ' Protegido en v1 significa suelo bajo malla/invernadero; cuida humedad y ventilacion, no hidroponia.'
        : '';
    return '$base$protectedNote';
  }
}

EggplantNutritionModifier resolveEggplantNutritionModifier({
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

  final canonical = _canonicalEggplantProfile(tokens, joined);
  final isProtected = _containsAny(joined, const <String>[
    'protegido',
    'invernadero',
    'malla',
    'casa malla',
    'casa sombra',
    'malla sombra',
    'macro tunel',
    'macro túnel',
    'protected',
  ]);

  if (canonical == kBe01) {
    return EggplantNutritionModifier(
      profileId: kBe01,
      group: EggplantNutritionGroup.longPurple,
      labelEs: 'BE-01 Berenjena larga / semilarga morada',
      summaryEs: 'Tipo dominante, fruto fresco y cosecha progresiva.',
      isProtected: isProtected,
    );
  }
  if (canonical == kBe02) {
    return EggplantNutritionModifier(
      profileId: kBe02,
      group: EggplantNutritionGroup.ovalRound,
      labelEs: 'BE-02 Berenjena oval / bola morada',
      summaryEs: 'Fruto fresco con foco en tamano y uniformidad.',
      isProtected: isProtected,
    );
  }
  if (canonical == kBe03) {
    return EggplantNutritionModifier(
      profileId: kBe03,
      group: EggplantNutritionGroup.striped,
      labelEs: 'BE-03 Berenjena rayada / listada',
      summaryEs: 'Nicho visual; manchas y cicatrices bajan valor.',
      isProtected: isProtected,
    );
  }
  if (canonical == kBe04) {
    return EggplantNutritionModifier(
      profileId: kBe04,
      group: EggplantNutritionGroup.white,
      labelEs: 'BE-04 Berenjena blanca',
      summaryEs: 'Nicho visual; alta sensibilidad a manchas y sol.',
      isProtected: isProtected,
    );
  }

  return EggplantNutritionModifier(
    profileId: kBeGen,
    group: EggplantNutritionGroup.generic,
    labelEs: 'BE-GEN Berenjena generica',
    summaryEs: 'Perfil conservador, migrable y sin alto rendimiento asumido.',
    isProtected: isProtected,
  );
}

String _canonicalEggplantProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalEggplantProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>[
    'eggplant_long_purple',
    'larga',
    'semilarga',
    'barcelona',
    'dark night',
    'orestia',
    'napoli',
  ])) {
    return kBe01;
  }
  if (_containsAny(joined, const <String>[
    'eggplant_oval_round',
    'eggplant_italian_purple',
    'oval',
    'bola',
    'italiana',
    'italian',
    'clasica',
    'clásica',
    'morada clasica',
    'morada clásica',
    'black beauty',
    'night shadow',
    'emma',
  ])) {
    return kBe02;
  }
  if (_containsAny(joined, const <String>[
    'eggplant_striped',
    'rayada',
    'listada',
    'graffiti',
    'grafiti',
  ])) {
    return kBe03;
  }
  if (_containsAny(joined, const <String>[
    'eggplant_white',
    'blanca',
    'white egg',
  ])) {
    return kBe04;
  }
  return kBeGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
