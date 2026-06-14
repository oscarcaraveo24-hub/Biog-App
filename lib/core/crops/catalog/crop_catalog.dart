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
      _ => 'Cultivo',
    };
  }

  static String? _normalize(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized.toLowerCase();
  }
}
