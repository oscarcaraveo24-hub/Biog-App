import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_agro_score_engine.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_crop_engine_adapter.dart';
import 'package:bio_g/core/crops/sunflower/sunflower_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/sunflower_models.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Definición del cultivo Girasol (primera ornamental ANUAL VERDADERA).
///
/// Es HÍBRIDA por diseño, igual que el Tulipán (Documento A §21): el `engine` es
/// el reloj anual tipo granos (`SunflowerCropEngineAdapter`), mientras que los
/// targets, pesos y la evaluación de telemetría siguen el patrón de las
/// ornamentales recientes (rosal/tulipán), con targets explícitos por etapa +
/// perfil. NO expone rendimiento ni cosecha (supportsYieldProjection = false). El
/// final del ciclo es `cycle_complete` TERMINAL, no dormancia ni cosecha
/// (Documento A §8.4).
class SunflowerCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.sunflower;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Girasol';

  @override
  CropEngine get engine => const SunflowerCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? fromId = _resolveCanonicalProfileId(profileId, varietyAlias);
    if (fromId != null) {
      final resolved = sunflowerProfiles[fromId];
      if (resolved != null) return resolved;
    }

    // Fallback general gi_skip (perfil conservador; NUNCA cae a otra ornamental
    // ni a un grano).
    return sunflowerProfiles[kGiSkip] ??
        (sunflowerProfiles.isNotEmpty ? sunflowerProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveSunflowerTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveSunflowerTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveSunflowerStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeSunflowerStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveSunflowerTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveSunflowerStageWeights(
      stageId,
      profileId: profile.id,
    );

    return SunflowerAgroScoreEngine.evaluate(
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

  String? _resolveCanonicalProfileId(String? profileId, String? varietyAlias) {
    if (profileId != null && profileId.trim().isNotEmpty) {
      final canonical = resolveCanonicalSunflowerProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalSunflowerProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}
