// lib/widgets/seeds/tulip_engine.dart
//
// Motor fenológico puro del Tulipán. Mantiene el MISMO patrón que
// oat/bean/garlic (fecha ancla → día → ventanas por perfil → etapa →
// días al próximo hito), con la biología del bulbo al final:
//
//   - cuando el día supera todas las ventanas, conserva la ÚLTIMA etapa
//     (`dormancy`) indefinidamente — igual que el Frijol conserva `harvest`,
//     pero SIN cerrar el registro (Documento A §2.2, §5.11);
//   - `stageProgressPct` es null en dormancia (no hay final universal);
//   - `expectedDaysToEnd` cuenta días al PRÓXIMO hito de la temporada, no a
//     una cosecha (Documento A §13).
//
// El calendario de cada temporada vive en el `TulipProfile` (límites de fin
// de etapa). El modo de establecimiento (plantación / preenfriado / ya
// brotado) queda representado por el calendario por defecto de cada perfil:
// el perfil forzado de interior usa una ventana abreviada porque el bulbo ya
// recibió frío (Documento A §10.5), sin recorrer 12–16 semanas ficticias.

import 'dart:math' as math;

import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';

class TulipEngine {
  TulipEngine._();

  /// Sentinela lógico para el "final" abierto de la dormancia.
  static const int _dormancyOpenEnd = 100000;

