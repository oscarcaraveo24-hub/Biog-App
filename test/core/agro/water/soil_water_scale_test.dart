// test/core/agro/water/soil_water_scale_test.dart
//
// Fija el contrato de unidad de humedad. Si alguien vuelve a escribir un
// objetivo de humedad a mano contra una escala inventada, estas pruebas lo
// cazan antes de que llegue a un agricultor.

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/water/crop_water_policy.dart';
import 'package:bio_g/core/agro/water/moisture_target_resolver.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/widgets/seeds/garlic_models.dart';
import 'package:bio_g/widgets/seeds/maize_models.dart';
import 'package:bio_g/widgets/seeds/onion_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

void main() {
  group('SoilWaterScale · constantes hídricas', () {
    test('el orden físico se respeta en todas las texturas', () {
      for (final t in SoilTexture.values) {
        if (t == SoilTexture.unknown) continue;
        final c = SoilWaterScale.constantsOf(t);
        expect(
          c.wiltingPointPct,
          lessThan(c.fieldCapacityPct),
          reason: '$t: el punto de marchitez debe estar por debajo de la '
              'capacidad de campo',
        );
        expect(
          c.fieldCapacityPct,
          lessThan(c.saturationPct),
          reason: '$t: la capacidad de campo debe estar por debajo de la '
              'saturación',
        );
        expect(c.availableWaterPct, greaterThan(0));
      }
    });

    test('la saturación de suelo mineral nunca supera 55 % VWC', () {
      // Es porosidad total. Un umbral de encharcamiento por encima de esto
      // sería inalcanzable, que es exactamente el bug que motivó este archivo.
      const mineral = [
        SoilTexture.sandy,
        SoilTexture.sandyLoam,
        SoilTexture.loam,
        SoilTexture.clayLoam,
        SoilTexture.clay,
      ];
      for (final t in mineral) {
        expect(SoilWaterScale.constantsOf(t).saturationPct, lessThanOrEqualTo(55));
      }
    });

    test('el sustrato de maceta retiene mucho más que cualquier suelo', () {
      // Esto protege el trabajo de ornamentales: sus números eran correctos
      // para maceta y solo estaban mal aplicados a suelo.
      expect(
        SoilWaterScale.constantsOf(SoilTexture.pottingMix).fieldCapacityPct,
        greaterThan(SoilWaterScale.constantsOf(SoilTexture.clay).saturationPct),
      );
    });
  });

  group('SoilWaterScale · agua disponible y agotamiento', () {
    test('capacidad de campo es 100 % de agua disponible', () {
      final c = SoilWaterScale.constantsOf(SoilTexture.loam);
      expect(
        SoilWaterScale.availableWater01(c.fieldCapacityPct, SoilTexture.loam),
        closeTo(1.0, 1e-9),
      );
      expect(
        SoilWaterScale.depletionPct(c.fieldCapacityPct, SoilTexture.loam),
        closeTo(0.0, 1e-9),
      );
    });

    test('punto de marchitez es 0 % de agua disponible', () {
      final c = SoilWaterScale.constantsOf(SoilTexture.loam);
      expect(
        SoilWaterScale.availableWater01(c.wiltingPointPct, SoilTexture.loam),
        closeTo(0.0, 1e-9),
      );
      expect(
        SoilWaterScale.depletionPct(c.wiltingPointPct, SoilTexture.loam),
        closeTo(100.0, 1e-9),
      );
    });

    test('por encima de capacidad de campo no hay más agua DISPONIBLE', () {
      // El exceso está drenando, no está disponible. Recortar aquí evita que
      // un suelo encharcado se lea como "de sobra bien regado".
      expect(SoilWaterScale.availableWater01(46, SoilTexture.loam), 1.0);
    });

    test('el mismo VWC significa cosas distintas según la textura', () {
      // Este es el corazón del asunto: 20 % VWC es un suelo arenoso encharcado
      // y un suelo arcilloso por debajo del punto de marchitez.
      final arena = SoilWaterScale.availableWater01(20, SoilTexture.sandy);
      final arcilla = SoilWaterScale.availableWater01(20, SoilTexture.clay);
      expect(arena, 1.0);
      expect(arcilla, 0.0);
    });
  });

  group('SoilWaterScale · encharcamiento', () {
    test('la alarma es alcanzable en todas las texturas', () {
      for (final t in SoilTexture.values) {
        if (t == SoilTexture.unknown) continue;
        final c = SoilWaterScale.constantsOf(t);
        final umbral = SoilWaterScale.waterloggingThresholdPct(t);
        expect(
          umbral,
          lessThan(c.saturationPct),
          reason: '$t: el umbral debe estar por debajo de la saturación o '
              'nunca se dispara',
        );
        expect(
          umbral,
          greaterThan(c.fieldCapacityPct),
          reason: '$t: el umbral debe estar por encima de capacidad de campo '
              'o daría falsas alarmas tras cada riego',
        );
        expect(
          umbral,
          lessThanOrEqualTo(80),
          reason: 'Ningún sensor real reporta por encima de esto en suelo. '
              'El bug original tenía umbrales de 88 a 100.',
        );
      }
    });

    test('un suelo franco encharcado dispara la alarma', () {
      // 46 % VWC en franco es agua ocupando casi toda la porosidad.
      expect(SoilWaterScale.isWaterlogged(46, SoilTexture.loam), isTrue);
      // Y a capacidad de campo, no.
      expect(SoilWaterScale.isWaterlogged(28, SoilTexture.loam), isFalse);
    });
  });

  group('SoilWaterScale · lámina de riego', () {
    test('la aritmética coincide con el cálculo a mano', () {
      // Franco (cc 28) leyendo 20, raíz de 40 cm:
      //   (0.28 − 0.20) × 400 mm = 32 mm
      final mm = SoilWaterScale.netIrrigationDepthMm(
        vwcPct: 20,
        texture: SoilTexture.loam,
        rootDepthCm: 40,
      );
      expect(mm, closeTo(32.0, 1e-9));
    });

    test('1 mm es exactamente 1 litro por metro cuadrado', () {
      expect(SoilWaterScale.litersPerSquareMeter(32), 32);
      expect(SoilWaterScale.cubicMetersPerHectare(32), 320);
    });

    test('no inventa lámina cuando el suelo ya está lleno', () {
      expect(
        SoilWaterScale.netIrrigationDepthMm(
          vwcPct: 30,
          texture: SoilTexture.loam,
          rootDepthCm: 40,
        ),
        isNull,
      );
    });

    test('no inventa lámina sin profundidad radicular', () {
      expect(
        SoilWaterScale.netIrrigationDepthMm(
          vwcPct: 20,
          texture: SoilTexture.loam,
          rootDepthCm: null,
        ),
        isNull,
      );
    });

    test('la lámina bruta siempre es mayor o igual que la neta', () {
      final neta = SoilWaterScale.netIrrigationDepthMm(
        vwcPct: 20,
        texture: SoilTexture.loam,
        rootDepthCm: 40,
      )!;
      for (final s in IrrigationSystem.values) {
        final bruta = SoilWaterScale.grossIrrigationDepthMm(
          vwcPct: 20,
          texture: SoilTexture.loam,
          rootDepthCm: 40,
          systemEfficiency01: s.efficiency01,
        )!;
        expect(bruta, greaterThanOrEqualTo(neta), reason: '$s');
      }
    });
  });

  group('MoistureTargetResolver · bandas derivadas', () {
    test('las bandas salen ordenadas para todo cultivo y toda textura', () {
      for (final crop in CropKey.values) {
        for (final tex in SoilTexture.values) {
          final r = MoistureTargetResolver.resolve(
            cropKey: crop,
            texture: tex,
          );
          expect(
            r.range.lowMax,
            lessThanOrEqualTo(r.range.optimalMin),
            reason: '$crop / $tex',
          );
          expect(
            r.range.optimalMin,
            lessThanOrEqualTo(r.range.optimalMax),
            reason: '$crop / $tex',
          );
          expect(
            r.range.optimalMax,
            lessThanOrEqualTo(r.range.highMin),
            reason: '$crop / $tex',
          );
        }
      }
    });

    test('EL BUG ORIGINAL: capacidad de campo ya no es crítico bajo', () {
      // Un huerto de manzano en franco, regado a la perfección, lee 28 % VWC.
      // Con los rangos escritos a mano (45/60/80/90) eso era CRÍTICO BAJO.
      final r = MoistureTargetResolver.resolve(
        cropKey: CropKey.appleTree,
        texture: SoilTexture.loam,
      );
      const capacidadDeCampo = 28.0;
      expect(capacidadDeCampo, greaterThanOrEqualTo(r.range.optimalMin));
      expect(capacidadDeCampo, lessThanOrEqualTo(r.range.optimalMax));
    });

    test('EL OTRO BUG: un suelo encharcado ya no sale "bajo"', () {
      final r = MoistureTargetResolver.resolve(
        cropKey: CropKey.avocadoTree,
        texture: SoilTexture.loam,
      );
      // 46 % VWC en franco es asfixia radicular. Antes salía BAJO y la app
      // pedía regar más; ahora tiene que caer en saturado.
      expect(46.0, greaterThanOrEqualTo(r.range.highMin));
    });

    test('la lechuga exige más agua que el maíz en el mismo suelo', () {
      final lechuga = MoistureTargetResolver.resolve(
        cropKey: CropKey.lettuce,
        texture: SoilTexture.loam,
      );
      final maiz = MoistureTargetResolver.resolve(
        cropKey: CropKey.maize,
        texture: SoilTexture.loam,
      );
      expect(lechuga.range.optimalMin, greaterThan(maiz.range.optimalMin));
    });

    test('el mismo cultivo pide números distintos según la tierra', () {
      final arena = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.sandy,
      );
      final arcilla = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.clay,
      );
      expect(arcilla.range.optimalMin, greaterThan(arena.range.optimalMin));
    });

    // OJO al elegir las cadenas de esta prueba: usa SOLO claves que un motor
    // emita de verdad. La versión anterior probaba el maíz con 'grain_fill' y
    // 'vegetative', que ningún adaptador produce —el maíz emite vegMid,
    // tasseling, flowerSet…—, así que validaba el matcher contra sí mismo y
    // por eso no detectó que llevaba meses roto.
    test('la etapa crítica aprieta el riego', () {
      final vegetativo = MoistureTargetResolver.resolve(
        cropKey: CropKey.maize,
        stageKey: MaizeStageKey.vegMid.name,
        texture: SoilTexture.loam,
      );
      final llenado = MoistureTargetResolver.resolve(
        cropKey: CropKey.maize,
        stageKey: MaizeStageKey.tasseling.name,
        texture: SoilTexture.loam,
      );
      expect(
        llenado.effectiveDepletion,
        lessThan(vegetativo.effectiveDepletion),
      );
      expect(llenado.range.optimalMin, greaterThan(vegetativo.range.optimalMin));
    });

    test('la etapa de curado permite secar', () {
      final bulbo = MoistureTargetResolver.resolve(
        cropKey: CropKey.onion,
        stageKey: OnionStageKey.llenadoBulbo.name,
        texture: SoilTexture.loam,
      );
      final curado = MoistureTargetResolver.resolve(
        cropKey: CropKey.onion,
        stageKey: OnionStageKey.maduracionCosecha.name,
        texture: SoilTexture.loam,
      );
      expect(curado.effectiveDepletion, greaterThan(bulbo.effectiveDepletion));
    });

    test('maceta manda sobre la textura declarada', () {
      final r = MoistureTargetResolver.resolve(
        cropKey: CropKey.cactus,
        texture: SoilTexture.clay,
        isPotted: true,
      );
      expect(r.texture, SoilTexture.pottingMix);
    });

    test('sin textura se declara la limitación y baja la confianza', () {
      final r = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.unknown,
      );
      expect(r.isFallbackTexture, isTrue);
      expect(r.limitationsEs, isNotEmpty);
      expect(r.confidencePenalty, greaterThan(0));
    });

    test('el SoilContext resultante SÍ soporta balance hídrico', () {
      // Era `false` en toda la app hasta ahora: los cuatro campos estaban
      // definidos y nunca se llenaban.
      final r = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.loam,
      );
      expect(r.soilContext.supportsWaterBalance, isTrue);
    });
  });

  group('MoistureTargetResolver · lámina en lenguaje de campo', () {
    test('un tomate con déficit recibe milímetros y litros', () {
      final target = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.loam,
        system: IrrigationSystem.drip,
      );
      final d = MoistureTargetResolver.depthFor(vwcPct: 20, target: target)!;
      // (28 − 20)/100 × 450 mm = 36 mm netos; con goteo 0.90 → 40 brutos.
      expect(d.netMm, closeTo(36.0, 0.01));
      expect(d.grossMm, closeTo(40.0, 0.01));
      expect(d.litersPerSquareMeter, closeTo(40.0, 0.01));
      expect(d.includesSystemLosses, isTrue);
      expect(d.headlineEs(), contains('mm'));
    });

    test('un árbol recibe litros por planta', () {
      final target = MoistureTargetResolver.resolve(
        cropKey: CropKey.appleTree,
        texture: SoilTexture.loam,
        system: IrrigationSystem.drip,
      );
      final d = MoistureTargetResolver.depthFor(vwcPct: 20, target: target)!;
      expect(d.litersPerPlant, isNotNull);
      expect(d.headlineEs(preferPerPlant: true), contains('litros'));
    });

    test('sin déficit no hay lámina, y no se inventa una', () {
      final target = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.loam,
      );
      expect(MoistureTargetResolver.depthFor(vwcPct: 30, target: target), isNull);
    });
  });

  group('CropWaterPolicies · cobertura del catálogo', () {
    test('todo CropKey resuelve a una política', () {
      for (final k in CropKey.values) {
        expect(CropWaterPolicies.forCrop(k).rootDepthCm, greaterThan(0));
      }
    });

    test('el agotamiento ajustado nunca sale de un rango sensato', () {
      // Claves reales de los tres catálogos que conviven, más los dos casos
      // degenerados. Nada inventado.
      final stages = <String>[
        MaizeStageKey.tasseling.name,
        MaizeStageKey.harvest.name,
        WheatStageKey.grainFill.name,
        OnionStageKey.maduracionCosecha.name,
        GarlicStageKey.bulbMaturation.name,
        TomatoStageKey.cosechaProgresiva.name,
        TreeStageIds.fruitFill,
        TreeStageIds.postHarvest,
        TreeStageIds.dormancy,
        '',
        'etapa_que_no_existe',
      ];
      for (final k in CropKey.values) {
        final p = CropWaterPolicies.forCrop(k);
        for (final s in stages) {
          final mad = CropWaterPolicies.allowableDepletionForStage(p, s);
          expect(mad, inInclusiveRange(0.20, 0.85), reason: '$k / $s');
        }
      }
    });
  });
}
