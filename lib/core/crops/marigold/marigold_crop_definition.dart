import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/marigold/marigold_agro_score_engine.dart';
import 'package:bio_g/core/crops/marigold/marigold_crop_engine_adapter.dart';
import 'package:bio_g/core/crops/marigold/marigold_universal_profile.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/widgets/seeds/marigold_models.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart';
import 'package:bio_g/models/biog_telemetry.dart';

/// Definición del cultivo Cempasúchil (segunda ornamental ANUAL VERDADERA,
/// después del Girasol).
///
/// Es HÍBRIDA por diseño, igual que el Girasol y el Tulipán: el `engine` es el
/// reloj anual tipo granos (`MarigoldCropEngineAdapter`), mientras que los
/// targets, pesos y la evaluación de telemetría siguen el patrón de las
/// ornamentales recientes, con targets explícitos por etapa + perfil
/// (Documento B §15). NO expone rendimiento ni cosecha
/// (`supportsYieldProjection = false`, `supportsHarvest = false`, Documento A
/// §0.1). El final del ciclo es `cycle_complete` TERMINAL, no dormancia ni
/// cosecha (Documento A §10.11).
///
/// Regla dura (Documento A §17.6, Documento B §25): NUNCA cae al Girasol. Un
/// perfil no resuelto cae a `cs_skip`, jamás a `gi_skip`.
class MarigoldCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.marigold;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Cempasúchil';

  @override
  CropEngine get engine => const MarigoldCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? fromId = _resolveCanonicalProfileId(profileId, varietyAlias);
    if (fromId != null) {
      final resolved = marigoldProfiles[fromId];
      if (resolved != null) return resolved;
    }

    // Fallback general cs_skip (perfil conservador; NUNCA cae al Girasol, a
    // otra ornamental ni a un grano).
    return marigoldProfiles[kCsSkip] ??
        (marigoldProfiles.isNotEmpty ? marigoldProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveMarigoldTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
    String? cultivationContextId,
  }) => resolveMarigoldTargetsForProfile(
    stage.stageKey,
    profileId: profileId,
    cultivationContextId: cultivationContextId,
  );

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveMarigoldStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeMarigoldStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveMarigoldTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveMarigoldStageWeights(
      stageId,
      profileId: profile.id,
    );

    return MarigoldAgroScoreEngine.evaluate(
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
      final canonical = resolveCanonicalMarigoldProfileId(profileId.trim());
      if (canonical != null) return canonical;
    }
    if (varietyAlias != null && varietyAlias.trim().isNotEmpty) {
      // Un alias AMBIGUO (color, tamaño, marca, contexto) NO decide el perfil
      // (Documento A §8.2): cae al general y el wizard puede precisar después.
      if (isAmbiguousMarigoldProfileAlias(varietyAlias)) return kCsSkip;
      final canonical = resolveCanonicalMarigoldProfileId(varietyAlias.trim());
      if (canonical != null) return canonical;
    }
    return null;
  }
}
