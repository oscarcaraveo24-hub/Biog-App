// lib/widgets/seeds/marigold_engine.dart
//
// Motor fenológico puro del Cempasúchil. Mantiene el MISMO patrón que
// sunflower/oat/bean/tulip (fecha ancla → día → ventanas por perfil → etapa →
// progreso → días al fin del ciclo), con la biología del ANUAL VERDADERO al
// final:
//
//   - cuando el día supera todas las ventanas, conserva la ÚLTIMA etapa
//     (`cycle_complete`) indefinidamente — es TERMINAL: no hay recarga, no hay
//     reposo, no hay bulbo que sobreviva (Documento A §0.3, §10.11);
//   - en `cycle_complete`, `stageProgressPct = 1.0` y `expectedDaysToEnd = 0`;
//   - una fecha antigua (muy posterior al fin de la ventana) resuelve a
//     `cycle_complete`, NUNCA a `unknown` ni a una etapa del Girasol.
//
// El calendario de cada temporada vive en el `MarigoldProfile` (límites de fin
// de etapa). El motor NO usa lecturas de sensores para cambiar la etapa: la
// fecha manda (Documento A §9.4). Tampoco usa el mes ni la fecha cultural: el
// 1 de noviembre no produce `flowering` (Documento A §9.4, §13.5). En v1
// `stressDelayDays` es 0 y el fotoperiodo NO aplica offset automático
// (Documento A §12.6).

import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';

class MarigoldEngine {
  MarigoldEngine._();

  /// Sentinela lógico para el final abierto de la etapa terminal.
  static const int _cycleCompleteOpenEnd = 100000;

  /// Carpeta de assets fenológicos EN DISCO. Respeta la capitalización real del
  /// repositorio: `assets/seeds/cempasuchil` (minúsculas, nombre en español).
  /// `MarigoldAssets` espeja estas mismas rutas.
  static const String _stageDir = 'assets/seeds/cempasuchil';

