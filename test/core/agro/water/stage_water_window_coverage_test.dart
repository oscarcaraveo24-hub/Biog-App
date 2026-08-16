// test/core/agro/water/stage_water_window_coverage_test.dart
//
// La prueba que faltaba.
//
// El matcher por palabras que esto reemplaza llevaba meses roto y las pruebas
// no lo notaron NUNCA, porque probaban el maíz con la cadena 'grain_fill' —que
// ningún motor emite— y la cebolla con 'bulking' y 'curing', cuando la cebolla
// emite 'llenadoBulbo' y 'maduracionCosecha'. Validaban la lista de palabras
// contra sí misma, jamás contra el catálogo real.
//
// Esta prueba hace lo contrario: recorre las claves de etapa REALES —las que
// los adaptadores emiten de verdad— y falla si alguna no está clasificada.
//
// Cubre las dos convenciones que conviven en el catálogo:
//
//   1. Enums `*StageKey`. Se recorre `.values` y se usa `.name`, que es
//      exactamente lo que el adaptador manda (`result.stage.name`). Al ser el
//      propio enum la fuente, agregar una etapa nueva rompe esta prueba sola.
//   2. Clases `*StageIds`, que son constantes sueltas y no se pueden recorrer
//      desde Dart. Se leen del CÓDIGO FUENTE con una expresión regular, para
//      que una constante nueva quede cubierta sin que nadie se acuerde de
//      añadirla aquí.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/core/agro/water/stage_water_window.dart';
import 'package:bio_g/core/crops/crop_types.dart';

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
import 'package:bio_g/widgets/seeds/squash_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/tomato_models.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/wheat_models.dart';

/// Los archivos que declaran clases `*StageIds`.
const _stageIdSources = <String>[
  'lib/core/crops/tree_lifecycle.dart',
  'lib/core/crops/rose/rose_lifecycle.dart',
  'lib/core/crops/cactus/cactus_lifecycle.dart',
  'lib/core/crops/nopal/nopal_lifecycle.dart',
  'lib/core/crops/succulent/succulent_lifecycle.dart',
  'lib/core/crops/aloe/aloe_lifecycle.dart',
  'lib/core/crops/agave/agave_lifecycle.dart',
  'lib/widgets/seeds/marigold_models.dart',
  'lib/widgets/seeds/sunflower_models.dart',
  'lib/widgets/seeds/tulip_models.dart',
];

/// Saca los valores de las constantes de una clase `*StageIds` del fuente.
Map<String, List<String>> _stageIdsFromSource(String path) {
  final file = File(path);
  expect(
    file.existsSync(),
    isTrue,
    reason:
        'No existe $path. Si el archivo se movió, actualiza _stageIdSources: '
        'si esta lista se queda corta, la prueba deja de cubrir ese catálogo '
        'sin avisar, que es justo el fallo que esta prueba existe para evitar.',
  );
  final src = file.readAsStringSync();
  final out = <String, List<String>>{};
  final classRe = RegExp(r'class\s+(\w*StageIds)\s*\{(.*?)\n\}', dotAll: true);
  final constRe = RegExp(r"static\s+const\s+String\s+\w+\s*=\s*'([^']+)'");
  for (final m in classRe.allMatches(src)) {
    final name = m.group(1)!;
    final body = m.group(2)!;
    final ids = constRe.allMatches(body).map((c) => c.group(1)!).toList();
    if (ids.isNotEmpty) out[name] = ids;
  }
  return out;
}

