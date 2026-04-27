import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

class ConfigureSeedWizardAssets {
  static const String logoPath = 'assets/images/logo_bio_g.png';

  static const String introIcon = 'assets/icons/metrics/nav_power.png';
  static const String successIcon = 'assets/icons/metrics/ic_balance.png';

  static const String categoryGrain = 'assets/icons/wizard/ic_grano.png';
  static const String categoryVegetable =
      'assets/icons/wizard/ic_hortaliza.png';
  static const String categoryTree = 'assets/icons/wizard/ic_arbol.png';
  static const String categoryOrnamental =
      'assets/icons/wizard/ic_planta_hornamental.png';
  static const String categoryGeneric =
      'assets/icons/wizard/ic_planta_generica.png';

  static const String cropMaize = 'assets/icons/wizard/ic_maiz.png';
  static const String cropWheat = 'assets/icons/wizard/ic_trigo.png';
  static const String cropBarley = 'assets/icons/wizard/ic_cebada.png';
  static const String cropBean = 'assets/icons/wizard/ic_frijol.png';
  static const String cropOat = 'assets/icons/wizard/ic_avena.png';
  static const String cropCucumber = 'assets/icons/wizard/ic_cucumber.png';
  static const String cropChili = 'assets/icons/wizard/ic_chili.png';
  static const String cropEggplant = 'assets/icons/wizard/ic_eggplant.png';

  static const String cucumberSlicer =
      'assets/icons/wizard/ic_cucumber_slicer.png';
  static const String cucumberEnglishProtected =
      'assets/icons/wizard/ic_cucumber_english_protected.png';
  static const String cucumberPersianMini =
      'assets/icons/wizard/ic_cucumber_persian_mini.png';
  static const String cucumberCornichonPickling =
      'assets/icons/wizard/ic_cucumber_cornichon_pickling.png';

  static const String chiliGeneric = 'assets/icons/wizard/ic_chili_generic.png';
  static const String chiliJalapeno =
      'assets/icons/wizard/ic_chili_jalapeno.png';
  static const String chiliSerrano = 'assets/icons/wizard/ic_chili_serrano.png';
  static const String chiliPoblanoAncho =
      'assets/icons/wizard/ic_chili_poblano_ancho.png';
  static const String chiliChilacaPasilla =
      'assets/icons/wizard/ic_chili_chilaca_pasilla.png';
  static const String chiliGuajilloMirasol =
      'assets/icons/wizard/ic_chili_guajillo_mirasol.png';
  static const String chiliArbolPuya =
      'assets/icons/wizard/ic_chili_arbol_puya.png';
  static const String chiliHabanero =
      'assets/icons/wizard/ic_chili_habanero.png';
  static const String chiliBellPepper =
      'assets/icons/wizard/ic_chili_bell_pepper.png';

  // Berenjena
  //
  // El genérico usa el icono madre de berenjena.
  static const String eggplantGeneric = 'assets/icons/wizard/ic_eggplant.png';
  static const String eggplantItalianBlack =
      'assets/icons/wizard/ic_eggplant_italian_black.png';
  static const String eggplantLongPurple =
      'assets/icons/wizard/ic_eggplant_long_purple.png';
  static const String eggplantOvalRound =
      'assets/icons/wizard/ic_eggplant_oval_round.png';
  static const String eggplantStriped =
      'assets/icons/wizard/ic_eggplant_striped.png';
  static const String eggplantWhite =
      'assets/icons/wizard/ic_eggplant_white.png';

  /// Ícono principal del cultivo tomate (listas y encabezados).
  static const String cropTomato = 'assets/icons/wizard/ic_tomate.png';

  static const String tomatoGeneric =
      'assets/icons/wizard/ic_tomate_generico.png';
  static const String tomatoBola = 'assets/icons/wizard/ic_tomate_bola.png';
  static const String tomatoCherry = 'assets/icons/wizard/ic_tomate_cherry.png';
  static const String tomatoRacimo = 'assets/icons/wizard/ic_tomate_racimo.png';
  static const String tomatoSaladetteOpen =
      'assets/icons/wizard/ic_tomate_saladette_campo_abierto.png';
  static const String tomatoSaladetteProtected =
      'assets/icons/wizard/ic_tomate_saladette_protegido.png';

