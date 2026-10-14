import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_icons/phosphor_icons.dart';
import '../../../../core/network/api_cache_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/glass_surface.dart';
import '../../../../core/utils/ui_feedback.dart';
import '../../../../core/widgets/app_glass_nav_bar.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/load_error_state.dart';
import '../../data/models/schedule_item.dart';
import '../controllers/schedules_controller.dart';
import '../widgets/edit_meeting_dialog.dart';
import '../widgets/meeting_card.dart';

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
          .endMeeting(meeting.meetingId);
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
              onPressed: () => Navigator.of(ctx).pop('occurrence'),
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
            .deleteMeeting(meeting.meetingId, deleteOption: option);
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
            .deleteMeeting(meeting.meetingId, deleteOption: 'occurrence');
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => EditMeetingDialog(meeting: meeting),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: const AppGlassNavBar(currentIndex: 2),
      appBar: AppBar(
        flexibleSpace: const GlassAppBarBackground(),
        title: const Text('Jadwal rapat'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Live Rapat'),
            Tab(text: 'Mendatang'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: schedulesAsync.when(
        data: (data) => TabBarView(
          controller: _tabController,
          children: [
            _buildMeetingList(
              items: data.liveMeetings,
              type: MeetingCardType.live,
              emptyMessage: 'Tidak ada rapat yang sedang berlangsung saat ini.',
            ),
            _buildMeetingList(
              items: data.upcomingMeetings,
              type: MeetingCardType.upcoming,
              emptyMessage: 'Tidak ada jadwal rapat mendatang.',
            ),
            _buildMeetingList(
              items: data.pastMeetings,
              type: MeetingCardType.past,
              emptyMessage: 'Belum ada riwayat rapat yang selesai.',
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (_, __) => LoadErrorState(
          title: 'Jadwal belum dapat dimuat',
          onRetry: () => ref.invalidate(schedulesProvider),
        ),
      ),
    );
  }

  Widget _buildMeetingList({
    required List<ScheduleItem> items,
    required MeetingCardType type,
    required String emptyMessage,
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
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 110),
          children: [
            EmptyStateWidget(
              icon: PhosphorIconsRegular.calendarBlank,
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, idx) => RepaintBoundary(
          child: MeetingCard(
            meeting: items[idx],
            type: type,
            onEndMeeting: type == MeetingCardType.live
                ? () => _handleEndMeeting(items[idx])
                : null,
            onEditMeeting: (type == MeetingCardType.upcoming ||
                    type == MeetingCardType.live)
                ? () => _handleEditMeeting(items[idx])
                : null,
            onDeleteMeeting: type == MeetingCardType.upcoming
                ? () => _handleDeleteMeeting(items[idx])
                : null,
          ),
        ),
      ),
    );
  }
}
