// test/core/peach_tree/peach_tree_assets_resolvers_test.dart
//
// Assets definitivos del Durazno: iconos glossy `ic_peach_*` y etapas
// fenologicas `assets/seeds/peach/peach_stage_*`.

import 'dart:io';

import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/crop_presentation_resolver.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_stage_resolver.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

DeviceCropContext _peachContext({
  String profileId = kDzSkip,
  String? perennialStateId,
  String? phenologyStageId,
  DateTime? perennialAnchorDate,
  String? perennialAnchorTypeId,
}) {
  final now = DateTime(2026, 6, 21);
  return DeviceCropContext(
    deviceId: 'peach-dev-1',
    cropCategoryId: CropCatalog.treeCategoryId,
    cropId: CropCatalog.peachTreeCropId,
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
  group('assets reales del durazno', () {
    const allStages = <String>[
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

    test('cada etapa resuelve un peach_stage_* que existe en disco', () {
      for (final stage in allStages) {
        final path = peachTreeStageImageOrNeutral(stage);
        expect(path, startsWith('assets/seeds/peach/'), reason: stage);
        expect(path, contains('peach_stage_'), reason: stage);
        expect(path, isNot(contains('ic_tree')), reason: stage);
        expect(File(path).existsSync(), isTrue, reason: 'falta $path ($stage)');
      }
    });

    test('iconos de cultivo y perfiles DZ usan ic_peach_* reales', () {
      final icons = <String>[
        PeachTreeAssets.cropIcon,
        PeachTreeAssets.neutralIcon,
        peachTreeProfileIcon(kDzSkip),
        peachTreeProfileIcon(kDz01CriolloRegional),
        peachTreeProfileIcon(kDz02TempranoBajoFrio),
        peachTreeProfileIcon(kDz03AmarilloComercial),
        peachTreeProfileIcon(kDz04BlancoDulce),
        peachTreeProfileIcon(kDz05TardioIndustria),
      ];
      for (final icon in icons) {
        expect(icon, startsWith('assets/icons/wizard/ic_peach'), reason: icon);
        expect(File(icon).existsSync(), isTrue, reason: 'falta $icon');
        expect(icon, isNot(contains('apple')));
        expect(icon, isNot(contains('pear')));
      }
    });

    test('mapeo de perfiles a iconos definitivos', () {
      expect(peachTreeProfileIcon(kDzSkip), PeachTreeAssets.iconGeneric);
      expect(
        peachTreeProfileIcon(kDz01CriolloRegional),
        PeachTreeAssets.iconCriolloRegional,
      );
      expect(
        peachTreeProfileIcon(kDz03AmarilloComercial),
        PeachTreeAssets.iconAmarilloComercial,
      );
      expect(
        peachTreeProfileIcon(kDz05TardioIndustria),
        PeachTreeAssets.iconTardioIndustria,
      );
    });
  });

  group('resolver perenne del durazno', () {
    test('fruit_fill, harvest_maturity y post_harvest usan hero distinto', () {
      final fruitFill = PerennialStageResolver.resolve(
        context: _peachContext(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.fruitFill,
        ),
        today: DateTime(2026, 6, 21),
      );
      final harvest = PerennialStageResolver.resolve(
        context: _peachContext(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.harvestMaturity,
        ),
        today: DateTime(2026, 6, 21),
      );
      final postHarvest = PerennialStageResolver.resolve(
        context: _peachContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.postHarvest,
        ),
        today: DateTime(2026, 6, 21),
      );

      expect(fruitFill.stageKey, TreeStageIds.fruitFill);
      expect(harvest.stageKey, TreeStageIds.harvestMaturity);
      expect(postHarvest.stageKey, TreeStageIds.postHarvest);
      expect(fruitFill.heroAsset, isNot(harvest.heroAsset));
      expect(harvest.heroAsset, isNot(postHarvest.heroAsset));
      expect(File(fruitFill.heroAsset).existsSync(), isTrue);
      expect(File(harvest.heroAsset).existsSync(), isTrue);
      expect(File(postHarvest.heroAsset).existsSync(), isTrue);
    });

    test('post_harvest sigue activo y no usa sowingDate como eje', () {
      final result = PerennialStageResolver.resolve(
        context: _peachContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.postHarvest,
        ),
        today: DateTime(2026, 6, 21),
      );
      expect(result.stageKey, TreeStageIds.postHarvest);
      expect(result.expectedDaysToEnd, 0);
      expect(result.daySinceSowing, isNull);
      expect(result.helperCaption, contains('etapa activa'));
    });
  });

  group('presentacion visual del durazno', () {
    test('DZ-01 muestra nombre humano, nunca id crudo', () {
      final presentation = CropPresentationResolver.resolve(
        cropContext: _peachContext(profileId: kDz01CriolloRegional),
        seed: null,
      );
      expect(presentation.cropId, CropCatalog.peachTreeCropId);
      expect(presentation.varietyLabel, 'Criollo / regional');
      expect(presentation.headlineLabel, 'Durazno · Criollo / regional');
      expect(presentation.headlineLabel, isNot(contains('dz_01')));
      expect(presentation.headlineLabel.toUpperCase(), isNot(contains('DZ-01')));
      expect(presentation.isGenericSelection, isFalse);
    });

    test('DZ-SKIP no filtra codigos y usa icono generico de durazno', () {
      final presentation = CropPresentationResolver.resolve(
        cropContext: _peachContext(profileId: kDzSkip),
        seed: null,
      );
      expect(presentation.headlineLabel, 'Durazno');
      expect(presentation.varietyLabel, isNull);
      expect(presentation.headlineLabel.toLowerCase(), isNot(contains('skip')));
      expect(presentation.headlineLabel.toLowerCase(), isNot(contains('perfil')));
      expect(presentation.isGenericSelection, isTrue);
      expect(presentation.iconAsset, PeachTreeAssets.neutralIcon);
      expect(presentation.iconAsset, contains('ic_peach_tree_generic'));
      expect(presentation.isFallowMode, isFalse);
    });
  });
}
