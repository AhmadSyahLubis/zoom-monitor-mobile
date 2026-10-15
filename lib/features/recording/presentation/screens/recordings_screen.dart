import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
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

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      ref.read(recordingFilterProvider.notifier).update(
            (state) =>
                state.copyWith(search: val.trim().isEmpty ? null : val.trim()),
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
                                (state) => state.copyWith(search: null),
                              );
                        },
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
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
                      padding: const EdgeInsets.fromLTRB(20, 40, 20, 110),
                      children: const [
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
                          child: ContentSurface(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pustaka cloud',
                                  style: TextStyle(
                                    color: AppColors.textMain,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${recordings.length} rekaman tersedia',
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
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
