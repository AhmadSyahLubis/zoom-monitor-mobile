import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../config/app_routes.dart';
import '../theme/app_colors.dart';

class AppGlassNavBar extends StatelessWidget {
  const AppGlassNavBar({super.key, required this.currentIndex});

  final int currentIndex;

  static const _items =
      <({IconData icon, IconData activeIcon, String label, String route})>[
    (
      icon: PhosphorIconsRegular.house,
      activeIcon: PhosphorIconsFill.house,
      label: 'Beranda',
      route: AppRoutes.dashboard
    ),
    (
      icon: PhosphorIconsRegular.magnifyingGlass,
      activeIcon: PhosphorIconsBold.magnifyingGlass,
      label: 'Cari',
      route: AppRoutes.search
    ),
    (
      icon: PhosphorIconsRegular.calendarDots,
      activeIcon: PhosphorIconsFill.calendarDots,
      label: 'Jadwal',
      route: AppRoutes.schedules
    ),
    (
      icon: PhosphorIconsRegular.cloudArrowDown,
      activeIcon: PhosphorIconsFill.cloudArrowDown,
      label: 'Rekaman',
      route: AppRoutes.recordings
    ),
    (
      icon: PhosphorIconsRegular.usersThree,
      activeIcon: PhosphorIconsFill.usersThree,
      label: 'Akun',
      route: AppRoutes.accounts
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAF7).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: AppColors.borderLight, width: 1),
                ),
                child: Row(
                  children: [
                    for (var index = 0; index < _items.length; index++)
                      Expanded(
                        child: _NavDestination(
                          icon: _items[index].icon,
                          activeIcon: _items[index].activeIcon,
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
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryDark : AppColors.textMuted;
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
              color: selected ? AppColors.primaryLight : Colors.transparent,
              borderRadius: BorderRadius.circular(21),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  selected ? activeIcon : icon,
                  size: 21,
                  color: color,
                ),
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