  static const String variety = 'assets/icons/wizard/ic_variedad.png';

  static const String beanPinto = 'assets/icons/wizard/ic_frijol.png';
  static const String beanRed = 'assets/icons/wizard/ic_frijol_rojo.png';
  static const String beanBlack = 'assets/icons/wizard/ic_frijol_negro.png';
  static const String beanWhite = 'assets/icons/wizard/ic_frijol_blanco.png';

  static const String maizeWhite = 'assets/icons/wizard/ic_maiz_blanco.png';
  static const String maizeYellow = 'assets/icons/wizard/ic_maiz.png';
  static const String maizeForage = 'assets/icons/wizard/ic_maiz_forrajero.png';
  static const String maizeElote = 'assets/icons/wizard/ic_maiz_elotero.png';

  static String maizeIconForVariety({String? useTypeId, String? marketTypeId}) {
    if (useTypeId == 'elote') return maizeElote;
    if (useTypeId == 'forage') {
      // Forrajero blanco → ícono blanco; forrajero amarillo → ícono forrajero.
      if (marketTypeId == 'white') return maizeWhite;
      return maizeForage;
    }
    // Grano: respeta el color del mercado.
    if (marketTypeId == 'white') return maizeWhite;
    if (marketTypeId == 'yellow') return maizeYellow;
    return cropMaize;
  }

  static String beanIconForVariety({
    String? varietyId,
    String? label,
    bool genericFallbackToPinto = true,
  }) {
    switch (varietyId) {
      case 'bean_negro_temprano':
      case 'bean_negro':
        return beanBlack;
      case 'bean_pinto':
        return beanPinto;
      case 'bean_flor_mayo_junio':
        return beanRed;
      case 'bean_bayo_azufrado_blanco':
        return beanWhite;
      case 'bean_generic':
        return genericFallbackToPinto ? beanPinto : variety;
    }

    final normalized = (label ?? '').trim().toLowerCase();

    if (normalized.contains('negro')) return beanBlack;
    if (normalized.contains('pinto')) return beanPinto;
    if (normalized.contains('flor de mayo') ||
        normalized.contains('flor de junio') ||
        normalized.contains('rojo')) {
      return beanRed;
    }
    if (normalized.contains('bayo') ||
        normalized.contains('azufrado') ||
        normalized.contains('blanco')) {
      return beanWhite;
    }
    if (normalized.contains('gen')) {
      return genericFallbackToPinto ? beanPinto : variety;
    }

    return beanPinto;
  }

  /// Resuelve el ícono por tipo de tomate. Los IDs canónicos son
  /// tm_01..tm_05 y tm_gen; también se aceptan alias textuales comunes.
  static String tomatoIconForVariety({String? varietyId, String? label}) {
    switch (varietyId) {
      case 'tm_01':
        return tomatoSaladetteOpen;
      case 'tm_02':
        return tomatoSaladetteProtected;
      case 'tm_03':
        return tomatoBola;
      case 'tm_04':
        return tomatoCherry;
      case 'tm_05':
        return tomatoRacimo;
      case 'tm_gen':
        return tomatoGeneric;
    }

    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return tomatoGeneric;

    if (normalized.contains('cherry') || normalized.contains('uva')) {
      return tomatoCherry;
    }
    if (normalized.contains('bola') ||
        normalized.contains('redondo') ||
        normalized.contains('beef')) {
      return tomatoBola;
    }
    if (normalized.contains('racimo') ||
        normalized.contains('tov') ||
        normalized.contains('truss')) {
      return tomatoRacimo;
    }
    if (normalized.contains('saladette') ||
        normalized.contains('roma') ||
        normalized.contains('pera')) {
      if (normalized.contains('protegido') ||
          normalized.contains('invernadero') ||
          normalized.contains('malla')) {
        return tomatoSaladetteProtected;
      }
      return tomatoSaladetteOpen;
    }
    if (normalized.contains('gen')) return tomatoGeneric;
    return tomatoGeneric;
  }

