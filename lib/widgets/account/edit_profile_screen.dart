import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';

// ✅ Pantallas
import 'package:bio_g/core/account/account_deletion_service.dart';
import 'package:bio_g/core/auth/auth_repository.dart';
import 'package:bio_g/core/profile/profile_repository.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/account/location_screen.dart';
import 'package:bio_g/widgets/account/telephone_screen.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ===========================
  // ✅ Brand (NO cambiar)
  // ===========================
  static const Color kBrandMid = Color(0xFF3FAF6E);

  // ===========================
  // ✅ Pref keys
  // ===========================
  static const String _kPrefLocation = 'profile_location';
  static const String _kPrefPhone = 'profile_phone';
  static const String _kPrefSync = 'profile_sync_active';
  static const String _kPrefAvatarPath = 'profile_avatar_path';

  final ProfileRepository _profileRepo = ProfileRepository(
    Supabase.instance.client,
  );

  // ===========================
  // ✅ Datos reales desde Supabase auth
  // ===========================
  String _name = '';
  String _email = '';

  String _location = 'Rancho El Encanto';
  String _phone = '+52 55 1234 5678';
  bool _syncActive = true;

  File? _avatarFile;

  late _InitialProfile _initial;
  bool _saving = false;

  /// True mientras corre el borrado de cuenta, para bloquear la interfaz.
  bool _deletingAccount = false;
  bool _loadingPrefs = true;

  bool get _hasChanges {
    return _location != _initial.location ||
        _phone != _initial.phone ||
        _syncActive != _initial.syncActive ||
        (_avatarFile?.path != _initial.avatarPath);
  }

  @override
  void initState() {
    super.initState();

    _initial = _InitialProfile(
      location: _location,
      phone: _phone,
      syncActive: _syncActive,
      avatarPath: _avatarFile?.path,
    );

    _loadLocalProfile();
  }

  // ===========================
  // ✅ Helpers Tel (display)
  // ===========================
  String _formatPhoneForDisplay(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');

    String ten;
    if (digits.length >= 12 && digits.startsWith('52')) {
      ten = digits.substring(2, 12);
    } else if (digits.length >= 10) {
      ten = digits.substring(digits.length - 10);
    } else {
      ten = digits;
    }

    if (ten.length != 10) {
      return raw.trim().isEmpty ? '' : raw.trim();
    }

    final a = ten.substring(0, 2);
    final b = ten.substring(2, 6);
    final c = ten.substring(6, 10);
    return '+52 $a $b $c';
  }

  Future<void> _loadLocalProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final prefs = await SharedPreferences.getInstance();

      final loc = prefs.getString(_kPrefLocation);
      final phone = prefs.getString(_kPrefPhone);
      final sync = prefs.getBool(_kPrefSync);
      final avatarPath = prefs.getString(_kPrefAvatarPath);

      File? loadedAvatar;
      if (avatarPath != null && avatarPath.trim().isNotEmpty) {
        final f = File(avatarPath);
        if (f.existsSync()) loadedAvatar = f;
      }

      if (!mounted) return;
      setState(() {
        _name = user?.userMetadata?['full_name']?.toString().trim() ?? 'Usuario';
        _email = user?.email ?? '';

        if (loc != null && loc.trim().isNotEmpty) _location = loc.trim();

        if (phone != null && phone.trim().isNotEmpty) {
          _phone = _formatPhoneForDisplay(phone.trim());
        }

        if (sync != null) _syncActive = sync;

        _avatarFile = loadedAvatar;

        _initial = _InitialProfile(
          location: _location,
          phone: _phone,
          syncActive: _syncActive,
          avatarPath: _avatarFile?.path,
        );

        _loadingPrefs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPrefs = false);
    }
  }

  void _showWebOnlyDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _WebOnlyAlert(brandMid: kBrandMid),
    );
  }

  // ===========================
  // ✅ AVATAR PERSIST (anti-cache + borra anterior)
  // ===========================
  Future<File> _persistAvatar(File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final avatarDir = Directory(p.join(dir.path, 'profile'));
    if (!await avatarDir.exists()) {
      await avatarDir.create(recursive: true);
    }

    final oldPath = _avatarFile?.path ?? _initial.avatarPath;
    if (oldPath != null && oldPath.trim().isNotEmpty) {
      final oldFile = File(oldPath);
      if (oldFile.existsSync()) {
        try {
          imageCache.evict(FileImage(oldFile));
          await oldFile.delete();
        } catch (_) {}
      }
    }

    final targetPath = p.join(
      avatarDir.path,
      'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );

    final targetFile = await source.copy(targetPath);
    imageCache.evict(FileImage(targetFile));
    return targetFile;
  }

  Future<void> _changePhoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _GlassCard(
              radius: 22,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetAction(
                    icon: Icons.photo_camera_rounded,
                    title: 'Tomar foto',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFrom(ImageSource.camera);
                    },
                  ),
                  const _DividerLine(),
                  _SheetAction(
                    icon: Icons.photo_library_rounded,
                    title: 'Elegir de galería',
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickFrom(ImageSource.gallery);
                    },
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickFrom(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 1200,
        preferredCameraDevice: CameraDevice.front,
      );

      if (picked == null) return;

      final persisted = await _persistAvatar(File(picked.path));
      if (!mounted) return;

      setState(() => _avatarFile = persisted);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'No se pudo abrir la cámara. Revisa permisos.'
                : 'No se pudo seleccionar la foto. Revisa permisos de galería.',
          ),
        ),
      );
    }
  }

  // ===========================
  // ✅ Sync always-on — portal-only toggle
  // ===========================
  void _handleSyncToggle(bool v) {
    if (v == false) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => const _SyncPortalOnlyAlert(),
      );
    }
    // Sync is always on — ignore the toggle value.
  }

  Future<void> _confirmDeleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            '¿Eliminar cuenta?',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'Esta acción es permanente. Se eliminarán tus datos y la cuenta quedará inhabilitada.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  color: Color(0xFFB2554E),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true || !mounted) return;

    // Reautenticación obligatoria antes de una acción destructiva. Es
    // requisito de ambas tiendas y, más importante, evita que alguien que
    // encuentre el teléfono desbloqueado pueda borrar la cuenta.
    final password = await _askPasswordForDeletion();
    if (password == null || !mounted) return;

    final store = BioGScope.of(context);
    // Los dos ids de cada Bio-G: el de interfaz y el de telemetría. El
    // almacenamiento local de lecturas usa el segundo, y para los dispositivos
    // heredados no coinciden.
    final deviceIds = <String>{
      for (final d in store.devices) ...<String>[
        d.id,
        if (d.telemetryDeviceId != null) d.telemetryDeviceId!,
      ],
    }.toList(growable: false);
    final userId = store.currentUserId;

    setState(() => _deletingAccount = true);

    final service = AccountDeletionService(
      authRepository: AuthRepository(Supabase.instance.client),
      // Sin esto, la cola de subidas pendientes sobrevivía al borrado y el
      // mensaje "borramos todos los datos de este teléfono" era inexacto.
      ingestService: store.telemetryIngest,
      // La instancia viva de la cola de sincronización: su `clear` se serializa
      // con los drenados en vuelo, cosa que borrar la clave a mano no hace.
      clearPendingSync: store.clearPendingSync,
    );

    late final AccountDeletionResult result;
    try {
      result = await service.deleteAccount(
        password: password,
        userId: userId,
        deviceIds: deviceIds,
      );
    } catch (e) {
      result = AccountDeletionResult(
        outcome: AccountDeletionOutcome.failed,
        messageEs:
            'No se pudo completar la eliminación. Inténtalo de nuevo.',
        remoteError: e.toString(),
      );
    }

    if (!mounted) return;
    setState(() => _deletingAccount = false);

    // El mensaje lo redacta el servicio a partir de lo que REALMENTE ocurrió.
    // La pantalla no puede prometer un borrado que no sucedió.
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          result.isComplete ? 'Cuenta eliminada' : 'Eliminación parcial',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        content: Text(result.messageEs),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (result.outcome != AccountDeletionOutcome.failed) {
      // La sesión ya se cerró dentro del servicio; se sale de la pantalla para
      // que el árbol de navegación vuelva a la puerta de entrada.
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  /// Pide la contraseña actual para confirmar el borrado.
  Future<String?> _askPasswordForDeletion() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: const Text(
              'Confirma tu identidad',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Escribe tu contraseña actual para eliminar la cuenta.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text),
                child: const Text(
                  'Continuar',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _save() async {
    if (_saving || !_hasChanges) return;
    setState(() => _saving = true);

    try {
      // 1) Offline-first: local cache is written first and unconditionally,
      //    so the change survives even with no connectivity.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPrefLocation, _location.trim());
      await prefs.setString(_kPrefPhone, _phone.trim());
      await prefs.setBool(_kPrefSync, _syncActive);

      if (_avatarFile != null && _avatarFile!.path.isNotEmpty) {
        await prefs.setString(_kPrefAvatarPath, _avatarFile!.path);
      } else {
        await prefs.remove(_kPrefAvatarPath);
      }

      // 2) Best-effort durable mirror to Supabase. Wrapped so a network
      //    failure never blocks saving locally — the next successful save
      //    (or sync) reconciles it.
      await _syncProfileToSupabase();

      if (!mounted) return;
      setState(() {
        _saving = false;
        _initial = _InitialProfile(
          location: _location,
          phone: _phone,
          syncActive: _syncActive,
          avatarPath: _avatarFile?.path,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar los cambios')),
      );
    }
  }

  /// Mirror the editable profile fields to Supabase. Best-effort, but the
  /// avatar upload and the text-field update are kept INDEPENDENT: a failed
  /// photo upload must never block phone/location from syncing (an earlier
  /// version coupled them, so any upload error left all three fields null).
  Future<void> _syncProfileToSupabase() async {
    if (Supabase.instance.client.auth.currentUser == null) return;

    // (a) Text fields — always attempt, independent of the avatar.
    try {
      await _profileRepo.updateProfile(
        phone: _phone.trim(),
        location: _location.trim(),
      );
    } catch (e) {
      debugPrint('[BioG/ProfileSync] updateProfile failed: $e');
    }

    // (b) Avatar — upload whenever a local file exists. The upload is
    //     idempotent (always {userId}/avatar.jpg), so this also BACK-FILLS
    //     a photo that was set before cloud sync existed. On failure we
    //     surface the reason instead of swallowing it, so the photo isn't
    //     silently left out of the cloud.
    final avatar = _avatarFile;
    if (avatar == null || avatar.path.isEmpty) return;

    try {
      final bytes = await avatar.readAsBytes();
      final storagePath = await _profileRepo.uploadAvatar(bytes);
      if (storagePath != null) {
        await _profileRepo.updateProfile(avatarStoragePath: storagePath);
      }
    } catch (e) {
      debugPrint('[BioG/ProfileSync] avatar upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Foto guardada en el equipo, pero no se pudo subir a la nube.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingPrefs) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _SoftBackground(),
            Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _SoftBackground(),
          SafeArea(
            top: true,
            bottom: false,
            child: Column(
              children: [
                _TopBar(
                  saving: _saving,
                  canSave: _hasChanges,
                  onCancel: () => Navigator.pop(context),
                  onSave: _save,
                  brandMid: kBrandMid,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderCard(
                          brandMid: kBrandMid,
                          name: _name,
                          email: _email,
                          active: _syncActive,
                          avatarFile: _avatarFile,
                          onPickPhoto: _changePhoto,
                        ),
                        const SizedBox(height: 14),
                        _GlassCard(
                          radius: 22,
                          child: Column(
                            children: [
                              _EditRow(
                                assetIcon:
                                    'assets/icons/metrics/ic_security.png',
                                title: 'Nombre',
                                value: _name,
                                locked: true,
                                onTap: _showWebOnlyDialog,
                              ),
                              const _DividerLine(),
                              _EditRow(
                                assetIcon:
                                    'assets/icons/metrics/ic_contact.png',
                                title: 'Correo',
                                value: _email,
                                locked: true,
                                onTap: _showWebOnlyDialog,
                              ),
                              const _DividerLine(),
                              _EditRow(
                                assetIcon:
                                    'assets/icons/metrics/ic_location.png',
                                title: 'Ubicación',
                                value: _location,
                                onTap: () async {
                                  final res = await Navigator.of(context)
                                      .push<String>(
                                        BioGPageRoute(
                                          builder: (_) => LocationScreen(
                                            initialValue: _location,
                                            brandMid: kBrandMid,
                                          ),
                                        ),
                                      );
                                  if (res == null) return;
                                  setState(() => _location = res);
                                },
                              ),
                              const _DividerLine(),
                              _EditRow(
                                assetIcon:
                                    'assets/icons/metrics/ic_telephone.png',
                                title: 'Teléfono',
                                value: _phone,
                                onTap: () async {
                                  final res = await Navigator.of(context)
                                      .push<String>(
                                        BioGPageRoute(
                                          builder: (_) => TelephoneScreen(
                                            initialValue: _phone,
                                            brandMid: kBrandMid,
                                          ),
                                        ),
                                      );
                                  if (res == null) return;
                                  setState(
                                    () => _phone = _formatPhoneForDisplay(res),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const _SectionTitle('Sincronización actual'),
                        const SizedBox(height: 10),

                        // ✅ Card de sync más angosto + centrado
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.92,
                            child: _GlassCard(
                              radius: 22,
                              child: Row(
                                children: [
                                  Icon(
                                    _syncActive
                                        ? Icons.check_circle_rounded
                                        : Icons.cancel_rounded,
                                    size: 18,
                                    color: _syncActive
                                        ? kBrandMid
                                        : Colors.black38,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _syncActive ? 'Activa' : 'Inactiva',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF0E1A16),
                                      ),
                                    ),
                                  ),
                                  Switch(
                                    value: _syncActive,
                                    onChanged: _handleSyncToggle,
                                    activeColor: kBrandMid,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),

                        // ✅ Botón eliminar más abajo
                        //
                        // Se deshabilita mientras corre el borrado: pulsarlo
                        // dos veces lanzaría dos reautenticaciones y dos
                        // purgas locales en paralelo.
                        _DeleteButton(
                          onTap: _deletingAccount
                              ? null
                              : _confirmDeleteAccount,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== TOP BAR ===================== */

class _TopBar extends StatelessWidget {
  final bool saving;
  final bool canSave;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final Color brandMid;

  const _TopBar({
    required this.saving,
    required this.canSave,
    required this.onCancel,
    required this.onSave,
    required this.brandMid,
  });

  @override
  Widget build(BuildContext context) {
    final saveEnabled = canSave && !saving;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
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
            'Editar perfil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0E1A16),
            ),
          ),
          const Spacer(),
          _SavePillButton(
            enabled: saveEnabled,
            loading: saving,
            onTap: onSave,
            color: brandMid,
          ),
        ],
      ),
    );
  }
}

class _SavePillButton extends StatefulWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;
  final Color color;

  const _SavePillButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
    required this.color,
  });

  @override
  State<_SavePillButton> createState() => _SavePillButtonState();
}

class _SavePillButtonState extends State<_SavePillButton> {
  bool _pressed = false;

  static const Color brandTop = Color(0xFF40BB5F);
  static const Color brandMid = Color(0xFF3FAF6E);
  static const Color brandBase = Color.fromARGB(137, 43, 126, 101);

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.985 : 1.0;

    if (!widget.enabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha:0.08),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Guardar',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: Colors.black.withValues(alpha:0.35),
          ),
        ),
      );
    }

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
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha:0.08),
              blurRadius: 24,
              offset: const Offset(0, 10),
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
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [brandTop, brandMid, brandBase],
                ),
              ),
              child: Padding(
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
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================== HEADER CARD ===================== */

class _HeaderCard extends StatelessWidget {
  final Color brandMid;
  final String name;
  final String email;
  final bool active;
  final File? avatarFile;
  final VoidCallback onPickPhoto;

  const _HeaderCard({
    required this.brandMid,
    required this.name,
    required this.email,
    required this.active,
    required this.avatarFile,
    required this.onPickPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      radius: 22,
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _AvatarCircle(size: 74, file: avatarFile),
              Positioned(
                right: -6,
                bottom: -6,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onPickPhoto,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha:0.92),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha:0.95),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha:0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.photo_camera_rounded,
                      size: 18,
                      color: brandMid,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0E1A16),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: active ? brandMid : Colors.black38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sincronización: ${active ? "Activa" : "Inactiva"}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.black.withValues(alpha:0.55),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ===================== ROWS ===================== */

class _EditRow extends StatelessWidget {
  final String? assetIcon;
  final String title;
  final String value;
  final VoidCallback? onTap;
  final bool locked;

  const _EditRow({
    this.assetIcon,
    required this.title,
    required this.value,
    this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (assetIcon != null)
              _AssetIcon(path: assetIcon!, box: 34, size: 22, scale: 2.65),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0E1A16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha:locked ? 0.40 : 0.55),
                    ),
                  ),
                ],
              ),
            ),
            if (locked)
              Icon(
                Icons.lock_rounded,
                size: 18,
                color: Colors.black.withValues(alpha:0.30),
              )
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.black26),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w900,
        color: Color(0xFF0E1A16),
      ),
    );
  }
}

