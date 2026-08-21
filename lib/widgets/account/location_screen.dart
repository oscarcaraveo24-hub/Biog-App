// lib/widgets/account/location_screen.dart
//
// Elegir dónde está la parcela.
//
// ═════════════════════════════════════════════════════════════════════════════
// LO QUE SE ARREGLÓ AQUÍ
// ═════════════════════════════════════════════════════════════════════════════
//
// ── 1. El salto de cámara al abrir ───────────────────────────────────────────
//
// El mapa se construía con CDMX como `initialCameraPosition` y las
// preferencias se leían después, en paralelo. Al volver, `_handleMapCreated`
// movía la cámara a CDMX y milisegundos más tarde `_loadSavedLocation`
// la animaba hasta la parcela real. El usuario veía abrirse el Zócalo y
// después un viaje hasta su terreno. Eso era el «se siente medio bugeado».
//
// Ahora el mapa NO se construye hasta saber dónde apuntar. Leer preferencias
// es una operación de memoria (el `SharedPreferences` ya está instanciado
// desde `main`), así que la espera dura un fotograma y no hay estado
// intermedio que enseñar.
//
// ── 2. Dos peticiones de geocodificación por cada gesto ──────────────────────
//
// `onCameraIdle` dispara `onCenterChanged`, y `onCameraIdle` se emite TAMBIÉN
// cuando la cámara la movió el propio código. La secuencia real de una
// búsqueda era:
//
//   buscar dirección  → 1 llamada (forward)
//   mover la cámara   → onCameraIdle → 1 llamada (reverse)  ← sobra
//
// Es decir, se le pedía a Google el nombre de un punto cuyo nombre Google
// acababa de dar. Además provocaba el parpadeo de la etiqueta. `_skipNextIdle`
// distingue el movimiento programático del dedo del usuario.
//
// ── 3. Respuestas fuera de orden ─────────────────────────────────────────────
//
// Arrastrando el mapa varias veces seguidas quedaban varias peticiones en
// vuelo y ganaba la que respondiera última, no la del punto actual. La
// etiqueta podía acabar mostrando una dirección que el usuario ya había
// dejado atrás. `_geocodeSeq` descarta toda respuesta que no sea de la última
// petición emitida.
//
// ── 4. Se perdía el nombre bueno cuando fallaba la red ───────────────────────
//
// Sin llave o sin conexión, la etiqueta se sobrescribía con «Ubicación
// seleccionada», pisando un nombre correcto que ya estaba guardado. Ahora un
// fallo deja intacto lo que hubiera.
//
// ── 5. No se guardaba de verdad ──────────────────────────────────────────────
//
// `_save` escribía tres claves de preferencias y nada más. La fila «Ubicación»
// de la Cuenta lee OTRA clave (`profile_location`), así que no se enteraba, y
// la nube no se enteraba nunca. Todo eso vive ahora en `ParcelLocationStore`,
// que escribe las dos claves y espeja a Supabase en la misma operación.
//
// ── 6. El botón de localizar no localizaba ───────────────────────────────────
//
// El icono de la izquierda del buscador es un pin de «llévame a mi posición»
// y lo único que hacía era recentrar la cámara sobre el punto que ya estaba
// elegido, un gesto sin efecto visible salvo que hubieras arrastrado el mapa.
// Ahora pide GPS —igual que el asistente de alta, con el mismo manejo de
// permisos— y si algo falla recentra como antes, sin bloquear nunca.
//
// NADA de la presentación cambió: los mismos widgets, los mismos colores, las
// mismas medidas.

import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:bio_g/core/geo/geocoding_service.dart';
import 'package:bio_g/core/profile/parcel_location_store.dart';

class LocationScreen extends StatefulWidget {
  final String initialValue;
  final Color brandMid;