  static TulipStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required TulipProfile profile,
    int stressDelayDays = 0,
  }) {
    final daySinceAnchor = math.max(1, today.difference(sowingDate).inDays + 1);

    // Semántica explícita (Documento A §12.1): un retraso fisiológico NO puede
    // empujar a la planta hacia una etapa más avanzada. Un `stressDelayDays`
    // positivo RETARDA el desarrollo (se resta), a diferencia de algunos
    // motores legacy que lo sumaban. El runtime pasa 0 en el flujo normal.
    final effectiveDay = math.max(1, daySinceAnchor - stressDelayDays);

    final bounds = _bounds(profile);
    final currentBounds = bounds.firstWhere(
      (b) => b.contains(effectiveDay),
      orElse: () => bounds.last,
    );
    final stage = currentBounds.key;

    final double? stageProgressPct;
    if (stage == TulipStageKey.dormancy) {
      // En dormancia no existe un final universal: barra oculta (null).
      stageProgressPct = null;
    } else {
      final span = math.max(1, currentBounds.endDay - currentBounds.startDay + 1);
      stageProgressPct = ((effectiveDay - currentBounds.startDay + 1) / span)
          .clamp(0.0, 1.0);
    }

    final expectedDaysToEnd = _daysToNextMilestone(profile, stage, effectiveDay);

    return TulipStageResult(
      profile: profile,
      stage: stage,
      daySinceAnchor: daySinceAnchor,
      establishmentMode: profile.defaultEstablishmentMode,
      floweringWindow: profile.floweringWindowDays,
      expectedFloweringDay: profile.floweringWindowDays.mid,
      expectedDormancyStartDay: profile.dormancyStartDay,
      expectedDaysToEnd: expectedDaysToEnd,
      stageProgressPct: stageProgressPct,
      windowsNow: _windows(stage),
      stageId: tulipStageIdFor(stage),
      stageLabelEs: tulipStageDisplayName(tulipStageIdFor(stage)),
      heroAsset: _heroAsset(stage),
      helperCaption: _helperCaption(stage),
    );
  }

  /// Construye las ventanas ordenadas desde los límites de fin del perfil.
  /// Cada `math.max` evita traslapes inválidos si el perfil trae bandas muy
  /// comprimidas (perfiles preenfriados).
  static List<TulipStageBounds> _bounds(TulipProfile p) {
    final plantingEnd = math.max(1, p.plantingEndDay);
    final rootingStart = plantingEnd + 1;
    final rootingEnd = math.max(rootingStart, p.rootingChillingEndDay);
    final emergenceStart = rootingEnd + 1;
    final emergenceEnd = math.max(emergenceStart, p.emergenceEndDay);
    final vegStart = emergenceEnd + 1;
    final vegEnd = math.max(vegStart, p.vegetativeEndDay);
    final elongStart = vegEnd + 1;
    final elongEnd = math.max(elongStart, p.stemElongationEndDay);
    final budStart = elongEnd + 1;
    final budEnd = math.max(budStart, p.budEndDay);
    final flowerStart = budEnd + 1;
    final flowerEnd = math.max(flowerStart, p.floweringEndDay);
    final rechargeStart = flowerEnd + 1;
    final rechargeEnd = math.max(rechargeStart, p.rechargeEndDay);
    final senescenceStart = rechargeEnd + 1;
    final senescenceEnd = math.max(senescenceStart, p.senescenceEndDay);
    final dormancyStart = senescenceEnd + 1;

    return <TulipStageBounds>[
      TulipStageBounds(
        key: TulipStageKey.bulbPlanting,
        startDay: 1,
        endDay: plantingEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.rootingChilling,
        startDay: rootingStart,
        endDay: rootingEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.shootEmergence,
        startDay: emergenceStart,
        endDay: emergenceEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.vegetativeGrowth,
        startDay: vegStart,
        endDay: vegEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.stemElongation,
        startDay: elongStart,
        endDay: elongEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.budFormation,
        startDay: budStart,
        endDay: budEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.flowering,
        startDay: flowerStart,
        endDay: flowerEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.bulbRecharge,
        startDay: rechargeStart,
        endDay: rechargeEnd,
      ),
      TulipStageBounds(
        key: TulipStageKey.foliageSenescence,
        startDay: senescenceStart,
        endDay: senescenceEnd,
      ),
      // Dormancia: final abierto. Es la propiedad del motor de granos que
      // aprovechamos — cuando el día excede las ventanas, se conserva la
      // última etapa (Documento A §5.11).
      TulipStageBounds(
        key: TulipStageKey.dormancy,
        startDay: dormancyStart,
        endDay: _dormancyOpenEnd,
      ),
    ];
  }

  /// Días aproximados al PRÓXIMO hito de la temporada (Documento A §13):
  /// - antes de floración → a que empiece la floración;
  /// - floración → días restantes de la ventana de floración;
  /// - recarga → a que empiece la senescencia;
  /// - senescencia → a que empiece la dormancia;
  /// - dormancia → 0.
  static int _daysToNextMilestone(
    TulipProfile p,
    TulipStageKey stage,
    int effectiveDay,
  ) {
    switch (stage) {
      case TulipStageKey.bulbPlanting:
      case TulipStageKey.rootingChilling:
      case TulipStageKey.shootEmergence:
      case TulipStageKey.vegetativeGrowth:
      case TulipStageKey.stemElongation:
      case TulipStageKey.budFormation:
        return math.max(0, p.floweringStartDay - effectiveDay);
      case TulipStageKey.flowering:
        return math.max(0, p.floweringEndDay - effectiveDay);
      case TulipStageKey.bulbRecharge:
        return math.max(0, p.rechargeEndDay + 1 - effectiveDay);
      case TulipStageKey.foliageSenescence:
        return math.max(0, p.dormancyStartDay - effectiveDay);
      case TulipStageKey.dormancy:
        return 0;
    }
  }

  static List<SeedWindowKey> _windows(TulipStageKey stage) {
    // Ventanas operativas por etapa (Documento A §14). La ventana crítica del
    // enraizado/frío representa FRÍO y DRENAJE, no NPK. El NPK pierde peso en
    // senescencia y dormancia.
    switch (stage) {
      case TulipStageKey.bulbPlanting:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
        ];
      case TulipStageKey.rootingChilling:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case TulipStageKey.shootEmergence:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
        ];
      case TulipStageKey.vegetativeGrowth:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
        ];
      case TulipStageKey.stemElongation:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case TulipStageKey.budFormation:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case TulipStageKey.flowering:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case TulipStageKey.bulbRecharge:
        return const <SeedWindowKey>[
          SeedWindowKey.irrigation,
          SeedWindowKey.nutrition,
          SeedWindowKey.scouting,
          SeedWindowKey.critical,
        ];
      case TulipStageKey.foliageSenescence:
        return const <SeedWindowKey>[SeedWindowKey.scouting];
      case TulipStageKey.dormancy:
        return const <SeedWindowKey>[SeedWindowKey.scouting];
    }
  }

  /// Imagen fenológica por etapa. Las rutas se inlinean aquí (patrón oat) y
  /// coinciden EXACTAMENTE con `assets/seeds/Tulipan/` en disco. `TulipAssets`
  /// espeja estas mismas rutas para las capas de presentación y sanidad.
  static String _heroAsset(TulipStageKey stage) {
    const dir = 'assets/seeds/Tulipan';
    switch (stage) {
      case TulipStageKey.bulbPlanting:
        return '$dir/tulip_stage_bulb_planting.png';
      case TulipStageKey.rootingChilling:
        return '$dir/tulip_stage_rooting_chilling.png';
      case TulipStageKey.shootEmergence:
        return '$dir/tulip_stage_shoot_emergence.png';
      case TulipStageKey.vegetativeGrowth:
        return '$dir/tulip_stage_vegetative_growth.png';
      case TulipStageKey.stemElongation:
        return '$dir/tulip_stage_stem_elongation.png';
      case TulipStageKey.budFormation:
        return '$dir/tulip_stage_bud_formation.png';
      case TulipStageKey.flowering:
        return '$dir/tulip_stage_flowering.png';
      case TulipStageKey.bulbRecharge:
        return '$dir/tulip_stage_bulb_recharge.png';
      case TulipStageKey.foliageSenescence:
        return '$dir/tulip_stage_foliage_senescence.png';
      case TulipStageKey.dormancy:
        return '$dir/tulip_stage_dormancy.png';
    }
  }

  /// Nota corta por etapa, en lenguaje de agricultor (Documento A §19).
  /// Explica explícitamente la recarga (la flor terminó pero las hojas siguen
  /// alimentando el bulbo), la senescencia (amarillamiento normal) y la
  /// dormancia (el bulbo sigue vivo).
  static String _helperCaption(TulipStageKey stage) {
    switch (stage) {
      case TulipStageKey.bulbPlanting:
        return 'El bulbo acaba de instalarse. Mantén el sustrato con humedad '
            'moderada y revisa que el agua salga bien.';
      case TulipStageKey.rootingChilling:
        return 'El crecimiento puede seguir bajo tierra. El frío y un buen '
            'drenaje son más importantes que fertilizar fuerte.';
      case TulipStageKey.shootEmergence:
        return 'El brote empieza a salir. Evita cambios bruscos de humedad y '
            'calor.';
      case TulipStageKey.vegetativeGrowth:
        return 'Las hojas están construyendo energía para el tallo y la flor.';
      case TulipStageKey.stemElongation:
        return 'La temperatura y la luz influyen mucho en la firmeza y '
            'longitud del tallo.';
      case TulipStageKey.budFormation:
        return 'El botón está cerca de abrir. Evita que el sustrato se seque '
            'por completo o quede encharcado.';
      case TulipStageKey.flowering:
        return 'La flor está en su ventana principal. Un ambiente fresco ayuda '
            'a que dure más.';
      case TulipStageKey.bulbRecharge:
        return 'La flor terminó, pero las hojas todavía alimentan al bulbo. No '
            'las cortes mientras sigan verdes.';
      case TulipStageKey.foliageSenescence:
        return 'El follaje está cerrando su temporada. El amarillamiento '
            'gradual puede ser normal; reduce el agua conforme se seca.';
      case TulipStageKey.dormancy:
        return 'No hay parte aérea visible. El bulbo puede seguir vivo bajo '
            'tierra o almacenado; el cultivo sigue registrado.';
    }
  }
}
