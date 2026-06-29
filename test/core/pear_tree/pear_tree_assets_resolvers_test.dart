// test/core/pear_tree/pear_tree_assets_resolvers_test.dart
//
// Regresion dirigida para assets reales de Pera y su cableado en resolvers.

import 'dart:io';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_presentation_resolver.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_assets.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_stage_resolver.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

DeviceCropContext _pearContext({
  String profileId = kPrSkip,
  String? perennialStateId,
  String? phenologyStageId,
  DateTime? perennialAnchorDate,
  String? perennialAnchorTypeId,
}) {
  final now = DateTime(2026, 6, 20);
  return DeviceCropContext(
    deviceId: 'pear-dev-1',
    cropCategoryId: CropCatalog.treeCategoryId,
    cropId: CropCatalog.pearTreeCropId,
    profileId: profileId,
    lifecycleStatus: CropLifecycleStatus.planted,
    sowingDateConfidence: DateConfidence.unknown,
    catalogVersion: 'test',
    source: CropConfigSource.wizard,
    configuredAt: now,
    updatedAt: now,
    perennialStateId: perennialStateId,
    phenologyStageId: phenologyStageId,
    perennialAnchorDate: perennialAnchorDate,
    perennialAnchorTypeId: perennialAnchorTypeId,
  );
}