  const LocationScreen({
    super.key,
    required this.initialValue,
    required this.brandMid,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  /// Encuadre inicial cuando no hay nada guardado: CDMX.
  ///
  /// ⚠️ Es SOLO un encuadre, nunca una ubicación válida para guardar. `_save`
  /// escribía `_center` tal cual, así que quien abriera esta pantalla y tocara
  /// «Guardar» sin mover nada se llevaba CDMX a sus preferencias — y de ahí al
  /// `DeviceCropContext`, al registro auditable y al motor de riego, que
  /// acababa razonando sobre la lluvia de una ciudad ajena creyendo que era la
  /// parcela del agricultor. `_hasExplicitPick` lo impide.
  static const LatLng _kDefault = LatLng(19.4326, -99.1332);

  /// Lo que se enseña mientras no se conoce el nombre del sitio.
  ///
  /// NO es un nombre, y por eso no se guarda. Se guardaba: abrir la pantalla
  /// sin ubicación previa, arrastrar el mapa y pulsar «Guardar» con el
  /// geocodificado caído —sin red o sin llave de Google— escribía literalmente
  /// «Ubicación actual» como nombre de la parcela, y de ahí pasaba a la fila
  /// «Ubicación» de la Cuenta y a `profiles.location`, que es lo que lee el
  /// panel. Un pin llamado «Ubicación actual» no le dice nada a nadie.
  static const String _kPlaceholderLabel = 'Ubicación actual';

  static bool _isPlaceholderLabel(String value) =>
      value.isEmpty || value == _kPlaceholderLabel;

  /// Último recurso para el nombre del sitio: las propias coordenadas.
  ///
  /// Se usa cuando ni Google ni el usuario dieron un nombre. Son feas de leer,
  /// pero son ciertas y localizan la parcela; «Ubicación actual» no hace ni lo
  /// uno ni lo otro. Devolver cadena vacía tampoco valdría: esta pantalla
  /// contesta con un String al volver, y quien la abrió no sabría distinguir
  /// «guardé sin nombre» de «cancelé».
  static String _coordinateLabel(LatLng p) =>
      '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

  static const double _kZoomSaved = 15.5;
  static const double _kZoomPicked = 16.0;

  /// Cuánto se espera tras soltar el mapa antes de preguntar la dirección.
  /// Suficiente para que un arrastre en varios tirones cuente como uno solo.
  static const Duration _kGeocodeDebounce = Duration(milliseconds: 520);

  /// 1e-6 grados son ~11 cm: cualquier arrastre real queda por encima, y un
  /// `onCameraIdle` disparado al asentarse la cámara inicial queda por debajo
  /// y no cuenta como elección del usuario.
  static bool _isDefaultCenter(LatLng p) =>
      (p.latitude - _kDefault.latitude).abs() < 1e-6 &&
      (p.longitude - _kDefault.longitude).abs() < 1e-6;

  final Completer<GoogleMapController> _mapC = Completer<GoogleMapController>();
  final FocusNode _searchFocus = FocusNode();
  static const GeocodingService _geocoder = GeocodingService();

  late final TextEditingController _searchC = TextEditingController(
    text: widget.initialValue,
  );

  /// Null hasta que se sabe dónde apuntar. Mientras tanto no hay mapa que
  /// construir: ver el punto 1 de la cabecera.
  LatLng? _center;

  String _currentLabel = '';
  bool _loadingAddress = false;
  bool _saving = false;
  bool _locating = false;

  /// True cuando las coordenadas de `_center` las eligió el usuario de verdad:
  /// vienen de sus preferencias, de una búsqueda, del GPS o de haber movido el
  /// mapa. Mientras sea false, `_center` es el encuadre por defecto y no se
  /// guarda.
  bool _hasExplicitPick = false;

  ParcelLocationOrigin _origin = ParcelLocationOrigin.map;

  Timer? _debounce;

  /// Contador de peticiones. Una respuesta solo se aplica si sigue siendo la
  /// última pedida (punto 3 de la cabecera).
  int _geocodeSeq = 0;

  /// El siguiente `onCameraIdle` lo provocó el código, no el dedo: se ignora
  /// (punto 2 de la cabecera).
  bool _skipNextIdle = false;

  /// Todavía no ha llegado el `onCameraIdle` con el que el mapa anuncia que
  /// terminó de asentarse al nacer.
  ///
  /// Ese primer aviso NO es un gesto: es el mapa diciendo «ya cargué». Si se
  /// trata como movimiento, abrir la pantalla con una ubicación guardada
  /// dispara un geocodificado inverso que vuelve a preguntar por un nombre que
  /// ya se conoce — una llamada de Google regalada y un parpadeo de la
  /// etiqueta cada vez que se entra.
  ///
  /// Se compara contra el punto de partida en vez de ignorar el primer aviso a
  /// ciegas: si el usuario alcanzó a arrastrar antes de que el mapa terminara
  /// de cargar, su gesto no se pierde.
  bool _awaitingFirstIdle = true;

  bool get _ready => _center != null;

  @override
  void initState() {
    super.initState();
    _currentLabel = widget.initialValue.trim().isEmpty
        ? _kPlaceholderLabel
        : widget.initialValue.trim();
    unawaited(_restoreSavedLocation());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    // Invalida cualquier respuesta en vuelo: al volver ya no hay pantalla que
    // actualizar y `setState` sobre un State desmontado es un error.
    _geocodeSeq++;
    _searchC.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  // ── Arranque ───────────────────────────────────────────────────────────────

  Future<void> _restoreSavedLocation() async {
    final StoredParcelLocation? saved = await ParcelLocationStore.readLocal();
    if (!mounted) return;

    if (saved == null) {
      setState(() => _center = _kDefault);
      return;
    }

    setState(() {
      _center = LatLng(saved.lat, saved.lng);
      // Ya tenía ubicación guardada: puede reconfirmarla sin mover el mapa.
      _hasExplicitPick = true;
      _origin = saved.origin ?? ParcelLocationOrigin.map;

      if (saved.label.isNotEmpty) {
        _currentLabel = saved.label;
        if (!_searchFocus.hasFocus) _searchC.text = saved.label;
      }
    });

    // Solo se pregunta la dirección si NO había una guardada. Reconsultar un
    // nombre que ya se conoce gasta una llamada de Google y, cuando falla,
    // hace parpadear la etiqueta sin aportar nada.
    if (saved.label.isEmpty) {
      unawaited(_reverseGeocode(LatLng(saved.lat, saved.lng)));
    }
  }

  // ── Cámara ─────────────────────────────────────────────────────────────────

  /// Mueve la cámara marcando el movimiento como programático para que el
  /// `onCameraIdle` que llegue después no se confunda con un gesto.
  Future<void> _moveCameraTo(LatLng target, {required double zoom}) async {
    // Sin mapa todavía no hay cámara que mover, y tampoco hace falta: el mapa
    // aún no ha nacido y nacerá apuntando a `_center`, que ya vale `target`.
    // Esperar aquí a un `Completer` que quizá no se complete dejaría colgada
    // la llamada que nos trajo.
    if (!_mapC.isCompleted) return;

    _skipNextIdle = true;
    try {
      final GoogleMapController c = await _mapC.future;
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: zoom),
        ),
      );
    } catch (_) {
      // El mapa aún no existe o ya se destruyó. La bandera se limpia sola en
      // el siguiente idle real; dejarla puesta solo costaría ignorar un gesto.
      _skipNextIdle = false;
    }
  }

