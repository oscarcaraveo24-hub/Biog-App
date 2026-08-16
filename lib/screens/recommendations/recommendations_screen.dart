// lib/screens/recommendations/recommendations_screen.dart
//
// El motor de humedad de BIO-G, con cara.
//
// ═════════════════════════════════════════════════════════════════════════════
// PARA QUÉ EXISTE ESTA PANTALLA
// ═════════════════════════════════════════════════════════════════════════════
//
// La promesa de BIO-G es que el productor gaste menos agua y menos dinero en
// agua. Esa promesa vive aquí: es la única pantalla dedicada por completo al
// agua —cuánta hay, cuánta falta, cuánta va a caer del cielo y cuánta se va a
// evaporar hoy— y a la decisión que sale de todo eso.
//
// Lo demás —temperatura, clima, avisos de etapa— va debajo, ordenado. Y la
// nutrición NO está aquí a propósito: NPK tiene sus propias pantallas, su
// propio motor y su propio lenguaje. Son dos decisiones que el agricultor toma
// en momentos distintos y con herramientas distintas: la manguera y el saco.
//
// ═════════════════════════════════════════════════════════════════════════════
// LO QUE ESTA PANTALLA NO INVENTA
// ═════════════════════════════════════════════════════════════════════════════
//
// Todo lo que se muestra sale de un dato real:
//
//   · humedad actual .......... `IrrigationDecision.moisturePct` (sensor)
//   · objetivo de la etapa .... `StageTargets.moistureRaw` (catálogo)
//   · decisión de riego ....... el motor, con sus motivos y su vigencia
//   · lluvia .................. `RainOutlook` de Open-Meteo
//   · demanda de agua ......... `et0TodayMm`, verificada contra FAO-56
//
// Lo que el motor todavía NO calcula —la lámina en milímetros y los días que
// faltan para llegar a crítico— **no se muestra**. Requiere textura de suelo y
// profundidad radicular, que la app aún no captura. Cuando existan, las dos
// tarjetas se encienden solas: los huecos están marcados abajo.
//
// ═════════════════════════════════════════════════════════════════════════════
// ICONOS
// ═════════════════════════════════════════════════════════════════════════════
//
// Arte del proyecto, **desnudo y grande**, sin burbuja ni tarjeta alrededor —
// igual que en el Panel, Ambiente y NPK. Un PNG ilustrado dentro de un círculo
// tintado se ve como un icono de sistema; suelto y a buen tamaño se ve como
// BIO-G. Y sin teñir: `ColorFilter.srcIn` los aplanaría a una silueta.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/agro_types.dart';
import 'package:bio_g/core/agro/agronomic_event.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_coordinator.dart';
import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';
import 'package:bio_g/core/agro/water/moisture_trend.dart';
import 'package:bio_g/core/weather/agronomic_weather_snapshot.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/shared/bio_g_page_background.dart';

/// Paleta y rutas, en un solo sitio.
abstract final class _Rx {
  static const Color ink = Color(0xFF17232B);
  static const Color muted = Color(0xFF5F6E78);
  static const Color hair = Color(0x14000000);

  static const Color water = Color(0xFF2E86F0);
  static const Color waterDeep = Color(0xFF1B62C4);
  static const Color waterSoft = Color(0xFF7FC0FA);
  static const Color track = Color(0xFFDDE4EA);

  // ── El idioma de color del agua ────────────────────────────────────────
  //
  // Tres estados, tres colores, en TODA la pantalla: dial, barra, píldora y
  // leyenda. Si alguno hablara distinto, el productor tendría que aprenderse
  // dos códigos para el mismo dato.
  //
  //   AMARILLO ... falta agua para entrar al rango ideal
  //   VERDE ...... está dentro del rango ideal
  //   ROJO ....... sobra agua, por encima del rango ideal
  //
  // El azul queda para el agua que hay pero todavía no llega al ideal, y
  // para el propio elemento "agua" (gota, lluvia). No es un estado.

  /// Falta.
  static const Color lack = Color(0xFFD9A31E);
  static const Color lackDeep = Color(0xFFB0770D);

  /// Dentro del rango.
  static const Color optimal = Color(0xFF3F9D5C);
  static const Color optimalSoft = Color(0xFF5CB877);

  /// Sobra.
  static const Color excess = Color(0xFFC94F3D);
  static const Color excessSoft = Color(0xFFE0796A);

  static const Color sevCritical = Color(0xFFB3402E);
  static const Color sevWarning = Color(0xFF9A5B2A);
  static const Color sevCaution = Color(0xFF8A6A1F);
  static const Color sevInfo = Color(0xFF3F7D3A);

  static const String _m = 'assets/icons/metrics/';
  static const String _w = 'assets/icons/weather/';

  static const String icMoisture = '${_m}ic_moisture.png';
  static const String icRiego = '${_m}ic_riego.png';
  static const String icTemperature = '${_m}ic_temperature.png';
  static const String icPh = '${_m}ic_ph.png';
  static const String icResistance = '${_m}ic_resistance.png';
  static const String icAlert = '${_m}ic_alert.png';
  static const String icBalance = '${_m}ic_balance.png';
  static const String icGrowth = '${_m}ic_plant_growth.png';
  static const String icSiembra = '${_m}ic_siembra.png';
  static const String icProtection = '${_m}ic_protection.png';
  static const String icNpk = '${_m}ic_npk.png';

  static const String icSun = '${_w}ic_solar_uv.png';
  static const String icTime = '${_m}ic_smart_time.png';
  static const String icLocation = '${_m}ic_location.png';
  static const String icFrost = '${_w}ic_weather_frost.png';
  static const String icHeat = '${_w}ic_weather_heatwave.png';
  static const String icAirMoisture = '${_w}ic_air_moisture.png';

  static Color severity(AgronomicEventSeverity s) => switch (s) {
    AgronomicEventSeverity.critical => sevCritical,
    AgronomicEventSeverity.warning => sevWarning,
    AgronomicEventSeverity.caution => sevCaution,
    AgronomicEventSeverity.info => sevInfo,
  };

  static int severityRank(AgronomicEventSeverity s) => switch (s) {
    AgronomicEventSeverity.critical => 3,
    AgronomicEventSeverity.warning => 2,
    AgronomicEventSeverity.caution => 1,
    AgronomicEventSeverity.info => 0,
  };

  static String iconFor(AgronomicEventType t) => switch (t) {
    AgronomicEventType.frostWarning || AgronomicEventType.coldStress => icFrost,
    AgronomicEventType.highAirTemp || AgronomicEventType.heatStress => icHeat,
    AgronomicEventType.lowAirHumidity ||
    AgronomicEventType.highAirHumidity => icAirMoisture,
    AgronomicEventType.stableSoilTemp => icTemperature,
    AgronomicEventType.lowMoisture ||
    AgronomicEventType.highMoisture ||
    AgronomicEventType.stableMoisture => icMoisture,
    AgronomicEventType.irrigationRecommended => icRiego,
    AgronomicEventType.soilCompaction ||
    AgronomicEventType.goodSoilStructure => icResistance,
    AgronomicEventType.lowPh ||
    AgronomicEventType.highPh ||
    AgronomicEventType.stablePh => icPh,
    AgronomicEventType.stageTransition ||
    AgronomicEventType.cropActivated ||
    AgronomicEventType.preSowing => icSiembra,
    AgronomicEventType.genericMode || AgronomicEventType.recovery => icGrowth,
    AgronomicEventType.stableSoil => icBalance,
    _ => icAlert,
  };

  static String relative(DateTime when, DateTime now) {
    final Duration d = now.difference(when);
    if (d.isNegative || d.inMinutes < 1) return 'ahora';
    if (d.inMinutes < 60) return 'hace ${d.inMinutes} min';
    if (d.inHours < 24) return 'hace ${d.inHours} h';
    if (d.inDays == 1) return 'ayer';
    if (d.inDays < 7) return 'hace ${d.inDays} días';
    return '${when.day}/${when.month}';
  }

  static String mm(double v) =>
      v >= 10 ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

/// Lectura de humedad ya interpretada contra el objetivo de la etapa.
///
/// Se calcula una sola vez y la usan el dial, la tarjeta y la barra, para que
/// las tres cuenten exactamente lo mismo.
@immutable
class _MoistureRead {
  const _MoistureRead({
    required this.value,
    required this.range,
    required this.bandEs,
    required this.color,
    required this.fill01,
    required this.optimum01,
    required this.optimumPct,
    required this.lowMax,
    required this.optMin,
    required this.optMax,
    required this.highMin,
  });

  final double value;
  final AgroRange range;
  final String bandEs;
  final Color color;

  /// Posición del valor sobre la escala del dial y de la barra, 0..1.
  final double fill01;

  /// Posición del objetivo sobre esa misma escala.
  final double optimum01;

  /// El objetivo, para escribirlo con letras.
  final double optimumPct;