void main() {
  group('cobertura de ventanas hídricas', () {
    test('toda etapa de enum está declarada', () {
      final catalogos = <String, List<String>>{
        'BarleyStageKey': BarleyStageKey.values.map((e) => e.name).toList(),
        'BeanStageKey': BeanStageKey.values.map((e) => e.name).toList(),
        'ChiliStageKey': ChiliStageKey.values.map((e) => e.name).toList(),
        'CucumberStageKey': CucumberStageKey.values.map((e) => e.name).toList(),
        'EggplantStageKey': EggplantStageKey.values.map((e) => e.name).toList(),
        'GarlicStageKey': GarlicStageKey.values.map((e) => e.name).toList(),
        'LettuceStageKey': LettuceStageKey.values.map((e) => e.name).toList(),
        'MaizeStageKey': MaizeStageKey.values.map((e) => e.name).toList(),
        'MarigoldStageKey': MarigoldStageKey.values.map((e) => e.name).toList(),
        'OatStageKey': OatStageKey.values.map((e) => e.name).toList(),
        'OnionStageKey': OnionStageKey.values.map((e) => e.name).toList(),
        'SpinachStageKey': SpinachStageKey.values.map((e) => e.name).toList(),
        'SquashStageKey': SquashStageKey.values.map((e) => e.name).toList(),
        'SunflowerStageKey':
            SunflowerStageKey.values.map((e) => e.name).toList(),
        'TomatoStageKey': TomatoStageKey.values.map((e) => e.name).toList(),
        'TulipStageKey': TulipStageKey.values.map((e) => e.name).toList(),
        'WheatStageKey': WheatStageKey.values.map((e) => e.name).toList(),
      };

      final faltantes = <String>[];
      for (final entry in catalogos.entries) {
        for (final key in entry.value) {
          if (StageWaterWindows.lookup(key) == null) {
            faltantes.add('${entry.key}.$key');
          }
        }
      }

      expect(
        faltantes,
        isEmpty,
        reason:
            'Estas etapas no declaran ventana hídrica, así que el riego las '
            'trata con el agotamiento base sin que nadie lo haya decidido:\n'
            '  ${faltantes.join('\n  ')}\n'
            'Declara cada una en StageWaterWindows como normal, critical o '
            'drying. Si de verdad no lleva ajuste, decláralo como normal: la '
            'diferencia entre "decidimos que no lleva" y "se nos pasó" es el '
            'motivo de esta prueba.',
      );
    });

    test('toda constante *StageIds está declarada', () {
      final faltantes = <String>[];
      var catalogos = 0;
      for (final path in _stageIdSources) {
        final clases = _stageIdsFromSource(path);
        expect(
          clases,
          isNotEmpty,
          reason:
              'No se encontró ninguna clase *StageIds en $path. Si cambió su '
              'forma, esta prueba dejó de leerlo y hay que arreglarla.',
        );
        for (final entry in clases.entries) {
          catalogos++;
          for (final id in entry.value) {
            if (StageWaterWindows.lookup(id) == null) {
              faltantes.add('${entry.key}: $id  ($path)');
            }
          }
        }
      }

      expect(catalogos, greaterThanOrEqualTo(10));
      expect(
        faltantes,
        isEmpty,
        reason:
            'Estas constantes de etapa no declaran ventana hídrica:\n'
            '  ${faltantes.join('\n  ')}',
      );
    });

    test('camelCase y snake_case caen en la misma entrada', () {
      // Esto es lo que mató al matcher anterior: el catálogo usa las dos
      // convenciones y la lista de palabras solo contemplaba una.
      expect(
        StageWaterWindows.lookup('grainFill'),
        StageWaterWindows.lookup('grain_fill'),
      );
      expect(
        StageWaterWindows.lookup('fruitSet'),
        StageWaterWindows.lookup('fruit_set'),
      );
      expect(
        StageWaterWindows.lookup('postHarvest'),
        StageWaterWindows.lookup('post_harvest'),
      );
      expect(StageWaterWindows.lookup('GRAIN_FILL'), WaterWindow.critical);
    });

    test('el mapa por cultivo se consulta antes que el global', () {
      // Sin esta prueba, un error de dedo en una clave de `_byCrop` pasaría
      // desapercibido: el mapa global respondería igual y nadie se enteraría de
      // que la excepción por cultivo dejó de aplicarse.

      // Arraigo: crítico en frutal y rosal, deliberadamente normal en xerófita.
      expect(
        StageWaterWindows.lookup('root_establishment',
            cropKey: CropKey.appleTree),
        WaterWindow.critical,
      );
      expect(
        StageWaterWindows.lookup('root_establishment', cropKey: CropKey.rose),
        WaterWindow.critical,
      );
      expect(
        StageWaterWindows.lookup('root_establishment', cropKey: CropKey.cactus),
        WaterWindow.normal,
      );
      // Y sin cultivo hereda el valor conservador, no el del frutal.
      expect(
        StageWaterWindows.lookup('root_establishment'),
        WaterWindow.normal,
      );

      // Largo de tallo: producto en tulipán, rutina en girasol.
      expect(
        StageWaterWindows.lookup('stem_elongation', cropKey: CropKey.tulip),
        WaterWindow.critical,
      );
      expect(
        StageWaterWindows.lookup('stem_elongation', cropKey: CropKey.sunflower),
        WaterWindow.normal,
      );

      // La sábila no sigue a las xerófitas en `maintenance`.
      expect(
        StageWaterWindows.lookup('maintenance', cropKey: CropKey.aloe),
        WaterWindow.normal,
      );
      expect(
        StageWaterWindows.lookup('maintenance', cropKey: CropKey.cactus),
        WaterWindow.drying,
      );
    });

    test('clave nula o vacía no resuelve', () {
      expect(StageWaterWindows.lookup(null), isNull);
      expect(StageWaterWindows.lookup(''), isNull);
      expect(StageWaterWindows.lookup('   '), isNull);
      expect(StageWaterWindows.lookup('etapa_que_no_existe'), isNull);
    });
  });
}
