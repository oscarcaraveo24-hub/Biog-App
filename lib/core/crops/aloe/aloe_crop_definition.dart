import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/aloe/aloe_agro_score_engine.dart';
import 'package:bio_g/core/crops/aloe/aloe_assets.dart';
import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/core/crops/aloe/aloe_lifecycle.dart';
import 'package:bio_g/core/crops/aloe/aloe_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class AloeProfile extends CropProfile {
  const AloeProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.aloe);
}

final Map<String, AloeProfile> aloeProfiles = <String, AloeProfile>{
  for (final entry in aloeProfileEntries)
    entry.id: AloeProfile(
      id: entry.id,
      label: entry.label,
      useType: 'ornamental',
    ),
};

/// Definición del cultivo Sábila / Aloe (tercera ornamental oficial de BIO-G).
///
/// Cultivo de primera clase: resuelve perfil, targets por etapa y evalúa
/// telemetría con su motor. NO expone rendimiento ni cosecha (Doc A §0.2). El
/// eje NO es la siembra: el runtime resuelve la etapa con `AloeStageResolver`.
class AloeCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.aloe;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Sábila';

  @override
  CropEngine get engine => const AloeCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      final resolved = aloeProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
      for (final entry in aloeProfileEntries) {
        final isAlias = entry.aliases.any(
          (alias) => _normalize(alias) == normalizedProfileId,
        );
        if (_normalize(entry.label) == normalizedProfileId || isAlias) {
          return aloeProfiles[entry.id];
        }
      }
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      for (final entry in aloeProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any((a) => _normalize(a) == normalizedAlias)) {
          return aloeProfiles[entry.id];
        }
      }
    }

    // Fallback SA-SKIP (perfil general/prudente; NUNCA cae en cactus, suculenta
    // ni otra ornamental).
    return aloeProfiles[kSaSkip] ??
        (aloeProfiles.isNotEmpty ? aloeProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveAloeTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
  }) => resolveAloeTargetsForProfile(stage.stageKey, profileId: profileId);

  StageWeights resolveStageWeights(
    CropStageResult stage, {
    String? profileId,
  }) => resolveAloeStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeAloeStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveAloeTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveAloeStageWeights(
      stageId,
      profileId: profile.id,
    );

    return AloeAgroScoreEngine.evaluate(
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

/// Adapter de engine anual: el runtime ornamental usa `AloeStageResolver`, no
/// este `compute`. Este fallback mantiene seguro el contrato de CropDefinition
/// si una ruta legacy llamara `engine.compute`.
class AloeCropEngineAdapter implements CropEngine {
  const AloeCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    return CropStageResult(
      stageKey: AloeStageIds.unknown,
      stageLabelEs: aloeStageDisplayName(AloeStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: AloeAssets.stageImageOrNeutral(AloeStageIds.unknown),
      helperCaption: 'Resolver ornamental requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