  /// Las cuatro cotas del objetivo de la etapa, ya normalizadas. Las usan la
  /// barra de zonas y la proyeccion de tendencia.
  final double lowMax;
  final double optMin;
  final double optMax;
  final double highMin;

  /// Puntos porcentuales que faltan para entrar al rango ideal. Negativo si va
  /// por encima.
  double get gapToOptimal => optMin - value;

  bool get isInsideOptimal => value >= optMin && value <= optMax;

  static _MoistureRead? from(double? value, AgroRange? range) {
    if (value == null || range == null) return null;
    if (!value.isFinite) return null;

    // Se normalizan los límites igual que hace el motor: el catálogo puede
    // traerlos cruzados si alguien los editó a mano.
    final double lowMax = math.min(range.lowMax, range.optimalMin);
    final double optMin = math.max(range.lowMax, range.optimalMin);
    final double optMax = math.max(range.optimalMax, optMin);
    final double highMin = math.max(range.highMin, optMax);
    if (highMin <= 0) return null;

    final String band;
    final Color color;
    if (value >= highMin) {
      band = 'Saturado';
      color = _Rx.excess;
    } else if (value > optMax) {
      band = 'Alto';
      color = _Rx.excessSoft;
    } else if (value >= optMin) {
      band = 'Óptimo';
      color = _Rx.optimal;
    } else if (value >= lowMax) {
      band = 'Bajo';
      color = _Rx.lack;
    } else {
      // Ámbar quemado, NO rojo. Antes era terracota y ahora el rojo significa
      // "sobra": un suelo en seco crítico pintado de rojo diría lo contrario
      // de lo que pasa.
      band = 'Crítico';
      color = _Rx.lackDeep;
    }

    return _MoistureRead(
      value: value,
      range: range,
      bandEs: band,
      color: color,
      fill01: (value / highMin).clamp(0.0, 1.0),
      optimum01: (optMin / highMin).clamp(0.0, 1.0),
      optimumPct: optMin,
      lowMax: lowMax,
      optMin: optMin,
      optMax: optMax,
      highMin: highMin,
    );
  }
}

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({
    super.key,
    required this.events,
    this.irrigationDecision,
    this.cropLabel,
    this.moisturePct,
    this.moistureTarget,
    this.stageLabel,
    this.cropIconAsset,
    this.coordinator,
    this.onRefresh,
    this.onOpenEnvironment,
  });

  final List<AgronomicEvent> events;
  final IrrigationDecision? irrigationDecision;
  final String? cropLabel;

  /// Humedad del sensor. Si es null se usa la de la decisión de riego.
  final double? moisturePct;

  /// Objetivo de humedad de la etapa, del catálogo. Sin él no hay dial ni
  /// barra: no se dibuja una escala inventada.
  final AgroRange? moistureTarget;

  /// Etapa del cultivo. Da contexto a todo lo demas: el rango ideal cambia
  /// con ella.
  final String? stageLabel;

  /// Arte del cultivo, el mismo que usa la cabecera del Panel.
  final String? cropIconAsset;

  /// El coordinador de riego, para que esta pantalla se entere de las
  /// decisiones que llegan DESPUÉS de haberse abierto.
  ///
  /// Sin esto la pantalla se queda congelada: una ruta empujada no se
  /// reconstruye porque el Panel se reconstruya, así que la decisión que
  /// recibió al abrirse era la única que iba a ver en toda su vida.
  final IrrigationCoordinator? coordinator;

  /// Refresco de clima y decisión. Se dispara al abrir la pantalla.
  final Future<void> Function()? onRefresh;

  /// Lleva a la pantalla de Entorno. El bloque del pronóstico es un resumen;
  /// quien quiera el pronóstico completo tiene que poder llegar de un toque.
  final VoidCallback? onOpenEnvironment;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance;

  /// Historial reciente, para la tendencia. Es lo unico derivado de esta
  /// pantalla, y por eso sale de lecturas reales y no de una suposicion.
  StreamSubscription<List<BioGTelemetry>>? _historySub;
  List<BioGTelemetry> _history = const <BioGTelemetry>[];
  BioGStore? _store;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();

