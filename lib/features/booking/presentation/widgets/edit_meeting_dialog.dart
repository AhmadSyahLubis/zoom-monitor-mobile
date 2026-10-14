import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../data/models/booking_request.dart';
import '../../data/models/schedule_item.dart';
import '../controllers/schedules_controller.dart';

class EditMeetingDialog extends ConsumerStatefulWidget {
  final ScheduleItem meeting;

  const EditMeetingDialog({super.key, required this.meeting});

  @override
  ConsumerState<EditMeetingDialog> createState() => _EditMeetingDialogState();
}

class _EditMeetingDialogState extends ConsumerState<EditMeetingDialog> {
  late final TextEditingController _topicController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _duration;
  late bool _isRecurring;
  int _recurringType = 1; // 1: Harian, 2: Mingguan, 3: Bulanan
  late DateTime _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _topicController = TextEditingController(text: widget.meeting.topic);

    // Parse waktu mulai WIB
    final startWib = DateTimeUtil.parseToWib(widget.meeting.startTime);
    _selectedDate = DateTime(startWib.year, startWib.month, startWib.day);
    _selectedTime = TimeOfDay(hour: startWib.hour, minute: startWib.minute);
    _duration = widget.meeting.duration > 0 ? widget.meeting.duration : 60;
    _isRecurring = widget.meeting.isRecurring;
    _endDate = _selectedDate.add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Rapat',
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        if (_endDate.isBefore(_selectedDate)) {
          _endDate = _selectedDate.add(const Duration(days: 7));
        }
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      helpText: 'Pilih Jam Mulai (WIB)',
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isAfter(_selectedDate)
          ? _endDate
          : _selectedDate.add(const Duration(days: 7)),
      firstDate: _selectedDate.add(const Duration(days: 1)),
      lastDate: _selectedDate.add(const Duration(days: 365)),
      helpText: 'Pilih Tanggal Berakhir Perulangan',
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  String _formatDate(DateTime dt) => DateTimeUtil.dateWibFormat.format(dt);

  String _formatTime(TimeOfDay t) {
    final hour = t.hour.toString().padLeft(2, '0');
    final minute = t.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _submitEdit() async {
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      UiFeedback.showError(context, 'Topik rapat tidak boleh kosong');
      return;
    }

    setState(() => _isLoading = true);

    final dateStr =
        '${_selectedDate.year.toString().padLeft(4, '0')}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final timeStr = _formatTime(_selectedTime);
    final startTimeFormatted = '$dateStr $timeStr';

    String? endDateTimeUtc;
    if (_isRecurring) {
      final endWib =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
      endDateTimeUtc =
          endWib.subtract(const Duration(hours: 7)).toIso8601String();
    }

    final req = UpdateMeetingRequest(
      accountId: widget.meeting.accountId,
      topic: topic,
      startTime: startTimeFormatted,
      duration: _duration,
      isRecurring: _isRecurring,
      recurrenceType: _isRecurring ? _recurringType : null,
      repeatInterval: _isRecurring ? 1 : null,
      endDateTime: endDateTimeUtc,
    );

    final success = await ref
        .read(schedulesControllerProvider.notifier)
        .updateMeeting(widget.meeting.meetingId, req);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.of(context).pop(true);
      UiFeedback.showSuccess(context, 'Jadwal rapat berhasil diperbarui!');
    } else {
      UiFeedback.showError(
          context, 'Gagal memperbarui rapat. Periksa benturan jadwal.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
            // Header
            Row(
              children: [
                const Icon(PhosphorIconsRegular.pencilSimple,
                    color: AppColors.primary, size: 22),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Edit Jadwal Rapat',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
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

            // Info Akun & ID
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.scaffoldLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(PhosphorIconsRegular.videoCamera,
                      color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${widget.meeting.accountName} • ID: ${widget.meeting.meetingId}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Topik Rapat
            const Text(
              'Topik Rapat *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                hintText: 'Masukkan topik rapat...',
                prefixIcon: Icon(PhosphorIconsRegular.notepad,
                    color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),

            // Row Tanggal & Jam
            Row(
              children: [
                // Tanggal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tanggal Rapat *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.calendarBlank,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(_selectedDate),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Jam
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jam Mulai (WIB) *',
                        style: TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.scaffoldLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(PhosphorIconsRegular.clock,
                                  size: 18, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatTime(_selectedTime),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Durasi
            const Text(
              'Durasi Rapat *',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Builder(
              builder: (context) {
                final standardDurations = <int, String>{
                  15: '15 Menit',
                  30: '30 Menit',
                  45: '45 Menit',
                  60: '1 Jam (60 Menit)',
                  90: '1.5 Jam (90 Menit)',
                  120: '2 Jam (120 Menit)',
                  180: '3 Jam (180 Menit)',
                  240: '4 Jam (240 Menit)',
                  300: '5 Jam (300 Menit)',
                  360: '6 Jam (360 Menit)',
                  480: '8 Jam (480 Menit - Seharian)',
                };
                if (!standardDurations.containsKey(_duration)) {
                  standardDurations[_duration] = '$_duration Menit';
                }
                final sortedKeys = standardDurations.keys.toList()..sort();
                return DropdownButtonFormField<int>(
                  isExpanded: true,
                  initialValue: _duration,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(PhosphorIconsRegular.timer,
                        color: AppColors.textMuted),
                  ),
                  items: sortedKeys.map((minutes) {
                    return DropdownMenuItem<int>(
                      value: minutes,
                      child: Text(
                        standardDurations[minutes]!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _duration = val);
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            // Switch Rapat Berulang
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              activeTrackColor: AppColors.primary,
              title: const Text('Rapat Berulang (Recurring)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text('Perbarui perulangan rapat secara terjadwal',
                  style: TextStyle(fontSize: 12)),
              value: _isRecurring,
              onChanged: (val) => setState(() => _isRecurring = val),
            ),

            if (_isRecurring) ...[
              const SizedBox(height: 8),
              // Tipe Perulangan
              DropdownButtonFormField<int>(
                isExpanded: true,
                initialValue: _recurringType,
                decoration: const InputDecoration(labelText: 'Tipe Perulangan'),
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
                                Text(_formatDate(_selectedDate),
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
                      '🗓️ Rapat akan berulang dari ${_formatDate(_selectedDate)} s/d ${_formatDate(_endDate)} (${_endDate.difference(_selectedDate).inDays + 1} hari rentang)',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          height: 1.3),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitEdit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'Simpan Perubahan Jadwal',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
