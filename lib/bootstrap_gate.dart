import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/core/crops/ornamental/ornamental_crops.dart';
import 'package:bio_g/core/crops/recurring_bloom/recurring_bloom_crops.dart';
import 'package:bio_g/core/crops/catalog/crop_catalog.dart';
import 'package:bio_g/core/crops/tree_lifecycle.dart';
import 'package:bio_g/core/profile/profile_repository.dart';
import 'package:bio_g/models/device_crop_context.dart';
import 'package:bio_g/models/onboarding/onboarding_draft.dart';
import 'package:bio_g/models/user_profile.dart';
import 'package:bio_g/screens/app_shell.dart';
import 'package:bio_g/screens/auth/auth_screen.dart';
import 'package:bio_g/screens/auth/welcome_screen.dart';
import 'package:bio_g/screens/onboarding/onboarding_wizard_screen.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/widgets/account/wizard/wizard_crop_context_resolver.dart';
import 'package:bio_g/widgets/shared/bio_g_page_route.dart';

const bool _kDebugForceSignInPreview = false;
const bool _kDebugScreenGallery = false;

@visibleForTesting
DeviceCropContext resolveOnboardingTreeDraftContext({
  required String deviceId,
  required OnboardingDraft draft,
  required String cropId,
  required String stage,
  DeviceCropContext? previous,
  DateTime? now,
  WizardCropContextResolver contextResolver = const WizardCropContextResolver(),
}) {
  final DateTime effectiveNow = now ?? DateTime.now();
  final String categoryId =
      draft.cropCategory ??
      previous?.cropCategoryId ??
      CropCatalog.treeCategoryId;

  // "Aún no planto / por plantar": ciclo planeado, sin anclaje perenne todavía.
  if (stage == 'planned') {
    return contextResolver.resolve(
      deviceId: deviceId,
      cropCategoryId: categoryId,
      cropId: cropId,
      lifecycleStatus: CropLifecycleStatus.planned,
      dateConfidence: draft.useFlexibleDate
          ? DateConfidence.unknown
          : DateConfidence.exact,
      now: effectiveNow,
      previous: previous,
      varietyId: draft.varietyId,
      varietyAlias: draft.varietyAlias,
      selectedDate: draft.useFlexibleDate ? null : draft.selectedDate,
      timezone: draft.timezone ?? previous?.timezone,
      cultivationScaleId: draft.cultivationScale,
    );
  }

  // El estado/etapa/anclaje se resuelven con el MISMO modelo canónico que
  // account/configure (Fase 4). La rama "solo creciendo" deriva el estado de
  // la fecha de plantación; la primera floración entra a producción.
  final DateTime? plantingOrAnchorDate = draft.useFlexibleDate
      ? null
      : (draft.selectedDate ?? effectiveNow);

  final selection = resolveOnboardingTreeSelection(
    productionStatusId: draft.treeProductionStatusId,
    phenologyStageId: stage,
    plantingDate: plantingOrAnchorDate,
    now: effectiveNow,
  );

  final String safeStageId = safeTreeStageForState(
    perennialStateId: selection.perennialStateId,
    phenologyStageId: selection.phenologyStageId,
  );

  final DateTime? anchorDate =
      selection.perennialAnchorTypeId == TreeAnchorTypeIds.unknown
      ? null
      : plantingOrAnchorDate;

  // Eje MEMORIA/EDAD (sowingDate): solo la rama de plantación captura una fecha
  // de plantación real. En las ramas productivas la fecha es un evento de etapa
  // (no plantación), así que se deja null y el resolver conserva la memoria
  // previa. La precisión (#1/#12) reutiliza sowing_date_confidence: exacta si el
  // usuario recuerda la fecha, unknown si la dejó aproximada.
  final DateTime? treePlantingDate =
      selection.perennialAnchorTypeId == TreeAnchorTypeIds.planting
      ? plantingOrAnchorDate
      : null;

  return contextResolver.resolve(
    deviceId: deviceId,
    cropCategoryId: categoryId,
    cropId: cropId,
    lifecycleStatus: CropLifecycleStatus.planted,
    dateConfidence: draft.useFlexibleDate
        ? DateConfidence.unknown
        : DateConfidence.exact,
    now: effectiveNow,
    previous: previous,
    varietyId: draft.varietyId,
    varietyAlias: draft.varietyAlias,
    selectedDate: null,
    timezone: draft.timezone ?? previous?.timezone,
    cultivationScaleId: draft.cultivationScale,
    perennialStateId: selection.perennialStateId,
    phenologyStageId: safeStageId,
    perennialAnchorDate: anchorDate,
    perennialAnchorTypeId: selection.perennialAnchorTypeId,
    treePlantingDate: treePlantingDate,
  );
}

