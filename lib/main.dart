import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:bio_g/bootstrap_gate.dart';
import 'package:bio_g/core/config/supabase_config.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/services/biog/hybrid_biog_repository.dart';
import 'package:bio_g/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_kBioGOverlays);

  // ---------------------------------------------------------------------------
  // Runtime wiring — hybrid architecture
  // ---------------------------------------------------------------------------
  //
  // Identity (devices, memberships, active device, crop context,
  // yield config) now lives in a REAL layer backed by Supabase with an
  // offline-first local cache.
  //
  // The sensor simulator is the ONLY temporary fake component in the
  // runtime and is scoped to live telemetry / short history / alerts
  // for whichever devices identity owns. When real hardware arrives,
  // the simulator is the single replacement point.
  //
  // BootstrapGate is responsible for calling `store.bindUser(...)` on
  // every auth-state change so that device identity and crop context
  // stay scoped to the authenticated user.
  final repo = HybridBioGRepository();
  final store = BioGStore(repo);

  // Load local-only state first so the UI has something to render
  // immediately. Remote hydration happens in `BioGStore.bindUser` once
  // an authenticated session is available.
  await store.init();

  runApp(BioGScope(store: store, child: const BioGApp()));
}

const _kBioGOverlays = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.transparent,
  systemNavigationBarDividerColor: Colors.transparent,
  systemNavigationBarIconBrightness: Brightness.light,
  systemNavigationBarContrastEnforced: false,
);

class BioGApp extends StatelessWidget {
  const BioGApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BIO-G',
      theme: AppTheme.light(),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _kBioGOverlays,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const BootstrapGate(),
    );
  }
}
