import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/core/auth/auth_repository.dart';
import 'package:bio_g/core/profile/profile_repository.dart';
import 'package:bio_g/widgets/onboarding/floating_particles.dart';
import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/onboarding/onboarding_background.dart';
import 'package:bio_g/widgets/onboarding/onboarding_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';

enum AuthMode { signUp, signIn }

class AuthScreen extends StatefulWidget {
  final AuthMode initialMode;
  final VoidCallback? onAuthenticated;

  const AuthScreen({
    super.key,
    this.initialMode = AuthMode.signUp,
    this.onAuthenticated,
  });

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late final AuthRepository _authRepository;
  late final ProfileRepository _profileRepository;
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _confirmPasswordController;
  late final AnimationController _entryController;
  late final Animation<double> _entryFade;
  late final Animation<Offset> _entrySlide;

  late AuthMode _mode;
  bool _loading = false;
  String? _errorText;

  bool get _isSignUp => _mode == AuthMode.signUp;

  String get _title => _isSignUp ? 'Crea tu cuenta' : 'Bienvenido de vuelta';

  String get _subtitle => _isSignUp
      ? 'Empieza a configurar tu cultivo y conecta tu primer equipo BioG.'
      : 'Inicia sesión para continuar con tu dashboard y tu onboarding.';

