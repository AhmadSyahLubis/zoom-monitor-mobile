import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/models/availability_result.dart';
import '../../data/models/booking_request.dart';
import '../controllers/booking_controller.dart';
import '../controllers/schedules_controller.dart';
import 'booking_success_dialog.dart';

class BookingDialog extends ConsumerStatefulWidget {
  final AvailabilityResult accountResult;
  final String date;
  final String startTime;
  final int duration;

  const BookingDialog({
    super.key,
    required this.accountResult,
    required this.date,
    required this.startTime,
    required this.duration,
  });

  @override
  ConsumerState<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends ConsumerState<BookingDialog> {
  final _topicController = TextEditingController();
  bool _isRecurring = false;
  int _recurringType = 1; // 1: Harian, 2: Mingguan, 3: Bulanan
  final _repeatInterval = 1;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _ignoreConflict = false;

  @override
  void initState() {
    super.initState();
    final parts = widget.date.split('-');
    if (parts.length == 3) {
      _startDate = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } else {
      _startDate = DateTime.now();
    }
    // Default rentang: 14 hari ke depan
    _endDate = _startDate.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_startDate)
          ? _endDate
          : _startDate.add(const Duration(days: 7)),
      firstDate: _startDate.add(const Duration(days: 1)),
      lastDate: _startDate.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Berakhir Perulangan',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  String _formatDate(DateTime dt) => DateTimeUtil.dateWibFormat.format(dt);

  int get _approximateSessions {
    final days = _endDate.difference(_startDate).inDays + 1;
    if (_recurringType == 1) {
      return days > 0 ? days : 1;
    } else if (_recurringType == 2) {
      return (days / 7).ceil().clamp(1, 52);
    } else {
      final months = (_endDate.year - _startDate.year) * 12 +
          _endDate.month -
          _startDate.month +
          1;
      return months.clamp(1, 12);
    }
  }

  Future<void> _submitBooking() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      UiFeedback.showError(context, 'Topik rapat wajib diisi');
      return;
    }

    // Susun ISO 8601 UTC string dari date dan start_time WIB (UTC+7)
    final dateParts = widget.date.split('-');
    final timeParts = widget.startTime.split(':');
    final wibDateTime = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    // Konversi ke UTC untuk backend
    final utcIso =
        wibDateTime.subtract(const Duration(hours: 7)).toIso8601String();

    String? endUtcIso;
    if (_isRecurring) {
      final endWib =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      endUtcIso = endWib.subtract(const Duration(hours: 7)).toIso8601String();
    }

    final req = BookMeetingRequest(
      accountId: widget.accountResult.account.id,
      topic: topic,
      startTime: utcIso,
      duration: widget.duration,
      timezone: 'Asia/Jakarta',
      isRecurring: _isRecurring,
      recurringType: _isRecurring ? _recurringType : null,
      repeatInterval: _isRecurring ? _repeatInterval : null,
      endTimes: _isRecurring ? _approximateSessions : null,
      endDateTime: endUtcIso,
      ignoreConflict: _ignoreConflict,
    );

    final res =
        await ref.read(bookingControllerProvider.notifier).bookMeeting(req);

    if (!mounted) return;

    if (res != null) {
      ref.invalidate(schedulesProvider);
      ref
          .read(dashboardAccountsProvider.notifier)
          .loadDashboard(forceRefresh: true);
      Navigator.of(context).pop(); // Tutup modal input
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => BookingSuccessDialog(meeting: res),
      );
    } else {
      final err = ref.read(bookingControllerProvider).errorMessage ??
          'Gagal membuat rapat';
      UiFeedback.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingControllerProvider);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Form Booking Rapat',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Info Akun & Waktu Terpilih
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.scaffoldLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.meeting_room_outlined,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.accountResult.account.name} • ${widget.startTime} WIB (${widget.duration} mnt)',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Input Topik
            const Text(
              'Topik Rapat *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                hintText: 'Contoh: Rapat Koordinasi Wilayah',
                prefixIcon:
                    Icon(Icons.edit_note_rounded, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // Switch Rapat Berulang
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppColors.primary,
              title: const Text('Rapat Berulang (Recurring)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Jadwalkan rapat berulang dengan rentang tanggal pasti',
                  style: TextStyle(fontSize: 12)),
              value: _isRecurring,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 8),

              // Pilihan Tipe Perulangan
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _recurringType,
                decoration:
                    const InputDecoration(labelText: 'Tipe Perulangan'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Harian (Daily)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 2, child: Text('Mingguan (Weekly)', overflow: TextOverflow.ellipsis)),
                  DropdownMenuItem(value: 3, child: Text('Bulanan (Monthly)', overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _recurringType = val);
                },
              ),
              const SizedBox(height: 12),

              // Rentang Waktu (Dari Tanggal s/d Sampai Tanggal)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.scaffoldLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(PhosphorIconsRegular.calendarCheck,
                            size: 17, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Rentang Waktu Perulangan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        // Dari Tanggal
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Mulai Dari',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted)),
                                const SizedBox(height: 2),
                                Text(_formatDate(_startDate),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(PhosphorIconsRegular.arrowRight,
                              size: 16, color: AppColors.textMuted),
                        ),
                        // Sampai Tanggal
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors.primary, width: 1.2),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Sampai Tanggal (Pilih)',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 2),
                                  Text(_formatDate(_endDate),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primaryDark)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '🗓️ Rapat berulang dari ${_formatDate(_startDate)} s/d ${_formatDate(_endDate)} (${_endDate.difference(_startDate).inDays + 1} hari • ~$_approximateSessions sesi)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Switch Abaikan Benturan (opsional jika benturan)
            if (!widget.accountResult.isAvailable) ...[
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppColors.statusMeeting,
                title: const Text(
                  'Abaikan Benturan Jadwal',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.statusMeeting),
                ),
                subtitle: const Text(
                  'Paksa buat rapat meskipun bertabrakan dengan jadwal lain',
                  style: TextStyle(fontSize: 12),
                ),
                value: _ignoreConflict,
                onChanged: (val) => setState(() => _ignoreConflict = val),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            ElevatedButton(
              onPressed: state.isLoading ? null : _submitBooking,
              child: state.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Konfirmasi & Buat Rapat',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