/* ===================== DISABLE SYNC ALERT (MAIL-LIKE) ===================== */

class _DisableSyncAlert extends StatefulWidget {
  const _DisableSyncAlert({super.key});

  @override
  State<_DisableSyncAlert> createState() => _DisableSyncAlertState();
}

class _DisableSyncAlertState extends State<_DisableSyncAlert>
    with TickerProviderStateMixin {
  static const String _kIconPath = 'assets/icons/metrics/ic_alert.png';

  // ✅ Tamaños como pediste
  static const double _kW = 0.90;
  static const double _kH = 0.50;
  static const double _kIconBaseScale = 4.2;
  static const double _kDialogScale = 1.10;

  late final AnimationController _dialogC;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  late final AnimationController _iconC;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _dialogC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic));

    _iconC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.98,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
    ]).animate(_iconC);

    Future.delayed(const Duration(milliseconds: 40), () {
      if (!mounted) return;
      _dialogC.forward();
    });

    Future.delayed(const Duration(milliseconds: 170), () {
      if (!mounted) return;
      _iconC.forward();
    });
  }

  @override
  void dispose() {
    _dialogC.dispose();
    _iconC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          child: Transform.scale(
            scale: _kDialogScale,
            child: SizedBox(
              width: size.width * _kW,
              height: size.height * _kH,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                actionsPadding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                title: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _iconC,
                      builder: (context, _) {
                        return Opacity(
                          opacity: (_iconC.value == 0) ? 0.0 : 1.0,
                          child: Transform.scale(
                            scale: _iconScale.value * _kIconBaseScale,
                            child: Image.asset(
                              _kIconPath,
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Desactivar sincronización',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.black.withValues(alpha:0.06),
                    ),
                  ],
                ),
                content: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Si desactivas la sincronización, tus datos no se actualizarán en la web. ¿Estás seguro?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha:0.68),
                    ),
                  ),
                ),

                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Desactivar',
                      style: TextStyle(
                        color: Color(0xFFB2554E),
                        fontWeight: FontWeight.w900,
                      ),
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

