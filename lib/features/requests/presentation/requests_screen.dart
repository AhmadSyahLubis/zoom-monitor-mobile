import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_routes.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/widgets/app_glass_nav_bar.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';
import 'request_detail_screen.dart';
import 'claim_host_guide.dart';
import 'request_recording_panel.dart';

class RequestsScreen extends ConsumerStatefulWidget {
  const RequestsScreen({super.key, this.history = false});
  final bool history;
  @override
  ConsumerState<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends ConsumerState<RequestsScreen> {
  int page = 1;
  String status = 'active', search = '';
  DateTime? from, until;
  late Future<List<MeetingRequest>> future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final repo = ref.read(meetingRequestRepositoryProvider);
    future = widget.history
        ? repo.history(
            page: page,
            search: search,
            startDate: _date(from),
            endDate: _date(until))
        : repo.list(page: page, status: status);
  }

  String? _date(DateTime? date) =>
      date == null ? null : DateFormat('yyyy-MM-dd').format(date);
  void refresh() => setState(_load);
  String _time(String value) {
    final parsed = DateTime.tryParse(value);
    return parsed == null
        ? value
        : DateFormat('dd MMM yyyy, HH.mm')
            .format(parsed.toUtc().add(const Duration(hours: 7)));
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(authStateProvider).user?.isAdmin == true;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
          flexibleSpace: const GlassAppBarBackground(),
          title: Text(widget.history ? 'Riwayat rapat' : 'Pengajuan rapat')),
      bottomNavigationBar: AppGlassNavBar(
          currentIndex: widget.history ? (admin ? -1 : 2) : 1, isAdmin: admin),
      body: RefreshIndicator(
        onRefresh: () async {
          refresh();
          await future.then<void>((_) {}, onError: (Object _) {});
        },
        child: FutureBuilder<List<MeetingRequest>>(
          future: future,
          builder: (context, snapshot) {
            final rows = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 116),
              children: [
                if (!widget.history) ...[
                  if (admin)
                    Wrap(spacing: 8, children: [
                      TextButton(
                          onPressed: () => context.push(AppRoutes.history),
                          child: const Text('Riwayat rapat')),
                      TextButton(
                          onPressed: () => context.push(AppRoutes.search),
                          child: const Text('Cari slot Zoom')),
                      TextButton(
                          onPressed: () => context.push(AppRoutes.systemHealth),
                          child: const Text('Status layanan')),
                    ]),
                  FilledButton.icon(
                      onPressed: () async {
                        await context.push(AppRoutes.requestForm);
                        if (mounted) refresh();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Ajukan rapat')),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration:
                          const InputDecoration(labelText: 'Filter status'),
                      items: const [
                        'active',
                        'all',
                        'pending',
                        'approved',
                        'rejected',
                        'expired',
                        'provisioning',
                        'reconciliation_required',
                        'needs_reschedule',
                        'displacing'
                      ]
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(_statusLabel(s))))
                          .toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() {
                            status = value;
                            page = 1;
                            _load();
                          });
                      }),
                ] else ...[
                  TextField(
                      decoration: const InputDecoration(
                          labelText: 'Cari topik, OPD, atau PIC',
                          prefixIcon: Icon(Icons.search)),
                      onSubmitted: (value) => setState(() {
                            search = value.trim();
                            page = 1;
                            _load();
                          })),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              initialDate: from ?? DateTime.now());
                          if (d != null)
                            setState(() {
                              from = d;
                              if (until != null && until!.isBefore(d))
                                until = null;
                              page = 1;
                              _load();
                            });
                        },
                        child:
                            Text(from == null ? 'Dari tanggal' : _date(from)!)),
                    OutlinedButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: from ?? DateTime(2020),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                              initialDate: until ??
                                  (from != null && from!.isAfter(DateTime.now())
                                      ? from!
                                      : DateTime.now()));
                          if (d != null)
                            setState(() {
                              until = d;
                              page = 1;
                              _load();
                            });
                        },
                        child: Text(
                            until == null ? 'Sampai tanggal' : _date(until)!)),
                    if (from != null || until != null)
                      TextButton(
                          onPressed: () => setState(() {
                                from = null;
                                until = null;
                                page = 1;
                                _load();
                              }),
                          child: const Text('Hapus tanggal')),
                  ]),
                ],
                const SizedBox(height: 18),
                if (snapshot.connectionState != ConnectionState.done)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator()))
                else if (snapshot.hasError)
                  ContentSurface(
                      child: Column(children: [
                    Text(requestError(snapshot.error!)),
                    TextButton(
                        onPressed: refresh, child: const Text('Coba lagi'))
                  ]))
                else if (rows.isEmpty)
                  const ContentSurface(
                      child: Text('Belum ada pengajuan pada daftar ini.'))
                else
                  for (final row in rows) ...[
                    ContentSurface(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(row.opdName,
                              style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 4),
                          Text(row.topic,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(
                              '${_time(row.startTime)} WIB · ${_statusLabel(row.status)}'),
                          if (row.reviewReason.isNotEmpty)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('Catatan: ${row.reviewReason}')),
                          if (!admin && row.status == 'approved') ...[
                            const SizedBox(height: 12),
                            ClaimHostGuide(
                                requestId: row.id,
                                meetingId: row.zoomMeetingId),
                          ],
                          if (widget.history && row.recordCloud) ...[
                            const SizedBox(height: 12),
                            RequestRecordingPanel(requestId: row.id),
                          ],
                          Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                  onPressed: () async {
                                    await Navigator.of(context).push(
                                        MaterialPageRoute(
                                            builder: (_) => RequestDetailScreen(
                                                id: row.id)));
                                    if (mounted) refresh();
                                  },
                                  child: const Text('Lihat detail'))),
                        ])),
                    const SizedBox(height: 10),
                  ],
                if (snapshot.connectionState == ConnectionState.done &&
                    !snapshot.hasError)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        OutlinedButton(
                            onPressed: page > 1
                                ? () => setState(() {
                                      page--;
                                      _load();
                                    })
                                : null,
                            child: const Text('Sebelumnya')),
                        Text('$page'),
                        OutlinedButton(
                            onPressed: rows.length == 50
                                ? () => setState(() {
                                      page++;
                                      _load();
                                    })
                                : null,
                            child: const Text('Berikutnya')),
                      ]),
                if (admin && !widget.history)
                  TextButton(
                      onPressed: () => context.push(AppRoutes.opdAccounts),
                      child: const Text('Kelola akun OPD')),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _statusLabel(String status) => switch (status) {
      'active' => 'Aktif',
      'all' => 'Semua',
      'pending' => 'Menunggu persetujuan',
      'approved' => 'Disetujui',
      'rejected' => 'Ditolak',
      'expired' => 'Kedaluwarsa',
      'provisioning' => 'Membuat rapat',
      'reconciliation_required' => 'Perlu verifikasi',
      'needs_reschedule' => 'Perlu jadwal baru',
      'displacing' => 'Mengalihkan jadwal',
      _ => status,
    };