    // Abrir esta pantalla es la señal más clara de que al usuario le interesa
    // el agua ahora mismo. Se pide un refresco: si el clima todavía no había
    // llegado cuando el Panel empujó la ruta, esta es la única forma de que
    // llegue sin obligarle a salir y volver a entrar.
    final Future<void> Function()? refresh = widget.onRefresh;
    if (refresh != null) {
      WidgetsBinding.instance.addPostFrameCallback((Duration _) {
        if (mounted) unawaited(refresh());
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // `BioGScope` envuelve la app entera, asi que tambien alcanza a las
    // pantallas empujadas: el mismo camino que usan NPK y Estado del Bio-G.
    final BioGStore next = BioGScope.of(context);
    if (identical(next, _store)) return;
    _store = next;
    unawaited(_historySub?.cancel());
    _historySub = next.watchHistory(MoistureTrend.analysisWindow).listen((
      List<BioGTelemetry> rows,
    ) {
      if (!mounted) return;
      setState(() => _history = rows);
    });
  }

  @override
  void dispose() {
    unawaited(_historySub?.cancel());
    _entrance.dispose();
    super.dispose();
  }

  // ── Clasificación de eventos ──────────────────────────────────────────────

  static bool _isNutrition(AgronomicEvent e) => switch (e.type) {
    AgronomicEventType.npkReading ||
    AgronomicEventType.nutrientImbalance ||
    AgronomicEventType.nitrogenLow ||
    AgronomicEventType.nitrogenHigh ||
    AgronomicEventType.phosphorusLow ||
    AgronomicEventType.phosphorusHigh ||
    AgronomicEventType.potassiumLow ||
    AgronomicEventType.potassiumHigh ||
    AgronomicEventType.fertilizationRecommended => true,
    _ => false,
  };

  static bool _isClimate(AgronomicEvent e) => switch (e.type) {
    AgronomicEventType.frostWarning ||
    AgronomicEventType.highAirTemp ||
    AgronomicEventType.lowAirHumidity ||
    AgronomicEventType.highAirHumidity ||
    AgronomicEventType.heatStress ||
    AgronomicEventType.coldStress ||
    AgronomicEventType.stableSoilTemp => true,
    _ => false,
  };

  /// Los eventos de humedad NO entran en las listas de abajo: ya están
  /// contados arriba, en el bloque de agua. Repetirlos sería el ruido que
  /// hace que un agricultor deje de leer.
  static bool _isWater(AgronomicEvent e) => switch (e.type) {
    AgronomicEventType.lowMoisture ||
    AgronomicEventType.highMoisture ||
    AgronomicEventType.stableMoisture ||
    AgronomicEventType.irrigationRecommended => true,
    _ => false,
  };

  List<AgronomicEvent> _pick(bool Function(AgronomicEvent) test) {
    final List<AgronomicEvent> list = widget.events
        .where((AgronomicEvent e) => !_isNutrition(e) && !_isWater(e) && test(e))
        .toList();
    list.sort((AgronomicEvent a, AgronomicEvent b) {
      final int s = _Rx.severityRank(
        b.severity,
      ).compareTo(_Rx.severityRank(a.severity));
      return s != 0 ? s : b.timestamp.compareTo(a.timestamp);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final IrrigationCoordinator? coordinator = widget.coordinator;
    if (coordinator == null) {
      return _buildBody(context, widget.irrigationDecision);
    }
    // Escuchando al coordinador, la decisión que llega tarde —normalmente
    // porque el pronóstico tardó unos segundos en bajar— repinta la pantalla
    // en vez de quedarse fuera.
    return AnimatedBuilder(
      animation: coordinator,
      builder: (BuildContext context, Widget? _) =>
          _buildBody(context, _freshestDecision(coordinator)),
    );
  }

  /// La más reciente entre la que llegó al abrir y la que tiene el
  /// coordinador.
  ///
  /// No es paranoia: el Panel calcula su decisión dentro de `build`, y el
  /// coordinador solo publica la suya al terminar un `sync`. Durante ese hueco
  /// la del coordinador es la vieja, y preferirla a ciegas haría retroceder la
  /// pantalla. Se comparan por `decidedAt` y gana la nueva.
  IrrigationDecision? _freshestDecision(IrrigationCoordinator coordinator) {
    final IrrigationDecision? live = coordinator.decision;
    final IrrigationDecision? pushed = widget.irrigationDecision;
    if (live == null) return pushed;
    if (pushed == null) return live;
    return live.decidedAt.isBefore(pushed.decidedAt) ? pushed : live;
  }

  /// El subtítulo de la cabecera, sin la etapa.
  ///
  /// `cropLabel` llega como "Mango · Floración / panícula" y la etapa ya tiene
  /// su propio bloque en el parte de agua. Repetirla aquí la hacía aparecer
  /// tres veces en la misma pantalla. Se recorta solo cuando la cola coincide
  /// exactamente con la etapa: nada de adivinar por el separador.
  String? _headerSubtitle() {
    final String raw = (widget.cropLabel ?? '').trim();
    if (raw.isEmpty) return null;
    final String stage = (widget.stageLabel ?? '').trim();
    if (stage.isEmpty) return raw;

    final String tail = ' · $stage';
    if (raw.endsWith(tail)) {
      final String head = raw.substring(0, raw.length - tail.length).trim();
      if (head.isNotEmpty) return head;
    }
    return raw;
  }

  Widget _buildBody(BuildContext context, IrrigationDecision? decision) {
    final _MoistureRead? moisture = _MoistureRead.from(
      // La del motor es la más fresca: se recalcula en cada sincronización.
      // La del constructor es la que había al abrir, y sirve de respaldo.
      decision?.moisturePct ?? widget.moisturePct,
      widget.moistureTarget,
    );
    final AgronomicWeatherSnapshot? weather = decision?.weather;

    // Tendencia sobre lecturas reales de las ultimas 48 h. Sin muestras
    // suficientes devuelve `unknown` y la interfaz no la menciona.
    final MoistureTrend trend = moisture == null
        ? const MoistureTrend.unknown()
        : MoistureTrend.from(
            _history,
            now: DateTime.now(),
            criticalThresholdPct: moisture.lowMax,
          );

    final List<AgronomicEvent> climate = _pick(_isClimate);
    final List<AgronomicEvent> other = _pick((AgronomicEvent e) =>
        !_isClimate(e));

    final double bottomPad = MediaQuery.of(context).viewPadding.bottom + 32;

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: <Widget>[
          const BioGPageBackground(enabled: true, particleDensity: 0.7),
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                SliverToBoxAdapter(child: _Header(subtitle: _headerSubtitle())),

                // ── El bloque de agua ─────────────────────────────────────
                if (moisture != null)
                  SliverToBoxAdapter(
                    child: _Reveal(
                      controller: _entrance,
                      begin: 0.00,
                      end: 0.40,
                      child: _MoistureDialHero(read: moisture),
                    ),
                  ),

                if (moisture != null)
                  SliverToBoxAdapter(
                    child: _Reveal(
                      controller: _entrance,
                      begin: 0.12,
                      end: 0.55,
                      child: _SoilMoistureCard(read: moisture, trend: trend),
                    ),
                  ),

                // ── LA LÁMINA ────────────────────────────────────────────
                //
                // Este es el hueco que el encabezado de este archivo declaraba:
                // «lo que el motor todavía NO calcula —la lámina en milímetros
                // y los días que faltan para llegar a crítico— no se muestra.
                // Requiere textura de suelo y profundidad radicular, que la app
                // aún no captura. Cuando existan, las dos tarjetas se encienden
                // solas».
                //
                // Ya existen. Se enciende sola, y sale nula por su cuenta
                // cuando falta cualquier ingrediente: sin textura resuelta, sin
                // lectura presente o con el suelo por encima de capacidad de
                // campo, `decision.depth` es null y esta tarjeta no aparece.
                // Nunca se inventa un número.
                if (decision?.depth != null)
                  SliverToBoxAdapter(
                    child: _Reveal(
                      controller: _entrance,
                      begin: 0.18,
                      end: 0.66,
                      child: _IrrigationDepthCard(depth: decision!.depth!),
                    ),
                  ),

                // Pronóstico, decisión y etapa: una sola tarjeta.
                if (decision != null)
                  SliverToBoxAdapter(
                    child: _Reveal(
                      controller: _entrance,
                      begin: 0.22,
                      end: 0.80,
                      child: _WaterBriefCard(
                        decision: decision,
                        read: moisture,
                        trend: trend,
                        weather: weather,
                        // El motor de riego ya resolvió la etapa para decidir;
                        // si el Panel no la pasó, se usa la suya.
                        stageLabel: widget.stageLabel ?? decision.stageLabel,
                        cropIconAsset: widget.cropIconAsset,
                        onOpenEnvironment: widget.onOpenEnvironment,
                      ),
                    ),
                  ),

                // ── Lo que no es agua ─────────────────────────────────────
                if (climate.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _EventSection(
                      title: 'Temperatura y clima',
                      subtitle: 'Lo que el ambiente le hace al cultivo',
                      iconAsset: _Rx.icTemperature,
                      events: climate,
                    ),
                  ),

                if (other.isNotEmpty)
                  SliverToBoxAdapter(
                    child: _EventSection(
                      title: 'Etapa y estado general',
                      subtitle: 'Cómo va el ciclo del cultivo',
                      iconAsset: _Rx.icGrowth,
                      events: other,
                    ),
                  ),

                if (moisture == null && decision == null && climate.isEmpty &&
                    other.isEmpty)
                  const SliverToBoxAdapter(child: _EmptyState()),

                const SliverToBoxAdapter(child: _NpkFootnote()),
                SliverToBoxAdapter(child: SizedBox(height: bottomPad)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cabecera
// ═══════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final String? sub = subtitle?.trim();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _GlassCircleButton(
            icon: Icons.arrow_back_rounded,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Una sola linea, siempre. En un telefono angosto el titulo
                  // se partia en "Recomendacione / s", que se ve roto.
                  const FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                    'Recomendaciones',
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.6,
                      height: 1.05,
                      color: _Rx.ink,
                    ),
                  ),
                  ),
                  if (sub != null && sub.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        sub,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _Rx.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCircleButton extends StatelessWidget {
  const _GlassCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Material(
          color: Colors.white.withValues(alpha: 0.86),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, size: 23, color: _Rx.ink),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// El dial de humedad
// ═══════════════════════════════════════════════════════════════════════════

class _MoistureDialHero extends StatefulWidget {
  const _MoistureDialHero({required this.read});

  final _MoistureRead read;

  @override
  State<_MoistureDialHero> createState() => _MoistureDialHeroState();
}

class _MoistureDialHeroState extends State<_MoistureDialHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fill;

  @override
  void initState() {
    super.initState();
    _fill = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..forward();
  }

  @override
  void didUpdateWidget(covariant _MoistureDialHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.read.value != widget.read.value) {
      _fill
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _MoistureRead r = widget.read;
    final Animation<double> t = CurvedAnimation(
      parent: _fill,
      curve: Curves.easeOutCubic,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
      child: Column(
        children: <Widget>[
          // `scaleDown` protege en telefonos angostos: 300 + 36 de margen son
          // 336, pero con la fuente del sistema en grande el bloque crece.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
            width: 300,
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                // El globo: un halo suave detrás de la gota, para que el
                // icono no quede flotando sobre el fondo.
                Container(
                  width: 208,
                  height: 208,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.80),
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                      stops: const <double>[0.0, 0.62, 1.0],
                    ),
                  ),
                ),
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: t,
                    builder: (BuildContext context, Widget? child) {
                      return CustomPaint(
                        size: const Size(300, 300),
                        painter: _DialPainter(
                          // Solo el nivel se anima. La zona ideal es la
                          // referencia contra la que se llena, y una
                          // referencia que crece con el nivel no es
                          // referencia.
                          fill01: r.fill01 * t.value,
                          optMin01: (r.optMin / r.highMin).clamp(0.0, 1.0),
                          optMax01: (r.optMax / r.highMin).clamp(0.0, 1.0),
                        ),
                      );
                    },
                  ),
                ),
                // La gota, al doble y con sombra propia.
                //
                // Sube 11 px, y no es un ajuste a ojo: el PNG mide 540x675 y
                // su centroide de opacidad cae un 7.0 % por debajo del centro
                // de la caja —la punta es fina y el bulbo es ancho, asi que la
                // masa visual esta abajo—. Centrada por caja *parece* baja
                // dentro del anillo. Esto corrige el grueso de esa diferencia
                // sin llegar a invertirla, que se veria igual de raro.
                Transform.translate(
                  offset: const Offset(0, -11),
                  child: const _DropWithShadow(size: 200),
                ),
              ],
            ),
          ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Humedad del suelo',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
              color: _Rx.ink,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _DialLegend(
                color: _Rx.water,
                label: 'Actual',
                value: '${r.value.toStringAsFixed(0)}%',
                solid: true,
              ),
              Container(
                width: 1,
                height: 22,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: _Rx.hair,
              ),
              // Antes decía "Óptimo 38 %", que era el borde INFERIOR del
              // rango 38–76: se leía como si el objetivo fuera 38. Y el
              // número ya estaba en la tarjeta de abajo. Ahora dice el
              // estado, con la misma forma y el mismo color que las motas
              // del dial: la leyenda explica el dibujo en vez de repetir un
              // dato.
              if (r.value < r.optMin)
                _DialLegend(
                  color: _Rx.lack,
                  label: 'Falta',
                  value: '${(r.optMin - r.value).toStringAsFixed(0)} pts',
                  solid: false,
                )
              else if (r.value > r.optMax)
                _DialLegend(
                  color: _Rx.excess,
                  label: 'Sobra',
                  value: '${(r.value - r.optMax).toStringAsFixed(0)} pts',
                  solid: true,
                )
              else
                _DialLegend(
                  color: _Rx.optimal,
                  label: 'En rango',
                  solid: true,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La gota con sombra propia.
///
/// La sombra no puede salir de un `BoxShadow`: eso sombrearia la caja, no la
/// silueta del dibujo. Se pinta una copia del PNG teñida de negro, desenfocada
/// y desplazada, y encima va la original. Es la unica forma de que el contorno
/// de la gota proyecte su propia sombra.
class _DropWithShadow extends StatelessWidget {
  const _DropWithShadow({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.translate(
          offset: Offset(0, size * 0.05),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 13, sigmaY: 13),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.26),
                BlendMode.srcIn,
              ),
              child: _Art(asset: _Rx.icMoisture, size: size),
            ),
          ),
        ),
        _Art(asset: _Rx.icMoisture, size: size),
      ],
    );
  }
}

