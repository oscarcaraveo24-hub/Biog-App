import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/widgets/seeds/lettuce_profiles.dart';

/// Grupos de nutrición por tipo UX dentro del cultivo madre lechuga.
///
/// La lógica activa de v1 es NPK; estos grupos matizan la presión de
/// etapa y el mensaje farmer-friendly según la arquitectura comercial
/// (cabeza, mini cabeza, hoja suelta).
enum LettuceNutritionGroup {
  generic,
  romaine,
  miniRomaine,
  iceberg,
  butterhead,
  looseLeaf,
}

/// Modificador nutricional por perfil de lechuga.
///
/// `isProtected` se infiere de alias/calendario. NO activa hidroponía:
/// significa suelo bajo malla / invernadero / túnel (fuera de alcance
/// hidropónico en BIO-G v1).
class LettuceNutritionModifier {
  const LettuceNutritionModifier({
    required this.profileId,
    required this.group,
    required this.labelEs,
    required this.summaryEs,
    this.isProtected = false,
  });

  final String profileId;
  final LettuceNutritionGroup group;
  final String labelEs;
  final String summaryEs;
  final bool isProtected;

  bool get isGeneric => group == LettuceNutritionGroup.generic;

  /// Tipos que forman cabeza/cogollo compacto.
  bool get formsHead =>
      group == LettuceNutritionGroup.romaine ||
      group == LettuceNutritionGroup.miniRomaine ||
      group == LettuceNutritionGroup.iceberg ||
      group == LettuceNutritionGroup.butterhead;

  /// Hoja suelta / baby leaf: ciclo corto, sin cabeza obligatoria.
  bool get isLooseLeaf => group == LettuceNutritionGroup.looseLeaf;

