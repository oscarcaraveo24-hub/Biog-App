import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/widgets/seeds/onion_profiles.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';

/// Línea de presentación del ciclo del cultivo (label/value/helper).
///
/// Reemplaza el texto fijo "Estimado a cosecha" por una política
/// dinámica: la etiqueta y el valor dependen del cultivo, perfil y
/// etapa fenológica. En granos sigue diciendo "Estimado a cosecha";
/// en hortalizas de fruto distingue primera cosecha, ventana activa,
/// cierre de ciclo, maduración o madurez de semilla.
class CropCycleDisplayLine {
  final String label;
  final String value;
  final String? helper;

  const CropCycleDisplayLine({
    required this.label,
    required this.value,
    this.helper,
  });
}

/// Resuelve qué texto mostrar como "línea de ciclo" en la card de cultivo.
///
/// Reglas resumidas:
/// - Granos (maize/wheat/barley/oat/bean): "Estimado a cosecha:" o
///   "Cierre de ciclo:" si ya está en etapa final.
/// - Hortalizas de fruto: distingue primera cosecha, ventana activa,
///   cierre, llenado/maduración por perfil de calabaza, etc.
/// - Trees / ornamentales / generic: placeholders conservadores.
///
/// Importante: cosechaProgresiva NO es fin de ciclo, es ventana
/// productiva activa.
CropCycleDisplayLine resolveCycleDisplayLine({
  required String cropId,
  required String? profileId,
  required String? stageKey,
  required String? stageLabel,
  required int? expectedDaysToEnd,
}) {
  final crop = cropId.toLowerCase().trim();
  final stage = (stageKey ?? '').toLowerCase();
  final daysValue = expectedDaysToEnd ?? -1;
  final hasDays = daysValue > 0;

  final isLate = _isLateStage(stage);
  final isProgressiveHarvest = _isProgressiveHarvest(stage);
  final isFilling = stage.contains('llen') || stage.contains('fill');

  // Familia
  final family = _resolveFamily(crop);

  // Granos
  if (family == _CropFamily.grain) {
    if (isLate) {
      return CropCycleDisplayLine(
        label: 'Cierre de ciclo:',
        value: hasDays ? '$daysValue días aprox.' : 'Cerrando',
      );
    }
    return CropCycleDisplayLine(
      label: 'Estimado a cosecha:',
      value: hasDays ? '$daysValue días' : 'Pendiente',
    );
  }

  // Tulipán (bulbosa estacional): línea de ciclo por etapa (Documento A §13).
  // Nunca dice "estimado a cosecha", "cultivo muerto" ni "sin cultivo activo".
  // En dormancia muestra "Bulbo en reposo", NO cierra el registro.
  if (family == _CropFamily.seasonalBulb) {
    final profile = (profileId ?? '').toLowerCase();
    final bool isCutFlower =
        profile.contains('cut') || profile.contains('tu_04');
    if (stage.contains('dorman')) {
      return const CropCycleDisplayLine(
        label: 'Estado del ciclo:',
        value: 'Bulbo en reposo',
      );
    }
    if (stage.contains('senesc')) {
      return CropCycleDisplayLine(
        label: 'Cierre de temporada:',
        value: hasDays ? '$daysValue días aprox.' : 'Cerrando',
      );
    }
    if (stage.contains('recharge') || stage.contains('recarga')) {
      return CropCycleDisplayLine(
        label: 'Recarga del bulbo:',
        value: hasDays ? '$daysValue días aprox.' : 'En curso',
      );
    }
    if (stage.contains('flower') || stage.contains('flor')) {
      return CropCycleDisplayLine(
        label: isCutFlower ? 'Ventana de corte:' : 'Ventana de floración:',
        value: 'Activa',
      );
    }
    return CropCycleDisplayLine(
      label: 'Floración estimada:',
      value: hasDays ? '$daysValue días aprox.' : 'Pendiente',
    );
  }

  // Girasol y Cempasúchil (ornamentales anuales verdaderas): línea de ciclo por
  // etapa. El final `cycle_complete` es TERMINAL: nunca dice "estimado a
  // cosecha" ni "cultivo muerto"; invita a registrar una nueva siembra. La
  // "ventana de corte" es solo un rótulo de lectura: NO activa cosecha ni
  // rendimiento, y en el Cempasúchil cortar una flor tampoco cierra el ciclo.
  if (family == _CropFamily.annualOrnamental) {
    final bool isCutFlower = annualOrnamentalIsCutFlowerProfile(
      cropId,
      profileId,
    );
    if (stage.contains('cycle_complete') ||
        stage.contains('cycle') ||
        stage.contains('complete') ||
        stage.contains('terminado')) {
      return const CropCycleDisplayLine(
        label: 'Estado del ciclo:',
        value: 'Ciclo terminado',
        helper: 'Para cultivar otro, registra una nueva siembra.',
      );
    }
    if (stage.contains('senesc') || stage.contains('secand')) {
      return CropCycleDisplayLine(
        label: 'Cierre de ciclo:',
        value: hasDays ? '$daysValue días aprox.' : 'Cerrando',
      );
    }
    if (stage.contains('post_bloom') || stage.contains('envejec')) {
      return CropCycleDisplayLine(
        label: 'Flor envejeciendo:',
        value: hasDays ? '$daysValue días aprox.' : 'En curso',
      );
    }
    if (stage.contains('flower') || stage.contains('flor')) {
      return CropCycleDisplayLine(
        label: isCutFlower ? 'Ventana de corte:' : 'Ventana de floración:',
        value: 'Activa',
      );
    }
    return CropCycleDisplayLine(
      label: 'Floración estimada:',
      value: hasDays ? '$daysValue días aprox.' : 'Pendiente',
    );
  }

  // Hortalizas de fruto
  if (family == _CropFamily.fruitVeg) {
    if (isLate) {
      return CropCycleDisplayLine(
        label: 'Cierre de ciclo:',
        value: hasDays ? '$daysValue días aprox.' : 'Cerrando',
      );
    }

    // Calabaza tiene matices por perfil además del estado fenológico.
    if (crop == 'squash' ||
        crop == 'calabaza' ||
        crop == 'pumpkin' ||
        crop == 'zucchini' ||
        crop == 'calabacita') {
      final squashLine = _resolveSquashLine(
        profileId: profileId,
        isProgressiveHarvest: isProgressiveHarvest,
        isFilling: isFilling,
        hasDays: hasDays,
        daysValue: daysValue,
      );
      if (squashLine != null) return squashLine;
    }

    if (isProgressiveHarvest) {
      return CropCycleDisplayLine(
        label: 'Ventana de cosecha:',
        value: hasDays ? 'Activa · $daysValue días al cierre' : 'Activa',
      );
    }

    return CropCycleDisplayLine(
      label: 'Estimado a primera cosecha:',
      value: hasDays ? '$daysValue días' : 'Pendiente',
    );
  }

  // Hortalizas de bulbo (cebolla / ajo): calibre, cuello, dientes y curado.
  if (family == _CropFamily.bulbVeg) {
    final isGarlic = crop == 'garlic' || crop == 'crop_garlic' || crop == 'ajo';
    if (isGarlic) {
      final isScapeEvent =
          stage.contains('escapo') ||
          stage.contains('canuto') ||
          stage.contains('escobete') ||
          stage.contains('broom') ||
          stage.contains('scape') ||
          stage.contains('bolting');
      final isVernalization =
          stage.contains('vernal') ||
          stage.contains('frio') ||
          stage.contains('cold');
      final isMaturity =
          stage.contains('madur') ||
          stage.contains('cosech') ||
          stage.contains('harvest') ||
          stage.contains('curado') ||
          stage.contains('curing');
      final isBulbFormation =
          stage.contains('diferenci') ||
          stage.contains('diente') ||
          stage.contains('bulb') ||
          stage.contains('bulbo') ||
          stage.contains('llenado') ||
          stage.contains('fill');

      if (isScapeEvent) {
        return const CropCycleDisplayLine(
          label: 'Evento fisiologico:',
          value: 'Escapo / escobeteado',
          helper:
              'Compatible con estres, frio irregular o N tardio; no se corrige con NPK.',
        );
      }
      if (isVernalization) {
        return CropCycleDisplayLine(
          label: 'Ventana de frio:',
          value: hasDays ? '$daysValue dias aprox.' : 'En evaluacion',
          helper:
              'La vernalizacion define potencial de dientes; no la fuerces con fertilizante.',
        );
      }
      if (isMaturity) {
        return CropCycleDisplayLine(
          label: 'Maduracion / curado:',
          value: hasDays ? '$daysValue dias aprox.' : 'Revisar en campo',
          helper:
              'Baja N y agua tardia; cuida cuello, curado y descarte comercial.',
        );
      }
      if (isBulbFormation) {
        return CropCycleDisplayLine(
          label: 'Llenado de bulbo estimado:',
          value: hasDays ? 'en $daysValue dias aprox.' : 'En curso',
          helper:
              'K, agua estable y CE baja sostienen calibre; revisa sanidad de bulbo.',
        );
      }
      return CropCycleDisplayLine(
        label: 'Ventana de cosecha estimada:',
        value: hasDays ? 'en $daysValue dias aprox.' : 'Pendiente',
      );
    }

    final isBunching = _canonicalOnionProfile(profileId) == kOn05;
    final isBolting =
        stage.contains('espig') ||
        stage.contains('bolting') ||
        stage.contains('seedstalk');
    final isMaturity =
        stage.contains('madur') ||
        stage.contains('cosech') ||
        stage.contains('harvest') ||
        stage.contains('curado');
    final isBulbFormation =
        stage.contains('induccion') ||
        stage.contains('bulb') ||
        stage.contains('bulbo') ||
        stage.contains('llenado') ||
        stage.contains('fill');

    if (isBolting) {
      return const CropCycleDisplayLine(
        label: 'Cierre de ciclo:',
        value: 'Espigado / fuera de punto',
        helper:
            'El tallo floral no es productivo; revisa cosecha y registra la causa.',
      );
    }
    if (isMaturity) {
      return CropCycleDisplayLine(
        label: isBunching ? 'Ventana de cosecha:' : 'Maduración / cosecha:',
        value: hasDays ? '$daysValue días aprox.' : 'Revisar en campo',
        helper: isBunching
            ? 'Corta el manojo en su punto; no esperes bulbo seco completo.'
            : 'Revisa cuello, madurez y curado; evita N y riego tardíos.',
      );
    }
    if (isBulbFormation) {
      return CropCycleDisplayLine(
        label: isBunching
            ? 'Cosecha de manojo estimada:'
            : 'Maduración estimada:',
        value: hasDays ? 'en $daysValue días aprox.' : 'En curso',
        helper: isBunching
            ? 'El objetivo es hoja + base tierna.'
            : 'Protege calibre con agua estable y salinidad controlada.',
      );
    }
    return CropCycleDisplayLine(
      label: isBunching
          ? 'Cosecha de manojo estimada:'
          : 'Ventana de cosecha estimada:',
      value: hasDays ? 'en $daysValue días aprox.' : 'Pendiente',
    );
  }

  // Hortalizas de hoja (lechuga): lenguaje de ventana comercial y
  // cosecha oportuna, nunca "primera cosecha" de fruto ni grano.
  if (family == _CropFamily.leafVeg) {
    final isOverMature = isLate || stage.contains('sobremadur');
    final isHarvestWindow =
        stage.contains('ventanacosecha') || stage.contains('ventana');

    if (isOverMature) {
      return const CropCycleDisplayLine(
        label: 'Cierre de ciclo:',
        value: 'Punto de cosecha pasado',
        helper: 'Revisa cosecha urgente: la calidad baja rápido.',
      );
    }
    if (isHarvestWindow) {
      return CropCycleDisplayLine(
        label: 'Ventana de cosecha:',
        value: hasDays
            ? 'Punto óptimo · $daysValue días al cierre'
            : 'Punto óptimo',
        helper: 'Buen momento para revisar firmeza, turgencia y cortar.',
      );
    }
    return CropCycleDisplayLine(
      label: 'Ventana de cosecha estimada:',
      value: hasDays ? 'en $daysValue días aprox.' : 'Pendiente',
    );
  }

  // Árboles / frutales (cuando se incorporen).
  if (family == _CropFamily.tree) {
    return CropCycleDisplayLine(
      label: 'Próxima etapa fenológica:',
      value: stageLabel?.trim().isNotEmpty == true
          ? stageLabel!.trim()
          : 'Pendiente',
    );
  }

  // Ornamentales (cactus): no son cíclicas, no hay cosecha. Se muestra el
  // estado de la planta en lenguaje de agricultor, no "estado ornamental".
  if (family == _CropFamily.ornamental) {
    return CropCycleDisplayLine(
      label: 'Estado de la planta:',
      value: stageLabel?.trim().isNotEmpty == true
          ? stageLabel!.trim()
          : 'Pendiente',
    );
  }

  // Genérico / desconocido.
  return const CropCycleDisplayLine(label: 'Seguimiento:', value: 'Pendiente');
}

