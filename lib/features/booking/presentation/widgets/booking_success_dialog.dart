import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/invite_formatter.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/models/booking_request.dart';

class BookingSuccessDialog extends StatelessWidget {
  final BookMeetingResponse meeting;

  const BookingSuccessDialog({super.key, required this.meeting});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Success Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 36),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Rapat Berhasil Dijadwalkan!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              meeting.topic,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),

            // Card Detail Kredensial Rapat
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.scaffoldLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildRow('Meeting ID', meeting.meetingId.toString(), isHighlight: true),
                  const Divider(height: 16),
                  _buildRow('Passcode', meeting.password),
                  const Divider(height: 16),
                  _buildRow(
                    'Host Key',
                    meeting.hostKey?.isNotEmpty == true ? meeting.hostKey! : 'Tersedia di Zoom',
                    isBadge: true,
                  ),
                  const Divider(height: 16),
                  _buildRow('Waktu', DateTimeUtil.formatWib(meeting.startTime)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Action Buttons
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                final inviteText = InviteFormatter.formatInvite(
                  topic: meeting.topic,
                  startTimeWib: DateTimeUtil.formatTimeOnlyWib(meeting.startTime),
                  endTimeWib: DateTimeUtil.formatTimeOnlyWib(
                    DateTimeUtil.parseToWib(meeting.startTime)
                        .add(Duration(minutes: meeting.duration))
                        .toIso8601String(),
                  ),
                  accountName: meeting.accountName,
                  meetingId: meeting.meetingId.toString(),
                  passcode: meeting.password,
                  hostKey: meeting.hostKey,
                  joinUrl: meeting.joinUrl,
                );

                Clipboard.setData(ClipboardData(text: inviteText));
                UiFeedback.showSuccess(context, 'Undangan rapat berhasil disalin ke clipboard');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('📋 Salin Undangan Rapat'),
            ),
            const SizedBox(height: 10),

            if (meeting.joinUrl.isNotEmpty) ...[
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () async {
                  final uri = Uri.parse(meeting.joinUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: const Text('🔗 Buka di Aplikasi Zoom'),
              ),
              const SizedBox(height: 10),
            ],

            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Selesai', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isHighlight = false, bool isBadge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
        if (isBadge)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          )
        else
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
      ],
    );
  }
}
