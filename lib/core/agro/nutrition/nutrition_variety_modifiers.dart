// lib/core/agro/nutrition/nutrition_variety_modifiers.dart
//
// Puente entre los MODIFICADORES POR VARIEDAD que ya existían y el nuevo motor
// de nutrición.
//
// Los archivos `*_nutrition_modifier.dart` son conocimiento agronómico que la
// Guía v0.4 (§5) manda conservar: qué variedad empuja o frena la prioridad de
// un nutriente en una etapa, y qué cautela práctica le corresponde (una
// cebada maltera no quiere N tardío; un chile de secado quiere K alto en
// llenado). Antes los consumía el motor NPK legacy para inflar o rebajar la
// «presión fenológica» de una lectura cruda. Ahora ajustan la PRIORIDAD por
// etapa —que sale del perfil, no de la sonda— y aportan su cautela al texto
// de la recomendación. Mismo conocimiento, otra autoridad.
import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/apple_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/avocado_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/chili_nutrition_modifier.dart';
import 'package:bio_g/core/agro/eggplant_nutrition_modifier.dart';
import 'package:bio_g/core/agro/garlic_nutrition_modifier.dart';
import 'package:bio_g/core/agro/lemon_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/lettuce_nutrition_modifier.dart';
import 'package:bio_g/core/agro/mango_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/onion_nutrition_modifier.dart';
import 'package:bio_g/core/agro/orange_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/peach_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/pear_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/pistachio_tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/spinach_nutrition_modifier.dart';
import 'package:bio_g/core/agro/squash_nutrition_modifier.dart';
import 'package:bio_g/core/agro/tree_nutrition_modifier.dart';
import 'package:bio_g/core/agro/walnut_tree_nutrition_modifier.dart';

/// Ajuste de prioridad y cautela por variedad, resuelto para un cultivo.
class VarietyNutritionAdjustment {
  const VarietyNutritionAdjustment._({
    required this.adjustPriority,
    required this.cautionFor,
    this.labelEs,
  });

  /// Sin variedad conocida: no ajusta nada y no opina.
  static const VarietyNutritionAdjustment none = VarietyNutritionAdjustment._(
    adjustPriority: _identity,
    cautionFor: _noCaution,
  );

  final double Function(double base, AgroMetricKey nutrient, String? stageKey)
  adjustPriority;

  final String? Function(AgroMetricKey nutrient, String? stageKey) cautionFor;

  /// Nombre del grupo de variedad, si el modificador lo declara.
  final String? labelEs;

  static double _identity(double base, AgroMetricKey n, String? s) => base;
  static String? _noCaution(AgroMetricKey n, String? s) => null;

  /// Resuelve el ajuste para [cropKey] con los datos de perfil/variedad que ya
  /// viajan en el contexto del cultivo.
  static VarietyNutritionAdjustment resolve({
    required String? cropKey,
    String? profileId,
    String? varietyId,
    String? varietyAlias,
    String? calendarId,
  }) {
    final String crop = (cropKey ?? '').trim().toLowerCase();
    if (crop.isEmpty) return none;

    String? clean(String? raw) {
      final String t = (raw ?? '').trim();
      return t.isEmpty ? null : t;
    }

    switch (crop) {
      case 'chili':
      case 'chile':
      case 'pepper':
      case 'crop_chili':
        final m = resolveChiliNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'eggplant':
      case 'berenjena':
      case 'crop_eggplant':
        final m = resolveEggplantNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'squash':
      case 'calabaza':
      case 'crop_squash':
        final m = resolveSquashNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'lettuce':
      case 'lechuga':
      case 'crop_lettuce':
        final m = resolveLettuceNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'spinach':
      case 'espinaca':
      case 'crop_spinach':
        final m = resolveSpinachNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'onion':
      case 'cebolla':
      case 'crop_onion':
        final m = resolveOnionNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'garlic':
      case 'ajo':
      case 'crop_garlic':
        final m = resolveGarlicNutritionModifier(
          profileId: profileId,
          varietyId: varietyId,
          alias: varietyAlias,
          calendarId: calendarId,
        );
        return VarietyNutritionAdjustment._(
          labelEs: m.labelEs,
          adjustPriority: (b, n, s) =>
              m.adjustStagePressure(b, nutrient: n, stageKey: s),
          cautionFor: (n, s) => clean(m.practicalCaution(n, s ?? '')),
        );
      case 'apple_tree':
        return _tree(
          resolveAppleTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'pear_tree':
        return _tree(
          resolvePearTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'peach_tree':
        return _tree(
          resolvePeachTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'walnut_tree':
        return _tree(
          resolveWalnutTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'pistachio_tree':
        return _tree(
          resolvePistachioTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'orange_tree':
        return _tree(
          resolveOrangeTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'lemon_tree':
        return _tree(
          resolveLemonTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'mango_tree':
        return _tree(
          resolveMangoTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      case 'avocado_tree':
        return _tree(
          resolveAvocadoTreeNutritionModifier(
            profileId: profileId,
            varietyId: varietyId,
            alias: varietyAlias,
            calendarId: calendarId,
          ),
        );
      default:
        return none;
    }
  }

  static VarietyNutritionAdjustment _tree(TreeNutritionModifier m) {
    return VarietyNutritionAdjustment._(
      adjustPriority: (double b, AgroMetricKey n, String? s) =>
          m.adjustStagePressure(b, nutrient: n, stageKey: s),
      cautionFor: (AgroMetricKey n, String? s) {
        final String t = m.practicalCaution(n, s).trim();
        return t.isEmpty ? null : t;
      },
    );
  }
}