/// Las dos referencias del dial, escritas. Sin esto el usuario ve dos tonos de
/// azul y tiene que adivinar cuál es cuál.
class _DialLegend extends StatelessWidget {
  const _DialLegend({
    required this.color,
    required this.label,
    required this.solid,
    this.value,
  });

  final Color color;
  final String label;
  final bool solid;

  /// Opcional. "En rango" no lleva número: el rango completo ya está en la
  /// tarjeta de abajo y repetirlo aquí era justo lo que se quitó.
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: solid ? color : Colors.transparent,
            border: solid
                ? null
                : Border.all(color: color.withValues(alpha: 0.85), width: 2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: _Rx.muted,
          ),
        ),
        if (value != null) ...<Widget>[
          const SizedBox(width: 5),
          Text(
            value!,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: solid ? _Rx.ink : color,
            ),
          ),
        ],
      ],
    );
  }
}

/// El dial de estallido.
///
/// ─────────────────────────────────────────────────────────────────────────
/// POR QUÉ LOS RADIOS TIENEN LARGOS DISTINTOS
/// ─────────────────────────────────────────────────────────────────────────
///
/// Un anillo de radios iguales se lee como una barra de progreso doblada, y
/// eso ya lo cuenta el anillo del Panel. Variando el largo de cada radio con
/// una función determinista, el conjunto deja de parecer una escala y pasa a
/// parecer una medición: muchas lecturas puntuales, no una sola línea.
///
/// El largo NO es aleatorio en tiempo de ejecución: sale de un hash del índice.
/// Con `Random()` las puntas saltarían de sitio en cada repintado —sesenta
/// veces por segundo durante la animación de llenado— y se vería como ruido.
///
/// ─────────────────────────────────────────────────────────────────────────
/// LAS TRES ZONAS
/// ─────────────────────────────────────────────────────────────────────────
///
///   0 → menor(actual, óptimo) ..... mota sólida: el agua que hay
///   ese tramo → mayor de los dos .. mota hueca: lo que falta para el óptimo
///                                   (o sólida oscura, si va por encima)
///   resto ......................... solo el radio, apagado
///
/// Así el hueco entre lo que hay y lo que debería haber **se ve**, que es
/// justo la información por la que existe esta pantalla.
/// El dial de motas.
///
/// Tres estados, tres formas. Se puede leer sin saber leer:
///
///   · **mota azul sólida** ... agua que hay y que sirve
///   · **aro hueco** ......... agua que falta para entrar al rango ideal
///   · **mota roja** ......... agua de más, por encima del rango ideal
///
/// Antes solo había dos, y el corte estaba mal puesto: el tramo "intermedio"
/// se medía contra `optMin`, o sea contra el BORDE INFERIOR del rango ideal.
/// Con eso, una humedad perfectamente dentro del rango —59 % en un ideal de
/// 38–76— se pintaba entera como "por encima del objetivo". Ahora la carencia
/// se mide contra `optMin` y el exceso contra `optMax`, que es lo que
/// significan.
class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.fill01,
    required this.optMin01,
    required this.optMax01,
  });

  /// Nivel actual sobre la escala del dial, 0..1. Es lo único que se anima.
  final double fill01;

  /// Bordes del rango ideal sobre esa misma escala.
  final double optMin01;
  final double optMax01;

  static const int _spokes = 56;

  /// Resplandor de las motas.
  ///
  /// `MaskFilter.blur` difumina la figura entera antes de pintarla, que es lo
  /// que hace que la mota se funda con el fondo en vez de quedar pegada
  /// encima. Va en `final` y no en `const` a proposito: sale barato y evita
  /// depender de que el constructor siga siendo const.
  static final MaskFilter _dotGlow = MaskFilter.blur(BlurStyle.normal, 3.6);
  static final MaskFilter _dotGlowSoft = MaskFilter.blur(
    BlurStyle.normal,
    2.6,
  );

  /// Largo de cada radio, 0..1, estable entre repintados.
  static final List<double> _jitter = List<double>.generate(_spokes, (int i) {
    final double h = (i * 0.6180339887 + 0.31) % 1.0;
    final double g = (i * 0.7548776662 + 0.77) % 1.0;
    // Dos frecuencias mezcladas: evita que se note un patrón repetido.
    return (0.55 * h + 0.45 * g).clamp(0.0, 1.0);
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double rBase = size.width / 2 - 12;
    // Pegado a la gota. El PNG trae margen transparente, asi que el dibujo
    // visible es bastante mas pequeño que su caja de 200: los radios pueden
    // empezar dentro de esa caja sin tocar el trazo.
    final double rIn = rBase * 0.60;

    final int fillIdx = (fill01 * _spokes).round().clamp(0, _spokes);
    final int minIdx = (optMin01 * _spokes).round().clamp(0, _spokes);
    final int maxIdx = (optMax01 * _spokes).round().clamp(0, _spokes);

    for (int i = 0; i < _spokes; i++) {
      final double a = (-math.pi / 2) + (2 * math.pi * i / _spokes);
      final double cosA = math.cos(a);
      final double sinA = math.sin(a);

      // El largo varía entre el 74 % y el 100 % del radio disponible.
      final double rOut = rBase * (0.74 + 0.20 * _jitter[i]);
      final Offset p1 = Offset(c.dx + rIn * cosA, c.dy + rIn * sinA);
      final Offset p2 = Offset(c.dx + rOut * cosA, c.dy + rOut * sinA);

      // Agua de más: pasado el borde superior del rango ideal y por debajo
      // del nivel actual.
      final bool isExcess = i >= maxIdx && i < fillIdx;
      // Agua útil: por debajo del nivel y todavía dentro de lo razonable.
      final bool inFilled = i < fillIdx && !isExcess;
      // Lo que falta para entrar al rango ideal.
      final bool inGap = i >= fillIdx && i < minIdx;

      // Dentro del rango ideal, verde. Debajo, azul que aclara con la
      // vuelta: da sensación de nivel que sube, no de dos colores pegados.
      // El salto de azul a verde es el que hace visible el momento en que el
      // suelo entra donde debe estar.
      final bool inOptimalZone = i >= minIdx && i < maxIdx;
      final Color tone = inOptimalZone
          ? Color.lerp(
              _Rx.optimal,
              _Rx.optimalSoft,
              maxIdx == minIdx ? 0.0 : (i - minIdx) / (maxIdx - minIdx),
            )!
          : Color.lerp(_Rx.waterDeep, _Rx.waterSoft, i / _spokes)!;

      // ── El radio ────────────────────────────────────────────────────────
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..color = isExcess
              ? _Rx.excess.withValues(alpha: 0.30)
              : (inFilled
                    ? tone.withValues(alpha: 0.26)
                    : (inGap
                          ? _Rx.lack.withValues(alpha: 0.22)
                          : _Rx.track.withValues(alpha: 0.75)))
          ..strokeWidth = 1.1
          ..isAntiAlias = true,
      );

      // ── La mota ─────────────────────────────────────────────────────────
      if (isExcess) {
        // Roja y un pelo más grande que las azules: el agua de más no es una
        // ausencia, es algo que está ahí y que estorba. Tiene que pesar.
        canvas.drawCircle(
          p2,
          5.0,
          Paint()
            ..color = _Rx.excess.withValues(alpha: 0.62)
            ..maskFilter = _dotGlow
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          p2,
          7.4,
          Paint()..color = _Rx.excess.withValues(alpha: 0.14),
        );
        canvas.drawCircle(
          p2,
          3.9,
          Paint()
            ..color = _Rx.excess
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          p2.translate(-1.05, -1.15),
          1.3,
          Paint()
            ..color = _Rx.excessSoft.withValues(alpha: 0.85)
            ..isAntiAlias = true,
        );
      } else if (inFilled) {
        // Resplandor, halo plano y núcleo, en ese orden. Las tres capas
        // juntas son lo que convierte un disco en una cuenta encendida.
        canvas.drawCircle(
          p2,
          4.6,
          Paint()
            ..color = tone.withValues(alpha: 0.62)
            ..maskFilter = _dotGlow
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          p2,
          7.0,
          Paint()..color = tone.withValues(alpha: 0.14),
        );
        canvas.drawCircle(
          p2,
          3.6,
          Paint()
            ..color = tone
            ..isAntiAlias = true,
        );
        // El reflejo. Un punto blanco arriba a la izquierda es todo lo que
        // hace falta para que la mota se lea como vidrio y no como pintura.
        canvas.drawCircle(
          p2.translate(-1.05, -1.15),
          1.25,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.60)
            ..isAntiAlias = true,
        );
      } else if (inGap) {
        // Carencia: hueca Y amarilla. Las dos cosas a la vez, forma y color,
        // para que no dependa de distinguir tonos bajo el sol del campo.
        // Resplandece más bajo que las llenas: es una promesa, no un nivel
        // alcanzado.
        canvas.drawCircle(
          p2,
          4.0,
          Paint()
            ..color = _Rx.lack.withValues(alpha: 0.34)
            ..maskFilter = _dotGlowSoft
            ..isAntiAlias = true,
        );
        canvas.drawCircle(
          p2,
          3.4,
          Paint()
            ..color = _Rx.lack
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.9
            ..isAntiAlias = true,
        );
      } else {
        canvas.drawCircle(
          p2,
          1.9,
          Paint()
            ..color = _Rx.track
            ..isAntiAlias = true,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.fill01 != fill01 ||
      old.optMin01 != optMin01 ||
      old.optMax01 != optMax01;
}

// ═══════════════════════════════════════════════════════════════════════════
// Tarjeta de humedad
// ═══════════════════════════════════════════════════════════════════════════

/// LA TARJETA PRINCIPAL.
///
/// Responde tres preguntas en menos de un segundo:
///
///   1. ¿Cuánta agua hay?            → la cifra, con todo el peso visual
///   2. ¿Es la que debería?          → la píldora de estado y el rango ideal
///   3. ¿Hacia dónde va?             → la tendencia, sobre lecturas reales
///
/// Y una barra de zonas que hace visible lo que ninguna de las tres dice sola:
/// **dónde cae el valor dentro del recorrido seco→saturado de esta etapa**.
class _SoilMoistureCard extends StatelessWidget {
  const _SoilMoistureCard({required this.read, required this.trend});

  final _MoistureRead read;
  final MoistureTrend trend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: BioGGlassCard(
        radius: 24,
        padding: EdgeInsets.zero,
        backgroundColor: _cardSurface(read.color),
        borderColor: _cardBorder(read.color),
        boxShadows: _cardShadow,
        child: DecoratedBox(
          decoration: _glassSheen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Cifra y rango ideal ─────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // El grupo de la izquierda va en `Expanded` + `FittedBox`
                    // porque el peor caso real —"100" con la píldora
                    // "Saturado"— no cabe en un teléfono angosto. Así se
                    // encoge un punto en vez de romper con la franja de
                    // desbordamiento.
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              read.value.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 51,
                                height: 0.94,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -2.4,
                                color: _Rx.ink,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 7, left: 2),
                              child: Text(
                                '%',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w800,
                                  color: _Rx.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: _Pill(
                                text: read.bandEs,
                                color: read.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            'RANGO IDEAL',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: _Rx.muted.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${read.optMin.toStringAsFixed(0)}'
                            '–${read.optMax.toStringAsFixed(0)} %',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.4,
                              color: _Rx.water,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),
                _ZoneBar(read: read),

                const SizedBox(height: 14),
                Container(height: 1, color: _Rx.hair),
                const SizedBox(height: 11),

                // ── Tendencia y distancia al ideal ──────────────────────
                //
                // Los dos lados van en `Flexible`: juntos superan el ancho de
                // un teléfono angosto, y aquí prefiero que uno se recorte a
                // que la tarjeta se rompa.
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      child: trend.direction.isKnown
                          ? _TrendChip(trend: trend)
                          : const _MutedNote('Aún sin tendencia'),
                    ),
                    if (!read.isInsideOptimal) ...<Widget>[
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          read.gapToOptimal > 0
                              ? '${read.gapToOptimal.toStringAsFixed(0)} '
                                    'puntos al ideal'
                              : '${(-read.gapToOptimal).toStringAsFixed(0)} '
                                    'puntos por encima',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: read.color,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  const _TrendChip({required this.trend});

  final MoistureTrend trend;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color) = switch (trend.direction) {
      MoistureTrendDirection.drying => (
        Icons.trending_down_rounded,
        _Rx.lack,
      ),
      MoistureTrendDirection.wetting => (
        Icons.trending_up_rounded,
        _Rx.water,
      ),
      // Neutro, no verde: verde ahora significa "dentro del rango", y un
      // suelo seco pero quieto se pintaba de verde diciendo que iba bien.
      _ => (Icons.trending_flat_rounded, _Rx.muted),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            trend.direction == MoistureTrendDirection.stable
                ? 'Estable'
                : '${trend.direction.labelEs} ${trend.rateLabelEs()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _MutedNote extends StatelessWidget {
  const _MutedNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        color: _Rx.muted.withValues(alpha: 0.75),
      ),
    );
  }
}

/// La barra de zonas.
///
/// Segmentos, no una barra continua: un relleno liso se lee como "progreso
/// hacia el 100 %", y aquí el 100 % es **saturación**, que es malo. Los
/// segmentos se leen como una escala con tramos, que es lo que realmente es.
///
/// El recorrido va de 0 a la saturación de la etapa, la zona ideal queda
/// marcada por detrás y la aguja dice dónde caes tú.
class _ZoneBar extends StatelessWidget {
  const _ZoneBar({required this.read});

  final _MoistureRead read;

  @override
  Widget build(BuildContext context) {
    // `width: double.infinity` NO es decorativo. `CustomPaint` sin hijo se
    // dimensiona con `constraints.constrain(size)`, y su `size` por defecto
    // es `Size.zero`: con anchura holgada —que es lo que da una Column con
    // `crossAxisAlignment.start`— salía midiendo 0 de ancho y el painter se
    // iba por su propia guarda sin pintar nada. Así las cotas quedan
    // ajustadas y la barra ocupa todo el ancho disponible.
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: CustomPaint(
        size: const Size(double.infinity, 45),
        painter: _ZoneBarPainter(read: read),
      ),
    );
  }
}

