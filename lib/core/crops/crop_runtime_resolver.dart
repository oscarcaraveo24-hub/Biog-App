import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/water/moisture_target_resolver.dart';
import 'package:bio_g/core/agro/water/soil_profile_resolver.dart';
import 'package:bio_g/core/crops/cactus/cactus_crop_definition.dart';
import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/succulent/succulent_crop_definition.dart';
import 'package:bio_g/core/crops/aloe/aloe_crop_definition.dart';
import 'package:bio_g/core/crops/agave/agave_crop_definition.dart';
import 'package:bio_g/core/crops/rose/rose_crop_definition.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
import 'package:bio_g/core/crops/tulip/tulip_crop_definition.dart';
import 'package:bio_g/core/crops/seasonal_bulb/seasonal_bulb_crops.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_crop_definition.dart';
import 'package:bio_g/core/crops/marigold/marigold_crop_definition.dart';
import 'package:bio_g/core/crops/annual_ornamental/annual_ornamental_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/agro/guide_agro_score_engine.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/generic/generic_guide.dart';
import 'package:bio_g/core/crops/crop_presentation_resolver.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/core/crops/crop_runtime_snapshot.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/crops/tree_stage_resolver.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

class CropRuntimeResolver {
  CropRuntimeResolver._();

  static CropRuntimeSnapshot resolve({
    required BioGDevice? device,
    required SeedInstall? seed,
    DeviceCropContext? cropContext,
    required BioGTelemetry? live,
    required AlertsState alertsState,
    DateTime? now,
  }) {
    final DateTime today = now ?? DateTime.now();
    final DeviceCropContext? normalizedContext = _normalizeContext(cropContext);
    final SeedInstall? effectiveSeed = normalizedContext != null
        ? SeedInstall.fromDeviceCropContext(normalizedContext)
        : seed;

    final SowingStatus sowingStatus = _resolveSowingStatus(
      seed: effectiveSeed,
      cropContext: normalizedContext,
    );

    final bool hasSeed = effectiveSeed != null || normalizedContext != null;

    final String cropKeyName = _canonicalCropKey(
      normalizedContext?.cropId ?? effectiveSeed?.cropKey,
    );

    // Modo guía general. Se resuelve aquí arriba, antes que nada, porque
    // `isPlanted` depende de él: en guía no hay fecha de siembra que exigir.
    //
    // Se exige `planted` y no un simple "distinto de skip". Ambos wizards
    // guardan la guía como `planted` —no hay pantalla que la deje en
    // `planned`—, pero si un contexto llegara así, `isPlanted` daría false y
    // la pantalla pintaría textos de pre-siembra ("Seco", "Apta") mientras el
    // motor de guía seguía calculando bandas por detrás: dos lecturas
    // distintas del mismo dato. Con esta guarda ese contexto degrada limpio a
    // "sin cultivo interpretable" en vez de contradecirse.
    final bool isGuideRuntime =
        isGuideCropId(cropKeyName) && sowingStatus == SowingStatus.planted;

    final CropDefinition? definition = cropKeyName.isEmpty
        ? null
        : CropRegistry.byKeyName(cropKeyName);

    final CropProfile? profile = _resolveProfile(
      seed: effectiveSeed,
      cropContext: normalizedContext,
      definition: definition,
      cropKeyName: cropKeyName,
      sowingStatus: sowingStatus,
    );

    final DateTime? plantedDate = _resolvePlantedDate(
      seed: effectiveSeed,
      cropContext: normalizedContext,
    );

    final bool isPerennialRuntime = isPerennialCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    // Ornamental de establecimiento/mantenimiento (cactus, suculenta…): el eje
    // NO es la siembra; la etapa se resuelve por estado guardado o por la fecha
    // de plantación. No hay rendimiento ni cosecha. La pregunta es por el MODO
    // DE CICLO, no por una planta concreta.
    final bool isOrnamentalRuntime = isEstablishmentMaintenanceCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    // Ornamental de floración recurrente (rosal): tras el establecimiento la
    // etapa la confirma el usuario visualmente; el eje NO es la siembra y no hay
    // cosecha. La pregunta es por el MODO DE CICLO, no por una planta concreta.
    final bool isRecurringBloomRuntime = isRecurringBloomCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    // Ornamental bulbosa estacional (tulipán): usa el RELOJ ANUAL tipo granos
    // (fecha ancla → día → etapa) pero es categoría ornamental y su cierre es
    // dormancia, no cosecha. El eje SÍ es la fecha ancla (`sowingDate`), por eso
    // NO cae en la rama de establecimiento (que anularía la fecha). La pregunta
    // es por el MODO DE CICLO, no por una planta concreta.
    final bool isSeasonalBulbRuntime = isSeasonalBulbCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    // Ornamental ANUAL VERDADERA (girasol): usa el RELOJ ANUAL tipo granos
    // (fecha ancla → día → etapa) pero es categoría ornamental y su cierre es
    // `cycle_complete` TERMINAL, no cosecha ni dormancia. El eje SÍ es la fecha
    // ancla (`sowingDate`), por eso NO cae en la rama de establecimiento (que
    // anularía la fecha) ni en seasonal_bulb (que implicaría dormancia). La
    // pregunta es por el MODO DE CICLO, no por una planta concreta (Documento A
    // §4.2, §8, §16.7).
    final bool isAnnualOrnamentalRuntime = isAnnualOrnamentalCrop(
      cropId: cropKeyName,
      cropCategoryId: normalizedContext?.cropCategoryId,
      category: definition?.category,
    );

    final bool isPlanted =
        sowingStatus == SowingStatus.planted &&
        (isPerennialRuntime ||
            isOrnamentalRuntime ||
            isRecurringBloomRuntime ||
            // La guía no pide fecha de siembra: sin fenología no habría qué
            // calcular con ella. Sin esta rama, las cinco métricas caerían a
            // los textos de pre-siembra ("Seco", "Apta") en vez de mostrar la
            // banda evaluada.
            isGuideRuntime ||
            plantedDate != null);

    final bool isPlanned = sowingStatus == SowingStatus.planned;

    final presentation = CropPresentationResolver.resolve(
      cropContext: normalizedContext,
      seed: effectiveSeed,
      definition: definition,
      explicitCropId: cropKeyName,
    );

    CropStageResult? stageResult;
    StageTargets? targets;
    AgroEvalResult? eval;
    DateTime? engineSowingDate;
    AlertsState nextAlertsState = alertsState;

    // ─────────────────────────────────────────────────────────────────────────
    // EL OBJETIVO DE HUMEDAD SE SOBRESCRIBE AQUÍ, EN EL CENTRO
    // ─────────────────────────────────────────────────────────────────────────
    //
    // Esta es la única razón por la que arreglar la escala de humedad cuesta
    // dos puntos de enganche y no 32 archivos de perfil: el motor de riego, el
    // anillo del Panel y los 26 motores de score reciben todos su `AgroRange`
    // desde `targets`. Sustituir la FUENTE de ese objeto —no los archivos que
    // lo escribieron a mano— corrige el catálogo entero de golpe.
    //
    // Y tiene que ser aquí y no en cada consumidor: si el motor de riego usara
    // la banda derivada y el Panel siguiera con la del catálogo, las dos
    // pantallas darían lecturas distintas de la misma humedad. Esa
    // contradicción es lo que se está cerrando, no una optimización.
    //
    // Los rangos escritos a mano en los perfiles NO se borran: los de maceta
    // siguen siendo válidos como referencia y los de suelo se conservan como
    // historia hasta que el prototipo confirme estas constantes en campo.
    final ResolvedSoilProfile soilProfile = SoilProfileResolver.resolve(
      deviceModelId: device?.deviceModelId,
      cultivationScaleId: normalizedContext?.cultivationScaleId,
      soilTextureId: normalizedContext?.soilTextureId,
      soilTextureSourceId: normalizedContext?.soilTextureSource,
      cropKey: definition?.cropKey,
    );

    ResolvedMoistureTarget? resolvedMoisture;

    ResolvedMoistureTarget resolveMoistureFor(String? stageKey) {
      final r = MoistureTargetResolver.resolveForSoilProfile(
        soilProfile: soilProfile,
        cropKey: definition?.cropKey,
        stageKey: stageKey,
      );
      resolvedMoisture = r;
      return r;
    }

    /// Devuelve los mismos objetivos con la banda de humedad derivada de
    /// (textura + cultivo + etapa). Todo lo demás del catálogo queda intacto.
    StageTargets? withDerivedMoisture(StageTargets? base, String? stageKey) {
      if (base == null) return null;
      return base.copyWith(moistureRaw: resolveMoistureFor(stageKey).range);
    }

    // ── MODO GUÍA GENERAL ────────────────────────────────────────────────────
    //
    // El agricultor eligió "Otro": tiene una planta que no está en el catálogo.
    // Se le dan bandas para las cinco condiciones de suelo que casi todas las
    // plantas comparten, y NADA de nutrición.
    //
    // `targets` se queda deliberadamente en NULL. Es lo que hace que NPK salga
    // sin interpretar en toda la app sin tocar un solo consumidor: quien
    // pregunta por objetivos de nutrientes obtiene null, y de ahí sale
    // `AgroBand.unknown` → '—'. Las bandas de suelo no viajan por `targets`,
    // viajan ya evaluadas dentro de `eval`.
    //
    // `stageResult` también queda en null: sin cultivo no hay fenología, y
    // fabricar una etapa sería inventarla. Ninguna pantalla lo exige sin
    // comprobarlo antes.
    if (isGuideRuntime) {
      // Se exige al menos un sensor de suelo con dato. `soilControlScore01` es
      // un `double` no nulable: sin ninguna métrica que promediar, el motor
      // solo puede devolver 0.0, y el anillo del Panel pintaría "0 % de salud"
      // —un diagnóstico catastrófico— cuando lo cierto es que no llegó
      // ninguna lectura. Con `eval` en null la app ya sabe pintar "sin datos".
      final bool guideHasSoilData =
          live != null &&
          (live.hasSoilMoistureData ||
              live.hasSoilTempData ||
              live.hasPhData ||
              live.hasEcData ||
              live.hasResistanceData);

      if (guideHasSoilData) {
        // La guía general también recibe la banda derivada. Sus 18/35/70/85
        // salían de la mediana de 67 rangos mesófitos, es decir de la misma
        // escala rota que el resto del catálogo.
        final guideBuild = GuideAgroScoreEngine.evaluate(
          t: live,
          targets: kGuideTargets.copyWith(
            moistureRaw: resolveMoistureFor(null).range,
          ),
          alertsState: alertsState,
        );
        eval = guideBuild.eval;
        nextAlertsState = guideBuild.nextAlertsState;
      }
    } else if (isOrnamentalRuntime &&
        (sowingStatus == SowingStatus.planted ||
            sowingStatus == SowingStatus.planned) &&
        normalizedContext != null) {
      // Ornamental: etapa por estado guardado o por fecha (sin cosecha ni
      // rendimiento). NO se invoca YieldProjection.
      stageResult = resolveOrnamentalStageResult(
        context: normalizedContext,
        today: today,
      );

      if (definition != null && profile != null) {
        targets = definition is CactusCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition is SucculentCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition is AloeCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition is AgaveCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition.resolveTargets(stageResult);
        targets = withDerivedMoisture(targets, stageResult.stageKey);

        if (sowingStatus == SowingStatus.planted && live != null) {
          final out = definition.evaluateTelemetry(
            telemetry: live,
            stage: stageResult,
            profile: profile,
            targetsOverride: targets,
            alertsState: alertsState,
          );
          eval = out.eval;
          nextAlertsState = out.nextAlertsState;
        }
      }
    } else if (isRecurringBloomRuntime &&
        (sowingStatus == SowingStatus.planted ||
            sowingStatus == SowingStatus.planned) &&
        normalizedContext != null) {
      // Rosal: etapa por estado visual confirmado o por fecha (solo el
      // establecimiento). Sin cosecha ni rendimiento; NO se invoca
      // YieldProjection.
      stageResult = resolveRecurringBloomStageResult(
        context: normalizedContext,
        today: today,
      );

      if (definition != null && profile != null) {
        targets = definition is RoseCropDefinition
            ? definition.resolveTargetsForProfile(
                stageResult,
                profileId: profile.id,
              )
            : definition.resolveTargets(stageResult);
        targets = withDerivedMoisture(targets, stageResult.stageKey);

        if (sowingStatus == SowingStatus.planted && live != null) {
          final out = definition.evaluateTelemetry(
            telemetry: live,
            stage: stageResult,
            profile: profile,
            targetsOverride: targets,
            alertsState: alertsState,
          );
          eval = out.eval;
          nextAlertsState = out.nextAlertsState;
        }
      }
    } else if (isPerennialRuntime &&
        sowingStatus == SowingStatus.planted &&
        normalizedContext != null) {
      stageResult = PerennialStageResolver.resolve(
        context: normalizedContext,
        today: today,
      );

      if (definition != null && profile != null) {
        targets = withDerivedMoisture(
          definition.resolveTargets(stageResult),
          stageResult.stageKey,
        );

        if (live != null) {
          final out = definition.evaluateTelemetry(
            telemetry: live,
            stage: stageResult,
            profile: profile,
            targetsOverride: targets,
            alertsState: alertsState,
          );
          eval = out.eval;
          nextAlertsState = out.nextAlertsState;
        }
      }
    } else if (isSeasonalBulbRuntime &&
        isPlanted &&
        definition != null &&
        profile != null) {
      // Tulipán (seasonal_bulb): ESPEJO ESTRUCTURAL de la rama anual de granos.
      // `sowingDate` es la fecha ancla del ciclo (Documento A §2.1, §2.4). El
      // motor conserva la última etapa (dormancia) cuando el día supera las
      // ventanas: NO se cierra el registro ni se convierte en fallow. Usa
      // targets por perfil (modificadores de maceta/forzado/corte, Documento B
      // §17). No hay calendario ni rendimiento.
      final DateTime effectiveSowingDate = plantedDate!;
      engineSowingDate = effectiveSowingDate;

      stageResult = definition.engine.compute(
        sowingDate: effectiveSowingDate,
        today: today,
        profile: profile,
        stressDelayDays: 0,
      );

      targets = definition is TulipCropDefinition
          ? definition.resolveTargetsForProfile(
              stageResult,
              profileId: profile.id,
            )
          : definition.resolveTargets(stageResult);
      targets = withDerivedMoisture(targets, stageResult.stageKey);

      if (live != null) {
        final out = definition.evaluateTelemetry(
          telemetry: live,
          stage: stageResult,
          profile: profile,
          targetsOverride: targets,
          alertsState: alertsState,
        );
        eval = out.eval;
        nextAlertsState = out.nextAlertsState;
      }
    } else if (isAnnualOrnamentalRuntime &&
        isPlanted &&
        definition != null &&
        profile != null) {
      // Girasol y Cempasúchil (annual_ornamental): ESPEJO ESTRUCTURAL de la
      // rama anual de granos y del tulipán. `sowingDate` es la fecha ancla del
      // ciclo. El motor conserva la última etapa (`cycle_complete`) cuando el
      // día supera las ventanas: es TERMINAL (no dormancia, no cosecha), con
      // progreso 1.0 y días restantes 0. Ambos usan targets por perfil (pH +
      // modificadores de contenedor/corte/paisaje) resueltos por su propio
      // módulo: el despacho es EXPLÍCITO por definición, nunca un fallback a
      // otro cultivo. No hay calendario ni rendimiento.
      final DateTime effectiveSowingDate = plantedDate!;
      engineSowingDate = effectiveSowingDate;

      stageResult = definition.engine.compute(
        sowingDate: effectiveSowingDate,
        today: today,
        profile: profile,
        stressDelayDays: 0,
      );

      targets = switch (definition) {
        SunflowerCropDefinition() => definition.resolveTargetsForProfile(
          stageResult,
          profileId: profile.id,
        ),
        MarigoldCropDefinition() => definition.resolveTargetsForProfile(
          stageResult,
          profileId: profile.id,
        ),
        _ => definition.resolveTargets(stageResult),
      };
      targets = withDerivedMoisture(targets, stageResult.stageKey);

      if (live != null) {
        final out = definition.evaluateTelemetry(
          telemetry: live,
          stage: stageResult,
          profile: profile,
          targetsOverride: targets,
          alertsState: alertsState,
        );
        eval = out.eval;
        nextAlertsState = out.nextAlertsState;
      }
    } else if (!isPerennialRuntime &&
        !isOrnamentalRuntime &&
        !isRecurringBloomRuntime &&
        !isSeasonalBulbRuntime &&
        !isAnnualOrnamentalRuntime &&
        isPlanted &&
        definition != null &&
        profile != null) {
      final DateTime effectiveSowingDate = _effectiveSowingDateForCalendar(
        cropId: cropKeyName,
        calendarTypeId: normalizedContext?.calendarTypeId,
        plantedDate: plantedDate!,
      );
      engineSowingDate = effectiveSowingDate;

      stageResult = definition.engine.compute(
        sowingDate: effectiveSowingDate,
        today: today,
        profile: profile,
        stressDelayDays: 0,
      );

      final StageTargets? baseTargets = definition.resolveTargets(stageResult);
      if (baseTargets != null) {
        targets = CropCatalog.adjustTargetsForCalendar(
          cropId: cropKeyName,
          calendarId: normalizedContext?.calendarTypeId,
          stageKey: stageResult.stageKey,
          baseTargets: baseTargets,
        );
      }
      // Después del ajuste de calendario, no antes: el desplazamiento de
      // calendario opera sobre la banda del catálogo, y lo que llega al motor
      // tiene que ser la banda derivada de la textura.
      targets = withDerivedMoisture(targets, stageResult.stageKey);

      if (live != null) {
        final out = definition.evaluateTelemetry(
          telemetry: live,
          stage: stageResult,
          profile: profile,
          targetsOverride: targets,
          alertsState: alertsState,
        );
        eval = out.eval;
        nextAlertsState = out.nextAlertsState;
      }
    }

    // Siempre hay un objetivo resuelto, aunque no haya `targets` (modo guía,
    // genérico o sin cultivo): el motor de riego necesita el `SoilContext` para
    // calcular la lámina, y ese no depende del catálogo de etapas.
    resolvedMoisture ??= resolveMoistureFor(stageResult?.stageKey);

    return CropRuntimeSnapshot(
      device: device,
      live: live,
      resolvedMoisture: resolvedMoisture,
      seed: effectiveSeed,
      cropContext: normalizedContext,
      definition: definition,
      profile: profile,
      stageResult: stageResult,
      targets: targets,
      eval: eval,
      nextAlertsState: nextAlertsState,
      cropKeyName: cropKeyName,
      cropLabel: presentation.runtimeLabel,
      cropIconAsset: presentation.iconAsset,
      stageLabel: _buildStageLabel(
        sowingStatus: sowingStatus,
        stageResult: stageResult,
        hasSeed: hasSeed,
        hasResolvedDefinition: definition != null,
        hasResolvedProfile: profile != null,
      ),
      sowingStatus: sowingStatus,
      engineSowingDate: engineSowingDate,
      hasSeed: hasSeed,
      isPlanted: isPlanted,
      isPlanned: isPlanned,
      // Excluyentes. Sin esta resta, el modo guía heredaría el apagado total
      // del genérico y perdería las cinco bandas que es su razón de existir:
      // `_resolveVisibleVarietyAlias` devuelve 'generic' cuando el alias viene
      // vacío, y eso enciende `isGenericSelection`.
      isGenericMode: presentation.isGenericSelection && !isGuideRuntime,
      isGuideMode: isGuideRuntime,
    );
  }

