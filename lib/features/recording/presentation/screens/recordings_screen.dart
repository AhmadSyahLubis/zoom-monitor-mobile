import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../../../core/widgets/section_photo_banner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/load_error_state.dart';
import '../controllers/recording_controller.dart';
import '../widgets/recording_card.dart';

class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  int? _selectedPeriodDays;
  bool _customPeriod = false;

  void _setPeriod(int? days) {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final end = DateFormat('yyyy-MM-dd').format(nowWib);
    final start = days == null
        ? null
        : DateFormat('yyyy-MM-dd')
            .format(nowWib.subtract(Duration(days: days - 1)));
    setState(() {
      _selectedPeriodDays = days;
      _customPeriod = false;
    });
    ref.read(recordingFilterProvider.notifier).state = RecordingFilter(
      from: start,
      to: days == null ? null : end,
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  Future<void> _pickPeriod() async {
    final nowWib = DateTime.now().toUtc().add(const Duration(hours: 7));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(nowWib.year, nowWib.month, nowWib.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedPeriodDays = null;
      _customPeriod = true;
    });
    ref.read(recordingFilterProvider.notifier).state = RecordingFilter(
      from: DateFormat('yyyy-MM-dd').format(picked.start),
      to: DateFormat('yyyy-MM-dd').format(picked.end),
      search: _searchController.text.trim().isEmpty
          ? null
          : _searchController.text.trim(),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(recordingFilterProvider.notifier).update(
            (state) => RecordingFilter(
              from: state.from,
              to: state.to,
              search: val.trim().isEmpty ? null : val.trim(),
            ),
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final recordingsAsync = ref.watch(recordingsListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const AppGlassNavBar(currentIndex: 3),
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: const Text('Rekaman'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Cari topik rekaman atau host...',
                prefixIcon: const Icon(PhosphorIconsRegular.magnifyingGlass,
                    color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(PhosphorIconsRegular.x, size: 18),
                        onPressed: () {
                          _debounceTimer?.cancel();
                          _searchController.clear();
                          ref.read(recordingFilterProvider.notifier).update(
                                (state) => RecordingFilter(
                                  from: state.from,
                                  to: state.to,
                                ),
                              );
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _selectedPeriodDays == null && !_customPeriod,
                  onSelected: (_) => _setPeriod(null),
                ),
                ChoiceChip(
                  label: const Text('7 hari'),
                  selected: _selectedPeriodDays == 7,
                  onSelected: (_) => _setPeriod(7),
                ),
                ChoiceChip(
                  label: const Text('30 hari'),
                  selected: _selectedPeriodDays == 30,
                  onSelected: (_) => _setPeriod(30),
                ),
                ActionChip(
                  avatar:
                      const Icon(PhosphorIconsRegular.calendarBlank, size: 16),
                  label:
                      Text(_customPeriod ? 'Rentang dipilih' : 'Pilih tanggal'),
                  onPressed: _pickPeriod,
                ),
              ],
            ),
          ),

          // List Rekaman
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ApiCacheManager().invalidate('recordings');
                ref.invalidate(recordingsListProvider);
                await ref.read(recordingsListProvider.future);
              },
              child: recordingsAsync.when(
                data: (recordings) {
                  if (recordings.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                      children: const [
                        SectionPhotoBanner(
                          asset: 'assets/images/recordings_console.png',
                          title: 'Pustaka rekaman',
                          subtitle: 'Cari ulang rapat yang sudah direkam.',
                        ),
                        SizedBox(height: 30),
                        EmptyStateWidget(
                          icon: PhosphorIconsRegular.cloudArrowDown,
                          title: 'Tidak Ada Rekaman Cloud',
                          message:
                              'Rekaman Zoom yang tersimpan di cloud akan otomatis muncul di sini.',
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                    itemCount: recordings.length + 1,
                    itemBuilder: (ctx, idx) {
                      if (idx == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SectionPhotoBanner(
                            asset: 'assets/images/recordings_console.png',
                            title: 'Pustaka rekaman',
                            subtitle: '${recordings.length} rekaman tersedia',
                          ),
                        );
                      }

                      final recording = recordings[idx - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RepaintBoundary(
                          child: RecordingCard(recording: recording),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary)),
                error: (_, __) => LoadErrorState(
                  title: 'Rekaman belum dapat dimuat',
                  onRetry: () => ref.invalidate(recordingsListProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
