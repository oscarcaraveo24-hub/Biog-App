// lib/screens/onboarding/steps/soil_texture_step.dart
//
// «¿Cómo es tu tierra?» — el selector de material.
//
// ─────────────────────────────────────────────────────────────────────────────
// QUÉ DEBE SENTIRSE AL ABRIR
// ─────────────────────────────────────────────────────────────────────────────
//
// Un selector de materiales de herramienta ag-tech premium: limpio, táctil y
// fácil de entender aunque el productor no conozca un solo término técnico. La
// esfera es la protagonista; el resto de la interfaz explica, no compite. Debe
// sentirse tecnológica por la precisión del movimiento, no por llenar la
// pantalla de efectos.
//
// **El usuario nunca debe sentir que está contestando un examen de agronomía.**
//
// ─────────────────────────────────────────────────────────────────────────────
// UNA SOLA PANTALLA, UN SOLO PASO
// ─────────────────────────────────────────────────────────────────────────────
//
// El selector, las propiedades, los nombres locales y la ayuda de 20 segundos
// pertenecen al mismo paso del wizard. La ayuda abre como hoja inferior interna
// y NO cuenta como otro paso del onboarding: al cerrarla el usuario vuelve al
// carrusel exactamente donde estaba. Los nombres locales se despliegan **dentro**
// de la misma pantalla, sin navegar: son opcionales y no deben costar un viaje.
//
// ─────────────────────────────────────────────────────────────────────────────
// EL ORDEN DE LECTURA, Y POR QUÉ ES ESE
// ─────────────────────────────────────────────────────────────────────────────
//
//   hoja  →  título  →  subtítulo  →  esfera  →  nombre + etiqueta + frase
//         →  mini carrusel  →  propiedades  →  ayuda | nombres locales
//
// El mini carrusel va ANTES de las propiedades, no después. Es la única fila
// que dice «hay seis opciones y estás en la tercera»; ponerla detrás de la
// tarjeta de propiedades la deja fuera de la primera pantalla en teléfonos
// pequeños, y entonces el productor cree que solo existe lo que ve.
//
// ─────────────────────────────────────────────────────────────────────────────
// LO QUE ESTE WIDGET NO HACE
// ─────────────────────────────────────────────────────────────────────────────
//
// · No gira la esfera 360°. Es un PNG plano: girarlo lo delataría.
// · No usa modelado 3D, shaders ni dependencias pesadas.
// · No preselecciona una textura como dato confirmado. Puede *mostrar* Franca
//   como vista inicial, pero no la reporta hasta que hay interacción explícita:
//   quien no toca nada no ha declarado nada.
// · No decide con el color. El color NO define la textura —la definen
//   granulometría, cohesión, porosidad y microgrietas— y por eso la selección
//   se marca con aro, palomita Y texto, nunca solo con verde.
// · El arco del medidor NO se mueve con la textura. Es un bisel de instrumento,
//   deliberadamente fijo: un arco que creciera o menguara con cada esfera
//   parecería una medición, y aquí no hay ninguna medición que mostrar.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bio_g/core/agro/water/soil_texture_source.dart';
import 'package:bio_g/core/agro/water/soil_water_scale.dart';
import 'package:bio_g/widgets/onboarding/soil_texture_guide_sheet.dart';

/// La paleta de esta pantalla.
///
/// Existe como bloque nombrado —y no como literales sueltos por el archivo—
/// porque los mismos diez colores se repiten en ocho widgets: el día que la
/// marca ajuste el verde, se ajusta aquí y no en cuarenta sitios.
abstract final class _Soil {
  static const Color ink = Color(0xFF12201C);
  static const Color body = Color(0xFF6B7A80);
  static const Color faint = Color(0xFF9AA5AA);
  static const Color hair = Color(0xFFE8EDEA);

  static const Color green = Color(0xFF2AA84A);
  static const Color greenDeep = Color(0xFF1E7C37);
  static const Color greenSoft = Color(0xFFE9F6EC);
  static const Color greenHair = Color(0xFFBFE3C7);

  static const Color water = Color(0xFF2E7FE8);
}

// ─────────────────────────────────────────────────────────────────────────────
// NOMBRES LOCALES — retirados de la interfaz
// ─────────────────────────────────────────────────────────────────────────────
//
// El bloque «¿La conoces por otro nombre?» —roja, blanca/caliza, negra,
// volcánica, otra— se eliminó de esta pantalla. Costaba ~120 px de altura, o
// sea un tercio de lo que empujaba las propiedades fuera del primer pantallazo,
// y por diseño **no cambiaba un solo cálculo**: ni la textura, ni la retención,
// ni el drenaje, ni la lámina. Un dato opcional que no mueve nada no puede
// pagar el sitio donde se decide el riego.
//
// Los campos `soilLocalDescriptors` y `soilLocalOther` SIGUEN en el modelo y en
// la base de datos, y quien ya los tenía guardados los conserva: la pantalla de
// Cuenta los propaga intactos con `copyWith`. Se retiró la captura, no el dato.

/// Precarga los seis assets. Se llama al entrar al paso —o desde el paso
/// anterior— para que el primer swipe no haga flash.
void precacheSoilTextureAssets(BuildContext context) {
  // Sin `await` dentro del bucle: encadenarlos usaría el `context` después de
  // una brecha asíncrona —lo que `use_build_context_synchronously` prohíbe y
  // lo que revienta de verdad si el usuario sale del paso a media precarga—.
  // Las seis peticiones se lanzan de una vez con el context todavía montado.
  for (final t in SoilTexture.selectable) {
    precacheImage(AssetImage(t.assetPath), context);
  }
}

class SoilTextureStep extends StatefulWidget {
  const SoilTextureStep({
    super.key,
    required this.selectedTextureId,
    required this.onTextureChanged,
    this.title = '¿Cómo es tu tierra?',
    this.subtitle = 'Desliza para elegir la que más se parece a la tuya.',
    this.showLeadingMark = true,
  });

  /// Id ya guardado, o `null` si el productor todavía no ha declarado nada.
  final String? selectedTextureId;

  /// Reporta textura **y procedencia**: manual → `declared`, guía de 20
  /// segundos → `guidedEstimate`, «No estoy seguro» → `unknown`.
  final void Function(SoilTexture texture, SoilTextureSource source)
  onTextureChanged;

  final String title;
  final String subtitle;

  /// La hojita verde sobre el título. En el onboarding sí; en Cuenta, donde ya
  /// hay una barra de navegación con su propio título, sobra.
  final bool showLeadingMark;

  @override
  State<SoilTextureStep> createState() => _SoilTextureStepState();
}

