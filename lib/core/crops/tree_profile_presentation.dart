import 'package:bio_g/core/crops/apple_tree/apple_tree_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog_models.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_catalog.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_catalog.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_catalog.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_catalog.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_catalog.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_catalog.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_catalog.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_catalog.dart';

/// Presentación humana de perfiles/variedades de árboles para el wizard y el
/// onboarding.
///
/// Base común para Manzano, Pera y futuros árboles perennes (sin hardcodes
/// Apple-only). Reglas de producto:
/// - El productor NUNCA ve códigos técnicos (`PR-01`, `AP-SKIP`, "Perfil") en
///   las opciones visibles; sólo nombres humanos.
/// - El perfil general/SKIP va SIEMPRE al final de la lista, no arriba.
/// - La pregunta del selector habla de "variedad de manzano/peral", no de
///   "perfil del árbol".
class TreeProfilePresentation {
  const TreeProfilePresentation._();

  /// Pregunta humana del selector de variedad, por árbol.
  static String varietyQuestion(String? cropId) {
    switch (CropCatalog.canonicalCropKey(cropId)) {
      case CropCatalog.appleTreeCropId:
        return '¿Qué variedad de manzano tienes?';
      case CropCatalog.pearTreeCropId:
        return '¿Qué variedad de peral tienes?';
      case CropCatalog.peachTreeCropId:
        return '¿Qué variedad de duraznero tienes?';
      case CropCatalog.walnutTreeCropId:
        return '¿Qué variedad de nogal tienes?';
      case CropCatalog.pistachioTreeCropId:
        return '¿Qué tipo de pistache tienes?';
      case CropCatalog.orangeTreeCropId:
        return '¿Qué tipo de naranja tienes?';
      case CropCatalog.lemonTreeCropId:
        return '¿Qué tipo de limón tienes?';
      case CropCatalog.mangoTreeCropId:
        return '¿Qué tipo de mango tienes?';
      case CropCatalog.avocadoTreeCropId:
        return '¿Qué tipo de aguacate tienes?';
      default:
        return '¿Qué variedad de árbol tienes?';
    }
  }

