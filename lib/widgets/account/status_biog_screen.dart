import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/services/biog/biog_store.dart';

class StatusBioGScreen extends StatefulWidget {
  final Map<String, dynamic> device;

  const StatusBioGScreen({super.key, required this.device});

  @override
  State<StatusBioGScreen> createState() => _StatusBioGScreenState();
}

class _StatusBioGScreenState extends State<StatusBioGScreen> {
  static const Color kBrandTop = Color(0xFF40BB5F);
  static const Color kBrandMid = Color(0xFF3FAF6E);
  static const Color kBrandBase = Color.fromARGB(137, 43, 126, 101);

  static const String kHeroPng = 'assets/images/biog_image.png';

  static const String kIcBattery = 'assets/icons/metrics/ic_battery.png';
  static const String kIcSensors = 'assets/icons/metrics/ic_riego.png';
  static const String kIcSignal = 'assets/icons/metrics/ic_signal.png';
  static const String kIcSystem = 'assets/icons/metrics/ic_protection.png';

  static const double kHeroScale = 1.45;
  static const double kHeroHeight = 190;

  static const double kIconScale = 3.1;
  static const double kIconSize = 18;
  static const double kIconBox = 24;

  bool _isShowing = false;
  bool _loadingShowingState = true;

  Map<String, dynamic> get device => widget.device;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshShowingState();
  }

  void _refreshShowingState() {
    final id = (device['id'] ?? '').toString().trim();
    final store = BioGScope.of(context);
    final activeId = store.activeDevice?.id ?? '';

    final nextIsShowing = id.isNotEmpty && activeId == id;

    if (_isShowing == nextIsShowing && !_loadingShowingState) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _isShowing = nextIsShowing;
        _loadingShowingState = false;
      });
    });
  }

  Future<void> _setAsShowing() async {
    final id = (device['id'] ?? '').toString().trim();
    if (id.isEmpty) return;

    final store = BioGScope.of(context);
    await store.setActiveDevice(id);

    if (!mounted) return;

    setState(() {
      _isShowing = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device['name'] ?? 'Bio-G'} ahora se está mostrando'),
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    Navigator.pop(context, {'changedDisplayed': true, 'deviceId': id});
  }

  Future<void> _deleteThisBioG() async {
    final id = (device['id'] ?? '').toString().trim();
    final name = (device['name'] ?? 'Bio-G').toString();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          '¿Eliminar Bio-G?',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text('Se eliminará "$name" de tu lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Eliminar',
              style: TextStyle(
                color: Color(0xFFB2554E),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final store = BioGScope.of(context);
    await store.removeDevice(id);

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final name = (device['name'] ?? 'Bio-G').toString();

    final batteryRaw = device['batteryPct'];
    final int battery = (batteryRaw is int)
        ? batteryRaw
        : int.tryParse(batteryRaw?.toString() ?? '') ?? 92;

    final signalLabel = (device['signalLabel'] ?? 'Buena').toString();
    final sensorsLabel = (device['sensorsLabel'] ?? 'OK').toString();
    final systemLabel = (device['systemLabel'] ?? 'Estable').toString();

    final batteryState = battery >= 70
        ? 'Óptima'
        : (battery >= 35 ? 'Media' : 'Baja');
    final batteryTint = battery >= 70
        ? kBrandMid
        : (battery >= 35 ? const Color(0xFFB58B2B) : const Color(0xFFB2554E));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    titleLeft: 'Mis Bio-G',
                    titleBold: name,
                    isShowing: _isShowing,
                    loading: _loadingShowingState,
                    onBack: () => Navigator.pop(context, false),
                  ),
                  const SizedBox(height: 14),
                  _GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: kHeroHeight,
                          width: double.infinity,
                          child: Center(
                            child: Transform.scale(
                              scale: kHeroScale,
                              child: Image.asset(kHeroPng, fit: BoxFit.contain),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Estado del hardware',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E1A16),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Resumen rápido del estado actual del dispositivo.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.black.withValues(alpha:0.55),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _ChipPill(
                              label: 'Batería $battery%',
                              tint: batteryTint,
                            ),
                            _ChipPill(
                              label: 'Señal $signalLabel',
                              tint: kBrandMid,
                            ),
                            _ChipPill(
                              label: 'Sensores $sensorsLabel',
                              tint: kBrandMid,
                            ),
                            _ChipPill(
                              label: 'Sistema $systemLabel',
                              tint: kBrandMid,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: _DisplaySelectorCard(
                      isShowing: _isShowing,
                      loading: _loadingShowingState,
                      onUseThis: _setAsShowing,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _GlassCard(
                    radius: 22,
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                    child: Column(
                      children: [
                        _StatusRowAssetPlain(
                          asset: kIcBattery,
                          iconScale: kIconScale,
                          iconSize: kIconSize,
                          iconBox: kIconBox,
                          leftText: 'Batería: $battery%',
                          rightText: batteryState,
                          rightTint: batteryTint,
                        ),
                        const _DividerLine(),
                        _StatusRowAssetPlain(
                          asset: kIcSignal,
                          iconScale: kIconScale,
                          iconSize: kIconSize,
                          iconBox: kIconBox,
                          leftText: 'Señal: $signalLabel',
                          rightText: signalLabel,
                          rightTint: kBrandMid,
                        ),
                        const _DividerLine(),
                        _StatusRowAssetPlain(
                          asset: kIcSensors,
                          iconScale: kIconScale,
                          iconSize: kIconSize,
                          iconBox: kIconBox,
                          leftText: 'Sensores: $sensorsLabel',
                          rightText: sensorsLabel,
                          rightTint: kBrandMid,
                        ),
                        const _DividerLine(),
                        _StatusRowAssetPlain(
                          asset: kIcSystem,
                          iconScale: kIconScale,
                          iconSize: kIconSize,
                          iconBox: kIconBox,
                          leftText: 'Sistema: $systemLabel',
                          rightText: systemLabel,
                          rightTint: kBrandMid,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _DangerButton(
                    label: 'Eliminar Bio-G',
                    onTap: _deleteThisBioG,
                  ),
                  SizedBox(height: 24 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String titleLeft;
  final String titleBold;
  final bool isShowing;
  final bool loading;
  final VoidCallback onBack;

  const _TopBar({
    required this.titleLeft,
    required this.titleBold,
    required this.isShowing,
    required this.loading,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onBack,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Colors.black.withValues(alpha:0.55),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF0E1A16),
                  ),
                  children: [
                    TextSpan(
                      text: '$titleLeft · ',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha:0.55),
                      ),
                    ),
                    TextSpan(
                      text: titleBold,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              if (!loading)
                _TopStatusChip(
                  label: isShowing ? 'Mostrando' : 'Sin mostrar',
                  isShowing: isShowing,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TopStatusChip extends StatelessWidget {
  final String label;
  final bool isShowing;

  const _TopStatusChip({required this.label, required this.isShowing});

  @override
  Widget build(BuildContext context) {
    final bg = isShowing ? const Color(0xFFEAF7EE) : const Color(0xFFFFF5DA);
    final border = isShowing
        ? const Color(0xFF9FD1AE)
        : const Color(0xFFE0C36B);
    final text = isShowing ? const Color(0xFF2F8F57) : const Color(0xFFB58B2B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border.withValues(alpha:0.9)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.8,
          fontWeight: FontWeight.w900,
          color: text,
        ),
      ),
    );
  }
}

class _DisplaySelectorCard extends StatelessWidget {
  final bool isShowing;
  final bool loading;
  final Future<void> Function() onUseThis;

  const _DisplaySelectorCard({
    required this.isShowing,
    required this.loading,
    required this.onUseThis,
  });

  @override
  Widget build(BuildContext context) {
    final title = isShowing
        ? 'Este Bio-G se está mostrando ahora'
        : 'Este Bio-G no se está mostrando';
    final subtitle = isShowing
        ? 'Los datos visibles en la app corresponden actualmente a este dispositivo.'
        : 'Cámbialo para que la app muestre los datos de este Bio-G.';
    final chipLabel = isShowing ? 'Mostrando' : 'Sin mostrar';
    final chipBg = isShowing
        ? const Color(0xFFEAF7EE)
        : const Color(0xFFFFF5DA);
    final chipText = isShowing
        ? const Color(0xFF2F8F57)
        : const Color(0xFFB58B2B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Visualización actual',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0E1A16),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                chipLabel,
                style: TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w900,
                  color: chipText,
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.6,
                fontWeight: FontWeight.w800,
                color: Color(0xFF23312D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 13.2,
            height: 1.34,
            color: Colors.black.withValues(alpha:0.55),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 14),
        if (loading)
          const SizedBox(
            height: 46,
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          )
        else if (isShowing)
          Container(
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFEAF7EE),
              border: Border.all(color: const Color(0xFFB8DEC5)),
            ),
            child: const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.visibility_rounded,
                    size: 18,
                    color: Color(0xFF2F8F57),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Se está mostrando ahora',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2F8F57),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          _PrimaryShowButton(onTap: onUseThis),
      ],
    );
  }
}

class _PrimaryShowButton extends StatelessWidget {
  final Future<void> Function() onTap;

  const _PrimaryShowButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3FAF6E).withValues(alpha:0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async => onTap(),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF40BB5F).withValues(alpha:0.92),
                    const Color(0xFF2F9E62).withValues(alpha:0.82),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.24),
                  width: 1,
                ),
              ),
              child: const SizedBox(
                height: 46,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Cambiar a mostrar este',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChipPill extends StatelessWidget {
  final String label;
  final Color tint;

  const _ChipPill({required this.label, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tint.withValues(alpha:0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha:0.06)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: tint.withValues(alpha:0.95),
        ),
      ),
    );
  }
}

class _StatusRowAssetPlain extends StatelessWidget {
  final String asset;
  final double iconScale;
  final double iconSize;
  final double iconBox;
  final String leftText;
  final String rightText;
  final Color rightTint;

  const _StatusRowAssetPlain({
    required this.asset,
    required this.iconScale,
    required this.iconSize,
    required this.iconBox,
    required this.leftText,
    required this.rightText,
    required this.rightTint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: iconBox,
            height: iconBox,
            child: Center(
              child: Transform.scale(
                scale: iconScale,
                child: Image.asset(
                  asset,
                  width: iconSize,
                  height: iconSize,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              leftText,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0E1A16),
              ),
            ),
          ),
          Text(
            rightText,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: rightTint,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      width: double.infinity,
      color: Colors.black.withValues(alpha:0.06),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.radius = 20,
    this.padding = const EdgeInsets.all(14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.55),
                width: 1,
              ),
            ),
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF6FAF8), Color(0xFFEFF6F2), Color(0xFFF6FAF8)],
        ),
      ),
      child: Stack(
        children: const [
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(size: 260, opacity: 0.18),
          ),
          Positioned(
            top: 160,
            right: -110,
            child: _GlowBlob(size: 300, opacity: 0.14),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowBlob(size: 340, opacity: 0.16),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowBlob({required this.size, required this.opacity});

  static const Color _brandMid = Color(0xFF3FAF6E);

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _brandMid.withValues(alpha:opacity),
        ),
      ),
    );
  }
}

class _DangerButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _DangerButton({required this.label, required this.onTap});

  static const Color _red = Color(0xFFFF3B30);
  static const Color _deep = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _red.withValues(alpha:0.14),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha:0.10),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_red.withValues(alpha:0.73), _deep.withValues(alpha:0.58)],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha:0.22),
                  width: 1,
                ),
              ),
              child: SizedBox(
                height: 46,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
