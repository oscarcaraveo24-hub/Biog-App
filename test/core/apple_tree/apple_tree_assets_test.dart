// test/core/apple_tree/apple_tree_assets_test.dart
//
// Imágenes fenológicas por etapa (con fallback neutro para `unknown`), su
// cableado en el resolver perenne, ausencia de eje sowingDate y seguridad de
// la migración AP-SKIP → AP-01.

import 'dart:io';

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_stage_resolver.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:flutter_test/flutter_test.dart';

DeviceCropContext _appleContext({
  String profileId = kApSkip,
  String? perennialStateId,
  String? phenologyStageId,
  DateTime? perennialAnchorDate,
  String? perennialAnchorTypeId,
}) {
  final now = DateTime(2026, 6, 13);
  return DeviceCropContext(
    deviceId: 'dev-1',
    cropCategoryId: CropCatalog.treeCategoryId,
    cropId: CropCatalog.appleTreeCropId,
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
  group('Mapeo etapa → imagen fenológica', () {
    const expected = <String, String>{
      TreeStageIds.plantingTransplant:
          'assets/seeds/apple/apple_stage_planting_transplant.png',
      TreeStageIds.rootEstablishment:
          'assets/seeds/apple/apple_stage_root_establishment.png',
      TreeStageIds.juvenileVegetative:
          'assets/seeds/apple/apple_stage_juvenile_vegetative.png',
      TreeStageIds.dormancy: 'assets/seeds/apple/apple_stage_dormancy.png',
      TreeStageIds.budbreak: 'assets/seeds/apple/apple_stage_budbreak.png',
      TreeStageIds.vegetativeGrowth:
          'assets/seeds/apple/apple_stage_vegetative_growth.png',
      TreeStageIds.flowering: 'assets/seeds/apple/apple_stage_flowering.png',
      TreeStageIds.fruitSet: 'assets/seeds/apple/apple_stage_fruit_set.png',
      TreeStageIds.fruitFill: 'assets/seeds/apple/apple_stage_fruit_fill.png',
      TreeStageIds.harvestMaturity:
          'assets/seeds/apple/apple_stage_harvest_maturity.png',
      TreeStageIds.postHarvest:
          'assets/seeds/apple/apple_stage_post_harvest.png',
    };

    test('cada etapa real resuelve su asset correcto', () {
      expected.forEach((stage, path) {
        expect(appleTreeStageImage(stage), path, reason: 'etapa $stage');
      });
    });

    test('los assets de cada etapa existen en disco', () {
      expected.forEach((stage, path) {
        expect(File(path).existsSync(), isTrue, reason: 'falta $path');
      });
    });
  });

  group('Etapa unknown', () {
    test(
      'unknown NO usa imagen fenológica (no existe apple_stage_unknown)',
      () {
        expect(appleTreeStageImage(TreeStageIds.unknown), isNull);
        expect(appleTreeStageImage(null), isNull);
        expect(appleTreeStageImage('etapa_inventada'), isNull);
        expect(
          File('assets/seeds/apple/apple_stage_unknown.png').existsSync(),
          isFalse,
        );
      },
    );

    test('el fallback neutro nunca es nulo ni vacío', () {
      for (final stage in <String?>[
        null,
        TreeStageIds.unknown,
        'basura',
        TreeStageIds.flowering,
      ]) {
        final asset = appleTreeStageImageOrNeutral(stage);
        expect(asset, isNotEmpty);
      }
      expect(
        appleTreeStageImageOrNeutral(TreeStageIds.unknown),
        AppleTreeAssets.neutralIcon,
      );
    });
  });

  group('Resolver perenne (hero asset, sin sowingDate)', () {
    test('hero asset corresponde a la imagen de la etapa', () {
      final result = PerennialStageResolver.resolve(
        context: _appleContext(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.flowering,
        ),
        today: DateTime(2026, 6, 13),
      );
      expect(result.heroAsset, 'assets/seeds/apple/apple_stage_flowering.png');
    });

    test('etapa desconocida → hero neutro (no imagen fenológica)', () {
      final result = PerennialStageResolver.resolve(
        context: _appleContext(),
        today: DateTime(2026, 6, 13),
      );
      expect(result.heroAsset, AppleTreeAssets.neutralIcon);
    });

    test('el manzano NO usa sowingDate como eje (daySinceSowing == null)', () {
      final result = PerennialStageResolver.resolve(
        context: _appleContext(
          perennialStateId: TreeStateIds.productiveSeason,
          phenologyStageId: TreeStageIds.fruitFill,
        ),
        today: DateTime(2026, 6, 13),
      );
      expect(result.daySinceSowing, isNull);
      expect(result.expectedDaysToEnd, 0);
    });

    test('post_harvest sigue activo (no cierra el cultivo)', () {
      final result = PerennialStageResolver.resolve(
        context: _appleContext(
          perennialStateId: TreeStateIds.established,
          phenologyStageId: TreeStageIds.postHarvest,
        ),
        today: DateTime(2026, 6, 13),
      );
      expect(result.stageKey, TreeStageIds.postHarvest);
      expect(
        result.heroAsset,
        'assets/seeds/apple/apple_stage_post_harvest.png',
      );
      expect(result.helperCaption, contains('etapa activa'));
    });
  });

  group('Migración de perfil AP-SKIP → AP-01', () {
    test('cambiar de perfil NO borra estado/etapa/ancla perenne', () {
      final anchor = DateTime(2026, 3, 1);
      final base = _appleContext(
        profileId: kApSkip,
        perennialStateId: TreeStateIds.productiveSeason,
        phenologyStageId: TreeStageIds.flowering,
        perennialAnchorDate: anchor,
        perennialAnchorTypeId: TreeAnchorTypeIds.flowering,
      );

      final migrated = base.copyWith(profileId: kAp01Golden);

      expect(migrated.profileId, kAp01Golden);
      // Toda la memoria perenne se conserva tras la migración.
      expect(migrated.perennialStateId, TreeStateIds.productiveSeason);
      expect(migrated.phenologyStageId, TreeStageIds.flowering);
      expect(migrated.perennialAnchorDate, anchor);
      expect(migrated.perennialAnchorTypeId, TreeAnchorTypeIds.flowering);
    });
  });
}
