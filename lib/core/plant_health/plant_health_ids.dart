class PlantHealthIds {
  PlantHealthIds._();

  // ── Organs ──────────────────────────────────────────────────────────────────
  static const String organWhorl = 'whorl';
  static const String organLeaf = 'leaf';
  static const String organStem = 'stem';
  static const String organRoot = 'root';
  static const String organCrown = 'crown';
  static const String organSpike = 'spike';
  static const String organEar = 'ear';
  static const String organPod = 'pod';
  static const String organWholePlant = 'whole_plant';
  static const String organGrain = 'grain';

  // ── Symptoms ────────────────────────────────────────────────────────────────
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

  // ── Signals ─────────────────────────────────────────────────────────────────
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

  // ── Label maps ──────────────────────────────────────────────────────────────

  static const Map<String, String> organLabelsEs = <String, String>{
    organWhorl: 'Cogollo',
    organLeaf: 'Hoja',
    organStem: 'Tallo',
    organRoot: 'Raíz',
    organCrown: 'Cuello / corona',
    organSpike: 'Espiga',
    organEar: 'Mazorca',
    organPod: 'Vaina',
    organWholePlant: 'Planta completa',
    organGrain: 'Grano',
  };

  static const Map<String, String> symptomLabelsEs = <String, String>{
    symptomOrangeReddishPustules: 'Pústulas naranja o rojizas',
    symptomNecroticFoliarSpots: 'Manchas foliares café o necróticas',
    symptomAphidColonies: 'Colonias de pulgón',
    symptomLateDefoliation: 'Defoliación rápida / daño foliar tardío',
    symptomWhorlFeeding: 'Cogollo perforado o comido',
    symptomStuntingReddening: 'Enanismo o rojizos',
    symptomRaisedBlackSpots: 'Puntos negros elevados',
    symptomOrangePustules: 'Pústulas anaranjadas',
    symptomEarRot: 'Pudrición o moho en mazorca',
    symptomWhiteflyPresence: 'Mosca blanca visible',
    symptomNetLikeSpots: 'Manchas reticuladas en hoja',
    symptomMosaicYellowing: 'Mosaico o amarillamiento',
    symptomWiltPodLesions: 'Marchitez o lesiones en vaina',
    symptomDarkSunkenLesions: 'Lesiones oscuras hundidas',
    symptomAngularSpots: 'Manchas angulares en hoja',
    symptomStripedLeaves: 'Hojas con rayas o bandas',
    symptomGrayFoliarScald: 'Escaldadura gris / blanquecina',
  };

  static const Map<String, String> signalLabelsEs = <String, String>{
    signalPustulesOnStem: 'También hay pústulas en tallo',
    signalNoClearPustules: 'No veo pústulas claras',
    signalHumidWindow: 'Hubo humedad alta / ambiente húmedo',
    signalCoolDewyWindow: 'Clima fresco con rocío prolongado',
    signalAphidEarlyToxicity: 'Daño tóxico temprano / clorosis fuerte',
    signalSpikeFeeding: 'La colonia ya está en espiga',
    signalLeafRolling: 'Hojas enrolladas o torcidas',
    signalActiveChewing: 'Hay mordidas activas o larvas',
    signalNoBiteMarks: 'No hay mordidas claras',
    signalRapidFoliarCollapse: 'El follaje verde cayó muy rápido',
    signalFrassPresent: 'Hay excretas visibles',
    signalDeadHeart: 'Hay corazón muerto',
    signalVectorPresent: 'Hay vector presente',
    signalCannotScrapeOff: 'No se desprende al raspar',
    signalSporesRubOff: 'Sí suelta polvo de esporas',
    signalMoldOnEar: 'Hay moho visible en mazorca',
    signalSilkDamage: 'Jilotes / sedas dañados',
    signalDarkStriations: 'Estrías oscuras en hoja o tallo',
    signalStickyHoneydew: 'Mielecilla pegajosa en hojas',
    signalSootyMold: 'Fumagina (tizne negro) en follaje',
    signalWhiteflyCloud: 'Nube de mosca blanca al mover follaje',
    signalSeedStaining: 'Grano manchado o decolorado',
    signalNetPattern: 'Patrón reticulado en lesiones',
    signalScaldBleaching: 'Blanqueamiento o escaldadura en hoja',
    signalPodCanker: 'Cancro o lesión en vaina',
    signalWaterSoakedMargin: 'Margen acuoso en las manchas',
    signalAngularLesionPattern: 'Lesiones con forma angular definida',
    signalPinkSporeMass: 'Masa de esporas rosada visible',
  };

  static String organLabel(String organId) => organLabelsEs[organId] ?? organId;
  static String symptomLabel(String symptomId) => symptomLabelsEs[symptomId] ?? symptomId;
  static String signalLabel(String signalId) => signalLabelsEs[signalId] ?? signalId;
}
