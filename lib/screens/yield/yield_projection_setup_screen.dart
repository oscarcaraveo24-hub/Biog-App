import 'package:flutter/material.dart';

import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/yield_projection_config.dart';
import 'package:bio_g/core/yield/yield_projection_engine_proposed.dart';
import 'package:bio_g/core/yield/yield_reference_catalog.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/theme/bio_g_theme.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';

// --- UTILIDAD GLOBAL ---
String formatNumber(double value, {int maxDecimals = 1}) {
  final fixed = value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(maxDecimals);
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    final reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) buffer.write(',');
  }
  return parts.length == 1
      ? buffer.toString()
      : '${buffer.toString()}.${parts[1].replaceFirst(RegExp(r'0+$'), '')}';
}

class YieldProjectionSetupScreen extends StatefulWidget {
  const YieldProjectionSetupScreen({super.key});

  static const String routeName = '/yield/setup';

  @override
  State<YieldProjectionSetupScreen> createState() =>
      _YieldProjectionSetupScreenState();
}

class _YieldProjectionSetupScreenState
    extends State<YieldProjectionSetupScreen> {
  static const String _surfaceIconAsset = 'assets/icons/metrics/ic_surface.png';
  static const String _seedsIconAsset =
      'assets/icons/wizard/ic_planta_generica.png';

  static const double _surfaceIconScale = 3.0;
  static const double _seedsIconScale = 3.0;
  static const double _cropIconScale = 3.0;

  late final TextEditingController _areaController;
  late final TextEditingController _populationController;

  YieldAreaUnit _areaUnit = YieldAreaUnit.hectare;
  YieldOutputMode _outputMode = YieldOutputMode.grain;

  bool _saving = false;
  bool _didLoadInitialValues = false;

  bool _isCalculated = false;
  int _calculationTrigger = 0;

  double _projectedYieldPerUnit = 0.0;
  double _projectedTotalYield = 0.0;
  double _projectedIncome = 0.0;

  String _yieldUnitLabel = 't/ha';
  String _totalUnitLabel = 't';

  @override
  void initState() {
    super.initState();
    _areaController = TextEditingController();
    _populationController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didLoadInitialValues) return;

    final store = BioGScope.of(context);
    final existing = store.activeYieldProjectionConfig;
    final cropContext = store.activeCropContext;

    _areaUnit = existing?.areaUnit ?? _defaultAreaUnitForScale(cropContext);
    _outputMode = _defaultOutputModeForContext(cropContext);
    _areaController.text = _formatNullable(existing?.areaValue);
    _populationController.text = _formatNullable(
      _initialPopulationInputForConfig(existing, _areaUnit),
    );

    final areaVal = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);

    if (areaVal != null &&
        populationInput != null &&
        _areaUnit != YieldAreaUnit.pot) {
      final actualHealthScore = _getActualHealthScore(store);
      _calculateProjections(
        areaVal,
        populationInput,
        cropContext,
        actualHealthScore,
      );
      _isCalculated = true;
      _calculationTrigger++;
    }

    _didLoadInitialValues = true;
  }

  @override
  void dispose() {
    _areaController.dispose();
    _populationController.dispose();
    super.dispose();
  }

  BioGStore _readStore() => BioGScope.of(context);

  double _getActualHealthScore(BioGStore store) {
    const double fallbackScore = 0.68;
    try {
      final double? average = (store as dynamic).cropCareAverage;
      return average ?? store.lastAgroEval?.soilControlScore01 ?? fallbackScore;
    } catch (_) {
      return store.lastAgroEval?.soilControlScore01 ?? fallbackScore;
    }
  }

  void _calculateProjections(
    double area,
    double populationInput,
    DeviceCropContext? ctx,
    double healthScore,
  ) {
    if (ctx == null) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 't/ha';
      _totalUnitLabel = 't';
      return;
    }

    if (_areaUnit == YieldAreaUnit.pot) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 'kg/maceta';
      _totalUnitLabel = 'kg';
      return;
    }

    final reference = _resolveYieldReference(ctx);
    if (reference == null) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 't/ha';
      _totalUnitLabel = 't';
      return;
    }

    final now = DateTime.now();
    final tempConfig = _buildProjectionConfigForInput(
      deviceId: ctx.deviceId,
      cropId: ctx.cropId,
      cultivationScaleId: ctx.cultivationScaleId,
      areaValue: area,
      populationInput: populationInput,
      now: now,
    );

    final estimate = YieldProjectionEngine.estimate(
      reference: reference,
      config: tempConfig,
      historicalCareScore01: _readStore().cropCareAverage,
      currentCareScore01: healthScore,
    );

    if (estimate == null) {
      _projectedTotalYield = 0.0;
      _projectedYieldPerUnit = 0.0;
      _projectedIncome = 0.0;
      _yieldUnitLabel = 't/ha';
      _totalUnitLabel = 't';
      return;
    }

    if (_areaUnit == YieldAreaUnit.hectare) {
      _projectedYieldPerUnit = estimate.projectedMidTonPerHa;
      _projectedTotalYield = estimate.projectedMidTotalTon;
      _yieldUnitLabel = estimate.perHaUnitLabel;
      _totalUnitLabel = estimate.totalUnitLabel;
    } else if (_areaUnit == YieldAreaUnit.squareMeter) {
      _projectedYieldPerUnit = estimate.projectedMidTonPerHa * 0.1;
      _projectedTotalYield = estimate.projectedMidTotalTon * 1000.0;
      _yieldUnitLabel = estimate.isFreshMatter ? 'kg MV/m²' : 'kg/m²';
      _totalUnitLabel = estimate.isFreshMatter ? 'kg MV' : 'kg';
    }

    _projectedIncome = 0.0;
  }

  YieldOutputMode _defaultOutputModeForContext(DeviceCropContext? ctx) {
    if (ctx == null) return YieldOutputMode.grain;
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final profile = ctx.profileId.toLowerCase();
    if (alias.contains('forraj') || profile.contains('forage')) {
      return YieldOutputMode.forage;
    }
    return YieldOutputMode.grain;
  }

  YieldReference? _resolveYieldReference(DeviceCropContext? ctx) {
    if (ctx?.cropId == 'chili') {
      final chiliReference = _resolveChiliYieldReference(ctx!);
      if (chiliReference != null) return chiliReference;
    }
    if (ctx?.cropId == 'eggplant') {
      final eggplantReference = _resolveEggplantYieldReference(ctx!);
      if (eggplantReference != null) return eggplantReference;
    }

    final varietyId = ctx?.varietyId?.trim();
    if (varietyId != null && varietyId.isNotEmpty) {
      final direct = YieldReferenceCatalog.byId[varietyId];
      if (direct != null) {
        if (_outputMode == YieldOutputMode.forage &&
            direct.useType != 'forage') {
          final forageId = varietyId.replaceAll('_grain', '_forage');
          final alt = YieldReferenceCatalog.byId[forageId];
          if (alt != null) return alt;
          return YieldReferenceCatalog.genericForage(ctx!.cropId) ?? direct;
        }
        if (_outputMode == YieldOutputMode.grain &&
            direct.useType == 'forage') {
          final grainId = varietyId.replaceAll('_forage', '_grain');
          final alt = YieldReferenceCatalog.byId[grainId];
          if (alt != null) return alt;
          return YieldReferenceCatalog.genericGrain(ctx!.cropId) ?? direct;
        }
        return direct;
      }
    }
    return _genericYieldReferenceForContext(ctx);
  }

  YieldReference? _resolveChiliYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isGeneric = _containsAny(joined, const [
      'ch-gen',
      'ch_gen',
      'chgen',
      'chili_generic',
      'generico',
      'otro chile',
      'no se',
    ]);
    if (isGeneric) return YieldReferenceCatalog.byId['chili_generic'];

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'malla',
      'protected',
      'chili_protegido',
    ]);
    final wantsDry = _containsAny(joined, const [
      'seco',
      'dry',
      'deshidrat',
      'ancho seco',
      'mulato seco',
    ]);
    final wantsFresh = _containsAny(joined, const [
      'fresco',
      'fresh',
      'verde',
      'chilaca verde',
    ]);

    if (_containsAny(joined, const ['ch-01', 'ch_01', 'ch01', 'jalapeno'])) {
      return YieldReferenceCatalog.byId['chili_jalapeno'];
    }
    if (_containsAny(joined, const ['ch-02', 'ch_02', 'ch02', 'serrano'])) {
      return YieldReferenceCatalog.byId['chili_serrano'];
    }
    if (_containsAny(joined, const [
      'ch-03',
      'ch_03',
      'ch03',
      'poblano',
      'ancho',
      'mulato',
    ])) {
      final explicitDry = variety == 'chili_ancho_dry' ||
          wantsDry ||
          alias.contains('ancho seco') ||
          alias.contains('mulato seco');
      return explicitDry
          ? YieldReferenceCatalog.byId['chili_ancho_dry'] ??
              YieldReferenceCatalog.byId['chili_poblano_ancho']
          : YieldReferenceCatalog.byId['chili_poblano_ancho'];
    }
    if (_containsAny(joined, const [
      'ch-04',
      'ch_04',
      'ch04',
      'chilaca',
      'pasilla',
    ])) {
      final explicitFresh = variety == 'chili_chilaca_fresh' ||
          alias.contains('chilaca verde') ||
          (alias.contains('chilaca') && wantsFresh && !alias.contains('pasilla'));
      final explicitDry = variety == 'chili_chilaca_pasilla' ||
          alias.contains('pasilla') ||
          wantsDry;
      if (explicitFresh && !explicitDry) {
        return YieldReferenceCatalog.byId['chili_chilaca_fresh'] ??
            YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
      }
      return YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
    }
    if (_containsAny(joined, const [
      'ch-05',
      'ch_05',
      'ch05',
      'guajillo',
      'mirasol',
    ])) {
      return YieldReferenceCatalog.byId['chili_guajillo_mirasol'];
    }
    if (_containsAny(joined, const [
      'ch-06',
      'ch_06',
      'ch06',
      'arbol',
      'puya',
    ])) {
      if (variety == 'chili_arbol_fresh' || (wantsFresh && !wantsDry)) {
        return YieldReferenceCatalog.byId['chili_arbol_fresh'] ??
            YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
            YieldReferenceCatalog.byId['chili_arbol_puya'];
      }
      return YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
          YieldReferenceCatalog.byId['chili_arbol_puya'];
    }
    if (_containsAny(joined, const ['ch-07', 'ch_07', 'ch07', 'habanero'])) {
      return YieldReferenceCatalog.byId['chili_habanero'];
    }
    if (_containsAny(joined, const [
      'ch-08',
      'ch_08',
      'ch08',
      'morron',
      'pimiento',
      'chile gordo',
      'bell',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['chili_bell_pepper_protected'] ??
              YieldReferenceCatalog.byId['chili_bell_pepper']
          : YieldReferenceCatalog.byId['chili_bell_pepper'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
            YieldReferenceCatalog.genericFresh(ctx.cropId)
        : YieldReferenceCatalog.genericFresh(ctx.cropId);
  }

  YieldReference? _resolveEggplantYieldReference(DeviceCropContext ctx) {
    final profile = ctx.profileId.toLowerCase();
    final alias = (ctx.varietyAlias ?? '').toLowerCase();
    final variety = (ctx.varietyId ?? '').toLowerCase();
    final calendar = (ctx.calendarTypeId ?? '').toLowerCase();
    final scale = (ctx.cultivationScaleId ?? '').toLowerCase();
    final joined = '$profile $alias $variety $calendar $scale';

    final isGeneric = _containsAny(joined, const [
      'be-gen',
      'be_gen',
      'begen',
      'eggplant_generic',
      'generico',
      'generica',
      'otra berenjena',
      'no se',
      'no sé',
    ]);
    if (isGeneric) return YieldReferenceCatalog.byId['eggplant_generic'];

    final isProtected = _containsAny(joined, const [
      'protegido',
      'invernadero',
      'casa malla',
      'casa sombra',
      'malla',
      'malla sombra',
      'macro tunel',
      'macro túnel',
      'protected',
      'eggplant_protegido',
    ]);

    if (_containsAny(joined, const [
      'be-01',
      'be_01',
      'be01',
      'eggplant_long_purple',
      'larga',
      'semilarga',
      'barcelona',
      'dark night',
      'orestia',
      'napoli',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_long_purple_protected'] ??
              YieldReferenceCatalog.byId['eggplant_long_purple_field']
          : YieldReferenceCatalog.byId['eggplant_long_purple_field'];
    }
    if (_containsAny(joined, const [
      'be-02',
      'be_02',
      'be02',
      'eggplant_oval_round',
      'eggplant_italian_purple',
      'eggplant_italian_black',
      'oval',
      'bola',
      'italiana',
      'italian',
      'clasica',
      'clásica',
      'morada clasica',
      'morada clásica',
      'black beauty',
      'night shadow',
      'emma',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_oval_round_protected'] ??
              YieldReferenceCatalog.byId['eggplant_oval_round_field']
          : YieldReferenceCatalog.byId['eggplant_oval_round_field'];
    }
    if (_containsAny(joined, const [
      'be-03',
      'be_03',
      'be03',
      'eggplant_striped',
      'rayada',
      'listada',
      'graffiti',
      'grafiti',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_striped_protected'] ??
              YieldReferenceCatalog.byId['eggplant_striped_field']
          : YieldReferenceCatalog.byId['eggplant_striped_field'];
    }
    if (_containsAny(joined, const [
      'be-04',
      'be_04',
      'be04',
      'eggplant_white',
      'blanca',
      'white egg',
      'white',
    ])) {
      return isProtected
          ? YieldReferenceCatalog.byId['eggplant_white_protected'] ??
              YieldReferenceCatalog.byId['eggplant_white_field']
          : YieldReferenceCatalog.byId['eggplant_white_field'];
    }

    final direct = YieldReferenceCatalog.byId[variety];
    if (direct != null) return direct;
    return isProtected
        ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
            YieldReferenceCatalog.genericFresh(ctx.cropId)
        : YieldReferenceCatalog.genericFresh(ctx.cropId);
  }

  bool _containsAny(String source, List<String> needles) {
    for (final needle in needles) {
      if (source.contains(needle)) return true;
    }
    return false;
  }

  YieldReference? _genericYieldReferenceForContext(DeviceCropContext? ctx) {
    if (ctx == null) return null;

    if (_outputMode == YieldOutputMode.forage) {
      return YieldReferenceCatalog.genericForage(ctx.cropId) ??
          YieldReferenceCatalog.genericGrain(ctx.cropId);
    }

    switch (ctx.cropId) {
      case 'maize':
        final alias = (ctx.varietyAlias ?? '').toLowerCase();
        final profile = ctx.profileId.toLowerCase();

        if (alias.contains('elote') || profile.contains('elote')) {
          return YieldReferenceCatalog.byId['generic_maize_elote'];
        }
        if (alias.contains('amarill') || profile.contains('yellow')) {
          return YieldReferenceCatalog.byId['generic_maize_yellow_grain'];
        }
        return YieldReferenceCatalog.byId['generic_maize_white_grain'];

      case 'bean':
        return YieldReferenceCatalog.byId['bean_generic'];

      case 'wheat':
        return YieldReferenceCatalog.byId['wheat_generic'];

      case 'barley':
        return YieldReferenceCatalog.byId['barley_generic'];

      case 'oat':
        return YieldReferenceCatalog.byId['oat_generic'];

      case 'tomato':
        // v1: suelo. Protegido vs campo abierto se discrimina por el perfil
        // oficial (TM-02 = protegido, TM-04/05 suelen ser protegido, TM-01
        // campo abierto). TM-GEN usa campo abierto como piso conservador.
        final profile = ctx.profileId.toLowerCase();
        final alias = (ctx.varietyAlias ?? '').toLowerCase();

        final isProtected = profile.contains('tm-02') ||
            profile.contains('tm_02') ||
            profile == 'tm02' ||
            profile.contains('protegido') ||
            alias.contains('protegido') ||
            alias.contains('invernadero') ||
            alias.contains('malla') ||
            profile.contains('tm-04') ||
            profile.contains('tm_04') ||
            profile == 'tm04' ||
            profile.contains('tm-05') ||
            profile.contains('tm_05') ||
            profile == 'tm05';

        return isProtected
            ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
                YieldReferenceCatalog.genericFresh(ctx.cropId)
            : YieldReferenceCatalog.genericFresh(ctx.cropId);

      case 'cucumber':
        final cucumberProfile = ctx.profileId.toLowerCase();
        final cucumberAlias = (ctx.varietyAlias ?? '').toLowerCase();

        final isGeneric = cucumberProfile.contains('pe-gen') ||
            cucumberProfile.contains('pe_gen') ||
            cucumberProfile == 'pegen' ||
            cucumberAlias.contains('generico') ||
            cucumberAlias.contains('genérico');

        if (isGeneric) {
          return YieldReferenceCatalog.byId['cucumber_generic'];
        }

        final isPickler = cucumberProfile.contains('pe-04') ||
            cucumberProfile.contains('pe_04') ||
            cucumberProfile == 'pe04' ||
            cucumberAlias.contains('pickler') ||
            cucumberAlias.contains('pickle') ||
            cucumberAlias.contains('pepinillo') ||
            cucumberAlias.contains('encurtido');
        if (isPickler) {
          return YieldReferenceCatalog.byId['cucumber_pickler'];
        }

        final cucumberIsProtected = cucumberProfile.contains('pe-02') ||
            cucumberProfile.contains('pe_02') ||
            cucumberProfile == 'pe02' ||
            cucumberProfile.contains('pe-03') ||
            cucumberProfile.contains('pe_03') ||
            cucumberProfile == 'pe03' ||
            cucumberProfile.contains('protegido') ||
            cucumberAlias.contains('protegido') ||
            cucumberAlias.contains('invernadero') ||
            cucumberAlias.contains('malla') ||
            cucumberAlias.contains('europeo') ||
            cucumberAlias.contains('ingles') ||
            cucumberAlias.contains('inglés') ||
            cucumberAlias.contains('persa') ||
            cucumberAlias.contains('mini') ||
            cucumberAlias.contains('beit');

        final isEuropean = cucumberProfile.contains('pe-02') ||
            cucumberProfile.contains('pe_02') ||
            cucumberProfile == 'pe02' ||
            cucumberAlias.contains('europeo') ||
            cucumberAlias.contains('ingles') ||
            cucumberAlias.contains('inglés');
        if (isEuropean) {
          return YieldReferenceCatalog.byId['cucumber_european_protected'];
        }

        final isPersian = cucumberProfile.contains('pe-03') ||
            cucumberProfile.contains('pe_03') ||
            cucumberProfile == 'pe03' ||
            cucumberAlias.contains('persa') ||
            cucumberAlias.contains('mini') ||
            cucumberAlias.contains('beit');
        if (isPersian) {
          return YieldReferenceCatalog.byId['cucumber_persian'];
        }

        return cucumberIsProtected
            ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
                YieldReferenceCatalog.genericFresh(ctx.cropId)
            : YieldReferenceCatalog.byId['cucumber_slicer_ca'] ??
                YieldReferenceCatalog.genericFresh(ctx.cropId);

      case 'chili':
        final chiliProfile = ctx.profileId.toLowerCase();
        final chiliAlias = (ctx.varietyAlias ?? '').toLowerCase();

        final isGeneric = chiliProfile.contains('ch-gen') ||
            chiliProfile.contains('ch_gen') ||
            chiliProfile == 'chgen' ||
            chiliAlias.contains('generico') ||
            chiliAlias.contains('otro chile') ||
            chiliAlias.contains('no se');
        if (isGeneric) return YieldReferenceCatalog.byId['chili_generic'];

        final isProtected = chiliProfile.contains('protegido') ||
            chiliAlias.contains('protegido') ||
            chiliAlias.contains('invernadero') ||
            chiliAlias.contains('malla') ||
            chiliAlias.contains('casa malla');

        final wantsDry = chiliAlias.contains('seco') ||
            chiliAlias.contains('deshidratado');

        if (chiliProfile.contains('ch-01') ||
            chiliProfile.contains('ch_01') ||
            chiliProfile == 'ch01' ||
            chiliAlias.contains('jalapeno') ||
            chiliAlias.contains('chipotle')) {
          return YieldReferenceCatalog.byId['chili_jalapeno'];
        }
        if (chiliProfile.contains('ch-02') ||
            chiliProfile.contains('ch_02') ||
            chiliProfile == 'ch02' ||
            chiliAlias.contains('serrano')) {
          return YieldReferenceCatalog.byId['chili_serrano'];
        }
        if (chiliProfile.contains('ch-03') ||
            chiliProfile.contains('ch_03') ||
            chiliProfile == 'ch03' ||
            chiliAlias.contains('poblano') ||
            chiliAlias.contains('ancho') ||
            chiliAlias.contains('mulato')) {
          // Destino seco para CH-03 -> ancho/mulato seco.
          if (wantsDry ||
              chiliAlias.contains('ancho') ||
              chiliAlias.contains('mulato')) {
            return YieldReferenceCatalog.byId['chili_ancho_dry'] ??
                YieldReferenceCatalog.byId['chili_poblano_ancho'];
          }
          return YieldReferenceCatalog.byId['chili_poblano_ancho'];
        }
        if (chiliProfile.contains('ch-04') ||
            chiliProfile.contains('ch_04') ||
            chiliProfile == 'ch04' ||
            chiliAlias.contains('chilaca') ||
            chiliAlias.contains('pasilla')) {
          // Chilaca verde fresca vs pasilla seco.
          if (chiliAlias.contains('chilaca') && !wantsDry) {
            return YieldReferenceCatalog.byId['chili_chilaca_fresh'] ??
                YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
          }
          return YieldReferenceCatalog.byId['chili_chilaca_pasilla'];
        }
        if (chiliProfile.contains('ch-05') ||
            chiliProfile.contains('ch_05') ||
            chiliProfile == 'ch05' ||
            chiliAlias.contains('guajillo') ||
            chiliAlias.contains('mirasol')) {
          return YieldReferenceCatalog.byId['chili_guajillo_mirasol'];
        }
        if (chiliProfile.contains('ch-06') ||
            chiliProfile.contains('ch_06') ||
            chiliProfile == 'ch06' ||
            chiliAlias.contains('arbol') ||
            chiliAlias.contains('puya')) {
          final wantsFresh = chiliAlias.contains('fresco') ||
              chiliAlias.contains('fresh') ||
              chiliAlias.contains('verde');
          if (wantsFresh && !wantsDry) {
            return YieldReferenceCatalog.byId['chili_arbol_fresh'] ??
                YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
                YieldReferenceCatalog.byId['chili_arbol_puya'];
          }
          return YieldReferenceCatalog.byId['chili_arbol_puya_dry'] ??
              YieldReferenceCatalog.byId['chili_arbol_puya'];
        }
        if (chiliProfile.contains('ch-07') ||
            chiliProfile.contains('ch_07') ||
            chiliProfile == 'ch07' ||
            chiliAlias.contains('habanero')) {
          return YieldReferenceCatalog.byId['chili_habanero'];
        }
        if (chiliProfile.contains('ch-08') ||
            chiliProfile.contains('ch_08') ||
            chiliProfile == 'ch08' ||
            chiliAlias.contains('morron') ||
            chiliAlias.contains('gordo') ||
            chiliAlias.contains('pimiento') ||
            chiliAlias.contains('bell')) {
          if (isProtected) {
            return YieldReferenceCatalog.byId['chili_bell_pepper_protected'] ??
                YieldReferenceCatalog.byId['chili_bell_pepper'];
          }
          return YieldReferenceCatalog.byId['chili_bell_pepper'];
        }

        return isProtected
            ? YieldReferenceCatalog.genericFreshProtected(ctx.cropId) ??
                YieldReferenceCatalog.genericFresh(ctx.cropId)
            : YieldReferenceCatalog.genericFresh(ctx.cropId);

      case 'eggplant':
        return _resolveEggplantYieldReference(ctx) ??
            YieldReferenceCatalog.genericFresh(ctx.cropId);

      default:
        return null;
    }
  }

  void _changeOutputMode(YieldOutputMode mode) {
    if (_saving || mode == _outputMode) return;

    final store = _readStore();
    final cropContext = store.activeCropContext;
    final areaValue = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);
    final healthScore = _getActualHealthScore(store);

    setState(() {
      _outputMode = mode;
    });

    if (cropContext != null && areaValue != null && populationInput != null) {
      _calculateProjections(
        areaValue,
        populationInput,
        cropContext,
        healthScore,
      );

      setState(() {
        _isCalculated = true;
        _calculationTrigger++;
      });
    } else {
      setState(() {
        _isCalculated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = BioGScope.of(context);
    final activeDevice = store.activeDevice;
    final cropContext = store.activeCropContext;
    final canEdit = activeDevice != null && cropContext != null;

    final areaValue = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);
    final estimatedSeedsPerHa = _estimateSeedsPerHa(
      areaValue: areaValue,
      populationInput: populationInput,
      areaUnit: _areaUnit,
    );
    final estimatedTotalSeeds = _estimateTotalSeeds(
      areaValue: areaValue,
      populationInput: populationInput,
      areaUnit: _areaUnit,
    );

    final YieldReference? activeReference = _resolveYieldReference(cropContext);
    final bool isProjectionSupported = _areaUnit != YieldAreaUnit.pot;
    final bool isReadyToCalculate =
        isProjectionSupported && areaValue != null && populationInput != null;
    final double realHealthScore = _getActualHealthScore(store);
    final bool supportsBothModes =
        cropContext != null &&
        isProjectionSupported &&
        YieldOutputModeSupport.supportsBothModes(cropContext.cropId);

    return Scaffold(
      backgroundColor: BioGTheme.surface,
      appBar: AppBar(
        backgroundColor: BioGTheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Calculadora de Rendimiento',
          style: TextStyle(fontWeight: FontWeight.w900, color: BioGTheme.ink),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _HeroProjectionCard(
                  hasManualBase: areaValue != null && populationInput != null,
                  isCalculated: _isCalculated,
                  isProjectionSupported: isProjectionSupported,
                  animationKey: _calculationTrigger,
                  cropName: _prettyCropName(cropContext?.cropId),
                  targetYieldPerUnit: _projectedYieldPerUnit,
                  yieldUnitLabel: _yieldUnitLabel,
                  targetTotalYield: _projectedTotalYield,
                  totalUnitLabel: _totalUnitLabel,
                  targetIncome: _projectedIncome,
                  healthScore: realHealthScore,
                  supportBadgeLabel: _referenceSupportBadgeLabel(
                    activeReference,
                  ),
                ),
                const SizedBox(height: 24),

                _SectionHeaderWithMode(
                  title: 'Base manual del lote',
                  showModeSelector: supportsBothModes,
                  outputMode: _outputMode,
                  onModeChanged: _saving ? null : _changeOutputMode,
                ),

                const SizedBox(height: 12),

                if (!canEdit)
                  _buildMissingContextCard()
                else ...[
                  _OverviewInfoCard(
                    title: 'Superficie del lote',
                    value: areaValue == null
                        ? 'Aún sin capturar'
                        : '${formatNumber(areaValue)} ${_areaUnitLabelPlural(_areaUnit)}',
                    subtitle: _areaSubtitle(cropContext, _areaUnit),
                    leading: const _AssetGlyph(
                      assetPath: _surfaceIconAsset,
                      scale: _surfaceIconScale,
                      size: 24,
                      dx: 27,
                      dy: 20,
                    ),
                    trailing: _EditPillButton(
                      label: 'Editar',
                      onTap: _saving ? null : () => _editArea(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _OverviewInfoCard(
                    title: _populationCardTitle(_areaUnit),
                    value: populationInput == null
                        ? 'Aún sin capturar'
                        : _populationCardValue(
                            populationInput: populationInput,
                            areaUnit: _areaUnit,
                          ),
                    subtitle: _populationCardSubtitle(
                      areaValue: areaValue,
                      populationInput: populationInput,
                      estimatedSeedsPerHa: estimatedSeedsPerHa,
                      estimatedTotalSeeds: estimatedTotalSeeds,
                    ),
                    leading: const _AssetGlyph(
                      assetPath: _seedsIconAsset,
                      scale: _seedsIconScale,
                      size: 24,
                      dx: 25,
                      dy: 30,
                    ),
                    trailing: _EditPillButton(
                      label: 'Editar',
                      onTap: _saving ? null : () => _editPopulationInput(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: _showVarietyInfoDialog,
                    child: _OverviewInfoCard(
                      title: 'Variedad de semilla',
                      value: _varietyTitle(cropContext),
                      subtitle: _varietySubtitle(cropContext),
                      leading: _AssetGlyph(
                        assetPath: _cropIconAssetFor(cropContext),
                        scale: _cropIconScale,
                        size: 24,
                        dx: 27,
                        dy: 20,
                      ),
                      trailing: const _ReadOnlyTag('Wizard'),
                    ),
                  ),
                ],

                const SizedBox(height: 18),
                _InlineInfoText(
                  ready: isReadyToCalculate,
                  isCalculated: _isCalculated,
                  unsupported: !isProjectionSupported,
                  supportNote: _projectionSupportNote(activeReference),
                ),
              ],
            ),
          ),
          _buildStickyBottomBar(
            canEdit: canEdit,
            isReady: isReadyToCalculate,
            isProjectionSupported: isProjectionSupported,
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar({
    required bool canEdit,
    required bool isReady,
    required bool isProjectionSupported,
  }) {
    final label = !isProjectionSupported
        ? 'Proyección por maceta próximamente'
        : (_isCalculated ? 'Recalcular Proyección' : 'Calcular Proyección');

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: BioGTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BioGButton(
        label: label,
        loading: _saving,
        onTap: (!canEdit || !isReady || !isProjectionSupported || _saving)
            ? null
            : () => _save(),
      ),
    );
  }

  void _showVarietyInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: BioGGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 76,
                  child: Center(
                    child: Transform.scale(
                      scale: 3.3,
                      child: Image.asset(
                        'assets/icons/wizard/ic_configurar_cultivo.png',
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Variedad Inteligente',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                    color: BioGTheme.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'El modelo matemático de BIO-G se adapta a la genética específica de tu semilla.\n\nPara cambiar la variedad y ajustar el cálculo, debes reconfigurarla directamente desde el Wizard del dispositivo.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                    color: BioGTheme.ink.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          side: BorderSide(
                            color: BioGTheme.brandMid.withValues(alpha: 0.22),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Entendido',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: BioGTheme.teal,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BioGButton(
                        label: 'Ir al Wizard',
                        onTap: () {
                          Navigator.of(ctx).pop();
                          Navigator.of(context).pushNamed('/account');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMissingContextCard() {
    return BioGGlassCard(
      radius: BioGTheme.rCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: BioGTheme.warmOrange,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Sin cultivo activo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: BioGTheme.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Para usar la calculadora necesitas configurar el cultivo desde el wizard del dispositivo primero.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: BioGTheme.ink.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _editArea() async {
    final result = await _showNumberEditor(
      title: 'Editar superficie del lote',
      helper:
          'La unidad se toma automáticamente desde el tipo de dispositivo. Aquí solo ajustas la cantidad.',
      label: 'Superficie (${_areaUnitLabelPlural(_areaUnit)})',
      initialValue: _areaController.text,
      hint: _areaHintForUnit(_areaUnit),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (!mounted || result == null) return;
    setState(() => _areaController.text = result);
    _resetCalculation();
  }

  Future<void> _editPopulationInput() async {
    final result = await _showNumberEditor(
      title: _populationEditorTitle(_areaUnit),
      helper: _populationEditorHelper(_areaUnit),
      label: _populationEditorLabel(_areaUnit),
      initialValue: _populationController.text,
      hint: _populationHintForUnit(_areaUnit),
      keyboardType: TextInputType.numberWithOptions(
        decimal: _areaUnit == YieldAreaUnit.squareMeter,
      ),
    );
    if (!mounted || result == null) return;
    setState(() => _populationController.text = result);
    _resetCalculation();
  }

  void _resetCalculation() {
    if (_isCalculated) {
      setState(() => _isCalculated = false);
    }
  }

  Future<String?> _showNumberEditor({
    required String title,
    required String helper,
    required String label,
    required String initialValue,
    required String hint,
    required TextInputType keyboardType,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final controller = TextEditingController(text: initialValue);
        final formKey = GlobalKey<FormState>();

        return Padding(
          padding: EdgeInsets.fromLTRB(
            14,
            0,
            14,
            MediaQuery.of(sheetContext).viewInsets.bottom + 14,
          ),
          child: BioGGlassCard(
            radius: 26,
            padding: const EdgeInsets.all(22),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: BioGTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    helper,
                    style: TextStyle(
                      fontSize: 13.3,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: BioGTheme.ink.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: keyboardType,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: BioGTheme.ink,
                    ),
                    validator: (value) {
                      if (_parsePositive(value) == null) {
                        return 'Captura un valor válido.';
                      }
                      return null;
                    },
                    decoration: _sheetInputDecoration(label: label, hint: hint),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            side: BorderSide(
                              color: BioGTheme.brandMid.withValues(alpha: 0.22),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                BioGTheme.rButton,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: BioGTheme.teal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: BioGButton(
                          label: 'Aplicar',
                          onTap: () {
                            if (formKey.currentState?.validate() ?? false) {
                              Navigator.of(
                                sheetContext,
                              ).pop(controller.text.trim());
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _sheetInputDecoration({
    required String label,
    required String hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(
        fontWeight: FontWeight.w700,
        color: BioGTheme.ink.withValues(alpha: 0.6),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: BioGTheme.brandMid.withValues(alpha: 0.15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: BioGTheme.brandMid, width: 2.0),
      ),
    );
  }

  Future<void> _save() async {
    final store = _readStore();
    final activeDevice = store.activeDevice;
    final cropContext = store.activeCropContext;
    final existing = store.activeYieldProjectionConfig;

    if (activeDevice == null || cropContext == null) return;
    if (_areaUnit == YieldAreaUnit.pot) {
      _showMessage(
        'La proyección para maceta aún no está disponible. Por ahora la calculadora proyecta campo y huerto.',
      );
      return;
    }

    final areaValue = _parsePositive(_areaController.text);
    final populationInput = _parsePositive(_populationController.text);

    if (areaValue == null || populationInput == null) return;

    final actualHealthScore = _getActualHealthScore(store);
    _calculateProjections(
      areaValue,
      populationInput,
      cropContext,
      actualHealthScore,
    );

    setState(() {
      _saving = true;
      _isCalculated = false;
    });

    try {
      final now = DateTime.now();
      final base =
          existing ??
          YieldProjectionConfig.initial(
            deviceId: activeDevice.id,
            cropId: cropContext.cropId,
            cultivationScaleId: cropContext.cultivationScaleId,
            areaUnit: _areaUnit,
            inputMethod: _inputMethodForAreaUnit(_areaUnit),
            now: now,
          );

      final projectionBase = _buildProjectionConfigForInput(
        deviceId: activeDevice.id,
        cropId: cropContext.cropId,
        cultivationScaleId: cropContext.cultivationScaleId,
        areaValue: areaValue,
        populationInput: populationInput,
        now: now,
      );

      final config = base.copyWith(
        cropId: cropContext.cropId,
        cultivationScaleId: cropContext.cultivationScaleId,
        areaValue: projectionBase.areaValue,
        areaUnit: projectionBase.areaUnit,
        inputMethod: projectionBase.inputMethod,
        targetPopulationPerHa: projectionBase.targetPopulationPerHa,
        totalSeedsSown: projectionBase.totalSeedsSown,
        updatedAt: now,
      );

      await store.saveYieldProjectionConfig(config);

      if (!mounted) return;

      setState(() {
        _saving = false;
        _isCalculated = true;
        _calculationTrigger++;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('Error al calcular la proyección.');
    }
  }

  YieldAreaUnit _defaultAreaUnitForScale(DeviceCropContext? cropContext) {
    switch (cropContext?.cultivationScaleId) {
      case 'bed':
        return YieldAreaUnit.squareMeter;
      case 'pot':
        return YieldAreaUnit.pot;
      default:
        return YieldAreaUnit.hectare;
    }
  }

  double? _initialPopulationInputForConfig(
    YieldProjectionConfig? existing,
    YieldAreaUnit areaUnit,
  ) {
    if (existing == null) return null;

    switch (existing.inputMethod) {
      case YieldInputMethod.populationPerArea:
        final perHa = existing.targetPopulationPerHa;
        if (perHa == null || perHa <= 0) return null;
        return switch (areaUnit) {
          YieldAreaUnit.hectare => perHa,
          YieldAreaUnit.squareMeter => perHa / 10000.0,
          YieldAreaUnit.pot =>
            existing.totalSeedsSown ?? existing.estimatedSeedsSown,
        };

      case YieldInputMethod.totalSeeds:
      case YieldInputMethod.bagsAndSeedsPerBag:
        final totalSeeds =
            existing.totalSeedsSown ?? existing.estimatedSeedsSown;
        if (totalSeeds == null || totalSeeds <= 0) return null;

        return switch (areaUnit) {
          YieldAreaUnit.hectare => _estimateSeedsPerHaFromTotalSeeds(
            areaValue: existing.areaValue,
            totalSeeds: totalSeeds,
            areaUnit: areaUnit,
          ),
          YieldAreaUnit.squareMeter =>
            _estimatePopulationPerSquareMeterFromTotalSeeds(
              areaValue: existing.areaValue,
              totalSeeds: totalSeeds,
              areaUnit: areaUnit,
            ),
          YieldAreaUnit.pot => totalSeeds,
        };
    }
  }

  YieldProjectionConfig _buildProjectionConfigForInput({
    required String deviceId,
    required String cropId,
    required String? cultivationScaleId,
    required double areaValue,
    required double populationInput,
    required DateTime now,
  }) {
    final inputMethod = _inputMethodForAreaUnit(_areaUnit);

    if (inputMethod == YieldInputMethod.populationPerArea) {
      return YieldProjectionConfig.initial(
        deviceId: deviceId,
        cropId: cropId,
        cultivationScaleId: cultivationScaleId,
        areaUnit: _areaUnit,
        inputMethod: YieldInputMethod.populationPerArea,
        now: now,
      ).copyWith(
        areaValue: areaValue,
        targetPopulationPerHa: _populationPerHaFromInput(
          populationInput: populationInput,
          areaUnit: _areaUnit,
        ),
        totalSeedsSown: null,
        updatedAt: now,
      );
    }

    return YieldProjectionConfig.initial(
      deviceId: deviceId,
      cropId: cropId,
      cultivationScaleId: cultivationScaleId,
      areaUnit: _areaUnit,
      inputMethod: YieldInputMethod.totalSeeds,
      now: now,
    ).copyWith(
      areaValue: areaValue,
      totalSeedsSown: populationInput,
      targetPopulationPerHa: null,
      updatedAt: now,
    );
  }

  YieldInputMethod _inputMethodForAreaUnit(YieldAreaUnit unit) {
    return unit == YieldAreaUnit.pot
        ? YieldInputMethod.totalSeeds
        : YieldInputMethod.populationPerArea;
  }

  double? _populationPerHaFromInput({
    required double? populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (populationInput == null || populationInput <= 0) return null;
    return switch (areaUnit) {
      YieldAreaUnit.hectare => populationInput,
      YieldAreaUnit.squareMeter => populationInput * 10000.0,
      YieldAreaUnit.pot => null,
    };
  }

  double? _estimateSeedsPerHa({
    required double? areaValue,
    required double? populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (populationInput == null) return null;
    return switch (areaUnit) {
      YieldAreaUnit.hectare => populationInput,
      YieldAreaUnit.squareMeter => populationInput * 10000.0,
      YieldAreaUnit.pot => _estimateSeedsPerHaFromTotalSeeds(
        areaValue: areaValue,
        totalSeeds: populationInput,
        areaUnit: areaUnit,
      ),
    };
  }

  double? _estimatePopulationPerSquareMeterFromTotalSeeds({
    required double? areaValue,
    required double? totalSeeds,
    required YieldAreaUnit areaUnit,
  }) {
    final perHa = _estimateSeedsPerHaFromTotalSeeds(
      areaValue: areaValue,
      totalSeeds: totalSeeds,
      areaUnit: areaUnit,
    );
    if (perHa == null) return null;
    return perHa / 10000.0;
  }

  double? _estimateSeedsPerHaFromTotalSeeds({
    required double? areaValue,
    required double? totalSeeds,
    required YieldAreaUnit areaUnit,
  }) {
    if (areaValue == null || totalSeeds == null) return null;
    final areaInHectares = switch (areaUnit) {
      YieldAreaUnit.hectare => areaValue,
      YieldAreaUnit.squareMeter => areaValue / 10000,
      YieldAreaUnit.pot => null,
    };
    if (areaInHectares == null || areaInHectares <= 0) return null;
    return totalSeeds / areaInHectares;
  }

  double? _estimateTotalSeeds({
    required double? areaValue,
    required double? populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    if (areaValue == null || populationInput == null) return null;
    return switch (areaUnit) {
      YieldAreaUnit.hectare => populationInput * areaValue,
      YieldAreaUnit.squareMeter => populationInput * areaValue,
      YieldAreaUnit.pot => populationInput,
    };
  }

  String _populationCardTitle(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Semillas sembradas por hectárea';
      case YieldAreaUnit.squareMeter:
        return 'Semillas sembradas por m²';
      case YieldAreaUnit.pot:
        return 'Semillas sembradas';
    }
  }

  String _populationCardValue({
    required double populationInput,
    required YieldAreaUnit areaUnit,
  }) {
    switch (areaUnit) {
      case YieldAreaUnit.hectare:
        return '${formatNumber(populationInput)} semillas/ha';
      case YieldAreaUnit.squareMeter:
        return '${formatNumber(populationInput, maxDecimals: 2)} semillas/m²';
      case YieldAreaUnit.pot:
        return '${formatNumber(populationInput)} semillas en total';
    }
  }

  String _populationCardSubtitle({
    required double? areaValue,
    required double? populationInput,
    required double? estimatedSeedsPerHa,
    required double? estimatedTotalSeeds,
  }) {
    if (populationInput == null) {
      return _areaUnit == YieldAreaUnit.pot
          ? 'Captura el total sembrado en tus macetas.'
          : 'Captura la densidad de siembra y BIO-G calculará el total del lote.';
    }

    switch (_areaUnit) {
      case YieldAreaUnit.hectare:
        if (areaValue == null || estimatedTotalSeeds == null) {
          return 'BIO-G multiplicará esta densidad por tu superficie total.';
        }
        return '≈ ${formatNumber(estimatedTotalSeeds)} semillas en ${formatNumber(areaValue)} ha';
      case YieldAreaUnit.squareMeter:
        if (estimatedSeedsPerHa == null || estimatedTotalSeeds == null) {
          return 'BIO-G convertirá esta densidad a población equivalente por hectárea.';
        }
        return '≈ ${formatNumber(estimatedTotalSeeds)} semillas totales • ${formatNumber(estimatedSeedsPerHa)} semillas/ha';
      case YieldAreaUnit.pot:
        return 'Modo maceta: captura simple sin proyección agronómica por hectárea.';
    }
  }

  String _populationEditorTitle(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Editar semillas por hectárea';
      case YieldAreaUnit.squareMeter:
        return 'Editar semillas por m²';
      case YieldAreaUnit.pot:
        return 'Editar semillas sembradas';
    }
  }

  String _populationEditorHelper(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Captura cuántas semillas sembraste por cada hectárea. BIO-G multiplicará esa densidad por la superficie total del lote.';
      case YieldAreaUnit.squareMeter:
        return 'Captura cuántas semillas sembraste por cada metro cuadrado. BIO-G convertirá esta densidad al equivalente por hectárea para estimar el rendimiento.';
      case YieldAreaUnit.pot:
        return 'En maceta seguimos capturando el total sembrado, pero sin aplicar todavía una proyección agronómica por superficie.';
    }
  }

  String _populationEditorLabel(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Semillas por hectárea';
      case YieldAreaUnit.squareMeter:
        return 'Semillas por m²';
      case YieldAreaUnit.pot:
        return 'Total de semillas';
    }
  }

  String _populationHintForUnit(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Ej. 80000';
      case YieldAreaUnit.squareMeter:
        return 'Ej. 8.0';
      case YieldAreaUnit.pot:
        return 'Ej. 24';
    }
  }

  String _areaSubtitle(DeviceCropContext? cropContext, YieldAreaUnit unit) {
    final scaleText = switch (cropContext?.cultivationScaleId) {
      'field' => 'Campo',
      'bed' => 'Huerto',
      'pot' => 'Maceta',
      _ => 'Lote',
    };
    return '$scaleText • ${_areaUnitLabelPlural(unit)} de cultivo';
  }

  String _cropIconAssetFor(DeviceCropContext? cropContext) {
    return OnboardingUiAssets.assetForCrop(cropContext?.cropId);
  }

  String _varietyTitle(DeviceCropContext? cropContext) {
    if (cropContext == null) return 'Sin semilla configurada';
    return cropContext.varietyAlias ?? _prettyCropName(cropContext.cropId);
  }

  String _varietySubtitle(DeviceCropContext? cropContext) {
    if (cropContext == null) return 'Configura desde el wizard';
    final parts = <String>[_prettyCropName(cropContext.cropId)];
    final brand = _prettyId(cropContext.brandId);
    final calendar = _prettyId(cropContext.calendarTypeId);
    if (brand != null) parts.add(brand);
    if (calendar != null) parts.add(calendar);
    return parts.join(' • ');
  }

  String _prettyCropName(String? cropId) {
    switch (cropId) {
      case 'maize':
        return 'Maíz';
      case 'oat':
        return 'Avena';
      case 'wheat':
        return 'Trigo';
      case 'barley':
        return 'Cebada';
      case 'bean':
        return 'Frijol';
      case 'tomato':
        return 'Tomate';
      case 'cucumber':
        return 'Pepino';
      case 'chili':
        return 'Chile';
      default:
        return _prettyId(cropId) ?? 'Cultivo';
    }
  }

  String? _prettyId(String? raw) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) return null;
    return value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((r) => '${r[0].toUpperCase()}${r.substring(1)}')
        .join(' ');
  }

  String _areaHintForUnit(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'Ej. 3.5';
      case YieldAreaUnit.squareMeter:
        return 'Ej. 850';
      case YieldAreaUnit.pot:
        return 'Ej. 4';
    }
  }

  double? _parsePositive(String? raw) {
    if (raw == null) return null;
    final parsed = double.tryParse(raw.trim().replaceAll(',', ''));
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  String _formatNullable(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }

  String _areaUnitLabelPlural(YieldAreaUnit unit) {
    switch (unit) {
      case YieldAreaUnit.hectare:
        return 'hectáreas';
      case YieldAreaUnit.squareMeter:
        return 'm²';
      case YieldAreaUnit.pot:
        return 'macetas';
    }
  }

  String? _referenceSupportBadgeLabel(YieldReference? reference) {
    if (reference == null) return null;
    return switch (reference.confidence) {
      YieldDataConfidence.validated => 'Base validada',
      YieldDataConfidence.calibrated => 'Base calibrada',
      YieldDataConfidence.modeled => 'Base modelada',
    };
  }

  String? _projectionSupportNote(YieldReference? reference) {
    if (_areaUnit == YieldAreaUnit.pot) {
      return 'La escala maceta sigue capturando base manual, pero la proyección agronómica todavía no está soportada.';
    }
    if (reference == null) {
      return null;
    }
    if (reference.useType != 'forage') {
      return null;
    }
    return switch (reference.confidence) {
      YieldDataConfidence.validated =>
        'Modo forraje con base validada para este cultivo.',
      YieldDataConfidence.calibrated =>
        'Modo forraje con base calibrada. Úsalo como aproximación productiva y no como cierre comercial.',
      YieldDataConfidence.modeled =>
        'Modo forraje con base modelada. Tómalo como rango orientativo mientras se fortalece el catálogo.',
    };
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// --- SUBCOMPONENTES DE UI ---

class _CareVisualState {
  final int percent;
  final Color careColor;
  final String careLabel;
  final LinearGradient careGradient;

  const _CareVisualState({
    required this.percent,
    required this.careColor,
    required this.careLabel,
    required this.careGradient,
  });
}

_CareVisualState _careVisualStateFor(double healthScore) {
  final int percent = (healthScore.clamp(0.0, 1.0) * 100).round();

  Color careColor = BioGTheme.brandMid;
  String careLabel = 'Bien';
  LinearGradient careGradient = const LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [Color(0xFFB8D84A), Color(0xFF3FAF6E), Color(0xFF2E7D5A)],
  );

  if (percent <= 20) {
    careColor = const Color(0xFFD64545);
    careLabel = 'Crítico';
    careGradient = const LinearGradient(
      colors: [Color(0xFFFF8A8A), Color(0xFFF05B5B), Color(0xFFD64545)],
    );
  } else if (percent <= 45) {
    careColor = const Color(0xFFE08A2E);
    careLabel = 'Riesgo';
    careGradient = const LinearGradient(
      colors: [Color(0xFFFFC36A), Color(0xFFF2B34A), Color(0xFFE08A2E)],
    );
  } else if (percent <= 70) {
    careColor = const Color(0xFFB68918);
    careLabel = 'Atención';
    careGradient = const LinearGradient(
      colors: [Color(0xFFF2D06B), Color(0xFFE7B84B), Color(0xFFB68918)],
    );
  }

  return _CareVisualState(
    percent: percent,
    careColor: careColor,
    careLabel: careLabel,
    careGradient: careGradient,
  );
}

class _HeroCareImpactBar extends StatelessWidget {
  final double healthScore;
  final bool animate;

  const _HeroCareImpactBar({
    super.key,
    required this.healthScore,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final state = _careVisualStateFor(healthScore);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.show_chart_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.94),
              ),
              const SizedBox(width: 8),
              Text(
                'Impacto del cuidado',
                style: TextStyle(
                  fontSize: 13.2,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: Colors.black.withValues(alpha: 0.18)),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.0,
                      end: animate ? healthScore.clamp(0.0, 1.0) : 0.0,
                    ),
                    duration: const Duration(milliseconds: 1500),
                    curve: Curves.easeOutExpo,
                    builder: (context, value, child) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: state.careGradient,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${state.percent} / 100',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const Text(
                ' • ',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white70,
                ),
              ),
              Text(
                state.careLabel,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.96),
                ),
              ),
              const SizedBox(width: 7),
              Icon(Icons.circle, size: 8, color: state.careColor),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tu manejo real ajusta esta proyección final.',
            style: TextStyle(
              fontSize: 12.2,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewInfoCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Widget leading;
  final Widget? trailing;

  const _OverviewInfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.leading,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return BioGGlassCard(
      radius: BioGTheme.rCard,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          leading,
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: BioGTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 19,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: BioGTheme.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: BioGTheme.ink.withValues(alpha: 0.65),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _HeroProjectionCard extends StatelessWidget {
  final bool hasManualBase;
  final bool isCalculated;
  final bool isProjectionSupported;
  final int animationKey;
  final String cropName;
  final double targetYieldPerUnit;
  final String yieldUnitLabel;
  final double targetTotalYield;
  final String totalUnitLabel;
  final double targetIncome;
  final double healthScore;
  final String? supportBadgeLabel;

  const _HeroProjectionCard({
    super.key,
    required this.hasManualBase,
    required this.isCalculated,
    required this.isProjectionSupported,
    required this.animationKey,
    required this.cropName,
    required this.targetYieldPerUnit,
    required this.yieldUnitLabel,
    required this.targetTotalYield,
    required this.totalUnitLabel,
    required this.targetIncome,
    required this.healthScore,
    this.supportBadgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: BioGTheme.brandGradient,
        boxShadow: BioGTheme.cardShadow(strength: 1.2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Proyección de Cosecha',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$cropName • estimación inteligente',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),

          if (!hasManualBase) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(
                    Icons.calculate_rounded,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Esperando datos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ingresa la superficie y semillas abajo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isProjectionSupported) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Proyección por maceta próximamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Seguimos capturando tu base manual, pero todavía no estimamos rendimiento final por maceta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (hasManualBase && !isCalculated) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Listo para calcular',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Presiona el botón inferior',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _AnimatedCounterText(
                  key: ValueKey('unit_$animationKey'),
                  targetValue: targetYieldPerUnit,
                  fontSize: 62,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: Text(
                    yieldUnitLabel,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.96),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'rendimiento aproximado',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
          ],

          if (hasManualBase && isProjectionSupported) ...[
            const SizedBox(height: 18),
            _HeroCareImpactBar(healthScore: healthScore, animate: true),
          ],

          if (isProjectionSupported) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _HeroStatTile(
                    label: 'Prod. Total',
                    valueWidget: isCalculated
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              _AnimatedCounterText(
                                key: ValueKey('tot_$animationKey'),
                                targetValue: targetTotalYield,
                                fontSize: 19,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  totalUnitLabel,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
                if (targetIncome > 0) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeroStatTile(
                      label: 'Ingreso Est.',
                      valueWidget: isCalculated
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  '\$',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                                const SizedBox(width: 2),
                                _AnimatedCounterText(
                                  key: ValueKey('inc_$animationKey'),
                                  targetValue: targetIncome,
                                  fontSize: 19,
                                  isCurrency: true,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'MXN',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ],
          const SizedBox(height: 18),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroPill(
                icon: Icons.verified_rounded,
                label: hasManualBase
                    ? 'Datos aprox.'
                    : 'Captura la base manual',
              ),
              if (supportBadgeLabel != null)
                _HeroPill(
                  icon: Icons.layers_rounded,
                  label: supportBadgeLabel!,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnimatedCounterText extends StatelessWidget {
  final double targetValue;
  final double fontSize;
  final bool isCurrency;

  const _AnimatedCounterText({
    super.key,
    required this.targetValue,
    this.fontSize = 68,
    this.isCurrency = false,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: targetValue),
      duration: const Duration(milliseconds: 1800),
      curve: Curves.easeOutExpo,
      builder: (context, value, child) {
        String displayValue;
        if (isCurrency) {
          displayValue = formatNumber(value, maxDecimals: 0);
        } else {
          displayValue = value.toStringAsFixed(1);
        }

        return Text(
          displayValue,
          style: TextStyle(
            fontSize: fontSize,
            height: 0.95,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: fontSize > 20 ? -1.0 : -0.5,
          ),
        );
      },
    );
  }
}

class _HeroStatTile extends StatelessWidget {
  final String label;
  final Widget? valueWidget;

  const _HeroStatTile({super.key, required this.label, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          valueWidget ??
              const Text(
                '—',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeaderWithMode extends StatelessWidget {
  final String title;
  final bool showModeSelector;
  final YieldOutputMode outputMode;
  final ValueChanged<YieldOutputMode>? onModeChanged;

  const _SectionHeaderWithMode({
    super.key,
    required this.title,
    required this.showModeSelector,
    required this.outputMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final selector = showModeSelector
            ? _InlineYieldModeSelector(
                mode: outputMode,
                onChanged: onModeChanged,
              )
            : null;

        if (selector == null) {
          return _SectionLabel(title);
        }

        final bool compactRow = constraints.maxWidth >= 350;

        if (compactRow) {
          return Row(
            children: [
              Expanded(child: _SectionLabel(title)),
              const SizedBox(width: 12),
              selector,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionLabel(title),
            const SizedBox(height: 10),
            selector,
          ],
        );
      },
    );
  }
}

class _InlineYieldModeSelector extends StatelessWidget {
  final YieldOutputMode mode;
  final ValueChanged<YieldOutputMode>? onChanged;

  const _InlineYieldModeSelector({
    super.key,
    required this.mode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onChanged == null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: disabled ? 0.65 : 1,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: BioGTheme.brandMid.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _InlineYieldModeOption(
              label: 'Grano',
              selected: mode == YieldOutputMode.grain,
              onTap: disabled
                  ? null
                  : () => onChanged?.call(YieldOutputMode.grain),
            ),
            const SizedBox(width: 4),
            _InlineYieldModeOption(
              label: 'Forraje',
              selected: mode == YieldOutputMode.forage,
              onTap: disabled
                  ? null
                  : () => onChanged?.call(YieldOutputMode.forage),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineYieldModeOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _InlineYieldModeOption({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color fg = selected ? Colors.white : BioGTheme.teal;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? BioGTheme.teal : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.4,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
              color: fg,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineInfoText extends StatelessWidget {
  final bool ready;
  final bool isCalculated;
  final bool unsupported;
  final String? supportNote;

  const _InlineInfoText({
    super.key,
    required this.ready,
    required this.isCalculated,
    this.unsupported = false,
    this.supportNote,
  });

  @override
  Widget build(BuildContext context) {
    final message = unsupported
        ? 'La escala maceta todavía no tiene proyección agronómica. Puedes capturar base manual, pero aún no estimamos rendimiento final por maceta.'
        : (isCalculated
              ? 'Proyección guardada. Estos datos alimentarán tus métricas y alertas.'
              : (ready
                    ? 'Listo para calcular. BIO-G usará estos datos para proyectar un rango productivo.'
                    : 'Faltan parámetros. Toca sobre "Superficie" o "Semillas" para usar la calculadora.'));

    final icon = unsupported
        ? Icons.hourglass_top_rounded
        : (isCalculated
              ? Icons.check_circle_rounded
              : (ready
                    ? Icons.info_outline_rounded
                    : Icons.pending_actions_rounded));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BioGTheme.brandMid.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BioGTheme.brandMid.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: BioGTheme.teal),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              supportNote == null ? message : '$message\n\n$supportNote',
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: BioGTheme.charcoal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: BioGTheme.charcoal,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _ReadOnlyTag extends StatelessWidget {
  final String text;

  const _ReadOnlyTag(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: BioGTheme.brandMid.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: BioGTheme.teal,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.open_in_new_rounded,
            size: 14,
            color: BioGTheme.teal,
          ),
        ],
      ),
    );
  }
}

class _EditPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _EditPillButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: BioGTheme.brandMid.withValues(alpha: 0.18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                  color: BioGTheme.teal,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.edit_rounded, size: 15, color: BioGTheme.teal),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetGlyph extends StatelessWidget {
  final String assetPath;
  final double scale;
  final double size;
  final double dx;
  final double dy;

  const _AssetGlyph({
    super.key,
    required this.assetPath,
    this.scale = 1.0,
    this.size = 24,
    this.dx = 0,
    this.dy = 0,
  });

  @override
  Widget build(BuildContext context) {
    final overflowSize = size * (scale < 1 ? 1 : scale);
    return SizedBox(
      width: size,
      height: size,
      child: OverflowBox(
        alignment: Alignment.centerRight,
        minWidth: size,
        minHeight: size,
        maxWidth: overflowSize,
        maxHeight: overflowSize,
        child: Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.scale(
            scale: scale,
            alignment: Alignment.centerRight,
            child: Image.asset(
              assetPath,
              width: size,
              height: size,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