  /// Etiqueta visible (humana) de un perfil AP/PR/DZ. Nunca devuelve el código
  /// técnico; si el árbol no es conocido, limpia el prefijo del label del
  /// catálogo como red de seguridad.
  static String displayLabel(
    String? cropId,
    String? profileId, {
    String? fallbackLabel,
  }) {
    final canonicalCrop = CropCatalog.canonicalCropKey(cropId);
    final id = _normalizeTreeProfileKey(profileId);

    if (canonicalCrop == CropCatalog.appleTreeCropId) {
      switch (id) {
        case kApSkip:
          return 'No sé / Manzano general';
        case kAp01Golden:
          return 'Golden';
        case kAp02Red:
          return 'Red Delicious / Roja';
        case kAp03CriollaRayada:
          return 'Criolla rayada';
        case kAp04Gala:
          return 'Gala';
        case kAp05LowChill:
          return 'Bajo frío';
      }
    } else if (canonicalCrop == CropCatalog.pearTreeCropId) {
      switch (id) {
        case kPrSkip:
          return 'No sé / Pera general';
        case kPr01BartlettWilliams:
          return 'Bartlett / Williams';
        case kPr02Anjou:
          return "Anjou / D'Anjou";
        case kPr03Bosc:
          return 'Bosc';
        case kPr04SeckelComice:
          return 'Seckel / Comice';
        case kPr05KiefferRustic:
          return 'Kieffer / rústicas';
      }
    } else if (canonicalCrop == CropCatalog.peachTreeCropId) {
      switch (id) {
        case kDzSkip:
          return 'No sé / Durazno general';
        case kDz01CriolloRegional:
          return 'Criollo / regional';
        case kDz02TempranoBajoFrio:
          return 'Temprano / bajo frío';
        case kDz03AmarilloComercial:
          return 'Amarillo comercial';
        case kDz04BlancoDulce:
          return 'Blanco / dulce';
        case kDz05TardioIndustria:
          return 'Tardío / industria';
      }
    } else if (canonicalCrop == CropCatalog.walnutTreeCropId) {
      switch (id) {
        case kNgSkip:
          return 'No sé / Nogal general';
        case kNg01Western:
          return 'Western / Western Schley';
        case kNg02Wichita:
          return 'Wichita';
        case kNg03WesternWichita:
          return 'Bloque Western / Wichita';
        case kNg04CriolloRegional:
          return 'Criollo / regional';
        case kNg05TempranoPawneeKanza:
          return 'Temprano / Pawnee-Kanza';
      }
    } else if (canonicalCrop == CropCatalog.pistachioTreeCropId) {
      switch (id) {
        case kPsSkip:
          return 'No sé / Pistache general';
        case kPs01KermanPeters:
          return 'Kerman tradicional';
        case kPs02GoldenHillsRandy:
          return 'Golden Hills temprano';
        case kPs03LostHillsRandy:
          return 'Lost Hills calibre grande';
        case kPs04SiroraCompatible:
          return 'Sirora intermedio';
        case kPs05LarnakaMateurLowChill:
          return 'Mediterráneo / bajo-frío relativo';
      }
    } else if (canonicalCrop == CropCatalog.orangeTreeCropId) {
      switch (id) {
        case kOrSkip:
          return 'No sé / Naranjo general';
        case kOr01Valencia:
          return 'Valencia / tardía / jugo';
        case kOr02Navel:
          return 'Navel / ombligo / mesa';
        case kOr03Temprano:
          return 'Temprano / Hamlin-Pineapple';
        case kOr04CriolloRegional:
          return 'Criollo / regional';
        case kOr05TropicalCalido:
          return 'Tropical / clima cálido';
      }
    } else if (canonicalCrop == CropCatalog.lemonTreeCropId) {
      switch (id) {
        case kLmSkip:
          return 'No sé / Limón general';
        case kLm01PersaTahiti:
          return 'Persa / Tahití / sin semilla';
        case kLm02MexicanoColima:
          return 'Mexicano / Colima / con semilla';
        case kLm03AmarilloEurekaLisbon:
          return 'Amarillo / Eureka / Lisbon';
        case kLm04TropicalContinuo:
          return 'Tropical / producción continua';
        case kLm05DesfaseInducido:
          return 'Desfase / producción programada';
      }
    } else if (canonicalCrop == CropCatalog.mangoTreeCropId) {
      switch (id) {
        case kMgSkip:
          return 'No sé / Mango general';
        case kMg01AtaulfoManila:
          return 'Ataulfo / Manila / miel';
        case kMg02TommyAtkins:
          return 'Tommy Atkins';
        case kMg03Kent:
          return 'Kent';
        case kMg04Keitt:
          return 'Keitt';
        case kMg05CriolloRegional:
          return 'Criollo / regional';
      }
    } else if (canonicalCrop == CropCatalog.avocadoTreeCropId) {
      switch (id) {
        case kAgSkip:
          return 'No sé / Aguacate general';
        case kAg01Hass:
          return 'Hass';
        case kAg02MendezCarmen:
          return 'Méndez / Carmen / Hass temprano';
        case kAg03CriolloMexicano:
          return 'Criollo / mexicano / regional';
        case kAg04FuertePielVerde:
          return 'Fuerte / piel verde';
        case kAg05AntillanoTropical:
          return 'Antillano / tropical';
        case kAg06TardioLambReed:
          return 'Tardío / Lamb Hass / Reed';
      }
    }

    return _stripTechnicalCode(fallbackLabel);
  }

