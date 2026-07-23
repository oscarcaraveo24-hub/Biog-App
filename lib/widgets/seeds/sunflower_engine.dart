// lib/widgets/seeds/sunflower_engine.dart
//
// Motor fenológico puro del Girasol. Mantiene el MISMO patrón que
// oat/bean/tulip (fecha ancla → día → ventanas por perfil → etapa → progreso →
// días al fin del ciclo), con la biología del ANUAL VERDADERO al final:
//
//   - cuando el día supera todas las ventanas, conserva la ÚLTIMA etapa
//     (`cycle_complete`) indefinidamente — igual que el Frijol conserva
//     `harvest` y el Tulipán conserva `dormancy` — pero es TERMINAL: no hay
//     recarga, no hay reposo, no hay bulbo que sobreviva (Documento A §8, §11);
//   - en `cycle_complete`, `stageProgressPct = 1.0` y `expectedDaysToEnd = 0`
//     (Documento A §11.9, §11.10) — a diferencia del Tulipán, cuyo progreso es
//     null en dormancia;
//   - una fecha antigua (muy posterior al fin de la ventana) resuelve a
//     `cycle_complete`, NUNCA a `unknown` (Documento A §9.8).
//
// El calendario de cada temporada vive en el `SunflowerProfile` (límites de fin
// de etapa). El motor NO usa lecturas de sensores para cambiar la etapa: la
// fecha manda (Documento A §0.4, §9.10). En v1 `stressDelayDays` es 0.

import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';

class SunflowerEngine {
  SunflowerEngine._();

  /// Sentinela lógico para el final abierto de la etapa terminal.
  static const int _cycleCompleteOpenEnd = 100000;

  /// Carpeta de assets fenológicos EN DISCO (Documento A §15.1). Respeta la
  /// capitalización real del repositorio: `assets/seeds/Sunflower` (S mayúscula,
  /// nombre en inglés). `SunflowerAssets` espeja estas mismas rutas.
  static const String _stageDir = 'assets/seeds/Sunflower';