  static MarigoldStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required MarigoldProfile profile,
    int stressDelayDays = 0,
  }) {
    final daySinceAnchor = math.max(1, today.difference(sowingDate).inDays + 1);

    // Un retraso fisiológico NO puede empujar a una etapa más avanzada: un
    // `stressDelayDays` positivo RETARDA el desarrollo (se resta). En v1 el
    // runtime pasa 0 (Documento A §12.6).
    final effectiveDay = math.max(1, daySinceAnchor - stressDelayDays);

    final bounds = _bounds(profile);
    final currentBounds = bounds.firstWhere(
      (b) => b.contains(effectiveDay),
      orElse: () => bounds.last,
    );
    final stage = currentBounds.key;

    final double stageProgressPct;
    final int expectedDaysToEnd;
    if (stage == MarigoldStageKey.cycleComplete) {
      // Terminal: el ciclo anual terminó (Documento A §10.11).
      stageProgressPct = 1.0;
      expectedDaysToEnd = 0;
    } else {
      final denom = math.max(1, currentBounds.endDay - currentBounds.startDay);
      stageProgressPct = ((effectiveDay - currentBounds.startDay) / denom).clamp(
        0.0,
        1.0,
      );
      expectedDaysToEnd = math.max(
        0,
        profile.cycleCompleteStartDay - effectiveDay,
      );
    }

    return MarigoldStageResult(
      profile: profile,
      stage: stage,
      daySinceAnchor: daySinceAnchor,
      establishmentMode: profile.defaultEstablishmentMode,
      floweringWindow: profile.floweringWindowDays,
      expectedFloweringDay: profile.floweringWindowDays.mid,
      expectedCycleCompleteDay: profile.cycleCompleteStartDay,
      expectedDaysToEnd: expectedDaysToEnd,
      stageProgressPct: stageProgressPct,
      windowsNow: _windows(stage),
      stageId: marigoldStageIdFor(stage),
      stageLabelEs: marigoldStageDisplayName(marigoldStageIdFor(stage)),
      heroAsset: _heroAsset(stage),
      helperCaption: _helperCaption(stage),
    );
  }

  /// Construye las ventanas ordenadas desde los límites de fin del perfil. Cada
  /// `math.max` evita traslapes inválidos y garantiza las pruebas de frontera
  /// del Documento A §12.7: el día 1 es `sowing`, no hay huecos, ningún endDay
  /// es menor que el anterior y `cycle_complete` inicia el día siguiente a
  /// `senescenceEndDay`.
  static List<MarigoldStageBounds> _bounds(MarigoldProfile p) {
    final sowingEnd = math.max(1, p.sowingEndDay);
    final germStart = sowingEnd + 1;
    final germEnd = math.max(germStart, p.germinationEndDay);
    final emergStart = germEnd + 1;
    final emergEnd = math.max(emergStart, p.emergenceEndDay);
    final earlyVegStart = emergEnd + 1;
    final earlyVegEnd = math.max(earlyVegStart, p.earlyVegetativeEndDay);
    final activeVegStart = earlyVegEnd + 1;
    final activeVegEnd = math.max(activeVegStart, p.activeVegetativeEndDay);
    final stemStart = activeVegEnd + 1;
    final stemEnd = math.max(stemStart, p.stemElongationEndDay);
    final budStart = stemEnd + 1;
    final budEnd = math.max(budStart, p.budFormationEndDay);
    final flowerStart = budEnd + 1;
    final flowerEnd = math.max(flowerStart, p.floweringEndDay);
    final postBloomStart = flowerEnd + 1;
    final postBloomEnd = math.max(postBloomStart, p.postBloomEndDay);
    final senescenceStart = postBloomEnd + 1;
    final senescenceEnd = math.max(senescenceStart, p.senescenceEndDay);
    final cycleStart = senescenceEnd + 1;

    return <MarigoldStageBounds>[
      MarigoldStageBounds(
        key: MarigoldStageKey.sowing,
        startDay: 1,
        endDay: sowingEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.germination,
        startDay: germStart,
        endDay: germEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.emergence,
        startDay: emergStart,
        endDay: emergEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.earlyVegetativeGrowth,
        startDay: earlyVegStart,
        endDay: earlyVegEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.activeVegetativeGrowth,
        startDay: activeVegStart,
        endDay: activeVegEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.stemElongation,
        startDay: stemStart,
        endDay: stemEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.budFormation,
        startDay: budStart,
        endDay: budEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.flowering,
        startDay: flowerStart,
        endDay: flowerEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.postBloom,
        startDay: postBloomStart,
        endDay: postBloomEnd,
      ),
      MarigoldStageBounds(
        key: MarigoldStageKey.senescence,
        startDay: senescenceStart,
        endDay: senescenceEnd,
      ),
      // `cycle_complete`: TERMINAL de final abierto. Cuando el día excede las
      // ventanas se conserva esta etapa (Documento A §10.11).
      MarigoldStageBounds(
        key: MarigoldStageKey.cycleComplete,
        startDay: cycleStart,
        endDay: _cycleCompleteOpenEnd,
      ),
    ];
  }

  static List<SeedWindowKey> _windows(MarigoldStageKey stage) {
    // Ventanas operativas por etapa (Documento B §10.3, §17). La nutrición pesa
    // desde plántula hasta botón/flor; la ventana crítica cubre germinación,
    // emergencia, botón y floración (severityBump = 2), más siembra y
    // alargamiento (severityBump = 1). En `cycle_complete` solo queda scouting:
    // no hay manejo activo (Documento B §24.3).
    switch (stage) {
      case MarigoldStageKey.sowing:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case MarigoldStageKey.germination:
      case MarigoldStageKey.emergence:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case MarigoldStageKey.earlyVegetativeGrowth:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case MarigoldStageKey.activeVegetativeGrowth:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
        ];
      case MarigoldStageKey.stemElongation:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case MarigoldStageKey.budFormation:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case MarigoldStageKey.flowering:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case MarigoldStageKey.postBloom:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
        ];
      case MarigoldStageKey.senescence:
      case MarigoldStageKey.cycleComplete:
        return const <SeedWindowKey>[SeedWindowKey.scouting];
    }
  }

  /// Imagen fenológica por etapa. Las rutas se inlinean aquí (patrón
  /// sunflower/oat/tulip) y coinciden EXACTAMENTE con
  /// `assets/seeds/cempasuchil/` en disco.
  static String _heroAsset(MarigoldStageKey stage) {
    switch (stage) {
      case MarigoldStageKey.sowing:
        return '$_stageDir/cempasuchil_stage_sowing.png';
      case MarigoldStageKey.germination:
        return '$_stageDir/cempasuchil_stage_germination.png';
      case MarigoldStageKey.emergence:
        return '$_stageDir/cempasuchil_stage_emergence.png';
      case MarigoldStageKey.earlyVegetativeGrowth:
        return '$_stageDir/cempasuchil_stage_early_vegetative_growth.png';
      case MarigoldStageKey.activeVegetativeGrowth:
        return '$_stageDir/cempasuchil_stage_active_vegetative_growth.png';
      case MarigoldStageKey.stemElongation:
        return '$_stageDir/cempasuchil_stage_stem_elongation.png';
      case MarigoldStageKey.budFormation:
        return '$_stageDir/cempasuchil_stage_bud_formation.png';
      case MarigoldStageKey.flowering:
        return '$_stageDir/cempasuchil_stage_flowering.png';
      case MarigoldStageKey.postBloom:
        return '$_stageDir/cempasuchil_stage_post_bloom.png';
      case MarigoldStageKey.senescence:
        return '$_stageDir/cempasuchil_stage_senescence.png';
      case MarigoldStageKey.cycleComplete:
        return '$_stageDir/cempasuchil_stage_cycle_complete.png';
    }
  }

  /// Nota corta por etapa, en lenguaje de jardinero (Documento A §9.3, §10).
  /// Nunca promete una fecha cultural ni declara inducción floral.
  static String _helperCaption(MarigoldStageKey stage) {
    switch (stage) {
      case MarigoldStageKey.sowing:
        return 'La fecha de siembra inicia el reloj anual de tu Cempasúchil.';
      case MarigoldStageKey.germination:
        return 'La semilla está tomando agua y la radícula inicia bajo el '
            'suelo.';
      case MarigoldStageKey.emergence:
        return 'El brote atraviesa el sustrato y todavía es muy frágil.';
      case MarigoldStageKey.earlyVegetativeGrowth:
        return 'La plántula forma sus primeras hojas verdaderas y su raíz '
            'inicial.';
      case MarigoldStageKey.activeVegetativeGrowth:
        return 'El follaje y las ramas crecen con rapidez; todavía sin botón '
            'visible.';
      case MarigoldStageKey.stemElongation:
        return 'La planta define su altura y su forma antes de mostrar '
            'botones.';
      case MarigoldStageKey.budFormation:
        return 'Ya hay botones visibles: la planta entró en reproducción '
            'observable.';
      case MarigoldStageKey.flowering:
        return 'La ventana floral está activa. Puede haber botones y flores de '
            'distinta edad al mismo tiempo.';
      case MarigoldStageKey.postBloom:
        return 'La mayoría de las flores envejece y aparecen menos botones '
            'nuevos.';
      case MarigoldStageKey.senescence:
        return 'El secado gradual puede ser el cierre normal de una anual.';
      case MarigoldStageKey.cycleComplete:
        return 'Este Cempasúchil terminó su ciclo. Para cultivar otro, '
            'registra una nueva siembra.';
    }
  }
}
