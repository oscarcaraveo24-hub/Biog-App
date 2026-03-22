import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'account_screen.dart';
import 'seeds_screen.dart';
import 'package:bio_g/screens/environment/environment_screen.dart';

const int? kDevForceIndex = null;

class AppShell extends StatefulWidget {
  final int initialIndex;

  const AppShell({super.key, this.initialIndex = 4});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;

    if (kDebugMode && kDevForceIndex != null) {
      currentIndex = kDevForceIndex!;
    }
  }

  @override
  void reassemble() {
    super.reassemble();

    if (kDebugMode && kDevForceIndex != null) {
      setState(() => currentIndex = kDevForceIndex!);
    }
  }

  void _onNavTap(int i) {
    if (i == currentIndex) return;
    setState(() => currentIndex = i);
  }

  int get _effectiveIndex {
    if (kDebugMode && kDevForceIndex != null) return kDevForceIndex!;
    return currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    final index = _effectiveIndex;

    return IndexedStack(
      index: index,
      children: [
        HistoryScreen(
          key: const PageStorageKey('history'),
          currentIndex: index,
          onNavTap: _onNavTap,
        ),
        AccountScreen(
          key: const PageStorageKey('account'),
          currentIndex: index,
          onNavTap: _onNavTap,
        ),
        SeedsScreen(
          key: const PageStorageKey('seeds'),
          currentIndex: index,
          onNavTap: _onNavTap,
        ),
        EnvironmentScreen(
          key: const PageStorageKey('environment'),
          currentIndex: index,
          onNavTap: _onNavTap,
        ),
        DashboardScreen(
          key: const PageStorageKey('dashboard'),
          currentIndex: index,
          onNavTap: _onNavTap,
        ),
      ],
    );
  }
}
