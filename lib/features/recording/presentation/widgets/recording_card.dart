import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_nav_symbol.dart';
import '../../data/models/recording_item.dart';

class RecordingCard extends StatelessWidget {
  const RecordingCard({super.key, required this.recording});

  final RecordingItem recording;

  String get _targetPlayUrl {
    if (recording.shareUrl.isNotEmpty) return recording.shareUrl;
    if (recording.recordingFiles.isNotEmpty &&
        recording.recordingFiles.first.playUrl.isNotEmpty) {
      return recording.recordingFiles.first.playUrl;
    }
    return '';
  }

  Future<void> _openRecording(BuildContext context) async {
    final url = _targetPlayUrl;
    if (url.isEmpty) {
      UiFeedback.showError(context, 'Link pemutaran rekaman tidak tersedia');
      return;
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      UiFeedback.showError(context, 'Tidak dapat membuka tautan rekaman');
    }
  }

  void _shareRecording(BuildContext context) {
    final url = _targetPlayUrl;
    if (url.isEmpty) {
      UiFeedback.showError(context, 'Tautan tidak tersedia untuk dibagikan');
      return;
    }
    Share.share('Rekaman Zoom: ${recording.topic}\nTautan: $url');
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Center(
                    child: AppNavSymbol(
                      kind: AppNavSymbolKind.recordings,
                      color: AppColors.primaryDark,
                      size: 25,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recording.topic,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.cardTitle,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        recording.accountName,
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
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8FC),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIREKAM PADA',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateTimeUtil.formatWib(recording.startTime),
                    style: const TextStyle(
                      color: AppColors.textMain,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 9),
                  LayoutBuilder(
                    builder: (context, constraints) => Wrap(
                      spacing: 12,
                      runSpacing: 7,
                      children: [
                        _detail(
                            PhosphorIconsRegular.timer,
                            '${recording.duration} menit',
                            constraints.maxWidth),
                        _detail(PhosphorIconsRegular.database,
                            recording.formattedTotalSize, constraints.maxWidth),
                        if (recording.hostName.isNotEmpty)
                          _detail(PhosphorIconsRegular.user, recording.hostName,
                              constraints.maxWidth),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _openRecording(context),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    icon: const AppNavSymbol(
                      kind: AppNavSymbolKind.play,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: const Text('Putar rekaman'),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.outlined(
                  tooltip: 'Bagikan tautan',
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  icon: const Icon(PhosphorIconsRegular.shareNetwork,
                      size: 19, color: AppColors.primary),
                  onPressed: () => _shareRecording(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(IconData icon, String text, double maxWidth) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMain,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
