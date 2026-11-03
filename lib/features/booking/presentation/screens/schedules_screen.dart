import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../../../core/widgets/section_photo_banner.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/load_error_state.dart';
import '../../data/models/schedule_item.dart';
import '../controllers/schedules_controller.dart';
import '../widgets/edit_meeting_dialog.dart';
import '../widgets/meeting_card.dart';
import '../../../../core/widgets/monitoring_refresh.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleEndMeeting(ScheduleItem meeting) async {
    final confirm = await UiFeedback.showConfirmDialog(
      context: context,
      title: 'Akhiri Rapat Ini?',
      message:
          'Apakah Anda yakin ingin memaksa mengakhiri rapat "${meeting.topic}" yang sedang berlangsung?',
      confirmLabel: 'Ya, Akhiri Rapat',
      confirmColor: AppColors.statusMeeting,
    );

    if (confirm) {
      final success = await ref
          .read(schedulesControllerProvider.notifier)
          .endMeeting(meeting.meetingId, accountId: meeting.accountId);
      if (mounted) {
        if (success) {
          UiFeedback.showSuccess(context, 'Rapat berhasil diakhiri');
        } else {
          UiFeedback.showError(context, 'Gagal mengakhiri rapat');
        }
      }
    }
  }

  Future<void> _handleDeleteMeeting(ScheduleItem meeting) async {
    if (meeting.isRecurring) {
      // Dialog pilihan hapus sesi ini atau seluruh seri
      final option = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Hapus Rapat Berulang',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: Text(
            'Rapat "${meeting.topic}" adalah bagian dari seri rapat berulang. Apa yang ingin Anda batalkan?',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Batal',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            OutlinedButton(
              onPressed:
                  meeting.occurrenceId == null || meeting.occurrenceId!.isEmpty
                      ? null
                      : () => Navigator.of(ctx).pop('occurrence'),
              child: const Text('Hapus Pertemuan Ini Saja'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusMeeting),
              onPressed: () => Navigator.of(ctx).pop('all'),
              child: const Text('Hapus Seluruh Seri',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (option != null) {
        final success = await ref
            .read(schedulesControllerProvider.notifier)
            .deleteMeeting(meeting.meetingId,
                accountId: meeting.accountId,
                deleteOption: option,
                occurrenceId: meeting.occurrenceId);
        if (mounted) {
          if (success) {
            UiFeedback.showSuccess(context, 'Jadwal berhasil dihapus');
          } else {
            UiFeedback.showError(context, 'Gagal menghapus rapat');
          }
        }
      }
    } else {
      final confirm = await UiFeedback.showConfirmDialog(
        context: context,
        title: 'Batalkan Rapat?',
        message:
            'Apakah Anda yakin ingin membatalkan rapat "${meeting.topic}"?',
        confirmLabel: 'Ya, Batalkan',
        confirmColor: AppColors.statusMeeting,
      );

      if (confirm) {
        final success = await ref
            .read(schedulesControllerProvider.notifier)
            .deleteMeeting(meeting.meetingId,
                accountId: meeting.accountId, deleteOption: 'all');
        if (mounted) {
          if (success) {
            UiFeedback.showSuccess(context, 'Jadwal berhasil dibatalkan');
          } else {
            UiFeedback.showError(context, 'Gagal membatalkan rapat');
          }
        }
      }
    }
  }

  void _handleEditMeeting(ScheduleItem meeting) {
    if (meeting.isRecurring) {
      UiFeedback.showError(
          context, 'Edit rapat berulang belum tersedia. Buat jadwal baru.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditMeetingDialog(meeting: meeting),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MonitoringRefresh(
      refresh: () async {
        ApiCacheManager().invalidate('bookings');
        ref.invalidate(schedulesProvider);
        await ref.read(schedulesProvider.future);
      },
      builder: (context) => Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        bottomNavigationBar: const AppGlassNavBar(currentIndex: 2),
        appBar: AppBar(
          flexibleSpace: const GlassAppBarBackground(),
          title: const Text('Jadwal rapat'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(58),
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 9),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.neoBase,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xB3FFFFFF)),
                boxShadow: NeoDepth.raised,
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.primaryDark,
                unselectedLabelColor: AppColors.textMuted,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: const Color(0xFFB8CCDE)),
                ),
                tabs: const [
                  Tab(height: 40, text: 'Live Rapat'),
                  Tab(height: 40, text: 'Mendatang'),
                  Tab(height: 40, text: 'Riwayat'),
                ],
              ),
            ),
          ),
        ),
        body: Consumer(builder: (context, ref, _) {
          final schedulesAsync = ref.watch(schedulesProvider);
          return schedulesAsync.when(
            skipLoadingOnRefresh: true,
            skipLoadingOnReload: true,
            data: (data) => TabBarView(
              controller: _tabController,
              children: [
                _buildMeetingList(
                  items: data.liveMeetings,
                  type: MeetingCardType.live,
                  stale: data.isStale,
                  emptyMessage:
                      'Tidak ada rapat yang sedang berlangsung saat ini.',
                ),
                _buildMeetingList(
                  items: data.upcomingMeetings,
                  type: MeetingCardType.upcoming,
                  stale: data.isStale,
                  emptyMessage: 'Tidak ada jadwal rapat mendatang.',
                ),
                _buildMeetingList(
                  items: data.pastMeetings,
                  type: MeetingCardType.past,
                  stale: data.isStale,
                  emptyMessage:
                      'Tidak ada jadwal yang telah terlewati dalam rentang ini.',
                ),
              ],
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
            error: (_, __) => LoadErrorState(
              title: 'Jadwal belum dapat dimuat',
              onRetry: () {
                ApiCacheManager().invalidate('bookings');
                ref.invalidate(schedulesProvider);
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMeetingList({
    required List<ScheduleItem> items,
    required MeetingCardType type,
    required String emptyMessage,
    bool stale = false,
  }) {
    if (items.isEmpty) {
      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ApiCacheManager().invalidate('bookings');
          ref.invalidate(schedulesProvider);
          await ref.read(schedulesProvider.future);
        },
        child: ListView(
          key: PageStorageKey('schedule-empty-${type.name}'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
          children: [
            SectionPhotoBanner(
              asset: 'assets/images/schedule_room.webp',
              title: 'Agenda rapat',
              subtitle: emptyMessage,
            ),
            const SizedBox(height: 30),
            EmptyStateWidget(
              artwork: 'assets/icons/state_calendar.png',
              title: 'Tidak Ada Rapat',
              message: emptyMessage,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () async {
        ApiCacheManager().invalidate('bookings');
        ref.invalidate(schedulesProvider);
        await ref.read(schedulesProvider.future);
      },
      child: ListView.separated(
        key: PageStorageKey('schedule-${type.name}'),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) => idx == 0
            ? SectionPhotoBanner(
                asset: 'assets/images/schedule_room.webp',
                title: type == MeetingCardType.live
                    ? 'Sedang berlangsung'
                    : type == MeetingCardType.upcoming
                        ? 'Rapat berikutnya'
                        : 'Riwayat rapat',
                subtitle: '${items.length} rapat dalam daftar',
              )
            : MeetingCard(
                meeting: items[idx - 1],
                type: type,
                stale: stale,
                onEndMeeting: type == MeetingCardType.live
                    ? () => _handleEndMeeting(items[idx - 1])
                    : null,
                onEditMeeting:
                    (items[idx - 1].monitoring?.scheduleKnown == true &&
                            !items[idx - 1].isRecurring &&
                            (type == MeetingCardType.upcoming ||
                                type == MeetingCardType.live))
                        ? () => _handleEditMeeting(items[idx - 1])
                        : null,
                onDeleteMeeting: type == MeetingCardType.upcoming
                    ? () => _handleDeleteMeeting(items[idx - 1])
                    : null,
              ),
      ),
    );
  }
}