void main() {
  group('assets reales de pera', () {
    const stageAssets = <String, String>{
      TreeStageIds.plantingTransplant:
          'assets/seeds/pear/pear_stage_planting_transplant.png',
      TreeStageIds.rootEstablishment:
          'assets/seeds/pear/pear_stage_root_establishment.png',
      TreeStageIds.juvenileVegetative:
          'assets/seeds/pear/pear_stage_juvenile_vegetative.png',
      TreeStageIds.dormancy: 'assets/seeds/pear/pear_stage_dormancy.png',
      TreeStageIds.budbreak: 'assets/seeds/pear/pear_stage_budbreak.png',
      TreeStageIds.vegetativeGrowth:
          'assets/seeds/pear/pear_stage_vegetative_growth.png',
      TreeStageIds.flowering: 'assets/seeds/pear/pear_stage_flowering.png',
      TreeStageIds.fruitSet: 'assets/seeds/pear/pear_stage_fruit_set.png',
      TreeStageIds.fruitFill: 'assets/seeds/pear/pear_stage_fruit_fill.png',
      TreeStageIds.harvestMaturity:
          'assets/seeds/pear/pear_stage_harvest_maturity.png',
      TreeStageIds.postHarvest: 'assets/seeds/pear/pear_stage_post_harvest.png',
      TreeStageIds.unknown: 'assets/seeds/pear/pear_stage_unknown.png',
    };

    test('cada etapa resuelve su PNG en assets/seeds/pear', () {
      stageAssets.forEach((stage, path) {
        expect(pearTreeStageImage(stage), path, reason: stage);
        expect(File(path).existsSync(), isTrue, reason: 'falta $path');
      });
    });

    test('iconos de cultivo y perfiles PR existen en disco', () {
      final icons = <String>[
        PearTreeAssets.cropIcon,
        PearTreeAssets.neutralIcon,
        pearTreeProfileIcon(kPr01BartlettWilliams),
        pearTreeProfileIcon(kPr02Anjou),
        pearTreeProfileIcon(kPr03Bosc),
        pearTreeProfileIcon(kPr04SeckelComice),
        pearTreeProfileIcon(kPr05KiefferRustic),
      ];

      for (final icon in icons) {
        expect(File(icon).existsSync(), isTrue, reason: 'falta $icon');
      }
    });

    test('no queda ruta pear_tree declarada para etapas de pera', () {
      for (final stage in stageAssets.keys) {
        expect(pearTreeStageImage(stage), isNot(contains('/pear_tree/')));
      }
    });
  });

  group('resolver perenne de pera', () {
    test('fruit_fill, harvest_maturity y post_harvest usan hero distinto', () {
      final fruitFill = PerennialStageResolver.resolve(
        context: _pearContext(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.fruitFill,
        ),
        today: DateTime(2026, 6, 20),
      );
      final harvest = PerennialStageResolver.resolve(
        context: _pearContext(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.harvestMaturity,
        ),
        today: DateTime(2026, 6, 20),
      );
      final postHarvest = PerennialStageResolver.resolve(
        context: _pearContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.postHarvest,
        ),
        today: DateTime(2026, 6, 20),
      );

      expect(fruitFill.stageKey, TreeStageIds.fruitFill);
      expect(harvest.stageKey, TreeStageIds.harvestMaturity);
      expect(postHarvest.stageKey, TreeStageIds.postHarvest);
      expect(fruitFill.heroAsset, contains('pear_stage_fruit_fill.png'));
      expect(harvest.heroAsset, contains('pear_stage_harvest_maturity.png'));
      expect(postHarvest.heroAsset, contains('pear_stage_post_harvest.png'));
      expect(fruitFill.heroAsset, isNot(harvest.heroAsset));
      expect(harvest.heroAsset, isNot(postHarvest.heroAsset));
    });

    test('post_harvest sigue activo y no usa sowingDate como eje', () {
      final result = PerennialStageResolver.resolve(
        context: _pearContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.postHarvest,
        ),
        today: DateTime(2026, 6, 20),
      );

      expect(result.stageKey, TreeStageIds.postHarvest);
      expect(result.expectedDaysToEnd, 0);
      expect(result.daySinceSowing, isNull);
      expect(result.helperCaption, contains('etapa activa'));
    });

    test('unknown de pera usa el asset real de etapa desconocida', () {
      final result = PerennialStageResolver.resolve(
        context: _pearContext(),
        today: DateTime(2026, 6, 20),
      );

      expect(result.stageKey, TreeStageIds.unknown);
      expect(result.heroAsset, 'assets/seeds/pear/pear_stage_unknown.png');
    });
  });

  group('presentacion visual de pera', () {
    test('PR-03 Bosc resuelve icono de perfil de pera', () {
      final presentation = CropPresentationResolver.resolve(
        cropContext: _pearContext(profileId: kPr03Bosc),
        seed: null,
      );

      expect(presentation.cropId, CropCatalog.pearTreeCropId);
      expect(presentation.iconAsset, pearTreeProfileIcon(kPr03Bosc));
      expect(presentation.iconAsset, isNot(contains('apple')));
    });

    test('PR-SKIP usa icono generico de pera y no AP-SKIP', () {
      final presentation = CropPresentationResolver.resolve(
        cropContext: _pearContext(profileId: kPrSkip),
        seed: null,
      );

      expect(presentation.iconAsset, PearTreeAssets.neutralIcon);
      expect(presentation.iconAsset, isNot(contains('apple')));
      expect(presentation.isFallowMode, isFalse);
    });

    test('PR-03 muestra nombre humano (Bosc), nunca el id crudo pr_03_bosc', () {
      final presentation = CropPresentationResolver.resolve(
        cropContext: _pearContext(profileId: kPr03Bosc),
        seed: null,
      );

      expect(presentation.varietyLabel, 'Bosc');
      expect(presentation.headlineLabel, 'Pera · Bosc');
      expect(presentation.headlineLabel, isNot(contains('pr_03')));
      expect(presentation.isGenericSelection, isFalse);
    });

    test('PR-SKIP no filtra códigos técnicos: solo "Pera"', () {
      final presentation = CropPresentationResolver.resolve(
        cropContext: _pearContext(profileId: kPrSkip),
        seed: null,
      );

      expect(presentation.headlineLabel, 'Pera');
      expect(presentation.varietyLabel, isNull);
      expect(presentation.headlineLabel.toLowerCase(), isNot(contains('skip')));
      expect(presentation.headlineLabel.toLowerCase(), isNot(contains('perfil')));
      expect(presentation.isGenericSelection, isTrue);
    });
  });
}