class _SoilTextureStepState extends State<SoilTextureStep>
    with TickerProviderStateMixin {
  static const List<SoilTexture> _options = SoilTexture.selectable;

  late final PageController _pageController;
  late final AnimationController _entry;
  late final AnimationController _idle;
  late final AnimationController _halo;

  /// Se crea UNA vez. Construirla en `build` registraría un listener nuevo
  /// sobre `_entry` en cada swipe, cada chip y cada tecla del campo «Otra», y
  /// esos listeners no se sueltan nunca.
  /// Tipada como `CurvedAnimation` y no como `Animation<double>` para poder
  /// liberarla: desde Flutter 3.19 `CurvedAnimation` se registra en el rastreo
  /// de memoria y no soltarla es una fuga con aviso en depuración.
  late final CurvedAnimation _entryCurve;

  late int _index;
  bool _precached = false;

  // ── Por qué el reporte NO cuelga de `onPageChanged` ───────────────────────
  //
  // `PageView.onPageChanged` no avisa cuando la página se asienta: avisa cada
  // vez que cambia la página **del centro del viewport**. Está implementado
  // sobre `ScrollUpdateNotification` comparando `metrics.page.round()`, así que
  // una animación de la página 2 a la 5 lo dispara TRES veces, una por cada
  // peldaño que cruza. Con el reporte colgado de ahí pasaban cosas graves:
  //
  //  · Un resultado de la guía a dos o más celdas de distancia se reportaba
  //    primero con la textura intermedia y luego con la buena, y la segunda
  //    llamada se llevaba la procedencia por delante: `guidedEstimate` acababa
  //    guardado como `declared`. La procedencia —lo único que distingue una
  //    estimación por tacto de una declaración en firme— se perdía justo en los
  //    casos en que la guía sirve de algo.
  //  · Un toque en una miniatura lejana escribía el borrador cuatro veces y
  //    vibraba cuatro veces en 260 ms.
  //  · Un banderín de un solo uso lo consumía la primera página cruzada, de modo
  //    que una animación interrumpida por el dedo dejaba el banderín puesto y se
  //    tragaba la SIGUIENTE selección de verdad: pantalla y borrador divergían
  //    en silencio y para siempre.
  //
  // Ahora hay dos caminos, separados a propósito:
  //
  //   · Toque (miniatura, flecha, guía) -> `_declare` reporta EN EL ACTO, con la
  //     procedencia que corresponde, y solo entonces mueve el carrusel.
  //   · Arrastre -> se reporta al terminar el desplazamiento, en
  //     `ScrollEndNotification`, que sí significa «aquí se quedó».
  //
  // `onPageChanged` ya no reporta nada: solo mueve el estado visual.

  /// Si en el desplazamiento en curso ha intervenido un dedo.
  ///
  /// Es lo que distingue «esto lo movimos nosotros» de «esto lo movió el
  /// usuario», y por tanto si el final del desplazamiento es una respuesta o no.
  ///
  /// Se mira también en las actualizaciones, no solo al empezar: cuando un
  /// arrastre **interrumpe** una animación nuestra, `ScrollPosition` cambia de
  /// actividad sin emitir un `ScrollStartNotification` —pasa de «desplazándose»
  /// a «desplazándose»—, así que el único aviso de que ahora manda el dedo llega
  /// en los `ScrollUpdateNotification`, que sí traen `dragDetails`. Sin esa
  /// segunda comprobación, interrumpir la animación de la guía y soltar en otra
  /// esfera dejaba la pantalla mostrando una tierra y el borrador guardando otra,
  /// en silencio y para siempre.
  bool _userDragging = false;

  /// True en cuanto hay una textura DECLARADA —por el padre o por un toque—.
  ///
  /// La vista inicial muestra Franca sin que nadie la haya elegido, así que el
  /// aro verde y la palomita de la miniatura no pueden pintarse todavía:
  /// afirmarían una respuesta que el propio wizard se niega a aceptar (el botón
  /// «Usar esta tierra» sigue apagado). Marca de selección y dato declarado
  /// tienen que encenderse a la vez.
  late bool _declared;

  SoilTexture get _current => _options[_index];

  @override
  void initState() {
    super.initState();

    // Vista inicial: el valor guardado si lo hay; si no, Franca —que es lo que
    // se ve, no lo que se declara—.
    final stored = SoilTexture.fromId(widget.selectedTextureId);
    final storedIndex = widget.selectedTextureId == null
        ? -1
        : _options.indexOf(stored);
    _index = storedIndex >= 0 ? storedIndex : _options.indexOf(SoilTexture.loam);
    _declared = storedIndex >= 0;

    _pageController = PageController(
      initialPage: _index,
      // El ancho de página tiene que dejar asomar a las vecinas: con `f` la
      // fracción del viewport, la vecina entra en pantalla solo si
      // `f < 0,5 + esfera / (2 × ancho)`. En un teléfono de 320 px la esfera se
      // limita por altura y ese techo baja a ~0,71, así que 0,72 —el valor con
      // el que empecé— dejaba el carrusel sin ninguna pista de que hubiera más
      // opciones justo en las pantallas donde el mini carrusel también se
      // aprieta. 0,66 asoma ~17 px en 320 y ~38 px en 390.
      viewportFraction: 0.66,
    );

    _entry = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();

    _entryCurve = CurvedAnimation(parent: _entry, curve: Curves.easeOut);

    _idle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4300),
    );

    _halo = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_precached) {
      _precached = true;
      // Precarga de los seis assets para que el primer swipe no parpadee.
      precacheSoilTextureAssets(context);
    }

    // Reduced Motion: se desactivan flotación y giro del bisel, y se conservan
    // solo las transiciones cortas de selección. No es un extra: es requisito.
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      if (_idle.isAnimating) _idle.stop();
      if (_halo.isAnimating) _halo.stop();
      _entry.value = 1.0;
    } else {
      if (!_idle.isAnimating) _idle.repeat(reverse: true);
      if (!_halo.isAnimating) _halo.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant SoilTextureStep oldWidget) {
    super.didUpdateWidget(oldWidget);

    // El padre puede imponer un valor (por ejemplo, el que devuelve la guía de
    // 20 segundos abierta desde la «?» de la barra superior). Se mueve, pero
    // NUNCA se vuelve a reportar: el padre ya escribió la procedencia correcta
    // cuando decidió imponerlo, y reportar aquí la sobrescribiría con
    // `declared`.
    //
    // La guarda `!= null` es de carga: `SoilTexture.fromId(null)` devuelve
    // `unknown`, cuyo índice es 5 —un índice válido—, así que sin ella el
    // borrado del campo en la rama de maceta arrastraría el carrusel hasta «No
    // estoy seguro» sin que nadie lo pidiera.
    if (widget.selectedTextureId != oldWidget.selectedTextureId &&
        widget.selectedTextureId != null) {
      final i = _options.indexOf(SoilTexture.fromId(widget.selectedTextureId));
      if (i >= 0) {
        // La guía tiene que acusar recibo aunque acierte con la esfera que ya
        // estaba en pantalla: si no, contestar tres preguntas y volver a una
        // pantalla idéntica se siente como que no pasó nada.
        if (!_declared || i != _index) {
          HapticFeedback.lightImpact();
        }
        if (!_declared) setState(() => _declared = true);
        _moveTo(i);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entryCurve.dispose();
    _entry.dispose();
    _idle.dispose();
    _halo.dispose();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  /// Declara una textura. **El único sitio que llama a `onTextureChanged`.**
  ///
  /// Reporta primero y mueve después, para que la procedencia no dependa nunca
  /// de cuántas páginas cruce una animación.
  ///
  /// Tocar la miniatura que YA está en el centro también pasa por aquí, y tiene
  /// que declarar: sin eso, el usuario que se conforma con la vista inicial
  /// —Franca— no tenía forma de aceptarla, el carrusel no se movía y «Usar esta
  /// tierra» se quedaba apagado para siempre. Era un callejón sin salida sin
  /// señal alguna.
  void _declare(int i, SoilTextureSource? source) {
    if (i < 0 || i >= _options.length) return;

    final texture = _options[i];
    HapticFeedback.lightImpact();
    if (!_declared) setState(() => _declared = true);
    widget.onTextureChanged(texture, source ?? _sourceFor(texture));
    _moveTo(i);
  }

  /// Mueve el carrusel y nada más. No reporta, no vibra.
  void _moveTo(int i) {
    if (i < 0 || i >= _options.length) return;

    if (!_pageController.hasClients) {
      // Solo alcanzable antes del primer layout. No reporta nada, así que es
      // seguro llamarlo desde `didUpdateWidget`.
      if (_index != i) setState(() => _index = i);
      return;
    }

    // Ya está donde tiene que estar; no hay nada que animar.
    if (i == _index) return;

    if (_reduceMotion) {
      _pageController.jumpToPage(i);
    } else {
      _pageController.animateToPage(
        i,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  /// Solo estado visual. Dispara varias veces por animación, a propósito: es lo
  /// que mantiene el nombre, las propiedades y los puntos sincronizados con la
  /// esfera mientras se mueve.
  void _onPageChanged(int i) {
    if (_index == i) return;
    setState(() => _index = i);
  }

  bool _onCarouselScroll(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      if (notification.dragDetails != null) _userDragging = true;
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) _userDragging = true;
      return false;
    }

    if (notification is ScrollEndNotification) {
      final bool wasDragged = _userDragging;
      _userDragging = false;

      // Sin dedo de por medio esto es el final de un movimiento que ordenamos
      // nosotros: quien lo ordenó ya reportó, o era mudo a propósito.
      if (!wasDragged) return false;

      // Con dedo, la página donde quedó es una declaración explícita.
      _declare(_index, null);
    }

    return false;
  }

  static SoilTextureSource _sourceFor(SoilTexture texture) =>
      texture == SoilTexture.unknown
      ? SoilTextureSource.unknown
      : SoilTextureSource.declared;

  Future<void> _openGuide() async {
    final result = await showSoilTextureGuideSheet(context);
    if (result == null || !mounted) return;

    final i = _options.indexOf(result);
    if (i < 0) return;

    // La guía marca su propia procedencia: es una aproximación de campo, no una
    // clasificación de laboratorio, y el historial tiene que poder distinguirlo.
    _declare(i, SoilTextureSource.guidedEstimate);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    // ── Por qué la caja de la esfera ENCOGIÓ y la esfera se ve más grande ────
    //
    // No es una contradicción. Los PNG venían en un lienzo de 540 × 675 con la
    // esfera ocupando el 53 % del ancho y el 43 % del alto: con `BoxFit.contain`
    // en una caja cuadrada, una caja de 194 px dibujaba una esfera de 84. Casi
    // dos tercios de la caja —y del presupuesto vertical de la pantalla— eran
    // aire transparente.
    //
    // Los assets se recortaron al contenido, así que ahora la esfera ocupa la
    // caja entera. Con 133 px de caja se dibujan ~125 px de tierra: un 50 % más
    // que antes, ocupando 61 px MENOS de pantalla. Ese es el metro cuadrado que
    // paga que retención y drenaje quepan sin desplazar, y que los iconos de la
    // tarjeta puedan doblar de tamaño sin alargar la pantalla.
    //
    // Se ajusta por altura disponible. Fijar un tamaño provocaría overflow en
    // pantallas pequeñas, que es justo lo que no puede pasar.
    // Un 10 % menos que el primer ajuste: la esfera ya era protagonista y
    // devolver esos píxeles es lo que paga que la tarjeta de retención y
    // drenaje crezca sin que la pantalla vuelva a hacer scroll.
    final heroSize = math
        .min(media.size.width * 0.342, media.size.height * 0.158)
        .clamp(94.0, 137.0);
    final gaugeSize = heroSize + 40;
    final heroBoxHeight = gaugeSize + 8;

    // ── Alturas reservadas: la pantalla NO puede moverse al deslizar ─────────
    //
    // «Franca» lleva píldora y «Arenosa» no; «Guarda poca agua: hay que regar
    // seguido y poco» ocupa dos líneas y «Toca regar» una. Con las cajas
    // ajustadas al contenido, cada swipe cambiaba la altura del bloque y la
    // pantalla entera daba un salto bajo el dedo: el productor deslizaba a la
    // tercera esfera y el botón de confirmar se le movía. Se reserva el caso
    // más alto y todas las texturas ocupan exactamente lo mismo.
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double nameBlockHeight =
        scaler.scale(24) * 1.14 + 7 + (scaler.scale(12.4) * 1.2 + 12) + 8 +
        scaler.scale(12.6) * 1.38 * 2;

    // La tarjeta de propiedades se reserva como MÍNIMO, no como altura impuesta.
    // Con una altura fija había tres formas de desbordar: la rama «No estoy
    // seguro» es un párrafo que crece con la escala de texto; por encima de
    // 1,25× la tarjeta se parte en dos mitades apiladas y mide el doble; y una
    // frase que pasara a tres líneas no cabría. Un mínimo consigue lo que se
    // buscaba —que las cinco texturas minerales midan exactamente lo mismo y la
    // pantalla no salte al deslizar— sin prometer un techo que no se cumple.
    // El apilado depende del ancho Y de la escala de texto, no solo de la
    // escala. Con el icono a 52 px, media tarjeta en un teléfono de 320 deja
    // 43,5 px para «RETENCIÓN DE AGUA» y se recorta a «RETENCI…». Ese ancho no
    // es raro: es el que tiene cualquier Android con el zoom de pantalla
    // subido, que es el ajuste típico de quien no ve bien de cerca — o sea,
    // exactamente la persona a la que el icono grande pretende ayudar.
    final bool stackedProps =
        scaler.scale(12) > 15 || media.size.width < 344;
    // 52 del icono (antes 28) + 6 + 9 de los puntos (antes 7) + 7 + la palabra
    // + 3 + la frase a dos líneas.
    final double propsHalf =
        52 + 6 + 9 + 7 + scaler.scale(13.5) * 1.2 + 3 +
        scaler.scale(11.2) * 1.34 * 2;
    // 2 del filete de _Card + 22 de su padding vertical. Apilada suma las dos
    // mitades más 12 + 1 de divisoria + 12.
    //
    // «No estoy seguro» se excluye del caso apilado a propósito: su tarjeta es
    // un párrafo, no dos mitades, así que reservarle el doble le dejaría 144 px
    // de blanco dentro del recuadro justo con el tamaño de letra de
    // accesibilidad. Ahí mide distinto de las otras cinco, que es lo correcto,
    // porque su contenido también lo es.
    final double propsHeight =
        2 +
        22 +
        (stackedProps && _current != SoilTexture.unknown
            ? propsHalf * 2 + 25
            : propsHalf);

    return FadeTransition(
      opacity: _entryCurve,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (widget.showLeadingMark) ...<Widget>[
            const _LeafMark(),
            const SizedBox(height: 12),
          ],

          _Title(text: widget.title, entry: _entry),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(
              widget.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.6,
                height: 1.42,
                color: _Soil.body,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Hero ────────────────────────────────────────────────────────────
          SizedBox(
            height: heroBoxHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Las flechas se anclan al BISEL, no a los bordes de la caja. Con
                // `left: 0` quedaban a 18 px del medidor en un teléfono de 320 y
                // a 227 px en una tableta: el mismo widget, dos composiciones
                // distintas. Con esto la distancia es siempre la misma y solo
                // vuelven al borde cuando de verdad no cabe más.
                final double inset = math.max(
                  0,
                  (constraints.maxWidth - gaugeSize) / 2 - 44 - 4,
                );

                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Bisel del medidor: detrás de todo, quieto en el centro. No
                    // viaja con las páginas porque no pertenece a ninguna esfera
                    // en particular: es el marco del instrumento.
                    AnimatedBuilder(
                      animation: Listenable.merge(<Listenable>[_halo, _entry]),
                      builder: (context, _) => CustomPaint(
                        size: Size.square(gaugeSize),
                        painter: _GaugePainter(
                          rotation: _reduceMotion
                              ? 0
                              : _halo.value * 2 * math.pi,
                          opacity: Curves.easeOut.transform(_entry.value),
                        ),
                      ),
                    ),

                    NotificationListener<ScrollNotification>(
                      onNotification: _onCarouselScroll,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _options.length,
                        onPageChanged: _onPageChanged,
                        itemBuilder: (context, i) {
                          return _HeroSphere(
                            texture: _options[i],
                            pageController: _pageController,
                            page: i,
                            size: heroSize,
                            idle: _idle,
                            entry: _entry,
                            reduceMotion: _reduceMotion,
                            isFocused: i == _index,
                          );
                        },
                      ),
                    ),

                    Positioned(
                      left: inset,
                      child: _ArrowButton(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Ver la tierra anterior',
                        onTap: _index > 0
                            ? () => _declare(_index - 1, null)
                            : null,
                      ),
                    ),
                    Positioned(
                      right: inset,
                      child: _ArrowButton(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Ver la tierra siguiente',
                        onTap: _index < _options.length - 1
                            ? () => _declare(_index + 1, null)
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Nombre + etiqueta + frase ───────────────────────────────────────
          //
          // El nombre y la etiqueta van ARRIBA, junto a la esfera grande, que es
          // donde el productor está mirando. Debajo, en el mini carrusel, ya no
          // se repiten: seis nombres de 8 px en fila no se leen, y eran 35 px de
          // altura gastados en decir dos veces lo mismo.
          SizedBox(
            height: nameBlockHeight,
            child: _NameBlock(texture: _current),
          ),
          const SizedBox(height: 12),

          // ── Mini carrusel: solo las bolitas ─────────────────────────────────
          _MiniCarousel(
            options: _options,
            index: _index,
            declared: _declared,
            onTap: (i) => _declare(i, null),
          ),
          const SizedBox(height: 12),

          // ── Propiedades ─────────────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: propsHeight),
            child: _PropertiesCard(texture: _current),
          ),
          const SizedBox(height: 10),

          // ── Ayuda ───────────────────────────────────────────────────────────
          //
          // A lo ancho y pegada al CTA. Es la salida de emergencia de la persona
          // para la que existe esta pantalla —la que no sabe qué tierra tiene— y
          // aparece justo donde le entra la duda: al ir a confirmar.
          _HelpRow(onTap: _openGuide),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Piezas
// ═══════════════════════════════════════════════════════════════════════════

/// La hojita sobre el título. Es `Icons.eco_rounded` del catálogo Material que
/// la app ya usa en todas partes: no se añade un PNG nuevo para un adorno de
/// 22 px que además tendría que existir en tres densidades.
class _LeafMark extends StatelessWidget {
  const _LeafMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _Soil.greenSoft,
        ),
        child: const Icon(Icons.eco_rounded, size: 22, color: _Soil.greenDeep),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.text, required this.entry});

  final String text;
  final AnimationController entry;

  @override
  Widget build(BuildContext context) {
    // Entrada: fade + desplazamiento corto. Jerarquía sin "show".
    return AnimatedBuilder(
      animation: entry,
      builder: (context, child) {
        final t = Curves.easeOut.transform(entry.value);
        return Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 24,
          height: 1.16,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          color: _Soil.ink,
        ),
      ),
    );
  }
}

/// El bisel del medidor: pista completa tenue, arco verde parcial, perilla con
/// aro blanco y una corona de marcas que gira despacio.
///
/// **El arco es fijo a propósito.** Un arco que cambiara de longitud con cada
/// textura se leería como una medición —«tu suelo está al 44 %»— y aquí no hay
/// nada medido: el sensor todavía no ha tomado una sola lectura. Fijo es
/// honesto; variable sería una cifra inventada con aspecto de dato.
class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.rotation, required this.opacity});

  /// Giro de la corona de marcas, en radianes.
  final double rotation;

  /// Opacidad global, para que el bisel entre con el resto de la pantalla.
  final double opacity;

  static const double _arcStart = math.pi * 1.06;
  static const double _arcSweep = math.pi * 0.44;
  static const int _tickCount = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0.01) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 3;

    // Pista completa: define el instrumento aunque el arco sea corto.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = _Soil.hair.withValues(alpha: opacity),
    );

    // Corona de marcas. Gira entera y despacio: ambiente, no protagonismo.
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round
      ..color = _Soil.faint.withValues(alpha: 0.34 * opacity);

    final tickOuter = radius - 5;
    final tickInner = radius - 9;
    for (var i = 0; i < _tickCount; i++) {
      final a = rotation + (i / _tickCount) * 2 * math.pi;
      final cosA = math.cos(a);
      final sinA = math.sin(a);
      canvas.drawLine(
        Offset(center.dx + cosA * tickOuter, center.dy + sinA * tickOuter),
        Offset(center.dx + cosA * tickInner, center.dy + sinA * tickInner),
        tick,
      );
    }

    // Arco activo.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      _arcStart,
      _arcSweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..color = _Soil.green.withValues(alpha: 0.95 * opacity),
    );

    // Perilla al final del arco: círculo blanco con núcleo verde.
    final knobAngle = _arcStart + _arcSweep;
    final knob = Offset(
      center.dx + math.cos(knobAngle) * radius,
      center.dy + math.sin(knobAngle) * radius,
    );
    canvas.drawCircle(
      knob,
      5.6,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      knob,
      5.6,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = _Soil.greenHair.withValues(alpha: opacity),
    );
    canvas.drawCircle(
      knob,
      3.2,
      Paint()..color = _Soil.green.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) =>
      old.rotation != rotation || old.opacity != opacity;
}

