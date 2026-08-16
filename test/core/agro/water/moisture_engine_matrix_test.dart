// test/core/agro/water/moisture_engine_matrix_test.dart
//
// La prueba de barrido: TODOS los cultivos × TODAS sus etapas × TODAS las
// texturas.
//
// ─────────────────────────────────────────────────────────────────────────────
// QUÉ CUBRE ESTA PRUEBA QUE NO CUBRÍAN LAS OTRAS
// ─────────────────────────────────────────────────────────────────────────────
//
// `soil_water_scale_test.dart` comprueba la aritmética con casos elegidos a
// mano. `stage_water_window_coverage_test.dart` comprueba que ninguna etapa se
// quede sin clasificar. Ninguna de las dos recorre el producto cartesiano, y es
// ahí donde viven los fallos que nadie elige a mano:
//
//   · una banda invertida en la única combinación donde el recorte de
//     `clamp` colapsa dos cotas (xerófita en secado sobre suelo arenoso);
//   · un umbral de encharcamiento por debajo de capacidad de campo;
//   · una etapa cuyo MAD ajustado se sale de [0,20 · 0,85] y vuelve el riego
//     imposible de satisfacer;
//   · un estado que desaparece del barrido —«cómodo» inalcanzable— y deja al
//     productor con la app diciendo «toca regar» para siempre.
//
// Son 2 114 combinaciones: 302 pares cultivo–etapa × 7 texturas. Tarda menos de
// dos segundos y es la red que hace que tocar una constante de textura, un MAD o
// una ventana no pueda romper en silencio un rincón del catálogo.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/water/crop_water_policy.dart';
import 'package:bio_g/core/agro/water/moisture_target_resolver.dart';
import 'package:bio_g/core/agro/water/soil_profile_resolver.dart';
import 'package:bio_g/core/agro/water/soil_texture_source.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/agro/water/stage_water_window.dart';
import 'package:bio_g/core/crops/crop_types.dart';

import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/widgets/seeds/barley_models.dart';
import 'package:bio_g/widgets/seeds/bean_models.dart';
import 'package:bio_g/widgets/seeds/chili_models.dart';
import 'package:bio_g/widgets/seeds/cucumber_models.dart';
import 'package:bio_g/widgets/seeds/eggplant_models.dart';
import 'package:bio_g/widgets/seeds/garlic_models.dart';
import 'package:bio_g/widgets/seeds/lettuce_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/oat_models.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';
import 'package:bio_g/widgets/seeds/spinach_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/squash_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

/// Las etapas REALES de cada cultivo, tomadas de la misma fuente que emite el
/// runtime. Si alguien añade una etapa al enum, esta prueba la recorre sola.
final Map<CropKey, List<String>> _stagesByCrop = <CropKey, List<String>>{
  CropKey.wheat: WheatStageKey.values.map((e) => e.name).toList(),
  CropKey.barley: BarleyStageKey.values.map((e) => e.name).toList(),
  CropKey.oat: OatStageKey.values.map((e) => e.name).toList(),
  CropKey.maize: MaizeStageKey.values.map((e) => e.name).toList(),
  CropKey.bean: BeanStageKey.values.map((e) => e.name).toList(),
  CropKey.tomato: TomatoStageKey.values.map((e) => e.name).toList(),
  CropKey.chili: ChiliStageKey.values.map((e) => e.name).toList(),
  CropKey.cucumber: CucumberStageKey.values.map((e) => e.name).toList(),
  CropKey.eggplant: EggplantStageKey.values.map((e) => e.name).toList(),
  CropKey.squash: SquashStageKey.values.map((e) => e.name).toList(),
  CropKey.lettuce: LettuceStageKey.values.map((e) => e.name).toList(),
  CropKey.spinach: SpinachStageKey.values.map((e) => e.name).toList(),
  CropKey.onion: OnionStageKey.values.map((e) => e.name).toList(),
  CropKey.garlic: GarlicStageKey.values.map((e) => e.name).toList(),
  // Ornamentales de reloj anual. El tulipán importa especialmente: es el único
  // cultivo con una excepción en `_byCrop` sobre `stem_elongation` —en tulipán
  // de corte el largo de tallo ES el producto— y sin él esa rama del código no
  // la recorría ninguna prueba.
  CropKey.tulip: TulipStageKey.values.map((e) => e.name).toList(),
  CropKey.sunflower: SunflowerStageKey.values.map((e) => e.name).toList(),
  CropKey.marigold: MarigoldStageKey.values.map((e) => e.name).toList(),
};

