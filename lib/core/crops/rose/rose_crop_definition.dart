import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/rose/rose_agro_score_engine.dart';
import 'package:bio_g/core/crops/rose/rose_assets.dart';
import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/core/crops/rose/rose_lifecycle.dart';
import 'package:bio_g/core/crops/rose/rose_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class RoseProfile extends CropProfile {
  const RoseProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.rose);
}

final Map<String, RoseProfile> roseProfiles = <String, RoseProfile>{
  for (final entry in roseProfileEntries)
    entry.id: RoseProfile(
      id: entry.id,
      label: entry.label,
      useType: 'ornamental',
    ),
};

/// Definición del cultivo Rosal (primera ornamental de floración recurrente).
///
/// Es un cultivo de primera clase: resuelve perfil, targets por etapa y evalúa
/// telemetría con el motor del rosal. NO expone rendimiento/cosecha (Doc A §1:
/// supportsYieldProjection=false, supportsHarvest=false). El eje NO es la
/// siembra: el runtime resuelve la etapa con `RoseStageResolver`, y tras el
/// establecimiento el estado lo confirma el usuario visualmente.
class RoseCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.rose;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Rosal';

  @override
  CropEngine get engine => const RoseCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final resolved = roseProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
      for (final entry in roseProfileEntries) {
        final isAlias = entry.aliases.any(
          (alias) => _normalize(alias) == normalizedProfileId,
        );
        if (_normalize(entry.label) == normalizedProfileId || isAlias) {
          return roseProfiles[entry.id];
        }
      }
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in roseProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any((a) => _normalize(a) == normalizedAlias)) {
          return roseProfiles[entry.id];
        }
      }
    }

    // Fallback RO-SKIP (perfil general/seguro; NUNCA cae a un árbol ni a otra
    // ornamental).
    return roseProfiles[kRoSkip] ??
        (roseProfiles.isNotEmpty ? roseProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveRoseTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveRoseTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveRoseStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeRoseStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveRoseTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveRoseStageWeights(
      stageId,
      profileId: profile.id,
    );

    return RoseAgroScoreEngine.evaluate(
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

/// Adapter de engine anual: el runtime del rosal usa `RoseStageResolver`, no
/// este `compute`. Este fallback mantiene seguro el contrato de CropDefinition
/// si una ruta legacy llamara `engine.compute`.
class RoseCropEngineAdapter implements CropEngine {
  const RoseCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    return CropStageResult(
      stageKey: RoseStageIds.unknown,
      stageLabelEs: roseStageDisplayName(RoseStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: RoseAssets.stageImageOrNeutral(RoseStageIds.unknown),
      helperCaption: 'Resolver de floración recurrente requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