class _ZoneBarPainter extends CustomPainter {
  const _ZoneBarPainter({required this.read});

  final _MoistureRead read;

  // Geometría. Más segmentos, más finos y más juntos que la primera versión:
  // la barra pesaba demasiado para lo que dice y competía con la cifra.
  static const int _segments = 40;
  static const double _gap = 2.4;
  static const double _segTop = 13.0;
  static const double _segH = 10.0;
  static const double _segRadius = 1.6;
  static const double _labelGap = 8.0;

  static final TextStyle _endStyle = TextStyle(
    fontSize: 10,
    height: 1.0,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
    color: _Rx.muted.withValues(alpha: 0.62),
  );

  static final TextStyle _idealStyle = TextStyle(
    fontSize: 10,
    height: 1.0,
    fontWeight: FontWeight.w900,
    letterSpacing: 1.0,
    color: _Rx.water.withValues(alpha: 0.92),
  );

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    if (w <= 0) return;

    final double scale = read.highMin;
    if (scale <= 0) return;

    final double segW = (w - _gap * (_segments - 1)) / _segments;
    if (segW <= 0) return;

    final double optA = (read.optMin / scale).clamp(0.0, 1.0);
    final double optB = (read.optMax / scale).clamp(0.0, 1.0);
    final double cur = (read.value / scale).clamp(0.0, 1.0);

