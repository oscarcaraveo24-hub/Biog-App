import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/water/moisture_target_resolver.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/seed_install.dart';

class CropRuntimeSnapshot {
  final BioGDevice? device;
  final BioGTelemetry? live;

  /// Adaptador legacy temporal.
  ///
  /// Ojo: este campo NO representa la fuente principal de verdad.
  /// Se conserva para compatibilidad mientras los callers terminan de migrar
  /// a [cropContext].
  final SeedInstall? seed;

  /// Fuente formal nueva de contexto del cultivo.
  final DeviceCropContext? cropContext;

  final CropDefinition? definition;
  final CropProfile? profile;
  final CropStageResult? stageResult;
  final StageTargets? targets;

  /// El objetivo de humedad ya derivado de (textura + cultivo + etapa), con su
  /// contexto de suelo, sus limitaciones y su penalización de confianza.
  ///
  /// `targets.moistureRaw` ya trae esta misma banda —se sobrescribe en el
  /// resolver— pero aquí viaja además todo lo que hace falta para **explicar**
  /// la decisión: qué textura se usó, de dónde salió, qué coeficiente de
  /// agotamiento se aplicó y qué no sabíamos. Sin eso, la lámina en milímetros
  /// y el registro auditable no se pueden construir.
  ///
  /// Nunca es null cuando hay dispositivo: el motor de riego necesita el
  /// `SoilContext` aunque no haya cultivo declarado.
  final ResolvedMoistureTarget? resolvedMoisture;

  final AgroEvalResult? eval;
  final AlertsState nextAlertsState;

  /// Crop key ya canonizado para runtime.
  final String cropKeyName;

  final String cropLabel;
  final String cropIconAsset;
  final String stageLabel;

  final SowingStatus sowingStatus;

  /// Fecha real de siembra usada por el motor fenológico después de aplicar
  /// offsets del calendario (temporal/riego/base).
  final DateTime? engineSowingDate;

  /// Compatibilidad legacy.
  ///
  /// Aunque el nombre histórico es `hasSeed`, en la práctica significa:
  /// "hay contexto/configuración de cultivo disponible", venga de `seed`
  /// o venga de `cropContext`.
  final bool hasSeed;

  final bool isPlanted;
  final bool isPlanned;
  final bool isGenericMode;

  /// Modo guía general: el agricultor eligió "Otro".
  ///
  /// Es un estado DISTINTO de [isGenericMode] y los dos son excluyentes. La
  /// diferencia práctica: en modo genérico no hay interpretación de ninguna
  /// clase; en modo guía sí la hay para humedad, pH, temperatura de suelo y
  /// compactación, y solo la nutrición queda sin interpretar.
  ///
  /// Se añade como campo nuevo con valor por omisión en vez de meterle un
  /// cuarto significado a [isGenericMode], que ya carga tres y está leído en
  /// más de una docena de sitios. Ese es justo el patrón que produjo las
  /// contradicciones entre pantallas que se cerraron en la auditoría V1-A.
  final bool isGuideMode;

  const CropRuntimeSnapshot({
    required this.device,
    required this.live,
    required this.seed,
    this.cropContext,
    required this.definition,
    required this.profile,
    required this.stageResult,
    required this.targets,
    this.resolvedMoisture,
    required this.eval,
    required this.nextAlertsState,
    required this.cropKeyName,
    required this.cropLabel,
    required this.cropIconAsset,
    required this.stageLabel,
    required this.sowingStatus,
    required this.engineSowingDate,
    required this.hasSeed,
    required this.isPlanted,
    required this.isPlanned,
    required this.isGenericMode,
    this.isGuideMode = false,
  });

  /// Fuente formal nueva disponible.
  bool get hasFormalContext => cropContext != null;

  /// Adaptador legacy disponible.
  bool get hasLegacySeedAdapter => seed != null;

  /// Nombre semántico preferido para callers nuevos.
  bool get hasConfiguredCrop => hasSeed;

  bool get isFallowMode => sowingStatus == SowingStatus.skip;

  bool get hasResolvedDefinition => definition != null;

  bool get hasResolvedProfile => profile != null;

  bool get hasResolvedStage => stageResult != null;

  bool get hasResolvedTargets => targets != null;

  bool get hasResolvedRuntime => hasResolvedDefinition && hasResolvedProfile;

  String? get effectiveProfileId => cropContext?.profileId ?? seed?.profileId;

  String? get effectiveVarietyId => cropContext?.varietyId;

  String? get effectiveVarietyAlias =>
      cropContext?.varietyAlias ?? seed?.varietyAlias;

  DateTime? get effectiveLifecycleDate {
    if (isPlanted) {
      return cropContext?.sowingDate ?? seed?.sowingDate;
    }

    if (isPlanned) {
      return cropContext?.plannedSowingDate ?? seed?.plannedSowingDate;
    }

    return null;
  }
}
