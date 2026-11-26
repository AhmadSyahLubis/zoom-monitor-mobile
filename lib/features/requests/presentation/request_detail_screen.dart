import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/glass_surface.dart';
import '../../auth/data/models/user_profile.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';
import 'request_form_screen.dart';

class RequestDetailScreen extends ConsumerStatefulWidget {
  const RequestDetailScreen({super.key, required this.id});
  final String id;
  @override
  ConsumerState<RequestDetailScreen> createState() =>
      _RequestDetailScreenState();
}

class _RequestDetailScreenState extends ConsumerState<RequestDetailScreen> {
  late Future<MeetingRequest> future;
  late Future<List<OpdProfile>> directory;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    directory = ref.read(meetingRequestRepositoryProvider).opds();
    reload();
  }

  void reload() => setState(() {
        future = ref.read(meetingRequestRepositoryProvider).get(widget.id);
        error = null;
      });

  Future<void> action(Future<void> Function() run) async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await run();
      if (mounted) reload();
    } catch (e) {
      if (mounted) setState(() => error = requestError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> showInvitation() async {
    await action(() async {
      final data = await ref
          .read(meetingRequestRepositoryProvider)
          .invitation(widget.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Undangan rapat'),
                  content: SingleChildScrollView(
                      child: SelectableText(
                          'Topik: ${asText(data['topic'])}\nMeeting ID: ${asText(data['meeting_id'])}\nLink: ${asText(data['join_url'])}\nPasscode: ${asText(data['password'])}\nPIC: ${asText(data['pic_name'])} (${asText(data['pic_phone'])})')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup')),
                    TextButton(
                        onPressed: () => Share.share(
                            'Rapat: ${asText(data['topic'])}\n${asText(data['join_url'])}\nMeeting ID: ${asText(data['meeting_id'])}\nPasscode: ${asText(data['password'])}'),
                        child: const Text('Bagikan'))
                  ]));
    });
  }

  Future<void> showHostAccess() async {
    await action(() async {
      final data = await ref
          .read(meetingRequestRepositoryProvider)
          .hostAccess(widget.id);
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
                  title: const Text('Akses host'),
                  content: SingleChildScrollView(
                      child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(asText(data['message']).isNotEmpty
                            ? asText(data['message'])
                            : 'Meeting ID: ${asText(data['meeting_id'])}'),
                        if (data['host_key_available'] == true)
                          SelectableText(
                              'Host key: ${asText(data['host_key'])}'),
                        Text(
                            'Join before host: ${data['join_before_host'] == true ? 'Aktif' : 'Tidak aktif'}'),
                        Text(
                            'Waiting room: ${data['waiting_room'] == true ? 'Aktif' : 'Tidak aktif'}'),
                        if (data['join_before_host_minutes'] != null)
                          Text(
                              'Masuk lebih awal: ${asInt(data['join_before_host_minutes'])} menit'),
                      ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Tutup'))
                  ]));
      data.clear();
    });
  }

  Future<void> shareLetter() async {
    await action(() async {
      final bytes = await ref
          .read(meetingRequestRepositoryProvider)
          .letterContent(widget.id);
      final file = File(
          '${(await getTemporaryDirectory()).path}/surat-${widget.id}.pdf');
      await file.writeAsBytes(bytes, flush: true);
      try {
        await Share.shareXFiles([XFile(file.path, mimeType: 'application/pdf')],
            text: 'Surat permintaan rapat');
      } finally {
        if (await file.exists()) await file.delete();
      }
    });
  }

  Future<void> reject(MeetingRequest row) async {
    var reason = '';
    final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Tolak pengajuan'),
                content: TextField(
                    onChanged: (value) => reason = value,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration:
                        const InputDecoration(labelText: 'Alasan penolakan')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () =>
                          Navigator.pop(context, reason.trim().isNotEmpty),
                      child: const Text('Tolak'))
                ]));
    if (approved == true)
      await action(() => ref
          .read(meetingRequestRepositoryProvider)
          .reject(row.id, reason.trim(), row.revision));
  }

  Future<void> approve(MeetingRequest row) async {
    final repo = ref.read(meetingRequestRepositoryProvider);
    List<ApprovalOption> options;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      options = await repo.options(row.id);
    } catch (e) {
      if (mounted)
        setState(() {
          error = requestError(e);
          busy = false;
        });
      return;
    }
    if (!mounted) return;
    setState(() => busy = false);
    ApprovalOption? selected;
    bool confirmed = false;
    var reason = '';
    final approval = await showDialog<ApprovalOption>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                  title: const Text('Pilih akun Zoom dan host'),
                  content: SizedBox(
                      width: double.maxFinite,
                      child: SingleChildScrollView(
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                        if (options.isEmpty)
                          const Text('Belum ada akun Zoom yang tersedia.'),
                        for (final option in options)
                          RadioListTile<ApprovalOption>(
                              contentPadding: EdgeInsets.zero,
                              value: option,
                              groupValue: selected,
                              onChanged: option.eligible
                                  ? (v) => update(() {
                                        selected = v;
                                        confirmed = false;
                                      })
                                  : null,
                              title: Text(
                                  '${option.accountName} · ${option.hostName}'),
                              subtitle: Text(
                                  'Kapasitas ${option.capacity} · Cloud ${option.cloudRecording ? 'ya' : 'tidak'}\nJoin before host: ${option.joinBeforeHost == null ? 'belum diverifikasi' : option.joinBeforeHost! ? 'aktif' : 'nonaktif'} · Waiting room: ${option.waitingRoom == null ? 'belum diverifikasi' : option.waitingRoom! ? 'aktif' : 'nonaktif'}\n${option.reason}')),
                        if (selected?.replaceRequests.isNotEmpty == true) ...[
                          const Divider(),
                          const Text('Jadwal berikut akan dialihkan:'),
                          for (final item in selected!.replaceRequests)
                            Text('${item.opdName}: ${item.topic}'),
                          TextField(
                              onChanged: (value) =>
                                  update(() => reason = value),
                              maxLength: 1000,
                              decoration: const InputDecoration(
                                  labelText: 'Alasan pengalihan')),
                          CheckboxListTile(
                              value: confirmed,
                              onChanged: (v) =>
                                  update(() => confirmed = v == true),
                              title: const Text(
                                  'Saya mengonfirmasi pengalihan jadwal. Meeting LIVE harus diakhiri manual.')),
                        ],
                      ]))),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Batal')),
                    FilledButton(
                        onPressed: selected == null ||
                                (selected!.replaceRequests.isNotEmpty &&
                                    (!confirmed || reason.trim().isEmpty))
                            ? null
                            : () => Navigator.pop(context, selected),
                        child: const Text('Setujui dan buat meeting'))
                  ],
                )));
    if (approval != null)
      await action(() => repo.approve(row.id, {
            'revision': row.revision,
            'account_id': approval.accountId,
            'host_id': approval.hostId,
            'replace_request_ids':
                approval.replaceRequests.map((e) => e.id).toList(),
            'reason': reason.trim()
          }));
  }

  Future<void> reconcile(MeetingRequest row) async {
    var meetingId = '';
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                title: const Text('Verifikasi hasil Zoom'),
                content: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('Verifikasi ini tidak membuat meeting baru.'),
                  if (row.createAttempted)
                    TextField(
                        onChanged: (value) => meetingId = value,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Meeting ID dari Zoom'))
                ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Batal')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Verifikasi'))
                ]));
    final id = int.tryParse(meetingId) ?? 0;
    if (confirmed == true && (!row.createAttempted || id >= 100000000))
      await action(() =>
          ref.read(meetingRequestRepositoryProvider).reconcile(row.id, id));
    else if (confirmed == true && mounted)
      setState(() => error = 'Masukkan Meeting ID Zoom yang valid.');
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
          flexibleSpace: const GlassAppBarBackground(),
          title: const Text('Detail pengajuan')),
      body: FutureBuilder<MeetingRequest>(
          future: future,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return Center(
                  child: snapshot.hasError
                      ? TextButton(
                          onPressed: reload,
                          child: Text(
                              '${requestError(snapshot.error!)}\nCoba lagi'))
                      : const CircularProgressIndicator());
            final row = snapshot.data!;
            final canEdit = row.canEdit && row.opdId == user?.opd?.id;
            return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  ContentSurface(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(row.opdName,
                            style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 6),
                        Text(row.topic,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(
                            'Status: ${_status(row.status)}\n${_wib(row.startTime)} – ${_wib(row.endTime)} WIB\nKluster ${row.cluster}\nPIC ${row.picName} · ${row.picPhone}\nKapasitas ${row.capacity} · Cloud recording ${row.recordCloud ? 'ya' : 'tidak'}\nPrioritas: ${_priority(row.priority)}'),
                        FutureBuilder<List<OpdProfile>>(
                            future: directory,
                            builder: (context, snapshot) {
                              final names = row.participantOpdIds.map((id) {
                                for (final opd
                                    in snapshot.data ?? <OpdProfile>[]) {
                                  if (opd.id == id) return opd.name;
                                }
                                return 'OPD $id';
                              }).toList()
                                ..addAll(row.participantOthers);
                              return Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Text('Peserta: ${names.join(', ')}'));
                            }),
                        if (row.reviewReason.isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child:
                                  Text('Catatan admin: ${row.reviewReason}')),
                        if (error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(error!,
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .error))),
                        if (busy) const LinearProgressIndicator(),
                        const SizedBox(height: 16),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          if (canEdit)
                            OutlinedButton(
                                onPressed: busy
                                    ? null
                                    : () async {
                                        final changed =
                                            await Navigator.push<bool>(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (_) =>
                                                        RequestFormScreen(
                                                            initial: row)));
                                        if (changed == true && mounted)
                                          reload();
                                      },
                                child: Text(row.status == 'expired'
                                    ? 'Ubah jadwal'
                                    : 'Edit pengajuan')),
                          if (row.hasLetter)
                            OutlinedButton(
                                onPressed: busy ? null : shareLetter,
                                child: const Text('Lihat surat PDF')),
                          if (row.status == 'approved' &&
                              row.zoomMeetingId > 0) ...[
                            OutlinedButton(
                                onPressed: busy ? null : showInvitation,
                                child: const Text('Undangan')),
                            OutlinedButton(
                                onPressed: busy ? null : showHostAccess,
                                child: const Text('Akses host'))
                          ],
                          if (user?.isAdmin == true &&
                              row.status == 'pending') ...[
                            FilledButton(
                                onPressed: busy ? null : () => approve(row),
                                child: const Text('Periksa dan setujui')),
                            OutlinedButton(
                                onPressed: busy ? null : () => reject(row),
                                child: const Text('Tolak'))
                          ],
                          if (user?.isAdmin == true &&
                              ['provisioning', 'reconciliation_required']
                                  .contains(row.status))
                            OutlinedButton(
                                onPressed: busy ? null : () => reconcile(row),
                                child: const Text('Verifikasi Zoom')),
                        ]),
                      ])),
                ]);
          }),
    );
  }

  String _wib(String value) {
    final date = DateTime.tryParse(value);
    return date == null
        ? value
        : DateFormat('dd MMM HH.mm')
            .format(date.toUtc().add(const Duration(hours: 7)));
  }

  String _status(String value) => switch (value) {
        'pending' => 'Menunggu persetujuan',
        'approved' => 'Disetujui',
        'rejected' => 'Ditolak',
        'expired' => 'Kedaluwarsa',
        'provisioning' => 'Membuat rapat',
        'reconciliation_required' => 'Perlu verifikasi',
        'needs_reschedule' => 'Perlu jadwal baru',
        'displacing' => 'Mengalihkan jadwal',
        _ => value,
      };
  String _priority(String value) => switch (value) {
        'governor' => 'Gubernur',
        'vice_governor' => 'Wakil Gubernur',
        'regional_secretary' => 'Sekda',
        _ => 'Biasa',
      };
}