  String get _primaryLabel => _isSignUp ? 'Crear cuenta' : 'Entrar';

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository(Supabase.instance.client);
    _profileRepository = ProfileRepository(Supabase.instance.client);
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _mode = widget.initialMode;

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _entryFade = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutQuart,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutQuart,
    ));

    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _switchMode() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = _isSignUp ? AuthMode.signIn : AuthMode.signUp;
      _errorText = null;
      _passwordController.clear();
      _confirmPasswordController.clear();
    });
  }

  String? _validateInputs() {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text;
    final String name = _nameController.text.trim();
    final String confirm = _confirmPasswordController.text;

    if (_isSignUp && name.isEmpty) {
      return 'Escribe tu nombre completo.';
    }
    if (email.isEmpty) {
      return 'Escribe tu correo electrónico.';
    }
    if (password.isEmpty) {
      return 'Escribe tu contraseña.';
    }
    if (_isSignUp && confirm != password) {
      return 'La confirmación de contraseña no coincide.';
    }
    return null;
  }

  Future<void> _seedProfileIfPossible() async {
    try {
      await _profileRepository.ensureMyProfileExists(
        fullName: _nameController.text.trim(),
      );
    } catch (_) {
      // En pruebas no queremos bloquear la entrada si el upsert falla.
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    bool authFlowCompleted = false;

    final String? validationError = _validateInputs();
    if (validationError != null) {
      setState(() => _errorText = validationError);
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    try {
      if (_isSignUp) {
        await _authRepository.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
        );

        if (!mounted) return;

        final bool hasSession =
            Supabase.instance.client.auth.currentSession != null;

        if (hasSession) {
          await _seedProfileIfPossible();
          authFlowCompleted = true;
          _handleAuthCompleted();
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Cuenta creada. Si tienes confirmación por correo activa en Supabase, revisa tu email para poder entrar.',
            ),
          ),
        );

        setState(() {
          _mode = AuthMode.signIn;
          _passwordController.clear();
          _confirmPasswordController.clear();
        });
      } else {
        await _authRepository.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        await _seedProfileIfPossible();

        if (!mounted) return;
        authFlowCompleted = true;
        _handleAuthCompleted();
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() => _errorText = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Ocurrió un error inesperado. Intenta de nuevo.';
      });
    } finally {
      if (authFlowCompleted) return;
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _handleAuthCompleted() {
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!();
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double logoHeight = constraints.maxWidth < 380 ? 140 : 190;

            return Stack(
              children: <Widget>[
                const _AuthLandscape(),
                const Positioned.fill(child: FloatingParticles()),
                SafeArea(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 28),
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: _loading
                                    ? null
                                    : () => Navigator.of(context).maybePop(),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Color(0xFF5F6B73),
                                ),
                                label: const Text(
                                  'Volver',
                                  style: TextStyle(
                                    color: Color(0xFF5F6B73),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Image.asset(
                                OnboardingUiAssets.logo,
                                height: logoHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                            FadeTransition(
                              opacity: _entryFade,
                              child: SlideTransition(
                                position: _entrySlide,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: <Widget>[
                                    Text(
                                      _title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF425058),
                                        letterSpacing: -0.55,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      child: Text(
                                        _subtitle,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          height: 1.45,
                                          color: Color(0xFF6A757C),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    AutofillGroup(
                                      child: OnboardingGlassCard(
                                        padding: const EdgeInsets.fromLTRB(
                                          18,
                                          16,
                                          18,
                                          14,
                                        ),
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        backgroundColor: const Color(
                                          0xFFFDFEFF,
                                        ).withValues(alpha:0.64),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: <Widget>[
                                            Row(
                                              children: <Widget>[
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFEAF5F1),
                                                    borderRadius: BorderRadius.circular(
                                                      14,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _isSignUp
                                                        ? 'Nuevo acceso'
                                                        : 'Acceso seguro',
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w800,
                                                      color: Color(0xFF0E6F5E),
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 14),
                                            ..._buildFields(),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (_errorText != null) ...<Widget>[
                                      const SizedBox(height: 14),
                                      _AuthErrorBanner(message: _errorText!),
                                    ],
                                    const SizedBox(height: 12),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                      child: OnboardingPrimaryButton(
                                        label: _primaryLabel,
                                        onPressed: _submit,
                                        loading: _loading,
                                        height: 64,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Center(
                                      child: Wrap(
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 4,
                                        children: <Widget>[
                                          Text(
                                            _isSignUp
                                                ? '¿Ya tienes cuenta?'
                                                : '¿No tienes cuenta?',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Color(0xFF70787D),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: _loading ? null : _switchMode,
                                            style: TextButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                              ),
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              _isSignUp
                                                  ? 'Iniciar sesión'
                                                  : 'Crear cuenta',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF0E6F5E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
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
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildFields() {
    final List<Widget> children = <Widget>[];

    if (_isSignUp) {
      children.add(
        _AuthInputRow(
          icon: Icons.person_outline_rounded,
          hintText: 'Nombre completo',
          controller: _nameController,
          textInputAction: TextInputAction.next,
          keyboardType: TextInputType.name,
          autofillHints: const <String>[AutofillHints.name],
        ),
      );
      children.add(const Divider(height: 1, color: Color(0x1F73808A)));
    }

    children.add(
      _AuthInputRow(
        icon: Icons.mail_outline_rounded,
        hintText: 'Correo electrónico',
        controller: _emailController,
        textInputAction: TextInputAction.next,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const <String>[AutofillHints.email],
      ),
    );
    children.add(const Divider(height: 1, color: Color(0x1F73808A)));

    children.add(
      _AuthInputRow(
        icon: Icons.lock_outline_rounded,
        hintText: 'Contraseña',
        controller: _passwordController,
        obscureText: true,
        textInputAction: _isSignUp
            ? TextInputAction.next
            : TextInputAction.done,
        autofillHints: _isSignUp
            ? const <String>[AutofillHints.newPassword]
            : const <String>[AutofillHints.password],
        onSubmitted: (_) {
          if (!_isSignUp) {
            _submit();
          }
        },
      ),
    );

    if (_isSignUp) {
      children.add(const Divider(height: 1, color: Color(0x1F73808A)));
      children.add(
        _AuthInputRow(
          icon: Icons.lock_outline_rounded,
          hintText: 'Confirmar contraseña',
          controller: _confirmPasswordController,
          obscureText: true,
          textInputAction: TextInputAction.done,
          autofillHints: const <String>[AutofillHints.newPassword],
          onSubmitted: (_) => _submit(),
        ),
      );
    }

    return children;
  }
}

class _AuthInputRow extends StatefulWidget {
  final IconData icon;
  final String hintText;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;

  const _AuthInputRow({
    required this.icon,
    required this.hintText,
    required this.controller,
    required this.textInputAction,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.onSubmitted,
  });

  @override
  State<_AuthInputRow> createState() => _AuthInputRowState();
}

class _AuthInputRowState extends State<_AuthInputRow> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant _AuthInputRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSecureField = widget.obscureText;

    return Row(
      children: <Widget>[
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF5F3),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(widget.icon, size: 22, color: const Color(0xFF6B777E)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: TextField(
            controller: widget.controller,
            obscureText: isSecureField ? _obscured : false,
            textInputAction: widget.textInputAction,
            keyboardType: widget.keyboardType,
            autofillHints: widget.autofillHints,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(
              fontSize: 17,
              color: Color(0xFF475158),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: const TextStyle(
                fontSize: 17,
                color: Color(0xFF8B949A),
                fontWeight: FontWeight.w400,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        if (isSecureField)
          IconButton(
            onPressed: () => setState(() => _obscured = !_obscured),
            splashRadius: 20,
            icon: Icon(
              _obscured
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              size: 20,
              color: const Color(0xFF7F8A91),
            ),
          ),
      ],
    );
  }
}

class _AuthErrorBanner extends StatelessWidget {
  final String message;

  const _AuthErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFCEAE8).withValues(alpha:0.94),
        border: Border.all(color: const Color(0xFFF3C8C0)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFC35A50),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                color: Color(0xFF9E473F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthLandscape extends StatelessWidget {
  const _AuthLandscape();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: -18,
      child: IgnorePointer(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.38,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Image.asset(
                OnboardingUiAssets.landscape,
                fit: BoxFit.cover,
                alignment: Alignment.bottomCenter,
                opacity: const AlwaysStoppedAnimation<double>(0.78),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      const Color(0xFFF7FBFD),
                      Colors.white.withValues(alpha:0.36),
                      Colors.white.withValues(alpha:0.08),
                    ],
                    stops: const <double>[0.0, 0.24, 1.0],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
