import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';

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
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            const Positioned.fill(
              child: Image(
                image: ResizeImage(
                  AssetImage('assets/images/meeting_room_hero.png'),
                  width: 600,
                ),
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF0183040),
                      Color(0xD9183040),
                      Color(0x65183040)
                    ],
                    stops: [0, 0.62, 1],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateTimeUtil.formatDateOnlyWib(
                        DateTime.now().toIso8601String()),
                    style: const TextStyle(
                      color: Color(0xFFE4EEEC),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${DateTimeUtil.getGreeting()}, $userName',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      height: 1.18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cari akun tersedia untuk rapat berikutnya.',
                    style: TextStyle(color: Color(0xFFE4EEEC), fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: onSearch,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFF5F8F5),
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                        size: 18),
                    label: const Text(
                      'Cari waktu rapat',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