  static String cucumberIconForVariety({String? varietyId, String? label}) {
    final normalizedId = (varietyId ?? '').trim().toLowerCase();
    if (normalizedId.startsWith('cucumber_') || normalizedId.startsWith('pe')) {
      return cropCucumber;
    }

    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized.contains('pepino') ||
        normalized.contains('cucumber') ||
        normalized.contains('slicer') ||
        normalized.contains('europeo') ||
        normalized.contains('ingles') ||
        normalized.contains('inglés') ||
        normalized.contains('persa') ||
        normalized.contains('persian') ||
        normalized.contains('pickler') ||
        normalized.contains('pepinillo')) {
      return cropCucumber;
    }

    return cropCucumber;
  }

  static String cucumberTypedIconForVariety({
    String? varietyId,
    String? label,
  }) {
    final normalizedId = (varietyId ?? '').trim().toLowerCase();

    switch (normalizedId) {
      case 'cucumber_slicer_ca':
      case 'pe_01':
      case 'pe-01':
      case 'pe01':
        return cucumberSlicer;
      case 'cucumber_european_protected':
      case 'pe_02':
      case 'pe-02':
      case 'pe02':
        return cucumberEnglishProtected;
      case 'cucumber_persian':
      case 'pe_03':
      case 'pe-03':
      case 'pe03':
        return cucumberPersianMini;
      case 'cucumber_pickler':
      case 'pe_04':
      case 'pe-04':
      case 'pe04':
        return cucumberCornichonPickling;
      case 'cucumber_generic':
      case 'pe_gen':
      case 'pe-gen':
      case 'pegen':
        return cropCucumber;
    }

    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized.contains('pickler') ||
        normalized.contains('cornichon') ||
        normalized.contains('cornichón') ||
        normalized.contains('encurtido') ||
        normalized.contains('pepinillo')) {
      return cucumberCornichonPickling;
    }
    if (normalized.contains('persa') ||
        normalized.contains('persian') ||
        normalized.contains('mini') ||
        normalized.contains('beit')) {
      return cucumberPersianMini;
    }
    if (normalized.contains('slicer') ||
        normalized.contains('americano') ||
        normalized.contains('criollo')) {
      return cucumberSlicer;
    }
    if (normalized.contains('europeo') ||
        normalized.contains('ingles') ||
        normalized.contains('inglés') ||
        normalized.contains('english') ||
        normalized.contains('protegido')) {
      return cucumberEnglishProtected;
    }

    return cropCucumber;
  }

  static String chiliTypedIconForVariety({String? varietyId, String? label}) {
    final normalizedId = (varietyId ?? '').trim().toLowerCase();

    switch (normalizedId) {
      case 'chili_jalapeno':
      case 'ch_01':
      case 'ch-01':
      case 'ch01':
        return chiliJalapeno;
      case 'chili_serrano':
      case 'ch_02':
      case 'ch-02':
      case 'ch02':
        return chiliSerrano;
      case 'chili_poblano_ancho':
      case 'ch_03':
      case 'ch-03':
      case 'ch03':
        return chiliPoblanoAncho;
      case 'chili_chilaca_pasilla':
      case 'ch_04':
      case 'ch-04':
      case 'ch04':
        return chiliChilacaPasilla;
      case 'chili_guajillo_mirasol':
      case 'ch_05':
      case 'ch-05':
      case 'ch05':
        return chiliGuajilloMirasol;
      case 'chili_arbol_puya':
      case 'ch_06':
      case 'ch-06':
      case 'ch06':
        return chiliArbolPuya;
      case 'chili_habanero':
      case 'ch_07':
      case 'ch-07':
      case 'ch07':
        return chiliHabanero;
      case 'chili_bell_pepper':
      case 'ch_08':
      case 'ch-08':
      case 'ch08':
        return chiliBellPepper;
      case 'chili_generic':
      case 'ch_gen':
      case 'ch-gen':
      case 'chgen':
        return chiliGeneric;
    }

    final normalized = (label ?? '').trim().toLowerCase();
    if (normalized.contains('jalapeno') || normalized.contains('chipotle')) {
      return chiliJalapeno;
    }
    if (normalized.contains('serrano')) return chiliSerrano;
    if (normalized.contains('poblano') ||
        normalized.contains('ancho') ||
        normalized.contains('mulato')) {
      return chiliPoblanoAncho;
    }
    if (normalized.contains('chilaca') || normalized.contains('pasilla')) {
      return chiliChilacaPasilla;
    }
    if (normalized.contains('guajillo') || normalized.contains('mirasol')) {
      return chiliGuajilloMirasol;
    }
    if (normalized.contains('arbol') || normalized.contains('puya')) {
      return chiliArbolPuya;
    }
    if (normalized.contains('habanero')) return chiliHabanero;
    if (normalized.contains('morron') ||
        normalized.contains('morrón') ||
        normalized.contains('gordo') ||
        normalized.contains('pimiento') ||
        normalized.contains('bell')) {
      return chiliBellPepper;
    }
    if (normalized.contains('gen') || normalized.contains('otro')) {
      return chiliGeneric;
    }

    return cropChili;
  }

  static String eggplantTypedIconForVariety({
    String? varietyId,
    String? label,
  }) {
    final normalizedId = (varietyId ?? '').trim().toLowerCase();

    switch (normalizedId) {
      case 'eggplant_long_purple':
      case 'be_01':
      case 'be-01':
      case 'be01':
        return eggplantLongPurple;
      case 'eggplant_italian_purple':
        return eggplantItalianBlack;
      case 'eggplant_oval_round':
      case 'be_02':
      case 'be-02':
      case 'be02':
        return eggplantOvalRound;
      case 'eggplant_striped':
      case 'be_03':
      case 'be-03':
      case 'be03':
        return eggplantStriped;
      case 'eggplant_white':
      case 'be_04':
      case 'be-04':
      case 'be04':
        return eggplantWhite;
      case 'eggplant_generic':
      case 'be_gen':
      case 'be-gen':
      case 'begen':
        return eggplantGeneric;
    }

    final normalized = (label ?? '').trim().toLowerCase();

    if (normalized.contains('italiana') ||
        normalized.contains('italian') ||
        normalized.contains('clasica') ||
        normalized.contains('clásica') ||
        normalized.contains('black beauty')) {
      return eggplantItalianBlack;
    }

    if (normalized.contains('larga') ||
        normalized.contains('semilarga') ||
        normalized.contains('morada larga') ||
        normalized.contains('larga morada') ||
        normalized.contains('barcelona') ||
        normalized.contains('dark night') ||
        normalized.contains('orestia') ||
        normalized.contains('napoli') ||
        normalized.contains('nápoli') ||
        normalized.contains('oriental') ||
        normalized.contains('china')) {
      return eggplantLongPurple;
    }

    if (normalized.contains('oval') ||
        normalized.contains('bola') ||
        normalized.contains('americana') ||
        normalized.contains('morada grande') ||
        normalized.contains('night shadow') ||
        normalized.contains('emma')) {
      return eggplantOvalRound;
    }

    if (normalized.contains('rayada') ||
        normalized.contains('listada') ||
        normalized.contains('jaspeada') ||
        normalized.contains('graffiti') ||
        normalized.contains('grafiti')) {
      return eggplantStriped;
    }

    if (normalized.contains('blanca') || normalized.contains('white')) {
      return eggplantWhite;
    }

    if (normalized.contains('gen') ||
        normalized.contains('otra') ||
        normalized.contains('no se') ||
        normalized.contains('no sé')) {
      return eggplantGeneric;
    }

    return cropEggplant;
  }

  static const String stagePlanned =
      'assets/icons/wizard/ic_aun_no_siembro.png';
  static const String stagePlanted = 'assets/icons/wizard/ic_ya_sembrado.png';
  static const String stageSkip = 'assets/icons/wizard/ic_ya_coseche.png';
}