    // Banda de fondo marcando la zona ideal. Va detrás de los segmentos para
    // que se lea como territorio, no como otro elemento más.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(
          optA * w - 2.5,
          _segTop - 4.5,
          optB * w + 2.5,
          _segTop + _segH + 4.5,
        ),
        const Radius.circular(7),
      ),
      Paint()..color = _Rx.water.withValues(alpha: 0.085),
    );

    for (int i = 0; i < _segments; i++) {
      final double mid = (i + 0.5) / _segments;
      final double x = i * (segW + _gap);

      final bool filled = mid <= cur;
      final bool inOptimal = mid >= optA && mid <= optB;

      // El color avanza de azul profundo a azul claro con el recorrido: da
      // sensación de nivel que sube, no de dos colores pegados.
      final Color c;
      if (filled) {
        // Los tres estados de la barra son los mismos tres del dial, con los
        // mismos colores. Si no coincidieran, el productor tendría que
        // aprenderse dos códigos para el mismo dato.
        c = mid > optB
            ? _Rx.excess
            : (inOptimal
                  ? _Rx.optimal
                  : Color.lerp(_Rx.waterDeep, _Rx.water, mid)!);
      } else {
        // Vacío pero dentro del rango ideal = exactamente lo que falta. Va
        // en amarillo, igual que los aros huecos del dial.
        c = inOptimal
            ? _Rx.lack.withValues(alpha: 0.30)
            : _Rx.track.withValues(alpha: 0.62);
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, _segTop, segW, _segH),
          const Radius.circular(_segRadius),
        ),
        Paint()
          ..color = c
          ..isAntiAlias = true,
      );
    }

    // La aguja. Se dibuja al final para que nada la tape.
    final double nx = (cur * w).clamp(2.0, w - 2);
    final Paint needle = Paint()
      ..color = _Rx.ink.withValues(alpha: 0.80)
      ..isAntiAlias = true;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(nx - 1.0, _segTop - 3.5, 2.0, _segH + 7),
        const Radius.circular(1.4),
      ),
      needle,
    );
    canvas.drawCircle(Offset(nx, _segTop - 5.5), 3.3, needle);
    canvas.drawCircle(
      Offset(nx, _segTop - 5.5),
      1.3,
      Paint()..color = Colors.white,
    );

    // ── Etiquetas ────────────────────────────────────────────────────────
    //
    // Se dibujan aquí y no en una fila debajo porque aquí sí se conoce el
    // ancho real de cada texto. Con `Row` + `Spacer` la posición de "IDEAL"
    // salía de constantes a ojo, y con este rango caía unos 20 px a la
    // izquierda de la banda que señala: parecía apuntar a otro tramo.
    final double labelY = _segTop + _segH + 9;

    final TextPainter ideal = _label('IDEAL', _idealStyle);
    final double idealLeft = (((optA + optB) / 2) * w - ideal.width / 2).clamp(
      0.0,
      w - ideal.width,
    );
    ideal.paint(canvas, Offset(idealLeft, labelY));

    // Los extremos, solo si no se montan con ella. Cuando la zona ideal cae
    // pegada a un extremo, la palabra de ese extremo sobra: la banda ya está
    // ahí y se ve.
    final TextPainter dry = _label('Seco', _endStyle);
    if (idealLeft > dry.width + _labelGap) {
      dry.paint(canvas, Offset(0, labelY));
    }

    final TextPainter wet = _label('Saturado', _endStyle);
    final double wetLeft = w - wet.width;
    if (idealLeft + ideal.width + _labelGap < wetLeft) {
      wet.paint(canvas, Offset(wetLeft, labelY));
    }
  }

  static TextPainter _label(String value, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: value, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant _ZoneBarPainter old) =>
      old.read.value != read.value ||
      old.read.optMin != read.optMin ||
      old.read.optMax != read.optMax ||
      old.read.highMin != read.highMin;
}

/// Píldora compacta, del tamaño de las del Panel.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Tarjetas de acción
// ═══════════════════════════════════════════════════════════════════════════

/// Sombra de las tarjetas de esta pantalla.
///
/// `BioGGlassCard` trae por defecto tres sombras muy abiertas —blur 34, 90 y
/// 110— pensadas para una tarjeta suelta sobre el Panel. Apiladas seis veces
/// una debajo de otra se suman y el fondo se ensucia: las tarjetas se veían
/// pesadas y planas a la vez. Aquí va una sola sombra, corta y cercana.
const List<BoxShadow> _cardShadow = <BoxShadow>[
  BoxShadow(
    color: Color(0x14000000),
    blurRadius: 22,
    offset: Offset(0, 10),
  ),
  BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 3,
    offset: Offset(0, 1),
  ),
];

/// Superficie de vidrio.
///
/// El 0.84 es lo que hace que se vea el fondo a traves: el desenfoque de
/// `BioGGlassCard` no sirve de nada si la capa de encima es casi opaca. El
/// 4.5 % del acento le da temperatura propia a cada tarjeta sin leerse como
/// color.
Color _cardSurface(Color accent) =>
    Color.lerp(const Color(0xFFF7FAFC), accent, 0.045)!
        .withValues(alpha: 0.84);

/// Borde de la tarjeta.
///
/// Blanco casi puro con una gota del acento. Un borde blanco liso sobre un
/// fondo con partículas verdes deja la tarjeta despegada del resto de la
/// pantalla; con un 12 % del acento el canto se integra y se sigue leyendo
/// como vidrio.
Color _cardBorder(Color accent) =>
    Color.lerp(Colors.white, accent, 0.12)!.withValues(alpha: 0.85);

/// Brillo interno del vidrio.
///
/// Un degradado vertical blanco→transparente de arriba a abajo. Es lo que
/// hace que la tarjeta parezca una lámina de vidrio con luz encima y no un
/// rectángulo de color plano; va por dentro del recorte de `BioGGlassCard`
/// para que respete el radio.
const BoxDecoration _glassSheen = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0x26FFFFFF), Color(0x00FFFFFF)],
    stops: <double>[0.0, 0.55],
  ),
);

/// La lámina de riego, siempre en banda.
///
/// ─────────────────────────────────────────────────────────────────────────────
/// POR QUÉ UNA BANDA Y NO UNA CIFRA
/// ─────────────────────────────────────────────────────────────────────────────
///
/// La exactitud declarada del canal de humedad es de ±3 puntos de contenido
/// volumétrico en el rango bajo. Sobre una zona radicular de 40 cm eso son ±12
/// mm de lámina; sobre una lámina neta calculada de 40 mm, **±30 %**. Un tercio.
///
/// Decir «aplica 40 mm» comunicaría una precisión que el instrumento no tiene,
/// antes siquiera de contar el error de la textura elegida a mano y el de la
/// profundidad radicular estimada. La banda no es una cortesía: es el número.
class _IrrigationDepthCard extends StatelessWidget {
  const _IrrigationDepthCard({required this.depth});

  final IrrigationDepthEstimate depth;

