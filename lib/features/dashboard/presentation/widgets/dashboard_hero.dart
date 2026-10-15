import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/widgets/app_nav_symbol.dart';

class DashboardHero extends StatelessWidget {
  const DashboardHero({
    super.key,
    required this.userName,
    required this.onSearch,
  });

  final String userName;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 252),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/meeting_console_hero.png',
                fit: BoxFit.cover,
                alignment: Alignment.centerRight,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      AppColors.primaryDark.withValues(alpha: 0.92),
                      AppColors.primaryDark.withValues(alpha: 0.66),
                      AppColors.primaryDark.withValues(alpha: 0.28),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 21, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        PhosphorIconsRegular.calendarBlank,
                        size: 15,
                        color: Color(0xFFDDE7F6),
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          DateTimeUtil.formatDateOnlyWib(
                            DateTime.now().toIso8601String(),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFDDE7F6),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${DateTimeUtil.getGreeting()}, $userName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.white,
                      fontSize: 25,
                      height: 1.12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Temukan akun yang siap untuk rapat berikutnya.',
                    style: TextStyle(
                      color: Color(0xFFDDE7F6),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 21),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onSearch,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF5F8FE),
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size.fromHeight(48),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: const AppNavSymbol(
                        kind: AppNavSymbolKind.search,
                        color: AppColors.primaryDark,
                        size: 18,
                      ),
                      label: const Text(
                        'Cari waktu rapat',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
