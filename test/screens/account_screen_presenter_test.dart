import 'package:flutter_test/flutter_test.dart';

import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';
import 'package:bio_g/screens/account/account_screen_presenter.dart';

void main() {
  late AccountScreenPresenter presenter;

  setUp(() {
    presenter = AccountScreenPresenter();
  });

  // ── Helpers ──────────────────────────────────────────────────────────────

  DeviceCropContext _makeCropContext({
    String deviceId = 'dev-1',
    String cropId = 'maize',
    String profileId = 'maize_generic',
    CropLifecycleStatus lifecycleStatus = CropLifecycleStatus.planted,
    DateTime? sowingDate,
    DateTime? plannedSowingDate,
    DateConfidence sowingDateConfidence = DateConfidence.exact,
  }) {
    final now = DateTime(2025, 6, 1);
    return DeviceCropContext(
      deviceId: deviceId,
      cropCategoryId: 'grain',
      cropId: cropId,
      profileId: profileId,
      lifecycleStatus: lifecycleStatus,
      sowingDateConfidence: sowingDateConfidence,
      catalogVersion: 'v1',
      source: CropConfigSource.demo,
      configuredAt: now,
      updatedAt: now,
      sowingDate: sowingDate,
      plannedSowingDate: plannedSowingDate,
    );
  }

  SeedInstall _makeSeedPlanted({
    String deviceId = 'dev-1',
    String cropKey = 'maize',
    String varietyAlias = 'DK-2069',
  }) {
    return SeedInstall.planted(
      deviceId: deviceId,
      cropKey: cropKey,
      varietyAlias: varietyAlias,
      sowingDate: DateTime(2025, 5, 15),
    );
  }

  SeedInstall _makeSeedSkip({
    String deviceId = 'dev-1',
    String cropKey = 'maize',
  }) {
    return SeedInstall.skip(deviceId: deviceId, cropKey: cropKey);
  }

  // ── 1. normalizedCropId ────────────────────────────────────────────────

  group('normalizedCropId', () {
    test('maize stays maize', () {
      expect(presenter.normalizedCropId('maize'), 'maize');
    });

    test('corn maps to maize', () {
      expect(presenter.normalizedCropId('corn'), 'maize');
    });

    test('MAIZ (case-insensitive) maps to maize', () {
      expect(presenter.normalizedCropId('MAIZ'), 'maize');
    });

    test('maiz maps to maize', () {
      expect(presenter.normalizedCropId('maiz'), 'maize');
    });

    test('bean maps to bean', () {
      expect(presenter.normalizedCropId('bean'), 'bean');
    });

    test('frijol maps to bean', () {
      expect(presenter.normalizedCropId('frijol'), 'bean');
    });

    test('wheat maps to wheat', () {
      expect(presenter.normalizedCropId('wheat'), 'wheat');
    });

    test('trigo maps to wheat', () {
      expect(presenter.normalizedCropId('trigo'), 'wheat');
    });

    test('null input returns empty string', () {
      expect(presenter.normalizedCropId(null), '');
    });

    test('empty string returns empty string', () {
      expect(presenter.normalizedCropId(''), '');
    });

    test('unknown crop returns itself lowercased', () {
      expect(presenter.normalizedCropId('sorghum'), 'sorghum');
    });
  });

  // ── 2. cropDisplayName ─────────────────────────────────────────────────

  group('cropDisplayName', () {
    test('maize displays as Maíz', () {
      expect(presenter.cropDisplayName('maize'), 'Maíz');
    });

    test('bean displays as Frijol', () {
      expect(presenter.cropDisplayName('bean'), 'Frijol');
    });

    test('wheat displays as Trigo', () {
      expect(presenter.cropDisplayName('wheat'), 'Trigo');
    });

    test('barley displays as Cebada', () {
      expect(presenter.cropDisplayName('barley'), 'Cebada');
    });

    test('unknown crop falls back to Cultivo', () {
      expect(presenter.cropDisplayName('sorghum'), 'Cultivo');
    });
  });

  // ── 3. isLegacyGenericAlias ────────────────────────────────────────────

  group('isLegacyGenericAlias', () {
    test('"generic" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generic'), isTrue);
    });

    test('"genérico" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('genérico'), isTrue);
    });

    test('"generico" (no accent) is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generico'), isTrue);
    });

    test('"generic_maize" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generic_maize'), isTrue);
    });

    test('"generic_corn" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generic_corn'), isTrue);
    });

    test('"generic_bean" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generic_bean'), isTrue);
    });

    test('"generic_wheat" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generic_wheat'), isTrue);
    });

    test('"generic_barley" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('generic_barley'), isTrue);
    });

    test('"perfil genérico" is a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('perfil genérico'), isTrue);
    });

    test('"DK-2069" is NOT a legacy generic alias', () {
      expect(presenter.isLegacyGenericAlias('DK-2069'), isFalse);
    });

    test('empty string is treated as generic', () {
      expect(presenter.isLegacyGenericAlias(''), isTrue);
    });

    test('whitespace-only string is treated as generic', () {
      expect(presenter.isLegacyGenericAlias('   '), isTrue);
    });

    test('case insensitive: "GENERIC" is generic', () {
      expect(presenter.isLegacyGenericAlias('GENERIC'), isTrue);
    });
  });

  // ── 4. isFallowMode ───────────────────────────────────────────────────

  group('isFallowMode', () {
    test('returns true when cropContext has fallow lifecycle', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.fallow,
      );
      expect(
        presenter.isFallowMode(cropContext: ctx, seed: null),
        isTrue,
      );
    });

    test('returns false when cropContext has planted lifecycle', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.planted,
      );
      expect(
        presenter.isFallowMode(cropContext: ctx, seed: null),
        isFalse,
      );
    });

    test('returns false when cropContext has planned lifecycle', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.planned,
      );
      expect(
        presenter.isFallowMode(cropContext: ctx, seed: null),
        isFalse,
      );
    });

    test('returns true with legacy seed skip status and no cropContext', () {
      final seed = _makeSeedSkip();
      expect(
        presenter.isFallowMode(cropContext: null, seed: seed),
        isTrue,
      );
    });

    test('returns false with legacy seed planted status and no cropContext',
        () {
      final seed = _makeSeedPlanted();
      expect(
        presenter.isFallowMode(cropContext: null, seed: seed),
        isFalse,
      );
    });

    test('cropContext takes precedence over seed', () {
      // Context says planted, seed says skip.
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.planted,
      );
      final seed = _makeSeedSkip();
      expect(
        presenter.isFallowMode(cropContext: ctx, seed: seed),
        isFalse,
      );
    });

    test('returns false when both are null', () {
      expect(
        presenter.isFallowMode(cropContext: null, seed: null),
        isFalse,
      );
    });
  });

  // ── 5. hasConfiguredCrop ──────────────────────────────────────────────

  group('hasConfiguredCrop', () {
    test('returns false when both are null', () {
      expect(
        presenter.hasConfiguredCrop(cropContext: null, seed: null),
        isFalse,
      );
    });

    test('returns true when seed is provided', () {
      final seed = _makeSeedPlanted();
      expect(
        presenter.hasConfiguredCrop(cropContext: null, seed: seed),
        isTrue,
      );
    });

    test('returns true when cropContext is provided', () {
      final ctx = _makeCropContext();
      expect(
        presenter.hasConfiguredCrop(cropContext: ctx, seed: null),
        isTrue,
      );
    });

    test('returns true when both are provided', () {
      final ctx = _makeCropContext();
      final seed = _makeSeedPlanted();
      expect(
        presenter.hasConfiguredCrop(cropContext: ctx, seed: seed),
        isTrue,
      );
    });
  });

  // ── 6. cropHeadline ───────────────────────────────────────────────────

  group('cropHeadline', () {
    test('returns "Sin cultivo configurado" when no crop', () {
      expect(
        presenter.cropHeadline(cropContext: null, seed: null),
        'Sin cultivo configurado',
      );
    });

    test('returns "Descanso del suelo" when fallow via context', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.fallow,
      );
      expect(
        presenter.cropHeadline(cropContext: ctx, seed: null),
        'Descanso del suelo',
      );
    });

    test('returns "Descanso del suelo" when fallow via legacy seed skip', () {
      final seed = _makeSeedSkip();
      expect(
        presenter.cropHeadline(cropContext: null, seed: seed),
        'Descanso del suelo',
      );
    });

    test('includes crop label when crop is configured', () {
      final ctx = _makeCropContext(
        cropId: 'maize',
        lifecycleStatus: CropLifecycleStatus.planted,
      );
      final headline = presenter.cropHeadline(cropContext: ctx, seed: null);
      expect(headline, contains('Maíz'));
    });
  });

  // ── 7. cropStageLabel ─────────────────────────────────────────────────

  group('cropStageLabel', () {
    test('returns "Pendiente" when no crop configured', () {
      expect(
        presenter.cropStageLabel(cropContext: null, seed: null),
        'Pendiente',
      );
    });

    test('returns "Descanso del suelo" when fallow via context', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.fallow,
      );
      expect(
        presenter.cropStageLabel(cropContext: ctx, seed: null),
        'Descanso del suelo',
      );
    });

    test('returns "Ya sembrado" when planted via context', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.planted,
      );
      expect(
        presenter.cropStageLabel(cropContext: ctx, seed: null),
        'Ya sembrado',
      );
    });

    test('returns "Aún no siembro" when planned via context', () {
      final ctx = _makeCropContext(
        lifecycleStatus: CropLifecycleStatus.planned,
      );
      expect(
        presenter.cropStageLabel(cropContext: ctx, seed: null),
        'Aún no siembro',
      );
    });

    test('returns "Ya sembrado" via legacy seed planted', () {
      final seed = _makeSeedPlanted();
      expect(
        presenter.cropStageLabel(cropContext: null, seed: seed),
        'Ya sembrado',
      );
    });

    test('returns "Aún no siembro" via legacy seed planned', () {
      final seed = SeedInstall.planned(
        deviceId: 'dev-1',
        cropKey: 'maize',
        varietyAlias: 'DK-2069',
        plannedDate: DateTime(2025, 7, 1),
      );
      expect(
        presenter.cropStageLabel(cropContext: null, seed: seed),
        'Aún no siembro',
      );
    });

    test('returns "Descanso del suelo" via legacy seed skip', () {
      final seed = _makeSeedSkip();
      expect(
        presenter.cropStageLabel(cropContext: null, seed: seed),
        'Descanso del suelo',
      );
    });
  });

  // ── 8. healthFromMetrics ──────────────────────────────────────────────

  group('healthFromMetrics', () {
    test('all good metrics return "good"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Buena',
          sensorsLabel: 'OK',
          systemLabel: 'Estable',
        ),
        'good',
      );
    });

    test('low battery (< 10) returns "bad"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 5,
          signalLabel: 'Buena',
          sensorsLabel: 'OK',
          systemLabel: 'Estable',
        ),
        'bad',
      );
    });

    test('medium battery (10-44) returns "warn"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 30,
          signalLabel: 'Buena',
          sensorsLabel: 'OK',
          systemLabel: 'Estable',
        ),
        'warn',
      );
    });

    test('medium signal returns "warn"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Media',
          sensorsLabel: 'OK',
          systemLabel: 'Estable',
        ),
        'warn',
      );
    });

    test('"Sin señal" signal returns "bad"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Sin señal',
          sensorsLabel: 'OK',
          systemLabel: 'Estable',
        ),
        'bad',
      );
    });

    test('sensor "Fallo" returns "bad"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Buena',
          sensorsLabel: 'Fallo',
          systemLabel: 'Estable',
        ),
        'bad',
      );
    });

    test('sensor "Inestable" returns "warn"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Buena',
          sensorsLabel: 'Inestable',
          systemLabel: 'Estable',
        ),
        'warn',
      );
    });

    test('system "Crítico" returns "bad"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Buena',
          sensorsLabel: 'OK',
          systemLabel: 'Crítico',
        ),
        'bad',
      );
    });

    test('system "Atención" returns "warn"', () {
      expect(
        presenter.healthFromMetrics(
          batteryPct: 92,
          signalLabel: 'Buena',
          sensorsLabel: 'OK',
          systemLabel: 'Atención',
        ),
        'warn',
      );
    });

    test('worst severity wins (multiple issues)', () {
      // Battery is warn (30), signal is bad (Sin señal) => "bad"
      expect(
        presenter.healthFromMetrics(
          batteryPct: 30,
          signalLabel: 'Sin señal',
          sensorsLabel: 'OK',
          systemLabel: 'Estable',
        ),
        'bad',
      );
    });
  });

  // ── 9. stableHash ────────────────────────────────────────────────────

  group('stableHash', () {
    test('same input produces same output', () {
      expect(presenter.stableHash('device-abc'), presenter.stableHash('device-abc'));
    });

    test('different inputs produce different outputs', () {
      expect(
        presenter.stableHash('device-abc'),
        isNot(presenter.stableHash('device-xyz')),
      );
    });

    test('empty string returns 0', () {
      expect(presenter.stableHash(''), 0);
    });

    test('result is non-negative', () {
      expect(presenter.stableHash('anything'), greaterThanOrEqualTo(0));
    });
  });

  // ── 10. clampInt ─────────────────────────────────────────────────────

  group('clampInt', () {
    test('value within range is returned unchanged', () {
      expect(presenter.clampInt(50, 0, 100), 50);
    });

    test('value below min returns min', () {
      expect(presenter.clampInt(-5, 0, 100), 0);
    });

    test('value above max returns max', () {
      expect(presenter.clampInt(150, 0, 100), 100);
    });

    test('value equal to min returns min', () {
      expect(presenter.clampInt(0, 0, 100), 0);
    });

    test('value equal to max returns max', () {
      expect(presenter.clampInt(100, 0, 100), 100);
    });
  });
}