/// Resuelve el contexto ORNAMENTAL del onboarding (cactus, suculenta…). Espejo
/// de [resolveOnboardingTreeDraftContext] pero para el modo
/// `establishment_maintenance`. Solo hay dos intenciones: la voy a plantar / ya
/// está plantada. Ninguna fecha se interpreta como evidencia biológica.
@visibleForTesting
DeviceCropContext resolveOnboardingOrnamentalDraftContext({
  required String deviceId,
  required OnboardingDraft draft,
  required String cropId,
  required String stage,
  DeviceCropContext? previous,
  DateTime? now,
  WizardCropContextResolver contextResolver = const WizardCropContextResolver(),
}) {
  final DateTime effectiveNow = now ?? DateTime.now();
  final String categoryId =
      draft.cropCategory ??
      previous?.cropCategoryId ??
      CropCatalog.ornamentalCategoryId;

  final String intentId = normalizeOrnamentalSetupIntentId(cropId, stage);
  final bool isPlannedPlant = intentId == kOrnamentalIntentPlannedPlant;

  final DateTime today = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day,
  );
  final DateTime? rawDate = draft.useFlexibleDate ? null : draft.selectedDate;
  DateTime? selectedDate;
  if (rawDate != null) {
    final pickedDay = DateTime(rawDate.year, rawDate.month, rawDate.day);
    final requiresFuture = ornamentalSetupIntentRequiresFutureDate(
      cropId,
      intentId,
    );
    final valid = requiresFuture
        ? pickedDay.isAfter(today)
        : !pickedDay.isAfter(today);
    if (valid) selectedDate = rawDate;
  }

  final bool preserveExistingAnchor =
      intentId == kOrnamentalIntentAlreadyPlanted &&
      selectedDate == null &&
      previous?.ornamentalAnchorDate != null;
  final DateTime? effectiveAnchorDate = preserveExistingAnchor
      ? previous!.ornamentalAnchorDate
      : selectedDate;

  late final DateConfidence dateConfidence;
  if (preserveExistingAnchor) {
    dateConfidence =
        previous!.ornamentalAnchorDateConfidence ?? DateConfidence.unknown;
  } else if (selectedDate == null) {
    dateConfidence = DateConfidence.unknown;
  } else if (intentId == kOrnamentalIntentAlreadyPlanted) {
    dateConfidence = DateConfidence.estimated;
  } else {
    dateConfidence = DateConfidence.exact;
  }

  // FUENTE ÚNICA de la etapa (la misma que usa el wizard de cuenta). Si se
  // duplica la lógica aquí, las dos pantallas se desincronizan.
  final OrnamentalStageEstimate stageEstimate = resolveOrnamentalSetupStage(
    cropId: cropId,
    intentId: intentId,
    plantingDate: effectiveAnchorDate,
    now: effectiveNow,
    profileId: draft.varietyId,
    previousStageId: previous?.ornamentalStageId,
  );

  final String ornamentalStageId = stageEstimate.stageId;
  final double ornamentalStageConfidence = stageEstimate.confidence;
  final String ornamentalAnchorTypeId = preserveExistingAnchor
      ? normalizeOrnamentalAnchorTypeId(
          cropId,
          previous?.ornamentalAnchorTypeId,
        )
      : stageEstimate.anchorTypeId;

  return contextResolver.resolve(
    deviceId: deviceId,
    cropCategoryId: categoryId,
    cropId: cropId,
    lifecycleStatus: isPlannedPlant
        ? CropLifecycleStatus.planned
        : CropLifecycleStatus.planted,
    dateConfidence: dateConfidence,
    now: effectiveNow,
    previous: previous,
    varietyId: draft.varietyId,
    varietyAlias: draft.varietyAlias,
    selectedDate: selectedDate,
    timezone: draft.timezone ?? previous?.timezone,
    // El flujo ornamental no pregunta ubicación/maceta/jardín. El contexto
    // queda desconocido hasta que exista una edición no bloqueante posterior.
    cultivationScaleId: null,
    ornamentalStageId: ornamentalStageId,
    ornamentalAnchorDate: effectiveAnchorDate,
    ornamentalAnchorTypeId: ornamentalAnchorTypeId,
    ornamentalStageConfidence: ornamentalStageConfidence,
  );
}

