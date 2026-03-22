import 'package:flutter/material.dart';

class OnboardingHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? logoAsset;
  final double logoHeight;
  final double? logoWidth;
  final TextAlign textAlign;

  const OnboardingHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.logoAsset,
    this.logoHeight = 72,
    this.logoWidth,
    this.textAlign = TextAlign.center,
  });

  static const String defaultLogoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool hasSubtitle = subtitle != null && subtitle!.trim().isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _HeaderLogo(
          assetPath: logoAsset ?? defaultLogoAsset,
          logoHeight: logoWidth != null ? null : logoHeight,
          logoWidth: logoWidth,
        ),
        const SizedBox(height: 26),
        Text(
          title,
          textAlign: textAlign,
          style: textTheme.headlineSmall?.copyWith(
            fontSize: 25,
            height: 1.16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF253540),
            letterSpacing: -0.45,
          ),
        ),
        if (hasSubtitle) ...<Widget>[
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(
              subtitle!,
              textAlign: textAlign,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w400,
                color: const Color(0xFF61717A),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  final String assetPath;
  final double? logoHeight;
  final double? logoWidth;

  const _HeaderLogo({required this.assetPath, this.logoHeight, this.logoWidth});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: logoHeight,
      width: logoWidth,
      fit: BoxFit.contain,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return Text(
              'BIO-G',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D5E3B),
                letterSpacing: -1.2,
              ),
            );
          },
    );
  }
}
