import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/npk_caps.dart';
import 'package:bio_g/core/crops/crop_target_models.dart';
import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/barley/barley_catalog.dart';
import 'package:bio_g/core/crops/bean/bean_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/chili/chili_catalog.dart';
import 'package:bio_g/core/crops/cucumber/cucumber_catalog.dart';
import 'package:bio_g/core/crops/eggplant/eggplant_catalog.dart';
import 'package:bio_g/core/crops/garlic/garlic_catalog.dart';
import 'package:bio_g/core/crops/lettuce/lettuce_catalog.dart';
import 'package:bio_g/core/crops/maize/maize_catalog.dart';
import 'package:bio_g/core/crops/oat/oat_catalog.dart';
import 'package:bio_g/core/crops/onion/onion_catalog.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';
import 'package:bio_g/core/crops/cactus/cactus_catalog.dart';
import 'package:bio_g/core/crops/succulent/succulent_catalog.dart';
import 'package:bio_g/core/crops/aloe/aloe_catalog.dart';
import 'package:bio_g/core/crops/agave/agave_catalog.dart';
import 'package:bio_g/core/crops/nopal/nopal_catalog.dart';
import 'package:bio_g/core/crops/rose/rose_catalog.dart';
import 'package:bio_g/core/crops/tulip/tulip_catalog.dart';
import 'package:bio_g/widgets/seeds/tulip_profiles.dart' show kTuSkip;
import 'package:bio_g/core/crops/sunflower/sunflower_catalog.dart';
import 'package:bio_g/widgets/seeds/sunflower_profiles.dart' show kGiSkip;
import 'package:bio_g/core/crops/marigold/marigold_catalog.dart';
import 'package:bio_g/widgets/seeds/marigold_profiles.dart' show kCsSkip;
import 'package:bio_g/core/crops/spinach/spinach_catalog.dart';
import 'package:bio_g/core/crops/squash/squash_catalog.dart';
import 'package:bio_g/core/crops/tomato/tomato_catalog.dart';
import 'package:bio_g/core/crops/wheat/wheat_catalog.dart';
import 'package:bio_g/widgets/seeds/barley_profiles.dart';
import 'package:bio_g/widgets/seeds/bean_profiles.dart';
import 'package:bio_g/widgets/seeds/garlic_profiles.dart';
import 'package:bio_g/widgets/seeds/lettuce_profiles.dart';
import 'package:bio_g/widgets/seeds/oat_profiles.dart';
import 'package:bio_g/widgets/seeds/onion_profiles.dart';
import 'package:bio_g/widgets/seeds/spinach_profiles.dart';
import 'package:bio_g/widgets/seeds/squash_profiles.dart';
import 'package:bio_g/widgets/seeds/wheat_profiles.dart';

class CropCatalog {
  static const String version = 'v1';

  static const String grainCategoryId = 'grain';
  static const String vegetableCategoryId = 'vegetable';
  static const String treeCategoryId = 'tree';
  static const String ornamentalCategoryId = 'ornamental';

  static const String maizeCropId = 'maize';
  static const String wheatCropId = 'wheat';
  static const String barleyCropId = 'barley';
  static const String beanCropId = 'bean';
  static const String oatCropId = 'oat';
  static const String tomatoCropId = 'tomato';
  static const String cucumberCropId = 'cucumber';
  static const String chiliCropId = 'chili';
  static const String eggplantCropId = 'eggplant';
  static const String squashCropId = kCropSquash;
  static const String lettuceCropId = kCropLettuce;
  static const String spinachCropId = kCropSpinach;
  static const String onionCropId = kCropOnion;
  static const String garlicCropId = kCropGarlic;
  static const String appleTreeCropId = kCropAppleTree;
  static const String pearTreeCropId = kCropPearTree;
  static const String peachTreeCropId = kCropPeachTree;
  static const String walnutTreeCropId = kCropWalnutTree;
  static const String pistachioTreeCropId = kCropPistachioTree;
  static const String orangeTreeCropId = kCropOrangeTree;
  static const String lemonTreeCropId = kCropLemonTree;
  static const String mangoTreeCropId = kCropMangoTree;
  static const String avocadoTreeCropId = kCropAvocadoTree;
  static const String cactusCropId = kCropCactus;
  static const String succulentCropId = kCropSucculent;
  static const String aloeCropId = kCropAloe;
  static const String agaveCropId = kCropAgave;
  static const String roseCropId = kCropRose;
  static const String tulipCropId = kCropTulip;
  static const String sunflowerCropId = kCropSunflower;
  static const String marigoldCropId = kCropMarigold;
  static const String nopalCropId = kCropNopal;

  static const String tomatoDefaultProfileId = 'tm_gen';
  static const String tomatoDefaultCalendarId = 'tomato_default';
  static const String cucumberDefaultProfileId = 'pe_gen';
  static const String cucumberDefaultCalendarId = 'cucumber_default';
  static const String chiliDefaultProfileId = 'ch_gen';
  static const String chiliDefaultCalendarId = 'chili_default';
  static const String eggplantDefaultProfileId = 'be_gen';
  static const String eggplantDefaultCalendarId = 'eggplant_default';
  static const String squashDefaultProfileId = kCaGen;
  static const String squashDefaultCalendarId = kSquashDefaultCalendarId;
  static const String lettuceDefaultProfileId = kLeGen;
  static const String lettuceDefaultCalendarId = kLettuceDefaultCalendarId;
  static const String spinachDefaultProfileId = kSpGen;
  static const String spinachDefaultCalendarId = kSpinachDefaultCalendarId;
  static const String onionDefaultProfileId = kOnGen;
  static const String onionDefaultCalendarId = kOnionDefaultCalendarId;
  static const String garlicDefaultProfileId = kAgGen;
  static const String garlicDefaultCalendarId = kGarlicDefaultCalendarId;

  // Manzano (perenne) — perfil general/seguro AP-SKIP. No es fallow.
  static const String appleTreeDefaultProfileId = kApSkip;

  // Pera (perenne) — perfil general/seguro PR-SKIP. No es fallow.
  static const String pearTreeDefaultProfileId = kPrSkip;

  // Durazno (perenne, frutal de hueso) — perfil general/seguro DZ-SKIP. No es fallow.
  static const String peachTreeDefaultProfileId = kDzSkip;

  // Nogal pecanero (perenne, frutal de nuez) — perfil general/seguro NG-SKIP. No es fallow.
  static const String walnutTreeDefaultProfileId = kNgSkip;

  // Pistache (perenne, frutal de nuez, dioico) — perfil general/seguro PS-SKIP. No es fallow.
  static const String pistachioTreeDefaultProfileId = kPsSkip;

  // Naranjo (perenne, cítrico siempreverde) — perfil general/seguro OR-SKIP. No es fallow.
  static const String orangeTreeDefaultProfileId = kOrSkip;

  // Limón (perenne, cítrico siempreverde) — perfil general/seguro LM-SKIP. No es fallow.
  static const String lemonTreeDefaultProfileId = kLmSkip;

  // Mango (perenne, tropical/subtropical siempreverde) — perfil general/seguro
  // MG-SKIP. No es fallow ni promete floración anual.
  static const String mangoTreeDefaultProfileId = kMgSkip;

  // Aguacate (perenne, subtropical/tropical siempreverde) — perfil general/
  // seguro AG-SKIP. No es fallow ni promete floración/cuajado. NO es mango, NO
  // es cítrico, NO es manzano.
  static const String avocadoTreeDefaultProfileId = kAgSkip;

  // Cactus (ornamental, establishment_maintenance) — perfil general/seguro
  // CA-SKIP. No es fallow ni promete floración/cosecha.
  static const String cactusDefaultProfileId = kCaSkip;

  // Suculenta (ornamental, establishment_maintenance) — perfil general/seguro
  // SU-SKIP. No es fallow ni promete floración/cosecha. Comparte el modo del
  // cactus, NO sus targets.
  static const String succulentDefaultProfileId = kSuSkip;

  // Sábila / Aloe (ornamental, establishment_maintenance) — perfil general/seguro
  // SA-SKIP. No es fallow ni promete floración/cosecha. Comparte el modo del
  // cactus y la suculenta, NO sus targets (banda hídrica más húmeda, tolera más
  // sal, responde a N).
  static const String aloeDefaultProfileId = kSaSkip;

  // Maguey / Agave (ornamental, establishment_maintenance) — perfil general/
  // seguro MG-SKIP. No es fallow ni promete floración/cosecha ni jima. Comparte
  // el modo del cactus, la suculenta y la sábila, NO sus targets (banda hídrica
  // baja-moderada, tolera banda pH más alcalina, responde a N en crecimiento).
  static const String agaveDefaultProfileId = kAgaveSkip;

  // Rosal (ornamental, recurring_bloom) — perfil general/seguro RO-SKIP. NO es
  // fallow ni promete cosecha; su ciclo es de floración recurrente confirmada
  // visualmente. Comparte categoría ornamental, NO el modo ni la biología de las
  // ornamentales de establecimiento.
  static const String roseDefaultProfileId = kRoSkip;

