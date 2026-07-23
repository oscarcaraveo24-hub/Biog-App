import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/tulip/tulip_agro_score_engine.dart';
import 'package:bio_g/core/crops/tulip/tulip_catalog.dart';
import 'package:bio_g/core/crops/tulip/tulip_crop_engine_adapter.dart';
import 'package:bio_g/core/crops/tulip/tulip_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/tulip_models.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Definición del cultivo Tulipán (primera ornamental bulbosa estacional).
///
/// Es HÍBRIDA por diseño (Documento A §22.5): el `engine` es el reloj anual
/// tipo granos (`TulipCropEngineAdapter`), mientras que los targets, pesos y la
/// evaluación de telemetría siguen el patrón de las ornamentales recientes
/// (rosal), con targets explícitos por etapa + perfil. NO expone rendimiento
/// ni cosecha (supportsYieldProjection = false). El final del ciclo es la
/// dormancia, no la eliminación.
class TulipCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.tulip;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Tulipán';

  @override
  CropEngine get engine => const TulipCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? fromId = _resolveCanonicalProfileId(profileId, varietyAlias);
    if (fromId != null) {
      final resolved = tulipProfiles[fromId];
      if (resolved != null) return resolved;
    }

    // Fallback general TU-SKIP (perfil conservador; NUNCA cae a otra ornamental
    // ni a un grano).
    return tulipProfiles[kTuSkip] ??
        (tulipProfiles.isNotEmpty ? tulipProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveTulipTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveTulipTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveTulipStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeTulipStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveTulipTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveTulipStageWeights(
      stageId,
      profileId: profile.id,
    );

    return TulipAgroScoreEngine.evaluate(
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
      final canonical = resolveCanonicalTulipProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      final canonical = resolveCanonicalTulipProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}
