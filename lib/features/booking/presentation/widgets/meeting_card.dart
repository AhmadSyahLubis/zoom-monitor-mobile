import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/invite_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/models/schedule_item.dart';

enum MeetingCardType { live, upcoming, past }

class MeetingCard extends StatelessWidget {
  final ScheduleItem meeting;
  final MeetingCardType type;
  final VoidCallback? onEndMeeting;
  final VoidCallback? onEditMeeting;
  final VoidCallback? onDeleteMeeting;

  const MeetingCard({
    super.key,
    required this.meeting,
    required this.type,
    this.onEndMeeting,
    this.onEditMeeting,
    this.onDeleteMeeting,
  });

  @override
  Widget build(BuildContext context) {
    final startWib = DateTime.tryParse(meeting.startTime)
        ?.toUtc()
        .add(const Duration(hours: 7));
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MEI',
      'JUN',
      'JUL',
      'AGU',
      'SEP',
      'OKT',
      'NOV',
      'DES',
    ];
    return ContentSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildTypeBadge(),
                if (meeting.isRecurring)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(PhosphorIconsRegular.repeat,
                            size: 12, color: AppColors.primaryDark),
                        SizedBox(width: 4),
                        Text('Berulang',
                            style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Column(
                    children: [
                      Text(
                        startWib?.day.toString() ?? '--',
                        style: AppType.metric.copyWith(fontSize: 22),
                      ),
                      Text(
                        startWib == null ? 'WIB' : months[startWib.month - 1],
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting.topic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.cardTitle.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meeting.accountName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),

            // Waktu WIB & Durasi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.clock,
                      size: 16, color: AppColors.primary),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${DateTimeUtil.formatTimeOnlyWib(meeting.startTime)} · ${meeting.duration} mnt',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip('ID: ${meeting.meetingId}'),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              children: [
                // Tombol Buka Zoom jika joinUrl tersedia
                if (meeting.joinUrl.isNotEmpty &&
                    type != MeetingCardType.past) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type == MeetingCardType.live
                            ? AppColors.statusMeeting
                            : AppColors.primary,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(meeting.joinUrl);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(PhosphorIconsFill.videoCamera,
                          size: 15, color: Colors.white),
                      label: Text(
                        type == MeetingCardType.live
                            ? 'Gabung Live'
                            : 'Gabung Zoom',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Tombol Salin Undangan
                IconButton.outlined(
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: const EdgeInsets.all(6),
                  tooltip: 'Salin Undangan',
                  icon: const Icon(PhosphorIconsRegular.copy,
                      size: 16, color: AppColors.textMain),
                  onPressed: () {
                    final invite = InviteFormatter.formatInvite(
                      topic: meeting.topic,
                      startTimeWib:
                          DateTimeUtil.formatTimeOnlyWib(meeting.startTime),
                      endTimeWib:
                          DateTimeUtil.formatTimeOnlyWib(meeting.endTime),
                      accountName: meeting.accountName,
                      meetingId: meeting.meetingId.toString(),
                      passcode: meeting.password,
                      hostKey: meeting.hostKey,
                      joinUrl: meeting.joinUrl,
                    );
                    Clipboard.setData(ClipboardData(text: invite));
                    UiFeedback.showSuccess(
                        context, 'Undangan berhasil disalin ke clipboard');
                  },
                ),

                // Tombol Akhiri Rapat jika Live
                if (type == MeetingCardType.live && onEndMeeting != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.statusMeetingBg),
                    tooltip: 'Paksa Selesai Rapat',
                    icon: const Icon(PhosphorIconsRegular.phoneDisconnect,
                        size: 16, color: AppColors.statusMeeting),
                    onPressed: onEndMeeting,
                  ),
                ],

                // Tombol Edit Rapat jika Upcoming atau Live
                if (onEditMeeting != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.primaryLight),
                    tooltip: 'Edit Jadwal Rapat',
                    icon: const Icon(PhosphorIconsRegular.pencilSimple,
                        size: 16, color: AppColors.primary),
                    onPressed: onEditMeeting,
                  ),
                ],

                // Tombol Hapus Rapat jika Upcoming
                if (type == MeetingCardType.upcoming &&
                    onDeleteMeeting != null) ...[
                  const SizedBox(width: 6),
                  IconButton(
                    constraints:
                        const BoxConstraints(minWidth: 44, minHeight: 44),
                    padding: const EdgeInsets.all(6),
                    style: IconButton.styleFrom(
                        backgroundColor: AppColors.statusMeetingBg),
                    tooltip: 'Batalkan Rapat',
                    icon: const Icon(PhosphorIconsRegular.trash,
                        size: 16, color: AppColors.statusMeeting),
                    onPressed: onDeleteMeeting,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    switch (type) {
      case MeetingCardType.live:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.statusMeetingBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.statusMeeting.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(PhosphorIconsFill.record,
                  size: 10, color: AppColors.statusMeeting),
              SizedBox(width: 4),
              Text('LIVE SEKARANG',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.statusMeeting)),
            ],
          ),
        );
      case MeetingCardType.upcoming:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.statusScheduledBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: AppColors.statusScheduled.withValues(alpha: 0.3)),
          ),
          child: const Text('MENDATANG',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.statusScheduled)),
        );
      case MeetingCardType.past:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.statusErrorBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('SELESAI',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMuted)),
        );
    }
  }

  Widget _buildInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMain,
        ),
      ),
    );
  }
}
