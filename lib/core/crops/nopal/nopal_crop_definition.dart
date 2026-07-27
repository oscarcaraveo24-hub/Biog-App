import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/crops/crop_definition.dart';
import 'package:bio_g/core/crops/crop_engine.dart';
import 'package:bio_g/core/crops/crop_profile_models.dart';
import 'package:bio_g/core/crops/crop_stage_models.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/crop_types.dart';
import 'package:bio_g/core/crops/nopal/nopal_agro_score_engine.dart';
import 'package:bio_g/core/crops/nopal/nopal_assets.dart';
import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/core/crops/nopal/nopal_lifecycle.dart';
import 'package:bio_g/core/crops/nopal/nopal_universal_profile.dart';
import 'package:bio_g/models/biog_telemetry.dart';

class NopalProfile extends CropProfile {
  const NopalProfile({
    required super.id,
    required super.label,
    required super.useType,
  }) : super(cropKey: CropKey.nopal);
}

final Map<String, NopalProfile> nopalProfiles = <String, NopalProfile>{
  for (final entry in nopalProfileEntries)
    entry.id: NopalProfile(
      id: entry.id,
      label: entry.label,
      useType: 'ornamental',
    ),
};

/// Definición del cultivo Nopal (octava ornamental oficial de BIO-G).
///
/// Cultivo de primera clase: resuelve perfil, targets por etapa y evalúa
/// telemetría con su motor. NO expone rendimiento ni cosecha (Doc A §0.1). El
/// eje NO es la siembra: el runtime resuelve la etapa con `NopalStageResolver`.
/// "Estable" es permanencia ornamental, no madurez productiva ni fecha de corte.
class NopalCropDefinition implements CropDefinition {
  @override
  CropKey get cropKey => CropKey.nopal;

  @override
  CropCategory get category => CropCategory.ornamental;

  @override
  String get displayName => 'Nopal';

  @override
  CropEngine get engine => const NopalCropEngineAdapter();

  @override
  CropProfile? resolveProfile({String? profileId, String? varietyAlias}) {
    final String? normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId != null) {
      // Un alias ambiguo (contexto, color o uso) NUNCA decide un perfil
      // concreto: cae en el general (Doc A §8.4).
      if (isNopalAmbiguousProfileAlias(normalizedProfileId)) {
        return nopalProfiles[kNopalSkip];
      }
      final resolved = nopalProfiles[normalizedProfileId];
      if (resolved != null) return resolved;
      for (final entry in nopalProfileEntries) {
        final isAlias = entry.aliases.any(
          (alias) => _normalize(alias) == normalizedProfileId,
        );
        if (_normalize(entry.label) == normalizedProfileId || isAlias) {
          return nopalProfiles[entry.id];
        }
      }
    }

    final String? normalizedAlias = _normalize(varietyAlias);
    if (normalizedAlias != null) {
      if (isNopalAmbiguousProfileAlias(normalizedAlias)) {
        return nopalProfiles[kNopalSkip];
      }
      for (final entry in nopalProfileEntries) {
        if (_normalize(entry.label) == normalizedAlias ||
            entry.aliases.any((a) => _normalize(a) == normalizedAlias)) {
          return nopalProfiles[entry.id];
        }
      }
    }

    // Fallback NO-SKIP (perfil general/prudente; NUNCA cae en cactus, suculenta,
    // sábila, maguey ni otra ornamental).
    return nopalProfiles[kNopalSkip] ??
        (nopalProfiles.isNotEmpty ? nopalProfiles.values.first : null);
  }

  @override
  StageTargets? resolveTargets(CropStageResult stage) =>
      resolveNopalTargets(stage.stageKey);

  StageTargets resolveTargetsForProfile(
    CropStageResult stage, {
    required String profileId,
    String? cultivationContextId,
  }) => resolveNopalTargetsForProfile(
    stage.stageKey,
    profileId: profileId,
    cultivationContextId: cultivationContextId,
  );

  StageWeights resolveStageWeights(CropStageResult stage, {String? profileId}) =>
      resolveNopalStageWeights(stage.stageKey, profileId: profileId);

  @override
  ({AgroEvalResult eval, AlertsState nextAlertsState}) evaluateTelemetry({
    required dynamic telemetry,
    required CropStageResult stage,
    required CropProfile profile,
    StageTargets? targetsOverride,
    required AlertsState alertsState,
  }) {
    final BioGTelemetry bioTelemetry = telemetry as BioGTelemetry;
    final String stageId = normalizeNopalStageId(stage.stageKey);
    final StageTargets targets =
        targetsOverride ??
        resolveNopalTargetsForProfile(stageId, profileId: profile.id);
    final StageWeights weights = resolveNopalStageWeights(
      stageId,
      profileId: profile.id,
    );

    return NopalAgroScoreEngine.evaluate(
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

/// Adapter de engine anual: el runtime ornamental usa `NopalStageResolver`, no
/// este `compute`. Este fallback mantiene seguro el contrato de CropDefinition
/// si una ruta legacy llamara `engine.compute`.
class NopalCropEngineAdapter implements CropEngine {
  const NopalCropEngineAdapter();

  @override
  CropStageResult compute({
    required DateTime sowingDate,
    required DateTime today,
    required CropProfile profile,
    int stressDelayDays = 0,
  }) {
    return CropStageResult(
      stageKey: NopalStageIds.unknown,
      stageLabelEs: nopalStageDisplayName(NopalStageIds.unknown),
      expectedDaysToEnd: 0,
      windowsNow: const <dynamic>[],
      heroAsset: NopalAssets.stageImageOrNeutral(NopalStageIds.unknown),
      helperCaption: 'Resolver ornamental requerido',
      daySinceSowing: null,
      stageProgressPct: null,
    );
  }
}