  void _handleMapCreated(GoogleMapController c) {
    if (!_mapC.isCompleted) _mapC.complete(c);
    // No se mueve nada: el mapa ya nació apuntando a `_center`, porque no se
    // construye hasta conocerlo.
  }

  void _handleCameraIdle(LatLng target) {
    if (_skipNextIdle) {
      _skipNextIdle = false;
      return;
    }

    if (_awaitingFirstIdle) {
      _awaitingFirstIdle = false;
      final LatLng? origin = _center;
      final bool sameSpot =
          origin != null &&
          (origin.latitude - target.latitude).abs() < 1e-6 &&
          (origin.longitude - target.longitude).abs() < 1e-6;
      // El mapa acaba de asentarse donde se le dijo: no hay nada que
      // recalcular.
      if (sameSpot) return;
    }

    _center = target;
    if (!_isDefaultCenter(target)) {
      _hasExplicitPick = true;
      _origin = ParcelLocationOrigin.map;
    }
    _scheduleReverseGeocode(target);
  }

  // ── Dirección a partir del punto ───────────────────────────────────────────

  void _scheduleReverseGeocode(LatLng target) {
    _debounce?.cancel();
    _debounce = Timer(_kGeocodeDebounce, () {
      unawaited(_reverseGeocode(target));
    });
  }