  @override
  Widget build(BuildContext context) {
    final double? lpp = depth.litersPerPlant;
    final double? lm2 = depth.litersPerSquareMeter;

    // Las dos unidades son opcionales. Sin ninguna, la línea no se pinta: un
    // renglón vacío entre la cifra y el pie parece un fallo de carga.
    final List<String> units = <String>[
      if (lm2 != null) '${lm2.toStringAsFixed(lm2 < 10 ? 1 : 0)} litros por m²',
      if (lpp != null)
        '${lpp.toStringAsFixed(lpp < 10 ? 1 : 0)} litros por planta',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: BioGGlassCard(
        radius: 24,
        padding: EdgeInsets.zero,
        backgroundColor: _cardSurface(_Rx.water),
        borderColor: _cardBorder(_Rx.water),
        boxShadows: _cardShadow,
        child: DecoratedBox(
          decoration: _glassSheen,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _ArtLifted(asset: _Rx.icRiego, size: 26),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Cuánta agua aplicar',
                        style: TextStyle(
                          fontSize: 13.4,
                          fontWeight: FontWeight.w800,
                          color: _Rx.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  depth.bandEs,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: _Rx.waterDeep,
                  ),
                ),
                if (units.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    units.join(' · '),
                    style: const TextStyle(
                      fontSize: 12.6,
                      height: 1.35,
                      color: _Rx.muted,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  depth.basisEs,
                  style: TextStyle(
                    fontSize: 11.4,
                    height: 1.38,
                    color: _Rx.muted.withValues(alpha: 0.86),
                  ),
                ),
                if (!depth.includesSystemLosses) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    // La lámina bruta SOLO si se conoce el sistema de riego.
                    // Para los mismos 40 mm netos son 44 por goteo, 53 por
                    // aspersión y 67 por surco: la diferencia entre el mejor y
                    // el peor sistema es del 52 %. Fingir esa conversión sin
                    // saber el sistema sería peor que no darla.
                    'Es el agua que le falta al suelo. No incluye las pérdidas '
                    'de tu sistema de riego.',
                    style: TextStyle(
                      fontSize: 11.4,
                      height: 1.38,
                      color: _Rx.muted.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Un dato suelto al pie de la tarjeta: icono diminuto y texto.
///
/// Es lo que permite que la tarjeta de riego cargue con el clima que uso para
/// decidir —probabilidad de lluvia, demanda de agua, vigencia— sin abrir otra
/// tarjeta ni obligar a rodar el dedo.
@immutable
class _Fact {
  const _Fact(this.iconAsset, this.text);

  final String iconAsset;
  final String text;
}

/// Arte con sombra de silueta, en pequeño.
///
/// Misma tecnica que la gota del dial: un `BoxShadow` sombrearia la caja, no
/// el dibujo. Se pinta una copia teñida de negro y desenfocada debajo.
class _ArtLifted extends StatelessWidget {
  const _ArtLifted({required this.asset, required this.size});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Transform.translate(
          offset: Offset(0, size * 0.06),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withValues(alpha: 0.20),
                BlendMode.srcIn,
              ),
              child: _Art(asset: asset, size: size),
            ),
          ),
        ),
        _Art(asset: asset, size: size),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// El parte de agua
// ═══════════════════════════════════════════════════════════════════════════

/// Todo lo que hace falta para decidir el riego, en UNA tarjeta.
///
/// Estaban en tres —pronóstico, recomendación, etapa— y era un error de
/// lectura: el productor no abre esta pantalla con tres preguntas, abre con
/// una sola, *¿riego o no riego?*, y las tres partes son tramos de esa misma
/// respuesta. Apiladas y separadas por una línea se leen como un párrafo; en
/// tarjetas sueltas se leían como tres avisos compitiendo entre sí.
///
/// El orden es el del razonamiento, no el de la jerarquía: primero lo que va a
/// hacer el cielo —porque puede ahorrarte el riego entero—, después lo que
/// BIO-G concluye con eso, y al final la etapa, que es el contexto contra el
/// que se midió todo.
class _WaterBriefCard extends StatelessWidget {
  const _WaterBriefCard({
    required this.decision,
    required this.read,
    required this.trend,
    this.weather,
    this.stageLabel,
    this.cropIconAsset,
    this.onOpenEnvironment,
  });

  final IrrigationDecision decision;
  final _MoistureRead? read;
  final MoistureTrend trend;
  final AgronomicWeatherSnapshot? weather;
  final String? stageLabel;
  final String? cropIconAsset;

  /// Salto a la pantalla de Entorno. Null si no hay a dónde ir.
  final VoidCallback? onOpenEnvironment;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (decision.action) {
      IrrigationAction.regar => _Rx.water,
      IrrigationAction.noRegar => _Rx.optimal,
      IrrigationAction.esperar => const Color(0xFFB07A1E),
      IrrigationAction.revisar => const Color(0xFF9A5B2A),
      IrrigationAction.datosInsuficientes => const Color(0xFF6A7278),
    };

    final AgronomicWeatherSnapshot? sky = weather;
    final bool hasSky = sky != null && !sky.isUnavailable;
    final String stage = (stageLabel ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: BioGGlassCard(
        radius: 22,
        padding: EdgeInsets.zero,
        backgroundColor: _cardSurface(accent),
        borderColor: _cardBorder(accent),
        boxShadows: _cardShadow,
        child: DecoratedBox(
          decoration: _glassSheen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (hasSky) ...<Widget>[
                _forecastRow(sky),
                const _BriefDivider(),
              ],
              _decisionRow(accent),
              if (stage.isNotEmpty) ...<Widget>[
                const _BriefDivider(),
                _stageRow(stage),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Pronóstico ────────────────────────────────────────────────────────────

  Widget _forecastRow(AgronomicWeatherSnapshot w) {
    final RainOutlook r = w.rain;
    final int? prob = r.maxProbNext24hPct;
    final double? mm = r.expectedNext24hMm;
    final double? fell = r.observedLast24hMm;
    final int code = w.weatherCode ?? 0;
    final DateTime when = w.observedAt ?? w.fetchedAt;

    final String icon = EnvironmentIconMapper.iconForForecastWeather(
      weatherCode: code,
      time: when,
      precipitationProbability: prob,
      precipitationMm: mm,
    );
    final String sky = _skyLabel(
      EnvironmentIconMapper.conditionFromWmoCode(code),
    );

    final String title;
    final String body;

    if (mm != null && mm >= 1 && (prob ?? 0) >= 50) {
      title = 'Parece que va a llover';
      body =
          '$sky · ${_Rx.mm(mm)} mm previstos. Si se confirma, puedes '
          'ahorrarte el riego de hoy.';
    } else if ((prob ?? 0) >= 30) {
      title = 'Puede llover, pero poco';
      body = '$sky · no cuentes con la lluvia para cubrir el riego.';
    } else if (fell != null && fell >= 1) {
      title = 'Llovieron ${_Rx.mm(fell)} mm ayer';
      body = '$sky · el suelo ya recibió agua; confírmalo con la humedad.';
    } else {
      title = sky;
      body = prob == null
          ? 'Sin pronóstico de lluvia para tu parcela.'
          : 'Sin lluvia útil prevista en las próximas 24 h.';
    }

    final String? temps = _temps(w);

    return _BriefRow(
      iconAsset: icon,
      kicker: 'Pronóstico',
      title: title,
      body: temps == null ? body : '$body $temps',
      bodyMaxLines: 3,
      accent: _Rx.water,
      onTap: onOpenEnvironment,
      trailing: prob == null
          ? (onOpenEnvironment == null ? null : const _GoChevron())
          : _RainGlance(
              probPct: prob,
              showChevron: onOpenEnvironment != null,
            ),
    );
  }

  String? _temps(AgronomicWeatherSnapshot w) {
    final double? mx = w.airTempMaxC;
    final double? mn = w.airTempMinC;
    if (mx == null || mn == null) return null;
    return 'Máx ${mx.toStringAsFixed(0)}° / mín ${mn.toStringAsFixed(0)}°.';
  }

  /// Cómo se llama en español cada condición del mapeo que ya existe.
  static String _skyLabel(EnvCondition c) => switch (c) {
    EnvCondition.sunny => 'Despejado',
    EnvCondition.night => 'Noche despejada',
    EnvCondition.partlyCloudy => 'Parcialmente nublado',
    EnvCondition.cloudy => 'Nublado',
    EnvCondition.fog => 'Neblina',
    EnvCondition.drizzle => 'Llovizna',
    EnvCondition.rain => 'Lluvia',
    EnvCondition.thunder => 'Tormenta eléctrica',
    EnvCondition.stormStrong => 'Tormenta fuerte',
    EnvCondition.snow => 'Nieve',
    EnvCondition.frost => 'Helada',
    EnvCondition.heatwave => 'Calor extremo',
    EnvCondition.unknown => 'Sin dato de cielo',
  };

  // ── La decisión ───────────────────────────────────────────────────────────

  Widget _decisionRow(Color accent) {
    return _BriefRow(
      iconAsset: _Rx.icRiego,
      kicker: 'BIO-G recomienda',
      title: decision.headlineEs,
      body: _reasoning(),
      // Sin tope de líneas, a propósito. Es la única frase de la pantalla
      // donde BIO-G explica su criterio; cortarla a media palabra la volvía
      // sospechosa en vez de breve.
      accent: accent,
      facts: _facts(),
    );
  }

  /// Compone la explicación con lo que el sistema sabe de verdad.
  ///
  /// Orden deliberado —posición, movimiento, clima— porque es como se razona
  /// una decisión de riego: primero dónde estás, luego hacia dónde vas, y solo
  /// al final qué puede cambiarlo desde fuera.
  String _reasoning() {
    final List<String> parts = <String>[];
    final _MoistureRead? r = read;

    if (r != null) {
      if (r.isInsideOptimal) {
        parts.add('La humedad está dentro del rango ideal de la etapa.');
      } else if (r.gapToOptimal > 0) {
        parts.add(
          'La humedad está ${r.gapToOptimal.toStringAsFixed(0)} puntos por '
          'debajo del rango ideal.',
        );
      } else {
        parts.add('La humedad está por encima del rango ideal.');
      }
    }

    final String? projection = trend.projectionLabelEs();
    if (projection != null && projection != 'ya está por debajo') {
      parts.add('A este ritmo llegaría a nivel crítico $projection.');
    } else if (trend.direction == MoistureTrendDirection.wetting) {
      parts.add('El suelo viene ganando humedad.');
    } else if (trend.direction == MoistureTrendDirection.stable) {
      // La píldora de arriba ya dice "Estable". Aquí lo que aporta no es el
      // dato sino lo que significa: quieto no es lo mismo que bien.
      parts.add(
        r != null && !r.isInsideOptimal
            ? 'No ha bajado en las últimas horas, así que el déficit no está '
                  'empeorando, pero tampoco se corrige solo.'
            : 'Se ha mantenido estable en las últimas horas.',
      );
    }

    final AgronomicWeatherSnapshot? w = decision.weather;
    if (w != null && !w.isUnavailable) {
      final int? prob = w.rain.maxProbNext24hPct;
      final double? mm = w.rain.expectedNext24hMm;
      if (prob != null && prob >= 50 && mm != null && mm >= 3) {
        // El "Pero" solo tiene sentido si hay una frase antes que contradecir.
        parts.add(
          '${parts.isEmpty ? 'Se' : 'Pero se'} esperan ${_Rx.mm(mm)} mm de '
          'lluvia, así que conviene esperar antes de gastar agua.',
        );
      } else if (prob != null && prob < 30) {
        parts.add('No se espera lluvia que lo resuelva.');
      }
    }

    if (parts.isEmpty) {
      final String d = decision.detailEs.trim();
      return d.isEmpty ? 'Sin explicación disponible.' : d;
    }
    return parts.join(' ');
  }

  /// Lo que sustenta la decisión, al pie de su bloque.
  ///
  /// Ya no lleva la probabilidad de lluvia: eso vive arriba, en el bloque del
  /// pronóstico, y repetirlo aquí era la clase de eco que hace que se deje de
  /// leer la tarjeta entera.
  List<_Fact> _facts() {
    final List<_Fact> out = <_Fact>[];
    final AgronomicWeatherSnapshot? w = decision.weather;

    if (w == null || w.isUnavailable) {
      out.add(
        const _Fact(
          _Rx.icLocation,
          'Guarda la ubicación de tu parcela para traer el pronóstico',
        ),
      );
    } else {
      final double? et0 = w.et0TodayMm;
      if (et0 != null) {
        out.add(_Fact(_Rx.icSun, 'Demanda ${_Rx.mm(et0)} mm hoy'));
      }
    }

    // La lámina NO se repite aquí: ya tiene su propia tarjeta arriba, con la
    // banda, las unidades y el supuesto con el que se calculó. Repetirla dos
    // tarjetas más abajo es la clase de eco que hace que se deje de leer la
    // tarjeta entera.

    final String? projection = trend.projectionLabelEs();
    if (projection != null && projection != 'ya está por debajo') {
      out.add(_Fact(_Rx.icAlert, 'Crítico $projection'));
    }

    final DateTime? until = decision.validUntil;
    if (until != null) {
      final int h = until.difference(decision.decidedAt).inHours;
      if (h > 0) out.add(_Fact(_Rx.icTime, 'Válida $h h'));
    }

    return out;
  }

  // ── Etapa ─────────────────────────────────────────────────────────────────

  /// Contexto, deliberadamente apagado.
  ///
  /// Sin acento de color y con el icono a menor tamaño. Y sin el rango ideal:
  /// ya está dos bloques más arriba, en la tarjeta de humedad, y era la
  /// tercera vez que aparecía el mismo `64–82 %` en una sola pantalla.
  Widget _stageRow(String stage) {
    final String art = (cropIconAsset ?? '').trim();
    return _BriefRow(
      iconAsset: art.isEmpty ? _Rx.icSiembra : art,
      kicker: 'Etapa actual',
      title: stage,
      accent: _Rx.muted,
      iconSize: 44,
      titleSize: 14,
    );
  }
}

/// Un bloque del parte.
class _BriefRow extends StatelessWidget {
  const _BriefRow({
    required this.iconAsset,
    required this.kicker,
    required this.title,
    required this.accent,
    this.body,
    this.bodyMaxLines,
    this.facts = const <_Fact>[],
    this.trailing,
    this.onTap,
    this.iconSize = 62,
    this.titleSize = 15.5,
  });

  final String iconAsset;
  final String kicker;
  final String title;
  final Color accent;
  final String? body;

  /// Null significa sin tope. Lo usa así el bloque de la recomendación.
  final int? bodyMaxLines;

  final List<_Fact> facts;
  final Widget? trailing;
  final VoidCallback? onTap;
  final double iconSize;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final String? b = body?.trim();

    final Widget content = Padding(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Desnudo, con su propia sombra: se despega del cristal en vez
              // de quedar pegado como una calcomanía.
              _ArtLifted(asset: iconAsset, size: iconSize),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      kicker.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                        height: 1.0,
                        color: accent,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: titleSize,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: _Rx.ink,
                      ),
                    ),
                    if (b != null && b.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        b,
                        maxLines: bodyMaxLines,
                        overflow: bodyMaxLines == null
                            ? TextOverflow.clip
                            : TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.38,
                          color: _Rx.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...<Widget>[
                const SizedBox(width: 10),
                trailing!,
              ],
            ],
          ),
          if (facts.isNotEmpty) ...<Widget>[
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 7,
              children: <Widget>[
                for (final _Fact f in facts)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      _Art(asset: f.iconAsset, size: 15),
                      const SizedBox(width: 5),
                      // Un dato largo (una etapa con nombre kilométrico) puede
                      // pasarse del ancho de la fila por un pelo. `Flexible`
                      // deja que ese caso caiga a una segunda línea en vez de
                      // desbordar; los datos cortos siguen igual que siempre.
                      Flexible(
                        child: Text(
                          f.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: _Rx.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    // `Material` transparente para que la onda del toque se pinte dentro del
    // cristal y no encima de él.
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );
  }
}

/// La línea que separa dos bloques del parte.
class _BriefDivider extends StatelessWidget {
  const _BriefDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(height: 1, color: _Rx.hair),
    );
  }
}

/// La probabilidad de lluvia, desnuda.
///
/// Antes iba dentro de una caja azul con borde, y esa caja competía con la
/// tarjeta que ya la contenía: una caja dentro de otra caja. Sin recuadro el
/// número respira y se lee como parte del texto, no como una etiqueta pegada
/// encima.
class _RainGlance extends StatelessWidget {
  const _RainGlance({required this.probPct, this.showChevron = false});

  final int probPct;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '$probPct',
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.3,
                    color: _Rx.water,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 2, left: 1),
                  child: Text(
                    '%',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      color: _Rx.water,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'LLUVIA',
              style: TextStyle(
                fontSize: 8.5,
                height: 1.0,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
                color: _Rx.water.withValues(alpha: 0.70),
              ),
            ),
          ],
        ),
        if (showChevron) ...<Widget>[
          const SizedBox(width: 3),
          const _GoChevron(),
        ],
      ],
    );
  }
}

