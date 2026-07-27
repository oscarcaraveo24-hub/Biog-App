/// Catálogo de riesgos, sanidad y estrés del Cempasúchil (Documento C).
///
/// Contrato de seguridad (Documento C §1): BIO-G NO diagnostica patógenos, NO
/// prescribe plaguicidas ni dosis. Una lectura de sensor por sí sola nunca
/// genera un `high` sanitario: se requiere una señal observada fuerte reportada
/// por el usuario (§33). El lenguaje es "condición compatible con…", "revisa",
/// "por confirmar". La senescencia normal y el fin del ciclo son procesos
/// NORMALES, no enfermedad (§S23).
///
/// Este archivo es el VOCABULARIO estable (grupos, niveles, urgencias e ids de
/// riesgo). El detalle clínico (síndromes, diferenciales, señales, preguntas de
/// confirmación) vive en
/// `lib/core/plant_health/catalog/marigold_syndromes.dart`, que consume el
/// motor de sanidad COMPARTIDO. Los ids aquí coinciden 1:1 con los ids de
/// síndrome para que el motor y el reporte los referencien sin duplicar
/// (Documento C §36).
library;

/// Familia del riesgo (Documento C §6).
enum MarigoldRiskGroup {
  seedAndSeedling,
  rootCrownStructure,
  foliageDisease,
  flowerAndBud,
  pestsInvertebrates,
  abioticStress,
  benignProcess,
}

/// Nivel de salida del riesgo (Documento C §32). El sensor nunca alcanza los
/// niveles altos por sí solo: eso requiere una señal observada.
///
/// `critical` NO se usa por defecto en Cempasúchil v1 (§32): queda reservado
/// para riesgo regulatorio confirmado, contaminación química, seguridad humana
/// o instrucción de autoridad.
enum MarigoldRiskLevel { normal, watch, review, highPriority, separateAndEscalate }

/// Urgencia recomendada (Documento C §32). El sensor nunca alcanza `immediate`
/// por sí solo: requiere confirmación externa/fitosanitaria.
enum MarigoldRiskUrgency { monitor72h, review48h, review24h, sameDay, immediate }

/// Disclaimer canónico obligatorio en cada resultado (Documento C §1.7).
const String marigoldHealthDisclaimer =
    'BIO-G organiza observaciones y contexto para orientar la revisión. '
    'No confirma una enfermedad, una plaga, una deficiencia ni un organismo '
    'causal.';

/// Texto canónico sobre productos fitosanitarios (Documento C §1.4). BIO-G no
/// prescribe ingredientes activos, marcas, dosis, mezclas ni intervalos.
const String marigoldPesticideDisclaimer =
    'Si necesitas tratamiento, confirma primero el problema y utiliza '
    'únicamente productos registrados para el cultivo y el uso local, '
    'siguiendo la etiqueta y protegiendo polinizadores.';

/// Ids canónicos de riesgo/síndrome del cempasúchil (Documento C §6, S01–S23).
/// Se conservan idénticos a los ids del catálogo de síndromes. NUNCA se
/// reutiliza un id con prefijo `sunflower_` (§36).
class MarigoldRiskIds {
  const MarigoldRiskIds._();

  // Familia 1 — semilla y plántula.
  static const String poorPatchyEmergence =
      'marigold_poor_patchy_emergence_01';
  static const String seedlingCollapseDampingOff =
      'marigold_seedling_collapse_damping_off_02';

  // Familia 2 — raíz, cuello y estructura.
  static const String rootCollarWilt = 'marigold_root_collar_wilt_03';
  static const String rootGallsStunting = 'marigold_root_galls_stunting_19';
  static const String lodgingStemBreak = 'marigold_lodging_stem_break_22';

  // Familia 3 — follaje y enfermedades foliares.
  static const String darkConcentricLeafBlight =
      'marigold_dark_concentric_leaf_blight_04';
  static const String grayBlackSpotsBlackDots =
      'marigold_gray_black_spots_black_dots_05';
  static const String whitePowderyCoating =
      'marigold_white_powdery_coating_07';
  static const String bronzeSpeckleLowPh = 'marigold_bronze_speckle_low_ph_08';
  static const String uniformChlorosisEdgeBurn =
      'marigold_uniform_chlorosis_edge_burn_09';
  static const String mosaicRingsDistortion =
      'marigold_mosaic_rings_distortion_10';
  static const String greenLeafyFlowersWitchesBroom =
      'marigold_green_leafy_flowers_witches_broom_11';

