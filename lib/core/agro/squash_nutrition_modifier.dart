import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';

/// Grupos de nutrición por tipo UX dentro del cultivo madre calabaza.
///
/// La lógica activa de v1 sigue siendo NPK; estos grupos sirven para
/// matizar la presión de etapa y el mensaje farmer-friendly según el
/// destino comercial (tierno, maduro, semilla).
enum SquashNutritionGroup {
  generic,
  italianZucchini,
  criollaMilpa,
  ballRound,
  castillaPumpkin,
  butternut,
  chilacayote,
  pipianSeed,
}

/// Modificador nutricional por perfil de calabaza.
///
/// `isProtected` se infiere de alias/calendario. NO activa hidroponía:
/// significa suelo bajo malla / invernadero / macro túnel / casa malla.
class SquashNutritionModifier {
  const SquashNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
  });

  final String profileId;
  final SquashNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;

  bool get isGeneric => group == SquashNutritionGroup.generic;

  /// Cosecha continua de fruto tierno (calabacita).
  bool get isTenderContinuousHarvest =>
      group == SquashNutritionGroup.italianZucchini ||
      group == SquashNutritionGroup.criollaMilpa ||
      group == SquashNutritionGroup.ballRound;

  /// Fruto maduro de cosecha única (Castilla, butternut, chilacayote).
  bool get isMatureFruit =>
      group == SquashNutritionGroup.castillaPumpkin ||
      group == SquashNutritionGroup.butternut ||
      group == SquashNutritionGroup.chilacayote;

  /// Destino semilla seca (CA-07).
  bool get isSeedFocused => group == SquashNutritionGroup.pipianSeed;

  /// Tipos vigorosos / ciclo largo: chilacayote y pipián.
  bool get isLongCycle =>
      group == SquashNutritionGroup.chilacayote ||
      group == SquashNutritionGroup.pipianSeed;

  /// Ajuste de presión por etapa, según el tipo.
  ///
  /// - Tierno continuo: K sostenido en producción; N moderado.
  /// - Maduro: N a la baja en llenado/cosecha; K alto.
  /// - Semilla: K sube en llenado; Mg/S quedan como contexto de balance.
  /// - Chilacayote: reposición suave y extendida.
  /// - Fin de ciclo: presión neutra/conservadora; nunca empuja productivo.
  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = (stageKey ?? '').toLowerCase();
    final isCritical = stage.contains('flor') ||
        stage.contains('cuaj') ||
        stage.contains('amarre') ||
        stage.contains('poliniz');
    final isFilling = stage.contains('llen') || stage.contains('fill');
    final isHarvest = stage.contains('progresiv') || stage.contains('harvest');
    final isLate = _isLateStageInternal(stage);
    final isProduction = isCritical || isFilling || isHarvest;
    final isVegetative =
        stage.contains('vegetativo') || stage.contains('vegetative');

    // En cierre de ciclo no empujamos NPK como si todavía hubiera amarre,
    // llenado o cortes. Bajamos un poco la presión para evitar sobreaplicación
    // y dejamos K neutral (no sumar). Cosecha progresiva NO entra aquí.
    if (isLate) {
      if (nutrient == AgroMetricKey.n) return -0.04;
      return 0.0;
    }

    switch (group) {
      case SquashNutritionGroup.generic:
        // CA-GEN: conservador. Si está en producción y N alto, baja un
        // poco la presión para evitar empujar follaje sin razón.
        if (nutrient == AgroMetricKey.n && isProduction) return -0.02;
        return 0.0;

      case SquashNutritionGroup.italianZucchini:
      case SquashNutritionGroup.ballRound:
        // Calabacita y bola: cosecha continua. K sube en producción.
        if (nutrient == AgroMetricKey.k && isProduction) return 0.05;
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest)) {
          return -0.02;
        }
        return 0.0;

      case SquashNutritionGroup.criollaMilpa:
        // Criolla / milpa: sistema mixto, no sobrefertilizar.
        if (nutrient == AgroMetricKey.n && isVegetative) return -0.03;
        if (nutrient == AgroMetricKey.k && isProduction) return 0.03;
        return 0.0;

      case SquashNutritionGroup.castillaPumpkin:
        // Castilla: fruto grande maduro. K alto en llenado, bajar N
        // tarde para no retrasar madurez/cáscara.
        if (nutrient == AgroMetricKey.k && (isFilling || isHarvest)) {
          return 0.06;
        }
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest || isLate)) {
          return -0.04;
        }
        return 0.0;

      case SquashNutritionGroup.butternut:
        // Butternut: calidad de almacenamiento manda; K + balance.
        if (nutrient == AgroMetricKey.k && (isFilling || isHarvest)) {
          return 0.06;
        }
        if (nutrient == AgroMetricKey.n && (isFilling || isHarvest)) {
          return -0.03;
        }
        return 0.0;

      case SquashNutritionGroup.chilacayote:
        // Chilacayote: reposición suave y extendida; ciclo muy largo.
        if (nutrient == AgroMetricKey.n && isCritical) return -0.02;
        if (nutrient == AgroMetricKey.k && (isFilling || isHarvest)) {
          return 0.03;
        }
        return 0.0;

      case SquashNutritionGroup.pipianSeed:
        // CA-07 pipián: objetivo semilla. K manda; Mg/S quedan como
        // contexto y N alto al final castiga peso de semilla.
        if (nutrient == AgroMetricKey.k && (isFilling || isHarvest)) {
          return 0.05;
        }
        if (nutrient == AgroMetricKey.n && (isHarvest || isLate)) {
          return -0.05;
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

  /// Frase corta para el panel de NPK. NO incluye dosis ni Ca/Mg/S como
  /// nutriente activo; solo contexto agronómico v1.
  String practicalCaution(AgroMetricKey nutrient, String stageKey) {
    final stage = stageKey.toLowerCase();
    final isCritical = stage.contains('flor') ||
        stage.contains('cuaj') ||
        stage.contains('amarre');
    final isProduction = isCritical ||
        stage.contains('llen') ||
        stage.contains('progresiv') ||
        stage.contains('harvest');
    final isLate = _isLateStageInternal(stage);

    // En cierre de ciclo / senescencia el mensaje productivo del perfil
    // (cortes continuos, llenado, etc.) es engañoso. Devolver una frase
    // corta de "cierre" por perfil. Cosecha progresiva NO entra aquí.
    if (isLate) {
      switch (group) {
        case SquashNutritionGroup.generic:
          return 'CA-GEN en cierre: guarda la lectura y afina el tipo de calabaza para el próximo ciclo si hace falta.';
        case SquashNutritionGroup.italianZucchini:
        case SquashNutritionGroup.ballRound:
          return 'Calabacita en cierre: ya no se busca sostener cortes; registra K, agua y sanidad para ajustar el próximo ciclo.';
        case SquashNutritionGroup.criollaMilpa:
          return 'Criolla/milpa en cierre: registra humedad, sanidad y nutrición para ajustar el siguiente temporal.';
        case SquashNutritionGroup.castillaPumpkin:
        case SquashNutritionGroup.butternut:
        case SquashNutritionGroup.chilacayote:
          return 'Fruto maduro en cierre: ya no conviene empujar N/K; registra calidad, pudriciones y suelo para el próximo ciclo.';
        case SquashNutritionGroup.pipianSeed:
          return 'Pipián/pepita en cierre: registra madurez, secado y lectura de suelo; no refuerces como si estuviera en llenado.';
      }
    }

    switch (group) {
      case SquashNutritionGroup.generic:
        return 'CA-GEN: lectura conservadora. Si después confirmas calabacita, fruto maduro o pepita, BIO-G afina sin reiniciar historial.';
      case SquashNutritionGroup.italianZucchini:
      case SquashNutritionGroup.ballRound:
        return 'Calabacita: cortes continuos. K sostenido y agua pareja sostienen continuidad y calidad de fruto tierno.';
      case SquashNutritionGroup.criollaMilpa:
        return 'Criolla / milpa: sistema mixto y temporal. No sobrefertilizar; suelo, MO y humedad pesan más que dosis ciega.';
      case SquashNutritionGroup.castillaPumpkin:
        if (isProduction) {
          return 'Castilla: K manda llenado y endurecimiento de cáscara; bajar N tarde para no retrasar madurez.';
        }
        return 'Castilla: fruto maduro de ciclo largo. Cuida sanidad foliar y agua estable.';
      case SquashNutritionGroup.butternut:
        if (isProduction) {
          return 'Butternut: calidad postcosecha pesa fuerte. K alto, N controlado y CE bajo control sostienen firmeza y vida de almacén.';
        }
        return 'Butternut: ciclo largo con destino almacenamiento. No retrasar madurez con N tardío.';
      case SquashNutritionGroup.chilacayote:
        return 'Chilacayote: ciclo muy largo y vigoroso. Reposición suave; vigila CE acumulada y no fuerces curva corta.';
      case SquashNutritionGroup.pipianSeed:
        if (isProduction) {
          return 'CA-07 pipián: el objetivo es la pepita. K y agua estable mandan; Mg/S quedan como contexto de balance. N alto tarde castiga peso de semilla.';
        }
        return 'CA-07 pipián: destino semilla seca. La estimación se mide en t/ha de pepita, no de fruto fresco.';
    }
  }

  String guideCaution(AgroMetricKey nutrient, String? stageKey) {
    final base = practicalCaution(nutrient, stageKey ?? '');
    final protectedNote = isProtected
        ? ' Protegido en v1 = suelo bajo malla/invernadero/túnel; cuida humedad y ventilación, no es hidroponía.'
        : '';
    return '$base$protectedNote';
  }

  // Detección compartida de fin de ciclo / senescencia. Cosecha progresiva
  // (productiva activa) explícitamente NO cuenta como cierre.
  static bool _isLateStageInternal(String stage) {
    if (stage.contains('progresiv')) return false;
    return stage.contains('senesc') ||
        stage.contains('senescence') ||
        stage.contains('lateseason') ||
        stage.contains('late') ||
        stage.contains('cierre') ||
        stage.contains('cerrando') ||
        stage.contains('fincic') ||
        stage.contains('fin_cic') ||
        stage.contains('fin cic') ||
        stage.contains('fin ciclo') ||
        stage.contains('fin_ciclo');
  }
}