/// La flecha de "hay más de esto en otra pantalla".
class _GoChevron extends StatelessWidget {
  const _GoChevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right_rounded,
      size: 22,
      color: _Rx.water.withValues(alpha: 0.55),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Secciones de eventos
// ═══════════════════════════════════════════════════════════════════════════

class _EventSection extends StatelessWidget {
  const _EventSection({
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.events,
  });

  final String title;
  final String subtitle;
  final String iconAsset;
  final List<AgronomicEvent> events;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Row(
              children: <Widget>[
                _Art(asset: iconAsset, size: 38),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                          color: _Rx.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: _Rx.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${events.length}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _Rx.muted,
                  ),
                ),
              ],
            ),
          ),
          BioGGlassCard(
            radius: 22,
            padding: const EdgeInsets.symmetric(vertical: 3),
            backgroundColor: _cardSurface(_Rx.water),
            borderColor: _cardBorder(_Rx.water),
            boxShadows: _cardShadow,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < events.length; i++) ...<Widget>[
                  if (i > 0)
                    const Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 14,
                      color: _Rx.hair,
                    ),
                  _EventRow(event: events[i], now: now),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.now});

  final AgronomicEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final Color c = _Rx.severity(event.severity);
    final String stage = (event.stageLabel ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Art(asset: _Rx.iconFor(event.type), size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: _Rx.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: Text(
                        _Rx.relative(event.timestamp, now),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _Rx.muted.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  event.message,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.38,
                    color: _Rx.muted,
                  ),
                ),
                if (stage.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 7),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      stage,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: c,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas menores
// ═══════════════════════════════════════════════════════════════════════════

/// Arte del proyecto: desnudo, sin teñir y a tamaño explícito.
class _Art extends StatelessWidget {
  const _Art({required this.asset, this.size = 24});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        asset,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => const SizedBox.shrink(),
      ),
    );
  }
}

/// Entrada escalonada de cada bloque. Sube, aparece y escala apenas: el mismo
/// gesto que usan el Panel y el Historial, para que la pantalla se sienta de
/// la misma app.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.controller,
    required this.begin,
    required this.end,
    required this.child,
  });

  final AnimationController controller;
  final double begin;
  final double end;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Animation<double> a = CurvedAnimation(
      parent: controller,
      curve: Interval(begin, end, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: a,
      child: child,
      builder: (BuildContext context, Widget? c) {
        return Opacity(
          opacity: a.value,
          child: Transform.translate(
            offset: Offset(0, (1 - a.value) * 18),
            child: Transform.scale(
              scale: 0.985 + (a.value * 0.015),
              child: c,
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 30, 18, 18),
      child: BioGGlassCard(
        radius: 24,
        padding: const EdgeInsets.fromLTRB(22, 32, 22, 32),
        backgroundColor: _cardSurface(_Rx.water),
        borderColor: _cardBorder(_Rx.water),
        boxShadows: _cardShadow,
        child: Column(
          children: <Widget>[
            const _Art(asset: _Rx.icProtection, size: 76),
            const SizedBox(height: 16),
            const Text(
              'Nada que atender por ahora',
              style: TextStyle(
                fontSize: 17.5,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
                color: _Rx.ink,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Cuando el Bio-G tenga una lectura de humedad y un cultivo '
              'configurado, aquí verás cuánta agua hay, cuánta falta y qué '
              'conviene hacer hoy.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.5, height: 1.45, color: _Rx.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _NpkFootnote extends StatelessWidget {
  const _NpkFootnote();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 2, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Opacity(opacity: 0.5, child: _Art(asset: _Rx.icNpk, size: 22)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'La nutrición del cultivo —nitrógeno, fósforo y potasio— tiene '
              'su propia pantalla, con sus dosis y sus ventanas de aplicación.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: _Rx.muted.withValues(alpha: 0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
