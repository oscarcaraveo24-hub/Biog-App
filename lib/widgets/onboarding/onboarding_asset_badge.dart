import 'package:flutter/material.dart';

class OnboardingUiAssets {
  static const String logo = 'assets/images/logo_bio_g.png';
  static const String landscape = 'assets/images/log_in_image.png';
  static const String grain = 'assets/icons/wizard/ic_grano.png';
  static const String vegetable = 'assets/icons/wizard/ic_hortaliza.png';
  static const String tree = 'assets/icons/wizard/ic_arbol.png';
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
      case 'pepper':
      case 'lettuce':
      case 'onion':
      case 'carrot':
      case 'zucchini':
      case 'calabacin':
        return vegetable;
      case 'lemon_tree':
      case 'apple_tree':
        return tree;
      case 'rose':
      case 'cactus':
        return ornamental;
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
      case 'growing_tree':
        return planted;
      case 'near_production':
      case 'productive':
        return category == 'tree' ? tree : planted;
      case 'dormant':
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
