import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/core/profile/parcel_location_store.dart';
import 'package:bio_g/core/profile/profile_repository.dart';
import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/account/account_screen_presenter.dart';
import 'package:bio_g/screens/account/account_screen_sections.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/services/profile/profile_local_service.dart';
import 'package:bio_g/widgets/account/add_biog_screen.dart';
import 'package:bio_g/widgets/account/edit_profile_screen.dart';
import 'package:bio_g/core/agro/water/soil_profile_resolver.dart';
import 'package:bio_g/core/crops/crop_registry.dart';
import 'package:bio_g/widgets/account/soil_texture_account_screen.dart';
import 'package:bio_g/widgets/account/status_biog_screen.dart' as sb;
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_screen.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
import 'package:bio_g/widgets/shared/bio_g_page_background.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';

class AccountScreen extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavTap;

  const AccountScreen({
    super.key,
    required this.currentIndex,
    required this.onNavTap,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
  static const int _accountTabIndex = 1;

  // Instancia, NO estatica.
  //
  // Con `static` esta bandera se compartia entre todas las instancias y entre
  // todas las reconstrucciones, asi que la animacion de entrada corria **una
  // sola vez en toda la vida del proceso**: la primera. A partir de ahi el
  // controlador se creaba ya en 1.0 y la pantalla aparecia pintada de golpe,
  // sin reveal, al cambiar de pestaña o al reabrir la app.
  bool _hasAnimatedThisSession = false;

  static const String kIcNotification =
      'assets/icons/metrics/ic_notification.png';
  static const String kIcTemperature =
      'assets/icons/metrics/ic_temperature.png';
  static const String kIcConfigureCrop =
      'assets/icons/wizard/ic_configurar_cultivo.png';
  // Icono propio de la fila. Antes se reutilizaba la esfera de tierra media del
  // selector, que ya no sirve por dos razones: el asset se recortó a su
  // contenido (así que su escala en esta fila cambió) y, sobre todo, la esfera
  // de suelo franco AFIRMA una textura concreta en una fila que existe justo
  // para el productor que todavía no la ha elegido.
  static const String kIcSoilType = 'assets/icons/metrics/ic_soil_type.png';
  static const String kIcHelp = 'assets/icons/metrics/ic_help.png';
  static const String kIcManual = 'assets/icons/metrics/ic_manual.png';
  static const String kIcContact = 'assets/icons/metrics/ic_contact.png';
  static const String kIcError = 'assets/icons/metrics/ic_error.png';
  static const String kLeafDeviceIcon = 'assets/icons/metrics/nav_power.png';

  final ProfileLocalService _profileLocalService = const ProfileLocalService();
  final ProfileRepository _profileRepo = ProfileRepository(
    Supabase.instance.client,
  );
  final AccountScreenPresenter _presenter = AccountScreenPresenter();

  String _name = '';
  String _email = '';

  String? _avatarPath;
  bool _syncActive = true;
  String _location = '—';
  String _phone = '—';
  bool _notifications = true;
  bool _useCelsius = true;

  late final AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
      value: _hasAnimatedThisSession ? 1.0 : 0.0,
    );

    _loadLocalProfile().then((_) => _hydrateProfileFromSupabase());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final bool isActiveNow = widget.currentIndex == _accountTabIndex;

      if (isActiveNow && !_hasAnimatedThisSession) {
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      }
    });
  }

  @override
  void didUpdateWidget(covariant AccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool wasActiveBefore = oldWidget.currentIndex == _accountTabIndex;
    final bool isActiveNow = widget.currentIndex == _accountTabIndex;

    if (!wasActiveBefore && isActiveNow) {
      _entranceController
        ..stop()
        ..reset();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _entranceController.forward(from: 0);
        _hasAnimatedThisSession = true;
      });
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadLocalProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    final snapshot = await _profileLocalService.loadProfile(
      defaultLocation: _location,
      defaultPhone: _phone,
      defaultSyncActive: _syncActive,
    );

    if (!mounted) return;
    setState(() {
      _name = user?.userMetadata?['full_name']?.toString().trim() ?? 'Usuario';
      _email = user?.email ?? '';
      _avatarPath = snapshot.avatarPath;
      _syncActive = snapshot.syncActive;
      _location = snapshot.location;
      _phone = snapshot.phone;
      _notifications = snapshot.notifications;
      _useCelsius = snapshot.useCelsius;
    });
  }

  /// Durable restore from Supabase. Runs after the instant local load so
  /// the screen never blanks while waiting on the network. Overlays only
  /// non-empty remote values, so a sparse/empty profile row can never wipe
  /// valid local cache (avoids the "remote empty overwrites local" race).
  /// Also re-materialises the avatar into the local cache after a reinstall.
  Future<void> _hydrateProfileFromSupabase() async {
    if (Supabase.instance.client.auth.currentUser == null) return;

    try {
      final profile = await _profileRepo.getMyProfile();
      if (!mounted || profile == null) return;

      final String? remotePhone = _nonEmpty(profile.phone);

      // Cache non-empty remote values locally so they survive offline and
      // future cold starts.
      if (remotePhone != null) {
        await _profileLocalService.savePhone(remotePhone);
      }

      // La ubicación NO se copia directamente desde la fila remota.
      //
      // Aquí se hacía `saveLocation(profile.location)` a secas, y eso pisaba
      // el texto local con el de la nube sin mirar cuál era más nuevo: una
      // ubicación elegida sin cobertura —guardada en el teléfono, todavía sin
      // subir— desaparecía en cuanto esta pantalla se refrescaba. El store
      // compara fechas y solo deja ganar a la nube cuando de verdad es
      // posterior, y de paso mantiene las coordenadas y la etiqueta juntas.
      final StoredParcelLocation? effectiveLocation =
          await ParcelLocationStore.hydrateFromCloud(
            repository: _profileRepo,
            knownProfile: profile,
          );
      final String? remoteLocation =
          _nonEmpty(effectiveLocation?.label) ?? _nonEmpty(profile.location);

      // Reconcile the avatar in both directions:
      //   - remote has one, local missing/stale (e.g. after reinstall)
      //     → download it into the local cache.
      //   - local has one, remote has none (photo set before cloud sync
      //     existed) → back-fill it up to Storage so it survives a future
      //     reinstall.
      String? restoredAvatarPath;
      final bool localAvatarValid =
          _avatarPath != null && File(_avatarPath!).existsSync();
      final bool remoteHasAvatar = _nonEmpty(profile.avatarUrl) != null;

      if (!localAvatarValid && remoteHasAvatar) {
        restoredAvatarPath = await _restoreAvatarFromSupabase();
      } else if (localAvatarValid && !remoteHasAvatar) {
        await _backfillAvatarToSupabase(_avatarPath!);
      }

      if (!mounted) return;
      setState(() {
        if (remotePhone != null) _phone = remotePhone;
        if (remoteLocation != null) _location = remoteLocation;
        if (restoredAvatarPath != null) _avatarPath = restoredAvatarPath;
      });
    } catch (_) {
      // Offline / transient — keep showing the local cache.
    }
  }

  /// Upload an existing local avatar to Storage and record its path in
  /// `profiles.avatar_url`. Used to back-fill photos that were set before
  /// cloud sync existed, so they survive a reinstall. Best-effort.
  Future<void> _backfillAvatarToSupabase(String localPath) async {
    try {
      final file = File(localPath);
      if (!file.existsSync()) return;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final storagePath = await _profileRepo.uploadAvatar(bytes);
      if (storagePath != null) {
        await _profileRepo.updateProfile(avatarStoragePath: storagePath);
      }
    } catch (_) {
      // Best-effort; will retry on the next account-screen load.
    }
  }

  /// Download the avatar bytes from Storage and persist them to the local
  /// profile cache directory, returning the new file path (or null).
  Future<String?> _restoreAvatarFromSupabase() async {
    try {
      final bytes = await _profileRepo.downloadAvatar();
      if (bytes == null || bytes.isEmpty) return null;

      final dir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory(p.join(dir.path, 'profile'));
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final targetPath = p.join(
        avatarDir.path,
        'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      final file = File(targetPath);
      await file.writeAsBytes(bytes, flush: true);
      imageCache.evict(FileImage(file));

      await _profileLocalService.saveAvatarPath(targetPath);
      return targetPath;
    } catch (_) {
      return null;
    }
  }

  String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _openBioGStatus(BioGDevice device, int index) async {
    final store = BioGScope.of(context);
    final isActive = store.activeDevice?.id == device.id;
    final payload = _presenter.payloadForDevice(
      device,
      index,
      isActive: isActive,
    );

    final result = await Navigator.of(context).push<dynamic>(
      BioGPageRoute(builder: (_) => sb.StatusBioGScreen(device: payload)),
    );

    if (!mounted) return;

    if (result is Map && result['changedDisplayed'] == true) {
      final deviceId = (result['deviceId'] ?? '').toString().trim();

      if (deviceId.isNotEmpty) {
        await store.setActiveDevice(deviceId);
      }

      if (!mounted) return;
      widget.onNavTap(4);
      return;
    }

    if (result == true) {
      setState(() {});
    }
  }

  List<AccountMyBioGItem> _buildBioGItems(
    BioGStore store,
    List<BioGDevice> devices,
    String? activeId,
  ) {
    return List<AccountMyBioGItem>.generate(devices.length, (int index) {
      final device = devices[index];
      final isActive = activeId == device.id;
      final cropContext = _presenter.cropContextForDevice(store, device.id);
      final seed = store.seedForDevice(device.id);

      AccountDeviceCardUiModel buildUiModel(BioGTelemetry? telemetry) {
        return _presenter.deviceCardUiModelFromTelemetry(
          device: device,
          cropContext: cropContext,
          seed: seed,
          isActive: isActive,
          telemetry: telemetry,
        );
      }

      return AccountMyBioGItem(
        uiModel: buildUiModel(null),
        onTap: () => _openBioGStatus(device, index),
        liveTelemetryStream: store.watchTelemetryForDevice(device.id),
        liveUiModelBuilder: buildUiModel,
      );
    });
  }

  Future<void> _openEditProfile() async {
    await Navigator.of(
      context,
    ).push(BioGPageRoute(builder: (_) => const EditProfileScreen()));
    await _loadLocalProfile();
  }

  Future<void> _openConfigureCrop() async {
    await Navigator.of(
      context,
    ).push(BioGPageRoute(builder: (_) => const ConfigureSeedWizardScreen()));

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openSoilType() async {
    await Navigator.of(
      context,
    ).push(BioGPageRoute(builder: (_) => const SoilTextureAccountScreen()));

    if (!mounted) return;
    setState(() {});
  }

  /// Resumen del suelo para la fila de Cuenta.
  ///
  /// Se pide al mismo resolver que usa el motor, no a una lectura propia del
  /// campo guardado: si la pantalla leyera `soilTextureId` a pelo, un BIO-G
  /// Maceta mostraria «Sin definir» mientras el motor esta usando sustrato.
  /// Dos lecturas del mismo dato es exactamente el defecto que este trabajo
  /// viene a cerrar.
  String get _soilTypeSubtitle {
    final store = BioGScope.of(context);
    final ctx = store.activeCropContext;
    if (ctx == null) return 'Configura tu cultivo para definirlo';

    final profile = SoilProfileResolver.resolve(
      deviceModelId: store.activeDevice?.deviceModelId,
      cultivationScaleId: ctx.cultivationScaleId,
      soilTextureId: ctx.soilTextureId,
      soilTextureSourceId: ctx.soilTextureSource,
      // El cultivo decide la VARIANTE del sustrato (drenante para xerófitas).
      // Sin pasarlo, esta fila diría «Sustrato de maceta» para un cactus
      // mientras el motor estaría usando sustrato drenante: dos lecturas del
      // mismo dato, que es justo lo que este trabajo viene a cerrar.
      cropKey: CropRegistry.byKeyName(ctx.cropId)?.cropKey,
    );

    if (profile.texture.isSubstrate) return profile.texture.displayNameEs;
    if (profile.isFallback) return 'Sin definir · se usa tierra media';
    return '${profile.texture.displayNameEs} · '
        '${profile.texture.shortLabelEs.toLowerCase()}';
  }

  Future<void> _openAddBioG() async {
    final added = await Navigator.of(
      context,
    ).push<bool>(BioGPageRoute(builder: (_) => const AddBioGScreen()));

    if (added == true && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Bio-G agregado')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = BioGScope.of(context);

    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final devices = store.devices;
        final activeId = store.activeDevice?.id;
        final biogItems = _buildBioGItems(store, devices, activeId);

        return Scaffold(
          extendBody: true,
          backgroundColor: Colors.transparent,
          bottomNavigationBar: BioGBottomNav(
            currentIndex: widget.currentIndex,
            onTap: widget.onNavTap,
          ),
          body: Stack(
            children: <Widget>[
              BioGPageBackground(
                enabled: widget.currentIndex == _accountTabIndex,
              ),
              SafeArea(
                top: true,
                bottom: false,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: <Widget>[
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.00,
                        intervalEnd: 0.22,
                        yOffset: 6,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.02,
                        child: const AccountTopHeaderSection(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 14,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.08,
                        child: AccountUserCardSection(
                          name: _name,
                          email: _email,
                          avatarPath: _avatarPath,
                          syncActive: _syncActive,
                          onEditTap: _openEditProfile,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 6,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.01,
                        child: const AccountSectionHeader(title: 'Mis Bio-G'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 14,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.08,
                        child: AccountMyBioGCardSection(
                          deviceIconAsset: kLeafDeviceIcon,
                          errorIconAsset: kIcError,
                          items: biogItems,
                          onAddBioGTap: _openAddBioG,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 6,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.01,
                        child: const AccountSectionHeader(
                          title: 'Preferencias',
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 14,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.08,
                        child: AccountPreferencesCardSection(
                          configureCropAssetPath: kIcConfigureCrop,
                          soilTypeAssetPath: kIcSoilType,
                          soilTypeSubtitle: _soilTypeSubtitle,
                          notificationAssetPath: kIcNotification,
                          temperatureAssetPath: kIcTemperature,
                          notifications: _notifications,
                          useCelsius: _useCelsius,
                          onConfigureCropTap: _openConfigureCrop,
                          onSoilTypeTap: _openSoilType,
                          onNotificationsChanged: (value) {
                            setState(() => _notifications = value);
                            _profileLocalService.saveNotifications(value);
                          },
                          onUseCelsiusChanged: (value) {
                            setState(() => _useCelsius = value);
                            _profileLocalService.saveUseCelsius(value);
                          },
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 14)),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 6,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.01,
                        child: const AccountSectionHeader(title: 'Soporte'),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AccountReveal(
                        controller: _entranceController,
                        intervalStart: 0.10,
                        intervalEnd: 0.62,
                        yOffset: 14,
                        beginScale: 1.0,
                        shadowOpacityBegin: 0.00,
                        shadowOpacityEnd: 0.08,
                        child: AccountSupportCardSection(
                          helpAssetPath: kIcHelp,
                          manualAssetPath: kIcManual,
                          contactAssetPath: kIcContact,
                          onHelpTap: () {},
                          onContactTap: () {},
                          onManualTap: () {},
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 140 + MediaQuery.of(context).viewPadding.bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
