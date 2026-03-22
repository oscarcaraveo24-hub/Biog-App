// telephone_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TelephoneScreen extends StatefulWidget {
  /// Puede venir como "+52..." o "5512345678" o "55 1234 5678"
  final String initialValue;
  final Color brandMid;

  const TelephoneScreen({
    super.key,
    required this.initialValue,
    required this.brandMid,
  });

  @override
  State<TelephoneScreen> createState() => _TelephoneScreenState();
}

/* ===================== COUNTRY MODEL ===================== */

enum _PhoneCountry { mx, usa, ca }

class _CountryMeta {
  final _PhoneCountry id;
  final String name;
  final String dial;
  final String flagAsset;

  const _CountryMeta({
    required this.id,
    required this.name,
    required this.dial,
    required this.flagAsset,
  });
}

const _kCountries = <_CountryMeta>[
  _CountryMeta(
    id: _PhoneCountry.mx,
    name: 'México',
    dial: '+52',
    flagAsset: 'assets/icons/flags/ic_flag_mx.png',
  ),
  _CountryMeta(
    id: _PhoneCountry.usa,
    name: 'Estados Unidos',
    dial: '+1',
    flagAsset: 'assets/icons/flags/ic_flag_usa.png',
  ),
  _CountryMeta(
    id: _PhoneCountry.ca,
    name: 'Canadá',
    dial: '+1',
    flagAsset: 'assets/icons/flags/ic_flag_ca.png',
  ),
];

