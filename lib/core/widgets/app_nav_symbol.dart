import 'package:flutter/material.dart';

enum AppNavSymbolKind {
  dashboard,
  search,
  calendar,
  recordings,
  accounts,
  available,
  busy,
  secure,
  play,
  link,
}

class AppNavSymbol extends StatelessWidget {
  const AppNavSymbol({
    super.key,
    required this.kind,
    required this.color,
    this.size = 22,
  });

  final AppNavSymbolKind kind;
  final Color color;
  final double size;

  String get _asset => switch (kind) {
        AppNavSymbolKind.dashboard => 'assets/icons/nav_dashboard.png',
        AppNavSymbolKind.search => 'assets/icons/nav_search.png',
        AppNavSymbolKind.calendar => 'assets/icons/nav_calendar.png',
        AppNavSymbolKind.recordings => 'assets/icons/nav_recordings.png',
        AppNavSymbolKind.accounts => 'assets/icons/nav_accounts.png',
        AppNavSymbolKind.available => 'assets/icons/status_available.png',
        AppNavSymbolKind.busy => 'assets/icons/status_busy.png',
        AppNavSymbolKind.secure => 'assets/icons/status_secure.png',
        AppNavSymbolKind.play => 'assets/icons/action_play.png',
        AppNavSymbolKind.link => 'assets/icons/action_link.png',
      };

  @override
  Widget build(BuildContext context) => Image.asset(
        _asset,
        width: size,
        height: size,
        color: color,
        filterQuality: FilterQuality.high,
        excludeFromSemantics: true,
      );
}
