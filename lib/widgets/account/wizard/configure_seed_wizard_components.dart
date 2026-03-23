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
