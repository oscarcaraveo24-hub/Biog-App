import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bio_g/bootstrap_gate.dart';

import 'package:bio_g/core/config/supabase_config.dart';
import 'package:bio_g/services/biog/biog_store.dart';
import 'package:bio_g/services/biog/fake_biog_repository.dart';
import 'package:bio_g/services/profile/profile_local_service.dart';
import 'package:bio_g/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(_kBioGOverlays);

  final repo = FakeBioGRepository();
  final store = BioGStore(repo);

  // Carga primero el contexto persistido por dispositivo.
  await store.init();

  // Ya con el store hidratado, conectamos el resolver legacy
  // que sigue usando el repo fake.
  repo.attachSeedResolver((deviceId) => store.seedInstallForDevice(deviceId));

  // Respeta el estado de sincronización persistido.
  final prefs = await SharedPreferences.getInstance();
  final syncActive = prefs.getBool(ProfileLocalService.kSyncActiveKey) ?? true;

  // Ahora sí arrancamos el motor fake.
  repo.start();
  if (!syncActive) repo.pause();

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