  Future<void> _reverseGeocode(LatLng target) async {
    final int seq = ++_geocodeSeq;

    if (mounted) setState(() => _loadingAddress = true);

    try {
      final String label = await _geocoder.reverseGeocode(
        target.latitude,
        target.longitude,
      );

      // Llegó tarde: ya hay otra petición más reciente. Se descarta.
      if (seq != _geocodeSeq || !mounted) return;

      setState(() {
        _currentLabel = label;
        _loadingAddress = false;
        if (!_searchFocus.hasFocus) _searchC.text = label;
      });
    } on GeocodingException {
      // Sin llave, sin red o sin resultado: se conserva la etiqueta que
      // hubiera. Pisar un nombre bueno con «Ubicación seleccionada» era el
      // punto 4 de la cabecera.
      if (seq != _geocodeSeq || !mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  // ── Buscar una dirección ───────────────────────────────────────────────────

  Future<void> _searchAndGo() async {
    final String q = _searchC.text.trim();
    if (q.isEmpty) return;

    _searchFocus.unfocus();
    _debounce?.cancel();

    final int seq = ++_geocodeSeq;
    setState(() => _loadingAddress = true);

    try {
      final GeocodedPlace place = await _geocoder.search(q);
      if (seq != _geocodeSeq || !mounted) return;

      final LatLng target = LatLng(place.lat, place.lng);

      setState(() {
        _center = target;
        _currentLabel = place.label;
        _loadingAddress = false;
        // Buscó una dirección y Google la resolvió: elección explícita.
        _hasExplicitPick = true;
        _origin = ParcelLocationOrigin.search;
        if (!_searchFocus.hasFocus) _searchC.text = place.label;
      });

      // Google ya devolvió el nombre en la misma respuesta: no hace falta
      // volver a preguntárselo tras mover la cámara.
      await _moveCameraTo(target, zoom: _kZoomPicked);
    } on GeocodingException catch (e) {
      if (seq != _geocodeSeq || !mounted) return;
      setState(() => _loadingAddress = false);
      _showMessage(e.userMessage);
    }
  }

  // ── Llevarme a donde estoy ─────────────────────────────────────────────────

  /// Pide la posición del GPS y lleva el mapa allí.
  ///
  /// Cualquier problema —servicio apagado, permiso denegado, sin señal— se
  /// resuelve recentrando sobre el punto que ya estaba elegido, que es lo
  /// único que hacía este botón antes. Nunca deja al usuario sin respuesta.
  Future<void> _handleLocateTap() async {
    if (_locating) return;
    setState(() => _locating = true);

    try {
      final Position? position = await _tryCurrentPosition();
      if (!mounted) return;

      if (position == null) {
        await _recenterToCurrentCenter();
        return;
      }

      final LatLng target = LatLng(position.latitude, position.longitude);
      if (!ParcelLocationStore.areUsableCoordinates(
        target.latitude,
        target.longitude,
      )) {
        await _recenterToCurrentCenter();
        return;
      }

      setState(() {
        _center = target;
        _hasExplicitPick = true;
        _origin = ParcelLocationOrigin.gps;
      });

      await _moveCameraTo(target, zoom: _kZoomPicked);
      _scheduleReverseGeocode(target);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  /// Devuelve la posición, o null explicando por qué no se pudo.
  Future<Position?> _tryCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _showMessage('Activa los servicios de ubicación en tu dispositivo.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showMessage('Se necesita permiso de ubicación para localizarte.');
        return null;
      }
      if (permission == LocationPermission.deniedForever) {
        _showMessage(
          'Permiso de ubicación denegado permanentemente. '
          'Habilítalo en ajustes.',
        );
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      _showMessage('No se pudo obtener tu ubicación.');
      return null;
    }
  }

  Future<void> _recenterToCurrentCenter() async {
    final LatLng? target = _center;
    if (target == null) return;
    await _moveCameraTo(target, zoom: _kZoomPicked);
  }

  // ── Guardar ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_saving) return;

    final LatLng? target = _center;

    // Guardar el encuadre por defecto sería inventarle una parcela al
    // agricultor. Se prefiere no guardar nada a guardar una coordenada falsa.
    if (target == null || !_hasExplicitPick) {
      _showMessage(
        'Mueve el mapa o busca tu parcela para confirmar la ubicación.',
      );
      return;
    }

    // Al reabrir la pantalla con una ubicación ya guardada, `_currentLabel`
    // trae el nombre bueno, así que el respaldo de coordenadas solo entra
    // cuando de verdad no hay ningún nombre que guardar.
    final String shown = _currentLabel.trim();
    final String typed = _searchC.text.trim();
    final String picked = _isPlaceholderLabel(shown)
        ? (_isPlaceholderLabel(typed) ? '' : typed)
        : shown;
    final String label = picked.isEmpty ? _coordinateLabel(target) : picked;

    setState(() => _saving = true);

    try {
      final bool mirrored = await ParcelLocationStore.save(
        lat: target.latitude,
        lng: target.longitude,
        label: label,
        origin: _origin,
      );

      if (!mounted) return;

      // Lo local ya está escrito pase lo que pase. Si la nube no respondió se
      // avisa, pero no se deshace nada ni se bloquea la salida: la ubicación
      // funciona sin red y se espejará en el siguiente guardado.
      if (!mirrored) {
        _showMessage('Ubicación guardada en el equipo. Se sincronizará luego.');
      }

      Navigator.pop(context, label);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('No se pudo guardar la ubicación.');
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _LocationSoftBackground(),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  // ================= TOP BAR =================
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 8,
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withValues(alpha:0.55),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Ajustar ubicación',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E1A16),
                        ),
                      ),
                      const Spacer(),

                      // ✅ Guardar con paleta BioGButton (sin usar BioGButton)
                      _TopSavePill(color: widget.brandMid, onTap: _save),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ================= SEARCH =================
                  _SearchBar(
                    controller: _searchC,
                    focusNode: _searchFocus,
                    onLocate: _handleLocateTap,
                    onSearch: _searchAndGo,
                    locateIconScale: 2.0,
                  ),

                  const SizedBox(height: 12),

                  // ================= MAP CARD (GOOGLE) =================
                  Expanded(
                    child: _MapCardGoogle(
                      brandMid: widget.brandMid,
                      mapReady: _ready,
                      currentLabel: _currentLabel,
                      loadingLabel: _loadingAddress || _locating,
                      onMapCreated: _handleMapCreated,
                      initial: _center ?? _kDefault,
                      onCenterChanged: _handleCameraIdle,
                      // Antes el mapa nacía en 15.2 y `_handleMapCreated` lo
                      // reencuadraba a 15.5 en cuanto llegaban las
                      // preferencias. Ahora nace ya en el zoom final: quien
                      // tiene parcela guardada la ve de cerca desde el primer
                      // fotograma, sin acercamiento intermedio.
                      initialZoom: _hasExplicitPick ? _kZoomSaved : 15.2,
                      pillIconScale: 1.35,
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

/* ===================== TOP SAVE PILL ===================== */

class _TopSavePill extends StatefulWidget {
  final Color color; // se queda por compatibilidad
  final VoidCallback onTap;
  const _TopSavePill({required this.color, required this.onTap});

  @override
  State<_TopSavePill> createState() => _TopSavePillState();
}

class _TopSavePillState extends State<_TopSavePill> {
  bool _pressed = false;

  // ✅ PALETA OFICIAL (match BioGButton)
  static const Color brandTop = Color(0xFF40BB5F);
  static const Color brandMid = Color(0xFF3FAF6E);
  static const Color brandBaseA = Color.fromARGB(137, 43, 126, 101);

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.985 : 1.0;
    final overlayOpacity = _pressed ? 0.05 : 0.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: brandTop.withValues(alpha:0.18),
              blurRadius: 22,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: _setPressed,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [brandTop, brandMid, brandBaseA],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    // blanqueado sutil
                    Container(color: Colors.white.withValues(alpha:0.06)),

                    // overlay al presionar
                    AnimatedOpacity(
                      opacity: overlayOpacity,
                      duration: const Duration(milliseconds: 120),
                      child: Container(color: Colors.black),
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        'Guardar',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white, // ✅ TEXTO BLANCO
                          shadows: [
                            Shadow(
                              color: Color(0x4D000000),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                            Shadow(
                              color: Color(0x2E000000),
                              blurRadius: 22,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== ASSET ICON (SCALE FRIENDLY) ===================== */

class _AssetIcon extends StatelessWidget {
  final String path;
  final double box;
  final double size;
  final double scale;

  const _AssetIcon({
    required this.path,
    this.box = 20,
    this.size = 18,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: box,
      height: box,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: Image.asset(
            path,
            width: size,
            height: size,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

/* ===================== SEARCH BAR ===================== */

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  final VoidCallback onLocate;
  final VoidCallback onSearch;

  final double locateIconScale;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onLocate,
    required this.onSearch,
    this.locateIconScale = 1.35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.78),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha:0.70)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onLocate,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: _AssetIcon(
                path: 'assets/icons/metrics/ic_location.png',
                box: 18,
                size: 18,
                scale: locateIconScale,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => onSearch(),
              decoration: const InputDecoration(
                hintText: 'Buscar ubicación...',
                border: InputBorder.none,
                isCollapsed: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          GestureDetector(
            onTap: onSearch,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Icon(Icons.search, color: Colors.black.withValues(alpha:0.55)),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== MAP CARD (GOOGLE MAP) ===================== */

class _MapCardGoogle extends StatefulWidget {
  final Color brandMid;
  final bool mapReady;

  final String currentLabel;
  final bool loadingLabel;

  final LatLng initial;
  final double initialZoom;
  final ValueChanged<GoogleMapController> onMapCreated;
  final ValueChanged<LatLng> onCenterChanged;

  final double pillIconScale;

  const _MapCardGoogle({
    required this.brandMid,
    required this.mapReady,
    required this.currentLabel,
    required this.loadingLabel,
    required this.initial,
    required this.onMapCreated,
    required this.onCenterChanged,
    this.initialZoom = 15.2,
    this.pillIconScale = 1.35,
  });

  @override
  State<_MapCardGoogle> createState() => _MapCardGoogleState();
}

class _MapCardGoogleState extends State<_MapCardGoogle> {
  /// Último punto que reportó la cámara. Solo sirve para tener algo que
  /// entregar en `onCameraIdle`, que no trae la posición.
  late LatLng _center = widget.initial;

  @override
  void didUpdateWidget(covariant _MapCardGoogle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) {
      _center = widget.initial;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.12),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // El mapa NO se construye hasta que se sabe dónde apuntar.
            //
            // `GoogleMap` solo lee `initialCameraPosition` una vez, al nacer:
            // construirlo antes de leer las preferencias obligaba a corregir
            // la cámara después, y esa corrección era el salto visible desde
            // CDMX hasta la parcela. Leer preferencias tarda un fotograma
            // (`SharedPreferences` ya está instanciado desde `main`), así que
            // este hueco no llega a verse.
            SizedBox.expand(
              child: widget.mapReady
                  ? GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: widget.initial,
                        zoom: widget.initialZoom,
                      ),
                      myLocationEnabled: false,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: widget.onMapCreated,
                      onCameraMove: (pos) => _center = pos.target,
                      onCameraIdle: () => widget.onCenterChanged(_center),
                    )
                  : const ColoredBox(color: Color(0xFFEFF3F1)),
            ),
            Positioned(
              top: 12,
              left: 12,
              right: 64,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.82),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha:0.65)),
                ),
                child: Row(
                  children: [
                    _AssetIcon(
                      path: 'assets/icons/metrics/ic_location.png',
                      box: 18,
                      size: 18,
                      scale: widget.pillIconScale,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.currentLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                widget.loadingLabel
                                    ? 'Actualizando...'
                                    : 'Ubicación',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black.withValues(alpha:0.55),
                                ),
                              ),
                              if (widget.loadingLabel) ...[
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      widget.brandMid.withValues(alpha:0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Center(
              child: IgnorePointer(
                child: Icon(
                  Icons.location_pin,
                  size: 44,
                  color: Color(0xFFB2554E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== BACKGROUND ===================== */

class _LocationSoftBackground extends StatelessWidget {
  const _LocationSoftBackground();

  @override
  Widget build(BuildContext context) {
    // Aislado en su propia capa: es estático y sus tres manchas son
    // desenfoques de sigma 34. Sin esto se repintaban cada vez que algo del
    // resto de la pantalla cambiaba — y encima de esta pantalla hay un mapa
    // que se mueve.
    return RepaintBoundary(child: _buildBackground());
  }

  Widget _buildBackground() {
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
