import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_routes.dart';
import '../theme/app_colors.dart';
import 'app_nav_symbol.dart';

class AppGlassNavBar extends StatelessWidget {
  const AppGlassNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items = <({AppNavSymbolKind icon, String label, String route})>[
    (
      icon: AppNavSymbolKind.dashboard,
      label: 'Beranda',
      route: AppRoutes.dashboard
    ),
    (icon: AppNavSymbolKind.search, label: 'Cari', route: AppRoutes.search),
    (
      icon: AppNavSymbolKind.calendar,
      label: 'Jadwal',
      route: AppRoutes.schedules
    ),
    (
      icon: AppNavSymbolKind.recordings,
      label: 'Rekaman',
      route: AppRoutes.recordings
    ),
    (icon: AppNavSymbolKind.accounts, label: 'Akun', route: AppRoutes.accounts),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 68,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.11),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.9),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < _items.length; index++)
                      Expanded(
                        child: _NavDestination(
                          icon: _items[index].icon,
                          label: _items[index].label,
                          selected: currentIndex == index,
                          onTap: () {
                            if (currentIndex != index) {
                              context.go(_items[index].route);
                            }
                          },
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

class _NavDestination extends StatelessWidget {
  const _NavDestination({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final AppNavSymbolKind icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(21),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: selected ? AppColors.primaryDark : Colors.transparent,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppNavSymbol(kind: icon, color: color),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