/// Resuelve el modificador a partir de cualquier combinación de
/// profileId, varietyId, alias o calendarId.
SquashNutritionModifier resolveSquashNutritionModifier({
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

  final canonical = _canonicalSquashProfile(tokens, joined);
  final isProtected = _containsAny(joined, const <String>[
    'protegido',
    'invernadero',
    'malla',
    'casa malla',
    'casa sombra',
    'malla sombra',
    'macro tunel',
    'macro túnel',
    'high tunnel',
    'protected',
  ]);

  if (canonical == kCa01) {
    return SquashNutritionModifier(
      profileId: kCa01,
      group: SquashNutritionGroup.italianZucchini,
      labelEs: 'CA-01 Calabacita italiana / zucchini',
      summaryEs: 'Fruto tierno de corte continuo; K sostenido, N moderado.',
      isProtected: isProtected,
    );
  }
  if (canonical == kCa02) {
    return SquashNutritionModifier(
      profileId: kCa02,
      group: SquashNutritionGroup.criollaMilpa,
      labelEs: 'CA-02 Calabacita criolla / huicha / milpa',
      summaryEs: 'Sistema mixto / temporal; conservador, sin sobrefertilizar.',
      isProtected: isProtected,
    );
  }
  if (canonical == kCa03) {
    return SquashNutritionModifier(
      profileId: kCa03,
      group: SquashNutritionGroup.ballRound,
      labelEs: 'CA-03 Calabacita de bola / redonda',
      summaryEs: 'Fruto tierno esférico; cuidar calibre y forma con K y agua estable.',
      isProtected: isProtected,
    );
  }
  if (canonical == kCa04) {
    return SquashNutritionModifier(
      profileId: kCa04,
      group: SquashNutritionGroup.castillaPumpkin,
      labelEs: 'CA-04 Calabaza de Castilla',
      summaryEs: 'Fruto maduro de ciclo largo; K alto, N a la baja en llenado.',
      isProtected: isProtected,
    );
  }
  if (canonical == kCa05) {
    return SquashNutritionModifier(
      profileId: kCa05,
      group: SquashNutritionGroup.butternut,
      labelEs: 'CA-05 Butternut / buchona / mantequilla',
      summaryEs: 'Calidad postcosecha; K alto, N controlado tras cuajado.',
      isProtected: isProtected,
    );
  }
  if (canonical == kCa06) {
    return SquashNutritionModifier(
      profileId: kCa06,
      group: SquashNutritionGroup.chilacayote,
      labelEs: 'CA-06 Chilacayote',
      summaryEs: 'Ciclo muy largo; reposición suave y extendida.',
      isProtected: isProtected,
    );
  }
  if (canonical == kCa07) {
    return SquashNutritionModifier(
      profileId: kCa07,
      group: SquashNutritionGroup.pipianSeed,
      labelEs: 'CA-07 Pipián / pipiana / pepita',
      summaryEs: 'Destino semilla seca; K y agua estable mandan. Mg/S solo como contexto.',
      isProtected: isProtected,
    );
  }

  return SquashNutritionModifier(
    profileId: kCaGen,
    group: SquashNutritionGroup.generic,
    labelEs: 'CA-GEN Calabaza genérica',
    summaryEs: 'Perfil conservador y migrable; no asume tierno, maduro ni semilla.',
    isProtected: isProtected,
  );
}

String _canonicalSquashProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalSquashProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>[
    'squash_zucchini',
    'zucchini',
    'zuccini',
    'calabacin',
    'calabacín',
    'italiana',
  ])) {
    return kCa01;
  }
  if (_containsAny(joined, const <String>[
    'squash_criolla',
    'criolla',
    'huicha',
    'milpa',
    'temporal',
  ])) {
    return kCa02;
  }
  if (_containsAny(joined, const <String>[
    'squash_round',
    'bola',
    'redonda',
    'eight ball',
    'round zucchini',
  ])) {
    return kCa03;
  }
  if (_containsAny(joined, const <String>[
    'squash_castilla',
    'castilla',
    'pumpkin mexicano',
    'altar',
    'winter squash',
  ])) {
    return kCa04;
  }
  if (_containsAny(joined, const <String>[
    'squash_butternut',
    'butternut',
    'buchona',
    'mantequilla',
    'cacahuate',
  ])) {
    return kCa05;
  }
  if (_containsAny(joined, const <String>[
    'squash_chilacayote',
    'chilacayote',
    'chilacayota',
    'alcayota',
  ])) {
    return kCa06;
  }
  if (_containsAny(joined, const <String>[
    'squash_pipian',
    'pipian',
    'pipián',
    'pipiana',
    'pepita',
    'chihua',
    'cushaw',
    'arota',
  ])) {
    return kCa07;
  }
  return kCaGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
