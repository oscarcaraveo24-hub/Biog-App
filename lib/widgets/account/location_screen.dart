import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  // ✅ Pasa tu key con --dart-define=GOOGLE_MAPS_API_KEY=xxxx
  static const String _kMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // ✅ Pref keys (local)
  static const String _kPrefLocLabel = 'profile_location_label';
  static const String _kPrefLocLat = 'profile_location_lat';
  static const String _kPrefLocLng = 'profile_location_lng';

  // ✅ Default: CDMX (si no hay nada guardado)
  static const LatLng _kDefault = LatLng(19.4326, -99.1332);

  final Completer<GoogleMapController> _mapC = Completer<GoogleMapController>();
  final FocusNode _searchFocus = FocusNode();

  late final TextEditingController _searchC = TextEditingController(
    text: widget.initialValue,
  );

  LatLng _center = _kDefault;
  String _currentLabel = '';
  bool _loadingAddress = false;

  Timer? _debounce;
  bool _loadedPrefs = false;

  // ✅ NUEVO: cuando prefs cargan antes del controller, movemos cámara al crearse
  bool _pendingMoveToSaved = false;

  @override
  void initState() {
    super.initState();
    _currentLabel = widget.initialValue.trim().isEmpty
        ? 'Ubicación actual'
        : widget.initialValue.trim();
    _loadSavedLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchC.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_kPrefLocLat);
      final lng = prefs.getDouble(_kPrefLocLng);
      final label = prefs.getString(_kPrefLocLabel);

      if (!mounted) return;

      // ✅ set center desde prefs
      if (lat != null && lng != null) {
        _center = LatLng(lat, lng);
      } else {
        _center = _kDefault;
      }

      // ✅ label desde prefs
      if (label != null && label.trim().isNotEmpty) {
        _currentLabel = label.trim();
        _searchC.text = _currentLabel;
      }

      setState(() => _loadedPrefs = true);

      // ✅ Si el controller ya existe, movemos la cámara ahora.
      // ✅ Si no existe, marcamos movimiento pendiente para onMapCreated.
      if (_mapC.isCompleted) {
        final c = await _mapC.future;
        await c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _center, zoom: 15.5),
          ),
        );
      } else {
        _pendingMoveToSaved = true;
      }

      // ✅ Refresca dirección
      _scheduleReverseGeocode(_center);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadedPrefs = true);
    }
  }

  Future<void> _recenterToCurrentCenter() async {
    try {
      if (!_mapC.isCompleted) return;
      final c = await _mapC.future;
      await c.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _center, zoom: 16.0),
        ),
      );
    } catch (_) {}
  }

  void _scheduleReverseGeocode(LatLng target) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 520), () async {
      await _reverseGeocode(target);
    });
  }

  // ---------- helpers para "fix rural" + quitar plus code ----------

  bool _looksLikePlusCode(String s) {
    final t = s.trim();
    // Ej: "52JHG+Q8 Chihuahua, Chih., México"
    return RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}\b').hasMatch(t);
  }

  String _stripPlusCodePrefix(String s) {
    var t = s.trim();
    // Quita "XXXX+XX " o "XXXX+XX, "
    t = t.replaceFirst(RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}\s*'), '');
    t = t.replaceFirst(RegExp(r'^[A-Z0-9]{4,}\+[A-Z0-9]{2,}\s*,\s*'), '');
    return t.trim();
  }

  String _pickComponent(List comps, List<String> types) {
    for (final c in comps) {
      final t =
          (c['types'] as List?)?.map((e) => e.toString()).toList() ?? const [];
      final name = (c['long_name'] ?? '').toString().trim();
      if (name.isEmpty) continue;
      if (types.any((x) => t.contains(x))) return name;
    }
    return '';
  }

  String _buildRuralLabelFromComponents(List comps) {
    final route = _pickComponent(comps, const ['route']);
    final streetNo = _pickComponent(comps, const ['street_number']);

    if (route.isNotEmpty) {
      final street = streetNo.isNotEmpty ? '$route $streetNo' : route;
      final locality = _pickComponent(comps, const ['locality']);
      final admin2 = _pickComponent(comps, const [
        'administrative_area_level_2',
      ]);
      final admin1 = _pickComponent(comps, const [
        'administrative_area_level_1',
      ]);
      final country = _pickComponent(comps, const ['country']);

      final parts = <String>[
        street,
        if (locality.isNotEmpty) locality,
        if (admin2.isNotEmpty && admin2 != locality) admin2,
        if (admin1.isNotEmpty && admin1 != admin2) admin1,
        if (country.isNotEmpty) country,
      ];
      return parts.join(', ');
    }

    final locality = _pickComponent(comps, const ['locality']);
    final admin2 = _pickComponent(comps, const ['administrative_area_level_2']);
    final admin1 = _pickComponent(comps, const ['administrative_area_level_1']);
    final country = _pickComponent(comps, const ['country']);

    final parts = <String>[
      if (locality.isNotEmpty) locality,
      if (admin2.isNotEmpty && admin2 != locality) admin2,
      if (admin1.isNotEmpty && admin1 != admin2) admin1,
      if (country.isNotEmpty) country,
    ];

    if (parts.isEmpty) return 'Ubicación seleccionada';
    return parts.join(', ');
  }

  String _bestLabelFromGeocode(Map<String, dynamic> data) {
    final results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) return 'Ubicación seleccionada';

    for (final r in results) {
      final formatted = (r['formatted_address'] ?? '').toString().trim();
      final comps = (r['address_components'] as List?) ?? const [];

      if (formatted.isEmpty) continue;

      if (_looksLikePlusCode(formatted)) {
        final built = _buildRuralLabelFromComponents(comps);
        if (built.isNotEmpty && built != 'Ubicación seleccionada') return built;
        final stripped = _stripPlusCodePrefix(formatted);
        if (stripped.isNotEmpty) return stripped;
        continue;
      }

      return formatted;
    }

    final first = results.first as Map<String, dynamic>;
    final comps = (first['address_components'] as List?) ?? const [];
    return _buildRuralLabelFromComponents(comps);
  }

  // ---------- reverse geocode ----------

  Future<void> _reverseGeocode(LatLng target) async {
    if (_kMapsKey.isEmpty) {
      setState(() => _currentLabel = 'Ubicación seleccionada');
      return;
    }

    setState(() => _loadingAddress = true);

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?latlng=${target.latitude},${target.longitude}'
        '&key=$_kMapsKey'
        '&language=es',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();

      String label = _currentLabel.isNotEmpty
          ? _currentLabel
          : 'Ubicación seleccionada';

      if (status == 'OK') {
        label = _bestLabelFromGeocode(data);
        if (label.isEmpty) label = 'Ubicación seleccionada';
      }

      if (!mounted) return;

      setState(() {
        _currentLabel = label;
        _loadingAddress = false;

        if (!_searchFocus.hasFocus) {
          _searchC.text = label;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAddress = false);
    }
  }

  // ---------- search (address -> coords) ----------

  Future<void> _searchAndGo() async {
    final q = _searchC.text.trim();
    if (q.isEmpty) return;

    if (_kMapsKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Falta GOOGLE_MAPS_API_KEY en --dart-define'),
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json'
        '?address=${Uri.encodeComponent(q)}'
        '&key=$_kMapsKey'
        '&language=es',
      );

      final res = await http.get(uri);
      if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}');

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final status = (data['status'] ?? '').toString();

      if (status != 'OK') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró esa ubicación')),
        );
        return;
      }

      final results = (data['results'] as List?) ?? [];
      if (results.isEmpty) return;

      final loc = results.first['geometry']?['location'];
      if (loc is! Map) return;

      final lat = (loc['lat'] as num).toDouble();
      final lng = (loc['lng'] as num).toDouble();
      final target = LatLng(lat, lng);

      _center = target;

      if (_mapC.isCompleted) {
        final c = await _mapC.future;
        await c.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: target, zoom: 16.0),
          ),
        );
      } else {
        _pendingMoveToSaved = true;
      }

      _scheduleReverseGeocode(target);
      _searchFocus.unfocus();
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo buscar. Revisa tu API y conexión.'),
        ),
      );
    }
  }

  // ---------- save local ----------

  Future<void> _save() async {
    final label = (_currentLabel.trim().isEmpty)
        ? _searchC.text.trim()
        : _currentLabel.trim();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefLocLabel, label);
    await prefs.setDouble(_kPrefLocLat, _center.latitude);
    await prefs.setDouble(_kPrefLocLng, _center.longitude);

    if (!mounted) return;
    Navigator.pop(context, label);
  }

  // ✅ NUEVO: handler único para controller + mover a saved center cuando ya exista
  Future<void> _handleMapCreated(GoogleMapController c) async {
    if (!_mapC.isCompleted) _mapC.complete(c);

    // Si prefs ya se cargaron pero no existía controller, movemos aquí.
    if (_pendingMoveToSaved) {
      _pendingMoveToSaved = false;
      try {
        await c.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _center, zoom: 15.5),
          ),
        );
      } catch (_) {}
    } else {
      // Asegura que al abrir por primera vez también quede en _center
      try {
        await c.moveCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: _center, zoom: 15.2),
          ),
        );
      } catch (_) {}
    }
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
                    onLocate: _recenterToCurrentCenter,
                    onSearch: _searchAndGo,
                    locateIconScale: 2.0,
                  ),

                  const SizedBox(height: 12),

                  // ================= MAP CARD (GOOGLE) =================
                  Expanded(
                    child: _MapCardGoogle(
                      brandMid: widget.brandMid,
                      mapReady: _loadedPrefs,
                      currentLabel: _currentLabel,
                      loadingLabel: _loadingAddress,
                      onMapCreated: _handleMapCreated,
                      initial: _center,
                      onCenterChanged: (latLng) {
                        _center = latLng;
                        _scheduleReverseGeocode(latLng);
                      },
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
    this.pillIconScale = 1.35,
  });

  @override
  State<_MapCardGoogle> createState() => _MapCardGoogleState();
}

class _MapCardGoogleState extends State<_MapCardGoogle> {
  LatLng _center = const LatLng(19.4326, -99.1332);

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
  }

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
            SizedBox.expand(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initial,
                  zoom: 15.2,
                ),
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: false,
                mapToolbarEnabled: false,
                onMapCreated: widget.onMapCreated,
                onCameraMove: (pos) => _center = pos.target,
                onCameraIdle: () => widget.onCenterChanged(_center),
              ),
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
