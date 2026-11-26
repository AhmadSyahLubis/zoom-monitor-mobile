import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/glass_surface.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/models/user_profile.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../data/meeting_request.dart';
import '../data/meeting_request_repository.dart';
import 'opd_participant_picker.dart';

class RequestFormScreen extends ConsumerStatefulWidget {
  const RequestFormScreen({super.key, this.initial});
  final MeetingRequest? initial;
  @override
  ConsumerState<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends ConsumerState<RequestFormScreen> {
  final key = GlobalKey<FormState>();
  final topic = TextEditingController(),
      pic = TextEditingController(),
      phone = TextEditingController(),
      capacity = TextEditingController(text: '100'),
      others = TextEditingController();
  DateTime date = DateTime.now().toUtc().add(const Duration(hours: 7));
  String cluster = '1', priority = 'normal';
  bool record = false, busy = false, uncertain = false;
  String? error, idempotencyKey, uploadedLetterId;
  Map<String, dynamic>? submission;
  PlatformFile? letter;
  late Future<List<OpdProfile>> directory;
  final Set<int> participantIds = {};

  @override
  void initState() {
    super.initState();
    directory = ref.read(meetingRequestRepositoryProvider).opds();
    final row = widget.initial;
    if (row != null) {
      topic.text = row.topic;
      pic.text = row.picName;
      phone.text = row.picPhone;
      capacity.text = row.capacity.toString();
      cluster = row.cluster;
      priority = row.priority;
      record = row.recordCloud;
      participantIds.addAll(row.participantOpdIds);
      others.text = row.participantOthers.join('\n');
      final parsed = DateTime.tryParse(row.startTime);
      if (parsed != null) date = parsed.toUtc().add(const Duration(hours: 7));
    }
  }

  @override
  void dispose() {
    for (final c in [topic, pic, phone, capacity, others]) {
      c.dispose();
    }
    super.dispose();
  }

  void changed() {
    if (uncertain) return;
    submission = null;
    idempotencyKey = null;
    setState(() => error = null);
  }

  Future<void> pickLetter() async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['pdf'], withData: true);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    if (picked.size > 5 * 1024 * 1024 ||
        picked.size == 0 ||
        !picked.name.toLowerCase().endsWith('.pdf')) {
      setState(() => error = 'Surat harus berupa PDF maksimal 5 MB.');
      return;
    }
    setState(() {
      letter = picked;
      uploadedLetterId = null;
      error = null;
    });
    changed();
  }

  Future<void> send() async {
    if (busy || !(key.currentState?.validate() ?? false)) return;
    final admin = ref.read(authStateProvider).user?.isAdmin == true;
    final names = others.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.length > 20 ||
        names.any((s) => s.length > 150) ||
        names.map((s) => s.toLowerCase()).toSet().length != names.length) {
      setState(() => error =
          'Peserta lain maksimal 20 nama unik, masing-masing 150 karakter.');
      return;
    }
    if (participantIds.isEmpty && names.isEmpty) {
      setState(() => error = 'Pilih OPD peserta atau tulis peserta lainnya.');
      return;
    }
    if (!admin && widget.initial?.hasLetter != true && letter == null) {
      setState(() => error = 'Surat permintaan PDF wajib dilampirkan.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final repo = ref.read(meetingRequestRepositoryProvider);
      if (letter != null && uploadedLetterId == null)
        uploadedLetterId = await repo.uploadLetter(letter!);
      submission ??= {
        'topic': topic.text.trim(),
        'date': DateFormat('yyyy-MM-dd').format(date),
        'cluster': cluster,
        'pic_name': pic.text.trim(),
        'pic_phone': phone.text.trim(),
        'capacity': int.parse(capacity.text),
        'record_cloud': record,
        'participant_opd_ids': participantIds.toList()..sort(),
        'participant_others': names,
        'priority': admin ? priority : 'normal',
        if (uploadedLetterId != null) 'request_letter_id': uploadedLetterId,
        if (widget.initial != null) 'revision': widget.initial!.revision,
      };
      idempotencyKey ??= const Uuid().v4();
      if (widget.initial == null) {
        await repo.submit(submission!, idempotencyKey!);
      } else {
        await repo.edit(widget.initial!.id, submission!, idempotencyKey!);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final code = e is DioException ? e.response?.statusCode : null;
      final isConflict = code == 409 || code == 404;
      final isValidation = code == 400 || code == 403 || code == 422;
      setState(() {
        error = isConflict
            ? 'Pengajuan sudah berubah. Kembali ke daftar dan buka ulang.'
            : requestError(e);
        uncertain = !isConflict && !isValidation && submission != null;
        if (isConflict || isValidation) {
          submission = null;
          idempotencyKey = null;
          if (isValidation && letter != null) uploadedLetterId = null;
        }
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _section(BuildContext context, String title, List<Widget> children) {
    return ContentSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  void _setParticipants(Set<int> ids) {
    if (uncertain) return;
    setState(() {
      participantIds
        ..clear()
        ..addAll(ids);
      submission = null;
      idempotencyKey = null;
      error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(authStateProvider).user?.isAdmin == true;
    final locked = busy || uncertain;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: Text(widget.initial == null ? 'Ajukan rapat' : 'Edit pengajuan'),
      ),
      body: Form(
        key: key,
        onChanged: changed,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
          children: [
            Text(
              widget.initial == null
                  ? 'Isi kebutuhan rapat. Admin Diskominfo akan memeriksa jadwal dan akun Zoom.'
                  : 'Perbarui pengajuan lalu kirim kembali untuk diperiksa admin.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.initial?.reviewReason.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Catatan admin: ${widget.initial!.reviewReason}'),
              ),
            const SizedBox(height: 18),
            _section(context, 'Jadwal rapat', [
              TextFormField(
                controller: topic,
                readOnly: locked,
                maxLength: 200,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Topik rapat',
                  counterText: '',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Isi topik rapat'
                    : null,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: locked
                      ? null
                      : () async {
                          final now = DateTime.now()
                              .toUtc()
                              .add(const Duration(hours: 7));
                          final first = DateTime(now.year, now.month, now.day);
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: date.isBefore(first) ? first : date,
                            firstDate: first,
                            lastDate: first.add(const Duration(days: 365)),
                          );
                          if (selected != null) {
                            setState(() {
                              date = selected;
                              submission = null;
                              idempotencyKey = null;
                              error = null;
                            });
                          }
                        },
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                      'Tanggal · ${DateFormat('dd MMM yyyy').format(date)}'),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: cluster,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Kluster waktu WIB'),
                items: const [
                  DropdownMenuItem(
                      value: '1', child: Text('Pagi · 08.00–12.00')),
                  DropdownMenuItem(
                      value: '2', child: Text('Siang · 14.00–16.30')),
                  DropdownMenuItem(
                      value: 'both', child: Text('Sehari · 08.00–16.30')),
                ],
                onChanged: locked
                    ? null
                    : (value) => setState(() {
                          cluster = value!;
                          submission = null;
                          idempotencyKey = null;
                          error = null;
                        }),
              ),
              const SizedBox(height: 8),
              Text(
                'Kluster yang sedang berjalan tetap dapat diajukan selama belum berakhir.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ]),
            const SizedBox(height: 14),
            _section(context, 'Penanggung jawab', [
              TextFormField(
                controller: pic,
                readOnly: locked,
                maxLength: 150,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Nama PIC', counterText: ''),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Isi nama PIC'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                readOnly: locked,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telepon PIC',
                  hintText: '+628123456789',
                ),
                validator: (value) =>
                    RegExp(r'^\+?[0-9]{8,16}$').hasMatch(value ?? '')
                        ? null
                        : 'Gunakan 8–16 angka, boleh diawali +',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: capacity,
                readOnly: locked,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Kapasitas peserta'),
                validator: (value) {
                  final count = int.tryParse(value ?? '');
                  return count == null || count < 1 || count > 10000
                      ? 'Isi 1–10.000 peserta'
                      : null;
                },
              ),
              const SizedBox(height: 4),
              Material(
                color: Colors.transparent,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Perlu cloud recording'),
                  value: record,
                  onChanged: locked
                      ? null
                      : (value) => setState(() {
                            record = value;
                            submission = null;
                            idempotencyKey = null;
                            error = null;
                          }),
                ),
              ),
              if (record)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Panduan rekaman cloud',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 6),
                      const Text(
                          'Setelah disetujui, rapat diatur merekam otomatis ke cloud. PIC perlu memastikan indikator Recording aktif saat rapat dimulai.'),
                      const SizedBox(height: 6),
                      const Text(
                          'Jika belum aktif, di Zoom mobile pilih More → Record → Start recording. Di desktop/web pilih More → Record → Record to the cloud.'),
                      const SizedBox(height: 6),
                      const Text(
                          'Setelah rapat selesai dan Zoom memprosesnya, buka Riwayat rapat lalu pilih Periksa rekaman cloud.'),
                    ],
                  ),
                ),
            ]),
            const SizedBox(height: 14),
            _section(context, 'Peserta', [
              FutureBuilder<List<OpdProfile>>(
                future: directory,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return TextButton.icon(
                      onPressed: () => setState(
                        () => directory =
                            ref.read(meetingRequestRepositoryProvider).opds(),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Daftar OPD gagal dimuat. Coba lagi'),
                    );
                  }
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return OpdParticipantPicker(
                    opds: snapshot.data!,
                    selectedIds: participantIds,
                    enabled: !locked,
                    onChanged: _setParticipants,
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: others,
                readOnly: locked,
                maxLines: 3,
                maxLength: 3000,
                decoration: const InputDecoration(
                  labelText: 'Peserta lain',
                  hintText: 'Satu nama per baris',
                  counterText: '',
                  helperText: 'Opsional, maksimal 20 nama',
                ),
              ),
            ]),
            const SizedBox(height: 14),
            _section(context, 'Dokumen dan pengiriman', [
              Text(
                admin
                    ? 'Surat permintaan PDF opsional untuk admin.'
                    : widget.initial?.hasLetter == true
                        ? 'Surat sebelumnya tetap dipakai jika tidak diganti.'
                        : 'Lampirkan surat permintaan PDF, maksimal 5 MB.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: locked ? null : pickLetter,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                      letter == null ? 'Pilih surat PDF' : 'Ganti surat PDF'),
                ),
              ),
              if (letter != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    letter!.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (admin) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  isExpanded: true,
                  decoration:
                      const InputDecoration(labelText: 'Prioritas rapat'),
                  items: const [
                    DropdownMenuItem(value: 'normal', child: Text('Biasa')),
                    DropdownMenuItem(
                        value: 'governor', child: Text('Gubernur')),
                    DropdownMenuItem(
                        value: 'vice_governor', child: Text('Wakil Gubernur')),
                    DropdownMenuItem(
                        value: 'regional_secretary', child: Text('Sekda')),
                  ],
                  onChanged: locked
                      ? null
                      : (value) => setState(() {
                            priority = value!;
                            submission = null;
                            idempotencyKey = null;
                            error = null;
                          }),
                ),
              ],
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              if (uncertain)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Pengiriman belum terkonfirmasi. Periksa daftar pengajuan, lalu coba kirim ulang data yang sama bila perlu.',
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: busy ? null : send,
                  child: Text(
                    busy
                        ? 'Mengirim...'
                        : uncertain
                            ? 'Coba kirim ulang'
                            : widget.initial == null
                                ? 'Kirim pengajuan'
                                : 'Simpan dan ajukan ulang',
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
