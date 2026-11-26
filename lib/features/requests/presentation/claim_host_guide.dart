import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';

class ClaimHostGuide extends StatelessWidget {
  const ClaimHostGuide(
      {super.key, required this.requestId, required this.meetingId});

  final String requestId;
  final int meetingId;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Untuk PIC rapat',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          const Text(
              'PIC dapat mengambil peran host lewat Zoom menggunakan host key rapat.'),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              useSafeArea: true,
              isScrollControlled: true,
              backgroundColor: AppColors.neoBase,
              showDragHandle: true,
              builder: (_) =>
                  _ClaimHostSheet(requestId: requestId, meetingId: meetingId),
            ),
            icon: const Icon(Icons.key_outlined),
            label: const Text('Cara claim host'),
          ),
        ]),
      );
}

class _ClaimHostSheet extends ConsumerStatefulWidget {
  const _ClaimHostSheet({required this.requestId, required this.meetingId});
  final String requestId;
  final int meetingId;

  @override
  ConsumerState<_ClaimHostSheet> createState() => _ClaimHostSheetState();
}

class _ClaimHostSheetState extends ConsumerState<_ClaimHostSheet> {
  Map<String, dynamic>? access;
  bool loading = false;
  String? error;

  Future<void> loadKey() async {
    if (loading) return;
    if (widget.meetingId <= 0) {
      setState(() => error =
          'Rapat belum terhubung ke meeting Zoom. Hubungi admin Diskominfo.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
      access = null;
    });
    try {
      final result = await ref
          .read(meetingRequestRepositoryProvider)
          .hostAccess(widget.requestId);
      if (asInt(result['meeting_id']) != widget.meetingId ||
          (result['host_key_available'] == true &&
              !RegExp(r'^\d{6}$').hasMatch(asText(result['host_key'])))) {
        throw StateError(
            'Akses host tidak cocok dengan rapat ini. Muat ulang pengajuan.');
      }
      if (mounted) setState(() => access = result);
    } catch (failure) {
      if (mounted) setState(() => error = requestError(failure));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> copyKey() async {
    final key = asText(access?['host_key']);
    if (key.isEmpty) return;
    try {
      await Clipboard.setData(ClipboardData(text: key));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Host key disalin. Jangan bagikan kepada peserta.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyalin host key.')));
      }
    }
  }

  @override
  void dispose() {
    access?.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = access;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.78,
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text('Cara claim host untuk PIC',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            const Text(
                'Host key terpisah dari undangan. Berikan hanya kepada PIC rapat.'),
            const SizedBox(height: 18),
            const _GuideStep(
                number: '1',
                text:
                    'Masuk ke aplikasi Zoom Workplace, lalu buka link peserta dari detail pengajuan.'),
            const _GuideStep(
                number: '2',
                text:
                    'Di Zoom mobile, pilih More → Enter Host Key to Claim Host. Di desktop/web, pilih Participants → Claim Host.'),
            const _GuideStep(
                number: '3',
                text:
                    'Ambil host key di bawah, masukkan enam angkanya di Zoom, lalu pilih Claim.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: loading ? null : loadKey,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.visibility_outlined),
              label: Text(loading
                  ? 'Memeriksa akses...'
                  : data == null
                      ? 'Lihat host key'
                      : 'Periksa ulang host key'),
            ),
            if (error != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error))),
            if (data?['host_key_available'] == true) ...[
              const SizedBox(height: 12),
              Text('Host key Zoom',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              SelectableText(asText(data?['host_key']),
                  style: Theme.of(context).textTheme.headlineMedium),
              Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                      onPressed: copyKey,
                      icon: const Icon(Icons.copy_outlined),
                      label: const Text('Salin host key'))),
              if (data?['join_before_host'] == false ||
                  data?['waiting_room'] == true)
                const Text(
                    'PIC mungkin perlu menunggu admin membuka rapat atau mengizinkan masuk sesuai pengaturan Zoom.'),
              if (data?['join_before_host'] == true &&
                  asInt(data?['join_before_host_minutes']) > 0)
                Text(
                    'Masuk sebelum jadwal dibatasi ${asInt(data?['join_before_host_minutes'])} menit oleh Zoom.'),
            ] else if (data != null) ...[
              const SizedBox(height: 12),
              Text(asText(data['message']).isNotEmpty
                  ? asText(data['message'])
                  : 'Host key tidak tersedia. Pemilik akun Zoom dapat membuka rapat lalu menyerahkan host kepada PIC.'),
            ],
          ]),
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({required this.number, required this.text});
  final String number, text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 30,
              child:
                  Text(number, style: Theme.of(context).textTheme.titleMedium)),
          Expanded(child: Text(text)),
        ]),
      );
}
