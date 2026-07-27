import 'package:flutter/material.dart';

import 'package:bio_g/core/crops/apple_tree/apple_tree_assets.dart';
import 'package:bio_g/core/crops/peach_tree/peach_tree_assets.dart';
import 'package:bio_g/core/crops/pear_tree/pear_tree_assets.dart';
import 'package:bio_g/core/crops/walnut_tree/walnut_tree_assets.dart';
import 'package:bio_g/core/crops/pistachio_tree/pistachio_tree_assets.dart';
import 'package:bio_g/core/crops/orange_tree/orange_tree_assets.dart';
import 'package:bio_g/core/crops/lemon_tree/lemon_tree_assets.dart';
import 'package:bio_g/core/crops/mango_tree/mango_tree_assets.dart';
import 'package:bio_g/core/crops/avocado_tree/avocado_tree_assets.dart';

class OnboardingUiAssets {
  static const String logo = 'assets/images/logo_bio_g.png';
  static const String landscape = 'assets/images/log_in_image.png';
  static const String grain = 'assets/icons/wizard/ic_grano.png';
  static const String vegetable = 'assets/icons/wizard/ic_hortaliza.png';
  static const String tree = 'assets/icons/wizard/ic_tree.png';
  static const String ornamental =
      'assets/icons/wizard/ic_planta_hornamental.png';
  static const String genericPlant =
      'assets/icons/wizard/ic_planta_generica.png';
  static const String maize = 'assets/icons/wizard/ic_maiz.png';
  static const String wheat = 'assets/icons/wizard/ic_trigo.png';
  static const String barley = 'assets/icons/wizard/ic_cebada.png';
  static const String oat = 'assets/icons/wizard/ic_avena.png';
  static const String bean = 'assets/icons/wizard/ic_frijol.png';
  static const String beanBlack = 'assets/icons/wizard/ic_frijol_negro.png';
  static const String beanRed = 'assets/icons/wizard/ic_frijol_rojo.png';
  static const String beanWhite = 'assets/icons/wizard/ic_frijol_blanco.png';
  static const String tomato = 'assets/icons/wizard/ic_tomate.png';
  static const String cucumber = 'assets/icons/wizard/ic_cucumber.png';
  static const String chili = 'assets/icons/wizard/ic_chili.png';
  static const String eggplant = 'assets/icons/wizard/ic_eggplant.png';
  static const String squash = 'assets/icons/wizard/ic_squash_generic.png';
  static const String lettuce = 'assets/icons/wizard/ic_lettuce_generic.png';
  static const String spinach = 'assets/icons/wizard/ic_spinach.png';
  static const String onion = 'assets/icons/wizard/ic_onion_generic.png';
  static const String garlic = 'assets/icons/wizard/ic_garlic_generic.png';
  static const String tulip = 'assets/icons/wizard/ic_tulip.png';
  static const String sunflower = 'assets/icons/wizard/ic_sunflower.png';
  static const String marigold = 'assets/icons/wizard/ic_cempasuchil.png';
  static const String variety = 'assets/icons/wizard/ic_variedad.png';
  static const String configureCrop =
      'assets/icons/wizard/ic_configurar_cultivo.png';
  static const String planned = 'assets/icons/wizard/ic_aun_no_siembro.png';
  static const String planted = 'assets/icons/wizard/ic_ya_sembrado.png';
  static const String harvested = 'assets/icons/wizard/ic_ya_coseche.png';

  static String assetForScale(String? scale) {
    switch (scale) {
      case 'field':
        return grain;
      case 'orchard':
        return vegetable;
      case 'pot':
        return ornamental;
      default:
        return genericPlant;
    }
  }

  static String assetForCategory(String? category) {
    switch (category) {
      case 'grain':
        return grain;
      case 'vegetable':
        return vegetable;
      case 'tree':
        return tree;
      case 'ornamental':
        return ornamental;
      default:
        return genericPlant;
    }
  }

