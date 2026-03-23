import 'package:bio_g/core/crops/barley/barley_catalog.dart';
import 'package:bio_g/core/crops/bean/bean_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/core/crops/oat/oat_catalog.dart';
import 'package:bio_g/core/crops/wheat/wheat_catalog.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';
import 'package:bio_g/widgets/seeds/maize_profiles.dart';
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
  // Legacy IDs kept for backward compat (may exist in SharedPrefs).
  static const String maizeDemoVarietyId = 'dk_2069';
  static const String maizeGenericVarietyId = 'generic_maize';
  static const String maizeGenericProfileId = kMaizeGenericProfileId;

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
    // ── MAÍZ ─────────────────────────────────────────────────────────────────
    CropCatalogEntry(
      cropId: maizeCropId,
      categoryId: grainCategoryId,
      label: 'Maíz',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kMzgGenB,
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
      ],
    ),

    // ── TRIGO ─────────────────────────────────────────────────────────────────
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
      ],
    ),

    // ── CEBADA ────────────────────────────────────────────────────────────────
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
      ],
    ),

    // ── AVENA ─────────────────────────────────────────────────────────────────
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
      ],
    ),

    // ── FRIJOL ────────────────────────────────────────────────────────────────
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
      ],
    ),
  ];

  // ── Lookup helpers ──────────────────────────────────────────────────────────

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

  // ── Variety lookup ──────────────────────────────────────────────────────────

  static CropVarietyEntry? varietyById(String cropId, String? varietyId) {
    final normalizedVarietyId = _normalize(varietyId);
    if (normalizedVarietyId == null) return null;

    // Fast path: maize uses maize_catalog helpers directly
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

    // Fast path: maize
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

  // ── Profile lookup ──────────────────────────────────────────────────────────

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

  // ── Resolution helpers ──────────────────────────────────────────────────────

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

  /// Resolves the canonical profile ID to use for the engine.
  ///
  /// Resolution order:
  ///   1. [explicitProfileId] — if valid in this crop's profile list.
  ///   2. [varietyId]'s defaultProfileId — if valid in this crop's profile list.
  ///   3. Crop-level defaultProfileId.
  ///   4. `{cropId}_generic` synthetic fallback.
  ///   5. First profile in the list.
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

  // ── Brand helpers (maize only) ──────────────────────────────────────────────

  /// Returns all brands registered for [cropId]. Only maize has brands in v1.
  static List<CropBrandEntry> brandsForCrop(String cropId) {
    final crop = cropById(cropId);
    return crop?.brands ?? const <CropBrandEntry>[];
  }

  /// Varieties filtered by brand + optional marketTypeId.
  static List<CropVarietyEntry> maizeVarietiesForBrand(
    String brandId, {
    String? marketTypeId,
  }) {
    if (marketTypeId != null) {
      return maizeVarietiesByBrandAndMarket(brandId, marketTypeId);
    }
    return maizeVarietiesByBrand(brandId);
  }

  // ── Crop key canonicalisation ───────────────────────────────────────────────

  /// Canonical crop key from any known alias (e.g. 'corn' → 'maize').
  ///
  /// Returns empty string for null/blank input. Non-nullable so callers
  /// can compare directly without `?` chains.
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

  /// Like [canonicalCropKey] but returns null for null/blank input.
  static String? canonicalCropKeyOrNull(String? raw) {
    final result = canonicalCropKey(raw);
    return result.isEmpty ? null : result;
  }

  /// Display name in Spanish for a canonical crop key.
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

  // ── Normalisation ───────────────────────────────────────────────────────────

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }
}
