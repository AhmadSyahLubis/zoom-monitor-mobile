import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../data/models/availability_result.dart';
import '../controllers/booking_controller.dart';
import '../widgets/booking_dialog.dart';
import '../widgets/conflict_banner.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  int _selectedDuration = 60; // menit
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().toUtc().add(const Duration(hours: 7));
    _selectedDate = DateTime(now.year, now.month, now.day);
    // Jam sekarang + 10 menit
    final nextTime = now.add(const Duration(minutes: 10));
    _selectedTime = TimeOfDay(hour: nextTime.hour, minute: nextTime.minute);
  }

  String get _formattedDate => DateFormat('yyyy-MM-dd').format(_selectedDate);
  String get _formattedTime =>
      '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _openBookingSheet(AvailabilityResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BookingDialog(
        accountResult: result,
        date: _formattedDate,
        startTime: _formattedTime,
        duration: _selectedDuration,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchParams = SearchParams(
      date: _formattedDate,
      startTime: _formattedTime,
      duration: _selectedDuration,
    );

    final searchAsync = _hasSearched
        ? ref.watch(searchAvailabilityProvider(searchParams))
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const AppGlassNavBar(currentIndex: 1),
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: const Text('Cari waktu rapat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Form Card
            ContentSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Pilih Waktu Pelaksanaan Rapat (WIB)',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textMain),
                  ),
                  const SizedBox(height: 14),

                  // Row Tanggal & Jam
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.calendarBlank,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Tanggal',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted)),
                                      Text(
                                        DateTimeUtil.formatDateOnlyWib(
                                            _selectedDate.toIso8601String()),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.scaffoldLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.clock,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Mulai (WIB)',
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted)),
                                      Text(
                                        '$_formattedTime WIB',
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Durasi
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: _selectedDuration,
                    decoration: const InputDecoration(
                      labelText: 'Durasi Rapat',
                      prefixIcon: Icon(PhosphorIconsRegular.timer,
                          color: AppColors.textMuted),
                    ),
                    items: const [
                      DropdownMenuItem(value: 15, child: Text('15 Menit', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 30, child: Text('30 Menit', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 45, child: Text('45 Menit', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 60, child: Text('60 Menit (1 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 90, child: Text('90 Menit (1.5 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 120, child: Text('120 Menit (2 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 180, child: Text('180 Menit (3 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 240, child: Text('240 Menit (4 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 300, child: Text('300 Menit (5 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 360, child: Text('360 Menit (6 Jam)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 480, child: Text('480 Menit (8 Jam - Seharian)', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuration = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tombol Cek Ketersediaan
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasSearched = true;
                      });
                    },
                    icon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                        size: 20),
                    label: const Text('Cek ketersediaan',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hasil Pencarian
            if (!_hasSearched)
              Container(
                padding: const EdgeInsets.all(28),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(PhosphorIconsRegular.calendarCheck,
                        size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Pilih waktu rapat dan tekan tombol Cek Ketersediaan untuk melihat akun yang kosong.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else if (searchAsync != null)
              searchAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: const Center(
                        child: Text(
                          'Tidak ada akun Zoom yang ditemukan pada sistem.',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      ),
                    );
                  }

                  final available =
                      results.where((r) => r.isAvailable).toList();
                  final busy = results.where((r) => !r.isAvailable).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Akun Tersedia
                      if (available.isNotEmpty) ...[
                        Text(
                          'Ruang Tersedia (${available.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusAvailable,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...available.map((item) =>
                            _buildResultCard(item, isAvailable: true)),
                        const SizedBox(height: 20),
                      ],

                      // Akun Benturan
                      if (busy.isNotEmpty) ...[
                        Text(
                          'Ruang Terisi / Benturan Jadwal (${busy.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.statusMeeting,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...busy.map((item) =>
                            _buildResultCard(item, isAvailable: false)),
                      ],
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
                error: (_, __) => ContentSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ketersediaan belum dapat diperiksa',
                        style: TextStyle(
                          color: AppColors.textMain,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Periksa koneksi lalu coba lagi.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => ref.invalidate(
                          searchAvailabilityProvider(searchParams),
                        ),
                        child: const Text('Coba lagi'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(AvailabilityResult result,
      {required bool isAvailable}) {
    return RepaintBoundary(
      child: ContentSurface(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.statusAvailableBg
                        : AppColors.statusMeetingBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isAvailable
                        ? PhosphorIconsFill.checkCircle
                        : PhosphorIconsFill.xCircle,
                    color: isAvailable
                        ? AppColors.statusAvailable
                        : AppColors.statusMeeting,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.account.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textMain),
                      ),
                      if (result.email.isNotEmpty)
                        Text(
                          result.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            // Detail konflik jika ada
            if (!isAvailable && result.conflictingMeeting != null) ...[
              const SizedBox(height: 12),
              ConflictBanner(conflict: result.conflictingMeeting!),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor:
                      isAvailable ? AppColors.primary : AppColors.statusMeeting,
                ),
                onPressed: () => _openBookingSheet(result),
                child: Text(isAvailable ? 'Booking' : 'Paksa booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
