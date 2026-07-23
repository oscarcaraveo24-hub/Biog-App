import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/agave/agave_agro_score_engine.dart';
import 'package:bio_g/core/crops/agave/agave_assets.dart';
import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/core/crops/agave/agave_lifecycle.dart';
import 'package:bio_g/core/crops/agave/agave_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AgaveProfile extends CropProfile {
  const AgaveProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.agave);
}

final Map<String, AgaveProfile> agaveProfiles = <String, AgaveProfile>{
  for (final entry in agaveProfileEntries)
    entry.id: AgaveProfile(
      id: entry.id,
      label: entry.label,
      useType: 'ornamental',
    ),
};

/// Definición del cultivo Maguey / Agave (cuarta ornamental oficial de BIO-G).
///
/// Cultivo de primera clase: resuelve perfil, targets por etapa y evalúa
/// telemetría con su motor. NO expone rendimiento ni cosecha (Doc A §0.2). El
/// eje NO es la siembra: el runtime resuelve la etapa con `AgaveStageResolver`.
/// "Maduro" es estabilidad ornamental, no jima ni denominación de origen.
class AgaveCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.agave;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Maguey';

  @override
  CropEngine get engine => const AgaveCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final resolved = agaveProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
      for (final entry in agaveProfileEntries) {
        final isAlias = entry.aliases.any(
          (alias) => _normalize(alias) == normalizedProfileId,
        );
        if (_normalize(entry.label) == normalizedProfileId || isAlias) {
          return agaveProfiles[entry.id];
        }
      }
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in agaveProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any((a) => _normalize(a) == normalizedAlias)) {
          return agaveProfiles[entry.id];
        }
      }
    }

    // Fallback MG-SKIP (perfil general/prudente; NUNCA cae en cactus, suculenta,
    // sábila ni otra ornamental).
    return agaveProfiles[kAgaveSkip] ??
        (agaveProfiles.isNotEmpty ? agaveProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveAgaveTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveAgaveTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveAgaveStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeAgaveStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveAgaveTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveAgaveStageWeights(
      stageId,
      profileId: profile.id,
    );

    return AgaveAgroScoreEngine.evaluate(
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

/// Adapter de engine anual: el runtime ornamental usa `AgaveStageResolver`, no
/// este `compute`. Este fallback mantiene seguro el contrato de CropDefinition
/// si una ruta legacy llamara `engine.compute`.
class AgaveCropEngineAdapter implements CropEngine {
  const AgaveCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    return CropStageResult(
      stageKey: AgaveStageIds.unknown,
      stageLabelEs: agaveStageDisplayName(AgaveStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: AgaveAssets.stageImageOrNeutral(AgaveStageIds.unknown),
      helperCaption: 'Resolver ornamental requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
