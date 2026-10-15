import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/theme/glass_surface.dart';

class StatsOverviewBar extends StatelessWidget {
  final int totalAccounts;
  final int availableAccounts;
  final int busyAccounts;

  const StatsOverviewBar({
    super.key,
    required this.totalAccounts,
    required this.availableAccounts,
    required this.busyAccounts,
  });

  @override
  Widget build(BuildContext context) {
    return ContentSurface(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RINGKASAN AKUN',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$totalAccounts akun',
            style: AppType.metric,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: availableAccounts,
                  label: 'Siap dipakai',
                  color: AppColors.statusAvailable,
                  background: AppColors.statusAvailableBg,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Metric(
                  value: busyAccounts,
                  label: 'Sedang rapat',
                  color: AppColors.statusMeeting,
                  background: AppColors.statusMeetingBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    required this.color,
    required this.background,
  });

  final int value;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textMain, fontSize: 12),
            ),
          ),
          Text(
            '$value',
            style: AppType.cardTitle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