  static String _normalizeTreeProfileKey(String? profileId) {
    final value = (profileId ?? '').trim().toLowerCase();
    final compact = value.replaceAll(RegExp(r'[\s_-]+'), '');

    if (compact.contains('apskip')) return kApSkip;
    if (compact.contains('ap01')) return kAp01Golden;
    if (compact.contains('ap02')) return kAp02Red;
    if (compact.contains('ap03')) return kAp03CriollaRayada;
    if (compact.contains('ap04')) return kAp04Gala;
    if (compact.contains('ap05')) return kAp05LowChill;

    if (compact.contains('prskip')) return kPrSkip;
    if (compact.contains('pr01')) return kPr01BartlettWilliams;
    if (compact.contains('pr02')) return kPr02Anjou;
    if (compact.contains('pr03')) return kPr03Bosc;
    if (compact.contains('pr04')) return kPr04SeckelComice;
    if (compact.contains('pr05')) return kPr05KiefferRustic;

    if (compact.contains('dzskip')) return kDzSkip;
    if (compact.contains('dz01')) return kDz01CriolloRegional;
    if (compact.contains('dz02')) return kDz02TempranoBajoFrio;
    if (compact.contains('dz03')) return kDz03AmarilloComercial;
    if (compact.contains('dz04')) return kDz04BlancoDulce;
    if (compact.contains('dz05')) return kDz05TardioIndustria;

    if (compact.contains('ngskip')) return kNgSkip;
    if (compact.contains('ng01')) return kNg01Western;
    if (compact.contains('ng02')) return kNg02Wichita;
    if (compact.contains('ng03')) return kNg03WesternWichita;
    if (compact.contains('ng04')) return kNg04CriolloRegional;
    if (compact.contains('ng05')) return kNg05TempranoPawneeKanza;

    if (compact.contains('psskip')) return kPsSkip;
    if (compact.contains('ps01')) return kPs01KermanPeters;
    if (compact.contains('ps02')) return kPs02GoldenHillsRandy;
    if (compact.contains('ps03')) return kPs03LostHillsRandy;
    if (compact.contains('ps04')) return kPs04SiroraCompatible;
    if (compact.contains('ps05')) return kPs05LarnakaMateurLowChill;

    if (compact.contains('orskip')) return kOrSkip;
    if (compact.contains('or01')) return kOr01Valencia;
    if (compact.contains('or02')) return kOr02Navel;
    if (compact.contains('or03')) return kOr03Temprano;
    if (compact.contains('or04')) return kOr04CriolloRegional;
    if (compact.contains('or05')) return kOr05TropicalCalido;

    if (compact.contains('lmskip')) return kLmSkip;
    if (compact.contains('lm01')) return kLm01PersaTahiti;
    if (compact.contains('lm02')) return kLm02MexicanoColima;
    if (compact.contains('lm03')) return kLm03AmarilloEurekaLisbon;
    if (compact.contains('lm04')) return kLm04TropicalContinuo;
    if (compact.contains('lm05')) return kLm05DesfaseInducido;

    if (compact.contains('mgskip')) return kMgSkip;
    if (compact.contains('mg01')) return kMg01AtaulfoManila;
    if (compact.contains('mg02')) return kMg02TommyAtkins;
    if (compact.contains('mg03')) return kMg03Kent;
    if (compact.contains('mg04')) return kMg04Keitt;
    if (compact.contains('mg05')) return kMg05CriolloRegional;

    if (compact.contains('agskip')) return kAgSkip;
    if (compact.contains('ag01')) return kAg01Hass;
    if (compact.contains('ag02')) return kAg02MendezCarmen;
    if (compact.contains('ag03')) return kAg03CriolloMexicano;
    if (compact.contains('ag04')) return kAg04FuertePielVerde;
    if (compact.contains('ag05')) return kAg05AntillanoTropical;
    if (compact.contains('ag06')) return kAg06TardioLambReed;

    return value;
  }

  /// Subtítulo humano para la opción general/SKIP (sin la palabra "Perfil").
  static const String genericOptionSubtitle =
      'Recomendado si no sabes la variedad. Es general y migrable: podrás '
      'precisarla después sin perder historial.';

  /// Reordena los perfiles para que el general/SKIP quede AL FINAL de la lista,
  /// conservando el orden relativo de los específicos. El perfil general de un
  /// árbol es su `defaultProfileId` (AP-SKIP / PR-SKIP / DZ-SKIP).
  static List<CropProfileEntry> genericLast(
    List<CropProfileEntry> profiles,
    String? cropId,
  ) {
    final canonicalCrop = CropCatalog.canonicalCropKey(cropId);
    final genericId = CropCatalog.cropById(canonicalCrop)?.defaultProfileId;

    final specific = <CropProfileEntry>[];
    final generic = <CropProfileEntry>[];
    for (final profile in profiles) {
      if (_isGenericProfile(profile, genericId)) {
        generic.add(profile);
      } else {
        specific.add(profile);
      }
    }
    return <CropProfileEntry>[...specific, ...generic];
  }

  static bool _isGenericProfile(CropProfileEntry profile, String? genericId) {
    if (genericId != null && profile.id == genericId) return true;
    final id = profile.id.trim().toLowerCase();
    return id == kApSkip ||
        id == kPrSkip ||
        id == kDzSkip ||
        id == kNgSkip ||
        id == kPsSkip ||
        id == kOrSkip ||
        id.endsWith('_skip');
  }

  /// Quita un prefijo de código técnico ("PR-01 - ", "AP-SKIP - ") si aparece
  /// en el label del catálogo. Sólo actúa cuando el prefijo parece un código de
  /// árbol, para no tocar labels legítimos de otros cultivos.
  static String _stripTechnicalCode(String? label) {
    final value = (label ?? '').trim();
    if (value.isEmpty) return 'Variedad';

    final separatorIndex = value.indexOf(' - ');
    if (separatorIndex > 0) {
      final prefix = value.substring(0, separatorIndex).trim().toUpperCase();
      if (RegExp(r'^(AP|PR|DZ|NG|PS)[-_ ]?[A-Z0-9]*$').hasMatch(prefix)) {
        final rest = value.substring(separatorIndex + 3).trim();
        if (rest.isNotEmpty) return rest;
      }
    }

    final codePrefix = RegExp(
      r'^(AP|PR|DZ|NG|PS)[-_ ]?(SKIP|0?[1-9])\b\s*[-:]?\s*',
      caseSensitive: false,
    );
    final withoutPrefix = value.replaceFirst(codePrefix, '').trim();
    if (withoutPrefix.isNotEmpty && withoutPrefix != value) {
      return withoutPrefix;
    }

    return value;
  }
}