class _HeroSphere extends StatelessWidget {
  const _HeroSphere({
    required this.texture,
    required this.pageController,
    required this.page,
    required this.size,
    required this.idle,
    required this.entry,
    required this.reduceMotion,
    required this.isFocused,
  });

  final SoilTexture texture;
  final PageController pageController;
  final int page;
  final double size;
  final AnimationController idle;
  final AnimationController entry;
  final bool reduceMotion;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[pageController, idle, entry]),
      builder: (context, _) {
        // Distancia al centro del viewport: 0 = protagonista, 1 = vecina.
        double delta = 0;
        if (pageController.hasClients &&
            pageController.position.haveDimensions) {
          delta = ((pageController.page ?? page.toDouble()) - page).abs();
        }
        final focus = (1.0 - delta).clamp(0.0, 1.0);

        // Swipe: la saliente encoge a 0.90 y se desvanece; la entrante crece.
        // No hay morph de píxeles: transición cruzada + escala + desplazamiento.
        final scale = 0.92 + 0.08 * focus;
        final opacity = 0.30 + 0.70 * focus;

        // Idle: flotación vertical mínima y escala 1.00↔1.01. Evita que parezca
        // una foto pegada; nunca llama la atención.
        final wave = reduceMotion
            ? 0.0
            : math.sin(idle.value * math.pi * 2) * focus;
        final floatY = wave * 3.0;
        final breathe = 1.0 + wave.abs() * 0.01;

        final entryT = Curves.easeOut.transform(entry.value);
        final entryScale = 0.94 + 0.06 * entryT;

        return Center(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale * breathe * (isFocused ? entryScale : 1.0),
              child: SizedBox(
                width: size + 20,
                height: size + 34,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // ── La sombra de contacto ──────────────────────────────
                    //
                    // Era un `Container` negro con `borderRadius` y un
                    // `boxShadow` encima: un rectángulo de color plano con
                    // bordes duros que se leía como una barra gris debajo de la
                    // esfera, no como una sombra.
                    //
                    // Ahora es un degradado radial dentro de una caja ancha y
                    // baja: el gradiente se mapea a la caja, así que sale un
                    // óvalo que se apaga hacia fuera y **no tiene borde**. Tres
                    // paradas —núcleo, halo, nada— en vez de un salto.
                    //
                    // Y responde a la física de la flotación, no a su valor
                    // absoluto. Antes usaba `wave.abs()`, que hace lo mismo
                    // subiendo que bajando; la sombra no distingue arriba de
                    // abajo y el efecto se pierde. Con el signo: esfera abajo
                    // (`wave > 0`) → sombra más ancha, más oscura y más
                    // recogida; esfera arriba → más pequeña, más clara y más
                    // difusa. Es lo que hace que la bolita parezca separarse
                    // del suelo en vez de deslizarse sobre él.
                    Positioned(
                      bottom: 1,
                      child: Opacity(
                        opacity: ((0.16 + 0.05 * wave) * focus).clamp(0.0, 1.0),
                        child: Container(
                          width: size * (0.64 + 0.07 * wave),
                          height: size * (0.17 - 0.02 * wave),
                          decoration: const BoxDecoration(
                            shape: BoxShape.rectangle,
                            gradient: RadialGradient(
                              // Verde muy desaturado, no negro puro: sobre
                              // blanco cálido el negro se ve sucio y la sombra
                              // acaba pareciendo una mancha.
                              colors: <Color>[
                                Color(0x8A1A2A24),
                                Color(0x3D1A2A24),
                                Color(0x001A2A24),
                              ],
                              stops: <double>[0.0, 0.48, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    Transform.translate(
                      offset: Offset(0, floatY),
                      child: Semantics(
                        image: true,
                        // Para «No estoy seguro» NO se dictan los niveles. Los
                        // getters devuelven 0 ahí, y «retención 0 de 5» no es
                        // «no se sabe»: es el fondo de la escala. La tarjeta de
                        // abajo ya se calla ese dato para quien ve; callarlo
                        // solo para quien ve y dictárselo a quien no ve
                        // invierte exactamente la regla que esta pantalla
                        // defiende.
                        label: texture == SoilTexture.unknown
                            ? '${texture.displayNameEs}. '
                                  '${texture.visualReadingEs} '
                                  'Todavía no sabemos su retención ni su drenaje.'
                            : '${texture.displayNameEs}. '
                                  '${texture.shortLabelEs}. '
                                  '${texture.visualReadingEs} '
                                  'Retención de agua '
                                  '${texture.waterRetention05} de 5. '
                                  'Drenaje ${texture.drainage05} de 5.',
                        child: Image.asset(
                          texture.assetPath,
                          width: size,
                          height: size,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                          errorBuilder: (_, _, _) => _AssetFallback(size: size),
                        ),
                      ),
                    ),

                    // Aquí vivía una «?» dibujada con `Text` encima de la
                    // esfera de «No estoy seguro». Sobra: el propio asset
                    // `soil_texture_unknown.png` ya trae la interrogación verde
                    // pintada sobre la tierra, así que se veían DOS.
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AssetFallback extends StatelessWidget {
  const _AssetFallback({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            const Color(0xFFB79B7C),
            const Color(0xFF6E5843).withValues(alpha: 0.9),
          ],
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: tooltip,
      child: Material(
        color: Colors.white,
        shape: CircleBorder(
          side: BorderSide(
            color: enabled ? _Soil.hair : _Soil.hair.withValues(alpha: 0.55),
          ),
        ),
        elevation: enabled ? 1.5 : 0,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          // Objetivo táctil mínimo 44×44, incluso con el círculo visual menor.
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: enabled ? _Soil.ink : _Soil.faint.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nombre técnico, etiqueta cotidiana y frase de una línea.
///
/// Las tres cajas tienen ALTURA FIJA, calculada desde la escala de texto del
/// sistema y reservada para el peor caso. Antes se ajustaban al contenido y la
/// pantalla daba un salto en cada deslizamiento: «Arenosa» no lleva píldora
/// —nombre técnico y cotidiano son la misma palabra— y su frase cabe en una
/// línea, mientras «Franco-arenosa» lleva píldora y ocupa dos. Ese salto movía
/// el botón de confirmar bajo el dedo del productor.
class _NameBlock extends StatelessWidget {
  const _NameBlock({required this.texture});

  final SoilTexture texture;

  @override
  Widget build(BuildContext context) {
    final isUnknown = texture == SoilTexture.unknown;
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final bool hasPill = texture.shortLabelEs != texture.displayNameEs;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Column(
        key: ValueKey<SoilTexture>(texture),
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: scaler.scale(24) * 1.14,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                texture.displayNameEs,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: _Soil.ink,
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          // La caja de la píldora se reserva SIEMPRE, aunque la textura no la
          // lleve: es lo que mantiene la frase y la tarjeta de propiedades a la
          // misma altura en las seis esferas.
          SizedBox(
            height: scaler.scale(12.4) * 1.2 + 12,
            child: hasPill
                ? _Pill(text: texture.shortLabelEs, muted: isUnknown)
                : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: scaler.scale(12.6) * 1.38 * 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                texture.plainDescriptionEs,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.6,
                  height: 1.38,
                  color: _Soil.body,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.muted = false});

  final String text;

  /// «Sin definir» no puede llevar el verde de marca: el verde afirma, y ahí no
  /// hay nada afirmado.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: muted ? const Color(0xFFF1F4F3) : _Soil.greenSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: muted ? _Soil.hair : _Soil.greenHair),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.4,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: muted ? _Soil.body : _Soil.greenDeep,
        ),
      ),
    );
  }
}

/// Base de todas las tarjetas de esta pantalla: blanca, filete de 1 px y una
/// sombra muy corta. Sustituye al cristal esmerilado del resto del wizard
/// porque sobre él las tipografías de 10–11 px de las propiedades pierden
/// contraste, y estas tarjetas son de lectura, no de ambiente.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});

  final Widget child;
  final EdgeInsets padding;

  /// Fijo. Fue un parámetro que nadie llegó a pasar nunca, y un parámetro
  /// opcional sin un solo consumidor es una promesa de flexibilidad que además
  /// el analizador reporta.
  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(color: _Soil.hair),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MiniCarousel extends StatelessWidget {
  const _MiniCarousel({
    required this.options,
    required this.index,
    required this.declared,
    required this.onTap,
  });

  final List<SoilTexture> options;
  final int index;

  /// Si hay una textura DECLARADA. Con `false` la celda central se resalta con
  /// gris —está a la vista— pero sin aro verde ni palomita: no hay respuesta
  /// que confirmar todavía.
  final bool declared;

  final ValueChanged<int> onTap;

  /// Separación entre celdas. Ya no compite con ningún texto —los nombres se
  /// quitaron de aquí—, así que puede respirar.
  static const double _separator = 6;

  @override
  Widget build(BuildContext context) {
    // ── Solo las bolitas ─────────────────────────────────────────────────────
    //
    // Debajo de cada esfera vivían el nombre técnico a 8,4 px en dos líneas y la
    // etiqueta corta a 7,8 px. Nadie lee 8 px en el campo, y esos dos renglones
    // costaban ~35 px de altura para repetir exactamente lo que el bloque de
    // arriba ya dice en 24 px sobre la esfera grande. Además obligaban a la fila
    // a decidir entre una y dos líneas según el ancho, y de ahí salía media
    // docena de reglas de layout para que las seis esferas quedaran a la misma
    // altura. Sin texto, la fila es una fila de bolitas y ya.
    //
    // El nombre no se pierde para quien no ve: sigue íntegro en el `Semantics`
    // de cada celda.
    //
    // El ancho de celda se mide, no se supone: un `SizedBox(40, 40)` bajo un
    // ancho menor no desborda, se deforma en silencio a 33 × 40 y la imagen
    // queda ovalada. Midiendo, la esfera es `min(46, celda)` y siempre cuadrada.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final int n = options.length;
          final double cell =
              (constraints.maxWidth - (n - 1) * _separator) / n;
          // 8 de padding horizontal —`EdgeInsets.all(4)` a cada lado— más 3,2
          // del aro de selección, que `Border` suma aunque sea transparente.
          // Descontar de menos no desborda: encoge la caja en silencio y deja
          // la esfera ovalada con banda muerta arriba y abajo.
          final double content = math.max(24.0, cell - 11.2);

          final children = <Widget>[];
          for (var i = 0; i < n; i++) {
            if (i > 0) children.add(const SizedBox(width: _separator));
            children.add(
              SizedBox(
                width: cell,
                child: _MiniItem(
                  texture: options[i],
                  focused: i == index,
                  declared: declared,
                  sphereSize: math.min(46.0, content),
                  onTap: () => onTap(i),
                ),
              ),
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: children,
          );
        },
      ),
    );
  }
}

class _MiniItem extends StatefulWidget {
  const _MiniItem({
    required this.texture,
    required this.focused,
    required this.declared,
    required this.sphereSize,
    required this.onTap,
  });

  final SoilTexture texture;

  /// La celda que está en el centro del carrusel. Puede estar enfocada **sin**
  /// estar declarada: es lo que se ve, no lo que se contestó.
  final bool focused;

  /// Si ya hay una respuesta en firme. Enfocada + declarada = seleccionada.
  final bool declared;

  final double sphereSize;
  final VoidCallback onTap;

  bool get isSelected => focused && declared;

  @override
  State<_MiniItem> createState() => _MiniItemState();
}

class _MiniItemState extends State<_MiniItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 190),
    lowerBound: 0,
    upperBound: 1,
  );

  @override
  void didUpdateWidget(covariant _MiniItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Confirmación visual: aro verde + micro escala 1.00 → 1.04 → 1.00.
    if (widget.isSelected && !oldWidget.isSelected) {
      _pulse.forward(from: 0).then((_) {
        if (mounted) _pulse.reverse();
      });
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.texture;
    final isUnknown = t == SoilTexture.unknown;
    final selected = widget.isSelected;

    return Semantics(
      button: true,
      selected: selected,
      label: isUnknown
          ? t.displayNameEs
          : '${t.displayNameEs}, ${t.shortLabelEs}',
      hint: selected ? null : 'Toca para elegir esta tierra',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) =>
              Transform.scale(scale: 1.0 + 0.04 * _pulse.value, child: child),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: selected
                  ? _Soil.greenSoft
                  : widget.focused
                  // Enfocada pero sin declarar: gris, nunca verde. El verde
                  // afirma, y aquí todavía no se ha afirmado nada.
                  ? const Color(0xFFF4F6F5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _Soil.green : Colors.transparent,
                width: 1.6,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: <Widget>[
                    // ── Las SEIS celdas usan el mismo asset ─────────────────
                    //
                    // «No estoy seguro» pintaba aquí un círculo gris con una
                    // «?» dibujada con `Text`, así que en la fila había cinco
                    // bolitas de tierra y un hueco gris. Su asset existe
                    // —`soil_texture_unknown.png`, tierra con la interrogación
                    // verde encima— y es el mismo que ya sale en el hero: la
                    // fila tiene que enseñar exactamente lo que el productor va
                    // a ver al centrarla.
                    //
                    // Mismo asset que el hero, reducido. No hay un segundo
                    // juego de imágenes, y `cacheWidth` evita decodificar el
                    // asset completo seis veces en una fila pequeña.
                    SizedBox(
                      width: widget.sphereSize,
                      height: widget.sphereSize,
                      child: Image.asset(
                        t.assetPath,
                        // 160 y no 120: el asset se recortó al contenido, así
                        // que la esfera pasó a ocupar la caja entera y a
                        // dibujarse al doble de tamaño real. Con 120 se veía
                        // suave en pantallas de 3×.
                        cacheWidth: 160,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) =>
                            _AssetFallback(size: widget.sphereSize * 0.9),
                      ),
                    ),
                    // Aro, palomita Y texto. La selección NO puede depender solo
                    // del color verde: es requisito de accesibilidad, no adorno.
                    // Va en un `Stack` y no en la columna porque
                    // `Transform.translate` desplaza el pintado pero no encoge la
                    // caja: sumaba 16 px al alto y desbordaba la fila.
                    if (selected)
                      Positioned(
                        right: -1,
                        bottom: -1,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _Soil.green,
                            border: Border.all(color: Colors.white, width: 1.4),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
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

class _PropertiesCard extends StatelessWidget {
  const _PropertiesCard({required this.texture});

  final SoilTexture texture;

  @override
  Widget build(BuildContext context) {
    if (texture == SoilTexture.unknown) {
      // Con «No estoy seguro» NO se pintan 3/5 y 3/5 como si fueran verdad.
      // Mostrar los números de la media aquí sería inventar una lectura que el
      // productor no dio.
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _Card(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Sin círculo alrededor: el glifo va solo, y al mismo tamaño que
              // los de retención y drenaje para que la tarjeta pese igual
              // eligiendo «No estoy seguro». Informativo, no interrogativo: la
              // «?» de la ayuda abre la guía, y repetir ese mismo glifo aquí
              // —donde no abre nada— enseña a ignorarlo justo donde sirve.
              const Icon(
                Icons.info_outline_rounded,
                size: 40,
                color: _Soil.greenDeep,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // El contrato pide la palabra, no el hueco: «Variable» dice
                    // que no se sabe. Los cinco puntos siguen sin pintarse, que
                    // es lo que habría inventado una lectura.
                    Text(
                      'Retención de agua: ${texture.retentionWordEs} · '
                      'Drenaje: ${texture.drainageWordEs}',
                      style: const TextStyle(
                        fontSize: 12.4,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        color: _Soil.greenDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'BIO-G usará temporalmente una tierra media hasta que la '
                      'cambies, y te lo dirá cuando te recomiende un riego.',
                      style: TextStyle(
                        fontSize: 12.2,
                        height: 1.42,
                        color: _Soil.body,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final retention = _PropertyHalf(
      // Se reutiliza el icono de humedad que ya existe en la app: no se crea un
      // juego de iconos nuevo para esta pantalla.
      iconAsset: 'assets/icons/metrics/ic_moisture.png',
      fallbackIcon: Icons.water_drop_rounded,
      title: 'RETENCIÓN DE AGUA',
      spokenTitle: 'Retención de agua',
      tint: _Soil.water,
      level: texture.waterRetention05,
      word: texture.retentionWordEs,
      sentence: texture.retentionSentenceEs,
    );

    final drainage = _PropertyHalf(
      iconAsset: 'assets/icons/metrics/ic_riego.png',
      fallbackIcon: Icons.filter_alt_outlined,
      title: 'DRENAJE',
      spokenTitle: 'Drenaje',
      tint: _Soil.greenDeep,
      level: texture.drainage05,
      word: texture.drainageWordEs,
      sentence: texture.drainageSentenceEs,
    );

    // Dos motivos para apilar, y hay que mirar los dos. Con el texto del
    // sistema agrandado media tarjeta se queda sin sitio para el título; y con
    // el icono a 52 px lo mismo ocurre por ancho, a partir de ~344 px de
    // pantalla hacia abajo: «RETENCIÓN DE AGUA» se recorta a «RETENCI…».
    // Apretar la tipografía solo aplaza el problema; apilando, cada mitad
    // dispone del ancho entero. En un teléfono normal y con letra normal —el
    // 95 % de los casos— la tarjeta sigue partida en dos, como el diseño.
    //
    // Este umbral tiene que ser el MISMO que el de `stackedProps` en `build`,
    // que es quien reserva la altura.
    final stacked = MediaQuery.textScalerOf(context).scale(12) > 15 ||
        MediaQuery.sizeOf(context).width < 344;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _Card(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  retention,
                  const Padding(
                    padding: EdgeInsets.fromLTRB(13, 12, 13, 12),
                    child: Divider(height: 1, thickness: 1, color: _Soil.hair),
                  ),
                  drainage,
                ],
              )
            // `IntrinsicHeight` para que el filete central llegue exactamente
            // hasta el borde inferior del lado más alto: sin él, una frase de
            // dos líneas a la izquierda y una de una a la derecha dejan el
            // filete cortado.
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(child: retention),
                    Container(width: 1, color: _Soil.hair),
                    Expanded(child: drainage),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PropertyHalf extends StatelessWidget {
  const _PropertyHalf({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.title,
    required this.spokenTitle,
    required this.tint,
    required this.level,
    required this.word,
    required this.sentence,
  });

  final String iconAsset;
  final IconData fallbackIcon;

  /// El título en versales, como se pinta.
  final String title;

  /// El mismo título en caja normal, para el lector de pantalla: varios motores
  /// de voz deletrean letra a letra lo que llega en mayúsculas.
  final String spokenTitle;

  final Color tint;
  final int level;
  final String word;
  final String sentence;

  static const String _scaleNoteEs =
      'Escala comparativa entre texturas, de 1 a 5. No es un porcentaje ni una '
      'lectura del sensor.';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // La advertencia va DENTRO de la etiqueta. Vivía solo en un `Tooltip`, y
      // el `excludeSemantics` de aquí borraba el nodo entero: el lector de
      // pantalla oía «3 de 5» y jamás la aclaración de que no es una medición.
      // Justo al revés de lo que hace falta.
      label: '$spokenTitle: $word, $level de 5. $sentence $_scaleNoteEs',
      excludeSemantics: true,
      // El objetivo táctil de la aclaración es la mitad entera de la tarjeta, no
      // el glifo de 12 px: esta pantalla se usa en el campo, a veces con guante.
      child: Tooltip(
        message: _scaleNoteEs,
        triggerMode: TooltipTriggerMode.tap,
        showDuration: const Duration(seconds: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  // ── El icono va SOLO, y grande ────────────────────────────
                  //
                  // Empezó dentro de un círculo de 26 px con el glifo a 14: el
                  // recuadro competía con la propia gota —que ya trae su color
                  // y su volumen— y a 14 px, sobre un fondo blanco y a un brazo
                  // de distancia en el campo, la gota sencillamente no se leía.
                  //
                  // Ahora son 52 px sin fondo: el doble del primer ajuste y
                  // casi cuatro veces el glifo original. La tarjeta NO crece por
                  // ello —los 24 px extra salen del hueco entre el icono y los
                  // puntos, y del 10 % que devolvió la esfera— y el icono pasa
                  // a ser lo primero que se ve de la tarjeta, que es justo lo
                  // que le faltaba de protagonismo.
                  Image.asset(
                    iconAsset,
                    width: 52,
                    height: 52,
                    cacheWidth: 156,
                    errorBuilder: (_, _, _) =>
                        Icon(fallbackIcon, size: 52, color: tint),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 8.6,
                        height: 1.2,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        color: _Soil.faint,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 2),
                    child: Icon(
                      Icons.info_outline_rounded,
                      size: 11,
                      color: _Soil.faint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // ── Los puntos, con halo ──────────────────────────────────────
              //
              // 9 px en vez de 7, y los encendidos llevan un resplandor del
              // mismo tinte. El halo NO es decoración: son cinco puntos de
              // 7 px sobre blanco, y encendido y apagado se distinguían solo
              // por el color —lo que la pauta de accesibilidad de esta pantalla
              // prohíbe—. Con el halo la diferencia también es de forma.
              Row(
                children: List<Widget>.generate(5, (i) {
                  final on = i < level;
                  return Container(
                    margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: on ? tint : _Soil.hair,
                      boxShadow: on
                          ? <BoxShadow>[
                              BoxShadow(
                                color: tint.withValues(alpha: 0.45),
                                blurRadius: 7,
                                spreadRadius: 0.4,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 7),
              Text(
                word,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  color: tint,
                ),
              ),
              const SizedBox(height: 3),
              // Dos líneas fijas: «Toca regar» ocupa una y «Guarda poca agua:
              // hay que regar seguido y poco» ocupa dos. Sin el tope, la
              // tarjeta cambiaba de alto con cada esfera y la pantalla saltaba.
              Text(
                sentence,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.2,
                  height: 1.34,
                  color: _Soil.body,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La fila de ayuda, a lo ancho.
///
/// Estuvo compartiendo la fila con los nombres locales, a media anchura. Es la
/// salida de emergencia de quien no sabe qué tierra tiene —o sea, la persona
/// exacta para la que se escribió esta pantalla—, y dejarla en 165 px la ponía
/// al mismo peso visual que un dato que no cambia un solo cálculo.
class _HelpRow extends StatelessWidget {
  const _HelpRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // «Probar ahora» cuesta 70 px, y por debajo de ~352 px de pantalla esos
          // 70 px se los quita al subtítulo, que entonces pierde la última
          // palabra. El galón solo ya dice que se abre algo; el texto de la
          // tarjeta ya dice qué. Se cae la etiqueta, no la frase.
          //
          // El umbral es sobre el ancho QUE LLEGA AQUÍ, que es el de la pantalla
          // menos 32 px de márgenes. Con 330 el corte caía en 362 px de pantalla
          // y un teléfono Android de 360 —el ancho más común que existe— perdía
          // la etiqueta sin ganar nada: el subtítulo cabía igual.
          final bool wide = constraints.maxWidth >= 320;

          return _TileCard(
            // El signo de interrogación del propio juego de iconos de la app,
            // recortado a su contenido. Un reloj de arena para «¿no sabes cuál
            // elegir?» hablaba del tiempo que cuesta, no de la duda que se
            // resuelve.
            iconAsset: 'assets/icons/metrics/ic_soil_help.png',
            fallbackIcon: Icons.help_outline_rounded,
            tint: _Soil.greenDeep,
            title: '¿No sabes cuál elegir?',
            subtitle:
                'Identifica tu tierra en 20 segundos con 3 preguntas simples.',
            hint: 'Abre tres preguntas para identificar tu tierra',
            trailing: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (wide)
                    const Text(
                      'Probar ahora',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _Soil.greenDeep,
                      ),
                    ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: _Soil.greenDeep,
                  ),
                ],
              ),
            ),
            onTap: onTap,
          );
        },
      ),
    );
  }
}

class _TileCard extends StatelessWidget {
  const _TileCard({
    required this.iconAsset,
    required this.fallbackIcon,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
    this.hint,
  });

  final String iconAsset;
  final IconData fallbackIcon;
  final Color tint;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback onTap;

  /// Lo que el lector de pantalla añade tras el título: lo que va a pasar al
  /// activar la tarjeta, que ni el título ni el subtítulo dicen.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      // Sin el punto tras el «?» y con coma en vez de «·»: varios motores de voz
      // leen «?.» como dos signos y el punto medio de forma impredecible.
      label: '$title ${subtitle.replaceAll(' · ', ', ')}',
      hint: hint,
      excludeSemantics: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 62),
            padding: const EdgeInsets.fromLTRB(11, 10, 8, 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _Soil.hair),
            ),
            child: Row(
              children: <Widget>[
                // Sin recuadro y al tamaño del wizard, igual que los iconos de
                // retención y drenaje.
                Image.asset(
                  iconAsset,
                  width: 28,
                  height: 28,
                  cacheWidth: 84,
                  errorBuilder: (_, _, _) =>
                      Icon(fallbackIcon, size: 26, color: tint),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.8,
                          height: 1.22,
                          fontWeight: FontWeight.w700,
                          color: _Soil.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.6,
                          height: 1.22,
                          color: _Soil.faint,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
