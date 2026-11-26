import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';

class RequestRecordingPanel extends ConsumerStatefulWidget {
  const RequestRecordingPanel({super.key, required this.requestId});

  final String requestId;

  @override
  ConsumerState<RequestRecordingPanel> createState() => _RequestRecordingPanelState();
}

class _RequestRecordingPanelState extends ConsumerState<RequestRecordingPanel> {
  bool loading = false;
  Map<String, dynamic>? result;
  String? error;

  Future<void> check() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final data = await ref.read(meetingRequestRepositoryProvider).recording(widget.requestId);
      if (mounted) setState(() => result = data);
    } catch (failure) {
      if (mounted) setState(() => error = requestError(failure));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> openRecording() async {
    final raw = asText(result?['share_url']);
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != 'zoom.us' && !uri.host.endsWith('.zoom.us'))) {
      setState(() => error = 'Tautan rekaman Zoom tidak valid.');
      return;
    }
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
        setState(() => error = 'Tautan rekaman belum dapat dibuka.');
      }
    } catch (_) {
      if (mounted) setState(() => error = 'Tautan rekaman belum dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rekaman cloud', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text('Periksa hasil setelah Zoom selesai memproses rapat.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: loading ? null : check,
            icon: loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_outlined),
            label: Text(loading ? 'Memeriksa...' : 'Periksa rekaman cloud'),
          ),
          if (result != null) ...[
            const SizedBox(height: 6),
            Text(asText(result?['message'])),
            if (result?['available'] == true &&
                asText(result?['share_url']).isNotEmpty)
              TextButton.icon(
                onPressed: openRecording,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Buka rekaman di Zoom'),
              ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
        ],
      );
}