class WizardTopChrome extends StatelessWidget {
  const WizardTopChrome({
    super.key,
    required this.showBack,
    required this.currentIndex,
    this.totalSteps = 4,
    required this.onBack,
    required this.onClose,
  });

  final bool showBack;
  final int currentIndex;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          _ChromeCircleButton(
            icon: showBack
                ? Icons.arrow_back_ios_new_rounded
                : Icons.close_rounded,
            onTap: showBack ? onBack : onClose,
          ),
          const Spacer(),
          _ProgressDots(currentIndex: currentIndex, totalSteps: totalSteps),
          const Spacer(),
          const SizedBox(width: 42, height: 42),
        ],
      ),
    );
  }
}

class _ChromeCircleButton extends StatelessWidget {
  const _ChromeCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 16,
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: const Color(0xFF274A44)),
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.currentIndex, required this.totalSteps});

  final int currentIndex;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          totalSteps,
          (index) => AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: index == currentIndex ? 18 : 7,
            height: 7,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 6),
            decoration: BoxDecoration(
              color: index == currentIndex
                  ? const Color(0xFF82A775)
                  : Colors.black.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
      ),
    );
  }
}

class CenteredWizardPage extends StatelessWidget {
  const CenteredWizardPage({
    super.key,
    required this.child,
    this.scrollable = true,
    this.topPadding = 0,
    this.horizontalPadding = 18,
  });

