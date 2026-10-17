import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/image_decode_size.dart';
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
    final compact = MediaQuery.textScalerOf(context).scale(1) > 1.4;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateTimeUtil.getGreeting()}, $userName',
          maxLines: compact ? 1 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.textMain,
            fontSize: compact ? 19 : 25,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
        ),
        SizedBox(height: compact ? 2 : 5),
        Text(
          DateTimeUtil.formatDateOnlyWib(DateTime.now().toIso8601String()),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: compact ? 10 : 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 218),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/meeting_console_hero.png',
                    cacheWidth: imageCacheWidth(
                      context,
                      MediaQuery.sizeOf(context).width,
                    ),
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
                          AppColors.primaryDark.withValues(alpha: 0.97),
                          AppColors.primaryDark.withValues(alpha: 0.84),
                          AppColors.primaryDark.withValues(alpha: 0.18),
                        ],
                        stops: const [0, 0.54, 1],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, compact ? 14 : 19, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!compact) ...[
                        const Icon(
                          PhosphorIconsRegular.videoCamera,
                          size: 22,
                          color: Color(0xFFD9F0FA),
                        ),
                        const SizedBox(height: 15),
                      ],
                      Text(
                        'Rapat berikutnya\ndimulai di sini.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: compact ? 17 : 22,
                          height: 1.14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.7,
                        ),
                      ),
                      if (!compact) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Temukan akun yang siap pada waktu pilihan Anda.',
                          style: TextStyle(
                            color: Color(0xFFE0EAF3),
                            fontSize: 12,
                            height: 1.35,
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 10 : 16),
                      FilledButton.icon(
                        onPressed: onSearch,
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primaryDark,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                              fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
