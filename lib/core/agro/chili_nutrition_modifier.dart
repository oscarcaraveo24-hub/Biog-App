import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/chili_profiles.dart';

enum ChiliNutritionGroup {
  generic,
  jalapeno,
  serrano,
  poblanoAncho,
  chilacaPasilla,
  guajilloMirasol,
  arbolPuya,
  habanero,
  bellPepper,
}

class ChiliNutritionModifier {
  const ChiliNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
    this.wantsDry = false,
  });

  final String profileId;
  final ChiliNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;
  final bool wantsDry;

  bool get isGeneric => group == ChiliNutritionGroup.generic;
  bool get isHighDensity =>
      group == ChiliNutritionGroup.serrano ||
      group == ChiliNutritionGroup.arbolPuya;
  bool get isLargeFruit =>
      group == ChiliNutritionGroup.poblanoAncho ||
      group == ChiliNutritionGroup.bellPepper;
  bool get isDryType =>
      group == ChiliNutritionGroup.chilacaPasilla ||
      group == ChiliNutritionGroup.guajilloMirasol ||
      group == ChiliNutritionGroup.arbolPuya ||
      wantsDry;
  bool get isChinense => group == ChiliNutritionGroup.habanero;
  bool get isContinuousHarvest =>
      group == ChiliNutritionGroup.serrano ||
      group == ChiliNutritionGroup.jalapeno ||
      group == ChiliNutritionGroup.habanero ||
      group == ChiliNutritionGroup.bellPepper;

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
      case ChiliNutritionGroup.generic:
        if (nutrient == AgroMetricKey.n && isProduction) return -0.02;
        return 0.0;
      case ChiliNutritionGroup.jalapeno:
        if (nutrient == AgroMetricKey.k && isProduction) return 0.02;
        return 0.0;
      case ChiliNutritionGroup.serrano:
        if (nutrient == AgroMetricKey.n && (isVegetative || isHarvest)) {
          return 0.03;
        }
        if (nutrient == AgroMetricKey.k && isProduction) return 0.05;
        return 0.0;
      case ChiliNutritionGroup.poblanoAncho:
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest || isLate)) {
          return wantsDry ? -0.04 : -0.01;
        }
        if (nutrient == AgroMetricKey.k && isProduction) return 0.06;
        return 0.0;
      case ChiliNutritionGroup.chilacaPasilla:
      case ChiliNutritionGroup.guajilloMirasol:
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest || isLate)) {
          return -0.04;
        }
        if (nutrient == AgroMetricKey.k && isProduction) return 0.05;
        return 0.0;
      case ChiliNutritionGroup.arbolPuya:
        if (nutrient == AgroMetricKey.n && (isVegetative || isHarvest)) {
          return 0.02;
        }
        if (nutrient == AgroMetricKey.k && isProduction) return 0.04;
        return 0.0;
      case ChiliNutritionGroup.habanero:
        if (nutrient == AgroMetricKey.p && isCritical) return 0.02;
        if (nutrient == AgroMetricKey.k && isProduction) return 0.04;
        return 0.0;
      case ChiliNutritionGroup.bellPepper:
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest)) {
          return -0.02;
        }
        if (nutrient == AgroMetricKey.k && isProduction) return 0.08;
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
      case ChiliNutritionGroup.generic:
        return 'CH-GEN: usa una lectura conservadora; no asumas fruto grande ni alto rendimiento hasta migrar a un tipo.';
      case ChiliNutritionGroup.jalapeno:
        return 'Jalapeno: mantener balance fresco/proceso; no perseguir N si la planta ya esta cargando fruto.';
      case ChiliNutritionGroup.serrano:
        return 'Serrano: alta carga y cortes continuos; fracciona N/K y vigila CE por densidad.';
      case ChiliNutritionGroup.poblanoAncho:
        if (nutrient == AgroMetricKey.n && wantsDry && isFillingOrHarvest) {
          return 'Poblano/ancho seco: baja N tardio para no retrasar color ni materia seca.';
        }
        return 'Poblano/ancho: fruto grande; K, Ca, Mg y riego uniforme pesan mucho en amarre y llenado.';
      case ChiliNutritionGroup.chilacaPasilla:
        return 'Chilaca/pasilla: orientado a secado; sostener K para color y materia seca, con N moderado al cierre.';
      case ChiliNutritionGroup.guajilloMirasol:
        return 'Guajillo/mirasol: mercado seco; sostener K y evitar exceso de humedad en cosecha.';
      case ChiliNutritionGroup.arbolPuya:
        return 'De arbol/puya: alta densidad; fracciona N/K y revisa focos de salinidad o estres por cama.';
      case ChiliNutritionGroup.habanero:
        return 'Habanero: Capsicum chinense; es mas sensible a calor, salinidad, pH y falta de Mg. Manejo estable primero.';
      case ChiliNutritionGroup.bellPepper:
        if (isCritical || isFillingOrHarvest) {
          return 'Morron/chile gordo: fruto grande y calidad visual; prioriza K-Ca-Mg, riego uniforme y CE baja para evitar BER.';
        }
        return 'Morron/chile gordo: prepara la planta para fruto grande; evita exceso de N antes de floracion.';
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