  static CropProfile? _resolveProfile({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
    required CropDefinition? definition,
    required String cropKeyName,
    required SowingStatus sowingStatus,
  }) {
    if (definition == null) return null;
    if (cropKeyName.isEmpty) return null;
    if (sowingStatus == SowingStatus.skip) return null;

    final bool isOrnamental = isEstablishmentMaintenanceCrop(
      cropId: cropKeyName,
      cropCategoryId: cropContext?.cropCategoryId,
      category: definition.category,
    );
    final bool isRecurringBloom = isRecurringBloomCrop(
      cropId: cropKeyName,
      cropCategoryId: cropContext?.cropCategoryId,
      category: definition.category,
    );
    final bool isOrnamentalLike = isOrnamental || isRecurringBloom;
    final String? ornamentalSelectionId = isOrnamental
        ? _resolveOrnamentalSelectionId(
            cropId: cropKeyName,
            profileId: cropContext?.profileId ?? seed?.profileId,
            varietyId: cropContext?.varietyId,
            varietyAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
          )
        : isRecurringBloom
        ? _resolveRecurringBloomSelectionId(
            cropId: cropKeyName,
            profileId: cropContext?.profileId ?? seed?.profileId,
            varietyId: cropContext?.varietyId,
            varietyAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
          )
        : null;

    final String? rawVarietyValue = isOrnamentalLike
        ? ornamentalSelectionId
        : cropContext?.varietyId ??
              cropContext?.varietyAlias ??
              seed?.varietyAlias;

    final String? resolvedVarietyId = CropCatalog.resolveVarietyId(
      cropId: cropKeyName,
      rawValue: rawVarietyValue,
    );

    final String? explicitProfileId = isOrnamentalLike
        ? ornamentalSelectionId
        : _normalizeNullable(cropContext?.profileId ?? seed?.profileId);

    final String resolvedProfileId = CropCatalog.resolveProfileId(
      cropId: cropKeyName,
      varietyId: resolvedVarietyId,
      explicitProfileId: explicitProfileId,
    );

    return definition.resolveProfile(
      profileId: resolvedProfileId,
      varietyAlias: cropContext?.varietyAlias ?? seed?.varietyAlias,
    );
  }

