// lib/core/crops/catalog/crop_catalog_models.dart

class CropCategoryEntry {
  final String id;
  final String label;
  final String? subtitle;
  final bool enabled;

  const CropCategoryEntry({
    required this.id,
    required this.label,
    this.subtitle,
    this.enabled = true,
  });
}

// ---------------------------------------------------------------------------
// Brand — solo para maíz en v1; los demás cultivos no usan brandId.
// ---------------------------------------------------------------------------
class CropBrandEntry {
  final String id;
  final String label;
  final String cropId;
  final bool enabled;

  const CropBrandEntry({
    required this.id,
    required this.label,
    required this.cropId,
    this.enabled = true,
  });
}

// ---------------------------------------------------------------------------
// Variety — ahora tiene brand + market type + use type (opcionales, backward
// compat: campos null en cultivos que no los usan).
//
// marketTypeId: 'white' | 'yellow' | 'sweet'   (solo maíz)
// useTypeId:    'grain' | 'forage' | 'elote'    (solo maíz)
// brandId:      id del CropBrandEntry            (solo maíz)
// ---------------------------------------------------------------------------
class CropVarietyEntry {
  final String id;
  final String label;
  final String cropId;
  final String? subtitle;
  final String? defaultProfileId;
  final List<String> aliases;
  final bool enabled;
  final bool isGeneric;

  // Maize-specific metadata (null en otros cultivos)
  final String? brandId;
  final String? marketTypeId;
  final String? useTypeId;

  const CropVarietyEntry({
    required this.id,
    required this.label,
    required this.cropId,
    this.subtitle,
    this.defaultProfileId,
    this.aliases = const <String>[],
    this.enabled = true,
    this.isGeneric = false,
    this.brandId,
    this.marketTypeId,
    this.useTypeId,
  });
}

class CropProfileEntry {
  final String id;
  final String label;
  final String cropId;
  final String? subtitle;
  final List<String> aliases;
  final bool enabled;

  const CropProfileEntry({
    required this.id,
    required this.label,
    required this.cropId,
    this.subtitle,
    this.aliases = const <String>[],
    this.enabled = true,
  });
}

class CropCalendarEntry {
  final String id;
  final String label;
  final String cropId;
  final String? subtitle;
  final bool enabled;
  final bool isDefault;

  const CropCalendarEntry({
    required this.id,
    required this.label,
    required this.cropId,
    this.subtitle,
    this.enabled = true,
    this.isDefault = false,
  });
}

class CropCatalogEntry {
  final String cropId;
  final String categoryId;
  final String label;
  final String? subtitle;
  final bool enabled;
  final String? defaultProfileId;
  final String? defaultCalendarId;
  final List<CropBrandEntry> brands;
  final List<CropVarietyEntry> varieties;
  final List<CropProfileEntry> profiles;
  final List<CropCalendarEntry> calendars;

  const CropCatalogEntry({
    required this.cropId,
    required this.categoryId,
    required this.label,
    required this.enabled,
    this.subtitle,
    this.defaultProfileId,
    this.defaultCalendarId,
    this.brands = const <CropBrandEntry>[],
    this.varieties = const <CropVarietyEntry>[],
    this.profiles = const <CropProfileEntry>[],
    this.calendars = const <CropCalendarEntry>[],
  });
}