ChiliNutritionModifier resolveChiliNutritionModifier({
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

  final canonical = _canonicalChiliProfile(tokens, joined);
  final isProtected = _containsAny(joined, const <String>[
    'protegido',
    'invernadero',
    'malla',
    'casa malla',
    'protected',
  ]);
  final wantsDry = _containsAny(joined, const <String>[
    'seco',
    'seca',
    'dry',
    'deshidrat',
    'ancho seco',
    'mulato seco',
    'pasilla',
    'guajillo',
  ]);

  if (canonical == kCh01) {
    return ChiliNutritionModifier(
      profileId: kCh01,
      group: ChiliNutritionGroup.jalapeno,
      labelEs: 'CH-01 Jalapeno',
      summaryEs: 'Intermedio, fresco/proceso/chipotle.',
      isProtected: isProtected,
      wantsDry: wantsDry,
    );
  }
  if (canonical == kCh02) {
    return ChiliNutritionModifier(
      profileId: kCh02,
      group: ChiliNutritionGroup.serrano,
      labelEs: 'CH-02 Serrano',
      summaryEs: 'Alta carga y cosecha continua.',
      isProtected: isProtected,
      wantsDry: wantsDry,
    );
  }
  if (canonical == kCh03) {
    return ChiliNutritionModifier(
      profileId: kCh03,
      group: ChiliNutritionGroup.poblanoAncho,
      labelEs: 'CH-03 Poblano / Ancho',
      summaryEs: 'Fruto grande; fresco o destino seco si se declara.',
      isProtected: isProtected,
      wantsDry: wantsDry,
    );
  }
  if (canonical == kCh04) {
    return ChiliNutritionModifier(
      profileId: kCh04,
      group: ChiliNutritionGroup.chilacaPasilla,
      labelEs: 'CH-04 Chilaca / Pasilla',
      summaryEs: 'Fruto largo; fresco como chilaca o seco como pasilla.',
      isProtected: isProtected,
      wantsDry: wantsDry,
    );
  }
  if (canonical == kCh05) {
    return ChiliNutritionModifier(
      profileId: kCh05,
      group: ChiliNutritionGroup.guajilloMirasol,
      labelEs: 'CH-05 Mirasol / Guajillo',
      summaryEs: 'Destino seco, color y materia seca.',
      isProtected: isProtected,
      wantsDry: true,
    );
  }
  if (canonical == kCh06) {
    return ChiliNutritionModifier(
      profileId: kCh06,
      group: ChiliNutritionGroup.arbolPuya,
      labelEs: 'CH-06 De arbol / Puya',
      summaryEs: 'Fruto pequeno, alta densidad, fresco o seco.',
      isProtected: isProtected,
      wantsDry: wantsDry,
    );
  }
  if (canonical == kCh07) {
    return ChiliNutritionModifier(
      profileId: kCh07,
      group: ChiliNutritionGroup.habanero,
      labelEs: 'CH-07 Habanero',
      summaryEs: 'Capsicum chinense, mas termico y sensible.',
      isProtected: isProtected,
      wantsDry: wantsDry,
    );
  }
  if (canonical == kCh08) {
    return ChiliNutritionModifier(
      profileId: kCh08,
      group: ChiliNutritionGroup.bellPepper,
      labelEs: 'CH-08 Pimiento morron / Chile gordo',
      summaryEs: 'Fruto grande y calidad visual.',
      isProtected: isProtected,
      wantsDry: false,
    );
  }

  return ChiliNutritionModifier(
    profileId: kChGen,
    group: ChiliNutritionGroup.generic,
    labelEs: 'CH-GEN Chile generico',
    summaryEs: 'Perfil conservador, migrable y sin alto rendimiento asumido.',
    isProtected: isProtected,
    wantsDry: wantsDry,
  );
}

String _canonicalChiliProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalChiliProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>['chili_jalapeno', 'jalapeno'])) {
    return kCh01;
  }
  if (_containsAny(joined, const <String>['chili_serrano', 'serrano'])) {
    return kCh02;
  }
  if (_containsAny(joined, const <String>[
    'chili_poblano_ancho',
    'poblano',
    'ancho',
    'mulato',
  ])) {
    return kCh03;
  }
  if (_containsAny(joined, const <String>[
    'chili_chilaca_pasilla',
    'chilaca',
    'pasilla',
  ])) {
    return kCh04;
  }
  if (_containsAny(joined, const <String>[
    'chili_guajillo_mirasol',
    'guajillo',
    'mirasol',
  ])) {
    return kCh05;
  }
  if (_containsAny(joined, const <String>['chili_arbol', 'arbol', 'puya'])) {
    return kCh06;
  }
  if (_containsAny(joined, const <String>['chili_habanero', 'habanero'])) {
    return kCh07;
  }
  if (_containsAny(joined, const <String>[
    'chili_bell_pepper',
    'pimiento',
    'morron',
    'chile gordo',
    'bell pepper',
  ])) {
    return kCh08;
  }
  return kChGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
