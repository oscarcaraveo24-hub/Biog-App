class OnboardingDraft {
  final String? locationSource;
  final String? locationLabel;
  final double? geoLat;
  final double? geoLng;
  final String? timezone;
  final String? cultivationScale;
  final String? cropCategory;
  final String? cropId;
  final String? brandId;
  final String? varietyId;
  final String? varietyAlias;
  final String? treeProductionStatusId;
  final String? stage;
  final String? treeAnchorOptionId;
  final DateTime? selectedDate;
  final bool useFlexibleDate;

  const OnboardingDraft({
    this.locationSource,
    this.locationLabel,
    this.geoLat,
    this.geoLng,
    this.timezone,
    this.cultivationScale,
    this.cropCategory,
    this.cropId,
    this.brandId,
    this.varietyId,
    this.varietyAlias,
    this.treeProductionStatusId,
    this.stage,
    this.treeAnchorOptionId,
    this.selectedDate,
    this.useFlexibleDate = false,
  });

  OnboardingDraft copyWith({
    Object? locationSource = _sentinel,
    Object? locationLabel = _sentinel,
    Object? geoLat = _sentinel,
    Object? geoLng = _sentinel,
    Object? timezone = _sentinel,
    Object? cultivationScale = _sentinel,
    Object? cropCategory = _sentinel,
    Object? cropId = _sentinel,
    Object? brandId = _sentinel,
    Object? varietyId = _sentinel,
    Object? varietyAlias = _sentinel,
    Object? treeProductionStatusId = _sentinel,
    Object? stage = _sentinel,
    Object? treeAnchorOptionId = _sentinel,
    Object? selectedDate = _sentinel,
    bool? useFlexibleDate,
  }) {
    return OnboardingDraft(
      locationSource: identical(locationSource, _sentinel)
          ? this.locationSource
          : locationSource as String?,
      locationLabel: identical(locationLabel, _sentinel)
          ? this.locationLabel
          : locationLabel as String?,
      geoLat: identical(geoLat, _sentinel) ? this.geoLat : geoLat as double?,
      geoLng: identical(geoLng, _sentinel) ? this.geoLng : geoLng as double?,
      timezone: identical(timezone, _sentinel)
          ? this.timezone
          : timezone as String?,
      cultivationScale: identical(cultivationScale, _sentinel)
          ? this.cultivationScale
          : cultivationScale as String?,
      cropCategory: identical(cropCategory, _sentinel)
          ? this.cropCategory
          : cropCategory as String?,
      cropId: identical(cropId, _sentinel) ? this.cropId : cropId as String?,
      brandId: identical(brandId, _sentinel)
          ? this.brandId
          : brandId as String?,
      varietyId: identical(varietyId, _sentinel)
          ? this.varietyId
          : varietyId as String?,
      varietyAlias: identical(varietyAlias, _sentinel)
          ? this.varietyAlias
          : varietyAlias as String?,
      treeProductionStatusId:
          identical(treeProductionStatusId, _sentinel)
              ? this.treeProductionStatusId
              : treeProductionStatusId as String?,
      stage: identical(stage, _sentinel) ? this.stage : stage as String?,
      treeAnchorOptionId: identical(treeAnchorOptionId, _sentinel)
          ? this.treeAnchorOptionId
          : treeAnchorOptionId as String?,
      selectedDate: identical(selectedDate, _sentinel)
          ? this.selectedDate
          : selectedDate as DateTime?,
      useFlexibleDate: useFlexibleDate ?? this.useFlexibleDate,
    );
  }
}

const Object _sentinel = Object();
