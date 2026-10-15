import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/widgets/app_nav_symbol.dart';
import '../../data/models/dashboard_account.dart';
import 'status_badge.dart';

class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account, this.onTap});

  final DashboardAccount account;
  final VoidCallback? onTap;

  Color get _statusColor {
    switch (account.status) {
      case 'available':
        return AppColors.statusAvailable;
      case 'meeting':
      case 'in_meeting':
      case 'busy':
        return AppColors.statusMeeting;
      case 'scheduled':
        return AppColors.statusScheduled;
      default:
        return AppColors.statusError;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ContentSurface(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: AppNavSymbol(
                          kind: AppNavSymbolKind.accounts,
                          color: AppColors.primaryDark,
                          size: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.accountName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppType.cardTitle,
                          ),
                          if (account.email?.isNotEmpty == true) ...[
                            const SizedBox(height: 3),
                            Text(
                              account.email!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 6),
                      const Icon(PhosphorIconsRegular.arrowRight,
                          size: 18, color: AppColors.textMuted),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: account.status),
                    if (account.planType.isNotEmpty)
                      Text(
                        account.planType,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (account.meetingCapacity > 0)
                      Text(
                        '${account.meetingCapacity} peserta',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                if (account.currentTopic?.isNotEmpty == true) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F8FC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border(
                        left: BorderSide(color: _statusColor, width: 3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'TOPIK RAPAT',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          account.currentTopic!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMain,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 11),
                Row(
                  children: [
                    const Icon(PhosphorIconsRegular.clock,
                        size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Diperbarui ${DateTimeUtil.formatTimeOnlyWib(account.lastUpdated.toIso8601String())}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                if (onTap != null) ...[
                  const SizedBox(height: 7),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Lihat jadwal',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