/// Resuelve el contexto del ROSAL (floración recurrente) desde el onboarding.
/// `draft.stage` trae el id de la opción VISUAL elegida; de ahí se derivan la
/// intención, el estado a persistir y el anclaje. Las opciones de establecimiento
/// dejan que la fecha resuelva la etapa; los estados recurrentes se guardan tal
/// cual el usuario los vio.
@visibleForTesting
DeviceCropContext resolveOnboardingRecurringBloomDraftContext({
  required String deviceId,
  required OnboardingDraft draft,
  required String cropId,
  required String stage,
  DeviceCropContext? previous,
  DateTime? now,
  WizardCropContextResolver contextResolver = const WizardCropContextResolver(),
}) {
  final DateTime effectiveNow = now ?? DateTime.now();
  final String categoryId =
      draft.cropCategory ??
      previous?.cropCategoryId ??
      CropCatalog.ornamentalCategoryId;

  RecurringBloomStateOption? option;
  for (final candidate in recurringBloomVisualStateOptions(cropId)) {
    if (candidate.id == stage) {
      option = candidate;
      break;
    }
  }

  final bool isPlanned =
      option?.intentId == kRecurringBloomIntentPlannedPlant;

  final DateTime today = DateTime(
    effectiveNow.year,
    effectiveNow.month,
    effectiveNow.day,
  );
  final DateTime? rawDate = draft.useFlexibleDate ? null : draft.selectedDate;
  DateTime? selectedDate;
  if (rawDate != null) {
    final pickedDay = DateTime(rawDate.year, rawDate.month, rawDate.day);
    final requiresFuture = option?.requiresFutureDate ?? false;
    final valid = requiresFuture
        ? pickedDay.isAfter(today)
        : !pickedDay.isAfter(today);
    if (valid) selectedDate = rawDate;
  }

  final bool preserveExistingAnchor =
      !isPlanned &&
      selectedDate == null &&
      previous?.ornamentalAnchorDate != null;
  final DateTime? effectiveAnchorDate = preserveExistingAnchor
      ? previous!.ornamentalAnchorDate
      : selectedDate;

  late final DateConfidence dateConfidence;
  if (preserveExistingAnchor) {
    dateConfidence =
        previous!.ornamentalAnchorDateConfidence ?? DateConfidence.unknown;
  } else if (selectedDate == null) {
    dateConfidence = DateConfidence.unknown;
  } else if (isPlanned) {
    dateConfidence = DateConfidence.exact;
  } else {
    dateConfidence = DateConfidence.estimated;
  }

  // Establecimiento → la fecha resuelve la etapa (pasa null); estado recurrente
  // → se guarda el estado elegido con su confianza.
  final bool usesDateEstimation = option?.usesDateEstimation ?? true;
  final String? passStageId = usesDateEstimation ? null : option?.stageId;
  final double? passConfidence = usesDateEstimation
      ? null
      : option?.stageConfidence;

  return contextResolver.resolve(
    deviceId: deviceId,
    cropCategoryId: categoryId,
    cropId: cropId,
    lifecycleStatus: isPlanned
        ? CropLifecycleStatus.planned
        : CropLifecycleStatus.planted,
    dateConfidence: dateConfidence,
    now: effectiveNow,
    previous: previous,
    varietyId: draft.varietyId,
    varietyAlias: draft.varietyAlias,
    selectedDate: effectiveAnchorDate,
    timezone: draft.timezone ?? previous?.timezone,
    cultivationScaleId: null,
    ornamentalStageId: passStageId,
    ornamentalAnchorDate: effectiveAnchorDate,
    ornamentalAnchorTypeId: option?.anchorTypeId,
    ornamentalStageConfidence: passConfidence,
  );
}

class BootstrapGate extends StatefulWidget {
  const BootstrapGate({super.key});

