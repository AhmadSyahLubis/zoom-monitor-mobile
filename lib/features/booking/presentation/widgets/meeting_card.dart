import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
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
    return ContentSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: Type Indicator + Account Name
            Row(
              children: [
                _buildTypeBadge(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meeting.accountName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
            const SizedBox(height: 10),

            // Topik Rapat
            Text(
              meeting.topic,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),

            // Waktu WIB & Durasi
            Row(
              children: [
                const Icon(PhosphorIconsRegular.clock,
                    size: 15, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${DateTimeUtil.formatWib(meeting.startTime)} (${meeting.duration} mnt)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Meeting ID, Passcode & Host Key chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildInfoChip('ID: ${meeting.meetingId}'),
                if (meeting.password.isNotEmpty)
                  _buildInfoChip('Pass: ${meeting.password}'),
                if (meeting.hostKey != null && meeting.hostKey!.isNotEmpty)
                  _buildInfoChip('Host Key: ${meeting.hostKey}',
                      isHighlight: true),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        visualDensity: VisualDensity.compact,
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
                  visualDensity: VisualDensity.compact,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
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
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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
                    visualDensity: VisualDensity.compact,
                    constraints:
                        const BoxConstraints(minWidth: 36, minHeight: 36),
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

  Widget _buildInfoChip(String text, {bool isHighlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isHighlight ? AppColors.primaryLight : AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isHighlight
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.borderLight),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
          color: isHighlight ? AppColors.primaryDark : AppColors.textMain,
        ),
      ),
    );
  }
}
