import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/theme/app_type.dart';
import '../../../../core/utils/date_time_util.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../../../core/widgets/app_nav_symbol.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/section_photo_banner.dart';
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

  void _setQuickDate(int daysFromToday) {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    setState(() {
      _selectedDate = DateTime(nowWib.year, nowWib.month, nowWib.day)
          .add(Duration(days: daysFromToday));
    });
  }

  bool _isQuickDate(int daysFromToday) {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final date = DateTime(nowWib.year, nowWib.month, nowWib.day)
        .add(Duration(days: daysFromToday));
    return _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
  }

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
            const SectionPhotoBanner(
              asset: 'assets/images/search_availability.png',
              title: 'Cari slot kosong',
              subtitle: 'Periksa akun yang siap untuk rapat Anda.',
            ),
            const SizedBox(height: 16),
            // Filter Form Card
            ContentSurface(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Atur waktu rapat',
                    style: AppType.section,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Semua waktu mengikuti WIB.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Tanggal rapat',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ChoiceChip(
                        label: const Text('Hari ini'),
                        selected: _isQuickDate(0),
                        onSelected: (_) => _setQuickDate(0),
                      ),
                      ChoiceChip(
                        label: const Text('Besok'),
                        selected: _isQuickDate(1),
                        onSelected: (_) => _setQuickDate(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

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

                  const Text(
                    'Durasi cepat',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final minutes in [30, 45, 60, 120])
                        ChoiceChip(
                          label: Text('$minutes mnt'),
                          selected: _selectedDuration == minutes,
                          onSelected: (_) =>
                              setState(() => _selectedDuration = minutes),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                      DropdownMenuItem(
                          value: 15,
                          child: Text('15 Menit',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 30,
                          child: Text('30 Menit',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 45,
                          child: Text('45 Menit',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 60,
                          child: Text('60 Menit (1 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 90,
                          child: Text('90 Menit (1.5 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 120,
                          child: Text('120 Menit (2 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 180,
                          child: Text('180 Menit (3 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 240,
                          child: Text('240 Menit (4 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 300,
                          child: Text('300 Menit (5 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 360,
                          child: Text('360 Menit (6 Jam)',
                              overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(
                          value: 480,
                          child: Text('480 Menit (8 Jam - Seharian)',
                              overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuration = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Tombol Cek Ketersediaan
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: () {
                      setState(() {
                        _hasSearched = true;
                      });
                    },
                    icon: const AppNavSymbol(
                      kind: AppNavSymbolKind.search,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: const Text('Cek ketersediaan',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Hasil Pencarian
            if (!_hasSearched)
              const EmptyStateWidget(
                artwork: 'assets/icons/state_search.png',
                title: 'Siap cari waktu rapat',
                message:
                    'Pilih waktu rapat dan tekan Cek ketersediaan untuk melihat akun yang siap dipakai.',
              )
            else if (searchAsync != null)
              searchAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return const EmptyStateWidget(
                      artwork: 'assets/icons/state_accounts.png',
                      title: 'Belum ada akun tersedia',
                      message:
                          'Tidak ada akun Zoom yang ditemukan pada sistem.',
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
                          'Akun tersedia (${available.length})',
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
                          'Akun belum tersedia (${busy.length})',
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
    final isError = result.status == 'ERROR';
    final statusColor = isAvailable
        ? AppColors.statusAvailable
        : isError
            ? AppColors.statusError
            : AppColors.statusMeeting;
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.statusAvailableBg
                        : isError
                            ? AppColors.statusErrorBg
                            : AppColors.statusMeetingBg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    isAvailable
                        ? PhosphorIconsFill.checkCircle
                        : isError
                            ? PhosphorIconsRegular.warningCircle
                            : PhosphorIconsFill.xCircle,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isAvailable
                        ? 'Siap dipakai'
                        : isError
                            ? 'Belum dapat diperiksa'
                            : result.conflictingMeeting != null
                                ? 'Jadwal bentrok'
                                : 'Sedang dipakai',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),
            Text(
              result.account.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.cardTitle.copyWith(fontSize: 18),
            ),
            if (result.email.isNotEmpty) ...[
              const SizedBox(height: 4),
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
                onPressed: isError ? null : () => _openBookingSheet(result),
                child: Text(isAvailable
                    ? 'Booking akun'
                    : isError
                        ? 'Tidak dapat dibooking'
                        : 'Paksa booking'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
