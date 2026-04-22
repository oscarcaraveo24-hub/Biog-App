import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/barley/barley_catalog.dart';
import 'package:bio_g/core/crops/bean/bean_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/core/crops/oat/oat_catalog.dart';
import 'package:bio_g/core/crops/wheat/wheat_catalog.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';
import 'package:bio_g/widgets/seeds/wheat_profiles.dart';

class CropCatalog {
  static const String version = 'v1';

  static const String grainCategoryId = 'grain';

  static const String maizeCropId = 'maize';
  static const String wheatCropId = 'wheat';
  static const String barleyCropId = 'barley';
  static const String beanCropId = 'bean';
  static const String oatCropId = 'oat';

  // ── Maize catalog constants ─────────────────────────────────────────────────
  static const String maizeDemoVarietyId = 'dekalb_dk2069_grain';
  static const String maizeGenericVarietyId = 'generic_maize_white_grain';
  static const String maizeDefaultProfileId = 'mzg_gen_b';
  static const String maizeGenericProfileId = 'maize_generic';

  static const String maizeDefaultCalendarId = 'maize_default';
  static const String beanDefaultCalendarId = kBeanDefaultCalendarId;
  static const String oatDefaultCalendarId = kOatDefaultCalendarId;
  static const String barleyDefaultCalendarId = kBarleyDefaultCalendarId;
  static const String wheatDefaultCalendarId = kWheatDefaultCalendarId;

  // ── Categories ──────────────────────────────────────────────────────────────

  static const List<CropCategoryEntry> categories = <CropCategoryEntry>[
    CropCategoryEntry(
      id: grainCategoryId,
      label: 'Grano',
      subtitle: 'Cereales y leguminosas de ciclo agrícola',
      enabled: true,
    ),
  ];

  // ── Crops ───────────────────────────────────────────────────────────────────

