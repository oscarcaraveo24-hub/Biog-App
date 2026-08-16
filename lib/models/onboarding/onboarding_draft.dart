class OnboardingDraft {
  final String? locationSource;
  final String? locationLabel;
  final double? geoLat;
  final double? geoLng;
  final String? timezone;
  final String? cultivationScale;

  // ── Tipo de suelo ──────────────────────────────────────────────────────────
  //
  // Va agrupado con ubicación y escala porque es **atributo de la parcela, no
  // del cultivo**: la textura no cambia si mañana se siembra frijol en vez de
  // maíz. Por eso el paso queda antes de la categoría de cultivo y por eso las
  // cascadas de limpieza al cambiar de cultivo NO lo incluyen.

  /// `sandy` | `sandyLoam` | `loam` | `clayLoam` | `clay` | `unknown`.
  /// Nulo mientras el productor no haya pasado por el paso.
  final String? soilTextureId;

  /// `declared` | `guided_estimate` | `unknown`. En el onboarding solo pueden
  /// darse estas tres: las derivadas de equipo o escala no se guardan, se
  /// resuelven en runtime.
  final String? soilTextureSource;

  /// Nombres locales opcionales. No cambian la clasificación hidráulica.
  final List<String> soilLocalDescriptors;

  /// Texto libre de la opción «Otra».
  final String? soilLocalOther;

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

  // ── Equipo emparejado ──────────────────────────────────────────────────────
  //
  // El paso de vinculación guardaba SOLO el nombre en el estado de la pantalla
  // y mostraba «conectado correctamente». El id del hardware, el modelo y la
  // serie se tiraban al suelo, así que todo equipo nacido del onboarding
  // quedaba con `deviceModelId` nulo y un UUID inventado por el teléfono —y sin
  // modelo no hay forma de saber si vive en maceta o en campo—.
  //
  // Ahora viajan en el borrador, que es el contrato entre el wizard y quien
  // crea el dispositivo.

  /// UUID de telemetría que declaró el aparato, si lo trae la etiqueta.
  final String? pairedHardwareId;

  /// `campo` | `huerto` | `maceta`, tal como sale de la serie.
  final String? pairedDeviceModelId;

  final String? pairedDeviceName;

  const OnboardingDraft({
    this.locationSource,
    this.locationLabel,
    this.geoLat,
    this.geoLng,
    this.timezone,
    this.cultivationScale,
    this.soilTextureId,
    this.soilTextureSource,
    this.soilLocalDescriptors = const <String>[],
    this.soilLocalOther,
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
    this.pairedHardwareId,
    this.pairedDeviceModelId,
    this.pairedDeviceName,
  });

  OnboardingDraft copyWith({
    Object? locationSource = _sentinel,
    Object? locationLabel = _sentinel,
    Object? geoLat = _sentinel,
    Object? geoLng = _sentinel,
    Object? timezone = _sentinel,
    Object? cultivationScale = _sentinel,
    Object? soilTextureId = _sentinel,
    Object? soilTextureSource = _sentinel,
    List<String>? soilLocalDescriptors,
    Object? soilLocalOther = _sentinel,
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
    Object? pairedHardwareId = _sentinel,
    Object? pairedDeviceModelId = _sentinel,
    Object? pairedDeviceName = _sentinel,
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
      soilTextureId: identical(soilTextureId, _sentinel)
          ? this.soilTextureId
          : soilTextureId as String?,
      soilTextureSource: identical(soilTextureSource, _sentinel)
          ? this.soilTextureSource
          : soilTextureSource as String?,
      soilLocalDescriptors: soilLocalDescriptors ?? this.soilLocalDescriptors,
      soilLocalOther: identical(soilLocalOther, _sentinel)
          ? this.soilLocalOther
          : soilLocalOther as String?,
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
      pairedHardwareId: identical(pairedHardwareId, _sentinel)
          ? this.pairedHardwareId
          : pairedHardwareId as String?,
      pairedDeviceModelId: identical(pairedDeviceModelId, _sentinel)
          ? this.pairedDeviceModelId
          : pairedDeviceModelId as String?,
      pairedDeviceName: identical(pairedDeviceName, _sentinel)
          ? this.pairedDeviceName
          : pairedDeviceName as String?,
    );
  }
}

const Object _sentinel = Object();
