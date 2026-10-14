import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../dashboard/presentation/controllers/dashboard_controller.dart';
import '../../data/models/booking_request.dart';
import '../../data/models/schedule_item.dart';
import 'booking_controller.dart';

final schedulesProvider = FutureProvider<SchedulesData>((ref) async {
  final repo = ref.watch(bookingRepositoryProvider);
  return repo.listSchedules();
});

class SchedulesController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  SchedulesController(this._ref) : super(const AsyncValue.data(null));

  Future<bool> endMeeting(dynamic meetingId) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(bookingRepositoryProvider);
      final success = await repo.endMeeting(meetingId);
      state = const AsyncValue.data(null);
      _ref.invalidate(schedulesProvider);
      _ref.read(dashboardAccountsProvider.notifier).loadDashboard(forceRefresh: true);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateMeeting(dynamic meetingId, UpdateMeetingRequest request) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(bookingRepositoryProvider);
      final success = await repo.updateMeeting(meetingId, request);
      state = const AsyncValue.data(null);
      _ref.invalidate(schedulesProvider);
      _ref.read(dashboardAccountsProvider.notifier).loadDashboard(forceRefresh: true);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteMeeting(dynamic meetingId, {String deleteOption = 'occurrence'}) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(bookingRepositoryProvider);
      final success = await repo.deleteMeeting(meetingId, deleteOption: deleteOption);
      state = const AsyncValue.data(null);
      _ref.invalidate(schedulesProvider);
      _ref.read(dashboardAccountsProvider.notifier).loadDashboard(forceRefresh: true);
      return success;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final schedulesControllerProvider =
    StateNotifierProvider<SchedulesController, AsyncValue<void>>((ref) {
  return SchedulesController(ref);
});