CropCycleDisplayLine? _resolveSquashLine({
  required String? profileId,
  required bool isProgressiveHarvest,
  required bool isFilling,
  required bool hasDays,
  required int daysValue,
}) {
  final canonical = _canonicalSquashProfile(profileId);

  if (isProgressiveHarvest) {
    if (canonical == kCa01 || canonical == kCa03) {
      return const CropCycleDisplayLine(
        label: 'Cosecha activa:',
        value: 'Cortes continuos',
      );
    }
    if (canonical == kCa02) {
      return const CropCycleDisplayLine(
        label: 'Ventana de cosecha:',
        value: 'Activa',
      );
    }
    return CropCycleDisplayLine(
      label: 'Ventana de cosecha:',
      value: hasDays ? 'Activa · $daysValue días al cierre' : 'Activa',
    );
  }

  if (isFilling) {
    if (canonical == kCa04 || canonical == kCa05 || canonical == kCa06) {
      return CropCycleDisplayLine(
        label: 'Maduración estimada:',
        value: hasDays ? '$daysValue días aprox.' : 'En curso',
      );
    }
    if (canonical == kCa07) {
      return CropCycleDisplayLine(
        label: 'Madurez de semilla:',
        value: hasDays ? '$daysValue días aprox.' : 'En curso',
      );
    }
  }

  return null;
}

