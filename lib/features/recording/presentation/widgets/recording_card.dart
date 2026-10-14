import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/models/recording_item.dart';

class RecordingCard extends StatelessWidget {
  final RecordingItem recording;

  const RecordingCard({super.key, required this.recording});

  String get _targetPlayUrl {
    if (recording.shareUrl.isNotEmpty) return recording.shareUrl;
    if (recording.recordingFiles.isNotEmpty &&
        recording.recordingFiles.first.playUrl.isNotEmpty) {
      return recording.recordingFiles.first.playUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return ContentSurface(
      padding: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Akun & File Count
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(PhosphorIconsFill.cloudCheck,
                          color: AppColors.primary, size: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      recording.accountName,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    '${recording.recordingFiles.length} File',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Topik Rekaman
            Text(
              recording.topic,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 6),

            // Waktu Rapat
            Row(
              children: [
                const Icon(PhosphorIconsRegular.clock,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  DateTimeUtil.formatWib(recording.startTime),
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Specs: Durasi, Ukuran File Total, Host
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildChip(
                    PhosphorIconsRegular.timer, '${recording.duration} Menit'),
                _buildChip(PhosphorIconsRegular.database,
                    recording.formattedTotalSize),
                if (recording.hostName.isNotEmpty)
                  _buildChip(PhosphorIconsRegular.user, recording.hostName),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Tombol Putar & Bagikan
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final url = _targetPlayUrl;
                      if (url.isNotEmpty) {
                        final uri = Uri.parse(url);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        } else {
                          if (context.mounted) {
                            UiFeedback.showError(
                                context, 'Tidak dapat membuka tautan rekaman');
                          }
                        }
                      } else {
                        UiFeedback.showError(
                            context, 'Link pemutaran rekaman tidak tersedia');
                      }
                    },
                    icon: const Icon(PhosphorIconsFill.playCircle,
                        size: 18, color: Colors.white),
                    label: const Text(
                      'Putar Rekaman',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.outlined(
                  tooltip: 'Bagikan Link',
                  icon: const Icon(PhosphorIconsRegular.shareNetwork,
                      size: 18, color: AppColors.primary),
                  onPressed: () {
                    final url = _targetPlayUrl;
                    if (url.isNotEmpty) {
                      Share.share(
                          'Rekaman Zoom: ${recording.topic}\nTautan: $url');
                    } else {
                      UiFeedback.showError(
                          context, 'Tautan tidak tersedia untuk dibagikan');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.scaffoldLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(text,
              style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMain,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
