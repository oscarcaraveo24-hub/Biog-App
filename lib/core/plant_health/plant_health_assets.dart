import 'package:bio_g/core/plant_health/plant_health_ids.dart';

/// Centralized registry that maps plant-health IDs to local PNG assets.
class PlantHealthAssets {
  PlantHealthAssets._();

  static const String _base = 'assets/icons/plant_health';

  static const Map<String, String> _organs = <String, String>{
    PlantHealthIds.organLeaf: '$_base/ph_leaf_normal.png',
    PlantHealthIds.organStem: '$_base/ph_stem_normal.png',
    PlantHealthIds.organWhorl: '$_base/ph_whorl_normal.png',
    PlantHealthIds.organEar: '$_base/ph_ear_head_normal.png',
    PlantHealthIds.organSpike: '$_base/ph_ear_head_normal.png',
    PlantHealthIds.organPod: '$_base/ph_pod_normal.png',
    PlantHealthIds.organFruit: '$_base/ph_pod_normal.png',
    PlantHealthIds.organFlower: '$_base/ph_pod_normal.png',
    PlantHealthIds.organRoot: '$_base/ph_whole_plant_normal.png',
    PlantHealthIds.organCrown: '$_base/ph_stem_normal.png',
    PlantHealthIds.organGrain: '$_base/ph_grain_normal.png',
    PlantHealthIds.organWholePlant: '$_base/ph_whole_plant_normal.png',
    'cob': '$_base/ph_cob_normal.png',
  };

  static const Map<String, String> _symptoms = <String, String>{
    PlantHealthIds.symptomOrangeReddishPustules:
        '$_base/ph_leaf_rust_pustules.png',
    PlantHealthIds.symptomNecroticFoliarSpots:
        '$_base/ph_leaf_necrotic_spots.png',
    PlantHealthIds.symptomAphidColonies: '$_base/ph_leaf_aphid_colony.png',
    PlantHealthIds.symptomLateDefoliation:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.symptomWhorlFeeding: '$_base/ph_whorl_chewed.png',
    PlantHealthIds.symptomStuntingReddening:
        '$_base/ph_plant_stunting_reddish.png',
    PlantHealthIds.symptomRaisedBlackSpots:
        '$_base/ph_leaf_black_raised_dots.png',
    PlantHealthIds.symptomOrangePustules: '$_base/ph_leaf_rust_pustules.png',
    PlantHealthIds.symptomEarRot: '$_base/ph_cob_mold_rot.png',
    PlantHealthIds.symptomWhiteflyPresence: '$_base/ph_whitefly_cloud.png',
    PlantHealthIds.symptomNetLikeSpots:
        '$_base/ph_leaf_reticulated_lesions.png',
    PlantHealthIds.symptomMosaicYellowing:
        '$_base/ph_leaf_mosaic_yellowing.png',
    PlantHealthIds.symptomWiltPodLesions: '$_base/ph_pod_canker.png',
    PlantHealthIds.symptomDarkSunkenLesions:
        '$_base/ph_leaf_dark_sunken_lesions.png',
    PlantHealthIds.symptomAngularSpots: '$_base/ph_leaf_angular_lesions.png',
    PlantHealthIds.symptomStripedLeaves: '$_base/ph_leaf_streaks_bands.png',
    PlantHealthIds.symptomGrayFoliarScald: '$_base/ph_leaf_scald_blanched.png',
    PlantHealthIds.symptomPowderyGrowth: '$_base/ph_leaf_spore_dust.png',
    PlantHealthIds.symptomWiltVascular:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.symptomFruitApicalRot: '$_base/ph_pod_canker.png',
    PlantHealthIds.symptomBacterialSpeckSpot:
        '$_base/ph_leaf_angular_lesions.png',
    PlantHealthIds.symptomBronzingStippling:
        '$_base/ph_leaf_strong_chlorosis.png',
    PlantHealthIds.symptomRootGalls:
        '$_base/ph_plant_stunting_reddish.png',
    PlantHealthIds.symptomSeedlingCollapse:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.symptomRootRotWilt:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.symptomGrayMoldNecrosis:
        '$_base/ph_leaf_spore_dust.png',
    PlantHealthIds.symptomLeafMines:
        '$_base/ph_leaf_reticulated_lesions.png',
    PlantHealthIds.symptomFeedingHoles:
        '$_base/ph_leaf_chewing_larva.png',
    PlantHealthIds.symptomBoltingStem:
        '$_base/ph_stem_normal.png',
    PlantHealthIds.symptomFlowerAbortion:
        '$_base/ph_pod_normal.png',
    PlantHealthIds.symptomFruitDeformation:
        '$_base/ph_pod_canker.png',
    PlantHealthIds.symptomColdInjury:
        '$_base/ph_leaf_scald_blanched.png',
  };

