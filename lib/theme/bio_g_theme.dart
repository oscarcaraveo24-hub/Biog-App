import 'package:flutter/material.dart';

/// Paleta + gradientes + sombras oficiales Bio-G.
///
/// Regla: cualquier color que se use en ≥2 archivos va aquí.
class BioGTheme {
  BioGTheme._();

  // ===== Brand core =========================================================
  static const Color brandTop = Color(0xFF40BB5F);
  static const Color brandMid = Color(0xFF3FAF6E);
  static const Color brandBaseA = Color.fromARGB(137, 43, 126, 101);
  static const Color brandAccent = Color(0xFF12B886);

  // ===== Greens ==============================================================
  static const Color green50  = Color(0xFFF6FAF8);
  static const Color green100 = Color(0xFFEFF6F2);
  static const Color green200 = Color(0xFFEAF7EE);
  static const Color green300 = Color(0xFFF0F7EE);
  static const Color green400 = Color(0xFFB7E6A5);
  static const Color green500 = Color(0xFF5BC8A4);
  static const Color green600 = Color(0xFF3E9F86);
  static const Color green700 = Color(0xFF2E7D5A);
  static const Color green800 = Color(0xFF2F8F57);
  static const Color teal      = Color(0xFF0E6F5E);

  // ===== Sage / muted greens =================================================
  static const Color sage300  = Color(0xFF9AB58A);
  static const Color sage400  = Color(0xFF8EB07C);
  static const Color sage500  = Color(0xFF8DB379);
  static const Color sage600  = Color(0xFF82A775);
  static const Color sage700  = Color(0xFF6B8E62);
  static const Color mint     = Color(0xFF7ED9BE);

  // ===== Neutrals ============================================================
  static const Color ink       = Color(0xFF0E1A16);
  static const Color charcoal  = Color(0xFF293533);
  static const Color charcoalB = Color(0xFF303836);
  static const Color surface   = Color(0xFFF7F8F8);
  static const Color surfaceAlt= Color(0xFFF6FAF8);

  // ===== Status ==============================================================
  static const Color ok     = brandMid;
  static const Color warn   = Color(0xFFB58B2B);
  static const Color danger = Color(0xFFB2554E);
  static const Color alertRed   = Color(0xFFE85B5B);
  static const Color warmOrange = Color(0xFFF08A5B);
  static const Color warmYellow = Color(0xFFF2C94C);

  // ===== Metric accent =======================================================
  static const Color cyan = Color(0xFF00BCD4);

  // ===== Nav bar =============================================================
  static const Color navGradientTop    = Color.fromARGB(185, 64, 187, 95);
  static const Color navGradientMid    = Color.fromARGB(255, 63, 175, 110);
  static const Color navGradientBottom = Color(0xFF2B7E65);
  static const Color ctaGradientTop    = Color.fromARGB(255, 69, 202, 102);
  static const Color ctaGradientBottom = Color.fromARGB(255, 47, 141, 94);
  static const Color ctaGlow           = Color(0xFF2F8D76);

  // ===== Gradients ===========================================================
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [brandTop, brandMid, brandBaseA],
  );

  static LinearGradient brandGradientDisabled() => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      brandTop.withValues(alpha: 0.14),
      brandMid.withValues(alpha: 0.14),
      brandBaseA.withValues(alpha: 0.14),
    ],
  );

  static const LinearGradient softBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF6FAF8), Color(0xFFEFF6F2), Color(0xFFF6FAF8)],
  );

  // ===== Shadows =============================================================
  static List<BoxShadow> cardShadow({double strength = 1.0}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.14 * strength),
      blurRadius: 30,
      offset: const Offset(0, 18),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> buttonShadow({
    bool enabled = true,
    bool glow = true,
  }) => [
    if (glow && enabled)
      BoxShadow(
        color: brandTop.withValues(alpha: 0.18),
        blurRadius: 22,
        offset: const Offset(0, 12),
        spreadRadius: 0,
      ),
    BoxShadow(
      color: Colors.black.withValues(alpha: enabled ? 0.08 : 0.04),
      blurRadius: enabled ? 24 : 18,
      offset: const Offset(0, 10),
      spreadRadius: 0,
    ),
  ];

  // ===== Text shadows ========================================================
  static List<Shadow> whiteTextShadow({double intensity = 1.0}) => [
    Shadow(
      color: Colors.black.withValues(alpha: 0.30 * intensity),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
    Shadow(
      color: Colors.black.withValues(alpha: 0.18 * intensity),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  // ===== Radii ===============================================================
  static const double rCard = 22;
  static const double rButton = 18;
  static const double rPill = 22;
}