  // Tulipán (ornamental, seasonal_bulb) — perfil general/seguro TU-SKIP. NO es
  // fallow ni promete cosecha ni rendimiento. Su ciclo es un RELOJ ANUAL tipo
  // granos que termina en dormancia (el registro sobrevive y puede iniciar otra
  // temporada). Comparte categoría ornamental, NO el modo ni la biología de las
  // ornamentales de establecimiento ni del rosal.
  static const String tulipDefaultProfileId = kTuSkip;

  // Girasol (ornamental, annual_ornamental) — perfil general/seguro gi_skip. NO
  // es fallow ni promete cosecha ni rendimiento. Su ciclo es un RELOJ ANUAL tipo
  // granos que termina en cycle_complete TERMINAL: la planta cierra su ciclo y
  // una nueva temporada exige una nueva siembra. Comparte categoría ornamental,
  // NO el modo ni la biología de las ornamentales de establecimiento, del rosal
  // ni del tulipán.
  static const String sunflowerDefaultProfileId = kGiSkip;

  // Cempasúchil (ornamental, annual_ornamental) — perfil general/seguro
  // cs_skip. Segunda ornamental ANUAL VERDADERA, con el mismo MODO que el
  // Girasol pero biología PROPIA: calendarios, targets, caps NPK, textos,
  // assets y sanidad distintos. NO promete cosecha, rendimiento, manojos,
  // tallos ni floración garantizada para una fecha cultural. Su ciclo termina
  // en cycle_complete TERMINAL: una nueva temporada exige una nueva siembra.
  static const String marigoldDefaultProfileId = kCsSkip;

  // Nopal (ornamental, establishment_maintenance) - perfil general/seguro
  // NO-SKIP. Quinta ornamental del modo de establecimiento. NO promete
  // rendimiento, cosecha, nopalito, tuna ni comestibilidad: el usuario decide
  // cuando cortar una penca o retirar una tuna, y eso no cambia la etapa.
  // Comparte el modo de cactus, suculenta, sabila y maguey, NO sus targets
  // (banda hidrica mas amplia en crecimiento, N mejor documentado que cactus).
  static const String nopalDefaultProfileId = kNopalSkip;

  // ── Maize catalog constants ─────────────────────────────────────────────────
  static const String maizeDemoVarietyId = 'dk_2069';
  static const String maizeGenericVarietyId = 'generic_maize';
  static const String maizeDefaultProfileId = 'mzg_gen_b';
  static const String maizeGenericProfileId = 'maize_generic';

  static const String maizeDefaultCalendarId = 'maize_default';
  static const String beanDefaultCalendarId = kBeanDefaultCalendarId;
  static const String oatDefaultCalendarId = kOatDefaultCalendarId;
  static const String barleyDefaultCalendarId = kBarleyDefaultCalendarId;
  static const String wheatDefaultCalendarId = kWheatDefaultCalendarId;

  // ── Categories ──────────────────────────────────────────────────────────────

  static const List<CropCategoryEntry> categories = <CropCategoryEntry>[
    CropCategoryEntry(
      id: grainCategoryId,
      label: 'Grano',
      subtitle: 'Cereales y leguminosas de ciclo agrícola',
      enabled: true,
    ),
    CropCategoryEntry(
      id: vegetableCategoryId,
      label: 'Hortalizas',
      subtitle: 'Cultivos hortícolas en suelo (campo abierto y protegido)',
      enabled: true,
    ),
    // Categoría Árbol (perennes/frutales). Habilitada: el runtime perenne, el
    // wizard y el onboarding ya soportan árboles. La condición "es perenne" se
    // deriva de esta categoría (tree), no se persiste.
    CropCategoryEntry(
      id: treeCategoryId,
      label: 'Árboles',
      subtitle: 'Frutales y perennes',
      enabled: true,
    ),
    // Categoría Ornamental habilitada: Cactus y Suculenta. El runtime ornamental
    // (establishment_maintenance), el wizard y el onboarding ya las soportan.
    // Otras ornamentales (sábila, maguey, rosal…) permanecen "Próximamente".
    CropCategoryEntry(
      id: ornamentalCategoryId,
      label: 'Planta ornamental',
      subtitle:
          'Cactus, suculentas, sábila, maguey, nopal, rosal, tulipán, '
          'girasol y cempasúchil',
      enabled: true,
    ),
  ];

  // ── Crops ───────────────────────────────────────────────────────────────────