  static String assetForCrop(String? cropId, {String? category}) {
    switch ((cropId ?? '').trim().toLowerCase()) {
      case 'maize':
      case 'maiz':
      case 'corn':
        return maize;
      case 'wheat':
      case 'trigo':
        return wheat;
      case 'barley':
      case 'cebada':
        return barley;
      case 'oat':
      case 'avena':
        return oat;
      case 'bean':
      case 'frijol':
        return bean;
      case 'tomato':
      case 'tomate':
      case 'jitomate':
        return tomato;
      case 'cucumber':
      case 'pepino':
        return cucumber;
      case 'chili':
      case 'chile':
      case 'pepper':
      case 'pimiento':
        return chili;
      case 'eggplant':
      case 'berenjena':
      case 'aubergine':
        return eggplant;
      case 'squash':
      case 'calabaza':
      case 'calabacita':
      case 'zucchini':
      case 'pumpkin':
      case 'zapallo':
      case 'ayote':
      case 'auyama':
      case 'castilla':
      case 'pipian':
      case 'pipián':
      case 'pepita':
      case 'chilacayote':
      case 'butternut':
        return squash;
      case 'lettuce':
      case 'lechuga':
        return lettuce;
      case 'spinach':
      case 'crop_spinach':
      case 'espinaca':
        return spinach;
      case 'onion':
      case 'crop_onion':
      case 'cebolla':
        return onion;
      case 'garlic':
      case 'crop_garlic':
      case 'ajo':
      case 'ajos':
        return garlic;
      case 'carrot':
      case 'calabacin':
        return vegetable;
      case 'crop_apple_tree':
      case 'apple_tree':
        return AppleTreeAssets.cropIcon;
      case 'crop_pear_tree':
      case 'pear_tree':
      case 'pera':
      case 'peral':
        return PearTreeAssets.cropIcon;
      case 'crop_peach_tree':
      case 'peach_tree':
      case 'peach':
      case 'peachtree':
      case 'durazno':
      case 'duraznero':
      case 'melocoton':
      case 'melocotón':
      case 'melocotonero':
        return PeachTreeAssets.cropIcon;
      case 'crop_walnut_tree':
      case 'walnut_tree':
      case 'walnut':
      case 'walnuttree':
      case 'nogal':
      case 'pecan':
      case 'nuez':
        return WalnutTreeAssets.cropIcon;
      case 'crop_pistachio_tree':
      case 'pistachio_tree':
      case 'pistachio':
      case 'pistachiotree':
      case 'pistache':
      case 'pistacho':
      case 'pistachero':
        return PistachioTreeAssets.cropIcon;
      case 'crop_orange_tree':
      case 'orange_tree':
      case 'orange':
      case 'orangetree':
      case 'naranjo':
      case 'naranja':
        return OrangeTreeAssets.cropIcon;
      case 'crop_lemon_tree':
      case 'lemon_tree':
      case 'lemontree':
      case 'crop_lime_tree':
      case 'lime_tree':
      case 'lemon':
      case 'lime':
      case 'limon':
      case 'limón':
      case 'limonero':
      case 'lima':
        return LemonTreeAssets.cropIcon;
      case 'crop_mango_tree':
      case 'mango_tree':
      case 'mangotree':
      case 'crop_mango':
      case 'mango':
      case 'mangos':
      case 'mangifera':
      case 'mangifera_indica':
      case 'arbol_mango':
      case 'árbol_mango':
        return MangoTreeAssets.cropIcon;
      case 'crop_avocado_tree':
      case 'avocado_tree':
      case 'avocadotree':
      case 'crop_avocado':
      case 'avocado':
      case 'avocados':
      case 'aguacate':
      case 'aguacates':
      case 'aguacatero':
      case 'palta':
      case 'palto':
      case 'persea':
      case 'persea_americana':
      case 'arbol_aguacate':
      case 'árbol_aguacate':
      case 'arbol de aguacate':
      case 'árbol de aguacate':
        return AvocadoTreeAssets.cropIcon;
      case 'rose':
      case 'cactus':
      case 'crop_cactus':
      case 'succulent':
      case 'crop_succulent':
      case 'suculenta':
      case 'aloe':
      case 'crop_aloe':
      case 'sabila':
      case 'sábila':
      case 'agave':
      case 'crop_agave':
      case 'maguey':
        return ornamental;
      case 'tulip':
      case 'crop_tulip':
      case 'tulipan':
      case 'tulipán':
      case 'tulipanes':
        return tulip;
      case 'sunflower':
      case 'crop_sunflower':
      case 'girasol':
      case 'girasoles':
        return sunflower;
      case 'marigold':
      case 'crop_marigold':
      case 'cempasuchil':
      case 'cempasúchil':
      case 'cempoalxochitl':
      case 'cempoalxóchitl':
      case 'flor de muerto':
        return marigold;
      default:
        return assetForCategory(category);
    }
  }

  /// Resuelve el ícono correcto de frijol según la variedad seleccionada.
  static String assetForBeanVariety(String? varietyId) {
    switch (varietyId) {
      case 'bean_negro_temprano':
      case 'bean_negro':
        return beanBlack;
      case 'bean_flor_mayo_junio':
        return beanRed;
      case 'bean_bayo_azufrado_blanco':
        return beanWhite;
      case 'bean_pinto':
      case 'bean_peruano':
      case 'bean_canario':
      case 'bean_generic':
      default:
        return bean;
    }
  }

  static String assetForStage(String? stage, {String? category}) {
    switch ((stage ?? '').trim().toLowerCase()) {
      case 'planned':
        return planned;
      case 'newly_planted':
      case 'growing':
        return planted;
      case 'fallow':
      case 'skip':
        return harvested;
      default:
        return assetForCategory(category);
    }
  }
}

class OnboardingAssetBadge extends StatelessWidget {
  final String assetPath;
  final IconData fallbackIcon;
  final double size;
  final double imageScale;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;

  const OnboardingAssetBadge({
    super.key,
    required this.assetPath,
    this.fallbackIcon = Icons.eco_rounded,
    this.size = 60,
    this.imageScale = 0.76,
    this.padding = const EdgeInsets.all(8),
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.backgroundColor,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: gradient == null
            ? backgroundColor ?? const Color(0xFFF1F7F4)
            : null,
        gradient: gradient,
      ),
      child: Image.asset(
        assetPath,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder:
            (BuildContext context, Object error, StackTrace? stackTrace) {
              return Icon(
                fallbackIcon,
                size: size * imageScale * 0.72,
                color: const Color(0xFF7FAA61),
              );
            },
      ),
    );
  }
}
