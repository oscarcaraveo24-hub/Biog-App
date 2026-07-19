import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/succulent/succulent_agro_score_engine.dart';
import 'package:bio_g/core/crops/succulent/succulent_assets.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_lifecycle.dart';
import 'package:bio_g/core/crops/succulent/succulent_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class SucculentProfile extends CropProfile {
  const SucculentProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.succulent);
}

final Map<String, SucculentProfile> succulentProfiles =
    <String, SucculentProfile>{
      for (final entry in succulentProfileEntries)
        entry.id: SucculentProfile(
          id: entry.id,
          label: entry.label,
          useType: 'ornamental',
        ),
    };

/// Definición del cultivo Suculenta (segunda ornamental oficial de BIO-G).
///
/// Cultivo de primera clase: resuelve perfil, targets por etapa y evalúa
/// telemetría con su motor. NO expone rendimiento ni cosecha (Doc A §0.2). El
/// eje NO es la siembra: el runtime resuelve la etapa con
/// `SucculentStageResolver`.
class SucculentCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.succulent;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Suculenta';

  @override
  CropEngine get engine => const SucculentCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final resolved = succulentProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
      for (final entry in succulentProfileEntries) {
        final isAlias = entry.aliases.any(
          (alias) => _normalize(alias) == normalizedProfileId,
        );
        if (_normalize(entry.label) == normalizedProfileId || isAlias) {
          return succulentProfiles[entry.id];
        }
      }
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in succulentProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any((a) => _normalize(a) == normalizedAlias)) {
          return succulentProfiles[entry.id];
        }
      }
    }

    // Fallback SU-SKIP (perfil general/prudente; NUNCA cae en cactus ni en otra
    // ornamental).
    return succulentProfiles[kSuSkip] ??
        (succulentProfiles.isNotEmpty ? succulentProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveSucculentTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveSucculentTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveSucculentStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeSucculentStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveSucculentTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveSucculentStageWeights(
      stageId,
      profileId: profile.id,
    );

    return SucculentAgroScoreEngine.evaluate(
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

/// Adapter de engine anual: el runtime ornamental usa `SucculentStageResolver`,
/// no este `compute`. Este fallback mantiene seguro el contrato de
/// CropDefinition si una ruta legacy llamara `engine.compute`.
class SucculentCropEngineAdapter implements CropEngine {
  const SucculentCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    return CropStageResult(
      stageKey: SucculentStageIds.unknown,
      stageLabelEs: succulentStageDisplayName(SucculentStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: SucculentAssets.stageImageOrNeutral(SucculentStageIds.unknown),
      helperCaption: 'Resolver ornamental requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
