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
        value: hasDays ? 'Punto óptimo · $daysValue días al cierre' : 'Punto óptimo',
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

  // Ornamentales (cuando se incorporen).
  if (family == _CropFamily.ornamental) {
    return CropCycleDisplayLine(
      label: 'Estado ornamental:',
      value: stageLabel?.trim().isNotEmpty == true
          ? stageLabel!.trim()
          : 'Pendiente',
    );
  }

  // Genérico / desconocido.
  return const CropCycleDisplayLine(
    label: 'Seguimiento:',
    value: 'Pendiente',
  );
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

enum _CropFamily { grain, fruitVeg, leafVeg, tree, ornamental, generic }

_CropFamily _resolveFamily(String crop) {
  switch (crop) {
    case 'lettuce':
    case 'lechuga':
      return _CropFamily.leafVeg;
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