  @override
  State<BootstrapGate> createState() => _BootstrapGateState();
}

class _BootstrapGateState extends State<BootstrapGate> {
  static const WizardCropContextResolver _contextResolver =
      WizardCropContextResolver();

  late final SupabaseClient _client;
  late final ProfileRepository _repo;
  StreamSubscription<AuthState>? _authSub;

  /// Whether the first [onAuthStateChange] event has been received.
  /// Until this is true we show a loading screen so the user never sees a
  /// flash of the wrong screen (e.g. WelcomeScreen → Wizard).
  bool _initialAuthResolved = false;

  /// True when the session was established during THIS app session (the user
  /// just tapped Sign In / Sign Up). False when the session was restored
  /// from storage on app startup.
  bool _freshLogin = false;

  Session? _session;
  String? _lastUserId;
  Future<UserProfile?>? _profileFuture;

  @override
  void initState() {
    super.initState();

    _client = Supabase.instance.client;
    _repo = ProfileRepository(_client);

    // Do NOT read currentSession synchronously — Supabase may not have
    // restored the stored token yet. Instead, wait for the first
    // onAuthStateChange event which is guaranteed to fire with the
    // definitive initial auth state.
    _authSub = _client.auth.onAuthStateChange.listen((authState) {
      if (!mounted) return;

      final Session? newSession = authState.session;
      final String? newUserId = newSession?.user.id;

      // A signedIn event means the user just authenticated in this session.
      // An initialSession event means Supabase restored a cached session.
      final bool isLogin = authState.event == AuthChangeEvent.signedIn;

      setState(() {
        _initialAuthResolved = true;
        _session = newSession;

        if (isLogin) _freshLogin = true;
        if (newSession == null) _freshLogin = false;

        // Only re-fetch the profile when the user actually changes.
        // Token-refresh events for the same user should not trigger a
        // new network request (and a FutureBuilder loading flash).
        if (newUserId != _lastUserId) {
          _lastUserId = newUserId;
          _profileFuture = newSession == null ? null : _repo.getMyProfile();

          // Rebind the BioGStore so identity (devices, active device,
          // crop context, yield config) is scoped to the current user.
          // This is the main transition seam: the hybrid repo pulls
          // real devices from Supabase here, then last-write-wins
          // merges crop context / yield config.
          unawaited(_rebindStoreForUser(newUserId));
        }
      });
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Rebinds the [BioGStore] to the currently authenticated user id.
  /// On sign-out this clears user-scoped identity; on sign-in it
  /// pulls real devices from Supabase and last-write-wins merges
  /// crop context / yield config.
  ///
  /// Best-effort: any failure leaves local state as-is so the UI
  /// keeps working offline.
  Future<void> _rebindStoreForUser(String? userId) async {
    if (!mounted) return;
    final BioGStore store = BioGScope.of(context);

    if (userId == null || userId.isEmpty) {
      store.unbindUser();
      return;
    }

    await store.bindUser(userId: userId);
  }

  Future<void> _handleOnboardingCompleted(OnboardingDraft draft) async {
    try {
      await _saveOnboardingDraftLocally(draft);
      await _repo.markOnboardingCompleted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      rethrow;
    }

    if (!mounted) return;

    setState(() {
      _profileFuture = _repo.getMyProfile();
    });
  }

  Future<void> _saveOnboardingDraftLocally(OnboardingDraft draft) async {
    final BioGStore store = BioGScope.of(context);
    final device = store.activeDevice;
    if (device == null) return;

    final String? cropId = _normalizeCropId(draft.cropId);
    final String? stage = draft.stage?.trim();

    if (cropId == null || stage == null || stage.isEmpty) {
      return;
    }

    // Árboles/perennes: usan el modelo perenne (estado + etapa + anclaje) y
    // NUNCA van a descanso/fallow. Reposo (dormancy) y post-cosecha son etapas
    // activas del ciclo del árbol, no suelo en descanso.
    if (isTreeCrop(cropId: cropId, cropCategoryId: draft.cropCategory)) {
      await _saveOnboardingTreeContext(
        store: store,
        deviceId: device.id,
        draft: draft,
        cropId: cropId,
        stage: stage,
      );
      return;
    }

    // Ornamentales (cactus, suculenta…): plantar o registrar una planta que ya
    // existe. Nunca van a descanso del suelo (fallow) y nunca se infiere una
    // etapa solo por antigüedad.
    if (isEstablishmentMaintenanceCrop(
      cropId: cropId,
      cropCategoryId: draft.cropCategory,
    )) {
      final DeviceCropContext? previous = store.cropContextForDevice(device.id);
      final resolved = resolveOnboardingOrnamentalDraftContext(
        deviceId: device.id,
        draft: draft,
        cropId: cropId,
        stage: stage,
        previous: previous,
        contextResolver: _contextResolver,
      );
      await store.saveCropContext(resolved);
      return;
    }

    // Rosal (floración recurrente): guarda el estado VISUAL elegido; nunca va a
    // descanso del suelo y no infiere estados recurrentes por antigüedad.
    if (isRecurringBloomCrop(
      cropId: cropId,
      cropCategoryId: draft.cropCategory,
    )) {
      final DeviceCropContext? previous = store.cropContextForDevice(device.id);
      final resolved = resolveOnboardingRecurringBloomDraftContext(
        deviceId: device.id,
        draft: draft,
        cropId: cropId,
        stage: stage,
        previous: previous,
        contextResolver: _contextResolver,
      );
      await store.saveCropContext(resolved);
      return;
    }

    if (stage == 'fallow') {
      await store.setSeedSkipForDevice(device.id, cropKey: cropId);
      return;
    }

    final DeviceCropContext? previous = store.cropContextForDevice(device.id);
    final bool isPlanned = stage == 'planned';
    final DateTime now = DateTime.now();

    final DateTime? selectedDate = isPlanned
        ? (draft.useFlexibleDate ? null : draft.selectedDate)
        : (draft.selectedDate ?? now);

    final DeviceCropContext resolvedContext = _contextResolver.resolve(
      deviceId: device.id,
      cropCategoryId:
          draft.cropCategory ??
          previous?.cropCategoryId ??
          CropCatalog.grainCategoryId,
      cropId: cropId,
      lifecycleStatus: isPlanned
          ? CropLifecycleStatus.planned
          : CropLifecycleStatus.planted,
      dateConfidence: isPlanned
          ? (draft.useFlexibleDate
                ? DateConfidence.unknown
                : DateConfidence.exact)
          : (draft.useFlexibleDate
                ? DateConfidence.estimated
                : DateConfidence.exact),
      now: now,
      previous: previous,
      brandId: draft.brandId,
      varietyId: draft.varietyId,
      varietyAlias: draft.varietyAlias,
      selectedDate: selectedDate,
      timezone: draft.timezone ?? previous?.timezone,
      cultivationScaleId: draft.cultivationScale,
    );

    await store.saveCropContext(resolvedContext);
  }

  /// Persiste el contexto de un árbol/perenne configurado en el onboarding.
  ///
  /// Usa el modelo canónico compartido con account/configure vía
  /// [resolveOnboardingTreeSelection] (Fase 4): estado de producción visible +
  /// etapa/señal → (perennialStateId + phenologyStageId + anclaje). La primera
  /// floración de un árbol no productivo entra a producción de temporada y
  /// "solo creciendo" deriva el estado de la edad de plantación. El árbol nunca
  /// se manda a fallow: reposo y post-cosecha siguen siendo etapas activas. La
  /// variedad de onboarding cae de forma segura al perfil general (AP-SKIP) si
  /// no coincide con un perfil del catálogo; el usuario puede precisarla después.
  Future<void> _saveOnboardingTreeContext({
    required BioGStore store,
    required String deviceId,
    required OnboardingDraft draft,
    required String cropId,
    required String stage,
  }) async {
    final DeviceCropContext? previous = store.cropContextForDevice(deviceId);
    final resolved = resolveOnboardingTreeDraftContext(
      deviceId: deviceId,
      draft: draft,
      cropId: cropId,
      stage: stage,
      previous: previous,
      contextResolver: _contextResolver,
    );
    await store.saveCropContext(resolved);
  }

  String? _normalizeCropId(String? value) {
    return CropCatalog.canonicalCropKeyOrNull(value);
  }

  void _handleOnboardingExited() {
    unawaited(_repo.signOut());
  }

  /// Sign out a restored-from-storage session whose onboarding is incomplete
  /// (or whose profile fetch failed). Deferred to a post-frame callback so
  /// it never calls setState during build.
  void _signOutStaleSession() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_repo.signOut());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode && _kDebugScreenGallery) {
      return const _DebugScreenGallery();
    }

    if (kDebugMode && _kDebugForceSignInPreview) {
      return const AuthScreen(initialMode: AuthMode.signIn);
    }

    // Wait for the initial auth state before deciding which screen to show.
    // This prevents a flash of WelcomeScreen → Wizard when a stored session
    // is being restored.
    if (!_initialAuthResolved) {
      return const _BootstrapLoading();
    }

    if (_session == null) {
      return const WelcomeScreen();
    }

    final profileFuture = _profileFuture;
    if (profileFuture == null) {
      return const _BootstrapLoading();
    }

    return FutureBuilder<UserProfile?>(
      future: profileFuture,
      builder: (context, profileSnapshot) {
        if (profileSnapshot.connectionState == ConnectionState.waiting) {
          return const _BootstrapLoading();
        }

        if (profileSnapshot.hasError) {
          // Session is likely expired or invalid — sign out so the user
          // returns to WelcomeScreen on the next rebuild.
          _signOutStaleSession();
          return const _BootstrapLoading();
        }

        final profile = profileSnapshot.data;

        if (profile == null || !profile.onboardingCompleted) {
          // If this is a restored session from a previous app launch (not a
          // fresh login), sign out so the user starts from WelcomeScreen.
          // They'll need to sign in / sign up again to reach the wizard.
          if (!_freshLogin) {
            _signOutStaleSession();
            return const _BootstrapLoading();
          }

          return OnboardingWizardScreen(
            onCompleted: _handleOnboardingCompleted,
            onExited: _handleOnboardingExited,
          );
        }

        return const AppShell();
      },
    );
  }
}

