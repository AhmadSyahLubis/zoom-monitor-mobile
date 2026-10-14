import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../data/models/availability_result.dart';

class ConflictBanner extends StatelessWidget {
  final MeetingSummary conflict;

  const ConflictBanner({super.key, required this.conflict});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusMeetingBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusMeeting.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.statusMeeting),
              SizedBox(width: 6),
              Text(
                'Benturan Jadwal Terdeteksi:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusMeeting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Topik: ${conflict.topic}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMain, fontWeight: FontWeight.w500),
          ),
          Text(
            '• Jam: ${DateTimeUtil.formatTimeRangeWib(conflict.startTime, conflict.endTime)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