  // Familia 4 — botón, flor y capítulo.
  static const String grayFuzzyFlowerBlight =
      'marigold_gray_fuzzy_flower_blight_06';
  static const String lushNoBudsElongated =
      'marigold_lush_no_buds_elongated_12';
  static const String budBrowningAbortion =
      'marigold_bud_browning_abortion_13';

  // Familia 5 — plagas e invertebrados.
  static const String silverScarBlackSpecksThrips =
      'marigold_silver_scar_black_specks_thrips_14';
  static const String stickyColoniesHoneydew =
      'marigold_sticky_colonies_honeydew_15';
  static const String stipplingBronzingWebbing =
      'marigold_stippling_bronzing_webbing_16';
  static const String serpentineLeafMines =
      'marigold_serpentine_leaf_mines_17';
  static const String chewedHolesCutSeedlings =
      'marigold_chewed_holes_cut_seedlings_18';

  // Familia 6 — estrés abiótico y final normal del ciclo.
  static const String wiltScorchWaterStress =
      'marigold_wilt_scorch_water_stress_20';
  static const String temperatureSunInjury =
      'marigold_temperature_sun_injury_21';
  static const String normalPostBloomSenescence =
      'marigold_normal_post_bloom_senescence_23';

  static const List<String> all = <String>[
    poorPatchyEmergence,
    seedlingCollapseDampingOff,
    rootCollarWilt,
    darkConcentricLeafBlight,
    grayBlackSpotsBlackDots,
    grayFuzzyFlowerBlight,
    whitePowderyCoating,
    bronzeSpeckleLowPh,
    uniformChlorosisEdgeBurn,
    mosaicRingsDistortion,
    greenLeafyFlowersWitchesBroom,
    lushNoBudsElongated,
    budBrowningAbortion,
    silverScarBlackSpecksThrips,
    stickyColoniesHoneydew,
    stipplingBronzingWebbing,
    serpentineLeafMines,
    chewedHolesCutSeedlings,
    rootGallsStunting,
    wiltScorchWaterStress,
    temperatureSunInjury,
    lodgingStemBreak,
    normalPostBloomSenescence,
  ];
}

/// Mensajes canónicos por familia (Documento C §35). Se usan como texto de
/// apoyo; nunca sustituyen al disclaimer ni afirman una causa.
class MarigoldRiskMessages {
  const MarigoldRiskMessages._();

  static const String dampingOff =
      'Varias plántulas están colapsando en la base. La humedad y la etapa '
      'aumentan el riesgo, pero no identifican la causa. Revisa cuello, '
      'drenaje y progresión.';

  static const String root =
      'La planta se marchita aunque el suelo está húmedo. Revisa firmeza de la '
      'base, olor y raíces antes de volver a regar o fertilizar.';

  static const String leafSpots =
      'Las manchas están aumentando. Fotografía ambas caras de la hoja y evita '
      'mantener el follaje mojado mientras confirmas.';

  static const String grayMold =
      'Hay flores o botones cafés con un crecimiento gris. Es compatible con '
      'moho gris, pero requiere confirmación. Mejora ventilación y evita mojar '
      'las flores.';

  static const String powderyMildew =
      'El material blanco puede ser cenicilla o un residuo. Revisa si se '
      'expande y si vuelve a aparecer.';

  static const String bronzeSpeckle =
      'El patrón bronce y el pH bajo pueden indicar acumulación de hierro o '
      'manganeso. Repite la medición antes de corregir.';

  static const String virus =
      'Los anillos y la deformación forman un patrón sistémico que requiere '
      'descartar virus. La presencia de trips aumenta el contexto, pero no lo '
      'confirma.';

  static const String asterYellows =
      'Las flores verdes o los pétalos con forma de hoja requieren descartar '
      'una alteración sistémica. Evita propagar la planta mientras confirmas.';

  static const String noBuds =
      'La planta sigue creciendo sin formar botones. Revisa fecha, cultivar, '
      'luz, fertilización y posible iluminación nocturna.';

  static const String thrips =
      'Hay raspado plateado y puntos negros compatibles con alimentación de '
      'trips. Confirma el insecto antes de tratar.';

  static const String mites =
      'El punteado y la telaraña son compatibles con ácaros. Revisa el envés '
      'con lupa.';

  static const String nematodes =
      'Las agallas requieren confirmación. Algunas variedades de Tagetes '
      'reducen ciertos nematodos, pero el cultivo no debe considerarse inmune.';

  static const String senescence =
      'El secado es coherente con el cierre anual. Si aparece tejido blando, '
      'olor o colapso rápido, activa una revisión sanitaria.';
}