class _BootstrapLoading extends StatelessWidget {
  const _BootstrapLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _DebugScreenGallery extends StatelessWidget {
  const _DebugScreenGallery();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F9),
      appBar: AppBar(
        title: const Text('Screen Gallery'),
        centerTitle: true,
        backgroundColor: const Color(0xFF0E6F5E),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          const _GallerySection(title: 'Auth'),
          _GalleryTile(
            icon: Icons.waving_hand_rounded,
            label: 'Welcome',
            onTap: () => _push(context, const WelcomeScreen()),
          ),
          _GalleryTile(
            icon: Icons.login_rounded,
            label: 'Sign In',
            onTap: () =>
                _push(context, const AuthScreen(initialMode: AuthMode.signIn)),
          ),
          _GalleryTile(
            icon: Icons.person_add_rounded,
            label: 'Sign Up',
            onTap: () =>
                _push(context, const AuthScreen(initialMode: AuthMode.signUp)),
          ),
          const SizedBox(height: 16),
          const _GallerySection(title: 'Onboarding'),
          _GalleryTile(
            icon: Icons.rocket_launch_rounded,
            label: 'Onboarding Wizard',
            onTap: () => _push(
              context,
              OnboardingWizardScreen(
                onCompleted: (_) async => Navigator.of(context).pop(),
                onExited: () => Navigator.of(context).pop(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _GallerySection(title: 'App'),
          _GalleryTile(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            onTap: () => _push(context, const AppShell(initialIndex: 4)),
          ),
          _GalleryTile(
            icon: Icons.show_chart_rounded,
            label: 'History',
            onTap: () => _push(context, const AppShell(initialIndex: 0)),
          ),
          _GalleryTile(
            icon: Icons.person_rounded,
            label: 'Account',
            onTap: () => _push(context, const AppShell(initialIndex: 1)),
          ),
          _GalleryTile(
            icon: Icons.grass_rounded,
            label: 'Seeds',
            onTap: () => _push(context, const AppShell(initialIndex: 2)),
          ),
          _GalleryTile(
            icon: Icons.cloud_rounded,
            label: 'Environment',
            onTap: () => _push(context, const AppShell(initialIndex: 3)),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(BioGPageRoute<void>(builder: (_) => screen));
  }
}

class _GallerySection extends StatelessWidget {
  final String title;
  const _GallerySection({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B777E),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _GalleryTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF5F1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF0E6F5E), size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF425058),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9EA8AE),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        onTap: onTap,
      ),
    );
  }
}