  static SunflowerStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required SunflowerProfile profile,
    int stressDelayDays = 0,
  }) {
    final daySinceAnchor = math.max(1, today.difference(sowingDate).inDays + 1);

    // Un retraso fisiológico NO puede empujar a una etapa más avanzada: un
    // `stressDelayDays` positivo RETARDA el desarrollo (se resta). En v1 el
    // runtime pasa 0 (Documento A §9.10).
    final effectiveDay = math.max(1, daySinceAnchor - stressDelayDays);

    final bounds = _bounds(profile);
    final currentBounds = bounds.firstWhere(
      (b) => b.contains(effectiveDay),
      orElse: () => bounds.last,
    );
    final stage = currentBounds.key;

    final double stageProgressPct;
    final int expectedDaysToEnd;
    if (stage == SunflowerStageKey.cycleComplete) {
      // Terminal: el ciclo anual terminó (Documento A §11.9, §11.10).
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

    return SunflowerStageResult(
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
      stageId: sunflowerStageIdFor(stage),
      stageLabelEs: sunflowerStageDisplayName(sunflowerStageIdFor(stage)),
      heroAsset: _heroAsset(stage),
      helperCaption: _helperCaption(stage),
    );
  }

  /// Construye las ventanas ordenadas desde los límites de fin del perfil. Cada
  /// `math.max` evita traslapes inválidos. `sowing` ocupa el día 1 (el día de la
  /// siembra); las etapas siguientes conservan las fronteras nominales del
  /// Documento A §11. `cycle_complete` es la etapa terminal de final abierto.
  static List<SunflowerStageBounds> _bounds(SunflowerProfile p) {
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

    return <SunflowerStageBounds>[
      SunflowerStageBounds(
        key: SunflowerStageKey.sowing,
        startDay: 1,
        endDay: sowingEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.germination,
        startDay: germStart,
        endDay: germEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.emergence,
        startDay: emergStart,
        endDay: emergEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.earlyVegetativeGrowth,
        startDay: earlyVegStart,
        endDay: earlyVegEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.activeVegetativeGrowth,
        startDay: activeVegStart,
        endDay: activeVegEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.stemElongation,
        startDay: stemStart,
        endDay: stemEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.budFormation,
        startDay: budStart,
        endDay: budEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.flowering,
        startDay: flowerStart,
        endDay: flowerEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.postBloom,
        startDay: postBloomStart,
        endDay: postBloomEnd,
      ),
      SunflowerStageBounds(
        key: SunflowerStageKey.senescence,
        startDay: senescenceStart,
        endDay: senescenceEnd,
      ),
      // `cycle_complete`: TERMINAL de final abierto. Cuando el día excede las
      // ventanas se conserva esta etapa (Documento A §8.4, §9.8).
      SunflowerStageBounds(
        key: SunflowerStageKey.cycleComplete,
        startDay: cycleStart,
        endDay: _cycleCompleteOpenEnd,
      ),
    ];
  }

  static List<SeedWindowKey> _windows(SunflowerStageKey stage) {
    // Ventanas operativas por etapa. La nutrición pesa en el crecimiento activo
    // y el alargamiento (N/K); la ventana crítica cubre germinación, emergencia,
    // botón y floración (Documento B §13.1). En `cycle_complete` solo queda
    // scouting: no hay manejo activo (Documento B §0.2 regla 11).
    switch (stage) {
      case SunflowerStageKey.sowing:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
        ];
      case SunflowerStageKey.germination:
      case SunflowerStageKey.emergence:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case SunflowerStageKey.earlyVegetativeGrowth:
      case SunflowerStageKey.activeVegetativeGrowth:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
        ];
      case SunflowerStageKey.stemElongation:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case SunflowerStageKey.budFormation:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case SunflowerStageKey.flowering:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case SunflowerStageKey.postBloom:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
        ];
      case SunflowerStageKey.senescence:
      case SunflowerStageKey.cycleComplete:
        return const <SeedWindowKey>[SeedWindowKey.scouting];
    }
  }

  /// Imagen fenológica por etapa. Las rutas se inlinean aquí (patrón oat/tulip)
  /// y coinciden EXACTAMENTE con `assets/seeds/Sunflower/` en disco.
  static String _heroAsset(SunflowerStageKey stage) {
    switch (stage) {
      case SunflowerStageKey.sowing:
        return '$_stageDir/sunflower_stage_sowing.png';
      case SunflowerStageKey.germination:
        return '$_stageDir/sunflower_stage_germination.png';
      case SunflowerStageKey.emergence:
        return '$_stageDir/sunflower_stage_emergence.png';
      case SunflowerStageKey.earlyVegetativeGrowth:
        return '$_stageDir/sunflower_stage_early_vegetative_growth.png';
      case SunflowerStageKey.activeVegetativeGrowth:
        return '$_stageDir/sunflower_stage_active_vegetative_growth.png';
      case SunflowerStageKey.stemElongation:
        return '$_stageDir/sunflower_stage_stem_elongation.png';
      case SunflowerStageKey.budFormation:
        return '$_stageDir/sunflower_stage_bud_formation.png';
      case SunflowerStageKey.flowering:
        return '$_stageDir/sunflower_stage_flowering.png';
      case SunflowerStageKey.postBloom:
        return '$_stageDir/sunflower_stage_post_bloom.png';
      case SunflowerStageKey.senescence:
        return '$_stageDir/sunflower_stage_senescence.png';
      case SunflowerStageKey.cycleComplete:
        return '$_stageDir/sunflower_stage_cycle_complete.png';
    }
  }

  /// Nota corta por etapa, en lenguaje de jardinero (Documento A §14.2).
  static String _helperCaption(SunflowerStageKey stage) {
    switch (stage) {
      case SunflowerStageKey.sowing:
        return 'La fecha de siembra iniciará el reloj anual de tu Girasol.';
      case SunflowerStageKey.germination:
        return 'La semilla está iniciando su desarrollo bajo el suelo.';
      case SunflowerStageKey.emergence:
        return 'El brote comienza a salir y todavía es muy frágil.';
      case SunflowerStageKey.earlyVegetativeGrowth:
        return 'La planta está formando sus primeras hojas verdaderas.';
      case SunflowerStageKey.activeVegetativeGrowth:
        return 'El follaje y las raíces están creciendo con rapidez.';
      case SunflowerStageKey.stemElongation:
        return 'El tallo gana altura antes de mostrar el botón floral.';
      case SunflowerStageKey.budFormation:
        return 'El capítulo floral ya se está formando en la punta.';
      case SunflowerStageKey.flowering:
        return 'La flor está abierta o en su mejor periodo ornamental.';
      case SunflowerStageKey.postBloom:
        return 'La flor está envejeciendo, aunque parte de la planta todavía '
            'puede seguir verde.';
      case SunflowerStageKey.senescence:
        return 'El secado gradual puede ser normal al final de un Girasol '
            'anual.';
      case SunflowerStageKey.cycleComplete:
        return 'Este Girasol terminó su ciclo. Una nueva planta requiere una '
            'nueva siembra.';
    }
  }
}