  static const List<CropCatalogEntry> crops = <CropCatalogEntry>[
    CropCatalogEntry(
      cropId: maizeCropId,
      categoryId: grainCategoryId,
      label: 'Maíz',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: maizeDefaultProfileId,
      defaultCalendarId: maizeDefaultCalendarId,
      brands: maizeBrands,
      varieties: maizeVarieties,
      profiles: maizeProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: maizeDefaultCalendarId,
          label: 'Calendario base',
          cropId: maizeCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'maize_temporal',
          label: 'Temporal',
          cropId: maizeCropId,
          subtitle: 'Ajusta humedad y fenología para lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'maize_riego',
          label: 'Riego',
          cropId: maizeCropId,
          subtitle: 'Mayor potencial y ajuste nutricional',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: wheatCropId,
      categoryId: grainCategoryId,
      label: 'Trigo',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kTrGen,
      defaultCalendarId: wheatDefaultCalendarId,
      varieties: wheatVarieties,
      profiles: wheatProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: wheatDefaultCalendarId,
          label: 'Calendario base',
          cropId: wheatCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'wheat_temporal',
          label: 'Temporal',
          cropId: wheatCropId,
          subtitle: 'Ajusta targets para secano / lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'wheat_riego',
          label: 'Riego',
          cropId: wheatCropId,
          subtitle: 'Escenario de mayor potencial',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: barleyCropId,
      categoryId: grainCategoryId,
      label: 'Cebada',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kCbGen,
      defaultCalendarId: barleyDefaultCalendarId,
      varieties: barleyVarieties,
      profiles: barleyProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: barleyDefaultCalendarId,
          label: 'Calendario base',
          cropId: barleyCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'barley_temporal',
          label: 'Temporal',
          cropId: barleyCropId,
          subtitle: 'Ajusta targets para secano / lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'barley_riego',
          label: 'Riego',
          cropId: barleyCropId,
          subtitle: 'Escenario de mayor potencial',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: oatCropId,
      categoryId: grainCategoryId,
      label: 'Avena',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kAvGen,
      defaultCalendarId: oatDefaultCalendarId,
      brands: oatBrands,
      varieties: oatVarieties,
      profiles: oatProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: oatDefaultCalendarId,
          label: 'Calendario base',
          cropId: oatCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'oat_temporal',
          label: 'Temporal',
          cropId: oatCropId,
          subtitle: 'Ajusta targets para secano / lluvia',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'oat_riego',
          label: 'Riego',
          cropId: oatCropId,
          subtitle: 'Escenario de mayor potencial',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: beanCropId,
      categoryId: grainCategoryId,
      label: 'Frijol',
      subtitle: 'Disponible ahora',
      enabled: true,
      defaultProfileId: kFjGen,
      defaultCalendarId: beanDefaultCalendarId,
      varieties: beanVarieties,
      profiles: beanProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: beanDefaultCalendarId,
          label: 'Calendario base',
          cropId: beanCropId,
          subtitle: 'Ciclo general de referencia',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'bean_temporal',
          label: 'Temporal',
          cropId: beanCropId,
          subtitle: 'Ajusta targets para lluvia y menor disponibilidad',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'bean_riego',
          label: 'Riego',
          cropId: beanCropId,
          subtitle: 'Escenario de mayor estabilidad hídrica',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: tomatoCropId,
      categoryId: vegetableCategoryId,
      label: 'Tomate',
      subtitle: 'Hortaliza · campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: tomatoDefaultProfileId,
      defaultCalendarId: tomatoDefaultCalendarId,
      varieties: tomatoVarieties,
      profiles: tomatoProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: tomatoDefaultCalendarId,
          label: 'Calendario base',
          cropId: tomatoCropId,
          subtitle: 'Ciclo general anclado al trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'tomato_campo_abierto',
          label: 'Campo abierto',
          cropId: tomatoCropId,
          subtitle: 'Ciclo exterior con mayor sensibilidad ambiental',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'tomato_protegido',
          label: 'Protegido en suelo',
          cropId: tomatoCropId,
          subtitle: 'Invernadero o malla; ciclo productivo extendido',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: cucumberCropId,
      categoryId: vegetableCategoryId,
      label: 'Pepino',
      subtitle: 'Hortaliza · campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: cucumberDefaultProfileId,
      defaultCalendarId: cucumberDefaultCalendarId,
      varieties: cucumberVarieties,
      profiles: cucumberProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: cucumberDefaultCalendarId,
          label: 'Calendario base',
          cropId: cucumberCropId,
          subtitle: 'Ciclo general anclado a siembra o trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'cucumber_campo_abierto',
          label: 'Campo abierto',
          cropId: cucumberCropId,
          subtitle: 'Mayor exposición climática y presión de vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'cucumber_protegido',
          label: 'Protegido en suelo',
          cropId: cucumberCropId,
          subtitle: 'Malla o invernadero en suelo; más humedad y continuidad',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: chiliCropId,
      categoryId: vegetableCategoryId,
      label: 'Chile',
      subtitle: 'Hortaliza - campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: chiliDefaultProfileId,
      defaultCalendarId: chiliDefaultCalendarId,
      varieties: chiliVarieties,
      profiles: chiliProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: chiliDefaultCalendarId,
          label: 'Calendario base',
          cropId: chiliCropId,
          subtitle: 'Ciclo general anclado a siembra o trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'chili_campo_abierto',
          label: 'Campo abierto',
          cropId: chiliCropId,
          subtitle: 'Mayor exposicion a calor, frio y vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'chili_protegido',
          label: 'Protegido en suelo',
          cropId: chiliCropId,
          subtitle: 'Malla o invernadero en suelo; mas humedad y continuidad',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: eggplantCropId,
      categoryId: vegetableCategoryId,
      label: 'Berenjena',
      subtitle: 'Hortaliza - campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: eggplantDefaultProfileId,
      defaultCalendarId: eggplantDefaultCalendarId,
      varieties: eggplantVarieties,
      profiles: eggplantProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: eggplantDefaultCalendarId,
          label: 'Calendario base',
          cropId: eggplantCropId,
          subtitle: 'Ciclo general anclado a siembra o trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'eggplant_campo_abierto',
          label: 'Campo abierto',
          cropId: eggplantCropId,
          subtitle: 'Mayor exposicion a calor, frio y vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'eggplant_protegido',
          label: 'Protegido en suelo',
          cropId: eggplantCropId,
          subtitle: 'Malla o invernadero en suelo; mas humedad y continuidad',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: squashCropId,
      categoryId: vegetableCategoryId,
      label: 'Calabaza',
      subtitle: 'Hortaliza - campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: squashDefaultProfileId,
      defaultCalendarId: squashDefaultCalendarId,
      varieties: squashVarieties,
      profiles: squashProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: squashDefaultCalendarId,
          label: 'Calendario base',
          cropId: squashCropId,
          subtitle: 'Ciclo general anclado a siembra o trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'squash_campo_abierto',
          label: 'Campo abierto',
          cropId: squashCropId,
          subtitle: 'Mayor exposicion a calor, lluvia y vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'squash_protegido',
          label: 'Protegido en suelo',
          cropId: squashCropId,
          subtitle: 'Malla o invernadero en suelo; sin hidroponia v1',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'squash_temporal',
          label: 'Temporal / milpa',
          cropId: squashCropId,
          subtitle: 'Ajusta humedad y ritmo para lluvia o sistema mixto',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'squash_riego',
          label: 'Riego',
          cropId: squashCropId,
          subtitle: 'Mayor estabilidad hidrica en suelo',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: lettuceCropId,
      categoryId: vegetableCategoryId,
      label: 'Lechuga',
      subtitle: 'Hortaliza de hoja - campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: lettuceDefaultProfileId,
      defaultCalendarId: lettuceDefaultCalendarId,
      varieties: lettuceVarieties,
      profiles: lettuceProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: lettuceDefaultCalendarId,
          label: 'Calendario base',
          cropId: lettuceCropId,
          subtitle: 'Ciclo general anclado a siembra o trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'lettuce_campo_abierto',
          label: 'Campo abierto',
          cropId: lettuceCropId,
          subtitle: 'Mayor exposicion a calor, viento y vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'lettuce_protegido',
          label: 'Protegido en suelo',
          cropId: lettuceCropId,
          subtitle: 'Malla o invernadero en suelo; sin hidroponia v1',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'lettuce_riego',
          label: 'Riego',
          cropId: lettuceCropId,
          subtitle: 'Mayor estabilidad hidrica en suelo',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: spinachCropId,
      categoryId: vegetableCategoryId,
      label: 'Espinaca',
      subtitle: 'Hortaliza de hoja - campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: spinachDefaultProfileId,
      defaultCalendarId: spinachDefaultCalendarId,
      varieties: spinachVarieties,
      profiles: spinachProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: spinachDefaultCalendarId,
          label: 'Calendario base',
          cropId: spinachCropId,
          subtitle: 'Ciclo general anclado a siembra o trasplante',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'spinach_campo_abierto',
          label: 'Campo abierto',
          cropId: spinachCropId,
          subtitle: 'Mayor exposicion a calor, viento y vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'spinach_protegido',
          label: 'Protegido en suelo',
          cropId: spinachCropId,
          subtitle: 'Malla o invernadero en suelo; sin hidroponia v1',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'spinach_riego',
          label: 'Riego',
          cropId: spinachCropId,
          subtitle: 'Mayor estabilidad hidrica en suelo',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: onionCropId,
      categoryId: vegetableCategoryId,
      label: 'Cebolla',
      subtitle: 'Hortaliza de bulbo - campo abierto y protegido en suelo',
      enabled: true,
      defaultProfileId: onionDefaultProfileId,
      defaultCalendarId: onionDefaultCalendarId,
      varieties: onionVarieties,
      profiles: onionProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: onionDefaultCalendarId,
          label: 'Calendario base',
          cropId: onionCropId,
          subtitle: 'Ciclo general anclado a siembra, trasplante o set',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'onion_campo_abierto',
          label: 'Campo abierto',
          cropId: onionCropId,
          subtitle: 'Mayor exposicion a calor, frio, fotoperiodo y vectores',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'onion_protegido',
          label: 'Protegido en suelo',
          cropId: onionCropId,
          subtitle: 'Malla o invernadero en suelo; sin hidroponia v1',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'onion_riego',
          label: 'Riego',
          cropId: onionCropId,
          subtitle: 'Goteo o gravedad; mayor estabilidad hidrica en suelo',
          enabled: true,
        ),
      ],
    ),
    CropCatalogEntry(
      cropId: garlicCropId,
      categoryId: vegetableCategoryId,
      label: 'Ajo',
      subtitle: 'Hortaliza de bulbo - campo abierto en suelo',
      enabled: true,
      defaultProfileId: garlicDefaultProfileId,
      defaultCalendarId: garlicDefaultCalendarId,
      varieties: garlicVarieties,
      profiles: garlicProfileEntries,
      calendars: <CropCalendarEntry>[
        CropCalendarEntry(
          id: garlicDefaultCalendarId,
          label: 'Calendario base',
          cropId: garlicCropId,
          subtitle: 'Ciclo general anclado a plantacion del diente',
          enabled: true,
          isDefault: true,
        ),
        CropCalendarEntry(
          id: 'garlic_campo_abierto',
          label: 'Campo abierto',
          cropId: garlicCropId,
          subtitle: 'Mayor exposicion a frio, calor, salinidad y sanidad',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'garlic_riego',
          label: 'Riego',
          cropId: garlicCropId,
          subtitle: 'Goteo o gravedad; mayor estabilidad hidrica en suelo',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'garlic_bajo_insumo',
          label: 'Bajo insumo',
          cropId: garlicCropId,
          subtitle:
              'Referencia conservadora por semilla, agua o manejo limitado',
          enabled: true,
        ),
        CropCalendarEntry(
          id: 'garlic_temporal',
          label: 'Temporal / secano',
          cropId: garlicCropId,
          subtitle: 'Mayor riesgo por frio, humedad, calibre y sanidad',
          enabled: true,
        ),
      ],
    ),
    // ── Árboles / perennes ────────────────────────────────────────────────────
    // Manzano habilitado: primer árbol real. Sin calendarios: los árboles no
    // usan fecha de siembra ni ciclo anual que termina; el anclaje perenne vive
    // en DeviceCropContext.perennialAnchorDate/perennialAnchorTypeId. El paquete
    // agronómico (targets/fertilización/sanidad) llega en la siguiente fase.
    CropCatalogEntry(
      cropId: appleTreeCropId,
      categoryId: treeCategoryId,
      label: 'Manzano',
      subtitle: 'Malus domestica · árbol frutal perenne',
      enabled: true,
      defaultProfileId: appleTreeDefaultProfileId,
      profiles: appleTreeProfileEntries,
    ),
    // Pera habilitada: segundo árbol real. Sin calendarios: los árboles no usan
    // fecha de siembra; el anclaje perenne vive en DeviceCropContext.
    CropCatalogEntry(
      cropId: pearTreeCropId,
      categoryId: treeCategoryId,
      label: 'Pera',
      subtitle: 'Pyrus communis · árbol frutal perenne',
      enabled: true,
      defaultProfileId: pearTreeDefaultProfileId,
      profiles: pearTreeProfileEntries,
    ),
    // Durazno habilitado: tercer árbol real y primer frutal de hueso/carozo.
    // Sin calendarios: los árboles no usan fecha de siembra; el anclaje perenne
    // vive en DeviceCropContext.
    CropCatalogEntry(
      cropId: peachTreeCropId,
      categoryId: treeCategoryId,
      label: 'Durazno',
      subtitle: 'Prunus persica · árbol frutal perenne (hueso/carozo)',
      enabled: true,
      defaultProfileId: peachTreeDefaultProfileId,
      profiles: peachTreeProfileEntries,
    ),
    // Nogal pecanero habilitado: cuarto árbol real y primer frutal de nuez. Sin
    // calendarios: los árboles no usan fecha de siembra; el anclaje perenne vive
    // en DeviceCropContext.
    CropCatalogEntry(
      cropId: walnutTreeCropId,
      categoryId: treeCategoryId,
      label: 'Nogal',
      subtitle: 'Carya illinoinensis · árbol frutal perenne (nuez pecana)',
      enabled: true,
      defaultProfileId: walnutTreeDefaultProfileId,
      profiles: walnutTreeProfileEntries,
    ),
    // Pistache habilitado: quinto árbol real y segundo frutal de nuez (dioico).
    // Sin calendarios: los árboles no usan fecha de siembra; el anclaje perenne
    // vive en DeviceCropContext.
    CropCatalogEntry(
      cropId: pistachioTreeCropId,
      categoryId: treeCategoryId,
      label: 'Pistache',
      subtitle: 'Pistacia vera · árbol frutal perenne (nuez, dioico)',
      enabled: true,
      defaultProfileId: pistachioTreeDefaultProfileId,
      profiles: pistachioTreeProfileEntries,
    ),
    // Naranjo habilitado: sexto árbol real y primer cítrico siempreverde. Sin
    // calendarios: los árboles no usan fecha de siembra; el anclaje perenne vive
    // en DeviceCropContext. `dormancy` es reposo relativo, no árbol pelón.
    CropCatalogEntry(
      cropId: orangeTreeCropId,
      categoryId: treeCategoryId,
      label: 'Naranjo',
      subtitle: 'Citrus sinensis · árbol frutal perenne (cítrico siempreverde)',
      enabled: true,
      defaultProfileId: orangeTreeDefaultProfileId,
      profiles: orangeTreeProfileEntries,
    ),
    // Limón habilitado: séptimo árbol real y segundo cítrico siempreverde. NO es
    // un naranjo pequeño: cropId propio, K más alto y producción frecuente/
    // escalonada. Sin calendarios: los árboles no usan fecha de siembra; el
    // anclaje perenne vive en DeviceCropContext. `dormancy` es reposo relativo.
    CropCatalogEntry(
      cropId: lemonTreeCropId,
      categoryId: treeCategoryId,
      label: 'Limón',
      subtitle:
          'Citrus (limón/lima) · árbol frutal perenne (cítrico siempreverde)',
      enabled: true,
      defaultProfileId: lemonTreeDefaultProfileId,
      profiles: lemonTreeProfileEntries,
    ),
    // Mango habilitado: octavo árbol real y primer frutal tropical episódico. NO
    // es limón, NO es naranjo, NO es manzano: cropId propio, floración NO
    // garantizada cada año (la no floración es estado válido) y fisiología
    // propia (inducción, panícula, cuajado frágil, alternancia). Sin
    // calendarios: los árboles no usan fecha de siembra; el anclaje perenne vive
    // en DeviceCropContext. `dormancy` es reposo funcional, no árbol pelón.
    CropCatalogEntry(
      cropId: mangoTreeCropId,
      categoryId: treeCategoryId,
      label: 'Mango',
      subtitle:
          'Mangifera indica · árbol frutal perenne (tropical/subtropical)',
      enabled: true,
      defaultProfileId: mangoTreeDefaultProfileId,
      profiles: mangoTreeProfileEntries,
    ),
    // Aguacate habilitado: noveno árbol real. NO es mango, NO es cítrico, NO es
    // manzano ni cultivo anual: cropId propio, floración A/B y cuajado FRÁGIL
    // (menos de 1% de flor llega a fruto), raíz superficial muy sensible a
    // asfixia/salinidad/Phytophthora, alternancia marcada y fruta que madura
    // DESPUÉS del corte. Sin calendarios: los árboles no usan fecha de siembra;
    // el anclaje perenne vive en DeviceCropContext. `dormancy` es reposo
    // funcional (siempreverde), no árbol pelón.
    CropCatalogEntry(
      cropId: avocadoTreeCropId,
      categoryId: treeCategoryId,
      label: 'Aguacate',
      subtitle:
          'Persea americana · árbol frutal perenne (subtropical/tropical)',
      enabled: true,
      defaultProfileId: avocadoTreeDefaultProfileId,
      profiles: avocadoTreeProfileEntries,
    ),
    // ── Ornamentales ─────────────────────────────────────────────────────────
    // Cactus habilitado: primera ornamental oficial. Sin calendarios: el cactus
    // no usa fecha de siembra ni ciclo anual que termina; el anclaje ornamental
    // (plantación / cambio de maceta) vive en los campos ornamentales de
    // DeviceCropContext, separado del estado fenológico de los árboles. NO
    // tiene rendimiento ni cosecha.
    CropCatalogEntry(
      cropId: cactusCropId,
      categoryId: ornamentalCategoryId,
      label: 'Cactus',
      subtitle: 'Planta ornamental xerófita · establecimiento y mantenimiento',
      enabled: true,
      defaultProfileId: cactusDefaultProfileId,
      profiles: cactusProfileEntries,
    ),
    // Suculenta: segunda ornamental oficial. Mismo modo de ciclo que el cactus
    // (establecimiento → mantenimiento abierto), biología PROPIA: usa una banda
    // hídrica algo mayor, no tolera helada por defecto y su NPK pesa más en
    // crecimiento. Sin rendimiento y sin cosecha.
    CropCatalogEntry(
      cropId: succulentCropId,
      categoryId: ornamentalCategoryId,
      label: 'Suculenta',
      subtitle:
          'Planta ornamental de hojas o tallos carnosos · establecimiento y '
          'mantenimiento',
      enabled: true,
      defaultProfileId: succulentDefaultProfileId,
      profiles: succulentProfileEntries,
    ),
    // Sábila / Aloe: tercera ornamental oficial. Mismo modo de ciclo que cactus
    // y suculenta (establecimiento → mantenimiento abierto), biología PROPIA:
    // banda hídrica ~2 puntos más húmeda, tolera mucha más sal, es indiferente
    // al pH y su NPK pesa más en crecimiento. Sin rendimiento y sin cosecha
    // (cortar hojas para gel es un evento, no cosecha).
    CropCatalogEntry(
      cropId: aloeCropId,
      categoryId: ornamentalCategoryId,
      label: 'Sábila',
      subtitle:
          'Planta ornamental de hojas carnosas con gel · establecimiento y '
          'mantenimiento',
      enabled: true,
      defaultProfileId: aloeDefaultProfileId,
      profiles: aloeProfileEntries,
    ),
    // Maguey / Agave: cuarta ornamental oficial. Mismo modo de ciclo que cactus,
    // suculenta y sábila (establecimiento → mantenimiento abierto), biología
    // PROPIA: banda hídrica baja-moderada, tolera una banda pH más alcalina,
    // responde a N en crecimiento y conserva K como cap más alto. Sin
    // rendimiento y sin cosecha; "Maduro" es estabilidad ornamental, no jima.
    CropCatalogEntry(
      cropId: agaveCropId,
      categoryId: ornamentalCategoryId,
      label: 'Maguey',
      subtitle:
          'Planta ornamental de roseta perenne (maguey / agave) · '
          'establecimiento y mantenimiento',
      enabled: true,
      defaultProfileId: agaveDefaultProfileId,
      profiles: agaveProfileEntries,
    ),
    // Rosal: primera ornamental de FLORACIÓN RECURRENTE. Modo de ciclo propio
    // (recurring_bloom), NO establecimiento/mantenimiento: tras arraigar entra
    // en un ciclo brote → botón → floración → post-floración → reposo que el
    // usuario confirma visualmente. Sin cosecha, sin rendimiento, sin etapa
    // final.
    CropCatalogEntry(
      cropId: roseCropId,
      categoryId: ornamentalCategoryId,
      label: 'Rosal',
      subtitle:
          'Arbusto ornamental de flor · floración recurrente (brote, botón, '
          'floración, reposo)',
      enabled: true,
      defaultProfileId: roseDefaultProfileId,
      profiles: roseProfileEntries,
    ),
    // Tulipán: primera ornamental BULBOSA ESTACIONAL. Modo de ciclo propio
    // (seasonal_bulb): reloj anual tipo granos (fecha ancla → día → etapa) que
    // termina en DORMANCIA, no en cosecha. El registro sobrevive al cierre y
    // puede iniciar otra temporada. Sin rendimiento. NO comparte el modo ni la
    // biología de las ornamentales de establecimiento ni del rosal.
    CropCatalogEntry(
      cropId: tulipCropId,
      categoryId: ornamentalCategoryId,
      label: 'Tulipán',
      subtitle:
          'Bulbo ornamental de flor · temporada anual (plantación, floración, '
          'recarga, reposo)',
      enabled: true,
      defaultProfileId: tulipDefaultProfileId,
      profiles: tulipProfileEntries,
    ),
    // Girasol: primera ornamental ANUAL VERDADERA. Modo de ciclo propio
    // (annual_ornamental): reloj anual tipo granos (fecha ancla → día → etapa)
    // que termina en cycle_complete TERMINAL, no en dormancia ni cosecha. Una
    // nueva temporada exige una nueva siembra. Sin rendimiento. NO comparte el
    // modo ni la biología de las ornamentales de establecimiento, el rosal ni el
    // tulipán.
    CropCatalogEntry(
      cropId: sunflowerCropId,
      categoryId: ornamentalCategoryId,
      label: 'Girasol',
      subtitle:
          'Flor ornamental anual · temporada única (siembra, tallo, botón, '
          'floración, fin de ciclo)',
      enabled: true,
      defaultProfileId: sunflowerDefaultProfileId,
      profiles: sunflowerProfileEntries,
    ),
    // Cempasúchil: segunda ornamental ANUAL VERDADERA (Tagetes erecta L.).
    // Comparte el MODO del Girasol (annual_ornamental: reloj anual tipo granos
    // que termina en cycle_complete TERMINAL) pero NO su biología: calendarios,
    // targets, caps NPK, textos, assets y sanidad son propios. Sin rendimiento,
    // sin cosecha y sin programación automática para el 1 y 2 de noviembre: la
    // fecha cultural nunca cambia la etapa.
    CropCatalogEntry(
      cropId: marigoldCropId,
      categoryId: ornamentalCategoryId,
      label: 'Cempasúchil',
      subtitle:
          'Flor ornamental anual · temporada única (siembra, ramificación, '
          'botón, floración, fin de ciclo)',
      enabled: true,
      defaultProfileId: marigoldDefaultProfileId,
      profiles: marigoldProfileEntries,
    ),
    // Nopal: quinta ornamental de establecimiento y mantenimiento. Mismo modo
    // que cactus, suculenta, sabila y maguey (establecimiento -> mantenimiento
    // abierto), biologia PROPIA: banda hidrica mas amplia en crecimiento (la
    // emision de pencas usa mas agua), respuesta a N mejor documentada que el
    // cactus y K con el cap mas alto. Sin rendimiento y sin cosecha: cortar una
    // penca o retirar una tuna lo decide el usuario y no cambia la etapa.
    CropCatalogEntry(
      cropId: nopalCropId,
      categoryId: ornamentalCategoryId,
      label: 'Nopal',
      subtitle:
          'Planta ornamental de pencas planas (Opuntia) - establecimiento y '
          'mantenimiento',
      enabled: true,
      defaultProfileId: nopalDefaultProfileId,
      profiles: nopalProfileEntries,
    ),
  ];

  static CropCategoryEntry? categoryById(String? categoryId) {
    final normalized = _normalize(categoryId);
    if (normalized == null) return null;

    for (final category in categories) {
      if (_normalize(category.id) == normalized) return category;
    }
    return null;
  }

  static CropCatalogEntry? cropById(String? cropId) {
    // Canonicaliza primero: así los ids legacy/alias (p. ej. `apple_tree`,
    // `manzano`, `corn`) resuelven a su entrada oficial sin duplicar cultivos.
    final normalized = canonicalCropKey(cropId);
    if (normalized.isEmpty) return null;

    for (final crop in crops) {
      if (_normalize(crop.cropId) == normalized) return crop;
    }
    return null;
  }

  static List<CropCatalogEntry> cropsByCategory(
    String categoryId, {
    bool enabledOnly = false,
  }) {
    final normalized = _normalize(categoryId);
    if (normalized == null) return const <CropCatalogEntry>[];

    return crops
        .where((crop) {
          final matchesCategory = _normalize(crop.categoryId) == normalized;
          if (!matchesCategory) return false;
          if (enabledOnly && !crop.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static List<CropVarietyEntry> varietiesForCrop(
    String cropId, {
    bool enabledOnly = false,
  }) {
    final crop = cropById(cropId);
    if (crop == null) return const <CropVarietyEntry>[];

    return crop.varieties
        .where((variety) {
          if (enabledOnly && !variety.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static List<CropProfileEntry> profilesForCrop(
    String cropId, {
    bool enabledOnly = false,
  }) {
    final crop = cropById(cropId);
    if (crop == null) return const <CropProfileEntry>[];

    return crop.profiles
        .where((profile) {
          if (enabledOnly && !profile.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static List<CropCalendarEntry> calendarsForCrop(
    String cropId, {
    bool enabledOnly = false,
  }) {
    final crop = cropById(cropId);
    if (crop == null) return const <CropCalendarEntry>[];

    return crop.calendars
        .where((calendar) {
          if (enabledOnly && !calendar.enabled) return false;
          return true;
        })
        .toList(growable: false);
  }

  static CropVarietyEntry? varietyById(String cropId, String? varietyId) {
    final normalizedVarietyId = _normalize(varietyId);
    if (normalizedVarietyId == null) return null;

    if (_normalize(cropId) == maizeCropId) {
      final direct = maizeVarietyById(varietyId!);
      if (direct != null) return direct;
    }

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final variety in crop.varieties) {
      if (_normalize(variety.id) == normalizedVarietyId) return variety;
    }
    return null;
  }

  static CropVarietyEntry? varietyByAlias(String cropId, String? alias) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias == null) return null;

    if (_normalize(cropId) == maizeCropId) {
      final byAlias = maizeVarietyByAlias(alias!);
      if (byAlias != null) return byAlias;
    }

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final variety in crop.varieties) {
      if (_normalize(variety.label) == normalizedAlias) return variety;

      for (final candidate in variety.aliases) {
        if (_normalize(candidate) == normalizedAlias) {
          return variety;
        }
      }
    }

    return null;
  }

  static CropVarietyEntry? varietyByAny(String cropId, String? value) {
    return varietyById(cropId, value) ?? varietyByAlias(cropId, value);
  }

  static CropProfileEntry? profileById(String cropId, String? profileId) {
    final normalizedProfileId = _normalize(profileId);
    if (normalizedProfileId == null) return null;

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final profile in crop.profiles) {
      if (_normalize(profile.id) == normalizedProfileId) return profile;
    }
    return null;
  }

  static CropProfileEntry? profileByAlias(String cropId, String? alias) {
    final normalizedAlias = _normalize(alias);
    if (normalizedAlias == null) return null;

    final crop = cropById(cropId);
    if (crop == null) return null;

    for (final profile in crop.profiles) {
      if (_normalize(profile.label) == normalizedAlias) return profile;

      for (final candidate in profile.aliases) {
        if (_normalize(candidate) == normalizedAlias) {
          return profile;
        }
      }
    }

    return null;
  }

  static CropProfileEntry? profileByAny(String cropId, String? value) {
    return profileById(cropId, value) ?? profileByAlias(cropId, value);
  }

  static String? resolveVarietyId({required String cropId, String? rawValue}) {
    return varietyByAny(cropId, rawValue)?.id;
  }

  static String? defaultCalendarIdForCrop(String cropId) {
    final crop = cropById(cropId);
    if (crop == null) return null;

    final explicitDefault = crop.defaultCalendarId;
    if (explicitDefault != null && explicitDefault.trim().isNotEmpty) {
      return explicitDefault;
    }

    for (final calendar in crop.calendars) {
      if (calendar.isDefault) return calendar.id;
    }

    if (crop.calendars.isNotEmpty) {
      return crop.calendars.first.id;
    }

    return null;
  }

  static String resolveProfileId({
    required String cropId,
    String? varietyId,
    String? explicitProfileId,
  }) {
    final crop = cropById(cropId);

    final explicitProfile = profileByAny(cropId, explicitProfileId);
    if (explicitProfile != null) {
      return explicitProfile.id;
    }

    final variety = varietyByAny(cropId, varietyId);
    final varietyDefaultProfileId = variety?.defaultProfileId;
    if (varietyDefaultProfileId != null &&
        profileById(cropId, varietyDefaultProfileId) != null) {
      return varietyDefaultProfileId;
    }

    final cropDefaultProfileId = crop?.defaultProfileId;
    if (cropDefaultProfileId != null &&
        profileById(cropId, cropDefaultProfileId) != null) {
      return cropDefaultProfileId;
    }

    final genericProfileId = '${cropId}_generic';
    if (profileById(cropId, genericProfileId) != null) {
      return genericProfileId;
    }

    if (crop != null && crop.profiles.isNotEmpty) {
      return crop.profiles.first.id;
    }

    return genericProfileId;
  }

  static List<CropBrandEntry> brandsForCrop(String cropId) {
    final crop = cropById(cropId);
    return crop?.brands ?? const <CropBrandEntry>[];
  }

  static List<CropVarietyEntry> maizeVarietiesForBrand(
    String brandId, {
    String? marketTypeId,
  }) {
    if (marketTypeId != null) {
      return maizeVarietiesByBrandAndMarket(brandId, marketTypeId);
    }
    return maizeVarietiesByBrand(brandId);
  }

  static String? resolveCalendarId({
    required String cropId,
    String? requested,
    String? previousCalendarId,
  }) {
    final canonicalCropId = canonicalCropKey(cropId);
    if (canonicalCropId.isEmpty) return null;

    final requestedId = _canonicalCalendarId(
      cropId: canonicalCropId,
      raw: requested,
    );
    if (requestedId != null) return requestedId;

    final previousId = _canonicalCalendarId(
      cropId: canonicalCropId,
      raw: previousCalendarId,
    );
    if (previousId != null) return previousId;

    return defaultCalendarIdForCrop(canonicalCropId);
  }

  static int phenologyOffsetDaysForCalendar({
    required String cropId,
    String? calendarId,
  }) {
    final canonical = _canonicalCalendarId(cropId: cropId, raw: calendarId);
    if (canonical == null) return 0;

    if (canonical.endsWith('_temporal')) return -4;
    if (canonical.endsWith('_riego')) return 4;
    return 0;
  }

  static StageTargets adjustTargetsForCalendar({
    required String cropId,
    required String? calendarId,
    required String stageKey,
    required StageTargets baseTargets,
  }) {
    final canonical = _canonicalCalendarId(cropId: cropId, raw: calendarId);
    if (canonical == null || canonical.endsWith('_default')) {
      return baseTargets;
    }

    final bool isTemporal = canonical.endsWith('_temporal');
    final bool isIrrigated = canonical.endsWith('_riego');
    if (!isTemporal && !isIrrigated) return baseTargets;

    final String normalizedStage = stageKey.trim().toLowerCase();
    final bool isVegetative = _stageMatches(normalizedStage, const <String>[
      'germ',
      'emerg',
      'veg',
      'tiller',
      'elong',
    ]);
    final bool isReproductive = _stageMatches(normalizedStage, const <String>[
      'boot',
      'head',
      'flower',
      'grain',
      'fill',
      'maturity',
      'harvest',
      'tassel',
      'silk',
      'r1',
      'r2',
      'r3',
      'r4',
      'r5',
    ]);

    final double moistureDelta = isTemporal ? 2.0 : 0.0;
    final double resistanceDelta = isTemporal ? -0.10 : 0.05;
    final double nDelta = isVegetative ? (isIrrigated ? 4.0 : -4.0) : 0.0;
    final double kDelta = isReproductive ? (isIrrigated ? 3.0 : -3.0) : 0.0;

    return baseTargets.copyWith(
      moistureRaw: _shiftRange(
        baseTargets.moistureRaw,
        moistureDelta,
        min: 0.0,
        max: 100.0,
      ),
      resistance: _shiftRange(
        baseTargets.resistance,
        resistanceDelta,
        min: -1.0,
        max: 4.0,
      ),
      nIndex: _shiftRange(baseTargets.nIndex, nDelta, min: 0.0, max: 100.0),
      kIndex: _shiftRange(baseTargets.kIndex, kDelta, min: 0.0, max: 100.0),
      nSoilPpmRange: _shiftComparableRange(
        cropId: cropId,
        nutrient: AgroMetricKey.n,
        baseRange: baseTargets.nSoilPpmRange,
        deltaIndex: nDelta,
      ),
      kSoilPpmRange: _shiftComparableRange(
        cropId: cropId,
        nutrient: AgroMetricKey.k,
        baseRange: baseTargets.kSoilPpmRange,
        deltaIndex: kDelta,
      ),
    );
  }

  static AgroRange? _shiftComparableRange({
    required String cropId,
    required AgroMetricKey nutrient,
    required AgroRange? baseRange,
    required double deltaIndex,
  }) {
    if (baseRange == null) return null;
    if (deltaIndex.abs() < 0.0001) return baseRange;

    final double cap = NpkCaps.forCropMetric(
      cropKey: cropId,
      metricKey: nutrient,
    );
    final double deltaPpm = (deltaIndex / 100.0) * cap;

    return _shiftRange(baseRange, deltaPpm, min: 0.0, max: cap * 1.25);
  }

  static bool isGenericAlias(String? raw) {
    final normalized = raw?.trim().toLowerCase() ?? '';
    return normalized.isEmpty ||
        normalized == 'generic' ||
        normalized == 'genérico' ||
        normalized == 'generico' ||
        normalized == 'perfil genérico' ||
        normalized == 'generic_maize' ||
        normalized == 'generic_corn' ||
        normalized == 'generic_bean' ||
        normalized == 'generic_wheat' ||
        normalized == 'generic_barley' ||
        normalized == 'generic_oat' ||
        normalized == 'generic_tomato' ||
        normalized == 'generic_cucumber' ||
        normalized == 'generic_chili' ||
        normalized == 'generic_eggplant' ||
        normalized == 'generic_squash' ||
        normalized == 'generic_lettuce' ||
        normalized == 'generic_spinach' ||
        normalized == 'generic_onion' ||
        normalized == 'generic_garlic' ||
        normalized == 'eggplant_generic' ||
        normalized == 'squash_generic' ||
        normalized == 'lettuce_generic' ||
        normalized == 'spinach_generic' ||
        normalized == 'onion_generic' ||
        normalized == 'garlic_generic' ||
        normalized == 'be_gen' ||
        normalized == 'be-gen' ||
        normalized == 'begen' ||
        normalized == 'ca_gen' ||
        normalized == 'ca-gen' ||
        normalized == 'cagen' ||
        normalized == 'le_gen' ||
        normalized == 'le-gen' ||
        normalized == 'legen' ||
        normalized == 'sp_gen' ||
        normalized == 'sp-gen' ||
        normalized == 'spgen' ||
        normalized == 'on_gen' ||
        normalized == 'on-gen' ||
        normalized == 'ongen' ||
        normalized == 'ag_gen' ||
        normalized == 'ag-gen' ||
        normalized == 'aggen' ||
        normalized == 'otra berenjena' ||
        normalized == 'otra calabaza' ||
        normalized == 'otra lechuga' ||
        normalized == 'otra espinaca' ||
        normalized == 'otra cebolla' ||
        normalized == 'otro ajo' ||
        normalized == 'otra ajo' ||
        normalized == 'calabaza generica' ||
        normalized == 'lechuga generica' ||
        normalized == 'espinaca generica' ||
        normalized == 'cebolla generica' ||
        normalized == 'ajo generico' ||
        normalized == 'no se' ||
        normalized == 'no sé' ||
        normalized.startsWith('generic_');
  }

  static bool isGenericProfileId(String? profileId) {
    final normalized = profileId?.trim().toLowerCase() ?? '';
    return normalized.isNotEmpty &&
        (normalized.endsWith('_generic') ||
            normalized == 'maize_generic' ||
            normalized == 'fj_gen' ||
            normalized == 'tr_gen' ||
            normalized == 'cb_gen' ||
            normalized == 'av_gen' ||
            normalized == 'tm_gen' ||
            normalized == 'pe_gen' ||
            normalized == 'ch_gen' ||
            normalized == 'ca_gen' ||
            normalized == 'be_gen' ||
            normalized == 'le_gen' ||
            normalized == 'sp_gen' ||
            normalized == 'on_gen' ||
            normalized == 'ag_gen');
  }

  static String? _canonicalCalendarId({
    required String cropId,
    required String? raw,
  }) {
    final normalizedCropId = canonicalCropKeyOrNull(cropId);
    final normalized = _normalize(raw);
    if (normalizedCropId == null || normalized == null) return null;

    final explicit = calendarsForCrop(normalizedCropId)
        .map((calendar) => _normalize(calendar.id))
        .whereType<String>()
        .firstWhere((calendarId) => calendarId == normalized, orElse: () => '');
    if (explicit.isNotEmpty) return explicit;

    return switch (normalized) {
      'default' ||
      'base' ||
      'general' ||
      'general_base' => defaultCalendarIdForCrop(normalizedCropId),
      'temporal' || 'rainfed' || 'secano' => '${normalizedCropId}_temporal',
      'riego' || 'irrigated' => '${normalizedCropId}_riego',
      _ => null,
    };
  }

  static bool _stageMatches(String stageKey, List<String> patterns) {
    for (final pattern in patterns) {
      if (stageKey.contains(pattern)) return true;
    }
    return false;
  }

  static AgroRange _shiftRange(
    AgroRange range,
    double delta, {
    required double min,
    required double max,
  }) {
    double clampValue(double value) => value.clamp(min, max).toDouble();

    double lowMax = clampValue(range.lowMax + delta);
    double optimalMin = clampValue(range.optimalMin + delta);
    double optimalMax = clampValue(range.optimalMax + delta);
    double highMin = clampValue(range.highMin + delta);

    if (optimalMin < lowMax) optimalMin = lowMax;
    if (optimalMax < optimalMin) optimalMax = optimalMin;
    if (highMin < optimalMax) highMin = optimalMax;

    return AgroRange(
      lowMax: lowMax,
      optimalMin: optimalMin,
      optimalMax: optimalMax,
      highMin: highMin,
    );
  }

  static String canonicalCropKey(String? raw) {
    final value = raw?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return '';

    return switch (value) {
      'maize' || 'maiz' || 'corn' => maizeCropId,
      'bean' || 'beans' || 'frijol' => beanCropId,
      'wheat' || 'trigo' => wheatCropId,
      'barley' || 'cebada' => barleyCropId,
      'oat' || 'avena' => oatCropId,
      'tomato' || 'tomate' || 'jitomate' => tomatoCropId,
      'cucumber' || 'pepino' => cucumberCropId,
      'chili' ||
      'chile' ||
      'chiles' ||
      'pepper' ||
      'pimiento' ||
      'aji' => chiliCropId,
      'eggplant' || 'berenjena' || 'aubergine' => eggplantCropId,
      'squash' ||
      'calabaza' ||
      'calabazas' ||
      'calabacita' ||
      'calabacitas' ||
      'zucchini' ||
      'zuccini' ||
      'calabacin' ||
      'calabacín' ||
      'pumpkin' ||
      'zapallo' ||
      'ayote' ||
      'auyama' ||
      'castilla' ||
      'pipian' ||
      'pipián' ||
      'pipiana' ||
      'pepita' ||
      'chilacayote' ||
      'chilacayota' ||
      'butternut' ||
      'buchona' ||
      'mantequilla' ||
      'bola' ||
      'redonda' ||
      'criolla' ||
      'huicha' ||
      'güicha' ||
      'milpa' => squashCropId,
      'lettuce' ||
      'crop_lettuce' ||
      'lechuga' ||
      'lechugas' ||
      'lechuga romana' ||
      'romana' ||
      'cos' ||
      'romaine' ||
      'mini romana' ||
      'corazones' ||
      'little gem' ||
      'lechuga orejona' ||
      'orejona' ||
      'lechuga iceberg' ||
      'lechuga bola' ||
      'iceberg' ||
      'crisphead' ||
      'lechuga mantequilla' ||
      'lechuga butterhead' ||
      'butterhead' ||
      'bibb' ||
      'boston' ||
      'hoja suelta' ||
      'lechuga hoja suelta' ||
      'baby leaf' ||
      'lechuga baby leaf' ||
      'looseleaf' => lettuceCropId,
      'spinach' ||
      'crop_spinach' ||
      'spinach_generic' ||
      'spinach_savoy_summer' ||
      'spinach_savoy_winter' ||
      'spinach_smooth_baby' ||
      'spinach_oriental_bunching' ||
      'spinach_processing' ||
      'sp_gen' ||
      'sp-gen' ||
      'sp01' ||
      'sp-01' ||
      'sp_01' ||
      'sp02' ||
      'sp-02' ||
      'sp_02' ||
      'sp03' ||
      'sp-03' ||
      'sp_03' ||
      'sp04' ||
      'sp-04' ||
      'sp_04' ||
      'sp05' ||
      'sp-05' ||
      'sp_05' ||
      'espinaca' ||
      'espinacas' ||
      'espinaca generica' ||
      'espinaca saboya' ||
      'saboya verano' ||
      'semi-saboya verano' ||
      'savoy summer' ||
      'saboya invierno' ||
      'semi-saboya invierno' ||
      'savoy winter' ||
      'dias cortos' ||
      'espinaca lisa' ||
      'baby spinach' ||
      'smooth baby' ||
      'espinaca baby leaf' ||
      'espinaca oriental' ||
      'oriental bunch' ||
      'manojo' ||
      'espinaca proceso' ||
      'espinaca industria' ||
      'processing spinach' => spinachCropId,
      'onion' ||
      'crop_onion' ||
      'onion_generic' ||
      'onion_white' ||
      'onion_yellow' ||
      'onion_purple' ||
      'onion_red' ||
      'onion_transition' ||
      'onion_intermediate' ||
      'onion_cambray' ||
      'on_gen' ||
      'on-gen' ||
      'on01' ||
      'on-01' ||
      'on_01' ||
      'on02' ||
      'on-02' ||
      'on_02' ||
      'on03' ||
      'on-03' ||
      'on_03' ||
      'on04' ||
      'on-04' ||
      'on_04' ||
      'on05' ||
      'on-05' ||
      'on_05' ||
      'cebolla' ||
      'cebollas' ||
      'cebolla generica' ||
      'cebolla blanca' ||
      'cebolla amarilla' ||
      'cebolla dorada' ||
      'cebolla morada' ||
      'cebolla roja' ||
      'cebolla cambray' ||
      'cebolla de rama' ||
      'cebollin' ||
      'cebollín' ||
      'cambray' ||
      'white onion' ||
      'yellow onion' ||
      'red onion' ||
      'purple onion' ||
      'green onion' ||
      'bunching onion' ||
      'scallion' => onionCropId,
      'garlic' ||
      'crop_garlic' ||
      'garlic_generic' ||
      'garlic_white_pearl' ||
      'garlic_orion' ||
      'garlic_san_marqueno' ||
      'garlic_jaspeado_calera' ||
      'garlic_cezac_06' ||
      'garlic_barretero' ||
      'garlic_purple' ||
      'garlic_criollo_regional' ||
      'garlic_chinese_korean' ||
      'ag_gen' ||
      'ag-gen' ||
      'aggen' ||
      'ag01' ||
      'ag-01' ||
      'ag_01' ||
      'ag02' ||
      'ag-02' ||
      'ag_02' ||
      'ag03' ||
      'ag-03' ||
      'ag_03' ||
      'ag04' ||
      'ag-04' ||
      'ag_04' ||
      'ag05' ||
      'ag-05' ||
      'ag_05' ||
      'ajo' ||
      'ajos' ||
      'ajo generico' ||
      'ajo blanco' ||
      'ajo perla' ||
      'ajo jaspeado' ||
      'ajo calera' ||
      'ajo rayado' ||
      'ajo morado' ||
      'ajo criollo' ||
      'ajo regional' ||
      'ajo chino' ||
      'ajo coreano' ||
      'perla' ||
      'orion' ||
      'san marqueno' ||
      'diamante' ||
      'blanco de egipto' ||
      'cezac 06' ||
      'cezac06' ||
      'jaspeado calera' ||
      'barretero' ||
      'inifap 94' ||
      'inifap94' ||
      'tacatzcuaro' ||
      'tinguindin' ||
      'criollo regional' ||
      'chino calera' ||
      'chino cedel' ||
      'coreano' => garlicCropId,
      'crop_apple_tree' ||
      'apple_tree' ||
      'appletree' ||
      'apple' ||
      'manzano' ||
      'manzana' ||
      'manzanos' => appleTreeCropId,
      'crop_pear_tree' ||
      'pear_tree' ||
      'peartree' ||
      'pear' ||
      'pera' ||
      'peral' ||
      'peras' ||
      'perales' => pearTreeCropId,
      'crop_peach_tree' ||
      'peach_tree' ||
      'peachtree' ||
      'peach' ||
      'durazno' ||
      'duraznos' ||
      'duraznero' ||
      'duraznera' ||
      'melocoton' ||
      'melocotón' ||
      'melocotones' ||
      'melocotonero' => peachTreeCropId,
      'crop_walnut_tree' ||
      'walnut_tree' ||
      'walnuttree' ||
      'walnut' ||
      'nogal' ||
      'nogales' ||
      'nogal pecanero' ||
      'nogal pecano' ||
      'pecan' ||
      'pecana' ||
      'pecanero' ||
      'nuez' ||
      'nuez pecana' ||
      'nuez pecanera' => walnutTreeCropId,
      'crop_pistachio_tree' ||
      'pistachio_tree' ||
      'pistachiotree' ||
      'pistachio' ||
      'pistache' ||
      'pistaches' ||
      'pistacho' ||
      'pistachos' ||
      'pistachero' ||
      'pistacheros' ||
      'alfoncigo' ||
      'alfóncigo' => pistachioTreeCropId,
      'crop_orange_tree' ||
      'orange_tree' ||
      'orangetree' ||
      'orange' ||
      'oranges' ||
      'sweet orange' ||
      'naranjo' ||
      'naranjos' ||
      'naranja' ||
      'naranjas' ||
      'naranja dulce' ||
      'naranjo dulce' ||
      'naranjero' => orangeTreeCropId,
      'crop_lemon_tree' ||
      'lemon_tree' ||
      'lemontree' ||
      'crop_lime_tree' ||
      'lime_tree' ||
      'limetree' ||
      'lemon' ||
      'lemons' ||
      'lime' ||
      'limes' ||
      'limon' ||
      'limón' ||
      'limones' ||
      'limonero' ||
      'limoneros' ||
      'lima' ||
      'limon verde' ||
      'limón verde' ||
      'limon persa' ||
      'limón persa' ||
      'limon mexicano' ||
      'limón mexicano' => lemonTreeCropId,
      'crop_mango_tree' ||
      'mango_tree' ||
      'mangotree' ||
      'crop_mango' ||
      'mango' ||
      'mangos' ||
      'mangifera' ||
      'mangifera_indica' ||
      'mangifera indica' ||
      'arbol_mango' ||
      'árbol_mango' ||
      'arbol de mango' ||
      'árbol de mango' ||
      'mango ataulfo' ||
      'mango manila' ||
      'mango tommy' ||
      'mango kent' ||
      'mango keitt' => mangoTreeCropId,
      'crop_avocado_tree' ||
      'avocado_tree' ||
      'avocadotree' ||
      'crop_avocado' ||
      'avocado' ||
      'avocados' ||
      'aguacate' ||
      'aguacates' ||
      'aguacatero' ||
      'palta' ||
      'palto' ||
      'persea' ||
      'persea_americana' ||
      'persea americana' ||
      'arbol_aguacate' ||
      'árbol_aguacate' ||
      'arbol de aguacate' ||
      'árbol de aguacate' ||
      'aguacate hass' ||
      'aguacate criollo' ||
      'aguacate fuerte' => avocadoTreeCropId,
      // Cactus (ornamental). cropId canónico + alias legacy + aliases humanos.
      // Los ids provisionales previos del wizard (cactus_generic/mini/columnar)
      // resuelven al cultivo cactus; el perfil específico se resuelve aparte.
      'crop_cactus' ||
      'cactus' ||
      'cactos' ||
      'cacto' ||
      'cactus ornamental' ||
      'cactus desertico' ||
      'cactus desértico' ||
      'cactaceae' ||
      'cactacea' ||
      'cactácea' ||
      'cactus_generic' ||
      'cactus_mini' ||
      'cactus_columnar' => cactusCropId,
      // Suculenta (ornamental). cropId canónico + alias legacy + aliases humanos.
      // NO se mezcla con cactus: son cultivos distintos con targets distintos.
      'crop_succulent' ||
      'succulent' ||
      'succulents' ||
      'suculenta' ||
      'suculentas' ||
      'planta suculenta' ||
      'plantas suculentas' ||
      'planta crasa' ||
      'crasa' ||
      'crasas' ||
      'suculenta ornamental' => succulentCropId,
      // Sábila / Aloe (ornamental). cropId canónico + alias legacy + aliases
      // humanos. NO se mezcla con suculenta ni cactus: cultivos distintos con
      // targets distintos.
      'crop_aloe' ||
      'aloe' ||
      'aloe vera' ||
      'sabila' ||
      'sábila' ||
      'zabila' ||
      'zábila' ||
      'sabila ornamental' ||
      'planta de sabila' ||
      'planta de sábila' => aloeCropId,
      // Maguey / Agave (ornamental). cropId canónico + alias legacy + aliases
      // humanos. NO se mezcla con sábila, suculenta ni cactus: cultivos
      // distintos con targets distintos.
      'crop_agave' ||
      'agave' ||
      'agaves' ||
      'maguey' ||
      'magueyes' ||
      'planta de maguey' ||
      'planta de agave' => agaveCropId,
      // Nopal (ornamental). cropId canonico + alias legacy (`orn_nopal`) +
      // aliases humanos. NO se mezcla con cactus ni con maguey: cultivos
      // distintos con targets distintos. Los nombres de finalidad productiva
      // (tuna, nopalito, xoconostle) NO se listan a proposito: requieren
      // preguntar el objetivo antes de continuar (Documento A section 4.6).
      'crop_nopal' ||
      'nopal' ||
      'nopales' ||
      'opuntia' ||
      'opuntias' ||
      'opuntia sp.' ||
      'opuntia spp.' ||
      'orn_nopal' ||
      'ornamental_nopal' ||
      'nopal_crop' ||
      'crop_opuntia' ||
      'prickly pear' ||
      'cactus pear' ||
      'planta de nopal' => nopalCropId,
      // Rosal (ornamental, floración recurrente). cropId canónico + alias legacy
      // + aliases humanos. NO se mezcla con las ornamentales de establecimiento:
      // cultivo distinto, modo distinto, targets distintos.
      'crop_rose' ||
      'rose' ||
      'roses' ||
      'rosa' ||
      'rosas' ||
      'rosal' ||
      'rosales' => roseCropId,
      // Tulipán (ornamental, bulbosa estacional). cropId canónico + alias legacy
      // + aliases humanos. NO se mezcla con las ornamentales de establecimiento
      // ni con el rosal: cultivo distinto, modo distinto, targets distintos. Los
      // nombres ambiguos (árbol de tulipán / Liriodendron / tulipán africano /
      // Spathodea / "tulipán mexicano") NO se listan a propósito: quedan fuera
      // del alta automática y requieren confirmación (Documento A §18.2).
      'crop_tulip' ||
      'tulip' ||
      'tulips' ||
      'tulipan' ||
      'tulipán' ||
      'tulipanes' ||
      'tulipa' ||
      'orn_tulip' => tulipCropId,
      // Girasol (ornamental, anual verdadera). cropId canónico + alias legacy +
      // aliases humanos. NO se mezcla con las ornamentales de establecimiento, el
      // rosal ni el tulipán: cultivo distinto, modo distinto, targets distintos.
      // Los nombres ambiguos ("girasol mexicano" / Tithonia / topinambur / alto
      // oleico / girasol agrícola) NO se listan a propósito: quedan fuera del
      // alta automática y requieren confirmación (Documento A §7.3).
      'crop_sunflower' ||
      'sunflower' ||
      'sun flower' ||
      'girasol' ||
      'girasoles' ||
      'helianthus annuus' ||
      'helianthus_annuus' ||
      'mirasol' ||
      'flor de sol' => sunflowerCropId,
      // Cempasúchil (ornamental, anual verdadera). cropId canónico + alias
      // legacy (orn_cempasuchil) + variantes ortográficas c/s/z + nombres
      // culturales. NO se mezcla con el Girasol: mismo modo, biología distinta.
      // Quedan FUERA a propósito (Documento A §4.4, §4.5, §8.3): las demás
      // especies de Tagetes (patula, tenuifolia, lucida, minuta, lemmonii), las
      // "marigolds" que no son Tagetes (Calendula/pot marigold, Caltha/marsh
      // marigold, Baileya/desert marigold, Glebionis/corn marigold) y la
      // palabra "Tagetes" sola, que exige confirmación de especie.
      'crop_marigold' ||
      'marigold' ||
      'crop_cempasuchil' ||
      'orn_cempasuchil' ||
      'orn_marigold' ||
      'cempasuchil' ||
      'cempasúchil' ||
      'sempasuchil' ||
      'sempasúchil' ||
      'zempasuchil' ||
      'zempasúchil' ||
      'cempoalxochitl' ||
      'cempoalxóchitl' ||
      'cempaxuchil' ||
      'cempaxuchitl' ||
      'cempaxúchitl' ||
      'flor de muerto' ||
      'flor de muertos' ||
      'tagetes erecta' ||
      't. erecta' ||
      'aztec marigold' ||
      'african marigold' ||
      'american marigold' => marigoldCropId,
      _ => value,
    };
  }

  static String? canonicalCropKeyOrNull(String? raw) {
    final result = canonicalCropKey(raw);
    return result.isEmpty ? null : result;
  }

  static String cropDisplayName(String cropId) {
    return cropById(cropId)?.label ?? _fallbackDisplayName(cropId);
  }

  static String _fallbackDisplayName(String cropId) {
    return switch (cropId) {
      maizeCropId => 'Maíz',
      beanCropId => 'Frijol',
      wheatCropId => 'Trigo',
      barleyCropId => 'Cebada',
      oatCropId => 'Avena',
      tomatoCropId => 'Tomate',
      cucumberCropId => 'Pepino',
      chiliCropId => 'Chile',
      eggplantCropId => 'Berenjena',
      squashCropId => 'Calabaza',
      lettuceCropId => 'Lechuga',
      spinachCropId => 'Espinaca',
      onionCropId => 'Cebolla',
      garlicCropId => 'Ajo',
      appleTreeCropId => 'Manzano',
      pearTreeCropId => 'Pera',
      peachTreeCropId => 'Durazno',
      walnutTreeCropId => 'Nogal',
      pistachioTreeCropId => 'Pistache',
      orangeTreeCropId => 'Naranjo',
      lemonTreeCropId => 'Limón',
      mangoTreeCropId => 'Mango',
      avocadoTreeCropId => 'Aguacate',
      cactusCropId => 'Cactus',
      succulentCropId => 'Suculenta',
      aloeCropId => 'Sábila',
      agaveCropId => 'Maguey',
      roseCropId => 'Rosal',
      tulipCropId => 'Tulipán',
      sunflowerCropId => 'Girasol',
      marigoldCropId => 'Cempasúchil',
      nopalCropId => 'Nopal',
      _ => 'Cultivo',
    };
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }
}