  static const Map<String, String> _signals = <String, String>{
    PlantHealthIds.signalPustulesOnStem: '$_base/ph_stem_pustules.png',
    PlantHealthIds.signalNoClearPustules: '$_base/ph_leaf_no_pustules.png',
    PlantHealthIds.signalHumidWindow: '$_base/ph_humid_environment.png',
    PlantHealthIds.signalCoolDewyWindow: '$_base/ph_leaf_dew.png',
    PlantHealthIds.signalAphidEarlyToxicity:
        '$_base/ph_leaf_strong_chlorosis.png',
    PlantHealthIds.signalSpikeFeeding: '$_base/ph_ear_head_with_pest.png',
    PlantHealthIds.signalLeafRolling: '$_base/ph_leaf_curled_twisted.png',
    PlantHealthIds.signalActiveChewing: '$_base/ph_leaf_chewing_larva.png',
    PlantHealthIds.signalNoBiteMarks: '$_base/ph_leaf_no_chewing.png',
    PlantHealthIds.signalRapidFoliarCollapse:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.signalFrassPresent: '$_base/ph_leaf_insect_frass.png',
    PlantHealthIds.signalDeadHeart: '$_base/ph_whorl_dead_heart.png',
    PlantHealthIds.signalVectorPresent: '$_base/ph_insect_vector.png',
    PlantHealthIds.signalCannotScrapeOff: '$_base/ph_leaf_fixed_lesion.png',
    PlantHealthIds.signalSporesRubOff: '$_base/ph_leaf_spore_dust.png',
    PlantHealthIds.signalMoldOnEar: '$_base/ph_cob_mold_rot.png',
    PlantHealthIds.signalSilkDamage: '$_base/ph_cob_damaged_silks.png',
    PlantHealthIds.signalDarkStriations: '$_base/ph_leaf_stem_dark_streaks.png',
    PlantHealthIds.signalStickyHoneydew: '$_base/ph_leaf_honeydew.png',
    PlantHealthIds.signalSootyMold: '$_base/ph_leaf_sooty_mold.png',
    PlantHealthIds.signalWhiteflyCloud: '$_base/ph_whitefly_cloud.png',
    PlantHealthIds.signalSeedStaining:
        '$_base/ph_grain_spotted_discolored.png',
    PlantHealthIds.signalNetPattern:
        '$_base/ph_leaf_reticulated_lesions.png',
    PlantHealthIds.signalScaldBleaching: '$_base/ph_leaf_scald_blanched.png',
    PlantHealthIds.signalPodCanker: '$_base/ph_pod_canker.png',
    PlantHealthIds.signalWaterSoakedMargin:
        '$_base/ph_leaf_water_soaked_margin.png',
    PlantHealthIds.signalAngularLesionPattern:
        '$_base/ph_leaf_angular_lesions.png',
    PlantHealthIds.signalPinkSporeMass:
        '$_base/ph_lesion_pink_spore_mass.png',
    PlantHealthIds.signalWhitePowderGrowth: '$_base/ph_leaf_spore_dust.png',
    PlantHealthIds.signalGrayFuzzyGrowth: '$_base/ph_leaf_spore_dust.png',
    PlantHealthIds.signalHaloMargin:
        '$_base/ph_leaf_water_soaked_margin.png',
    PlantHealthIds.signalVascularBrowning:
        '$_base/ph_leaf_stem_dark_streaks.png',
    PlantHealthIds.signalOneSidedWilt:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.signalFruitApicalBlackPatch: '$_base/ph_pod_canker.png',
    PlantHealthIds.signalThripsPresent: '$_base/ph_insect_vector.png',
    PlantHealthIds.signalBronzedLeafSurface:
        '$_base/ph_leaf_strong_chlorosis.png',
    PlantHealthIds.signalMitesWebbing: '$_base/ph_leaf_spore_dust.png',
    PlantHealthIds.signalRootGalls:
        '$_base/ph_plant_stunting_reddish.png',
    PlantHealthIds.signalStemCanker: '$_base/ph_pod_canker.png',
    PlantHealthIds.signalUndersideSporulation:
        '$_base/ph_leaf_dew.png',
    PlantHealthIds.signalSeedlingNeckCollapse:
        '$_base/ph_plant_rapid_defoliation.png',
    PlantHealthIds.signalWaterlogging:
        '$_base/ph_humid_environment.png',
    PlantHealthIds.signalRootsDarkRot:
        '$_base/ph_leaf_stem_dark_streaks.png',
    PlantHealthIds.signalHeatStress:
        '$_base/ph_plant_recent_stress.png',
    PlantHealthIds.signalDryHotWindow:
        '$_base/ph_plant_recent_stress.png',
    PlantHealthIds.signalFlowerDrop:
        '$_base/ph_pod_normal.png',
    PlantHealthIds.signalFruitHooking:
        '$_base/ph_pod_canker.png',
    PlantHealthIds.signalDeformedNoRot:
        '$_base/ph_pod_canker.png',
    PlantHealthIds.signalSalinityLoad:
        '$_base/ph_plant_recent_stress.png',
    PlantHealthIds.signalLeafMines:
        '$_base/ph_leaf_reticulated_lesions.png',
    PlantHealthIds.signalFeedingHoles:
        '$_base/ph_leaf_chewing_larva.png',
    PlantHealthIds.signalColdExposure:
        '$_base/ph_leaf_scald_blanched.png',
    PlantHealthIds.signalRecentStress:
        '$_base/ph_plant_recent_stress.png',
  };

  static const String contextHumidity = '$_base/ph_humid_environment.png';
  static const String contextCoolDew = '$_base/ph_leaf_dew.png';
  static const String contextRecentStress = '$_base/ph_plant_recent_stress.png';
  static const String contextVectorPressure = '$_base/ph_insect_vector.png';

  static String? forOrgan(String organId) => _organs[organId];

  static String? forSymptom(String symptomId) => _symptoms[symptomId];

  static String? forSignal(String signalId) => _signals[signalId];

  static String? forId(String id) =>
      _organs[id] ?? _symptoms[id] ?? _signals[id];
}