class _TelephoneScreenState extends State<TelephoneScreen>
    with TickerProviderStateMixin {
  // ===========================
  // ✅ Pref keys (compat + OTP)
  // ===========================
  static const String _kPrefPhoneFormatted = 'profile_phone';
  static const String _kPrefPhoneE164 = 'profile_phone_e164';
  static const String _kPrefPhoneDigits = 'profile_phone_digits';
  static const String _kPrefPhoneCountry = 'profile_phone_country'; // mx/usa/ca

  // ===========================
  // ✅ UI state
  // ===========================
  bool _editing = false;
  bool _saving = false;
  bool _loadedPrefs = false;

  _PhoneCountry _country = _PhoneCountry.mx;
  String _digits = ''; // 10 dígitos (MX/US/CA)
  String _error = '';

  // Anims (solo para subir/bajar keypad)
  late final AnimationController _padC;
  late final Animation<double> _padT;

  _CountryMeta get _meta => _kCountries.firstWhere((e) => e.id == _country);

  // Key para anclar popup de lada
  final GlobalKey _countryPillKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _padC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _padT = CurvedAnimation(parent: _padC, curve: Curves.easeOutCubic);

    // Arranca con initialValue (pero luego intenta cargar saved)
    final parsed = _parseInitial(widget.initialValue);
    _country = parsed.$1;
    _digits = parsed.$2;

    _loadSavedPhone();
  }

  @override
  void dispose() {
    _padC.dispose();
    super.dispose();
  }

  // -------------------------
  // Helpers (Parse)
  // -------------------------

  (_PhoneCountry, String) _parseInitial(String raw) {
    final t = raw.trim();

    if (t.startsWith('+52')) {
      return (_PhoneCountry.mx, _stripDialAndTake10(t, '+52'));
    }
    if (t.startsWith('+1')) {
      return (_PhoneCountry.usa, _stripDialAndTake10(t, '+1'));
    }

    final only = t.replaceAll(RegExp(r'[^0-9]'), '');
    if (only.startsWith('52') && only.length >= 12) {
      return (_PhoneCountry.mx, only.substring(2, 12));
    }
    if (only.startsWith('1') && only.length >= 11) {
      return (_PhoneCountry.usa, only.substring(1, 11));
    }

    final d = _digitsOnly10(only);
    return (_country, d);
  }

  static String _stripDialAndTake10(String raw, String dial) {
    final only = raw.replaceAll(RegExp(r'[^0-9]'), '');
    final dialDigits = dial.replaceAll(RegExp(r'[^0-9]'), '');

    if (only.startsWith(dialDigits)) {
      final rest = only.substring(dialDigits.length);
      return _digitsOnly10(rest);
    }
    return _digitsOnly10(only);
  }

  static String _digitsOnly10(String rawDigits) {
    final only = rawDigits.replaceAll(RegExp(r'[^0-9]'), '');
    if (only.isEmpty) return '';
    if (only.length > 10) return only.substring(only.length - 10);
    return only;
  }

  // -------------------------
  // Format
  // -------------------------

  static String _formatMx_3_3_2_2(String digits) {
    final d = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return '';
    final x = d.length > 10 ? d.substring(0, 10) : d;

    final a = x.substring(0, x.length.clamp(0, 3));
    final b = x.length > 3 ? x.substring(3, x.length.clamp(3, 6)) : '';
    final c = x.length > 6 ? x.substring(6, x.length.clamp(6, 8)) : '';
    final e = x.length > 8 ? x.substring(8, x.length.clamp(8, 10)) : '';

    return [a, b, c, e].where((p) => p.isNotEmpty).join(' ');
  }

  static String _formatNanp_3_3_4(String digits) {
    final d = digits.replaceAll(RegExp(r'[^0-9]'), '');
    if (d.isEmpty) return '';
    final x = d.length > 10 ? d.substring(0, 10) : d;

    final a = x.substring(0, x.length.clamp(0, 3));
    final b = x.length > 3 ? x.substring(3, x.length.clamp(3, 6)) : '';
    final c = x.length > 6 ? x.substring(6, x.length.clamp(6, 10)) : '';

    return [a, b, c].where((p) => p.isNotEmpty).join(' ');
  }

  String get _formatted {
    if (_digits.isEmpty) return '';
    if (_country == _PhoneCountry.mx) return _formatMx_3_3_2_2(_digits);
    return _formatNanp_3_3_4(_digits);
  }

  bool get _isValid => _digits.length == 10;

  // -------------------------
  // Live validation (UX)
  // -------------------------
  void _updateLiveError() {
    // No molestes si está vacío
    if (_digits.isEmpty) {
      _error = '';
      return;
    }

    if (_digits.length < 10) {
      final faltan = 10 - _digits.length;
      _error = 'Número inválido (faltan $faltan dígitos).';
      return;
    }

    // 10 dígitos => válido (por ahora)
    _error = '';
  }

  // -------------------------
  // Load / Save
  // -------------------------
  Future<void> _loadSavedPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final countryStr = (prefs.getString(_kPrefPhoneCountry) ?? '').trim();
      final savedCountry = _countryFromString(countryStr) ?? _country;

      final e164 = (prefs.getString(_kPrefPhoneE164) ?? '').trim();
      final digitsStored = (prefs.getString(_kPrefPhoneDigits) ?? '').trim();
      final formattedStored = (prefs.getString(_kPrefPhoneFormatted) ?? '')
          .trim();

      String pick = '';
      if (e164.isNotEmpty) pick = e164;
      if (pick.isEmpty && digitsStored.isNotEmpty) pick = digitsStored;
      if (pick.isEmpty && formattedStored.isNotEmpty) pick = formattedStored;

      final parsed = _parseInitial(pick);

      if (!mounted) return;
      setState(() {
        if (countryStr.isNotEmpty) {
          _country = savedCountry;
        } else {
          _country = parsed.$1;
        }
        if (parsed.$2.isNotEmpty) _digits = _digitsOnly10(parsed.$2);
        _loadedPrefs = true;
        _updateLiveError();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadedPrefs = true);
    }
  }

  _PhoneCountry? _countryFromString(String s) {
    switch (s.toLowerCase()) {
      case 'mx':
        return _PhoneCountry.mx;
      case 'usa':
      case 'us':
        return _PhoneCountry.usa;
      case 'ca':
        return _PhoneCountry.ca;
    }
    return null;
  }

  String _countryToString(_PhoneCountry c) {
    switch (c) {
      case _PhoneCountry.mx:
        return 'mx';
      case _PhoneCountry.usa:
        return 'usa';
      case _PhoneCountry.ca:
        return 'ca';
    }
  }

  Future<void> _save() async {
    if (_saving) return;

    // Forzamos validación
    if (!_isValid) {
      setState(() {
        _updateLiveError();
      });
      _enterEdit();
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _saving = true;
      _error = '';
    });

    try {
      final dial = _meta.dial;
      final e164 = '$dial$_digits';
      final formatted = '$dial $_formatted';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefPhoneCountry, _countryToString(_country));
      await prefs.setString(_kPrefPhoneDigits, _digits);
      await prefs.setString(_kPrefPhoneE164, e164);
      await prefs.setString(_kPrefPhoneFormatted, formatted);

      if (!mounted) return;
      Navigator.pop(context, formatted);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo guardar. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // -------------------------
  // Edit flow
  // -------------------------
  void _enterEdit() {
    if (_editing) return;
    setState(() => _editing = true);
    _padC.forward();
    HapticFeedback.selectionClick();
  }

  void _exitEdit() {
    if (!_editing) return;
    setState(() => _editing = false);
    _padC.reverse();
    HapticFeedback.selectionClick();
  }

  void _clear() {
    setState(() {
      _digits = '';
      _updateLiveError();
    });
    HapticFeedback.lightImpact();
    _enterEdit();
  }

  void _appendDigit(String d) {
    if (d.isEmpty) return;
    if (_digits.length >= 10) return;

    setState(() {
      _digits = '$_digits$d';
      _updateLiveError();
    });
    // opcional: haptic suave
    HapticFeedback.selectionClick();
  }

  void _backspace() {
    if (_digits.isEmpty) return;
    setState(() {
      _digits = _digits.substring(0, _digits.length - 1);
      _updateLiveError();
    });
    HapticFeedback.selectionClick();
  }

  // -------------------------
  // Country picker (anchored popup)
  // -------------------------
  Future<void> _openCountryPickerAnchored() async {
    final ctx = _countryPillKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      box.size.width,
      box.size.height,
    );

    // Popup justo debajo del pill
    final pos = RelativeRect.fromRect(
      Rect.fromLTWH(rect.left, rect.bottom + 8, rect.width, 1),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<_PhoneCountry>(
      context: context,
      position: pos,
      color: Colors.transparent,
      elevation: 0,
      items: [
        PopupMenuItem<_PhoneCountry>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: _LadaPopupCard(
            selected: _country,
            onPick: (c) => Navigator.pop(context, c),
          ),
        ),
      ],
    );

    if (selected == null) return;
    setState(() {
      _country = selected;
      _updateLiveError();
    });
    HapticFeedback.selectionClick();
  }

  // ===========================
  // UI
  // ===========================
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // Card keypad height (sin duplicar safeBottom)
    const double kKeypadBase = 320;
    final maxAllowed = size.height * 0.48;
    final padHeight = kKeypadBase.clamp(280.0, maxAllowed);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _PhoneSoftBackground(),

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
                        'Editar contacto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0E1A16),
                        ),
                      ),
                      const Spacer(),
                      _TopSavePill(
                        onTap: _save,
                        loading: _saving,
                        enabled: _isValid && !_saving,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // ================= PHONE CARD =================
                  _GlassShell(
                    radius: 22,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: _enterEdit,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                        child: Row(
                          children: [
                            _CountryPill(
                              key: _countryPillKey,
                              meta: _meta,
                              onTap: _openCountryPickerAnchored,
                            ),
                            const SizedBox(width: 10),

                            // ✅ sin animación al escribir
                            Expanded(
                              child: Text(
                                (_formatted.isEmpty)
                                    ? (_country == _PhoneCountry.mx
                                          ? '625 118 20 81'
                                          : '415 555 0123')
                                    : _formatted,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                  color: (_formatted.isEmpty)
                                      ? Colors.black.withValues(alpha:0.28)
                                      : const Color(0xFF0E1A16),
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            AnimatedOpacity(
                              opacity: (_editing || _digits.isNotEmpty) ? 1 : 0,
                              duration: const Duration(milliseconds: 120),
                              child: IgnorePointer(
                                ignoring: !(_editing || _digits.isNotEmpty),
                                child: GestureDetector(
                                  onTap: _clear,
                                  behavior: HitTestBehavior.opaque,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha:0.06),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: Colors.black.withValues(alpha:0.50),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ================= HINT / ERROR =================
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeOut,
                    child: (_error.isNotEmpty)
                        ? Padding(
                            key: const ValueKey('err'),
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _error,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12.8,
                                fontWeight: FontWeight.w900,
                                color: const Color(
                                  0xFFB2554E,
                                ).withValues(alpha:0.92),
                              ),
                            ),
                          )
                        : Padding(
                            key: const ValueKey('hint'),
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _editing
                                  ? 'Ingresa tu número y toca Guardar.'
                                  : (_loadedPrefs
                                        ? 'Toca para editar tu número.'
                                        : 'Cargando…'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black.withValues(alpha:0.45),
                              ),
                            ),
                          ),
                  ),

                  const Spacer(),

                  AnimatedOpacity(
                    opacity: _editing ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 160),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SoftPillsRow(
                        left: 'Cancelar',
                        right: 'Guardar',
                        brandMid: widget.brandMid,
                      ),
                    ),
                  ),

                  SizedBox(height: _editing ? 10 : 0),
                ],
              ),
            ),
          ),

          // ✅ scrim para cerrar al tocar fuera
          if (_editing)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _exitEdit,
                child: AnimatedBuilder(
                  animation: _padT,
                  builder: (context, _) {
                    final t = _padT.value;
                    return Container(color: Colors.black.withValues(alpha:0.08 * t));
                  },
                ),
              ),
            ),

          // ================= KEYPAD CARD (floats up) =================
          Align(
            alignment: Alignment.bottomCenter,
            child: IgnorePointer(
              ignoring: !_editing,
              child: AnimatedBuilder(
                animation: _padT,
                builder: (context, _) {
                  final t = _padT.value;

                  // ✅ más “card”: deja aire abajo y laterales
                  final bottomMargin = 12.0 + safeBottom;
                  final lift = 18.0;

                  return Transform.translate(
                    offset: Offset(
                      0,
                      (1 - t) * (padHeight + bottomMargin) + (t * -lift),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _PhoneKeypadCard(
                        height: padHeight,
                        bottomPadding: bottomMargin,
                        brandMid: widget.brandMid,
                        onDigit: _appendDigit,
                        onBackspace: _backspace,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== TOP SAVE PILL (BioG colors) ===================== */

class _TopSavePill extends StatefulWidget {
  final VoidCallback onTap;
  final bool loading;
  final bool enabled;

  const _TopSavePill({
    required this.onTap,
    this.loading = false,
    this.enabled = true,
  });

  @override
  State<_TopSavePill> createState() => _TopSavePillState();
}

class _TopSavePillState extends State<_TopSavePill> {
  bool _pressed = false;

  static const Color brandTop = Color(0xFF40BB5F);
  static const Color brandMid = Color(0xFF3FAF6E);
  static const Color brandBaseA = Color.fromARGB(137, 43, 126, 101);

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && !widget.loading;
    final scale = (enabled && _pressed) ? 0.985 : 1.0;
    final overlayOpacity = (enabled && _pressed) ? 0.05 : 0.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: brandTop.withValues(alpha:0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha:0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: enabled ? widget.onTap : null,
            onHighlightChanged: _setPressed,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: enabled
                      ? const [brandTop, brandMid, brandBaseA]
                      : [
                          brandTop.withValues(alpha:0.14),
                          brandMid.withValues(alpha:0.14),
                          brandBaseA.withValues(alpha:0.14),
                        ],
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  children: [
                    Container(color: Colors.white.withValues(alpha:0.06)),
                    AnimatedOpacity(
                      opacity: overlayOpacity,
                      duration: const Duration(milliseconds: 120),
                      child: Container(color: Colors.black),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: widget.loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Guardar',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
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

/* ===================== COUNTRY PILL ===================== */

class _CountryPill extends StatelessWidget {
  final _CountryMeta meta;
  final VoidCallback onTap;

  const _CountryPill({super.key, required this.meta, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha:0.74),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.black.withValues(alpha:0.06)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                meta.flagAsset,
                width: 26,
                height: 18,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              meta.dial,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: Colors.black.withValues(alpha:0.72),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.expand_more_rounded,
              size: 18,
              color: Colors.black.withValues(alpha:0.45),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== LADA POPUP (anchored) ===================== */

class _LadaPopupCard extends StatelessWidget {
  final _PhoneCountry selected;
  final ValueChanged<_PhoneCountry> onPick;

  const _LadaPopupCard({required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: _GlassCard(
        radius: 18,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 240),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Selecciona tu lada',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A16),
                ),
              ),
              const SizedBox(height: 10),
              const _DividerLine(),
              ..._kCountries.map((m) {
                final isSel = m.id == selected;
                return InkWell(
                  onTap: () => onPick(m.id),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            m.flagAsset,
                            width: 34,
                            height: 24,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            m.name,
                            style: const TextStyle(
                              fontSize: 13.8,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0E1A16),
                            ),
                          ),
                        ),
                        Text(
                          m.dial,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: Colors.black.withValues(alpha:0.55),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          isSel
                              ? Icons.check_circle_rounded
                              : Icons.circle_outlined,
                          size: 18,
                          color: isSel
                              ? const Color(0xFF3FAF6E)
                              : Colors.black.withValues(alpha:0.22),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

/* ===================== KEYPAD CARD (all corners rounded) ===================== */

class _PhoneKeypadCard extends StatelessWidget {
  final double height;
  final double bottomPadding;
  final Color brandMid;

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  const _PhoneKeypadCard({
    required this.height,
    required this.bottomPadding,
    required this.brandMid,
    required this.onDigit,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height + bottomPadding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.18),
            blurRadius: 44,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.76),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha:0.62)),
            ),
            child: Padding(
              // ✅ más espacio interno (aire premium)
              padding: EdgeInsets.fromLTRB(18, 14, 18, 14 + bottomPadding),
              child: Column(
                children: [
                  // mini handle sutil (opcional)
                  Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.10),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Column(
                      children: [
                        _KeyRow(
                          gap: 14,
                          keys: const [
                            _KeySpec('1'),
                            _KeySpec('2'),
                            _KeySpec('3'),
                          ],
                          onDigit: onDigit,
                        ),
                        const SizedBox(height: 12),
                        _KeyRow(
                          gap: 14,
                          keys: const [
                            _KeySpec('4'),
                            _KeySpec('5'),
                            _KeySpec('6'),
                          ],
                          onDigit: onDigit,
                        ),
                        const SizedBox(height: 12),
                        _KeyRow(
                          gap: 14,
                          keys: const [
                            _KeySpec('7'),
                            _KeySpec('8'),
                            _KeySpec('9'),
                          ],
                          onDigit: onDigit,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _KeyButton(
                                label: '+*',
                                onTap: () {},
                                muted: true,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _KeyButton(
                                label: '0',
                                onTap: () => onDigit('0'),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _BackspaceButton(onTap: onBackspace),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeySpec {
  final String digit;
  const _KeySpec(this.digit);
}

class _KeyRow extends StatelessWidget {
  final List<_KeySpec> keys;
  final ValueChanged<String> onDigit;
  final double gap;

  const _KeyRow({required this.keys, required this.onDigit, this.gap = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KeyButton(
            label: keys[0].digit,
            onTap: () => onDigit(keys[0].digit),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _KeyButton(
            label: keys[1].digit,
            onTap: () => onDigit(keys[1].digit),
          ),
        ),
        SizedBox(width: gap),
        Expanded(
          child: _KeyButton(
            label: keys[2].digit,
            onTap: () => onDigit(keys[2].digit),
          ),
        ),
      ],
    );
  }
}

/* ===================== KEY BUTTON (NO press animation) ===================== */

class _KeyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool muted;

  const _KeyButton({
    required this.label,
    required this.onTap,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = muted
        ? Colors.black.withValues(alpha:0.04)
        : Colors.white.withValues(alpha:0.90);

    final border = muted
        ? Colors.black.withValues(alpha:0.05)
        : Colors.black.withValues(alpha:0.06);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.black.withValues(alpha:0.04),
        highlightColor: Colors.black.withValues(alpha:0.02),
        child: Ink(
          height: 58,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.06),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: muted
                    ? Colors.black.withValues(alpha:0.40)
                    : const Color(0xFF0E1A16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _BackspaceButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.black.withValues(alpha:0.04),
        highlightColor: Colors.black.withValues(alpha:0.02),
        child: Ink(
          height: 58, // ✅ igual que las teclas
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.90),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black.withValues(alpha:0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.06),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.backspace_outlined,
              size: 22,
              color: Colors.black.withValues(alpha:0.55),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== MINI VISUAL PILLS (mock) ===================== */

class _SoftPillsRow extends StatelessWidget {
  final String left;
  final String right;
  final Color brandMid;

  const _SoftPillsRow({
    required this.left,
    required this.right,
    required this.brandMid,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.70),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.black.withValues(alpha:0.06)),
            ),
            child: Center(
              child: Text(
                left,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Colors.black.withValues(alpha:0.60),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: brandMid.withValues(alpha:0.18),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha:0.70)),
            ),
            child: Center(
              child: Text(
                right,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: brandMid.withValues(alpha:0.95),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/* ===================== GLASS SHELL (shadow outside) ===================== */

class _GlassShell extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassShell({required this.child, this.radius = 20});

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
            child: child,
          ),
        ),
      ),
    );
  }
}

/* ===================== GLASS CARD (for popup) ===================== */

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCard({required this.child, this.radius = 20});

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
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.72),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha:0.55)),
            ),
            child: child,
          ),
        ),
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

/* ===================== BACKGROUND ===================== */

class _PhoneSoftBackground extends StatelessWidget {
  const _PhoneSoftBackground();

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