/// Los nueve frutales comparten el ciclo de `TreeStageIds`.
const List<CropKey> _trees = <CropKey>[
  CropKey.appleTree,
  CropKey.pearTree,
  CropKey.peachTree,
  CropKey.walnutTree,
  CropKey.pistachioTree,
  CropKey.orangeTree,
  CropKey.lemonTree,
  CropKey.mangoTree,
  CropKey.avocadoTree,
];

/// El ciclo de las xerófitas y del rosal, en snake_case como lo emiten sus
/// adaptadores. Se declaran aquí y no se leen del fuente porque son constantes
/// sueltas; `stage_water_window_coverage_test.dart` es quien vigila que la
/// lista de constantes esté completa.
const List<String> _xericStages = <String>[
  'installation_establishment',
  'root_establishment',
  'active_growth',
  'maintenance',
  'rest',
  'unknown',
];

/// El rosal es de floración recurrente: comparte el arraigo crítico de los
/// frutales pero tiene su propio ciclo de brotación y flor.
const List<String> _roseStages = <String>[
  'installation_establishment',
  'root_establishment',
  'vegetative_flush',
  'bud_formation',
  'flowering',
  'post_bloom_recovery',
  'rest',
  'unknown',
];

const List<SoilTexture> _mineral = <SoilTexture>[
  SoilTexture.sandy,
  SoilTexture.sandyLoam,
  SoilTexture.loam,
  SoilTexture.clayLoam,
  SoilTexture.clay,
];

const List<SoilTexture> _todas = <SoilTexture>[
  ..._mineral,
  SoilTexture.pottingMix,
  SoilTexture.pottingMixDraining,
];

Map<CropKey, List<String>> _matrix() {
  final out = Map<CropKey, List<String>>.of(_stagesByCrop);
  for (final t in _trees) {
    out[t] = <String>[
      TreeStageIds.plantingTransplant,
      TreeStageIds.rootEstablishment,
      TreeStageIds.juvenileVegetative,
      TreeStageIds.dormancy,
      TreeStageIds.budbreak,
      TreeStageIds.vegetativeGrowth,
      TreeStageIds.flowering,
      TreeStageIds.fruitSet,
      TreeStageIds.fruitFill,
      TreeStageIds.harvestMaturity,
      TreeStageIds.postHarvest,
      TreeStageIds.unknown,
    ];
  }
  for (final k in <CropKey>[
    CropKey.cactus,
    CropKey.nopal,
    CropKey.succulent,
    CropKey.aloe,
    CropKey.agave,
  ]) {
    out[k] = _xericStages;
  }
  out[CropKey.rose] = _roseStages;
  return out;
}