  static SowingStatus _resolveSowingStatus({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    if (cropContext != null) {
      switch (cropContext.lifecycleStatus) {
        case CropLifecycleStatus.planned:
          return SowingStatus.planned;
        case CropLifecycleStatus.planted:
          return SowingStatus.planted;
        case CropLifecycleStatus.fallow:
          return SowingStatus.skip;
      }
    }

    return seed?.status ?? SowingStatus.skip;
  }

  static DateTime? _resolvePlantedDate({
    required SeedInstall? seed,
    required DeviceCropContext? cropContext,
  }) {
    final status = _resolveSowingStatus(seed: seed, cropContext: cropContext);
    if (status != SowingStatus.planted) return null;
    return cropContext?.sowingDate ?? seed?.sowingDate;
  }

  static String _canonicalCropKey(String? raw) =>
      CropCatalog.canonicalCropKey(raw);

  static DateTime _effectiveSowingDateForCalendar({
    required String cropId,
    required String? calendarTypeId,
    required DateTime plantedDate,
  }) {
    final int offsetDays = CropCatalog.phenologyOffsetDaysForCalendar(
      cropId: cropId,
      calendarId: calendarTypeId,
    );

    if (offsetDays == 0) return plantedDate;
    return plantedDate.subtract(Duration(days: offsetDays));
  }

  static String _buildStageLabel({
    required SowingStatus sowingStatus,
    required CropStageResult? stageResult,
    required bool hasSeed,
    required bool hasResolvedDefinition,
    required bool hasResolvedProfile,
  }) {
    if (!hasSeed) {
      return 'Sin cultivo configurado';
    }

    if (sowingStatus == SowingStatus.planted) {
      if (stageResult != null) {
        return stageResult.stageLabelEs;
      }

      if (!hasResolvedDefinition || !hasResolvedProfile) {
        return 'Cultivo configurado';
      }

      return 'Etapa desconocida';
    }

    if (sowingStatus == SowingStatus.planned) {
      if (stageResult != null) {
        return stageResult.stageLabelEs;
      }
      return 'Pre-siembra';
    }

    return 'Descanso del suelo';
  }

  static DeviceCropContext? _normalizeContext(DeviceCropContext? cropContext) {
    if (cropContext == null) return null;

    final String cropId = CropCatalog.canonicalCropKey(cropContext.cropId);
    if (cropId.isEmpty) {
      return cropContext;
    }

    final cropEntry = CropCatalog.cropById(cropId);
    final String cropCategoryId =
        _normalizeNullable(cropContext.cropCategoryId) ??
        cropEntry?.categoryId ??
        CropCatalog.grainCategoryId;

    final bool isEstMaint = isEstablishmentMaintenanceCrop(
      cropId: cropId,
      cropCategoryId: cropCategoryId,
    );
    final bool isRose = isRecurringBloomCrop(
      cropId: cropId,
      cropCategoryId: cropCategoryId,
    );
    // Tulipán (seasonal_bulb): categoría ornamental PERO con reloj anual. NO es
    // "ornamental" para efectos de normalización: conserva `sowingDate` (su
    // fecha ancla) y `sowingModeId`, como un grano (Documento A §22.9). Solo se
    // usa para estampar su `lifecycleModeId`.
    final bool isSeasonalBulb = isSeasonalBulbCrop(
      cropId: cropId,
      cropCategoryId: cropCategoryId,
    );
    // Girasol (annual_ornamental): igual que el tulipán, categoría ornamental
    // PERO con reloj anual. NO es "ornamental" para efectos de normalización:
    // conserva `sowingDate` (su fecha ancla) y `sowingModeId`, como un grano.
    // Solo se usa para estampar su `lifecycleModeId` (Documento A §4.4).
    final bool isAnnualOrnamental = isAnnualOrnamentalCrop(
      cropId: cropId,
      cropCategoryId: cropCategoryId,
    );
    // Ambos modos ornamentales comparten: categoría ornamental, sin siembra ni
    // campos perennes. Difieren en el resolver de perfil/etapa y el modo. El
    // tulipán y el girasol NO entran aquí: mantienen su fecha ancla como un grano.
    final bool isOrnamental = isEstMaint || isRose;
    final bool isFallow =
        cropContext.lifecycleStatus == CropLifecycleStatus.fallow &&
        !isOrnamental;
    final CropLifecycleStatus normalizedLifecycleStatus =
        isOrnamental && cropContext.lifecycleStatus == CropLifecycleStatus.fallow
        ? CropLifecycleStatus.planted
        : cropContext.lifecycleStatus;
    final String? ornamentalSelectionId = isEstMaint
        ? _resolveOrnamentalSelectionId(
            cropId: cropId,
            profileId: cropContext.profileId,
            varietyId: cropContext.varietyId,
            varietyAlias: cropContext.varietyAlias,
          )
        : isRose
        ? _resolveRecurringBloomSelectionId(
            cropId: cropId,
            profileId: cropContext.profileId,
            varietyId: cropContext.varietyId,
            varietyAlias: cropContext.varietyAlias,
          )
        : null;
    final String? rawVarietyValue = isFallow
        ? null
        : (isOrnamental
              ? ornamentalSelectionId
              : (cropContext.varietyId ?? cropContext.varietyAlias));

    final String? resolvedVarietyId = isFallow
        ? null
        : isOrnamental
        ? ornamentalSelectionId
        : CropCatalog.resolveVarietyId(
            cropId: cropId,
            rawValue: rawVarietyValue,
          );

    final String resolvedProfileId = isEstMaint
        ? (ornamentalSelectionId ?? ornamentalDefaultProfileId(cropId))
        : isRose
        ? (ornamentalSelectionId ?? recurringBloomDefaultProfileId(cropId))
        : CropCatalog.resolveProfileId(
            cropId: cropId,
            varietyId: resolvedVarietyId,
            explicitProfileId: isFallow
                ? null
                : _normalizeNullable(cropContext.profileId),
          );

    final resolvedVarietyAlias = _resolvedVarietyAlias(
      cropId: cropId,
      lifecycleStatus: normalizedLifecycleStatus,
      rawVarietyAlias: cropContext.varietyAlias,
      resolvedVarietyId: resolvedVarietyId,
      resolvedProfileId: resolvedProfileId,
    );

    return cropContext.copyWith(
      cropCategoryId: cropCategoryId,
      cropId: cropId,
      profileId: resolvedProfileId,
      lifecycleStatus: normalizedLifecycleStatus,
      brandId: _resolveBrandId(
        cropId: cropId,
        explicitBrandId: isFallow ? null : cropContext.brandId,
        varietyId: resolvedVarietyId,
      ),
      varietyId: resolvedVarietyId,
      varietyAlias: resolvedVarietyAlias,
      lifecycleModeId: isEstMaint
          ? ornamentalLifecycleMode(cropId)
          : isRose
          ? kRecurringBloomLifecycleModeId
          : isSeasonalBulb
          ? kSeasonalBulbLifecycleModeId
          : isAnnualOrnamental
          ? kAnnualOrnamentalLifecycleModeId
          : cropContext.lifecycleModeId,
      ornamentalStageId: isEstMaint
          ? normalizeOrnamentalStageId(
              cropId,
              cropContext.ornamentalStageId ?? cropContext.perennialStateId,
            )
          : isRose
          ? normalizeRecurringBloomStageId(
              cropId,
              cropContext.ornamentalStageId ?? cropContext.perennialStateId,
            )
          : cropContext.ornamentalStageId,
      ornamentalAnchorDate: isOrnamental
          ? cropContext.ornamentalAnchorDate ?? cropContext.perennialAnchorDate
          : cropContext.ornamentalAnchorDate,
      ornamentalAnchorTypeId: isOrnamental
          ? cropContext.ornamentalAnchorTypeId ??
                cropContext.perennialAnchorTypeId
          : cropContext.ornamentalAnchorTypeId,
      perennialStateId: isOrnamental ? null : cropContext.perennialStateId,
      phenologyStageId: isOrnamental ? null : cropContext.phenologyStageId,
      perennialAnchorDate: isOrnamental ? null : cropContext.perennialAnchorDate,
      perennialAnchorTypeId: isOrnamental
          ? null
          : cropContext.perennialAnchorTypeId,
      // La escala de cultivo (campo / cama / maceta) SÍ aplica a ornamentales
      // —de hecho es donde más importa, porque son las que viven en maceta—.
      // Antes se anulaba junto con los campos de ciclo perenne/anual, y por eso
      // una maceta terminaba recibiendo dosis en kg/ha de campo abierto.
      cultivationScaleId: cropContext.cultivationScaleId,
      calendarTypeId: CropCatalog.resolveCalendarId(
        cropId: cropId,
        requested: cropContext.calendarTypeId,
      ),
      sowingDate:
          !isOrnamental &&
              cropContext.lifecycleStatus == CropLifecycleStatus.planted
          ? cropContext.sowingDate
          : null,
      plannedSowingDate:
          !isOrnamental &&
              cropContext.lifecycleStatus == CropLifecycleStatus.planned
          ? cropContext.plannedSowingDate
          : null,
      sowingModeId: isOrnamental
          ? null
          : _normalizeNullable(cropContext.sowingModeId) ??
                _defaultSowingModeId(cropContext.lifecycleStatus),
    );
  }

  static String? _resolveBrandId({
    required String cropId,
    required String? explicitBrandId,
    required String? varietyId,
  }) {
    if (varietyId != null && varietyId.isNotEmpty) {
      final variety = CropCatalog.varietyById(cropId, varietyId);
      final fromVariety = _normalizeNullable(variety?.brandId);
      if (fromVariety != null) {
        return fromVariety;
      }
    }

    final normalizedExplicit = _normalizeNullable(explicitBrandId);
    if (normalizedExplicit == null) return null;

    final valid = CropCatalog.brandsForCrop(
      cropId,
    ).any((brand) => brand.id == normalizedExplicit);
    return valid ? normalizedExplicit : null;
  }

  static String? _resolvedVarietyAlias({
    required String cropId,
    required CropLifecycleStatus lifecycleStatus,
    required String? rawVarietyAlias,
    required String? resolvedVarietyId,
    required String resolvedProfileId,
  }) {
    if (lifecycleStatus == CropLifecycleStatus.fallow) {
      return 'generic';
    }

    if (isEstablishmentMaintenanceCrop(cropId: cropId)) {
      return CropCatalog.profileByAny(cropId, resolvedProfileId)?.label ??
          ornamentalGeneralProfileLabel(cropId);
    }

    if (isRecurringBloomCrop(cropId: cropId)) {
      return CropCatalog.profileByAny(cropId, resolvedProfileId)?.label ??
          recurringBloomGeneralProfileLabel(cropId);
    }

    if (resolvedVarietyId != null) {
      final variety = CropCatalog.varietyById(cropId, resolvedVarietyId);
      if (variety != null) {
        return variety.isGeneric ? 'generic' : variety.label;
      }
    }

    if (CropCatalog.isGenericAlias(rawVarietyAlias) ||
        CropCatalog.isGenericProfileId(resolvedProfileId)) {
      return 'generic';
    }

    return _normalizeNullable(rawVarietyAlias);
  }

  static String _defaultSowingModeId(CropLifecycleStatus status) {
    return switch (status) {
      CropLifecycleStatus.planned => 'planned',
      CropLifecycleStatus.planted => 'planted',
      CropLifecycleStatus.fallow => 'skip',
    };
  }

  static String? _normalizeNullable(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }

  /// Resuelve la selección visible de una ornamental (cactus, suculenta…).
  ///
  /// Una selección específica superviviente REPARA un perfil general heredado:
  /// si el usuario eligió "Suculenta colgante" y un roundtrip dejó `su_skip` en
  /// `profileId`, la selección se recupera de `varietyId`/`varietyAlias`.
  static String? _resolveOrnamentalSelectionId({
    required String cropId,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    final fromProfile = CropCatalog.profileByAny(cropId, profileId);
    final fromVariety = CropCatalog.profileByAny(cropId, varietyId);
    final fromAlias = CropCatalog.profileByAny(cropId, varietyAlias);

    final String generalProfileId = ornamentalDefaultProfileId(cropId);
    for (final entry in [fromVariety, fromProfile, fromAlias]) {
      if (entry != null && entry.id != generalProfileId) {
        return entry.id;
      }
    }
    return fromProfile?.id ?? fromVariety?.id ?? fromAlias?.id;
  }

  /// Igual que [_resolveOrnamentalSelectionId] pero para el modo de floración
  /// recurrente (rosal): usa su perfil general como red de seguridad.
  static String? _resolveRecurringBloomSelectionId({
    required String cropId,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
  }) {
    final fromProfile = CropCatalog.profileByAny(cropId, profileId);
    final fromVariety = CropCatalog.profileByAny(cropId, varietyId);
    final fromAlias = CropCatalog.profileByAny(cropId, varietyAlias);

    final String generalProfileId = recurringBloomDefaultProfileId(cropId);
    for (final entry in [fromVariety, fromProfile, fromAlias]) {
      if (entry != null && entry.id != generalProfileId) {
        return entry.id;
      }
    }
    return fromProfile?.id ?? fromVariety?.id ?? fromAlias?.id;
  }
}
