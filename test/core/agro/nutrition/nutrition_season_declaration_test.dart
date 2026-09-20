// test/core/agro/nutrition/nutrition_season_declaration_test.dart
import 'package:bio_g/core/agro/nutrition/nutrition_season_declaration.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ida y vuelta por JSON', () {
    final NutritionSeasonDeclaration d = NutritionSeasonDeclaration(
      deviceId: 'dev-1',
      seasonKey: 'dev-1|maize|2026-04-01',
      cropKey: 'maize',
      passes: NitrogenPassPlan.two,
      declaredAt: DateTime(2026, 4, 3, 10, 30),
      sourceId: NutritionDeclarationSources.timeline,
    );
    final NutritionSeasonDeclaration back =
        NutritionSeasonDeclaration.tryFromJson(d.toJson())!;
    expect(back.deviceId, d.deviceId);
    expect(back.seasonKey, d.seasonKey);
    expect(back.cropKey, d.cropKey);
    expect(back.passes, NitrogenPassPlan.two);
    expect(back.declaredAt.toUtc(), d.declaredAt.toUtc());
    expect(back.sourceId, NutritionDeclarationSources.timeline);
  });

  test('JSON incompleto o con pasadas desconocidas devuelve null', () {
    expect(NutritionSeasonDeclaration.tryFromJson(<String, dynamic>{}), isNull);
    expect(
      NutritionSeasonDeclaration.tryFromJson(<String, dynamic>{
        'deviceId': 'd',
        'seasonKey': 's',
        'passes': 'siete',
        'declaredAt': '2026-04-03T10:30:00Z',
      }),
      isNull,
    );
  });

  test('identificadores estables y alias', () {
    expect(NitrogenPassPlan.single.id, 'single');
    expect(NitrogenPassPlan.two.id, 'two');
    expect(NitrogenPassPlan.threeOrMore.id, 'three_plus');
    expect(NitrogenPassPlanX.fromId('three_plus'), NitrogenPassPlan.threeOrMore);
    expect(NitrogenPassPlanX.fromId('threeOrMore'), NitrogenPassPlan.threeOrMore);
    expect(NitrogenPassPlanX.fromId('1'), NitrogenPassPlan.single);
    expect(NitrogenPassPlanX.fromId('dos'), NitrogenPassPlan.two);
    expect(NitrogenPassPlanX.fromId(null), isNull);
    expect(NitrogenPassPlan.single.passes, 1);
    expect(NitrogenPassPlan.threeOrMore.passes, 3);
  });

  test('«ya fertilicé» (17 sep 2026): id estable, cero pasadas, ida y vuelta', () {
    expect(NitrogenPassPlan.alreadyDone.id, 'already_done');
    expect(NitrogenPassPlan.alreadyDone.passes, 0);
    expect(NitrogenPassPlan.alreadyDone.isAlreadyDone, isTrue);
    expect(NitrogenPassPlan.single.isAlreadyDone, isFalse);
    expect(NitrogenPassPlan.alreadyDone.labelEs, 'Ya fertilicé');
    expect(NitrogenPassPlanX.fromId('already_done'), NitrogenPassPlan.alreadyDone);
    expect(NitrogenPassPlanX.fromId('alreadyDone'), NitrogenPassPlan.alreadyDone);
    expect(NitrogenPassPlanX.fromId('0'), NitrogenPassPlan.alreadyDone);
    final NutritionSeasonDeclaration d = NutritionSeasonDeclaration(
      deviceId: 'dev-1',
      seasonKey: 'dev-1|maize|2026-04-01',
      cropKey: 'crop_maize',
      passes: NitrogenPassPlan.alreadyDone,
      declaredAt: DateTime(2026, 5, 20),
    );
    expect(NutritionSeasonDeclaration.tryFromJson(d.toJson())!.passes, NitrogenPassPlan.alreadyDone);
    expect(d.isSinglePass, isFalse);
  });
}
