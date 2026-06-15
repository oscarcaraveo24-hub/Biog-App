// test/core/apple_tree/apple_tree_targets_test.dart
//
// El rango comparable de suelo del manzano debe devolver los ppm REALES de
// suficiencia (doc 05), no el valor escalado por el cap legacy.

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/agro/nutrient_target_range_resolver.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_universal_profile.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('comparableRange del manzano usa ppm reales (no cap-scaled)', () {
    test('N en plantación: óptimo 20–40 mg/kg, NO el escalado por cap', () {
      final targets = resolveAppleTreeTargets(TreeStageIds.plantingTransplant);
      final range = NutrientTargetRangeResolver.comparableRange(
        nutrient: AgroMetricKey.n,
        cropKey: 'apple_tree',
        targets: targets,
      );

      expect(range, isNotNull);
      expect(range!.optimalMin, 20.0);
      expect(range.optimalMax, 40.0);

      // Bug previo: nIndex 20–40 interpretado como índice 0–100 y multiplicado
      // por el cap default 120 → 24–48. Con cap real 90 daría 18–36. Ninguno
      // debe ocurrir: usamos el rango explícito de suelo.
      final cap = NpkCaps.forCropMetric(
        cropKey: 'apple_tree',
        metricKey: AgroMetricKey.n,
      );
      expect(cap, 90.0);
      expect(range.optimalMax, isNot(48.0)); // cap default 120
      expect(range.optimalMax, isNot(36.0)); // cap 90 escalado
    });

    test('bandas suaves: lowMax < optimalMin y optimalMax < highMin', () {
      for (final stage in <String>[
        TreeStageIds.plantingTransplant,
        TreeStageIds.flowering,
        TreeStageIds.fruitFill,
        TreeStageIds.harvestMaturity,
      ]) {
        for (final nutrient in <AgroMetricKey>[
          AgroMetricKey.n,
          AgroMetricKey.p,
          AgroMetricKey.k,
        ]) {
          final range = NutrientTargetRangeResolver.comparableRange(
            nutrient: nutrient,
            cropKey: 'apple_tree',
            targets: resolveAppleTreeTargets(stage),
          )!;
          expect(
            range.lowMax,
            lessThan(range.optimalMin),
            reason: 'lowMax<optMin en $stage/$nutrient',
          );
          expect(
            range.optimalMax,
            lessThan(range.highMin),
            reason: 'optMax<highMin (zona alto útil) en $stage/$nutrient',
          );
        }
      }
    });

    test('fruit_fill: N=71 supera highMin (exceso); N=55 queda en alto útil', () {
      final range = NutrientTargetRangeResolver.comparableRange(
        nutrient: AgroMetricKey.n,
        cropKey: 'apple_tree',
        targets: resolveAppleTreeTargets(TreeStageIds.fruitFill),
      )!;
      // Óptimo de N en llenado: 25–45.
      expect(range.optimalMin, 25.0);
      expect(range.optimalMax, 45.0);
      expect(71, greaterThanOrEqualTo(range.highMin)); // exceso real
      expect(55, lessThan(range.highMin)); // alto útil tolerante
      expect(55, greaterThan(range.optimalMax));
    });
  });
}