String? _canonicalSquashProfile(String? profileId) {
  final raw = profileId?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  final canonical = resolveCanonicalSquashProfileId(raw);
  if (canonical != null) return canonical;
  if (raw.contains('zucchini') ||
      raw.contains('italiana') ||
      raw.contains('calabacin') ||
      raw.contains('calabacín')) {
    return kCa01;
  }
  if (raw.contains('criolla') ||
      raw.contains('huicha') ||
      raw.contains('milpa')) {
    return kCa02;
  }
  if (raw.contains('bola') || raw.contains('redonda')) {
    return kCa03;
  }
  if (raw.contains('castilla')) return kCa04;
  if (raw.contains('butternut') ||
      raw.contains('buchona') ||
      raw.contains('mantequilla')) {
    return kCa05;
  }
  if (raw.contains('chilacayote')) return kCa06;
  if (raw.contains('pipian') ||
      raw.contains('pipián') ||
      raw.contains('pepita')) {
    return kCa07;
  }
  return kCaGen;
}

String? _canonicalOnionProfile(String? profileId) {
  final raw = profileId?.trim().toLowerCase();
  if (raw == null || raw.isEmpty) return null;
  return resolveCanonicalOnionProfileId(raw);
}

bool _isLateStage(String stage) {
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

bool _isProgressiveHarvest(String stage) {
  return stage.contains('progresiv') ||
      stage.contains('cosechaprogres') ||
      stage.contains('cosecha_progres');
}

enum _CropFamily {
  grain,
  fruitVeg,
  bulbVeg,
  leafVeg,
  tree,
  ornamental,
  seasonalBulb,
  annualOrnamental,
  generic,
}

_CropFamily _resolveFamily(String crop) {
  switch (crop) {
    case 'crop_cactus':
    case 'cactus':
    case 'crop_succulent':
    case 'succulent':
    case 'suculenta':
    case 'crop_aloe':
    case 'aloe':
    case 'sabila':
    case 'sábila':
    case 'crop_agave':
    case 'agave':
    case 'maguey':
      return _CropFamily.ornamental;
    case 'crop_rose':
    case 'rose':
    case 'rosa':
    case 'rosal':
    case 'rosales':
      return _CropFamily.ornamental;
    // Tulipán: bulbosa estacional con reloj anual. NO es "ornamental" estático:
    // su línea de ciclo depende de la etapa (floración estimada → ventana de
    // floración → recarga → cierre de temporada → bulbo en reposo).
    case 'crop_tulip':
    case 'tulip':
    case 'tulipan':
    case 'tulipán':
    case 'tulipanes':
      return _CropFamily.seasonalBulb;
    // Girasol: ornamental ANUAL VERDADERA con reloj anual. NO es "ornamental"
    // estático: su línea de ciclo depende de la etapa (floración estimada →
    // ventana de floración → flor envejeciendo → cierre → ciclo terminado). El
    // final es TERMINAL (no dormancia): invita a una nueva siembra.
    case 'crop_sunflower':
    case 'sunflower':
    case 'girasol':
    case 'girasoles':
      return _CropFamily.annualOrnamental;
    // Cempasúchil: segunda ornamental ANUAL VERDADERA. Misma familia de línea
    // de ciclo que el Girasol (floración estimada → ventana de floración →
    // flores envejeciendo → cierre → ciclo terminado), con el mismo final
    // TERMINAL que invita a una nueva siembra.
    case 'crop_marigold':
    case 'marigold':
    case 'cempasuchil':
    case 'cempasúchil':
    case 'cempoalxochitl':
    case 'cempoalxóchitl':
    case 'flor de muerto':
      return _CropFamily.annualOrnamental;
    case 'lettuce':
    case 'lechuga':
    case 'spinach':
    case 'crop_spinach':
    case 'espinaca':
      return _CropFamily.leafVeg;
    case 'onion':
    case 'crop_onion':
    case 'cebolla':
    case 'garlic':
    case 'crop_garlic':
    case 'ajo':
      return _CropFamily.bulbVeg;
    case 'maize':
    case 'maiz':
    case 'corn':
    case 'wheat':
    case 'trigo':
    case 'barley':
    case 'cebada':
    case 'oat':
    case 'avena':
    case 'bean':
    case 'frijol':
      return _CropFamily.grain;
    case 'crop_apple_tree':
    case 'apple_tree':
    case 'appletree':
    case 'apple':
    case 'manzano':
    case 'manzana':
    case 'crop_pear_tree':
    case 'pear_tree':
    case 'peartree':
    case 'pear':
    case 'pera':
    case 'peral':
    case 'crop_peach_tree':
    case 'peach_tree':
    case 'peachtree':
    case 'peach':
    case 'durazno':
    case 'duraznero':
    case 'melocoton':
    case 'melocotón':
    case 'melocotonero':
    case 'crop_walnut_tree':
    case 'walnut_tree':
    case 'walnuttree':
    case 'walnut':
    case 'nogal':
    case 'nogal pecanero':
    case 'pecan':
    case 'nuez':
    case 'nuez pecana':
    case 'crop_pistachio_tree':
    case 'pistachio_tree':
    case 'pistachiotree':
    case 'pistachio':
    case 'pistache':
    case 'pistacho':
    case 'pistachero':
    case 'alfoncigo':
    case 'alfóncigo':
    case 'crop_orange_tree':
    case 'orange_tree':
    case 'orangetree':
    case 'orange':
    case 'naranjo':
    case 'naranja':
    case 'naranja dulce':
    case 'sweet orange':
    case 'crop_lemon_tree':
    case 'lemon_tree':
    case 'lemontree':
    case 'crop_lime_tree':
    case 'lime_tree':
    case 'lemon':
    case 'lime':
    case 'limon':
    case 'limón':
    case 'limonero':
    case 'lima':
    case 'crop_mango_tree':
    case 'mango_tree':
    case 'mangotree':
    case 'crop_mango':
    case 'mango':
    case 'mangos':
    case 'mangifera':
    case 'mangifera_indica':
    case 'arbol_mango':
    case 'árbol_mango':
    case 'crop_avocado_tree':
    case 'avocado_tree':
    case 'avocadotree':
    case 'crop_avocado':
    case 'avocado':
    case 'avocados':
    case 'aguacate':
    case 'aguacates':
    case 'aguacatero':
    case 'palta':
    case 'palto':
    case 'persea':
    case 'persea_americana':
    case 'arbol_aguacate':
    case 'árbol_aguacate':
      return _CropFamily.tree;
    case 'tomato':
    case 'tomate':
    case 'jitomate':
    case 'cucumber':
    case 'pepino':
    case 'chili':
    case 'chile':
    case 'pepper':
    case 'pimiento':
    case 'eggplant':
    case 'berenjena':
    case 'aubergine':
    case 'squash':
    case 'calabaza':
    case 'pumpkin':
    case 'zucchini':
    case 'calabacita':
      return _CropFamily.fruitVeg;
    default:
      return _CropFamily.generic;
  }
}