void main() {
  final matrix = _matrix();

  group('barrido cultivo × etapa × textura', () {
    test('la banda nunca se invierte y el encharcamiento siempre es alcanzable',
        () {
      final fallos = <String>[];
      var casos = 0;

      matrix.forEach((crop, stages) {
        for (final stage in stages) {
          for (final tex in _todas) {
            casos++;
            final r = MoistureTargetResolver.resolveForSoilProfile(
              soilProfile: ResolvedSoilProfile(
                texture: tex,
                source: SoilTextureSource.declared,
                isFallback: false,
                limitationsEs: const <String>[],
              ),
              cropKey: crop,
              stageKey: stage,
            );
            final b = r.range;
            final c = SoilWaterScale.constantsOf(tex);
            final donde = '${crop.name}/$stage/${tex.name}';

            if (!(b.lowMax <= b.optimalMin)) {
              fallos.add('$donde: lowMax ${b.lowMax} > optimalMin ${b.optimalMin}');
            }
            if (!(b.optimalMin <= b.optimalMax)) {
              fallos.add('$donde: optimalMin ${b.optimalMin} > optimalMax ${b.optimalMax}');
            }
            if (!(b.optimalMax <= b.highMin)) {
              fallos.add('$donde: optimalMax ${b.optimalMax} > highMin ${b.highMin}');
            }
            // El techo del óptimo ES capacidad de campo. Si deja de serlo, la
            // app estaría pidiendo regar por encima de lo que el suelo retiene.
            if ((b.optimalMax - c.fieldCapacityPct).abs() > 0.05) {
              fallos.add('$donde: optimalMax ${b.optimalMax} != θcc ${c.fieldCapacityPct}');
            }
            // La alarma de anoxia tiene que poder dispararse: ese era el bug
            // original —umbral en 90 % VWC, inalcanzable en suelo mineral—.
            if (b.highMin > c.saturationPct + 0.05) {
              fallos.add('$donde: highMin ${b.highMin} > saturación ${c.saturationPct}');
            }
            if (b.lowMax < c.wiltingPointPct - 0.05) {
              fallos.add('$donde: lowMax ${b.lowMax} < θpmp ${c.wiltingPointPct}');
            }
            // MAD ajustado por etapa dentro de los topes declarados.
            if (r.effectiveDepletion < 0.20 - 1e-9 ||
                r.effectiveDepletion > 0.85 + 1e-9) {
              fallos.add('$donde: MAD efectivo ${r.effectiveDepletion} fuera de [0,20 · 0,85]');
            }
          }
        }
      });

      // 302 pares cultivo–etapa × 7 texturas = 2 114. El umbral es un canario:
      // si alguien borra un catálogo de etapas, la matriz encoge y esto falla
      // antes de que el barrido pase «por vacío».
      expect(casos, greaterThan(1900),
          reason: 'La matriz encogió: alguien quitó un catálogo de etapas.');
      expect(fallos, isEmpty,
          reason: 'Bandas inválidas:\n  ${fallos.take(25).join('\n  ')}');
    });

    test('los cinco estados aparecen en orden y ninguno es inalcanzable', () {
      final fallos = <String>[];

      matrix.forEach((crop, stages) {
        for (final stage in stages) {
          for (final tex in _todas) {
            final r = MoistureTargetResolver.resolveForSoilProfile(
              soilProfile: ResolvedSoilProfile(
                texture: tex,
                source: SoilTextureSource.declared,
                isFallback: false,
                limitationsEs: const <String>[],
              ),
              cropKey: crop,
              stageKey: stage,
            );
            final donde = '${crop.name}/$stage/${tex.name}';

            final vistos = <SoilMoistureState>{};
            SoilMoistureState? previo;
            final orden = <SoilMoistureState>[];
            for (var i = 0; i <= 1000; i++) {
              final s = r.stateFor(i / 10.0);
              vistos.add(s);
              if (s != previo) {
                orden.add(s);
                previo = s;
              }
            }

            // Subiendo la humedad, el estado solo puede ir en un sentido.
            const esperado = <SoilMoistureState>[
              SoilMoistureState.belowWiltingPoint,
              SoilMoistureState.timeToIrrigate,
              SoilMoistureState.comfortable,
              SoilMoistureState.draining,
              SoilMoistureState.waterlogged,
            ];
            var cursor = 0;
            for (final s in orden) {
              final i = esperado.indexOf(s);
              if (i < cursor) {
                fallos.add('$donde: el estado retrocede a ${s.name} · $orden');
                break;
              }
              cursor = i;
            }

            if (!vistos.contains(SoilMoistureState.waterlogged)) {
              fallos.add('$donde: «encharcado» inalcanzable');
            }
            if (!vistos.contains(SoilMoistureState.comfortable)) {
              fallos.add('$donde: «cómodo» inalcanzable — regaría siempre');
            }
            if (!vistos.contains(SoilMoistureState.draining)) {
              fallos.add('$donde: «drenando» inalcanzable — llamaría anoxia a un riego normal');
            }
          }
        }
      });

      expect(fallos, isEmpty,
          reason: 'Estados inconsistentes:\n  ${fallos.take(25).join('\n  ')}');
    });

    test('toda etapa de la matriz declara ventana hídrica', () {
      final sin = <String>[];
      matrix.forEach((crop, stages) {
        for (final s in stages) {
          if (StageWaterWindows.lookup(s, cropKey: crop) == null) {
            sin.add('${crop.name}.$s');
          }
        }
      });
      expect(sin, isEmpty, reason: 'Sin ventana declarada: ${sin.join(', ')}');
    });

    test('la ventana crítica aprieta y la de secado afloja, siempre', () {
      // No basta con que las ventanas existan: tienen que MOVER el número en
      // la dirección correcta. Una ventana declarada que no cambia nada es
      // exactamente el fallo silencioso que este módulo vino a cerrar.
      matrix.forEach((crop, stages) {
        final base = CropWaterPolicies.forCrop(crop).allowableDepletion;
        for (final s in stages) {
          final w = StageWaterWindows.lookup(s, cropKey: crop);
          final mad = CropWaterPolicies.allowableDepletionForStage(
            CropWaterPolicies.forCrop(crop),
            s,
            cropKey: crop,
          );
          switch (w) {
            case WaterWindow.critical:
              expect(mad, lessThan(base),
                  reason: '${crop.name}.$s es crítica y no aprieta el riego');
            case WaterWindow.drying:
              expect(mad, greaterThan(base),
                  reason: '${crop.name}.$s es de secado y no lo afloja');
            case WaterWindow.normal:
              expect(mad, base,
                  reason: '${crop.name}.$s es normal y sin embargo se ajusta');
            case null:
              fail('${crop.name}.$s sin ventana');
          }
        }
      });
    });

    test('la lámina sale en banda en todo el catálogo, nunca como cifra cerrada',
        () {
      // ±3 puntos de exactitud sobre cualquier profundidad radicular dan
      // siempre ≥ 12 % de la lámina, así que `needsBand` tiene que ser true en
      // todos los cultivos. Si alguna vez deja de serlo, es que alguien tocó la
      // propagación de incertidumbre.
      for (final crop in matrix.keys) {
        final r = MoistureTargetResolver.resolveForSoilProfile(
          soilProfile: const ResolvedSoilProfile(
            texture: SoilTexture.loam,
            source: SoilTextureSource.declared,
            isFallback: false,
            limitationsEs: <String>[],
          ),
          cropKey: crop,
        );
        final d = MoistureTargetResolver.depthFor(vwcPct: 18, target: r);
        expect(d, isNotNull, reason: '${crop.name}: sin lámina a 18 % en franco');
        expect(d!.needsBand, isTrue,
            reason: '${crop.name}: la lámina saldría como cifra cerrada');
        expect(d.bandEs(), contains('entre'));
        expect(d.lowMm, greaterThanOrEqualTo(0));
      }
    });

    test('por encima de capacidad de campo NO hay lámina que aplicar', () {
      for (final tex in _mineral) {
        final r = MoistureTargetResolver.resolveForSoilProfile(
          soilProfile: ResolvedSoilProfile(
            texture: tex,
            source: SoilTextureSource.declared,
            isFallback: false,
            limitationsEs: const <String>[],
          ),
          cropKey: CropKey.tomato,
        );
        final cc = SoilWaterScale.constantsOf(tex).fieldCapacityPct;
        expect(MoistureTargetResolver.depthFor(vwcPct: cc, target: r), isNull,
            reason: '${tex.name}: inventa lámina justo a capacidad de campo');
        expect(MoistureTargetResolver.depthFor(vwcPct: cc + 2, target: r), isNull,
            reason: '${tex.name}: inventa lámina por encima de θcc');
      }
    });

    test('el sustrato drenante solo lo reciben las xerófitas, y sin preguntar',
        () {
      for (final crop in <CropKey>[
        CropKey.cactus,
        CropKey.nopal,
        CropKey.agave,
        CropKey.succulent,
      ]) {
        final p = SoilProfileResolver.resolve(
          deviceModelId: 'maceta',
          soilTextureId: 'clay', // el productor dijo arcilla: da igual
          cropKey: crop,
        );
        expect(p.texture, SoilTexture.pottingMixDraining,
            reason: '${crop.name} en maceta debería ir a sustrato drenante');
        expect(p.isFallback, isFalse);
      }
      // La sábila NO es xerófita en la política hídrica, a propósito.
      expect(
        SoilProfileResolver.resolve(deviceModelId: 'maceta', cropKey: CropKey.aloe)
            .texture,
        SoilTexture.pottingMix,
      );
      // Y un equipo de huerto manda sobre la escala declarada.
      expect(
        SoilProfileResolver.resolve(
          deviceModelId: 'huerto',
          cultivationScaleId: 'pot',
          soilTextureId: 'sandy',
          cropKey: CropKey.cactus,
        ).texture,
        SoilTexture.sandy,
      );
    });
  });
}
