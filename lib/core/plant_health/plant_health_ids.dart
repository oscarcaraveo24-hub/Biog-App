class PlantHealthIds {
  PlantHealthIds._();

  // Organs
  static const String organWhorl = 'whorl';
  static const String organLeaf = 'leaf';
  static const String organStem = 'stem';
  static const String organRoot = 'root';
  static const String organCrown = 'crown';
  static const String organSpike = 'spike';
  static const String organEar = 'ear';
  static const String organPod = 'pod';
  static const String organFruit = 'fruit';
  static const String organFlower = 'flower';
  static const String organWholePlant = 'whole_plant';
  static const String organGrain = 'grain';
  // Cebolla / bulbo
  static const String organBulb = 'bulb';
  static const String organNeck = 'neck';
  static const String organBasalPlate = 'basal_plate';
  static const String organSeedClove = 'seed_clove';
  // Girasol / Sunflower (Doc C §4.1): organos nuevos.
  static const String organSeed = 'seed';
  static const String organBud = 'bud';
  static const String organFlowerHead = 'flower_head';

  // Symptoms
  static const String symptomOrangeReddishPustules = 'orange_reddish_pustules';
  static const String symptomNecroticFoliarSpots = 'necrotic_foliar_spots';
  static const String symptomAphidColonies = 'aphid_colonies';
  static const String symptomLateDefoliation = 'late_defoliation';
  static const String symptomWhorlFeeding = 'whorl_feeding';
  static const String symptomStuntingReddening = 'stunting_reddening';
  static const String symptomRaisedBlackSpots = 'raised_black_spots';
  static const String symptomOrangePustules = 'orange_pustules';
  static const String symptomEarRot = 'ear_rot';
  static const String symptomWhiteflyPresence = 'whitefly_presence';
  static const String symptomNetLikeSpots = 'net_like_spots';
  static const String symptomMosaicYellowing = 'mosaic_yellowing';
  static const String symptomWiltPodLesions = 'wilt_pod_lesions';
  static const String symptomDarkSunkenLesions = 'dark_sunken_lesions';
  static const String symptomAngularSpots = 'angular_spots';
  static const String symptomStripedLeaves = 'striped_leaves';
  static const String symptomGrayFoliarScald = 'gray_foliar_scald';
  static const String symptomPowderyGrowth = 'powdery_growth';
  static const String symptomWiltVascular = 'wilt_vascular';
  static const String symptomFruitApicalRot = 'fruit_apical_rot';
  static const String symptomBacterialSpeckSpot = 'bacterial_speck_spot';
  static const String symptomBronzingStippling = 'bronzing_stippling';
  static const String symptomRootGalls = 'root_galls';
  static const String symptomSeedlingCollapse = 'seedling_collapse';
  static const String symptomRootRotWilt = 'root_rot_wilt';
  static const String symptomGrayMoldNecrosis = 'gray_mold_necrosis';
  static const String symptomLeafMines = 'leaf_mines';
  static const String symptomFeedingHoles = 'feeding_holes';
  static const String symptomBoltingStem = 'bolting_stem';
  static const String symptomTanPaperySpots = 'tan_papery_spots';
  static const String symptomWaterSoakedSpots = 'water_soaked_spots';
  static const String symptomWhitePustules = 'white_pustules';
  static const String symptomLeafDistortion = 'leaf_distortion';
  static const String symptomPoorEmergence = 'poor_emergence';
  static const String symptomLeafEdgeBurn = 'leaf_edge_burn';
  static const String symptomFlowerAbortion = 'flower_abortion';
  static const String symptomFruitDeformation = 'fruit_deformation';
  static const String symptomColdInjury = 'cold_injury';
  // Cactus ornamental: observaciones visuales, no diagnósticos.
  static const String symptomCactusRootCollarDeterioration =
      'cactus_root_collar_deterioration';
  static const String symptomCactusSoftWaterSoakedTissue =
      'cactus_soft_water_soaked_tissue';
  static const String symptomCactusDryFirmCorking = 'cactus_dry_firm_corking';
  static const String symptomCactusWrinklingTurgorLoss =
      'cactus_wrinkling_turgor_loss';
  static const String symptomCactusWhiteCottonyMaterial =
      'cactus_white_cottony_material';
  static const String symptomCactusSunburnPatch = 'cactus_sunburn_patch';
  static const String symptomCactusColdTissueChange =
      'cactus_cold_tissue_change';
  static const String symptomCactusLeaningCollapse = 'cactus_leaning_collapse';
  // Suculenta ornamental (Doc C §13.3): observaciones visuales, NUNCA
  // diagnósticos. La sonda no ve hojas, insectos ni tejido: estos síntomas los
  // reporta el usuario.
  static const String symptomSucculentRootCollarDeterioration =
      'succulent_root_collar_deterioration';
  static const String symptomSucculentSoftWaterSoakedTissue =
      'succulent_soft_water_soaked_tissue';
  static const String symptomSucculentWrinklingTurgorLoss =
      'succulent_wrinkling_turgor_loss';
  static const String symptomSucculentEdemaCorkyBlisters =
      'succulent_edema_corky_blisters';
  static const String symptomSucculentEtiolatedGrowth =
      'succulent_etiolated_growth';
  static const String symptomSucculentSunburnPatch = 'succulent_sunburn_patch';
  static const String symptomSucculentColdTissueChange =
      'succulent_cold_tissue_change';
  static const String symptomSucculentPowderySurfaceGrowth =
      'succulent_powdery_surface_growth';
  static const String symptomSucculentLeafSpotGrayMold =
      'succulent_leaf_spot_gray_mold';
  static const String symptomSucculentCottonWaxScale =
      'succulent_cotton_wax_scale';
  static const String symptomSucculentStipplingWebbing =
      'succulent_stippling_webbing_distortion';
  static const String symptomSucculentSaltLeafBurn = 'succulent_salt_leaf_burn';
  static const String symptomSucculentChemicalSprayBurn =
      'succulent_chemical_spray_burn';
  static const String symptomSucculentFungusGnatIndicator =
      'succulent_fungus_gnat_indicator';
  // Sábila / Aloe ornamental (Doc C §6): observaciones visuales, NUNCA
  // diagnósticos. La sonda no ve hojas, insectos ni tejido: estos síntomas los
  // reporta el usuario. v1 NO incluye perforaciones/barrenado (SA-SYN-010).
  static const String symptomAloeRootCollarCondition =
      'aloe_root_collar_condition';
  static const String symptomAloeSoftWaterSoakedTissue =
      'aloe_soft_water_soaked_tissue';
  static const String symptomAloeWartyGallDistortion =
      'aloe_warty_gall_distortion';
  static const String symptomAloeColdTissueChange = 'aloe_cold_tissue_change';
  static const String symptomAloeSunburnPatch = 'aloe_sunburn_patch';
  static const String symptomAloeDryHardLeafSpot = 'aloe_dry_hard_leaf_spot';
  static const String symptomAloeWetAdvancingLesion =
      'aloe_wet_advancing_lesion';
  static const String symptomAloeMealybugScaleSooty =
      'aloe_mealybug_scale_sooty';
  static const String symptomAloeSpiderMiteStippling =
      'aloe_spider_mite_stippling';
  static const String symptomAloeSaltLeafBurn = 'aloe_salt_leaf_burn';
  static const String symptomAloeSprayInjury = 'aloe_spray_injury';
  static const String symptomAloeEtiolatedGrowth = 'aloe_etiolated_growth';
  static const String symptomAloeWrinklingTurgorLoss =
      'aloe_wrinkling_turgor_loss';
  // Maguey / Agave ornamental (Doc C §6): observaciones visuales y táctiles,
  // NUNCA diagnósticos. La sonda no ve tejido, insectos ni el cogollo: estos
  // síntomas los reporta el usuario. El quiote y la senescencia postfloración NO
  // son enfermedades (Doc C §7.6). v1 incluye los 17 síndromes MG-SYN-001..017.
  static const String symptomAgaveRootCrownCondition =
      'agave_root_crown_condition';
  static const String symptomAgaveSoftWaterSoakedTissue =
      'agave_soft_water_soaked_tissue';
  static const String symptomAgaveWiltDryBud = 'agave_wilt_dry_bud';
  static const String symptomAgaveSnoutWeevil = 'agave_snout_weevil_boring';
  static const String symptomAgaveMiteGreasyStreak = 'agave_mite_greasy_streak';
  static const String symptomAgaveSoftScaleWaxy = 'agave_soft_scale_waxy';
  static const String symptomAgavePlantBugScar = 'agave_plant_bug_scar';
  static const String symptomAgaveAnthracnoseLesion =
      'agave_anthracnose_lesion';
  static const String symptomAgaveGraySpotLesion = 'agave_gray_spot_lesion';
  static const String symptomAgaveColdFrostInjury = 'agave_cold_frost_injury';
  static const String symptomAgaveSunburnHeat = 'agave_sunburn_heat';
  static const String symptomAgaveMechanicalWound = 'agave_mechanical_wound';
  static const String symptomAgaveSaltFertilizerInjury =
      'agave_salt_fertilizer_injury';
  static const String symptomAgaveAnimalDamage = 'agave_animal_damage';
  static const String symptomAgaveFlowerStalk = 'agave_flower_stalk';
  static const String symptomAgavePostFloweringSenescence =
      'agave_post_flowering_senescence';
  static const String symptomAgaveBenignNaturalChange =
      'agave_benign_natural_change';
  // Cebolla / bulbo
  static const String symptomThripsSilverScarring = 'thrips_silver_scarring';
  static const String symptomDownyFuzzyGrowth = 'downy_fuzzy_growth';
  static const String symptomPurpleConcentricLesions =
      'purple_concentric_lesions';
  static const String symptomDarkOliveLeafBlight = 'dark_olive_leaf_blight';
  static const String symptomWhiteSunkenLeafSpots = 'white_sunken_leaf_spots';
  static const String symptomPinkRoots = 'pink_roots';
  static const String symptomBasalPlateBrownRot = 'basal_plate_brown_rot';
  static const String symptomWhiteMyceliumSclerotia =
      'white_mycelium_sclerotia';
  static const String symptomNeckSoftRot = 'neck_soft_rot';
  static const String symptomBulbScaleWaterSoaked = 'bulb_scale_water_soaked';
  static const String symptomCenterLeafBleaching = 'center_leaf_bleaching';
  static const String symptomStrawDiamondLesions = 'straw_diamond_lesions';
  static const String symptomBlackMoldSpores = 'black_mold_spores';
  static const String symptomBlueGreenMold = 'blue_green_mold';
  static const String symptomNoBulbPhotoperiod = 'no_bulb_photoperiod';
  static const String symptomSeedstalkBolting = 'seedstalk_bolting';
  static const String symptomThickNeck = 'thick_neck';
  static const String symptomBulbSplitting = 'bulb_splitting';
  static const String symptomDeformedBulb = 'deformed_bulb';
  static const String symptomMaggotStandLoss = 'maggot_larvae_stand_loss';
  static const String symptomPoorCuringNeckMoist = 'poor_curing_neck_moist';
  static const String symptomPoorCloveDifferentiation =
      'poor_clove_differentiation';
  static const String symptomExposedClovesBrooming = 'exposed_cloves_brooming';
  static const String symptomStorageSprouting = 'storage_sprouting';
  static const String symptomSunscaldOuterScales = 'sunscald_outer_scales';
  static const String symptomBulbMiteScars = 'bulb_mite_scars';
  // Manzano / árbol perenne
  static const String symptomBlightedBlossomsShoots =
      'blighted_blossoms_shoots';
  static const String symptomVelvetyOliveSpots = 'velvety_olive_spots';
  static const String symptomFruitTunnelFrass = 'fruit_tunnel_frass';
  static const String symptomWoollyWhiteColonies = 'woolly_white_colonies';
  static const String symptomFruitSunkenPits = 'fruit_sunken_pits';
  static const String symptomFruitSunburnPatch = 'fruit_sunburn_patch';
  static const String symptomInternervalChlorosisNewLeaves =
      'internerval_chlorosis_new_leaves';
  static const String symptomShootDecayCanker = 'shoot_decay_canker';
  static const String symptomMummifiedFruitRot = 'mummified_fruit_rot';
  // Pera
  static const String symptomHoneydewSootyShoots = 'honeydew_sooty_shoots';

  // Durazno (frutal de hueso/carozo) — síntomas propios (doc 04 §8.2).
  static const String symptomLeafCurlReddened = 'leaf_curl_reddened';
  static const String symptomShotHoleLeafSpots = 'shot_hole_leaf_spots';
  static const String symptomTrunkBaseGumFrass = 'trunk_base_gum_frass';

  // Nogal pecanero (frutal de nuez) — síntomas propios (doc 04 §10).
  static const String symptomNutShuckTunnels = 'nut_shuck_tunnels';
  static const String symptomKernelDarkSpots = 'kernel_dark_spots';
  static const String symptomRosetteLittleLeaf = 'rosette_little_leaf';
  static const String symptomShuckDiebackBlackening =
      'shuck_dieback_blackening';
  static const String symptomPrematureNutDrop = 'premature_nut_drop';

  // Pistache (frutal de nuez, dioico) — síntomas propios (doc 04 §5, §6, §8).
  static const String symptomNutwormMummies = 'pistachio_nutworm_mummies';
  static const String symptomEarlySplitStaining =
      'pistachio_early_split_staining';
  static const String symptomPanicleShootBlight =
      'pistachio_panicle_shoot_blight';
  static const String symptomBlankClosedNut = 'pistachio_blank_closed_nut';

  // Naranjo (cítrico siempreverde) — síntomas propios (doc 04 §5, §8.4).
  static const String symptomCitrusBlotchyMottle = 'citrus_blotchy_mottle';
  static const String symptomCitrusSmallLopsidedFruit =
      'citrus_small_lopsided_fruit';
  static const String symptomCitrusGummosisTrunk = 'citrus_gummosis_trunk';
  static const String symptomCitrusSplitFruit = 'citrus_split_fruit';
  static const String symptomCitrusRindScarring = 'citrus_rind_scarring';
  static const String symptomCitrusRaisedCorkyHaloLesions =
      'citrus_raised_corky_halo_lesions';

  // Tulipán (Doc C §12.2): observaciones visuales del bulbo, follaje, tallo y
  // flor que reporta el usuario. NUNCA diagnósticos. La sonda no ve tejido,
  // insectos ni el bulbo enterrado: estos síntomas los reporta la persona.
  static const String symptomTulipFoliageYellowing = 'tulip_foliage_yellowing';
  static const String symptomTulipBulbSoftWatery = 'tulip_bulb_soft_watery';
  static const String symptomTulipBasalDryRot = 'tulip_basal_dry_rot';
  static const String symptomTulipBlueGreenMold = 'tulip_blue_green_mold';
  static const String symptomTulipSubterraneanShootRot =
      'tulip_subterranean_shoot_rot';
  static const String symptomTulipEthyleneDamage = 'tulip_ethylene_damage';
  static const String symptomTulipStemTopple = 'tulip_stem_topple';
  static const String symptomTulipWeakElongatedStem =
      'tulip_weak_elongated_stem';
  static const String symptomTulipShortBloom = 'tulip_short_bloom';
  static const String symptomTulipSaltRootBurn = 'tulip_salt_root_burn';
  static const String symptomTulipEdema = 'tulip_edema';
  static const String symptomTulipFoliageRemovedEarly =
      'tulip_foliage_removed_early';
  static const String symptomTulipPhysicalDamage = 'tulip_physical_damage';
  static const String symptomTulipBulbRingsDistortion =
      'tulip_bulb_rings_distortion';

  // Girasol / Sunflower (Doc C §4.2): sintomas nuevos. Observaciones
  // visuales que reporta el usuario, nunca diagnosticos.
  static const String symptomSunflowerTurgorLoss = 'sunflower_turgor_loss';
  static const String symptomSunflowerLodging = 'sunflower_lodging';
  static const String symptomSunflowerWildlifeDamage =
      'sunflower_wildlife_damage';
  static const String symptomSunflowerBudDelayed = 'sunflower_bud_delayed';
  static const String symptomSunflowerHeadDeformation =
      'sunflower_head_deformation';
  static const String symptomSunflowerHeadSoftRot = 'sunflower_head_soft_rot';
  static const String symptomSunflowerHeadDryRot = 'sunflower_head_dry_rot';
  static const String symptomSunflowerHeadDroop = 'sunflower_head_droop';
  static const String symptomSunflowerNutrientPattern =
      'sunflower_nutrient_pattern';
  static const String symptomSunflowerNormalSenescence =
      'sunflower_normal_senescence';

  // Signals
  static const String signalPustulesOnStem = 'pustules_on_stem';
  static const String signalNoClearPustules = 'no_clear_pustules';
  static const String signalHumidWindow = 'humid_window';
  static const String signalCoolDewyWindow = 'cool_dewy_window';
  static const String signalAphidEarlyToxicity = 'early_toxicity';
  static const String signalSpikeFeeding = 'spike_feeding';
  static const String signalLeafRolling = 'leaf_rolling';
  static const String signalActiveChewing = 'active_chewing';
  static const String signalNoBiteMarks = 'no_bite_marks';
  static const String signalRapidFoliarCollapse = 'rapid_foliar_collapse';
  static const String signalFrassPresent = 'frass_present';
  static const String signalDeadHeart = 'dead_heart';
  static const String signalVectorPresent = 'vector_present';
  static const String signalCannotScrapeOff = 'cannot_scrape_off';
  static const String signalSporesRubOff = 'spores_rub_off';
  static const String signalMoldOnEar = 'mold_on_ear';
  static const String signalSilkDamage = 'silk_damage';
  static const String signalDarkStriations = 'dark_striations';
  static const String signalStickyHoneydew = 'sticky_honeydew';
  static const String signalSootyMold = 'sooty_mold';
  static const String signalWhiteflyCloud = 'whitefly_cloud';
  static const String signalSeedStaining = 'seed_staining';
  static const String signalNetPattern = 'net_pattern';
  static const String signalScaldBleaching = 'scald_bleaching';
  static const String signalPodCanker = 'pod_canker';
  static const String signalWaterSoakedMargin = 'water_soaked_margin';
  static const String signalAngularLesionPattern = 'angular_lesion_pattern';
  static const String signalPinkSporeMass = 'pink_spore_mass';
  static const String signalWhitePowderGrowth = 'white_powder_growth';
  static const String signalGrayFuzzyGrowth = 'gray_fuzzy_growth';
  static const String signalHaloMargin = 'halo_margin';
  static const String signalVascularBrowning = 'vascular_browning';
  static const String signalOneSidedWilt = 'one_sided_wilt';
  static const String signalFruitApicalBlackPatch = 'fruit_apical_black_patch';
  static const String signalThripsPresent = 'thrips_present';
  static const String signalBronzedLeafSurface = 'bronzed_leaf_surface';
  static const String signalMitesWebbing = 'mites_webbing';
  static const String signalRootGalls = 'root_galls';
  static const String signalStemCanker = 'stem_canker';
  static const String signalUndersideSporulation = 'underside_sporulation';
  static const String signalSeedlingNeckCollapse = 'seedling_neck_collapse';
  static const String signalWaterlogging = 'waterlogging';
  static const String signalRootsDarkRot = 'roots_dark_rot';
  static const String signalHeatStress = 'heat_stress';
  static const String signalDryHotWindow = 'dry_hot_window';
  static const String signalFlowerDrop = 'flower_drop';
  static const String signalFruitHooking = 'fruit_hooking';
  static const String signalDeformedNoRot = 'deformed_no_rot';
  static const String signalSalinityLoad = 'salinity_load';
  static const String signalLeafMines = 'leaf_mines';
  static const String signalFeedingHoles = 'feeding_holes';
  static const String signalPurpleDownySporulation = 'purple_downy_sporulation';
  static const String signalCrownDistortion = 'crown_distortion';
  static const String signalBoltingStem = 'bolting_stem';
  static const String signalTanPaperySpots = 'tan_papery_spots';
  static const String signalWaterSoakedSpots = 'water_soaked_spots';
  static const String signalDenseWetCanopy = 'dense_wet_canopy';
  static const String signalAphidContamination = 'aphid_contamination';
  static const String signalWhitePustules = 'white_pustules';
  static const String signalLeafEdgeBurn = 'leaf_edge_burn';
  static const String signalPoorEmergence = 'poor_emergence';
  static const String signalColdExposure = 'cold_exposure';
  static const String signalRecentStress = 'recent_stress';
  // Cactus ornamental: comprobaciones visuales/táctiles normalizadas.
  static const String signalCactusSoftOrWatery = 'cactus_soft_or_watery';
  static const String signalCactusFirmDry = 'cactus_firm_dry';
  static const String signalCactusProgressing = 'cactus_progressing';
  static const String signalCactusStable = 'cactus_stable';
  static const String signalCactusDarkExudate = 'cactus_dark_exudate';
  static const String signalCactusAbnormalOdor = 'cactus_abnormal_odor';
  static const String signalCactusCottonWaxScale = 'cactus_cotton_wax_scale';
  static const String signalCactusFineWebbing = 'cactus_fine_webbing';
  static const String signalCactusSunnySide = 'cactus_sunny_side';
  static const String signalCactusChangedSunExposure =
      'cactus_changed_sun_exposure';
  static const String signalCactusWrinkling = 'cactus_wrinkling';
  static const String signalCactusNewLeaning = 'cactus_new_leaning';
  static const String signalCactusLossOfSupport = 'cactus_loss_of_support';
  // Suculenta ornamental (Doc C §13.5): comprobaciones visuales/táctiles
  // normalizadas. Sirven para DESCARTAR, no para diagnosticar.
  static const String signalSucculentSoftOrWatery = 'succulent_soft_or_watery';
  static const String signalSucculentFirmDry = 'succulent_firm_dry';
  static const String signalSucculentProgressing = 'succulent_progressing';
  static const String signalSucculentStable = 'succulent_stable';
  static const String signalSucculentAbnormalOdor = 'succulent_abnormal_odor';
  static const String signalSucculentWrinkling = 'succulent_wrinkling';
  static const String signalSucculentElongatedPaleGrowth =
      'succulent_elongated_pale_growth';
  static const String signalSucculentRosetteOpening =
      'succulent_rosette_opening';
  static const String signalSucculentChangedSunExposure =
      'succulent_changed_sun_exposure';
  static const String signalSucculentSunnySide = 'succulent_sunny_side';
  static const String signalSucculentUniformWaxyBloom =
      'succulent_uniform_waxy_bloom';
  static const String signalSucculentPowderyPatches =
      'succulent_powdery_patches';
  static const String signalSucculentCottonWaxInsects =
      'succulent_cotton_wax_insects';
  static const String signalSucculentScaleBodies = 'succulent_scale_bodies';
  static const String signalSucculentFineWebbing = 'succulent_fine_webbing';
  static const String signalSucculentRaisedBlisters =
      'succulent_raised_blisters';
  static const String signalSucculentCorkyScabs = 'succulent_corky_scabs';
  static const String signalSucculentRecentSpray = 'succulent_recent_spray';
  static const String signalSucculentDropletPattern =
      'succulent_droplet_pattern';
  static const String signalSucculentFungusGnats = 'succulent_fungus_gnats';
  static const String signalSucculentLowerLeavesOnly =
      'succulent_lower_leaves_only';
  static const String signalSucculentLossOfSupport =
      'succulent_loss_of_support';
  // Sábila / Aloe ornamental (Doc C §4): señales de apoyo que el usuario
  // reporta. Las marcadas ★ son exclusivas de la sábila (ácaro de agalla).
  static const String signalAloeSoftOrWatery = 'aloe_soft_or_watery';
  static const String signalAloeFirmDry = 'aloe_firm_dry';
  static const String signalAloeProgressing = 'aloe_progressing';
  static const String signalAloeStable = 'aloe_stable';
  static const String signalAloeAbnormalOdor = 'aloe_abnormal_odor';
  static const String signalAloeLossOfSupport = 'aloe_loss_of_support';
  static const String signalAloeWrinkling = 'aloe_wrinkling';
  static const String signalAloeWartyGrowth = 'aloe_warty_growth'; // ★
  static const String signalAloeCrookedFlowerStalk =
      'aloe_crooked_flower_stalk'; // ★
  static const String signalAloeTouchingAnotherAloe =
      'aloe_touching_another_aloe'; // ★
  static const String signalAloeGlassyTranslucent = 'aloe_glassy_translucent';
  static const String signalAloeReddishBrownBase = 'aloe_reddish_brown_base';
  static const String signalAloeChangedSunExposure =
      'aloe_changed_sun_exposure';
  static const String signalAloeSunnySide = 'aloe_sunny_side';
  static const String signalAloeDryHardSpots = 'aloe_dry_hard_spots';
  static const String signalAloeWetAdvancingLesion =
      'aloe_wet_advancing_lesion';
  static const String signalAloeCottonWaxInsects = 'aloe_cotton_wax_insects';
  static const String signalAloeScaleBodies = 'aloe_scale_bodies';
  static const String signalAloeStickySooty = 'aloe_sticky_sooty';
  static const String signalAloeFineStippling = 'aloe_fine_stippling';
  static const String signalAloeFineWebbing = 'aloe_fine_webbing';
  static const String signalAloeWhiteCrustSubstrate =
      'aloe_white_crust_substrate';
  static const String signalAloeRecentFertilizer = 'aloe_recent_fertilizer';
  static const String signalAloeRecentSpray = 'aloe_recent_spray';
  static const String signalAloeDropletPattern = 'aloe_droplet_pattern';
  static const String signalAloeElongatedPaleGrowth =
      'aloe_elongated_pale_growth';
  static const String signalAloeLowerLeavesOnly = 'aloe_lower_leaves_only';
  static const String signalAloeFungusGnats = 'aloe_fungus_gnats';
  static const String signalAloeLeafCutRecent = 'aloe_leaf_cut_recent';
  // Maguey / Agave (Doc C §4): observaciones normalizadas (firmeza, color,
  // superficie, forma, insecto, progresión) que el usuario reporta al confirmar.
  static const String signalAgaveSoftOrWatery = 'agave_soft_or_watery';
  static const String signalAgaveFirmDry = 'agave_firm_dry';
  static const String signalAgaveDryCorkyBud = 'agave_dry_corky_bud';
  static const String signalAgaveLossOfAnchor = 'agave_loss_of_anchor';
  static const String signalAgaveCenterCollapse = 'agave_center_collapse';
  static const String signalAgaveAbnormalOdor = 'agave_abnormal_odor';
  static const String signalAgaveBasalLeafDryOnly = 'agave_basal_leaf_dry_only';
  static const String signalAgaveProgressing = 'agave_progressing';
  static const String signalAgaveStable = 'agave_stable';
  static const String signalAgaveSnoutWeevilAdult = 'agave_snout_weevil_adult';
  static const String signalAgaveCreamLarvaeGalleries =
      'agave_cream_larvae_galleries';
  static const String signalAgaveGreasyStreakInnerLeaf =
      'agave_greasy_streak_inner_leaf';
  static const String signalAgaveDeformedCore = 'agave_deformed_core';
  static const String signalAgaveSoftScaleBodies = 'agave_soft_scale_bodies';
  static const String signalAgaveStickySooty = 'agave_sticky_sooty';
  static const String signalAgaveSmallPlantBugs = 'agave_small_plant_bugs';
  static const String signalAgavePaleFeedingScars =
      'agave_pale_feeding_scars';
  static const String signalAgaveSunkenConcentricRings =
      'agave_sunken_concentric_rings';
  static const String signalAgavePinkOrangeSporeMass =
      'agave_pink_orange_spore_mass';
  static const String signalAgaveGraySpotChloroticHalo =
      'agave_gray_spot_chlorotic_halo';
  static const String signalAgaveLesionReachingCore =
      'agave_lesion_reaching_core';
  static const String signalAgaveFrostBlackenedTissue =
      'agave_frost_blackened_tissue';
  static const String signalAgaveSunnySidePatch = 'agave_sunny_side_patch';
  static const String signalAgaveChangedSunExposure =
      'agave_changed_sun_exposure';
  static const String signalAgaveWhiteCrustSubstrate =
      'agave_white_crust_substrate';
  static const String signalAgaveRecentFertilizer = 'agave_recent_fertilizer';
  static const String signalAgaveLeafTipEdgeBurn = 'agave_leaf_tip_edge_burn';
  static const String signalAgaveMechanicalWoundMark =
      'agave_mechanical_wound_mark';
  static const String signalAgaveOffsetRemovalRecent =
      'agave_offset_removal_recent';
  static const String signalAgaveMissingChewedTissue =
      'agave_missing_chewed_tissue';
  static const String signalAgaveAnimalTracksScat = 'agave_animal_tracks_scat';
  static const String signalAgaveCentralFlowerStalk =
      'agave_central_flower_stalk';
  static const String signalAgaveOffsetsPresent = 'agave_offsets_present';
  static const String signalAgaveGradualOuterDrying =
      'agave_gradual_outer_drying';
  static const String signalAgaveUniformWaxyBloom = 'agave_uniform_waxy_bloom';
  static const String signalAgaveLeafImprint = 'agave_leaf_imprint';
  // Cebolla / bulbo
  static const String signalThripsSilverScarring = 'thrips_silver_scarring';
  static const String signalThripsInNeckFolds = 'thrips_in_neck_folds';
  static const String signalDownyFuzzyGrowth = 'downy_fuzzy_growth';
  static const String signalPurpleConcentricLesions =
      'purple_concentric_lesions';
  static const String signalDarkOliveLeafBlight = 'dark_olive_leaf_blight';
  static const String signalWhiteSunkenLeafSpots = 'white_sunken_leaf_spots';
  static const String signalPinkRoots = 'pink_roots';
  static const String signalBasalPlateBrownRot = 'basal_plate_brown_rot';
  static const String signalWhiteMyceliumSclerotia = 'white_mycelium_sclerotia';
  static const String signalNeckSoft = 'neck_soft';
  static const String signalGrayMoldNeck = 'gray_mold_neck';
  static const String signalBulbScaleWaterSoaked = 'bulb_scale_water_soaked';
  static const String signalSourSmell = 'sour_smell';
  static const String signalBlackMoldSpores = 'black_mold_spores';
  static const String signalBlueGreenMold = 'blue_green_mold';
  static const String signalCenterLeafBleaching = 'center_leaf_bleaching';
  static const String signalStrawDiamondLesions = 'straw_diamond_lesions';
  static const String signalNoBulbPhotoperiod = 'no_bulb_photoperiod';
  static const String signalThickNeck = 'thick_neck';
  static const String signalBulbSplitting = 'bulb_splitting';
  static const String signalSeedstalkBolting = 'seedstalk_bolting';
  static const String signalMaggotLarvae = 'maggot_larvae';
  static const String signalPoorCuringNeckMoist = 'poor_curing_neck_moist';
  static const String signalSeedCloveBlueGreenMold =
      'seed_clove_blue_green_mold';
  static const String signalSoftCloveBeforePlanting =
      'soft_clove_before_planting';
  static const String signalBulbMiteBrownScars = 'bulb_mite_brown_scars';
  static const String signalDistortedSpongyBulb = 'distorted_spongy_bulb';
  static const String signalPoorCloveDifferentiation =
      'poor_clove_differentiation';
  static const String signalExposedClovesBrooming = 'exposed_cloves_brooming';
  static const String signalUnexpectedScape = 'unexpected_scape';
  static const String signalLateGreenExcessVigor = 'late_green_excess_vigor';
  static const String signalStorageSprouting = 'storage_sprouting';
  static const String signalSunscaldOuterScales = 'sunscald_outer_scales';
  static const String signalUniformLeafBurn = 'uniform_leaf_burn';
  static const String signalWeedCompetition = 'weed_competition';
  // Manzano / árbol perenne
  static const String signalAmberBacterialOoze = 'amber_bacterial_ooze';
  static const String signalShepherdsCrookShoot = 'shepherds_crook_shoot';
  static const String signalFrostEvent = 'frost_event';
  static const String signalHailEvent = 'hail_event';
  static const String signalGallsOnWoodRoots = 'galls_on_wood_roots';
  static const String signalHighPhCalcareous = 'high_ph_calcareous';
  static const String signalExposedFruitSouthwest = 'exposed_fruit_southwest';
  static const String signalSpringWetFoliage = 'spring_wet_foliage';
  // Pera
  static const String signalPsyllaNymphsShoots = 'psylla_nymphs_shoots';
  static const String signalNoPollinatorNearby = 'no_pollinator_nearby';

  // Durazno (frutal de hueso/carozo) — señales propias (doc 04 §8.2).
  static const String signalShootTipWilt = 'shoot_tip_wilt';
  static const String signalInsufficientChill = 'insufficient_chill';

  // Nogal pecanero (frutal de nuez) — señales propias (doc 04 §10).
  static const String signalShuckStuck = 'shuck_stuck';
  static const String signalRoundBbExitHole = 'round_bb_exit_hole';
  static const String signalYellowAphids = 'yellow_aphids';
  static const String signalBlackPecanAphids = 'black_pecan_aphids';

  // Pistache (frutal de nuez, dioico) — señales propias (doc 04 §5, §6, §8).
  static const String signalNavelOrangeworm = 'navel_orangeworm';
  static const String signalMummyNuts = 'mummy_nuts';
  static const String signalEarlyHullSplit = 'early_hull_split';

  // Naranjo (cítrico siempreverde) — señales propias (doc 04 §8.5).
  static const String signalAsymmetricMottle = 'asymmetric_mottle';
  static const String signalPsyllidWaxyTubules = 'psyllid_waxy_tubules';
  static const String signalFlushNewGrowth = 'flush_new_growth';
  static const String signalFruitBitterMisshapen = 'fruit_bitter_misshapen';
  static const String signalGumAtTrunkBase = 'gum_at_trunk_base';
  static const String signalRindScarsNearCalyx = 'rind_scars_near_calyx';
  static const String signalFruitSplitAfterIrrigation =
      'fruit_split_after_irrigation';
  static const String signalFruitLowCanopyRainSplash =
      'fruit_low_canopy_rain_splash';
  static const String signalWhiteGreenBlueMold = 'white_green_blue_mold';
  static const String signalRecentSprayOilCopper = 'recent_spray_oil_copper';
  static const String signalFruitLarvae = 'fruit_larvae';

  // Rosal ornamental (Doc C): observaciones visuales, no diagnósticos.
  // La sonda no ve hojas, flores, insectos ni tejido: estos síntomas y señales
  // los reporta el usuario. Ninguna confirma por sí sola un organismo causal.
  static const String symptomRoseRosetteExcessPrickles =
      'rose_rosette_excess_prickles';
  static const String symptomRoseChlorosisWeakGrowth =
      'rose_chlorosis_weak_growth';
  static const String symptomRoseScaleCottonSooty = 'rose_scale_cotton_sooty';

  // Señales propias del Rosal (Doc C §26.3): observaciones de apoyo que el
  // usuario reporta al confirmar. Sirven para diferenciar y para DESCARTAR.
  static const String signalRoseAntActivity = 'rose_ant_activity';
  static const String signalRoseBeetlesOnFlower = 'rose_beetles_on_flower';
  static const String signalRoseBeneficialPredators =
      'rose_beneficial_predators';
  static const String signalRoseBentBlackenedShootTip =
      'rose_bent_blackened_shoot_tip';
  static const String signalRoseBleachedBlackenedCane =
      'rose_bleached_blackened_cane';
  static const String signalRoseBorerHoleFrass = 'rose_borer_hole_frass';
  static const String signalRoseBranchDieback = 'rose_branch_dieback';
  static const String signalRoseBrownSpottedPetals =
      'rose_brown_spotted_petals';
  static const String signalRoseBudDistortion = 'rose_bud_distortion';
  static const String signalRoseBudFailsToOpen = 'rose_bud_fails_to_open';
  static const String signalRoseBudsSepalsWhite = 'rose_buds_sepals_white';
  static const String signalRoseCaneDiesFromTip = 'rose_cane_dies_from_tip';
  static const String signalRoseCaneUniformlyGreenInside =
      'rose_cane_uniformly_green_inside';
  static const String signalRoseCastSkins = 'rose_cast_skins';
  static const String signalRoseCleanSemicircleCut =
      'rose_clean_semicircle_cut';
  static const String signalRoseCottonyWax = 'rose_cottony_wax';
  static const String signalRoseCrackedFlakingBark =
      'rose_cracked_flaking_bark';
  static const String signalRoseCrowdedNewGrowth = 'rose_crowded_new_growth';
  static const String signalRoseCrownBrownOrSoft = 'rose_crown_brown_or_soft';
  static const String signalRoseCrownFirmNormal = 'rose_crown_firm_normal';
  static const String signalRoseDamageHotWeather = 'rose_damage_hot_weather';
  static const String signalRoseDamageOnlyAfterAging =
      'rose_damage_only_after_aging';
  static const String signalRoseDamageProgressesHumidCool =
      'rose_damage_progresses_humid_cool';
  static const String signalRoseDeadBranchAmongHealthy =
      'rose_dead_branch_among_healthy';
  static const String signalRoseDeclineProgressing =
      'rose_decline_progressing';
  static const String signalRoseDeformedLeavesFlowers =
      'rose_deformed_leaves_flowers';
  static const String signalRoseDropletPattern = 'rose_droplet_pattern';
  static const String signalRoseDustyCrowdedSite = 'rose_dusty_crowded_site';
  static const String signalRoseExcessPrickles = 'rose_excess_prickles';
  static const String signalRoseFeatheryBlackMargin =
      'rose_feathery_black_margin';
  static const String signalRoseFewFeederRoots = 'rose_few_feeder_roots';
  static const String signalRoseFineStippling = 'rose_fine_stippling';
  static const String signalRoseFineWebbing = 'rose_fine_webbing';
  static const String signalRoseFixedScaleBodies = 'rose_fixed_scale_bodies';
  static const String signalRoseFlowerOpenedNormally =
      'rose_flower_opened_normally';
  static const String signalRoseFungusGnats = 'rose_fungus_gnats';
  static const String signalRoseGallAtSoilLine = 'rose_gall_at_soil_line';
  static const String signalRoseGallHardensDarkens =
      'rose_gall_hardens_darkens';
  static const String signalRoseGallInsectExitHole =
      'rose_gall_insect_exit_hole';
  static const String signalRoseGrayCenterBlackDots =
      'rose_gray_center_black_dots';
  static const String signalRoseGrayFuzzyFlower = 'rose_gray_fuzzy_flower';
  static const String signalRoseGrowthNormalizes = 'rose_growth_normalizes';
  static const String signalRoseHealthyBasalBreak = 'rose_healthy_basal_break';
  static const String signalRoseHerbicideAffectsOtherPlants =
      'rose_herbicide_affects_other_plants';
  static const String signalRoseHighPhContext = 'rose_high_ph_context';
  static const String signalRoseInsectEggsDistinct =
      'rose_insect_eggs_distinct';
  static const String signalRoseInsectsNodes = 'rose_insects_nodes';
  static const String signalRoseInsectsTenderShoots =
      'rose_insects_tender_shoots';
  static const String signalRoseInterveinalChlorosisNewLeaves =
      'rose_interveinal_chlorosis_new_leaves';
  static const String signalRoseInterveinalChlorosisNoPattern =
      'rose_interveinal_chlorosis_no_pattern';
  static const String signalRoseKnownGraftedStock =
      'rose_known_grafted_stock';
  static const String signalRoseLargeSilverScarsThrips =
      'rose_large_silver_scars_thrips';
  static const String signalRoseLarvaeUnderLeaf = 'rose_larvae_under_leaf';
  static const String signalRoseLeafCenterFallsFromSpot =
      'rose_leaf_center_falls_from_spot';
  static const String signalRoseLeafGrayOffGreen = 'rose_leaf_gray_off_green';
  static const String signalRoseLeafLeatheryWrinkled =
      'rose_leaf_leathery_wrinkled';
  static const String signalRoseLeafTwistingWithOrange =
      'rose_leaf_twisting_with_orange';
  static const String signalRoseLeafYellowing = 'rose_leaf_yellowing';
  static const String signalRoseLossOfSupport = 'rose_loss_of_support';
  static const String signalRoseLowNReadingRepeated =
      'rose_low_n_reading_repeated';
  static const String signalRoseLowerLeavesFirst = 'rose_lower_leaves_first';
  static const String signalRoseMitesUnderLeaf = 'rose_mites_under_leaf';
  static const String signalRoseMultipleGalls = 'rose_multiple_galls';
  static const String signalRoseNarrowLeavesCupping =
      'rose_narrow_leaves_cupping';
  static const String signalRoseNearOtherSymptomaticRoses =
      'rose_near_other_symptomatic_roses';
  static const String signalRoseNoGrowthDistortion =
      'rose_no_growth_distortion';
  static const String signalRoseNoHoneydew = 'rose_no_honeydew';
  static const String signalRoseNoInsectsNoMoldStable =
      'rose_no_insects_no_mold_stable';
  static const String signalRoseNormalCaneLenticels =
      'rose_normal_cane_lenticels';
  static const String signalRoseNormalFullSizedLeaves =
      'rose_normal_full_sized_leaves';
  static const String signalRoseNormalOldWood = 'rose_normal_old_wood';
  static const String signalRoseNormalPrickleDensity =
      'rose_normal_prickle_density';
  static const String signalRoseNormalRedGrowthTurnsGreen =
      'rose_normal_red_growth_turns_green';
  static const String signalRoseNormalRootFlare = 'rose_normal_root_flare';
  static const String signalRoseNormalSeasonalAging =
      'rose_normal_seasonal_aging';
  static const String signalRoseOldSpentFlower = 'rose_old_spent_flower';
  static const String signalRoseOnlyOneCaneAffected =
      'rose_only_one_cane_affected';
  static const String signalRoseOrangeObjectsDoNotSmear =
      'rose_orange_objects_do_not_smear';
  static const String signalRoseOrangePowderUnderLeaf =
      'rose_orange_powder_under_leaf';
  static const String signalRosePatternRepeatsNewLeaves =
      'rose_pattern_repeats_new_leaves';
  static const String signalRosePersistentRedYellowDistortion =
      'rose_persistent_red_yellow_distortion';
  static const String signalRosePetalScratchesFlecks =
      'rose_petal_scratches_flecks';
  static const String signalRosePetalsEaten = 'rose_petals_eaten';
  static const String signalRosePlantRecoversAfterIrrigation =
      'rose_plant_recovers_after_irrigation';
  static const String signalRosePowderRubsOrSmears =
      'rose_powder_rubs_or_smears';
  static const String signalRosePrematureLeafDrop =
      'rose_premature_leaf_drop';
  static const String signalRoseProgressesToOtherBranches =
      'rose_progresses_to_other_branches';
  static const String signalRosePurchasedWithSwelling =
      'rose_purchased_with_swelling';
  static const String signalRosePurpleBlackCaneLesion =
      'rose_purple_black_cane_lesion';
  static const String signalRosePurpleRedBrownSpots =
      'rose_purple_red_brown_spots';
  static const String signalRoseRaisedOrangeBumps =
      'rose_raised_orange_bumps';
  static const String signalRoseRecentFertilizer = 'rose_recent_fertilizer';
  static const String signalRoseRecentPruning = 'rose_recent_pruning';
  static const String signalRoseRecentSpray = 'rose_recent_spray';
  static const String signalRoseRecentTransplant = 'rose_recent_transplant';
  static const String signalRoseRecentWetWeather = 'rose_recent_wet_weather';
  static const String signalRoseRedTintAroundPowder =
      'rose_red_tint_around_powder';
  static const String signalRoseReflectedHeat = 'rose_reflected_heat';
  static const String signalRoseRootDeclineSigns = 'rose_root_decline_signs';
  static const String signalRoseRootsFirmWhiteTips =
      'rose_roots_firm_white_tips';
  static const String signalRoseRoughIrregularGall =
      'rose_rough_irregular_gall';
  static const String signalRoseSandyCalcareousSoil =
      'rose_sandy_calcareous_soil';
  static const String signalRoseShortWeakShoots = 'rose_short_weak_shoots';
  static const String signalRoseSkeletonizedLeaf = 'rose_skeletonized_leaf';
  static const String signalRoseSmoothRegularGraftUnion =
      'rose_smooth_regular_graft_union';
  static const String signalRoseSoftBodiedColonies =
      'rose_soft_bodied_colonies';
  static const String signalRoseSoftTemporaryCallus =
      'rose_soft_temporary_callus';
  static const String signalRoseSoilDry = 'rose_soil_dry';
  static const String signalRoseSoilDryDuringWilt =
      'rose_soil_dry_during_wilt';
  static const String signalRoseSourAbnormalOdor = 'rose_sour_abnormal_odor';
  static const String signalRoseSpotsDoNotProgress =
      'rose_spots_do_not_progress';
  static const String signalRoseSpotsOnCanes = 'rose_spots_on_canes';
  static const String signalRoseSpotsProgressWetWindow =
      'rose_spots_progress_wet_window';
  static const String signalRoseStableOldSwelling =
      'rose_stable_old_swelling';
  static const String signalRoseStemSwelling = 'rose_stem_swelling';
  static const String signalRoseStuntedAboveGall = 'rose_stunted_above_gall';
  static const String signalRoseStunting = 'rose_stunting';
  static const String signalRoseSunnyExposedSide = 'rose_sunny_exposed_side';
  static const String signalRoseSunnySideDamage = 'rose_sunny_side_damage';
  static const String signalRoseSymptomsCoolWeather =
      'rose_symptoms_cool_weather';
  static const String signalRoseThickenedCane = 'rose_thickened_cane';
  static const String signalRoseTinyInsectsInsideFlower =
      'rose_tiny_insects_inside_flower';
  static const String signalRoseUniformEdgeScorch =
      'rose_uniform_edge_scorch';
  static const String signalRoseUniformOldLeafYellowing =
      'rose_uniform_old_leaf_yellowing';
  static const String signalRoseUniformSprayResidue =
      'rose_uniform_spray_residue';
  static const String signalRoseUniformYellowOldLeaves =
      'rose_uniform_yellow_old_leaves';
  static const String signalRoseUpperLeafDiscoloration =
      'rose_upper_leaf_discoloration';
  static const String signalRoseVeinClearing = 'rose_vein_clearing';
  static const String signalRoseVeinLimitedAngular =
      'rose_vein_limited_angular';
  static const String signalRoseWarmDayCoolNight = 'rose_warm_day_cool_night';
  static const String signalRoseWeakShoots = 'rose_weak_shoots';
  static const String signalRoseWiltsWhileSoilWet =
      'rose_wilts_while_soil_wet';
  static const String signalRoseWindowpaneDamage = 'rose_windowpane_damage';
  static const String signalRoseWitchesBroom = 'rose_witches_broom';
  static const String signalRoseWoundNearGall = 'rose_wound_near_gall';
  static const String signalRoseYellowHaloOrLeaf = 'rose_yellow_halo_or_leaf';
  static const String signalRoseYellowRingsZigzags =
      'rose_yellow_rings_zigzags';
  static const String signalRoseYellowWavyLines = 'rose_yellow_wavy_lines';
  static const String signalRoseYoungLeavesCurled =
      'rose_young_leaves_curled';

  // Tulipán (Doc C §12.2): señales de apoyo que el usuario reporta al confirmar.
  // Sirven para diferenciar y para DESCARTAR; ninguna confirma por sí sola una
  // enfermedad, una plaga ni un organismo causal.
  static const String signalTulipPostBloomTiming = 'tulip_post_bloom_timing';
  static const String signalTulipGradualYellowing = 'tulip_gradual_yellowing';
  static const String signalTulipPrematureTiming = 'tulip_premature_timing';
  static const String signalTulipTissueFirm = 'tulip_tissue_firm';
  static const String signalTulipSoftOrWatery = 'tulip_soft_or_watery';
  static const String signalTulipAbnormalOdor = 'tulip_abnormal_odor';
  static const String signalTulipRapidProgression = 'tulip_rapid_progression';
  static const String signalTulipBasalBrownRot = 'tulip_basal_brown_rot';
  static const String signalTulipRootsAbsentOrRotted =
      'tulip_roots_absent_or_rotted';
  static const String signalTulipSourOdor = 'tulip_sour_odor';
  static const String signalTulipPinkWhiteGrowth = 'tulip_pink_white_growth';
  static const String signalTulipRootsGlassy = 'tulip_roots_glassy';
  static const String signalTulipRootsBrown = 'tulip_roots_brown';
  static const String signalTulipRootsBreakEasily = 'tulip_roots_break_easily';
  static const String signalTulipRootRings = 'tulip_root_rings';
  static const String signalTulipShootRotBelowSoil =
      'tulip_shoot_rot_below_soil';
  static const String signalTulipRootsStillIntact = 'tulip_roots_still_intact';
  static const String signalTulipBrownWhiteSpots = 'tulip_brown_white_spots';
  static const String signalTulipGraySporulation = 'tulip_gray_sporulation';
  static const String signalTulipTwistedLeaves = 'tulip_twisted_leaves';
  static const String signalTulipBlackSclerotia = 'tulip_black_sclerotia';
  static const String signalTulipIrregularColorBreak =
      'tulip_irregular_color_break';
  static const String signalTulipLeafMottling = 'tulip_leaf_mottling';
  static const String signalTulipGeneticPetalPattern =
      'tulip_genetic_petal_pattern';
  static const String signalTulipStickyHoneydew = 'tulip_sticky_honeydew';
  static const String signalTulipVisibleAphids = 'tulip_visible_aphids';
  static const String signalTulipGum = 'tulip_gum';
  static const String signalTulipBudNecrosis = 'tulip_bud_necrosis';
  static const String signalTulipOpenShoot = 'tulip_open_shoot';
  static const String signalTulipFruitStoredNearby =
      'tulip_fruit_stored_nearby';
  static const String signalTulipDarkWateryStemZone =
      'tulip_dark_watery_stem_zone';
  static const String signalTulipLeafSplitting = 'tulip_leaf_splitting';
  static const String signalTulipConstrictionBend = 'tulip_constriction_bend';
  static const String signalTulipWaterDropletsFromTissue =
      'tulip_water_droplets_from_tissue';
  static const String signalTulipLeansTowardLight = 'tulip_leans_toward_light';
  static const String signalTulipThinPaleStem = 'tulip_thin_pale_stem';
  static const String signalTulipInterveinalChlorosis =
      'tulip_interveinal_chlorosis';
  static const String signalTulipWhiteCollapsedTissue =
      'tulip_white_collapsed_tissue';
  static const String signalTulipRapidOpening = 'tulip_rapid_opening';
  static const String signalTulipRootsShortCrooked =
      'tulip_roots_short_crooked';
  static const String signalTulipDarkRootTips = 'tulip_dark_root_tips';
  static const String signalTulipBulbMissing = 'tulip_bulb_missing';
  static const String signalTulipFreshExcavation = 'tulip_fresh_excavation';
  static const String signalTulipChewedTissue = 'tulip_chewed_tissue';
  static const String signalTulipLeavesCutGreen = 'tulip_leaves_cut_green';
  static const String signalTulipBrownConcentricRings =
      'tulip_brown_concentric_rings';

  // Girasol / Sunflower (Doc C §13, Anexo A): senales que el usuario
  // reporta al confirmar. Sirven para diferenciar y para DESCARTAR;
  // ninguna confirma por si sola una enfermedad, una plaga ni un
  // organismo causal.
  static const String signalSunflowerSeedMissingOrSoft =
      'sunflower_seed_missing_or_soft';
  static const String signalSunflowerSoilCrust = 'sunflower_soil_crust';
  static const String signalSunflowerUnevenPatches = 'sunflower_uneven_patches';
  static const String signalSunflowerDeepSowing = 'sunflower_deep_sowing';
  static const String signalSunflowerHealthyEmergenceNearby =
      'sunflower_healthy_emergence_nearby';
  static const String signalSunflowerSeedlingPresent =
      'sunflower_seedling_present';
  static const String signalSunflowerSoftDarkNeck = 'sunflower_soft_dark_neck';
  static const String signalSunflowerOuterRootSloughs =
      'sunflower_outer_root_sloughs';
  static const String signalSunflowerReddishBrownGirdle =
      'sunflower_reddish_brown_girdle';
  static const String signalSunflowerStemCleanCut = 'sunflower_stem_clean_cut';
  static const String signalSunflowerFirmDryBreak = 'sunflower_firm_dry_break';
  static const String signalSunflowerSlimeTrail = 'sunflower_slime_trail';
  static const String signalSunflowerSoftWateryBase =
      'sunflower_soft_watery_base';
  static const String signalSunflowerLossOfSupport =
      'sunflower_loss_of_support';
  static const String signalSunflowerAbnormalOdor = 'sunflower_abnormal_odor';
  static const String signalSunflowerRootsFirmLight =
      'sunflower_roots_firm_light';
  static const String signalSunflowerBaseFirmDry = 'sunflower_base_firm_dry';
  static const String signalSunflowerWiltInWetSoil =
      'sunflower_wilt_in_wet_soil';
  static const String signalSunflowerPatchOrSinglePlant =
      'sunflower_patch_or_single_plant';
  static const String signalSunflowerRecoversAfterWater =
      'sunflower_recovers_after_water';
  static const String signalSunflowerNormalPostBloomDroop =
      'sunflower_normal_post_bloom_droop';
  static const String signalSunflowerSoilDry = 'sunflower_soil_dry';
  static const String signalSunflowerRecoversEvening =
      'sunflower_recovers_evening';
  static const String signalSunflowerContainerHeated =
      'sunflower_container_heated';
  static const String signalSunflowerLeafEdgeDry = 'sunflower_leaf_edge_dry';
  static const String signalSunflowerNoRecoveryOvernight =
      'sunflower_no_recovery_overnight';
  static const String signalSunflowerPetioleCenteredLesion =
      'sunflower_petiole_centered_lesion';
  static const String signalSunflowerTriangularLeafLesion =
      'sunflower_triangular_leaf_lesion';
  static const String signalSunflowerHollowPith = 'sunflower_hollow_pith';
  static const String signalSunflowerPrematureDrying =
      'sunflower_premature_drying';
  static const String signalSunflowerLodging = 'sunflower_lodging';
  static const String signalSunflowerSuperficialBlackSpotOnly =
      'sunflower_superficial_black_spot_only';
  static const String signalSunflowerFirmIntactPith =
      'sunflower_firm_intact_pith';
  static const String signalSunflowerMechanicalBruise =
      'sunflower_mechanical_bruise';
  static const String signalSunflowerNewLeaning = 'sunflower_new_leaning';
  static const String signalSunflowerStemCrease = 'sunflower_stem_crease';
  static const String signalSunflowerRootPlateLoose =
      'sunflower_root_plate_loose';
  static const String signalSunflowerHeadHeavy = 'sunflower_head_heavy';
  static const String signalSunflowerWindEvent = 'sunflower_wind_event';
  static const String signalSunflowerStemThin = 'sunflower_stem_thin';
  static const String signalSunflowerSoilLooseWet = 'sunflower_soil_loose_wet';
  static const String signalSunflowerStemFirmVertical =
      'sunflower_stem_firm_vertical';
  static const String signalSunflowerStableAngle = 'sunflower_stable_angle';
  static const String signalSunflowerLowerLeavesFirst =
      'sunflower_lower_leaves_first';
  static const String signalSunflowerLesionsCoalesce =
      'sunflower_lesions_coalesce';
  static const String signalSunflowerRainSplash = 'sunflower_rain_splash';
  static const String signalSunflowerYellowThenBrown =
      'sunflower_yellow_then_brown';
  static const String signalSunflowerDefoliationBottomUp =
      'sunflower_defoliation_bottom_up';
  static const String signalSunflowerGradualUniformYellowing =
      'sunflower_gradual_uniform_yellowing';
  static const String signalSunflowerInsectBodies = 'sunflower_insect_bodies';
  static const String signalSunflowerPowderRubOff = 'sunflower_powder_rub_off';
  static const String signalSunflowerUpperSurfaceWhite =
      'sunflower_upper_surface_white';
  static const String signalSunflowerBlackSpecksLate =
      'sunflower_black_specks_late';
  static const String signalSunflowerUniformDustResidue =
      'sunflower_uniform_dust_residue';
  static const String signalSunflowerCottonyInsects =
      'sunflower_cottony_insects';
  static const String signalSunflowerVeinBoundChlorosis =
      'sunflower_vein_bound_chlorosis';
  static const String signalSunflowerSystemicStunting =
      'sunflower_systemic_stunting';
  static const String signalSunflowerYoungPlant = 'sunflower_young_plant';
  static const String signalSunflowerNoStunting = 'sunflower_no_stunting';
  static const String signalSunflowerAbioticPatternUniform =
      'sunflower_abiotic_pattern_uniform';
  static const String signalSunflowerCinnamonPustules =
      'sunflower_cinnamon_pustules';
  static const String signalSunflowerYellowHalo = 'sunflower_yellow_halo';
  static const String signalSunflowerUndersidePustules =
      'sunflower_underside_pustules';
  static const String signalSunflowerWildVolunteerNearby =
      'sunflower_wild_volunteer_nearby';
  static const String signalSunflowerSoilSplashOnly =
      'sunflower_soil_splash_only';
  static const String signalSunflowerFlatNecroticSpot =
      'sunflower_flat_necrotic_spot';
  static const String signalSunflowerInterveinalNecrosis =
      'sunflower_interveinal_necrosis';
  static const String signalSunflowerProgressesUpward =
      'sunflower_progresses_upward';
  static const String signalSunflowerPithShrunkenDark =
      'sunflower_pith_shrunken_dark';
  static const String signalSunflowerYoungLeavesOnly =
      'sunflower_young_leaves_only';
  static const String signalSunflowerUniformLateYellowing =
      'sunflower_uniform_late_yellowing';
  static const String signalSunflowerLowerLeavesOnly =
      'sunflower_lower_leaves_only';
  static const String signalSunflowerStageAfterBloom =
      'sunflower_stage_after_bloom';
  static const String signalSunflowerLowNPattern = 'sunflower_low_n_pattern';
  static const String signalSunflowerShadedLowerLeaves =
      'sunflower_shaded_lower_leaves';
  static const String signalSunflowerRapidWholePlantYellow =
      'sunflower_rapid_whole_plant_yellow';
  static const String signalSunflowerUpperLeavesFirst =
      'sunflower_upper_leaves_first';
  static const String signalSunflowerActiveSpotsOrPustules =
      'sunflower_active_spots_or_pustules';
  static const String signalSunflowerOlderLeavesFirst =
      'sunflower_older_leaves_first';
  static const String signalSunflowerRecentFertilizer =
      'sunflower_recent_fertilizer';
  static const String signalSunflowerWaterSoakedMargin =
      'sunflower_water_soaked_margin';
  static const String signalSunflowerActiveFungalMargin =
      'sunflower_active_fungal_margin';
  static const String signalSunflowerColdEvent = 'sunflower_cold_event';
  static const String signalSunflowerMosaicLightDark =
      'sunflower_mosaic_light_dark';
  static const String signalSunflowerWitchesBroom = 'sunflower_witches_broom';
  static const String signalSunflowerFlowerGreening =
      'sunflower_flower_greening';
  static const String signalSunflowerLeafCurl = 'sunflower_leaf_curl';
  static const String signalSunflowerInternodesShort =
      'sunflower_internodes_short';
  static const String signalSunflowerAphidsOrLeafhoppers =
      'sunflower_aphids_or_leafhoppers';
  static const String signalSunflowerChemicalDropletPattern =
      'sunflower_chemical_droplet_pattern';
  static const String signalSunflowerGeneticUniformTrait =
      'sunflower_genetic_uniform_trait';
  static const String signalSunflowerVisibleAphidClusters =
      'sunflower_visible_aphid_clusters';
  static const String signalSunflowerAntActivity = 'sunflower_ant_activity';
  static const String signalSunflowerTenderNewGrowth =
      'sunflower_tender_new_growth';
  static const String signalSunflowerHighNitrogenContext =
      'sunflower_high_nitrogen_context';
  static const String signalSunflowerNoInsectsFound =
      'sunflower_no_insects_found';
  static const String signalSunflowerFineWebbingOnly =
      'sunflower_fine_webbing_only';
  static const String signalSunflowerDryDust = 'sunflower_dry_dust';
  static const String signalSunflowerFineStippling = 'sunflower_fine_stippling';
  static const String signalSunflowerMitesWithLens =
      'sunflower_mites_with_lens';
  static const String signalSunflowerLowerLeafUnderside =
      'sunflower_lower_leaf_underside';
  static const String signalSunflowerStickyHoneydew =
      'sunflower_sticky_honeydew';
  static const String signalSunflowerLargeChewedHoles =
      'sunflower_large_chewed_holes';
  static const String signalSunflowerDarkFecalSpecks =
      'sunflower_dark_fecal_specks';
  static const String signalSunflowerBudScarring = 'sunflower_bud_scarring';
  static const String signalSunflowerPetalDistortion =
      'sunflower_petal_distortion';
  static const String signalSunflowerDamageInsideBud =
      'sunflower_damage_inside_bud';
  static const String signalSunflowerMechanicalTear =
      'sunflower_mechanical_tear';
  static const String signalSunflowerLarvaOrBeetleVisible =
      'sunflower_larva_or_beetle_visible';
  static const String signalSunflowerNightDamage = 'sunflower_night_damage';
  static const String signalSunflowerRaggedMargin = 'sunflower_ragged_margin';
  static const String signalSunflowerNecroticSpotIntact =
      'sunflower_necrotic_spot_intact';
  static const String signalSunflowerHailTearPattern =
      'sunflower_hail_tear_pattern';
  static const String signalSunflowerCShapedLarva = 'sunflower_c_shaped_larva';
  static const String signalSunflowerSoilDisturbed = 'sunflower_soil_disturbed';
  static const String signalSunflowerPeckMarks = 'sunflower_peck_marks';
  static const String signalSunflowerMissingSeeds = 'sunflower_missing_seeds';
  static const String signalSunflowerBitePattern = 'sunflower_bite_pattern';
  static const String signalSunflowerTracksOrDroppings =
      'sunflower_tracks_or_droppings';
  static const String signalSunflowerHeadExposed = 'sunflower_head_exposed';
  static const String signalSunflowerGrayMycelium = 'sunflower_gray_mycelium';
  static const String signalSunflowerInsectFrassInsideStem =
      'sunflower_insect_frass_inside_stem';
  static const String signalSunflowerNoBudPastWindow =
      'sunflower_no_bud_past_window';
  static const String signalSunflowerLongThinGrowth =
      'sunflower_long_thin_growth';
  static const String signalSunflowerLowLight = 'sunflower_low_light';
  static const String signalSunflowerExcessVegetativeGrowth =
      'sunflower_excess_vegetative_growth';
  static const String signalSunflowerRootRestricted =
      'sunflower_root_restricted';
  static const String signalSunflowerStageDateUncertain =
      'sunflower_stage_date_uncertain';
  static const String signalSunflowerBudHiddenPresent =
      'sunflower_bud_hidden_present';
  static const String signalSunflowerProfileLate = 'sunflower_profile_late';
  static const String signalSunflowerRecentSowingEstimate =
      'sunflower_recent_sowing_estimate';
  static const String signalSunflowerBudBrownDry = 'sunflower_bud_brown_dry';
  static const String signalSunflowerBudSoftGray = 'sunflower_bud_soft_gray';
  static const String signalSunflowerBudOpeningNormally =
      'sunflower_bud_opening_normally';
  static const String signalSunflowerCutPerformed = 'sunflower_cut_performed';
  static const String signalSunflowerHeadAsymmetric =
      'sunflower_head_asymmetric';
  static const String signalSunflowerFasciatedStem = 'sunflower_fasciated_stem';
  static const String signalSunflowerCultivarNormalDoubleFlower =
      'sunflower_cultivar_normal_double_flower';
  static const String signalSunflowerUniformTraitAcrossBatch =
      'sunflower_uniform_trait_across_batch';
  static const String signalSunflowerNormalOpeningSequence =
      'sunflower_normal_opening_sequence';
  static const String signalSunflowerPetalsWetStuck =
      'sunflower_petals_wet_stuck';
  static const String signalSunflowerLesionProgressing =
      'sunflower_lesion_progressing';
  static const String signalSunflowerOldFlower = 'sunflower_old_flower';
  static const String signalSunflowerPetalsDryUniform =
      'sunflower_petals_dry_uniform';
  static const String signalSunflowerNormalPetalDrop =
      'sunflower_normal_petal_drop';
  static const String signalSunflowerNoGrayGrowth = 'sunflower_no_gray_growth';
  static const String signalSunflowerHeadSoftWatery =
      'sunflower_head_soft_watery';
  static const String signalSunflowerRottenOdor = 'sunflower_rotten_odor';
  static const String signalSunflowerSlime = 'sunflower_slime';
  static const String signalSunflowerHeadWound = 'sunflower_head_wound';
  static const String signalSunflowerHailBirdInjury =
      'sunflower_hail_bird_injury';
  static const String signalSunflowerWarmHumidWeather =
      'sunflower_warm_humid_weather';
  static const String signalSunflowerHeadDryFirm = 'sunflower_head_dry_firm';
  static const String signalSunflowerNoOdor = 'sunflower_no_odor';
  static const String signalSunflowerHeadShredded = 'sunflower_head_shredded';
  static const String signalSunflowerWhiteMycelium = 'sunflower_white_mycelium';
  static const String signalSunflowerBlackSclerotia =
      'sunflower_black_sclerotia';
  static const String signalSunflowerGrayThreadsBlackPins =
      'sunflower_gray_threads_black_pins';
  static const String signalSunflowerPriorSoftRot = 'sunflower_prior_soft_rot';
  static const String signalSunflowerUniformNormalDrying =
      'sunflower_uniform_normal_drying';
  static const String signalSunflowerSeedsFirm = 'sunflower_seeds_firm';
  static const String signalSunflowerNoMoldStructures =
      'sunflower_no_mold_structures';
  static const String signalSunflowerBirdPerching = 'sunflower_bird_perching';
  static const String signalSunflowerLargeHeadProfile =
      'sunflower_large_head_profile';
  static const String signalSunflowerGradualAngle = 'sunflower_gradual_angle';
  static const String signalSunflowerWholePlantWilt =
      'sunflower_whole_plant_wilt';
  static const String signalSunflowerNeckSoftDark = 'sunflower_neck_soft_dark';
  static const String signalSunflowerRapidCollapse = 'sunflower_rapid_collapse';
  static const String signalSunflowerDrainagePoor = 'sunflower_drainage_poor';
  static const String signalSunflowerSoilWetForDays =
      'sunflower_soil_wet_for_days';
  static const String signalSunflowerLowerLeafYellow =
      'sunflower_lower_leaf_yellow';
  static const String signalSunflowerNormalSenescence =
      'sunflower_normal_senescence';
  static const String signalSunflowerWholePlantFlaccid =
      'sunflower_whole_plant_flaccid';
  static const String signalSunflowerRootRotSigns = 'sunflower_root_rot_signs';
  static const String signalSunflowerSunnySide = 'sunflower_sunny_side';
  static const String signalSunflowerChangedExposure =
      'sunflower_changed_exposure';
  static const String signalSunflowerDropletPattern =
      'sunflower_droplet_pattern';
  static const String signalSunflowerProgressingInShade =
      'sunflower_progressing_in_shade';
  static const String signalSunflowerWaterSoakedAfterCold =
      'sunflower_water_soaked_after_cold';
  static const String signalSunflowerUniformExposedDamage =
      'sunflower_uniform_exposed_damage';
  static const String signalSunflowerForecastFrost = 'sunflower_forecast_frost';
  static const String signalSunflowerBlackenedTissue =
      'sunflower_blackened_tissue';
  static const String signalSunflowerLocalizedRotOdor =
      'sunflower_localized_rot_odor';
  static const String signalSunflowerWhiteCrust = 'sunflower_white_crust';
  static const String signalSunflowerRootTipBurn = 'sunflower_root_tip_burn';
  static const String signalSunflowerContainerContext =
      'sunflower_container_context';
  static const String signalSunflowerNoRecentInput =
      'sunflower_no_recent_input';
  static const String signalSunflowerHighResistance =
      'sunflower_high_resistance';
  static const String signalSunflowerRootCircling = 'sunflower_root_circling';
  static const String signalSunflowerHardPan = 'sunflower_hard_pan';
  static const String signalSunflowerSmallRootVolume =
      'sunflower_small_root_volume';
  static const String signalSunflowerRepeatedDrying =
      'sunflower_repeated_drying';
  static const String signalSunflowerRootsExpandingFreely =
      'sunflower_roots_expanding_freely';
  static const String signalSunflowerResistanceNormalMoistSoil =
      'sunflower_resistance_normal_moist_soil';
  static const String signalSunflowerGeneticCompactProfile =
      'sunflower_genetic_compact_profile';
  static const String signalSunflowerOlderLeavesYellow =
      'sunflower_older_leaves_yellow';
  static const String signalSunflowerPurpleTint = 'sunflower_purple_tint';
  static const String signalSunflowerYoungInterveinalChlorosis =
      'sunflower_young_interveinal_chlorosis';
  static const String signalSunflowerStunted = 'sunflower_stunted';
  static const String signalSunflowerWeakStem = 'sunflower_weak_stem';
  static const String signalSunflowerNpkOrientativeOutOfBand =
      'sunflower_npk_orientative_out_of_band';
  static const String signalSunflowerStageSenescence =
      'sunflower_stage_senescence';
  static const String signalSunflowerNoActiveLesion =
      'sunflower_no_active_lesion';
  static const String signalSunflowerStemStillFirm =
      'sunflower_stem_still_firm';
  static const String signalSunflowerNewPustulesOrMold =
      'sunflower_new_pustules_or_mold';
  static const String signalSunflowerWarmWetSoil = 'sunflower_warm_wet_soil';
  static const String signalSunflowerLateAfterBloom =
      'sunflower_late_after_bloom';
  static const String signalSunflowerPatchOrRow = 'sunflower_patch_or_row';
  static const String signalSunflowerGradualProgression =
      'sunflower_gradual_progression';
  static const String signalSunflowerUniformNutrientPattern =
      'sunflower_uniform_nutrient_pattern';
  static const String signalSunflowerStemBentByWeight =
      'sunflower_stem_bent_by_weight';
  static const String signalSunflowerSoftRot = 'sunflower_soft_rot';
  static const String signalSunflowerNormalPetalAging =
      'sunflower_normal_petal_aging';
  static const String signalSunflowerPhysicalDamage =
      'sunflower_physical_damage';
  static const String signalSunflowerStemFirm = 'sunflower_stem_firm';
  static const String signalSunflowerPustules = 'sunflower_pustules';
  static const String signalSunflowerInsectPattern = 'sunflower_insect_pattern';
  static const String signalSunflowerActivePustules =
      'sunflower_active_pustules';

  static const Map<String, String> organLabelsEs = <String, String>{
    organWhorl: 'Cogollo',
    organLeaf: 'Hoja',
    organStem: 'Tallo',
    organRoot: 'Raiz',
    organCrown: 'Cuello / corona',
    organSpike: 'Espiga',
    organEar: 'Mazorca',
    organPod: 'Vaina',
    organFruit: 'Fruto',
    organFlower: 'Flor / brote floral',
    organWholePlant: 'Planta completa',
    organGrain: 'Grano',
    organBulb: 'Bulbo',
    organNeck: 'Cuello del bulbo',
    organBasalPlate: 'Plato basal / base',
    organSeedClove: 'Diente-semilla',
    organSeed: 'Semilla',
    organBud: 'Botón floral',
    organFlowerHead: 'Capítulo / cabeza floral',
  };

  static const Map<String, String> symptomLabelsEs = <String, String>{
    symptomRoseRosetteExcessPrickles:
        'Crecimiento deforme con exceso de aguijones',
    symptomRoseChlorosisWeakGrowth:
        'Hojas pálidas o amarillas y crecimiento débil',
    symptomRoseScaleCottonSooty:
        'Bultos fijos, algodón, melaza o tizne en el tallo',
    symptomOrangeReddishPustules: 'Pustulas naranja o rojizas',
    symptomNecroticFoliarSpots: 'Manchas foliares cafe o necroticas',
    symptomAphidColonies: 'Colonias de pulgon',
    symptomLateDefoliation: 'Defoliacion rapida / dano foliar tardio',
    symptomWhorlFeeding: 'Cogollo perforado o comido',
    symptomStuntingReddening: 'Enanismo o rojizos',
    symptomRaisedBlackSpots: 'Puntos negros elevados',
    symptomOrangePustules: 'Pustulas anaranjadas',
    symptomEarRot: 'Pudricion o moho en mazorca',
    symptomWhiteflyPresence: 'Mosca blanca visible',
    symptomNetLikeSpots: 'Manchas reticuladas en hoja',
    symptomMosaicYellowing: 'Mosaico o amarillamiento',
    symptomWiltPodLesions: 'Marchitez o lesiones en vaina',
    symptomDarkSunkenLesions: 'Lesiones oscuras hundidas',
    symptomAngularSpots: 'Manchas angulares en hoja',
    symptomStripedLeaves: 'Hojas con rayas o bandas',
    symptomGrayFoliarScald: 'Escaldadura gris / blanquecina',
    symptomPowderyGrowth: 'Polvillo blanco o cenicilla',
    symptomWiltVascular: 'Marchitez vascular o unilateral',
    symptomFruitApicalRot: 'Mancha apical hundida en fruto',
    symptomBacterialSpeckSpot: 'Punteado o mancha bacteriana',
    symptomBronzingStippling: 'Bronceado, raspado o punteado fino',
    symptomRootGalls: 'Agallas en raiz y planta frenada',
    symptomSeedlingCollapse: 'Plantula colapsada o cuello vencido',
    symptomRootRotWilt: 'Marchitez con cuello o raiz comprometida',
    symptomGrayMoldNecrosis: 'Necrosis humeda con moho gris',
    symptomLeafMines: 'Galerias o minas dentro de la hoja',
    symptomFeedingHoles: 'Perforaciones o dano de mordida',
    symptomBoltingStem: 'Tallo central alargado / espigado',
    symptomTanPaperySpots: 'Manchas cafe claras, secas o papirosas',
    symptomWaterSoakedSpots: 'Manchas acuosas en hoja',
    symptomWhitePustules: 'Pustulas blancas en hoja',
    symptomLeafDistortion: 'Hoja deformada o crecimiento torcido',
    symptomPoorEmergence: 'Nacencia pobre o plantula debil',
    symptomLeafEdgeBurn: 'Bordes quemados o perdida de turgencia',
    symptomFlowerAbortion: 'Caida de flor o mal cuaje',
    symptomFruitDeformation: 'Fruto deforme o mal llenado',
    symptomColdInjury: 'Dano por frio o arranque frenado',
    symptomCactusRootCollarDeterioration:
        'Base o raiz con cambio de color, firmeza o soporte',
    symptomCactusSoftWaterSoakedTissue: 'Tejido blando, acuoso o hundido',
    symptomCactusDryFirmCorking: 'Zona seca, firme y corchosa',
    symptomCactusWrinklingTurgorLoss:
        'Arrugas, contraccion o perdida de volumen',
    symptomCactusWhiteCottonyMaterial:
        'Material blanco algodonoso, ceroso o escamas adheridas',
    symptomCactusSunburnPatch: 'Mancha seca o decolorada del lado soleado',
    symptomCactusColdTissueChange:
        'Cambio de color, firmeza o soporte después de frio',
    symptomCactusLeaningCollapse:
        'Inclinacion nueva, hundimiento o perdida de soporte',
    // Suculenta: lenguaje natural, sin nombres de patógeno ni jerga.
    symptomSucculentRootCollarDeterioration:
        'Base o raiz con cambio de color, firmeza o soporte',
    symptomSucculentSoftWaterSoakedTissue:
        'Hoja o tallo blando, acuoso o traslucido',
    symptomSucculentWrinklingTurgorLoss: 'Hojas arrugadas o menos firmes',
    symptomSucculentEdemaCorkyBlisters:
        'Ampollas o costras corchosas, sobre todo en hojas bajas',
    symptomSucculentEtiolatedGrowth: 'Crecimiento nuevo estirado o palido',
    symptomSucculentSunburnPatch: 'Mancha seca o blanqueada del lado soleado',
    symptomSucculentColdTissueChange:
        'Cambio de tejido despues de frio o helada',
    symptomSucculentPowderySurfaceGrowth: 'Capa o parches blancos en la planta',
    symptomSucculentLeafSpotGrayMold:
        'Manchas humedas, tejido cafe o moho gris',
    symptomSucculentCottonWaxScale:
        'Material blanco algodonoso o escamas adheridas',
    symptomSucculentStipplingWebbing:
        'Punteado, bronceado, telarana fina o deformacion',
    symptomSucculentSaltLeafBurn:
        'Puntas o bordes quemados con costra blanca en el sustrato',
    symptomSucculentChemicalSprayBurn:
        'Mancha o quemadura despues de aplicar un producto',
    symptomSucculentFungusGnatIndicator: 'Mosquitas alrededor del sustrato',
    // Sábila / Aloe: lenguaje natural, sin nombres de patógeno ni jerga.
    symptomAloeRootCollarCondition:
        'Base o raiz con cambio de color, firmeza o soporte',
    symptomAloeSoftWaterSoakedTissue:
        'Hoja o tallo blando, acuoso o traslucido',
    symptomAloeWartyGallDistortion:
        'Crecimiento deforme con verrugas o masas rugosas',
    symptomAloeColdTissueChange: 'Cambio de tejido despues de frio o helada',
    symptomAloeSunburnPatch: 'Mancha seca o blanqueada del lado soleado',
    symptomAloeDryHardLeafSpot: 'Manchas secas y duras en la hoja',
    symptomAloeWetAdvancingLesion: 'Manchas empapadas que avanzan',
    symptomAloeMealybugScaleSooty:
        'Material blanco algodonoso, escamas o superficie pegajosa',
    symptomAloeSpiderMiteStippling: 'Punteado fino, bronceado o telarana',
    symptomAloeSaltLeafBurn:
        'Puntas o bordes quemados con costra blanca en el sustrato',
    symptomAloeSprayInjury: 'Mancha o quemadura despues de aplicar un producto',
    symptomAloeEtiolatedGrowth: 'Crecimiento nuevo estirado o palido',
    symptomAloeWrinklingTurgorLoss: 'Hojas arrugadas o menos firmes',
    // Maguey / Agave: lenguaje natural, sin nombres de patogeno ni jerga.
    symptomAgaveRootCrownCondition:
        'Base, raiz o cogollo con deterioro por confirmar',
    symptomAgaveSoftWaterSoakedTissue: 'Tejido blando, humedo o acuoso',
    symptomAgaveWiltDryBud: 'Marchitez o cogollo seco y corrugado',
    symptomAgaveSnoutWeevil: 'Picudo, larvas o galerias internas',
    symptomAgaveMiteGreasyStreak: 'Raya grasosa interna y centro deformado',
    symptomAgaveSoftScaleWaxy:
        'Escama blanda o material ceroso con insectos',
    symptomAgavePlantBugScar: 'Cicatrices superficiales por chinche',
    symptomAgaveAnthracnoseLesion: 'Lesiones hundidas con anillos',
    symptomAgaveGraySpotLesion: 'Mancha gris con halo amarillo',
    symptomAgaveColdFrostInjury:
        'Ennegrecimiento o tejido flacido tras helada',
    symptomAgaveSunburnHeat: 'Parche seco o blanqueado del lado soleado',
    symptomAgaveMechanicalWound: 'Herida, golpe, granizo o retiro de hijuelo',
    symptomAgaveSaltFertilizerInjury:
        'Puntas y bordes secos con costra blanca',
    symptomAgaveAnimalDamage: 'Tejido faltante o mordido',
    symptomAgaveFlowerStalk: 'Tallo floral o quiote desde el centro',
    symptomAgavePostFloweringSenescence: 'Secado gradual tras la floracion',
    symptomAgaveBenignNaturalChange: 'Cambio natural o cicatriz estable',
    symptomThripsSilverScarring: 'Plateado o bronceado por trips',
    symptomDownyFuzzyGrowth: 'Moho velloso gris/blanco/morado en hoja',
    symptomPurpleConcentricLesions:
        'Lesiones purpuras con anillos concentricos',
    symptomDarkOliveLeafBlight: 'Manchas oscuras oliva-negro en hoja',
    symptomWhiteSunkenLeafSpots: 'Manchas blancas hundidas con halo',
    symptomPinkRoots: 'Raices rosadas, rojas o purpuras',
    symptomBasalPlateBrownRot: 'Plato basal cafe o pudricion seca de base',
    symptomWhiteMyceliumSclerotia: 'Micelio blanco con esclerocios negros',
    symptomNeckSoftRot: 'Cuello blando o pudricion de cuello',
    symptomBulbScaleWaterSoaked: 'Escamas internas acuosas o blandas',
    symptomCenterLeafBleaching: 'Hoja central blanqueada o colapsada',
    symptomStrawDiamondLesions: 'Lesiones pajizas tipo diamante',
    symptomBlackMoldSpores: 'Polvo o esporas negras bajo escamas',
    symptomBlueGreenMold: 'Moho azul-verde en escamas',
    symptomNoBulbPhotoperiod: 'Mucha hoja y poco bulbo',
    symptomSeedstalkBolting: 'Tallo floral / espigado',
    symptomThickNeck: 'Cuello grueso o madurez retrasada',
    symptomBulbSplitting: 'Bulbo partido, doble o rajado',
    symptomDeformedBulb: 'Bulbo deforme con raiz limitada',
    symptomMaggotStandLoss: 'Larvas en base y fallas de stand',
    symptomPoorCuringNeckMoist: 'Cuello humedo tras cosecha / mal curado',
    symptomPoorCloveDifferentiation: 'Pocos dientes o mala diferenciacion',
    symptomExposedClovesBrooming: 'Dientes expuestos / escobeteado',
    symptomStorageSprouting: 'Brotacion en almacenamiento',
    symptomSunscaldOuterScales: 'Escamas asoleadas o quemadas',
    symptomBulbMiteScars: 'Cicatrices o dano de acaro en bulbo',
    symptomBlightedBlossomsShoots:
        'Racimos florales o brotes quemados / ennegrecidos',
    symptomVelvetyOliveSpots:
        'Manchas oliva-negras aterciopeladas en hoja/fruto',
    symptomFruitTunnelFrass: 'Perforacion en fruto con galeria o aserrin',
    symptomWoollyWhiteColonies: 'Masas blancas algodonosas en ramas o tronco',
    symptomFruitSunkenPits: 'Puntos oscuros hundidos en el fruto',
    symptomFruitSunburnPatch: 'Mancha clara o quemada en el lado soleado',
    symptomInternervalChlorosisNewLeaves:
        'Hojas nuevas amarillas con nervaduras verdes',
    symptomShootDecayCanker: 'Muerte regresiva de rama o cancro en madera',
    symptomMummifiedFruitRot: 'Pudricion firme o fruto momificado',
    symptomHoneydewSootyShoots:
        'Melaza pegajosa y negrilla en brotes/hojas (chupadores)',
    symptomLeafCurlReddened:
        'Hojas engrosadas, rizadas y rojizas (torque/lepra del duraznero)',
    symptomShotHoleLeafSpots:
        'Manchas que caen y dejan agujeritos en la hoja (tiro de munición)',
    symptomTrunkBaseGumFrass: 'Goma con aserrín en la base del tronco',
    symptomNutShuckTunnels:
        'Nuez/ruezno con galerías, túneles negros o ruezno pegado',
    symptomKernelDarkSpots:
        'Almendra con puntos negros, manchada o de mal sabor',
    symptomRosetteLittleLeaf:
        'Hoja chica, entrenudos cortos o brotes en roseta (posible zinc)',
    symptomShuckDiebackBlackening:
        'Ruezno que se ennegrece o muere desde la punta',
    symptomPrematureNutDrop: 'Caída de nuez recién amarrada o nuez chica',
    symptomNutwormMummies:
        'Pistache con gusano, frass en racimo o momias en árbol',
    symptomEarlySplitStaining:
        'Cáscara abierta temprano (early split) con manchado',
    symptomPanicleShootBlight:
        'Racimo/brote ennegrecido con lesiones (tizón de panícula)',
    symptomBlankClosedNut: 'Pistache vano (blank) o cerrado / no abre',
    symptomCitrusBlotchyMottle:
        'Hoja con moteado amarillo asimétrico/disparejo (posible HLB)',
    symptomCitrusSmallLopsidedFruit: 'Naranja chica, ladeada, deforme o amarga',
    symptomCitrusGummosisTrunk: 'Goma en la base del tronco o cuello (gomosis)',
    symptomCitrusSplitFruit: 'Naranja rajada o partida',
    symptomCitrusRindScarring:
        'Cicatrices o raspaduras corchosas en la cáscara',
    symptomCitrusRaisedCorkyHaloLesions:
        'Lesiones elevadas/corchosas con halo (hoja/fruto/tallo)',
    // Tulipán: lenguaje natural, sin nombres de patógeno ni jerga.
    symptomTulipFoliageYellowing: 'Hojas amarillas o follaje que desaparece',
    symptomTulipBulbSoftWatery: 'Bulbo blando, acuoso o con olor anormal',
    symptomTulipBasalDryRot: 'Base seca, café o hundida con deterioro del bulbo',
    symptomTulipBlueGreenMold: 'Moho azul verdoso en el bulbo almacenado',
    symptomTulipSubterraneanShootRot: 'El brote se deteriora debajo del suelo',
    symptomTulipEthyleneDamage:
        'Daño de almacenamiento compatible con etileno',
    symptomTulipStemTopple: 'Tallo u hoja con zona acuosa que se dobla',
    symptomTulipWeakElongatedStem: 'Tallo largo, delgado o inclinado',
    symptomTulipShortBloom: 'La flor abre y termina demasiado rápido',
    symptomTulipSaltRootBurn:
        'Raíces cortas, torcidas o cafés con sales elevadas',
    symptomTulipEdema: 'Tejido oscuro y acuoso o gotas sin pudrición evidente',
    symptomTulipFoliageRemovedEarly:
        'Follaje retirado antes de terminar la recarga',
    symptomTulipPhysicalDamage:
        'Pétalos o tallos dañados por lluvia, viento o golpe',
    symptomTulipBulbRingsDistortion:
        'Bulbo con anillos cafés o crecimiento deformado',
    // Girasol / Sunflower: lenguaje natural, sin nombres de patogeno ni jerga.
    symptomSunflowerTurgorLoss: 'Marchitez o pérdida de firmeza',
    symptomSunflowerLodging:
        'Planta inclinada, vencida o con el tallo quebrándose',
    symptomSunflowerWildlifeDamage: 'Daño por aves, roedores u otra fauna',
    symptomSunflowerBudDelayed: 'Botón floral retrasado o ausente',
    symptomSunflowerHeadDeformation:
        'Capítulo o flor deforme, incompleto o asimétrico',
    symptomSunflowerHeadSoftRot: 'Capítulo blando, acuoso, oscuro o con olor',
    symptomSunflowerHeadDryRot:
        'Capítulo que se seca de forma irregular, se deshilacha o enmohece',
    symptomSunflowerHeadDroop: 'La cabeza se inclina después de abrirse',
    symptomSunflowerNutrientPattern:
        'Color o crecimiento compatible con nutrición desbalanceada',
    symptomSunflowerNormalSenescence:
        'Flor envejecida y amarillamiento gradual al final del ciclo',
  };

  static const Map<String, String> signalLabelsEs = <String, String>{
    signalRoseAntActivity: 'Hay hormigas subiendo por la planta',
    signalRoseBeetlesOnFlower: 'Hay escarabajos comiendo la flor',
    signalRoseBeneficialPredators:
        'Hay catarinas, crisopas o larvas benéficas presentes',
    signalRoseBentBlackenedShootTip:
        'La punta del tallo está doblada o ennegrecida',
    signalRoseBleachedBlackenedCane:
        'La caña está blanqueada o ennegrecida en el lado expuesto',
    signalRoseBorerHoleFrass:
        'Hay un orificio, aserrín o un canal interno en la caña',
    signalRoseBranchDieback: 'Algunas ramas mueren de forma regresiva',
    signalRoseBrownSpottedPetals:
        'Los pétalos tienen manchas rojas o marrones',
    signalRoseBudDistortion: 'Los botones salen deformes',
    signalRoseBudFailsToOpen: 'El botón no abre o abre deforme',
    signalRoseBudsSepalsWhite:
        'El blanco también está en botones, sépalos o tallos jóvenes',
    signalRoseCaneDiesFromTip: 'La caña se seca desde la punta hacia abajo',
    signalRoseCaneUniformlyGreenInside:
        'La caña está verde y uniforme por dentro',
    signalRoseCastSkins: 'Hay mudas o pieles blancas de insecto',
    signalRoseCleanSemicircleCut:
        'Los cortes son semicírculos o círculos limpios en el borde',
    signalRoseCottonyWax: 'El material blanco parece algodón o cera de insecto',
    signalRoseCrackedFlakingBark:
        'La corteza está agrietada o descascarándose',
    signalRoseCrowdedNewGrowth:
        'El crecimiento nuevo está apretado o sin ventilación',
    signalRoseCrownBrownOrSoft: 'La corona o base está marrón o blanda',
    signalRoseCrownFirmNormal: 'La corona se siente firme y normal',
    signalRoseDamageHotWeather: 'El daño se extiende con el calor',
    signalRoseDamageOnlyAfterAging:
        'El daño aparece solo después del envejecimiento esperado',
    signalRoseDamageProgressesHumidCool:
        'El daño avanza en periodos húmedos y frescos',
    signalRoseDeadBranchAmongHealthy:
        'Hay una rama muerta dentro de una planta sana',
    signalRoseDeclineProgressing: 'El deterioro avanza entre revisiones',
    signalRoseDeformedLeavesFlowers:
        'Las hojas y flores salen pequeñas y deformes',
    signalRoseDropletPattern: 'El daño tiene un patrón de gotas o salpicadura',
    signalRoseDustyCrowdedSite: 'La planta está en un sitio polvoso o apretado',
    signalRoseExcessPrickles:
        'Hay muchísimos más aguijones que en las ramas normales',
    signalRoseFeatheryBlackMargin:
        'Mancha oscura con borde irregular o de flecos',
    signalRoseFewFeederRoots: 'Hay pocas raíces finas o alimentadoras',
    signalRoseFineStippling: 'Hay un punteado muy fino en la hoja',
    signalRoseFineWebbing: 'Hay telaraña muy fina',
    signalRoseFixedScaleBodies: 'Hay cuerpos o escamas fijos que no caminan',
    signalRoseFlowerOpenedNormally: 'La flor abrió con normalidad',
    signalRoseFungusGnats: 'Hay mosquitas saliendo del sustrato',
    signalRoseGallAtSoilLine: 'El bulto está en la línea del suelo',
    signalRoseGallHardensDarkens: 'El bulto crece, endurece y oscurece',
    signalRoseGallInsectExitHole:
        'El bulto tiene un orificio de salida o una larva',
    signalRoseGrayCenterBlackDots:
        'La lesión tiene centro gris con puntitos negros',
    signalRoseGrayFuzzyFlower: 'Hay pelusa gris sobre el botón o la flor',
    signalRoseGrowthNormalizes: 'El crecimiento se normaliza con el tiempo',
    signalRoseHealthyBasalBreak: 'Es una sola caña basal fuerte y sana',
    signalRoseHerbicideAffectsOtherPlants:
        'Hubo herbicida cerca u otras especies también se deformaron',
    signalRoseHighPhContext: 'El suelo es de pH alto o calcáreo',
    signalRoseInsectEggsDistinct:
        'Parecen huevos u objetos separados y definidos',
    signalRoseInsectsNodes: 'Los insectos se concentran en nodos y tallos',
    signalRoseInsectsTenderShoots:
        'Los insectos están sobre los brotes tiernos',
    signalRoseInterveinalChlorosisNewLeaves:
        'Las hojas nuevas amarillean entre las venas, con venas verdes',
    signalRoseInterveinalChlorosisNoPattern:
        'El amarillo está solo entre las venas, sin anillos ni zigzags',
    signalRoseKnownGraftedStock: 'Es material injertado o de origen conocido',
    signalRoseLargeSilverScarsThrips:
        'Hay raspaduras plateadas más grandes o insectos que saltan',
    signalRoseLarvaeUnderLeaf: 'Hay larvas debajo de la hoja',
    signalRoseLeafCenterFallsFromSpot:
        'El centro de una mancha se desprendió y dejó el agujero',
    signalRoseLeafGrayOffGreen: 'La hoja se ve gris o con verde apagado',
    signalRoseLeafLeatheryWrinkled: 'La hoja se ve coriácea o arrugada',
    signalRoseLeafTwistingWithOrange:
        'Las hojas se tuercen junto con el color naranja',
    signalRoseLeafYellowing: 'Hay amarillamiento de hojas asociado',
    signalRoseLossOfSupport: 'La planta perdió anclaje o soporte',
    signalRoseLowNReadingRepeated:
        'La lectura de nitrógeno sale baja de forma repetida',
    signalRoseLowerLeavesFirst: 'El daño empezó en las hojas de abajo',
    signalRoseMitesUnderLeaf:
        'Se ven puntos móviles diminutos debajo de la hoja',
    signalRoseMultipleGalls: 'Hay varios bultos o agallas',
    signalRoseNarrowLeavesCupping:
        'Las hojas salen angostas o en forma de cuchara (cupping)',
    signalRoseNearOtherSymptomaticRoses:
        'Hay otros rosales con síntomas parecidos cerca',
    signalRoseNoGrowthDistortion: 'El crecimiento nuevo no está deformado',
    signalRoseNoHoneydew: 'No hay melaza pegajosa',
    signalRoseNoInsectsNoMoldStable:
        'No hay insectos ni pelusa y el cuadro está estable',
    signalRoseNormalCaneLenticels:
        'Son lenticelas normales de la caña, no insectos',
    signalRoseNormalFullSizedLeaves: 'Las hojas alcanzan su tamaño normal',
    signalRoseNormalOldWood: 'Parece madera vieja normal, sin lesión',
    signalRoseNormalPrickleDensity: 'La cantidad de aguijones es la habitual',
    signalRoseNormalRedGrowthTurnsGreen:
        'El brote empieza rojo pero madura a verde',
    signalRoseNormalRootFlare:
        'Es el ensanchamiento normal de la base de la raíz',
    signalRoseNormalSeasonalAging:
        'Es un envejecimiento normal de temporada de hojas viejas',
    signalRoseOldSpentFlower:
        'La flor ya había abierto y está agotada por edad',
    signalRoseOnlyOneCaneAffected: 'Solo una caña está afectada',
    signalRoseOrangeObjectsDoNotSmear:
        'Los puntos naranjas no sueltan polvo al tocarlos',
    signalRoseOrangePowderUnderLeaf:
        'Hay polvo o pústulas naranjas debajo de la hoja',
    signalRosePatternRepeatsNewLeaves:
        'El patrón se repite en las hojas nuevas',
    signalRosePersistentRedYellowDistortion:
        'El color rojo o amarillo anormal no madura a verde',
    signalRosePetalScratchesFlecks:
        'Los pétalos tienen raspaduras, rayas o puntos plateados',
    signalRosePetalsEaten: 'Los pétalos están comidos',
    signalRosePlantRecoversAfterIrrigation:
        'La planta se recupera al restablecer el riego o el oxígeno',
    signalRosePowderRubsOrSmears:
        'El polvo blanco se corre o se limpia al frotar',
    signalRosePrematureLeafDrop: 'Las hojas se caen con facilidad',
    signalRoseProgressesToOtherBranches: 'El patrón avanza a otras ramas',
    signalRosePurchasedWithSwelling:
        'La planta ya venía con la hinchazón al comprarla',
    signalRosePurpleBlackCaneLesion:
        'La caña tiene una lesión morada, negra o marrón',
    signalRosePurpleRedBrownSpots:
        'Las manchas son moradas, rojizas o marrones',
    signalRoseRaisedOrangeBumps:
        'Hay pequeños bultos o pústulas naranjas elevadas',
    signalRoseRecentFertilizer: 'Se fertilizó o abonó hace poco',
    signalRoseRecentPruning: 'Hubo una poda reciente',
    signalRoseRecentSpray: 'Se aplicó un producto sobre el follaje hace poco',
    signalRoseRecentTransplant: 'Hubo un trasplante o plantación reciente',
    signalRoseRecentWetWeather: 'Hubo lluvia, rocío o humedad alta reciente',
    signalRoseRedTintAroundPowder:
        'Hay tejido rojizo alrededor del polvo blanco',
    signalRoseReflectedHeat: 'Hay una pared o piedra que refleja calor cerca',
    signalRoseRootDeclineSigns: 'Hay señales de raíz limitada o dañada',
    signalRoseRootsFirmWhiteTips:
        'Las raíces están firmes y con puntas blancas',
    signalRoseRoughIrregularGall: 'El bulto es rugoso e irregular',
    signalRoseSandyCalcareousSoil: 'El suelo es arenoso o calcáreo',
    signalRoseShortWeakShoots: 'Los brotes salen cortos y débiles',
    signalRoseSkeletonizedLeaf: 'La hoja quedó como encaje o esqueletizada',
    signalRoseSmoothRegularGraftUnion:
        'El bulto es liso y regular, en la zona típica del injerto',
    signalRoseSoftBodiedColonies:
        'Hay colonias de insectos blandos en los brotes',
    signalRoseSoftTemporaryCallus:
        'Es un callo blando y temporal sobre una herida',
    signalRoseSoilDry: 'El suelo estaba seco',
    signalRoseSoilDryDuringWilt:
        'El suelo estaba seco cuando la planta se marchitó',
    signalRoseSourAbnormalOdor: 'Hay un olor agrio o anormal',
    signalRoseSpotsDoNotProgress: 'Las manchas no avanzan entre revisiones',
    signalRoseSpotsOnCanes:
        'También hay manchas o ampollas oscuras en las cañas',
    signalRoseSpotsProgressWetWindow:
        'Las manchas aumentan tras lluvia o follaje mojado',
    signalRoseStableOldSwelling: 'La hinchazón es antigua y estable, no crece',
    signalRoseStemSwelling: 'Hay una hinchazón en el tallo',
    signalRoseStuntedAboveGall: 'La planta se frena por encima del bulto',
    signalRoseStunting: 'La planta se ve enanizada o frenada',
    signalRoseSunnyExposedSide: 'El daño está en el lado más expuesto al sol',
    signalRoseSunnySideDamage: 'El daño está del lado más soleado',
    signalRoseSymptomsCoolWeather: 'El patrón se nota más con clima fresco',
    signalRoseThickenedCane:
        'La caña nueva es más gruesa y suculenta que la caña vieja',
    signalRoseTinyInsectsInsideFlower:
        'Hay insectos diminutos dentro de la flor o el botón',
    signalRoseUniformEdgeScorch: 'El daño es un borde quemado uniforme',
    signalRoseUniformOldLeafYellowing:
        'Las hojas viejas amarillean de forma uniforme',
    signalRoseUniformSprayResidue:
        'La capa blanca es uniforme, como residuo de aspersión',
    signalRoseUniformYellowOldLeaves:
        'Las hojas viejas están uniformemente amarillas',
    signalRoseUpperLeafDiscoloration:
        'La parte de arriba de la hoja se decoloró',
    signalRoseVeinClearing: 'Las venas se ven aclaradas o translúcidas',
    signalRoseVeinLimitedAngular:
        'Las manchas son angulares y quedan limitadas por las venas',
    signalRoseWarmDayCoolNight: 'Días cálidos con noches frescas',
    signalRoseWeakShoots: 'Los brotes se ven débiles',
    signalRoseWiltsWhileSoilWet:
        'La planta se marchita con el suelo todavía mojado',
    signalRoseWindowpaneDamage:
        'Falta solo una capa de la hoja, como ventana transparente',
    signalRoseWitchesBroom:
        'Salen muchos brotes pequeños desde un mismo punto (escoba de bruja)',
    signalRoseWoundNearGall: 'Hay una herida conocida cerca del bulto',
    signalRoseYellowHaloOrLeaf:
        'Hay amarillamiento alrededor de la mancha o en la hoja',
    signalRoseYellowRingsZigzags: 'Hay anillos o zigzags amarillos',
    signalRoseYellowWavyLines: 'Hay líneas amarillas onduladas en la hoja',
    signalRoseYoungLeavesCurled: 'Las hojas nuevas salen torcidas o rizadas',
    signalPustulesOnStem: 'Tambien hay pustulas en tallo',
    signalNoClearPustules: 'No veo pustulas claras',
    signalHumidWindow: 'Hubo humedad alta / ambiente humedo',
    signalCoolDewyWindow: 'Clima fresco con rocio prolongado',
    signalAphidEarlyToxicity: 'Dano toxico temprano / clorosis fuerte',
    signalSpikeFeeding: 'La colonia ya esta en espiga',
    signalLeafRolling: 'Hojas enrolladas o torcidas',
    signalActiveChewing: 'Hay mordidas activas o larvas',
    signalNoBiteMarks: 'No hay mordidas claras',
    signalRapidFoliarCollapse: 'El follaje verde cayo muy rapido',
    signalFrassPresent: 'Hay excretas visibles',
    signalDeadHeart: 'Hay corazon muerto',
    signalVectorPresent: 'Hay vector presente',
    signalCannotScrapeOff: 'No se desprende al raspar',
    signalSporesRubOff: 'Si suelta polvo de esporas',
    signalMoldOnEar: 'Hay moho visible en mazorca',
    signalSilkDamage: 'Jilotes / sedas danados',
    signalDarkStriations: 'Estrias oscuras en hoja o tallo',
    signalStickyHoneydew: 'Mielecilla pegajosa en hojas',
    signalSootyMold: 'Fumagina (tizne negro) en follaje',
    signalWhiteflyCloud: 'Nube de mosca blanca al mover follaje',
    signalSeedStaining: 'Grano manchado o decolorado',
    signalNetPattern: 'Patron reticulado en lesiones',
    signalScaldBleaching: 'Blanqueamiento o escaldadura en hoja',
    signalPodCanker: 'Cancro o lesion en vaina',
    signalWaterSoakedMargin: 'Margen acuoso en las manchas',
    signalAngularLesionPattern: 'Lesiones con forma angular definida',
    signalPinkSporeMass: 'Masa de esporas rosada visible',
    signalWhitePowderGrowth: 'Hay polvillo blanco superficial',
    signalGrayFuzzyGrowth: 'Hay moho gris afelpado',
    signalHaloMargin: 'Las lesiones traen halo clorotico o acuoso',
    signalVascularBrowning: 'Hay pardeamiento vascular en corte',
    signalOneSidedWilt: 'La marchitez empezo en un solo lado',
    signalFruitApicalBlackPatch: 'Hay parche apical negro y hundido en fruto',
    signalThripsPresent: 'Se observan trips o raspado fino',
    signalBronzedLeafSurface: 'La hoja se ve bronceada o plateada',
    signalMitesWebbing: 'Hay acaros o telarana fina',
    signalRootGalls: 'Las raices traen agallas o nudos',
    signalStemCanker: 'Hay cancros en tallo, peciolo o fruto',
    signalUndersideSporulation: 'Hay envés activo con esporulacion',
    signalSeedlingNeckCollapse:
        'El cuello de la plantula esta vencido o podrido',
    signalWaterlogging: 'Hubo exceso de agua, encharque o drenaje flojo',
    signalRootsDarkRot: 'La raiz o el cuello se ven oscuros o podridos',
    signalHeatStress: 'Hubo calor fuerte o pico termico',
    signalDryHotWindow: 'El ambiente estuvo seco y caliente',
    signalFlowerDrop: 'Se estan cayendo flores o falla el cuaje',
    signalFruitHooking: 'El fruto sale curvo, de cuello o tipo gancho',
    signalDeformedNoRot: 'El fruto esta deformado pero sin pudricion clara',
    signalSalinityLoad: 'Hay carga salina o CE alta en juego',
    signalLeafMines: 'La hoja trae minas o galerias internas',
    signalFeedingHoles: 'Hay perforaciones o mordidas reales',
    signalPurpleDownySporulation: 'Hay esporulacion morada/gris en enves',
    signalCrownDistortion: 'La corona o brote central se ve deformado',
    signalBoltingStem: 'El tallo floral empieza a alargarse',
    signalTanPaperySpots: 'Las manchas se ven secas, cafe claro o papirosas',
    signalWaterSoakedSpots: 'Las manchas se ven acuosas o traslucidas',
    signalDenseWetCanopy: 'Dosel cerrado, mojado o con poca ventilacion',
    signalAphidContamination: 'Hay pulgon contaminando hoja comercial',
    signalWhitePustules: 'Hay pustulas blancas o ampollas en hoja',
    signalLeafEdgeBurn: 'El borde de hoja esta quemado o seco',
    signalPoorEmergence: 'Hubo nacencia pobre o plantulas desuniformes',
    signalColdExposure: 'Hubo frio, noche fria o trasplante expuesto',
    signalRecentStress: 'La planta viene de estres reciente',
    signalCactusSoftOrWatery: 'La zona esta blanda, acuosa o cede al tacto',
    signalCactusFirmDry: 'La zona esta firme, seca o dura',
    signalCactusProgressing: 'La zona aumenta o cambia entre revisiones',
    signalCactusStable: 'La zona permanece estable y no aumenta',
    signalCactusDarkExudate: 'Hay liquido oscuro o exudado',
    signalCactusAbnormalOdor: 'Hay olor anormal reportado',
    signalCactusCottonWaxScale:
        'Se distinguen cuerpos, escamas, cera o algodon en areolas y uniones',
    signalCactusFineWebbing: 'Hay telarana muy fina u organismos con lupa',
    signalCactusSunnySide: 'La zona afectada mira hacia el lado soleado',
    signalCactusChangedSunExposure:
        'Hubo cambio reciente de orientacion o exposicion al sol',
    signalCactusWrinkling: 'Se contraen costillas o se pierde volumen',
    signalCactusNewLeaning: 'La inclinacion es nueva o esta aumentando',
    signalCactusLossOfSupport: 'La base o un segmento pierde soporte',
    // Suculenta: preguntas de descarte, en lenguaje del agricultor.
    signalSucculentSoftOrWatery: 'La zona esta blanda, acuosa o cede al tacto',
    signalSucculentFirmDry: 'La zona esta firme y seca',
    signalSucculentProgressing: 'El cambio aumenta entre revisiones',
    signalSucculentStable: 'El cambio esta estable y no aumenta',
    signalSucculentAbnormalOdor: 'Hay olor anormal reportado',
    signalSucculentWrinkling: 'Las hojas se ven arrugadas o menos firmes',
    signalSucculentElongatedPaleGrowth:
        'El crecimiento nuevo sale largo, separado o palido',
    signalSucculentRosetteOpening:
        'La roseta se abrio o las hojas se aplanaron',
    signalSucculentChangedSunExposure: 'La planta recibio mas sol que antes',
    signalSucculentSunnySide: 'La zona afectada mira hacia el lado soleado',
    signalSucculentUniformWaxyBloom:
        'La capa blanca es uniforme desde que nacio la hoja',
    signalSucculentPowderyPatches:
        'Los parches blancos aumentan o pasan a hojas nuevas',
    signalSucculentCottonWaxInsects:
        'Se distinguen cuerpos o insectos dentro del material blanco',
    signalSucculentScaleBodies: 'Hay escamas adheridas o melaza pegajosa',
    signalSucculentFineWebbing: 'Hay telarana muy fina u organismos con lupa',
    signalSucculentRaisedBlisters:
        'Hay bultos o ampollas, sobre todo en el enves',
    signalSucculentCorkyScabs: 'Los bultos se volvieron beige o corchosos',
    signalSucculentRecentSpray:
        'Se aplico un producto o remedio en los ultimos dias',
    signalSucculentDropletPattern:
        'La mancha tiene forma de gotas o escurrimiento',
    signalSucculentFungusGnats: 'Hay mosquitas saliendo del sustrato',
    signalSucculentLowerLeavesOnly:
        'Solo afecta una o dos hojas inferiores viejas',
    signalSucculentLossOfSupport: 'La planta se afloja o pierde soporte',
    // Sábila / Aloe (Doc C §4): señales que el usuario reporta al confirmar.
    signalAloeSoftOrWatery: 'La zona esta blanda, acuosa o cede al tacto',
    signalAloeFirmDry: 'La zona esta firme y seca',
    signalAloeProgressing: 'El cambio aumenta entre revisiones',
    signalAloeStable: 'El cambio esta estable y no aumenta',
    signalAloeAbnormalOdor: 'Hay olor anormal reportado',
    signalAloeLossOfSupport: 'La planta se afloja o pierde soporte',
    signalAloeWrinkling: 'Las hojas se ven arrugadas o menos firmes',
    signalAloeWartyGrowth:
        'Hay verrugas, masas rugosas o crecimiento deforme que avanza',
    signalAloeCrookedFlowerStalk:
        'La vara floral salio torcida, crespa o deforme',
    signalAloeTouchingAnotherAloe:
        'La planta toca o esta junto a otra sabila o aloe',
    signalAloeGlassyTranslucent:
        'La zona se ve vidriosa o traslucida, como congelada',
    signalAloeReddishBrownBase:
        'La base tomo un color rojizo o cafe despues de frio',
    signalAloeChangedSunExposure: 'La planta recibio mas sol que antes',
    signalAloeSunnySide: 'La zona afectada mira hacia el lado soleado',
    signalAloeDryHardSpots: 'Las manchas se sienten secas y duras al tacto',
    signalAloeWetAdvancingLesion:
        'La mancha se siente empapada y va creciendo',
    signalAloeCottonWaxInsects:
        'Se distinguen cuerpos o insectos dentro del material blanco',
    signalAloeScaleBodies: 'Hay escamas adheridas a la hoja',
    signalAloeStickySooty:
        'Hay melaza pegajosa o una capa negra sobre la hoja',
    signalAloeFineStippling: 'Hay punteado muy fino o bronceado en la hoja',
    signalAloeFineWebbing: 'Hay telarana muy fina u organismos con lupa',
    signalAloeWhiteCrustSubstrate:
        'Hay costra blanca de sales en el sustrato o el borde de la maceta',
    signalAloeRecentFertilizer:
        'Se fertilizo o se regó con abono en los ultimos dias',
    signalAloeRecentSpray:
        'Se aplico un producto o remedio en los ultimos dias',
    signalAloeDropletPattern: 'La mancha tiene forma de gotas o escurrimiento',
    signalAloeElongatedPaleGrowth:
        'El crecimiento nuevo sale estirado, palido o inclinado a la luz',
    signalAloeLowerLeavesOnly: 'Solo afecta una o dos hojas inferiores viejas',
    signalAloeFungusGnats: 'Hay mosquitas saliendo del sustrato',
    signalAloeLeafCutRecent:
        'Se corto una hoja para gel hace poco en esa zona',
    // Maguey / Agave (Doc C §4): senales que el usuario reporta al confirmar.
    signalAgaveSoftOrWatery: 'La zona esta blanda, acuosa o cede al tacto',
    signalAgaveFirmDry: 'La zona esta firme y seca',
    signalAgaveDryCorkyBud:
        'El cogollo esta seco, rigido y corrugado, sin olor',
    signalAgaveLossOfAnchor: 'La roseta perdio anclaje o se afloja en el suelo',
    signalAgaveCenterCollapse: 'El centro de la roseta se esta colapsando',
    signalAgaveAbnormalOdor: 'Hay olor anormal ya perceptible',
    signalAgaveBasalLeafDryOnly:
        'Solo una o pocas hojas basales viejas y secas',
    signalAgaveProgressing: 'El cambio aumenta entre revisiones',
    signalAgaveStable: 'El cambio esta estable y no aumenta',
    signalAgaveSnoutWeevilAdult: 'Se ve un insecto oscuro con pico alargado',
    signalAgaveCreamLarvaeGalleries:
        'Hay larvas claras, galerias o tejido perforado',
    signalAgaveGreasyStreakInnerLeaf:
        'Raya grasosa en la cara interna de hojas nuevas',
    signalAgaveDeformedCore: 'El cogollo o el crecimiento nuevo se deforma',
    signalAgaveSoftScaleBodies: 'Hay placas con un cuerpo debajo o colonias',
    signalAgaveStickySooty: 'La superficie esta pegajosa o con capa negra',
    signalAgaveSmallPlantBugs:
        'Hay insectos pequenos moviendose sobre la planta',
    signalAgavePaleFeedingScars:
        'Hay cicatrices claras y superficiales de alimentacion',
    signalAgaveSunkenConcentricRings: 'Lesion hundida con anillos concentricos',
    signalAgavePinkOrangeSporeMass: 'Hay masa rosada o naranja en humedad',
    signalAgaveGraySpotChloroticHalo: 'Mancha grisacea con halo amarillo',
    signalAgaveLesionReachingCore:
        'La lesion avanza hacia la base o el cogollo',
    signalAgaveFrostBlackenedTissue:
        'El tejido se volvio negro o translucido tras el frio',
    signalAgaveSunnySidePatch: 'La zona afectada mira hacia el lado soleado',
    signalAgaveChangedSunExposure: 'La planta recibio mas sol que antes',
    signalAgaveWhiteCrustSubstrate: 'Hay costra blanca en el suelo o la maceta',
    signalAgaveRecentFertilizer: 'Se fertilizo o abono hace poco',
    signalAgaveLeafTipEdgeBurn:
        'Las puntas o bordes de las hojas estan secos',
    signalAgaveMechanicalWoundMark: 'Hay un corte, golpe o herida visible',
    signalAgaveOffsetRemovalRecent: 'Se retiro un hijuelo hace poco',
    signalAgaveMissingChewedTissue: 'Falta tejido o esta mordido',
    signalAgaveAnimalTracksScat: 'Hay huellas, excremento o madrigueras',
    signalAgaveCentralFlowerStalk:
        'Sale un tallo alto desde el centro de la roseta',
    signalAgaveOffsetsPresent: 'La planta tiene hijuelos',
    signalAgaveGradualOuterDrying:
        'Las hojas exteriores se secan de forma gradual',
    signalAgaveUniformWaxyBloom: 'Hay una capa cerosa azul/gris uniforme',
    signalAgaveLeafImprint:
        'Hay improntas simetricas de los dientes de las hojas',
    signalThripsSilverScarring: 'Hay plateado/bronceado y raspado por trips',
    signalThripsInNeckFolds: 'Hay trips escondidos en cuello y pliegues',
    signalDownyFuzzyGrowth: 'Hay crecimiento velloso gris/blanco/morado',
    signalPurpleConcentricLesions: 'Lesiones purpuras con anillos en hoja',
    signalDarkOliveLeafBlight: 'Manchas oscuras oliva-negro que coalescen',
    signalWhiteSunkenLeafSpots: 'Manchas blancas hundidas con halo',
    signalPinkRoots: 'Las raices se ven rosadas, rojas o purpuras',
    signalBasalPlateBrownRot: 'El plato basal se ve cafe con pudricion seca',
    signalWhiteMyceliumSclerotia: 'Hay micelio blanco con bolitas negras',
    signalNeckSoft: 'El cuello del bulbo esta blando',
    signalGrayMoldNeck: 'Hay moho gris entre escamas o en el cuello',
    signalBulbScaleWaterSoaked: 'Las escamas internas se ven acuosas',
    signalSourSmell: 'Hay olor agrio o avinagrado en el bulbo',
    signalBlackMoldSpores: 'Hay polvo o esporas negras bajo las escamas',
    signalBlueGreenMold: 'Hay moho azul-verde en las escamas externas',
    signalCenterLeafBleaching: 'La hoja central se ve blanqueada o colapsada',
    signalStrawDiamondLesions: 'Hay lesiones pajizas en forma de diamante',
    signalNoBulbPhotoperiod: 'Hay mucha hoja pero el bulbo no avanza',
    signalThickNeck: 'El cuello esta grueso y el follaje muy verde tarde',
    signalBulbSplitting: 'Hay bulbos partidos, dobles o rajados',
    signalSeedstalkBolting: 'Hay tallo floral / espigado visible',
    signalMaggotLarvae: 'Hay larvas blancas sin patas en base o semilla',
    signalPoorCuringNeckMoist: 'El cuello quedo humedo tras cosecha',
    signalSeedCloveBlueGreenMold: 'El diente-semilla trae moho azul-verde',
    signalSoftCloveBeforePlanting: 'El diente venia blando antes de plantar',
    signalBulbMiteBrownScars: 'Hay cicatrices cafes o polvo por acaros',
    signalDistortedSpongyBulb: 'El bulbo se ve deformado o esponjoso',
    signalPoorCloveDifferentiation: 'Hay pocos dientes o dientes mal definidos',
    signalExposedClovesBrooming: 'Los dientes se abren o quedan expuestos',
    signalUnexpectedScape: 'Aparece escapo/canuto no esperado',
    signalLateGreenExcessVigor: 'Follaje muy verde y vigoroso tarde',
    signalStorageSprouting: 'Hay brotes durante almacenamiento',
    signalSunscaldOuterScales: 'Escamas externas con asoleado o quemadura',
    signalUniformLeafBurn: 'Quemadura uniforme sin patron de plaga',
    signalWeedCompetition: 'Hay maleza compitiendo o Allium voluntario',
    signalAmberBacterialOoze: 'Hay exudado ambar o pegajoso en brote/rama',
    signalShepherdsCrookShoot: 'El brote se dobla en gancho (cayado de pastor)',
    signalFrostEvent: 'Hubo helada o temperatura bajo cero',
    signalHailEvent: 'Hubo granizo o heridas por golpe',
    signalGallsOnWoodRoots: 'Hay agallas o deformaciones en madera/raiz',
    signalHighPhCalcareous: 'El suelo es de pH alto o calcareo',
    signalExposedFruitSouthwest:
        'El fruto esta expuesto al sol (lado suroeste)',
    signalSpringWetFoliage: 'Primavera humeda con mojado foliar prolongado',
    signalPsyllaNymphsShoots: 'Hay ninfas/insectos pequenos en brotes y enves',
    signalNoPollinatorNearby:
        'No hay otra variedad compatible floreando cerca / pocas abejas',
    signalShootTipWilt: 'Puntas de brote marchitas o quemadas',
    signalInsufficientChill: 'Brotación/floración irregular o dispareja',
    signalShuckStuck: 'El ruezno no abre o se queda pegado a la cáscara',
    signalRoundBbExitHole: 'Agujero redondo tipo munición (BB) en la cáscara',
    signalYellowAphids: 'Pulgones amarillos y mielecilla en el envés',
    signalBlackPecanAphids:
        'Puntos amarillos que se vuelven cafés y defoliación (pulgón negro)',
    signalNavelOrangeworm:
        'Gusano/larva en la nuez con frass o telaraña (gusano del ombligo)',
    signalMummyNuts: 'Hay momias (nueces viejas pegadas) en árbol o suelo',
    signalEarlyHullSplit: 'La cascarilla/hull se abrió antes de tiempo',
    signalAsymmetricMottle:
        'El amarillamiento es disparejo/asimétrico en la hoja',
    signalPsyllidWaxyTubules:
        'Hay ninfas o tubitos cerosos blancos en los brotes (psílido)',
    signalFlushNewGrowth: 'Hay brote tierno / flush nuevo',
    signalFruitBitterMisshapen:
        'La fruta sale chica, ladeada, deforme o amarga',
    signalGumAtTrunkBase: 'Hay goma/exudado en la base del tronco o cuello',
    signalRindScarsNearCalyx:
        'Hay cicatrices o anillos cerca del cáliz en fruta chica',
    signalFruitSplitAfterIrrigation:
        'La fruta se rajó tras un periodo seco y luego riego/lluvia',
    signalFruitLowCanopyRainSplash:
        'La fruta dañada está en la parte baja, con salpicadura de suelo',
    signalWhiteGreenBlueMold: 'Hay moho blanco/verde/azul en la fruta',
    signalRecentSprayOilCopper:
        'Hubo aspersión reciente de aceite, cobre o herbicida',
    signalFruitLarvae: 'Hay larvas o picaduras dentro de la fruta',
    // Tulipán (Doc C §12.2): señales que el usuario reporta al confirmar.
    signalTulipPostBloomTiming: 'La flor ya terminó o fue retirada',
    signalTulipGradualYellowing:
        'El amarillamiento avanza despacio desde puntas o bordes',
    signalTulipPrematureTiming: 'El cambio aparece antes de botón o flor',
    signalTulipTissueFirm: 'La base y el bulbo se sienten firmes',
    signalTulipSoftOrWatery: 'El bulbo o el tejido está blando o acuoso',
    signalTulipAbnormalOdor: 'Hay olor fuerte, agrio o desagradable',
    signalTulipRapidProgression: 'El deterioro avanzó en horas o pocos días',
    signalTulipBasalBrownRot: 'La placa basal está café, hundida o seca',
    signalTulipRootsAbsentOrRotted:
        'Las raíces están podridas, ausentes o se desprenden',
    signalTulipSourOdor: 'Hay olor agrio en la base del bulbo',
    signalTulipPinkWhiteGrowth:
        'Hay crecimiento blanco o rosado entre las escamas',
    signalTulipRootsGlassy: 'Las raíces se ven acuosas o transparentes',
    signalTulipRootsBrown: 'Las raíces están cafés',
    signalTulipRootsBreakEasily: 'Las raíces se rompen al tocarlas',
    signalTulipRootRings: 'Hay anillos cafés en la raíz o zonas marchitas',
    signalTulipShootRotBelowSoil: 'El brote se pudre debajo del suelo',
    signalTulipRootsStillIntact: 'Las raíces siguen relativamente intactas',
    signalTulipBrownWhiteSpots:
        'Hay manchas cafés o blancas que crecen o se unen',
    signalTulipGraySporulation: 'Aparece polvo o moho gris en humedad',
    signalTulipTwistedLeaves: 'Las hojas están torcidas o colapsadas',
    signalTulipBlackSclerotia:
        'Hay puntos negros firmes en tejido muerto o escamas',
    signalTulipIrregularColorBreak:
        'Hay rayas nuevas e irregulares en los pétalos',
    signalTulipLeafMottling: 'Las hojas muestran moteado o mosaico',
    signalTulipGeneticPetalPattern:
        'El patrón de la flor coincide con el cultivar (estable y simétrico)',
    signalTulipStickyHoneydew: 'La superficie se siente pegajosa (melaza)',
    signalTulipVisibleAphids:
        'Hay insectos pequeños agrupados en hojas, tallos o botón',
    signalTulipGum: 'Se formó goma clara o café entre las escamas',
    signalTulipBudNecrosis: 'El botón se volvió negro o necrótico',
    signalTulipOpenShoot: 'El brote interno quedó abierto',
    signalTulipFruitStoredNearby:
        'Hubo fruta madura, humo o combustión cerca del almacenamiento',
    signalTulipDarkWateryStemZone:
        'Hay una zona oscura y acuosa donde el tallo se dobla',
    signalTulipLeafSplitting: 'La hoja presenta grietas transversales',
    signalTulipConstrictionBend: 'El tallo se contrae y se dobla en una zona',
    signalTulipWaterDropletsFromTissue: 'Salen gotas de agua del tejido',
    signalTulipLeansTowardLight: 'El tallo se inclina hacia la luz',
    signalTulipThinPaleStem: 'El tallo es delgado y pálido',
    signalTulipInterveinalChlorosis:
        'Las hojas amarillean entre las venas, con venas verdes',
    signalTulipWhiteCollapsedTissue:
        'El tejido se volvió blanco, translúcido y colapsó',
    signalTulipRapidOpening: 'La flor abrió con mucha rapidez',
    signalTulipRootsShortCrooked: 'Las raíces son cortas y torcidas',
    signalTulipDarkRootTips: 'Las puntas de las raíces están oscuras',
    signalTulipBulbMissing: 'El bulbo está ausente o fue excavado',
    signalTulipFreshExcavation:
        'Hay suelo recién removido, túneles o huellas',
    signalTulipChewedTissue: 'El tejido tiene mordidas o cortes',
    signalTulipLeavesCutGreen:
        'Las hojas se cortaron cuando todavía estaban verdes',
    signalTulipBrownConcentricRings:
        'Un corte del bulbo muestra anillos o bandas internas',
    // Girasol / Sunflower (Doc C §13): senales que el usuario reporta al confirmar.
    signalSunflowerSeedMissingOrSoft:
        'La semilla está ausente, blanda u oscura',
    signalSunflowerSoilCrust: 'La superficie formó una costra dura',
    signalSunflowerUnevenPatches: 'El problema aparece en parches',
    signalSunflowerDeepSowing: 'La semilla quedó muy profunda',
    signalSunflowerHealthyEmergenceNearby:
        'Otras semillas cercanas emergieron bien',
    signalSunflowerSeedlingPresent: 'Ya se observa la plántula',
    signalSunflowerSoftDarkNeck: 'El cuello está blando y oscuro',
    signalSunflowerOuterRootSloughs: 'La capa exterior de la raíz se desprende',
    signalSunflowerReddishBrownGirdle:
        'Hay lesión rojiza o café que rodea el tallo',
    signalSunflowerStemCleanCut:
        'El tallo parece cortado o mordido de forma limpia',
    signalSunflowerFirmDryBreak: 'El quiebre está firme y seco',
    signalSunflowerSlimeTrail: 'Hay rastro brillante o de baba',
    signalSunflowerSoftWateryBase: 'La base está blanda o acuosa',
    signalSunflowerLossOfSupport: 'La planta se afloja o pierde soporte',
    signalSunflowerAbnormalOdor: 'Hay olor anormal',
    signalSunflowerRootsFirmLight: 'Las raíces están firmes y claras',
    signalSunflowerBaseFirmDry: 'La base está firme y seca',
    signalSunflowerWiltInWetSoil:
        'La planta se marchita aunque el suelo está húmedo',
    signalSunflowerPatchOrSinglePlant: 'Afecta plantas aisladas o parches',
    signalSunflowerRecoversAfterWater: 'Recupera después de corregir humedad',
    signalSunflowerNormalPostBloomDroop:
        'Solo la cabeza madura se inclina gradualmente',
    signalSunflowerSoilDry: 'La zona radicular está seca',
    signalSunflowerRecoversEvening: 'Recupera firmeza al bajar el calor',
    signalSunflowerContainerHeated: 'La maceta se calienta mucho',
    signalSunflowerLeafEdgeDry: 'Los bordes están secos y crujientes',
    signalSunflowerNoRecoveryOvernight: 'No recupera durante la noche',
    signalSunflowerPetioleCenteredLesion:
        'La lesión se centra en la unión del pecíolo',
    signalSunflowerTriangularLeafLesion:
        'La hoja tiene una lesión triangular desde el margen',
    signalSunflowerHollowPith: 'La médula está hueca o se hunde fácilmente',
    signalSunflowerPrematureDrying:
        'La planta se seca antes de la ventana esperada',
    signalSunflowerLodging: 'La planta se vence o cae',
    signalSunflowerSuperficialBlackSpotOnly:
        'La lesión negra parece superficial',
    signalSunflowerFirmIntactPith: 'La médula permanece firme',
    signalSunflowerMechanicalBruise: 'Hubo golpe, roce o amarre',
    signalSunflowerNewLeaning: 'La inclinación es nueva o aumenta',
    signalSunflowerStemCrease: 'Hay pliegue o rajadura en el tallo',
    signalSunflowerRootPlateLoose: 'La base se mueve con la raíz',
    signalSunflowerHeadHeavy: 'La cabeza está grande o pesada',
    signalSunflowerWindEvent: 'Hubo viento fuerte',
    signalSunflowerStemThin: 'El tallo está largo y delgado',
    signalSunflowerSoilLooseWet: 'El suelo está flojo y muy húmedo',
    signalSunflowerStemFirmVertical: 'El tallo permanece firme y vertical',
    signalSunflowerStableAngle: 'El ángulo no aumenta',
    signalSunflowerLowerLeavesFirst: 'Comenzó en hojas inferiores',
    signalSunflowerLesionsCoalesce: 'Las manchas se unen',
    signalSunflowerRainSplash: 'Hubo lluvia o salpicadura frecuente',
    signalSunflowerYellowThenBrown:
        'La zona amarillea y después se vuelve café',
    signalSunflowerDefoliationBottomUp:
        'La pérdida de hojas avanza de abajo hacia arriba',
    signalSunflowerGradualUniformYellowing:
        'El amarillamiento es gradual y uniforme',
    signalSunflowerInsectBodies: 'Se observan insectos o cuerpos adheridos',
    signalSunflowerPowderRubOff: 'El material se desprende como polvo',
    signalSunflowerUpperSurfaceWhite:
        'El blanco está principalmente sobre la hoja',
    signalSunflowerBlackSpecksLate:
        'Aparecen puntos negros en parches blancos viejos',
    signalSunflowerUniformDustResidue:
        'La capa es uniforme y coincide con polvo o aplicación',
    signalSunflowerCottonyInsects: 'Se ven insectos dentro del material blanco',
    signalSunflowerVeinBoundChlorosis: 'El amarillamiento sigue las venas',
    signalSunflowerSystemicStunting: 'La planta está mucho más baja que otras',
    signalSunflowerYoungPlant: 'Ocurre antes de floración',
    signalSunflowerNoStunting: 'La planta mantiene altura y vigor',
    signalSunflowerAbioticPatternUniform:
        'El patrón es uniforme y coincide con un evento ambiental',
    signalSunflowerCinnamonPustules: 'Hay pústulas color canela',
    signalSunflowerYellowHalo: 'Las pústulas tienen halo amarillo',
    signalSunflowerUndersidePustules: 'Hay pústulas en el envés',
    signalSunflowerWildVolunteerNearby:
        'Hay girasol voluntario o residuo cercano',
    signalSunflowerSoilSplashOnly: 'El material parece tierra salpicada',
    signalSunflowerFlatNecroticSpot: 'La lesión es plana, no polvosa',
    signalSunflowerInterveinalNecrosis: 'El tejido muere entre venas',
    signalSunflowerProgressesUpward: 'El daño avanza hacia hojas superiores',
    signalSunflowerPithShrunkenDark: 'La médula está contraída y oscura',
    signalSunflowerYoungLeavesOnly: 'Solo afecta hojas nuevas',
    signalSunflowerUniformLateYellowing:
        'Toda la planta amarillea gradualmente al final',
    signalSunflowerLowerLeavesOnly: 'Solo afecta hojas inferiores',
    signalSunflowerStageAfterBloom: 'La floración ya terminó o está terminando',
    signalSunflowerLowNPattern: 'El amarillamiento inicia en hojas viejas',
    signalSunflowerShadedLowerLeaves:
        'Las hojas afectadas quedan bajo sombra del dosel',
    signalSunflowerRapidWholePlantYellow:
        'Toda la planta amarillea rápidamente',
    signalSunflowerUpperLeavesFirst: 'Comienza en hojas nuevas',
    signalSunflowerActiveSpotsOrPustules:
        'Hay manchas, pústulas o crecimiento activo',
    signalSunflowerOlderLeavesFirst: 'El patrón empieza en hojas viejas',
    signalSunflowerRecentFertilizer: 'Hubo fertilización reciente',
    signalSunflowerWaterSoakedMargin: 'El borde está acuoso',
    signalSunflowerActiveFungalMargin:
        'El borde tiene crecimiento o halo activo',
    signalSunflowerColdEvent: 'Hubo frío o helada',
    signalSunflowerMosaicLightDark: 'Hay mosaico de verde claro y oscuro',
    signalSunflowerWitchesBroom: 'Hay muchos brotes cortos anormales',
    signalSunflowerFlowerGreening: 'La flor desarrolla partes verdes anormales',
    signalSunflowerLeafCurl: 'Las hojas se curvan o deforman',
    signalSunflowerInternodesShort: 'Los internudos son anormalmente cortos',
    signalSunflowerAphidsOrLeafhoppers: 'Se observan pulgones o chicharritas',
    signalSunflowerChemicalDropletPattern:
        'El daño sigue gotas o escurrimientos',
    signalSunflowerGeneticUniformTrait:
        'Todas las plantas del lote comparten el rasgo',
    signalSunflowerVisibleAphidClusters: 'Se ven grupos de pulgones',
    signalSunflowerAntActivity: 'Hay hormigas subiendo por la planta',
    signalSunflowerTenderNewGrowth:
        'El tejido o brote afectado es nuevo y tierno',
    signalSunflowerHighNitrogenContext:
        'Hay crecimiento muy tierno o N alto orientativo',
    signalSunflowerNoInsectsFound: 'No se encontraron insectos tras revisar',
    signalSunflowerFineWebbingOnly: 'Solo hay fibras finas sin mielecilla',
    signalSunflowerDryDust: 'El material es polvo seco',
    signalSunflowerFineStippling: 'Hay punteado fino abundante',
    signalSunflowerMitesWithLens: 'Se observan ácaros con lupa',
    signalSunflowerLowerLeafUnderside:
        'El daño se concentra en envés de hojas bajas',
    signalSunflowerStickyHoneydew: 'Hay superficie pegajosa',
    signalSunflowerLargeChewedHoles: 'Hay agujeros grandes masticados',
    signalSunflowerDarkFecalSpecks: 'Hay puntos fecales oscuros',
    signalSunflowerBudScarring: 'El botón tiene raspado o cicatriz',
    signalSunflowerPetalDistortion: 'Los pétalos salen deformes',
    signalSunflowerDamageInsideBud: 'El daño se concentra dentro del botón',
    signalSunflowerMechanicalTear: 'Hay desgarro por roce o viento',
    signalSunflowerLarvaOrBeetleVisible: 'Se observa larva o escarabajo',
    signalSunflowerNightDamage: 'El daño aumenta durante la noche',
    signalSunflowerRaggedMargin: 'El borde queda irregular y masticado',
    signalSunflowerNecroticSpotIntact: 'Existe mancha necrótica sin mordida',
    signalSunflowerHailTearPattern: 'Varias hojas se rasgaron tras granizo',
    signalSunflowerCShapedLarva: 'Hay una larva curvada cerca del suelo',
    signalSunflowerSoilDisturbed: 'El suelo está removido',
    signalSunflowerPeckMarks: 'Hay marcas de pico',
    signalSunflowerMissingSeeds: 'Faltan semillas o partes del disco',
    signalSunflowerBitePattern: 'Hay mordidas mayores',
    signalSunflowerTracksOrDroppings: 'Hay huellas o excremento',
    signalSunflowerHeadExposed: 'La cabeza queda accesible a fauna',
    signalSunflowerGrayMycelium: 'Hay hilos o crecimiento gris',
    signalSunflowerInsectFrassInsideStem: 'Hay excremento dentro del tallo',
    signalSunflowerNoBudPastWindow: 'La fecha ya superó la ventana sin botón',
    signalSunflowerLongThinGrowth: 'El crecimiento es largo y delgado',
    signalSunflowerLowLight: 'Recibe poca luz directa',
    signalSunflowerExcessVegetativeGrowth:
        'Hay follaje excesivo y transición tardía',
    signalSunflowerRootRestricted: 'La raíz está confinada',
    signalSunflowerStageDateUncertain: 'La fecha fue estimada o es incierta',
    signalSunflowerBudHiddenPresent: 'Existe un botón pequeño entre hojas',
    signalSunflowerProfileLate: 'El perfil puede ser tardío',
    signalSunflowerRecentSowingEstimate:
        'La fecha se retrocalculó desde una planta comprada',
    signalSunflowerBudBrownDry: 'El botón está café y seco',
    signalSunflowerBudSoftGray: 'El botón está blando o con crecimiento gris',
    signalSunflowerBudOpeningNormally: 'El botón continúa abriendo',
    signalSunflowerCutPerformed: 'La flor fue cortada intencionalmente',
    signalSunflowerHeadAsymmetric: 'El capítulo crece de forma asimétrica',
    signalSunflowerFasciatedStem: 'El tallo está aplanado o fusionado',
    signalSunflowerCultivarNormalDoubleFlower:
        'La variedad produce flor doble o forma especial',
    signalSunflowerUniformTraitAcrossBatch:
        'El rasgo se repite de forma uniforme',
    signalSunflowerNormalOpeningSequence:
        'La flor abre de forma normal desde el borde',
    signalSunflowerPetalsWetStuck: 'Los pétalos están húmedos y pegados',
    signalSunflowerLesionProgressing: 'La lesión aumenta entre revisiones',
    signalSunflowerOldFlower: 'La flor lleva varios días abierta',
    signalSunflowerPetalsDryUniform: 'Los pétalos se secan de manera uniforme',
    signalSunflowerNormalPetalDrop: 'Los pétalos caen gradualmente al final',
    signalSunflowerNoGrayGrowth: 'No existe moho gris visible',
    signalSunflowerHeadSoftWatery: 'La cabeza está blanda y acuosa',
    signalSunflowerRottenOdor: 'Hay olor fuerte a tejido podrido',
    signalSunflowerSlime: 'Hay masa viscosa o baba',
    signalSunflowerHeadWound: 'Existe herida en la cabeza',
    signalSunflowerHailBirdInjury: 'Hubo granizo o daño de ave',
    signalSunflowerWarmHumidWeather: 'Hubo calor con humedad alta',
    signalSunflowerHeadDryFirm: 'La cabeza está seca y firme',
    signalSunflowerNoOdor: 'No hay olor anormal',
    signalSunflowerHeadShredded: 'La cabeza se deshilacha o desintegra',
    signalSunflowerWhiteMycelium: 'Hay crecimiento blanco',
    signalSunflowerBlackSclerotia:
        'Hay estructuras negras, duras e irregulares',
    signalSunflowerGrayThreadsBlackPins:
        'Hay hilos grises y puntos negros pequeños',
    signalSunflowerPriorSoftRot: 'Antes hubo tejido blando o acuoso',
    signalSunflowerUniformNormalDrying: 'El secado es uniforme y sin moho',
    signalSunflowerSeedsFirm: 'El disco permanece firme',
    signalSunflowerNoMoldStructures: 'No hay estructuras de moho',
    signalSunflowerBirdPerching: 'Las aves se posan sobre la cabeza',
    signalSunflowerLargeHeadProfile: 'El perfil produce cabeza grande',
    signalSunflowerGradualAngle: 'La inclinación aumenta lentamente',
    signalSunflowerWholePlantWilt: 'Hojas y tallo también pierden firmeza',
    signalSunflowerNeckSoftDark:
        'El cuello bajo la cabeza está blando u oscuro',
    signalSunflowerRapidCollapse: 'El colapso ocurre rápido',
    signalSunflowerDrainagePoor: 'El agua no sale correctamente',
    signalSunflowerSoilWetForDays: 'El suelo permanece húmedo durante días',
    signalSunflowerLowerLeafYellow: 'Hojas bajas amarillas',
    signalSunflowerNormalSenescence:
        'El reloj ya corresponde al cierre natural',
    signalSunflowerWholePlantFlaccid: 'Toda la planta está flácida',
    signalSunflowerRootRotSigns: 'Hay raíz oscura o blanda',
    signalSunflowerSunnySide: 'El daño mira al lado más soleado',
    signalSunflowerChangedExposure: 'Hubo aumento reciente de sol',
    signalSunflowerDropletPattern: 'El daño sigue forma de gotas',
    signalSunflowerProgressingInShade:
        'La lesión avanza también en zonas no expuestas',
    signalSunflowerWaterSoakedAfterCold:
        'El tejido quedó acuoso después del frío',
    signalSunflowerUniformExposedDamage:
        'Varias partes expuestas se dañaron igual',
    signalSunflowerForecastFrost: 'Hubo registro o pronóstico de helada',
    signalSunflowerBlackenedTissue: 'El tejido se volvió oscuro tras el frío',
    signalSunflowerLocalizedRotOdor: 'El daño localizado tiene olor',
    signalSunflowerWhiteCrust:
        'Hay costra blanca en sustrato o borde de maceta',
    signalSunflowerRootTipBurn: 'Las puntas de raíz están oscuras o detenidas',
    signalSunflowerContainerContext: 'La planta está en maceta',
    signalSunflowerNoRecentInput: 'No hubo fertilización o producto reciente',
    signalSunflowerHighResistance:
        'La resistencia está alta con humedad interpretable',
    signalSunflowerRootCircling: 'Las raíces circulan por la maceta',
    signalSunflowerHardPan: 'Existe una capa dura bajo la raíz',
    signalSunflowerSmallRootVolume: 'El volumen de raíz es insuficiente',
    signalSunflowerRepeatedDrying: 'La maceta se seca repetidamente',
    signalSunflowerRootsExpandingFreely:
        'Las raíces tienen espacio y estructura suelta',
    signalSunflowerResistanceNormalMoistSoil:
        'La resistencia es normal con suelo húmedo',
    signalSunflowerGeneticCompactProfile: 'El perfil es compacto por diseño',
    signalSunflowerOlderLeavesYellow: 'Las hojas viejas amarillean primero',
    signalSunflowerPurpleTint: 'Hay tono rojizo o morado',
    signalSunflowerYoungInterveinalChlorosis:
        'Hojas nuevas amarillas entre venas',
    signalSunflowerStunted: 'El crecimiento está detenido',
    signalSunflowerWeakStem: 'El tallo está débil',
    signalSunflowerNpkOrientativeOutOfBand:
        'El NPK orientativo está fuera de banda',
    signalSunflowerStageSenescence: 'La etapa resuelta es senescencia',
    signalSunflowerNoActiveLesion: 'No hay lesión activa, moho ni pudrición',
    signalSunflowerStemStillFirm: 'El tallo sigue firme',
    signalSunflowerNewPustulesOrMold: 'Aparecen pústulas o moho nuevos',
    signalSunflowerWarmWetSoil: 'El suelo está cálido y húmedo',
    signalSunflowerLateAfterBloom: 'Aparece tarde, después de la floración',
    signalSunflowerPatchOrRow: 'Aparece en manchones o por hilera',
    signalSunflowerGradualProgression: 'El cambio avanza de forma gradual',
    signalSunflowerUniformNutrientPattern:
        'El patrón coincide con nutrición, no con virus',
    signalSunflowerStemBentByWeight: 'El tallo se dobló por el peso',
    signalSunflowerSoftRot: 'Hay pudrición blanda visible en la cabeza',
    signalSunflowerNormalPetalAging: 'Es el envejecimiento normal del pétalo',
    signalSunflowerPhysicalDamage: 'Hubo daño físico reciente',
    signalSunflowerStemFirm: 'El tallo está firme',
    signalSunflowerPustules: 'Hay pústulas visibles',
    signalSunflowerInsectPattern:
        'El daño sigue un patrón de insecto, no de frío',
    signalSunflowerActivePustules: 'Hay pústulas activas, no quemadura',
  };

  static String organLabel(String organId) => organLabelsEs[organId] ?? organId;

  static String symptomLabel(String symptomId) =>
      symptomLabelsEs[symptomId] ?? symptomId;

  static String signalLabel(String signalId) =>
      signalLabelsEs[signalId] ?? signalId;
}
