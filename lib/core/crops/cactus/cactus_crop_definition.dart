import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/cactus/cactus_agro_score_engine.dart';
import 'package:bio_g/core/crops/cactus/cactus_assets.dart';
import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_lifecycle.dart';
import 'package:bio_g/core/crops/cactus/cactus_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class CactusProfile extends CropProfile {
  const CactusProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.cactus);
}

final Map<String, CactusProfile> cactusProfiles = <String, CactusProfile>{
  for (final entry in cactusProfileEntries)
    entry.id: CactusProfile(
      id: entry.id,
      label: entry.label,
      useType: 'ornamental',
    ),
};

/// Definición del cultivo Cactus (primera ornamental oficial de BIO-G).
///
/// Es un cultivo de primera clase: resuelve perfil, targets por etapa y evalúa
/// telemetría con el motor ornamental. NO expone rendimiento/cosecha (doc 01
/// §0.1: supportsYieldProjection=false, supportsHarvest=false). El eje NO es la
/// siembra: el runtime resuelve la etapa con `CactusStageResolver`.
class CactusCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.cactus;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Cactus';

  @override
  CropEngine get engine => const CactusCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final resolved = cactusProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
      for (final entry in cactusProfileEntries) {
        final isAlias = entry.aliases.any(
          (alias) => _normalize(alias) == normalizedProfileId,
        );
        if (_normalize(entry.label) == normalizedProfileId || isAlias) {
          return cactusProfiles[entry.id];
        }
      }
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in cactusProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any((a) => _normalize(a) == normalizedAlias)) {
          return cactusProfiles[entry.id];
        }
      }
    }

    // Fallback CA-SKIP (perfil general/seguro; NUNCA cae a un árbol ni a otra
    // ornamental).
    return cactusProfiles[kCaSkip] ??
        (cactusProfiles.isNotEmpty ? cactusProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveCactusTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveCactusTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveCactusStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeCactusStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveCactusTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveCactusStageWeights(
      stageId,
      profileId: profile.id,
    );

    return CactusAgroScoreEngine.evaluate(
      t: bioTelemetry,
      stageId: stageId,
      stageLabelEs: stage.stageLabelEs,
      targets: targets,
      weights: weights,
      alertsState: alertsState,
      cropLabel: displayName,
      profileId: profile.id,
    );
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

/// Adapter de engine anual: el runtime ornamental usa `CactusStageResolver`, no
/// este `compute`. Este fallback mantiene seguro el contrato de CropDefinition
/// si una ruta legacy llamara `engine.compute`.
class CactusCropEngineAdapter implements CropEngine {
  const CactusCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    return CropStageResult(
      stageKey: CactusStageIds.unknown,
      stageLabelEs: cactusStageDisplayName(CactusStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: CactusAssets.stageImageOrNeutral(CactusStageIds.unknown),
      helperCaption: 'Resolver ornamental requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