  final Widget child;
  final bool scrollable;
  final double topPadding;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            topPadding,
            horizontalPadding,
            12,
          ),
          child: child,
        ),
      ),
    );

    if (!scrollable) return content;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 2),
      child: content,
    );
  }
}

class BrandMark extends StatelessWidget {
  final double? width;
  final double? height;
  const BrandMark({super.key, this.width = 196, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      ConfigureSeedWizardAssets.logoPath,
      width: height == null ? width : null,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}

class MiniStateChip extends StatelessWidget {
  const MiniStateChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF95B488).withValues(alpha: 0.50),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12.4,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B8E62),
        ),
      ),
    );
  }
}

class WizardLongPill extends StatelessWidget {
  const WizardLongPill({
    super.key,
    required this.iconPath,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String iconPath;
  final String title;
  final String subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF8EB07C)
        : Colors.white.withValues(alpha: 0.94);

    final bgColor = selected
        ? const Color(0xFFF0F7EE).withValues(alpha: 0.96)
        : const Color(0xFFF7F8F8).withValues(alpha: 0.94);

    return Opacity(
      opacity: enabled ? 1 : 0.62,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: BioGGlassCard(
          radius: 22,
          backgroundColor: bgColor,
          borderColor: borderColor,
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
          child: Row(
            children: [
              WizardAssetIcon(
                assetPath: iconPath,
                slotWidth: 44,
                slotHeight: 44,
                imageWidth: 44,
                imageHeight: 44,
                scale: 1.95,
                offsetX: -10,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16.2,
                        height: 1.18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                        color: Color(0xFF303836),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13.6,
                          color: Colors.black.withValues(alpha: 0.44),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: selected
                    ? const Color(0xFF8DB379)
                    : const Color(0xFF9AB58A),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SelectionPill extends StatelessWidget {
  const SelectionPill({
    super.key,
    required this.iconPath,
    required this.title,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String iconPath;
  final String title;
  final String value;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selectedBg = const Color(0xFFF0F7EE).withValues(alpha: 0.96);
    final normalBg = const Color(0xFFF7F8F8).withValues(alpha: 0.94);

    return Opacity(
      opacity: onTap == null && !selected ? 0.84 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: BioGGlassCard(
          radius: 22,
          backgroundColor: selected ? selectedBg : normalBg,
          borderColor: selected
              ? const Color(0xFF8EB07C)
              : Colors.white.withValues(alpha: 0.94),
          padding: const EdgeInsets.fromLTRB(18, 13, 16, 13),
          child: Row(
            children: [
              WizardAssetIcon(
                assetPath: iconPath,
                slotWidth: 44,
                slotHeight: 44,
                imageWidth: 44,
                imageHeight: 44,
                scale: 1.95,
                offsetX: -10,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.1,
                              color: Color(0xFF303836),
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 8),
                          const _MiniInlineSelectedChip(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                onTap == null
                    ? (selected
                          ? Icons.check_circle_rounded
                          : Icons.lock_outline_rounded)
                    : Icons.chevron_right_rounded,
                color: selected
                    ? const Color(0xFF8DB379)
                    : const Color(0xFF9AB58A),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FlexibleDateCard extends StatelessWidget {
  const FlexibleDateCard({
    super.key,
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: BioGGlassCard(
        radius: 22,
        backgroundColor: selected
            ? const Color(0xFFF0F7EE).withValues(alpha: 0.98)
            : const Color(0xFFF7F8F8).withValues(alpha: 0.94),
        borderColor: selected
            ? const Color(0xFF8EB07C)
            : Colors.white.withValues(alpha: 0.94),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFEAF7EE)
                    : Colors.white.withValues(alpha: 0.74),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF9DB691)
                      : Colors.black.withValues(alpha: 0.10),
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 20,
                      color: Color(0xFF7EA176),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 15.2,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3F4B48),
                          ),
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Flexible',
                            style: TextStyle(
                              fontSize: 10.8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF6B8E62),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13.4,
                        height: 1.34,
                        color: Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WizardSheetOption<T> {
  const WizardSheetOption({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.enabled,
  });

  final T value;
  final String title;
  final String subtitle;
  final String iconPath;
  final bool enabled;
}

class WizardSheetSelectionTile<T> extends StatelessWidget {
  const WizardSheetSelectionTile({
    super.key,
    required this.option,
    required this.onTap,
  });

  final WizardSheetOption<T> option;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: option.enabled ? 1 : 0.56,
      child: GestureDetector(
        onTap: onTap,
        child: BioGGlassCard(
          radius: 20,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          boxShadows: const <BoxShadow>[],
          backgroundColor: const Color(0xFFF4F7F6).withValues(alpha: 0.96),
          child: Row(
            children: [
              WizardAssetIcon(
                assetPath: option.iconPath,
                slotWidth: 40,
                slotHeight: 40,
                imageWidth: 40,
                imageHeight: 40,
                scale: 1.75,
                offsetX: -8,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: const TextStyle(
                        fontSize: 15.3,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF303836),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: 13.4,
                        color: Colors.black.withValues(alpha: 0.50),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                option.enabled
                    ? Icons.chevron_right_rounded
                    : Icons.lock_outline_rounded,
                color: const Color(0xFF9AB58A),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WizardAssetIcon extends StatelessWidget {
  const WizardAssetIcon({
    super.key,
    required this.assetPath,
    this.slotWidth = 44,
    this.slotHeight = 44,
    this.imageWidth = 44,
    this.imageHeight = 44,
    this.scale = 1.0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  final String assetPath;
  final double slotWidth;
  final double slotHeight;
  final double imageWidth;
  final double imageHeight;
  final double scale;
  final double offsetX;
  final double offsetY;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      child: OverflowBox(
        minWidth: 0,
        minHeight: 0,
        maxWidth: imageWidth * 3,
        maxHeight: imageHeight * 3,
        alignment: Alignment.centerLeft,
        child: Transform.translate(
          offset: Offset(offsetX, offsetY),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerLeft,
            child: Image.asset(
              assetPath,
              width: imageWidth,
              height: imageHeight,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              alignment: Alignment.centerLeft,
            ),
          ),
        ),
      ),
    );
  }
}

class StaggerIn extends StatefulWidget {
  const StaggerIn({
    super.key,
    required this.child,
    this.delay = 0,
    this.offsetY = 12,
    this.offsetX = 0,
    this.duration = const Duration(milliseconds: 600),
  });

  final Widget child;
  final int delay;
  final double offsetY;
  final double offsetX;
  final Duration duration;

  @override
  State<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends State<StaggerIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);

    _slide = Tween<Offset>(
      begin: Offset(widget.offsetX / 100, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _timer = Timer(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

class _MiniInlineSelectedChip extends StatelessWidget {
  const _MiniInlineSelectedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EE),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Listo',
        style: TextStyle(
          fontSize: 10.8,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B8E62),
        ),
      ),
    );
  }
}
