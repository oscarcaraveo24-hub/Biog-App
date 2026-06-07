import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/account/account_screen_presenter.dart';
import 'package:bio_g/screens/account/account_screen_sections.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/services/profile/profile_local_service.dart';
import 'package:bio_g/widgets/account/add_biog_screen.dart';
import 'package:bio_g/widgets/account/edit_profile_screen.dart';
import 'package:bio_g/widgets/account/status_biog_screen.dart' as sb;
import 'package:bio_g/widgets/account/wizard/configure_seed_wizard_screen.dart';
import 'package:bio_g/widgets/bottom_nav.dart';
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

  static bool _hasAnimatedThisSession = false;

  static const String kIcNotification =
      'assets/icons/metrics/ic_notification.png';
  static const String kIcTemperature =
      'assets/icons/metrics/ic_temperature.png';
  static const String kIcConfigureCrop =
      'assets/icons/wizard/ic_configurar_cultivo.png';
  static const String kIcHelp = 'assets/icons/metrics/ic_help.png';
  static const String kIcManual = 'assets/icons/metrics/ic_manual.png';
  static const String kIcContact = 'assets/icons/metrics/ic_contact.png';
  static const String kIcError = 'assets/icons/metrics/ic_error.png';
  static const String kLeafDeviceIcon = 'assets/icons/metrics/nav_power.png';

  final ProfileLocalService _profileLocalService = const ProfileLocalService();
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

    _loadLocalProfile();

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

    if (!wasActiveBefore && isActiveNow && !_hasAnimatedThisSession) {
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
              const AccountSoftBackground(),
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
                          notificationAssetPath: kIcNotification,
                          temperatureAssetPath: kIcTemperature,
                          notifications: _notifications,
                          useCelsius: _useCelsius,
                          onConfigureCropTap: _openConfigureCrop,
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