/* ===================== SYNC PORTAL-ONLY ALERT ===================== */

class _SyncPortalOnlyAlert extends StatefulWidget {
  const _SyncPortalOnlyAlert();

  @override
  State<_SyncPortalOnlyAlert> createState() => _SyncPortalOnlyAlertState();
}

class _SyncPortalOnlyAlertState extends State<_SyncPortalOnlyAlert>
    with TickerProviderStateMixin {
  static const String _kIconPath = 'assets/icons/metrics/ic_alert.png';

  static const double _kW = 0.90;
  static const double _kH = 0.50;
  static const double _kIconBaseScale = 4.2;
  static const double _kDialogScale = 1.10;

  late final AnimationController _dialogC;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  late final AnimationController _iconC;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _dialogC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _fade = CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic));

    _iconC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.98, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
    ]).animate(_iconC);

    Future.delayed(const Duration(milliseconds: 40), () {
      if (!mounted) return;
      _dialogC.forward();
    });

    Future.delayed(const Duration(milliseconds: 170), () {
      if (!mounted) return;
      _iconC.forward();
    });
  }

  @override
  void dispose() {
    _dialogC.dispose();
    _iconC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          child: Transform.scale(
            scale: _kDialogScale,
            child: SizedBox(
              width: size.width * _kW,
              height: size.height * _kH,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                actionsPadding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                title: Column(
                  children: [
                    AnimatedBuilder(
                      animation: _iconC,
                      builder: (context, _) {
                        return Opacity(
                          opacity: (_iconC.value == 0) ? 0.0 : 1.0,
                          child: Transform.scale(
                            scale: _iconScale.value * _kIconBaseScale,
                            child: Image.asset(
                              _kIconPath,
                              width: 26,
                              height: 26,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Sincronización activa',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ],
                ),
                content: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'La sincronización protege tus datos de cultivo, '
                    'telemetría y configuración.\n\n'
                    'Solo puedes desactivarla desde el portal web de BIO-G.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withValues(alpha: 0.68),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w900),
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

/* ===================== DELETE BUTTON ===================== */

class _DeleteButton extends StatefulWidget {
  /// Null deshabilita el botón (borrado en curso).
  final VoidCallback? onTap;
  const _DeleteButton({required this.onTap});

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _pressed = false;

  void _setPressed(bool v) {
    if (_pressed == v) return;
    setState(() => _pressed = v);
  }

  static const Color _red = Color(0xFFFF3B30);
  static const Color _deep = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    final scale = _pressed ? 0.988 : 1.0;
    final overlayOpacity = _pressed ? 0.06 : 0.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _red.withValues(alpha:0.14),
              blurRadius: 26,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha:0.10),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onHighlightChanged: _setPressed,
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              child: Ink(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_red.withValues(alpha:0.73), _deep.withValues(alpha:0.58)],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha:0.22),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    AnimatedOpacity(
                      opacity: overlayOpacity,
                      duration: const Duration(milliseconds: 120),
                      child: Container(color: Colors.black),
                    ),
                    const SizedBox(
                      height: 46,
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Eliminar cuenta',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    color: Color(0x55000000),
                                    blurRadius: 14,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
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

/* ===================== WEB ONLY ALERT ===================== */

class _WebOnlyAlert extends StatefulWidget {
  final Color brandMid;
  const _WebOnlyAlert({required this.brandMid});

  @override
  State<_WebOnlyAlert> createState() => _WebOnlyAlertState();
}

class _WebOnlyAlertState extends State<_WebOnlyAlert>
    with TickerProviderStateMixin {
  static const String _kIconPath = 'assets/icons/metrics/ic_alert.png';

  // ✅ Respeta tus tamaños originales
  static const double _kW = 0.90;
  static const double _kH = 0.50;
  static const double _kIconBaseScale = 4.2;
  static const double _kDialogScale = 1.10;

  late final AnimationController _dialogC;
  late final Animation<double> _dialogFade;
  late final Animation<double> _dialogScale;

  late final AnimationController _iconC;
  late final Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _dialogC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _dialogFade = CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic);
    _dialogScale = Tween<double>(
      begin: 0.88,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dialogC, curve: Curves.easeOutCubic));

    _iconC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _iconScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.12,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.12,
          end: 0.98,
        ).chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.98,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 15,
      ),
    ]).animate(_iconC);

    Future.delayed(const Duration(milliseconds: 80), () {
      if (!mounted) return;
      _dialogC.forward();
    });

    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      _iconC.forward();
    });
  }

  @override
  void dispose() {
    _dialogC.dispose();
    _iconC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return FadeTransition(
      opacity: _dialogFade,
      child: ScaleTransition(
        scale: _dialogScale,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          child: Transform.scale(
            scale: _kDialogScale,
            child: SizedBox(
              width: size.width * _kW,
              height: size.height * _kH,
              child: AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                titlePadding: const EdgeInsets.fromLTRB(22, 24, 22, 0),
                contentPadding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                actionsPadding: const EdgeInsets.fromLTRB(18, 6, 18, 14),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _iconC,
                      builder: (context, _) {
                        final s = _iconScale.value;
                        return Opacity(
                          opacity: (_iconC.value == 0) ? 0.0 : 1.0,
                          child: Transform.scale(
                            scale: s * _kIconBaseScale,
                            child: Image.asset(
                              _kIconPath,
                              width: 32,
                              height: 32,
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Cambios desde la web',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.black.withValues(alpha:0.06),
                    ),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'Por seguridad, el nombre y el correo se actualizan únicamente desde el portal web.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withValues(alpha:0.70),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'En la app puedes cambiar tu foto, teléfono y ubicación.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: Colors.black.withValues(alpha:0.55),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
                actionsAlignment: MainAxisAlignment.end,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Entendido',
                      style: TextStyle(fontWeight: FontWeight.w900),
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

/* ===================== BOTTOM SHEET ACTION ===================== */

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                icon,
                size: 20,
                color: Colors.black.withValues(alpha:0.80),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0E1A16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ===================== ASSET ICON ===================== */

class _AssetIcon extends StatelessWidget {
  final String path;
  final double box;
  final double size;
  final double scale;

  const _AssetIcon({
    required this.path,
    this.box = 34,
    this.size = 22,
    this.scale = 1.28,
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

/* ===================== BACKGROUND + GLASS ===================== */

class _SoftBackground extends StatelessWidget {
  const _SoftBackground();

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
              color: Colors.white.withValues(alpha:0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.white.withValues(alpha:0.55)),
            ),
            padding: const EdgeInsets.all(14),
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
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.black.withValues(alpha:0.06),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final double size;
  final File? file;

  const _AvatarCircle({required this.size, required this.file});

  @override
  Widget build(BuildContext context) {
    final hasFile = file != null && file!.path.isNotEmpty && file!.existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha:0.65),
        border: Border.all(color: Colors.white.withValues(alpha:0.75), width: 1),
      ),
      child: ClipOval(
        child: hasFile
            ? Image.file(file!, fit: BoxFit.cover, key: ValueKey(file!.path))
            : const Icon(Icons.person_rounded, color: Colors.black54, size: 34),
      ),
    );
  }
}

/* ===================== INTERNAL MODEL ===================== */

class _InitialProfile {
  final String location;
  final String phone;
  final bool syncActive;
  final String? avatarPath;

  const _InitialProfile({
    required this.location,
    required this.phone,
    required this.syncActive,
    required this.avatarPath,
  });
}
