// test/core/agro/water/soil_profile_resolver_test.dart
//
// La jerarquía «el hardware manda», y la calibración del sustrato drenante.

import 'package:bio_g/core/agro/water/moisture_target_resolver.dart';
import 'package:bio_g/core/agro/water/soil_profile_resolver.dart';
import 'package:bio_g/core/agro/water/soil_texture_source.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SoilProfileResolver · jerarquía', () {
    test('el modelo del equipo manda sobre la textura declarada', () {
      // Un BIO-G Maceta vive en sustrato POR CONSTRUCCIÓN. Que el productor
      // haya dicho «mi tierra es arcillosa» no cambia el medio del aparato.
      final r = SoilProfileResolver.resolve(
        deviceModelId: 'maceta',
        soilTextureId: 'clay',
        soilTextureSourceId: 'declared',
        cropKey: CropKey.lettuce,
      );
      expect(r.texture, SoilTexture.pottingMix);
      expect(r.source, SoilTextureSource.derivedFromDevice);
      expect(r.isFallback, isFalse);
    });

    test('con equipo de huerto o campo se usa la textura mineral', () {
      final r = SoilProfileResolver.resolve(
        deviceModelId: 'huerto',
        soilTextureId: 'sandy',
        soilTextureSourceId: 'declared',
        cropKey: CropKey.tomato,
      );
      expect(r.texture, SoilTexture.sandy);
      expect(r.source, SoilTextureSource.declared);
    });

    test('la escala solo decide cuando NO hay equipo emparejado', () {
      final sinEquipo = SoilProfileResolver.resolve(
        cultivationScaleId: 'pot',
        cropKey: CropKey.lettuce,
      );
      expect(sinEquipo.texture, SoilTexture.pottingMix);
      expect(sinEquipo.source, SoilTextureSource.derivedFromScale);

      // Con un BIO-G Huerto conectado, decir «maceta» en la escala NO puede
      // convertir el medio en sustrato: el aparato ya contestó esa pregunta.
      final conEquipo = SoilProfileResolver.resolve(
        deviceModelId: 'huerto',
        cultivationScaleId: 'pot',
        soilTextureId: 'loam',
        cropKey: CropKey.lettuce,
      );
      expect(conEquipo.texture, SoilTexture.loam);
    });

    test('la variante drenante se deriva del cultivo, no de una pregunta', () {
      // Cactus, nopal, agave y suculentas ya están clasificados como xerófitos
      // en la política hídrica. Un sustrato de cactus drena rápido y retiene
      // poco; uno de turba para ornamental convencional retiene mucho más.
      // Meterlos en la misma fila porque ambos están en maceta es el mismo
      // error de escala que se corrigió un nivel más abajo, en suelo.
      for (final xeric in <CropKey>[
        CropKey.cactus,
        CropKey.succulent,
        CropKey.agave,
        CropKey.nopal,
      ]) {
        final r = SoilProfileResolver.resolve(
          deviceModelId: 'maceta',
          cropKey: xeric,
        );
        expect(
          r.texture,
          SoilTexture.pottingMixDraining,
          reason: '$xeric debería vivir en sustrato drenante',
        );
      }

      final rosa = SoilProfileResolver.resolve(
        deviceModelId: 'maceta',
        cropKey: CropKey.rose,
      );
      expect(rosa.texture, SoilTexture.pottingMix);
    });

    test('sin textura declarada cae a media, marcada y con penalización', () {
      final r = SoilProfileResolver.resolve(cropKey: CropKey.maize);
      expect(r.texture, SoilTexture.loam);
      expect(r.isFallback, isTrue);
      expect(r.confidencePenalty, 0.15);
      expect(r.limitationsEs, isNotEmpty);
    });

    test('«no estoy seguro» es respuesta, no hueco, y también es respaldo', () {
      final r = SoilProfileResolver.resolve(
        soilTextureId: 'unknown',
        soilTextureSourceId: 'unknown',
        cropKey: CropKey.maize,
      );
      expect(r.texture, SoilTexture.loam);
      expect(r.isFallback, isTrue);
      expect(r.source, SoilTextureSource.unknown);
    });

    test('un sustrato guardado en el campo mineral se ignora', () {
      // Es un dato imposible: el sustrato jamás se pregunta ni se guarda ahí.
      final r = SoilProfileResolver.resolve(
        soilTextureId: 'pottingMix',
        cropKey: CropKey.maize,
      );
      expect(r.isFallback, isTrue);
      expect(r.texture, SoilTexture.loam);
    });
  });

  group('Sustrato drenante · calibrado contra las xerófitas del catálogo', () {
    // Los rangos actuales de cactus, nopal, agave y suculentas SON CORRECTOS
    // hoy porque están escritos para sustrato. La fila drenante se calibró
    // CONTRA ellos, no al revés: conectar sin hacerlo invertiría el consejo en
    // el grupo donde regar de más es exactamente lo que los mata.
    final c = SoilWaterScale.constantsOf(SoilTexture.pottingMixDraining);

    test('drena más y retiene menos que el sustrato general', () {
      final general = SoilWaterScale.constantsOf(SoilTexture.pottingMix);
      expect(c.fieldCapacityPct, lessThan(general.fieldCapacityPct));
      expect(c.saturationPct, lessThan(general.saturationPct));
      expect(c.wiltingPointPct, lessThan(general.wiltingPointPct));
    });

    test('reproduce la banda de un cactus establecido', () {
      final r = MoistureTargetResolver.resolveForSoilProfile(
        soilProfile: SoilProfileResolver.resolve(
          deviceModelId: 'maceta',
          cropKey: CropKey.cactus,
        ),
        cropKey: CropKey.cactus,
      );

      // Catálogo vigente del cactus en mantenimiento: 4 / 10 / 54 / 72.
      expect(r.range.optimalMax, closeTo(52, 4));
      expect(r.range.optimalMin, closeTo(12, 4));
      expect(r.range.lowMax, closeTo(4.5, 2));
      expect(r.range.highMin, closeTo(70, 3));
    });
  });

  group('Los cinco estados de humedad', () {
    // Tres cotas separadas —capacidad de campo, saturación y umbral de
    // encharcamiento— y hay que usar las tres. Confundir «por encima de
    // capacidad de campo» con «encharcado» genera justo la alarma falsa que
    // este trabajo elimina.
    test('18 % en arena está DRENANDO, no encharcado', () {
      final estado = SoilWaterScale.stateOf(
        vwcPct: 18,
        texture: SoilTexture.sandy,
        allowableDepletionFraction: 0.5,
      );
      // Arena: marchitez 5, campo 12, saturación 38, encharcamiento 34,2.
      // 18 está por encima de campo pero DIECISÉIS puntos por debajo del
      // umbral de encharcamiento. Es el estado normal unas horas después de un
      // riego: el agua gravitacional todavía se está yendo.
      expect(estado, SoilMoistureState.draining);
      expect(estado.isAlarm, isFalse);
    });

    test('el mismo 18 % significa cinco cosas distintas según el suelo', () {
      SoilMoistureState s(SoilTexture t) => SoilWaterScale.stateOf(
        vwcPct: 18,
        texture: t,
        allowableDepletionFraction: 0.40,
      );

      expect(s(SoilTexture.sandy), SoilMoistureState.draining);
      expect(s(SoilTexture.sandyLoam), SoilMoistureState.comfortable);
      expect(s(SoilTexture.loam), SoilMoistureState.timeToIrrigate);
      expect(s(SoilTexture.clayLoam), SoilMoistureState.belowWiltingPoint);
      expect(s(SoilTexture.clay), SoilMoistureState.belowWiltingPoint);
    });

    test('el encharcamiento es alcanzable en todas las texturas', () {
      for (final t in SoilTexture.values) {
        if (t == SoilTexture.unknown) continue;
        final umbral = SoilWaterScale.waterloggingThresholdPct(t);
        expect(
          umbral,
          lessThan(100),
          reason: 'una alarma inalcanzable no es una alarma',
        );
        expect(
          SoilWaterScale.stateOf(
            vwcPct: umbral + 0.5,
            texture: t,
            allowableDepletionFraction: 0.5,
          ),
          SoilMoistureState.waterlogged,
        );
      }
    });
  });

  group('La lámina sale en banda, nunca como cifra cerrada', () {
    test('±3 puntos sobre 40 cm de raíz son ±30 % de la lámina', () {
      final target = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.loam,
      );
      final depth = MoistureTargetResolver.depthFor(
        vwcPct: 18,
        target: target,
      );

      expect(depth, isNotNull);
      // Franco: campo 28. (28 - 18)/100 x 450 mm de raíz de tomate = 45 mm.
      expect(depth!.netMm, closeTo(45, 1));
      expect(depth.needsBand, isTrue);
      expect(depth.lowMm, lessThan(depth.grossMm));
      expect(depth.highMm, greaterThan(depth.grossMm));
      expect(depth.headlineEs(), contains('entre'));
    });

    test('por encima de capacidad de campo no hay lámina que aplicar', () {
      final target = MoistureTargetResolver.resolve(
        cropKey: CropKey.tomato,
        texture: SoilTexture.loam,
      );
      expect(
        MoistureTargetResolver.depthFor(vwcPct: 34, target: target),
        isNull,
        reason: 'fingir un número sería peor que callarse',
      );
    });
  });
}