  /// Ajuste de presión por etapa según el tipo comercial.
  ///
  /// Reglas conservadoras del Perfil de Fertilización §3-§10:
  /// - N a la baja cerca de cosecha (hoja tierna, nitratos, anaquel).
  /// - K de apoyo a turgencia y calidad en formación de cabeza/cosecha.
  /// - P con mayor peso en establecimiento.
  double stagePressureDelta(AgroMetricKey nutrient, String? stageKey) {
    final stage = (stageKey ?? '').toLowerCase();
    final isHead = stage.contains('cabeza') || stage.contains('formacion');
    final isHarvest = stage.contains('cosecha') || stage.contains('ventana');
    final isVegetative =
        stage.contains('vegetativo') || stage.contains('vegetative');
    final isLate = _isLateStageInternal(stage);

    // En cierre de ciclo / sobre-madurez no se empuja NPK: la planta ya
    // pasó su punto comercial. Bajar N y dejar K neutral.
    if (isLate) {
      if (nutrient == AgroMetricKey.n) return -0.05;
      return 0.0;
    }

    switch (group) {
      case LettuceNutritionGroup.generic:
        // LE-GEN: conservador. Bajar N cerca de cosecha sin más supuestos.
        if (nutrient == AgroMetricKey.n && isHarvest) return -0.04;
        return 0.0;

      case LettuceNutritionGroup.romaine:
      case LettuceNutritionGroup.iceberg:
        // Cabeza grande / ciclo más largo: K sostiene compactación y
        // turgencia; bajar N tarde para no ablandar la hoja.
        if (nutrient == AgroMetricKey.k && (isHead || isHarvest)) return 0.05;
        if (nutrient == AgroMetricKey.n && isHarvest) return -0.05;
        return 0.0;

      case LettuceNutritionGroup.miniRomaine:
        // Mini romana: ciclo corto; no sobrefertilizar N.
        if (nutrient == AgroMetricKey.k && isHead) return 0.04;
        if (nutrient == AgroMetricKey.n && isHarvest) return -0.05;
        return 0.0;

      case LettuceNutritionGroup.butterhead:
        // Mantequilla: premium, hoja muy tierna, sensible a exceso de N
        // y a Botrytis/tip burn. N más contenido en todo el cierre.
        if (nutrient == AgroMetricKey.k && (isHead || isHarvest)) return 0.04;
        if (nutrient == AgroMetricKey.n && (isHead || isHarvest)) return -0.05;
        return 0.0;

      case LettuceNutritionGroup.looseLeaf:
        // Hoja suelta / baby leaf: ciclo corto, sin cabeza. N moderado y
        // parejo; no hay etapa fuerte de compactación de K.
        if (nutrient == AgroMetricKey.n && isVegetative) return -0.02;
        if (nutrient == AgroMetricKey.n && isHarvest) return -0.05;
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

  /// Frase corta para el panel de NPK. Sin dosis, sin Ca/Mg/S como
  /// nutriente activo: solo contexto agronómico conservador v1.
  String practicalCaution(AgroMetricKey nutrient, String stageKey) {
    final stage = stageKey.toLowerCase();
    final isHarvest = stage.contains('cosecha') || stage.contains('ventana');
    final isHead = stage.contains('cabeza') || stage.contains('formacion');
    final isLate = _isLateStageInternal(stage);

    if (isLate) {
      switch (group) {
        case LettuceNutritionGroup.generic:
          return 'LE-GEN en cierre: la lechuga pasó su punto. Guarda la lectura y afina el tipo para el próximo ciclo.';
        case LettuceNutritionGroup.romaine:
        case LettuceNutritionGroup.miniRomaine:
        case LettuceNutritionGroup.iceberg:
        case LettuceNutritionGroup.butterhead:
          return 'Cabeza en cierre: ya no conviene empujar N/K. Registra calidad, espigado y suelo para ajustar el próximo ciclo.';
        case LettuceNutritionGroup.looseLeaf:
          return 'Hoja suelta en cierre: registra turgencia, sanidad y nutrición; no refuerces como si siguiera en expansión.';
      }
    }

    switch (group) {
      case LettuceNutritionGroup.generic:
        return 'LE-GEN: lectura conservadora de lechuga. Si confirmas romana, bola, mantequilla o hoja suelta, BIO-G afina sin reiniciar historial.';
      case LettuceNutritionGroup.romaine:
        if (isHarvest) {
          return 'Romana: cerca de corte, evita empujar N. Hoja firme, turgente y sin amargor pesa más que un poco más de tamaño.';
        }
        if (isHead) {
          return 'Romana: en formación de cogollo, K y agua estable apoyan compactación y nervadura firme; N moderado.';
        }
        return 'Romana / cos: cabeza alargada de 1 corte. N suficiente en expansión, K de cara a la cabeza.';
      case LettuceNutritionGroup.miniRomaine:
        return 'Mini romana / Little Gem: ciclo corto. No sobrefertilizar N; cuida CE y agua pareja para corazón compacto.';
      case LettuceNutritionGroup.iceberg:
        if (isHead || isHarvest) {
          return 'Iceberg / bola: K apoya cabeza firme y compacta. Evita N tardío que ablande la hoja y suba tip burn.';
        }
        return 'Iceberg / bola: ciclo más largo y sensible a calor. Agua estable y K son la base de una cabeza compacta.';
      case LettuceNutritionGroup.butterhead:
        return 'Mantequilla / butterhead: hoja muy tierna. N contenido cerca de cabeza y cosecha; el exceso favorece Botrytis y tip burn.';
      case LettuceNutritionGroup.looseLeaf:
        return 'Hoja suelta / baby leaf: ciclo corto. N moderado y parejo, agua estable; no hay etapa fuerte de compactación de cabeza.';
    }
  }

  String guideCaution(AgroMetricKey nutrient, String? stageKey) {
    final base = practicalCaution(nutrient, stageKey ?? '');
    final protectedNote = isProtected
        ? ' Protegido en v1 = suelo bajo malla/invernadero/túnel; cuida humedad y ventilación, no es hidroponía.'
        : '';
    return '$base$protectedNote';
  }

  // Cierre de ciclo: sobre-madurez / senescencia. La ventana de cosecha
  // (productiva activa) explícitamente NO cuenta como cierre.
  static bool _isLateStageInternal(String stage) {
    if (stage.contains('ventana') || stage.contains('cosecha')) {
      // ventanaCosecha es productiva; solo es cierre si dice sobre-madurez.
      return stage.contains('sobremadur') || stage.contains('senesc');
    }
    return stage.contains('sobremadur') ||
        stage.contains('senesc') ||
        stage.contains('lateseason') ||
        stage.contains('cierre') ||
        stage.contains('fincic') ||
        stage.contains('fin ciclo') ||
        stage.contains('fin_ciclo');
  }
}

/// Resuelve el modificador a partir de cualquier combinación de
/// profileId, varietyId, alias o calendarId.
LettuceNutritionModifier resolveLettuceNutritionModifier({
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

  final canonical = _canonicalLettuceProfile(tokens, joined);
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

  if (canonical == kLe01) {
    return LettuceNutritionModifier(
      profileId: kLe01,
      group: LettuceNutritionGroup.romaine,
      labelEs: 'LE-01 Lechuga romana / cos',
      summaryEs: 'Cabeza alargada de 1 corte; N suficiente en expansión, K de cara a la cabeza.',
      isProtected: isProtected,
    );
  }
  if (canonical == kLe02) {
    return LettuceNutritionModifier(
      profileId: kLe02,
      group: LettuceNutritionGroup.miniRomaine,
      labelEs: 'LE-02 Mini romana / corazones / Little Gem',
      summaryEs: 'Ciclo corto; no sobrefertilizar N, cuidar CE y agua pareja.',
      isProtected: isProtected,
    );
  }
  if (canonical == kLe03) {
    return LettuceNutritionModifier(
      profileId: kLe03,
      group: LettuceNutritionGroup.iceberg,
      labelEs: 'LE-03 Lechuga bola / iceberg',
      summaryEs: 'Cabeza compacta; K y agua estable mandan, N controlado tarde.',
      isProtected: isProtected,
    );
  }
  if (canonical == kLe04) {
    return LettuceNutritionModifier(
      profileId: kLe04,
      group: LettuceNutritionGroup.butterhead,
      labelEs: 'LE-04 Lechuga mantequilla / butterhead',
      summaryEs: 'Hoja tierna premium; N contenido para no favorecer Botrytis ni tip burn.',
      isProtected: isProtected,
    );
  }
  if (canonical == kLe05) {
    return LettuceNutritionModifier(
      profileId: kLe05,
      group: LettuceNutritionGroup.looseLeaf,
      labelEs: 'LE-05 Lechuga hoja suelta / orejona / baby leaf',
      summaryEs: 'Ciclo corto sin cabeza; N moderado y parejo, agua estable.',
      isProtected: isProtected,
    );
  }

  return LettuceNutritionModifier(
    profileId: kLeGen,
    group: LettuceNutritionGroup.generic,
    labelEs: 'LE-GEN Lechuga genérica',
    summaryEs: 'Perfil conservador y migrable; no asume cabeza ni baby leaf.',
    isProtected: isProtected,
  );
}

String _canonicalLettuceProfile(List<String> tokens, String joined) {
  for (final token in tokens) {
    final canonical = resolveCanonicalLettuceProfileId(token);
    if (canonical != null) return canonical;
  }
  if (_containsAny(joined, const <String>[
    'romana',
    'cos',
    'romaine',
    'oreja larga',
  ])) {
    return kLe01;
  }
  if (_containsAny(joined, const <String>[
    'mini romana',
    'corazon',
    'little gem',
    'gem',
  ])) {
    return kLe02;
  }
  if (_containsAny(joined, const <String>[
    'iceberg',
    'bola',
    'crisphead',
  ])) {
    return kLe03;
  }
  if (_containsAny(joined, const <String>[
    'mantequilla',
    'butterhead',
    'bibb',
    'boston',
  ])) {
    return kLe04;
  }
  if (_containsAny(joined, const <String>[
    'hoja suelta',
    'orejona',
    'looseleaf',
    'baby leaf',
    'babyleaf',
    'leaf lettuce',
  ])) {
    return kLe05;
  }
  return kLeGen;
}

bool _containsAny(String source, List<String> needles) {
  for (final needle in needles) {
    if (source.contains(needle)) return true;
  }
  return false;
}
