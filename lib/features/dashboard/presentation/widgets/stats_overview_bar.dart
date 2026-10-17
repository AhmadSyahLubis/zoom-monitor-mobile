import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/widgets/app_nav_symbol.dart';

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
      padding: const EdgeInsets.fromLTRB(18, 17, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Expanded(
                child: Text(
                  'Akun terhubung',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text('$totalAccounts', style: AppType.metric),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: SizedBox(
              height: 5,
              child: Row(
                children: [
                  if (availableAccounts > 0)
                    Expanded(
                      flex: availableAccounts,
                      child: const ColoredBox(color: AppColors.statusAvailable),
                    ),
                  if (busyAccounts > 0)
                    Expanded(
                      flex: busyAccounts,
                      child: const ColoredBox(color: AppColors.statusMeeting),
                    ),
                  if (totalAccounts - availableAccounts - busyAccounts > 0)
                    Expanded(
                      flex: totalAccounts - availableAccounts - busyAccounts,
                      child: const ColoredBox(color: AppColors.borderLight),
                    ),
                  if (totalAccounts == 0)
                    const Expanded(
                      child: ColoredBox(color: AppColors.borderLight),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  value: availableAccounts,
                  label: 'Siap dipakai',
                  kind: AppNavSymbolKind.available,
                  color: AppColors.statusAvailable,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _Metric(
                  value: busyAccounts,
                  label: 'Sedang rapat',
                  kind: AppNavSymbolKind.busy,
                  color: AppColors.statusMeeting,
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
    required this.kind,
    required this.color,
  });

  final int value;
  final String label;
  final AppNavSymbolKind kind;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          AppNavSymbol(kind: kind, color: color, size: 18),
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