  static const List<CropCatalogEntry> crops = <CropCatalogEntry>[
    CropCatalogEntry(
      cropId: maizeCropId,
      categoryId: grainCategoryId,
      label: 'Maíz',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: maizeDefaultProfileId,
      defaultCalendarId: maizeDefaultCalendarId,
      brands: maizeBrands,
      varieties: maizeVarieties,
      profiles: maizeProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: maizeDefaultCalendarId,
          label: 'Calendario base',
          cropId: maizeCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'maize_temporal',
          label: 'Temporal',
          cropId: maizeCropId,
          subtitle: 'Ajusta humedad y fenología para lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'maize_riego',
          label: 'Riego',
          cropId: maizeCropId,
          subtitle: 'Mayor potencial y ajuste nutricional',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: wheatCropId,
      categoryId: grainCategoryId,
      label: 'Trigo',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kTrGen,
      defaultCalendarId: wheatDefaultCalendarId,
      varieties: wheatVarieties,
      profiles: wheatProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: wheatDefaultCalendarId,
          label: 'Calendario base',
          cropId: wheatCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'wheat_temporal',
          label: 'Temporal',
          cropId: wheatCropId,
          subtitle: 'Ajusta targets para secano / lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'wheat_riego',
          label: 'Riego',
          cropId: wheatCropId,
          subtitle: 'Escenario de mayor potencial',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: barleyCropId,
      categoryId: grainCategoryId,
      label: 'Cebada',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kCbGen,
      defaultCalendarId: barleyDefaultCalendarId,
      varieties: barleyVarieties,
      profiles: barleyProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: barleyDefaultCalendarId,
          label: 'Calendario base',
          cropId: barleyCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'barley_temporal',
          label: 'Temporal',
          cropId: barleyCropId,
          subtitle: 'Ajusta targets para secano / lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'barley_riego',
          label: 'Riego',
          cropId: barleyCropId,
          subtitle: 'Escenario de mayor potencial',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: oatCropId,
      categoryId: grainCategoryId,
      label: 'Avena',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kAvGen,
      defaultCalendarId: oatDefaultCalendarId,
      brands: oatBrands,
      varieties: oatVarieties,
      profiles: oatProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: oatDefaultCalendarId,
          label: 'Calendario base',
          cropId: oatCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'oat_temporal',
          label: 'Temporal',
          cropId: oatCropId,
          subtitle: 'Ajusta targets para secano / lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'oat_riego',
          label: 'Riego',
          cropId: oatCropId,
          subtitle: 'Escenario de mayor potencial',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: beanCropId,
      categoryId: grainCategoryId,
      label: 'Frijol',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kFjGen,
      defaultCalendarId: beanDefaultCalendarId,
      varieties: beanVarieties,
      profiles: beanProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: beanDefaultCalendarId,
          label: 'Calendario base',
          cropId: beanCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'bean_temporal',
          label: 'Temporal',
          cropId: beanCropId,
          subtitle: 'Ajusta targets para lluvia y menor disponibilidad',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'bean_riego',
          label: 'Riego',
          cropId: beanCropId,
          subtitle: 'Escenario de mayor estabilidad hídrica',
          enabled: true,
        ),
      ],
    ),
  ];

  static CropCategoryEntry? categoryById(String? categoryId) {
    final normalized = _normalize(categoryId);
    if (normalized == null) return null;

    for (final category in categories) {
      if (_normalize(category.id) == normalized) return category;
    }
    return null;
  }

  static CropCatalogEntry? cropById(String? cropId) {
    final normalized = _normalize(cropId);
    if (normalized == null) return null;

    for (final crop in crops) {
      if (_normalize(crop.cropId) == normalized) return crop;
    }
    return null;
  }

  static List<CropCatalogEntry> cropsByCategory(
    String categoryId, {
    bool enabledOnly = false,
  }) {
    final normalized = _normalize(categoryId);
    if (normalized == null) return const <CropCatalogEntry>[];

    return crops
        .where((crop) {
          final matchesCategory = _normalize(crop.categoryId) == normalized;
          if (!matchesCategory) return false;
          if (enabledOnly && !crop.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static List<CropVarietyEntry> varietiesForCrop(
    String cropId, {
    bool enabledOnly = false,
  }) {
    final crop = cropById(cropId);
    if (crop == null) return const <CropVarietyEntry>[];

    return crop.varieties
        .where((variety) {
          if (enabledOnly && !variety.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static List<CropProfileEntry> profilesForCrop(
    String cropId, {
    bool enabledOnly = false,
  }) {
    final crop = cropById(cropId);
    if (crop == null) return const <CropProfileEntry>[];

    return crop.profiles
        .where((profile) {
          if (enabledOnly && !profile.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static List<CropCalendarEntry> calendarsForCrop(
    String cropId, {
    bool enabledOnly = false,
  }) {
    final crop = cropById(cropId);
    if (crop == null) return const <CropCalendarEntry>[];

    return crop.calendars
        .where((calendar) {
          if (enabledOnly && !calendar.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static CropVarietyEntry? varietyById(String cropId, String? varietyId) {
    final normalizedVarietyId = _normalize(varietyId);
    if (normalizedVarietyId == null) return null;

    if (_normalize(cropId) == maizeCropId) {
      final direct = maizeVarietyById(varietyId!);
      if (direct != null) return direct;
    }

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final variety in crop.varieties) {
      if (_normalize(variety.id) == normalizedVarietyId) return variety;
    }
    return null;
  }

  static CropVarietyEntry? varietyByAlias(String cropId, String? alias) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias == null) return null;

    if (_normalize(cropId) == maizeCropId) {
      final byAlias = maizeVarietyByAlias(alias!);
      if (byAlias != null) return byAlias;
    }

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final variety in crop.varieties) {
      if (_normalize(variety.label) == normalizedAlias) return variety;

      for (final candidate in variety.aliases) {
        if (_normalize(candidate) == normalizedAlias) {
          return variety;
        }
      }
    }

    return null;
  }

  static CropVarietyEntry? varietyByAny(String cropId, String? value) {
    return varietyById(cropId, value) ?? varietyByAlias(cropId, value);
  }

  static CropProfileEntry? profileById(String cropId, String? profileId) {
    final normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId == null) return null;

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final profile in crop.profiles) {
      if (_normalize(profile.id) == normalizedProfileId) return profile;
    }
    return null;
  }

  static CropProfileEntry? profileByAlias(String cropId, String? alias) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias == null) return null;

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final profile in crop.profiles) {
      if (_normalize(profile.label) == normalizedAlias) return profile;

      for (final candidate in profile.aliases) {
        if (_normalize(candidate) == normalizedAlias) {
          return profile;
        }
      }
    }

    return null;
  }

  static CropProfileEntry? profileByAny(String cropId, String? value) {
    return profileById(cropId, value) ?? profileByAlias(cropId, value);
  }

  static String? resolveVarietyId({required String cropId, String? rawValue}) {
    return varietyByAny(cropId, rawValue)?.id;
  }

  static String? defaultCalendarIdForCrop(String cropId) {
    final crop = cropById(cropId);
    if (crop == null) return null;

    final explicitDefault = crop.defaultCalendarId;
    if (explicitDefault != null && explicitDefault.trim().isNotEmpty) {
      return explicitDefault;
    }

    for (final calendar in crop.calendars) {
      if (calendar.isDefault) return calendar.id;
    }

    if (crop.calendars.isNotEmpty) {
      return crop.calendars.first.id;
    }

    return null;
  }

  static String resolveProfileId({
    required String cropId,
    String? varietyId,
    String? explicitProfileId,
  }) {
    final crop = cropById(cropId);

    final explicitProfile = profileByAny(cropId, explicitProfileId);
    if (explicitProfile != null) {
      return explicitProfile.id;
    }

    final variety = varietyByAny(cropId, varietyId);
    final varietyDefaultProfileId = variety?.defaultProfileId;
    if (varietyDefaultProfileId != null &&
        profileById(cropId, varietyDefaultProfileId) != null) {
      return varietyDefaultProfileId;
    }

    final cropDefaultProfileId = crop?.defaultProfileId;
    if (cropDefaultProfileId != null &&
        profileById(cropId, cropDefaultProfileId) != null) {
      return cropDefaultProfileId;
    }

    final genericProfileId = '${cropId}_generic';
    if (profileById(cropId, genericProfileId) != null) {
      return genericProfileId;
    }

    if (crop != null && crop.profiles.isNotEmpty) {
      return crop.profiles.first.id;
    }

    return genericProfileId;
  }

  static List<CropBrandEntry> brandsForCrop(String cropId) {
    final crop = cropById(cropId);
    return crop?.brands ?? const <CropBrandEntry>[];
  }

  static List<CropVarietyEntry> maizeVarietiesForBrand(
    String brandId, {
    String? marketTypeId,
  }) {
    if (marketTypeId != null) {
      return maizeVarietiesByBrandAndMarket(brandId, marketTypeId);
    }
    return maizeVarietiesByBrand(brandId);
  }

  static String? resolveCalendarId({
    required String cropId,
    String? requested,
    String? previousCalendarId,
  }) {
    final canonicalCropId = canonicalCropKey(cropId);
    if (canonicalCropId.isEmpty) return null;

    final requestedId = _canonicalCalendarId(
      cropId: canonicalCropId,
      raw: requested,
    );
    if (requestedId != null) return requestedId;

    final previousId = _canonicalCalendarId(
      cropId: canonicalCropId,
      raw: previousCalendarId,
    );
    if (previousId != null) return previousId;

    return defaultCalendarIdForCrop(canonicalCropId);
  }

  static int phenologyOffsetDaysForCalendar({
    required String cropId,
    String? calendarId,
  }) {
    final canonical = _canonicalCalendarId(cropId: cropId, raw: calendarId);
    if (canonical == null) return 0;

    if (canonical.endsWith('_temporal')) return -4;
    if (canonical.endsWith('_riego')) return 4;
    return 0;
  }

  static StageTargets adjustTargetsForCalendar({
    required String cropId,
    required String? calendarId,
    required String stageKey,
    required StageTargets baseTargets,
  }) {
    final canonical = _canonicalCalendarId(cropId: cropId, raw: calendarId);
    if (canonical == null || canonical.endsWith('_default')) {
      return baseTargets;
    }

    final bool isTemporal = canonical.endsWith('_temporal');
    final bool isIrrigated = canonical.endsWith('_riego');
    if (!isTemporal && !isIrrigated) return baseTargets;

    final String normalizedStage = stageKey.trim().toLowerCase();
    final bool isVegetative = _stageMatches(normalizedStage, const <String>[
      'germ',
      'emerg',
      'veg',
      'tiller',
      'elong',
    ]);
    final bool isReproductive = _stageMatches(normalizedStage, const <String>[
      'boot',
      'head',
      'flower',
      'grain',
      'fill',
      'maturity',
      'harvest',
      'tassel',
      'silk',
      'r1',
      'r2',
      'r3',
      'r4',
      'r5',
    ]);

    final double moistureDelta = isTemporal ? 2.0 : 0.0;
    final double resistanceDelta = isTemporal ? -0.10 : 0.05;
    final double nDelta = isVegetative ? (isIrrigated ? 4.0 : -4.0) : 0.0;
    final double kDelta = isReproductive ? (isIrrigated ? 3.0 : -3.0) : 0.0;

    return baseTargets.copyWith(
      moistureRaw: _shiftRange(
        baseTargets.moistureRaw,
        moistureDelta,
        min: 0.0,
        max: 100.0,
      ),
      resistance: _shiftRange(
        baseTargets.resistance,
        resistanceDelta,
        min: -1.0,
        max: 4.0,
      ),
      nIndex: _shiftRange(baseTargets.nIndex, nDelta, min: 0.0, max: 100.0),
      kIndex: _shiftRange(baseTargets.kIndex, kDelta, min: 0.0, max: 100.0),
      nSoilPpmRange: _shiftComparableRange(
        cropId: cropId,
        nutrient: AgroMetricKey.n,
        baseRange: baseTargets.nSoilPpmRange,
        deltaIndex: nDelta,
      ),
      kSoilPpmRange: _shiftComparableRange(
        cropId: cropId,
        nutrient: AgroMetricKey.k,
        baseRange: baseTargets.kSoilPpmRange,
        deltaIndex: kDelta,
      ),
    );
  }

  static AgroRange? _shiftComparableRange({
    required String cropId,
    required AgroMetricKey nutrient,
    required AgroRange? baseRange,
    required double deltaIndex,
  }) {
    if (baseRange == null) return null;
    if (deltaIndex.abs() < 0.0001) return baseRange;

    final double cap = NpkCaps.forCropMetric(cropKey: cropId, metricKey: nutrient);
    final double deltaPpm = (deltaIndex / 100.0) * cap;

    return _shiftRange(baseRange, deltaPpm, min: 0.0, max: cap * 1.25);
  }

  static bool isGenericAlias(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ||
        normalized == 'generic' ||
        normalized == 'genérico' ||
        normalized == 'generico' ||
        normalized == 'perfil genérico' ||
        normalized == 'generic_maize' ||
        normalized == 'generic_corn' ||
        normalized == 'generic_bean' ||
        normalized == 'generic_wheat' ||
        normalized == 'generic_barley' ||
        normalized == 'generic_oat' ||
        normalized.startsWith('generic_');
  }

  static bool isGenericProfileId(String? profileId) {
    final normalized = profileId?.trim().toLowerCase() ?? '';
    return normalized.isNotEmpty &&
        (normalized.endsWith('_generic') ||
            normalized == 'maize_generic' ||
            normalized == 'mzg_gen_b' ||
            normalized == 'mzg_gen_a' ||
            normalized == 'mzf_gen' ||
            normalized == 'mze_gen' ||
            normalized == 'fj_gen' ||
            normalized == 'tr_gen' ||
            normalized == 'cb_gen' ||
            normalized == 'av_gen');
  }

  static String? _canonicalCalendarId({
    required String cropId,
    required String? raw,
  }) {
    final normalizedCropId = canonicalCropKeyOrNull(cropId);
    final normalized = _normalize(raw);
    if (normalizedCropId == null || normalized == null) return null;

    final explicit = calendarsForCrop(normalizedCropId)
        .map((calendar) => _normalize(calendar.id))
        .whereType<String>()
        .firstWhere((calendarId) => calendarId == normalized, orElse: () => '');
    if (explicit.isNotEmpty) return explicit;

    return switch (normalized) {
      'default' ||
      'base' ||
      'general' ||
      'general_base' => defaultCalendarIdForCrop(normalizedCropId),
      'temporal' || 'rainfed' || 'secano' => '${normalizedCropId}_temporal',
      'riego' || 'irrigated' => '${normalizedCropId}_riego',
      _ => null,
    };
  }

  static bool _stageMatches(String stageKey, List<String> patterns) {
    for (final pattern in patterns) {
      if (stageKey.contains(pattern)) return true;
    }
    return false;
  }

  static AgroRange _shiftRange(
    AgroRange range,
    double delta, {
    required double min,
    required double max,
  }) {
    double clampValue(double value) => value.clamp(min, max).toDouble();

    double lowMax = clampValue(range.lowMax + delta);
    double optimalMin = clampValue(range.optimalMin + delta);
    double optimalMax = clampValue(range.optimalMax + delta);
    double highMin = clampValue(range.highMin + delta);

    if (optimalMin < lowMax) optimalMin = lowMax;
    if (optimalMax < optimalMin) optimalMax = optimalMin;
    if (highMin < optimalMax) highMin = optimalMax;

    return AgroRange(
      lowMax: lowMax,
      optimalMin: optimalMin,
      optimalMax: optimalMax,
      highMin: highMin,
    );
  }

  static String canonicalCropKey(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return '';

    return switch (value) {
      'maize' || 'maiz' || 'corn' => maizeCropId,
      'bean' || 'beans' || 'frijol' => beanCropId,
      'wheat' || 'trigo' => wheatCropId,
      'barley' || 'cebada' => barleyCropId,
      'oat' || 'avena' => oatCropId,
      _ => value,
    };
  }

  static String? canonicalCropKeyOrNull(String? raw) {
    final result = canonicalCropKey(raw);
    return result.isEmpty ? null : result;
  }

  static String cropDisplayName(String cropId) {
    return cropById(cropId)?.label ?? _fallbackDisplayName(cropId);
  }

  static String _fallbackDisplayName(String cropId) {
    return switch (cropId) {
      maizeCropId => 'Maíz',
      beanCropId => 'Frijol',
      wheatCropId => 'Trigo',
      barleyCropId => 'Cebada',
      oatCropId => 'Avena',
      _ => 'Cultivo',
    };
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }
}
