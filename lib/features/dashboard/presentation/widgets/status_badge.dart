import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color textColor;
    Color bgColor;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'available':
        textColor = AppColors.statusAvailable;
        bgColor = AppColors.statusAvailableBg;
        label = 'Tersedia';
        icon = PhosphorIconsFill.checkCircle;
        break;
      case 'meeting':
      case 'in_meeting':
      case 'busy':
        textColor = AppColors.statusMeeting;
        bgColor = AppColors.statusMeetingBg;
        label = 'Sedang Rapat';
        icon = PhosphorIconsFill.videoCamera;
        break;
      case 'scheduled':
        textColor = AppColors.statusScheduled;
        bgColor = AppColors.statusScheduledBg;
        label = 'Terjadwal';
        icon = PhosphorIconsRegular.clock;
        break;
      default:
        textColor = AppColors.statusError;
        bgColor = AppColors.statusErrorBg;
        label = 'Offline / Error';
        icon = PhosphorIconsRegular.warningCircle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
