import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/dashboard_repository.dart';
import '../../data/models/dashboard_account.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioClientProvider));
});

class DashboardController
    extends StateNotifier<AsyncValue<List<DashboardAccount>>> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard({bool forceRefresh = false}) async {
    // Stale-While-Revalidate: Only display loading spinner if we don't have any data yet
    if (!state.hasValue || state.value == null || state.value!.isEmpty) {
      state = const AsyncValue.loading();
    }
    try {
      final accounts =
          await _repository.getDashboard(forceRefresh: forceRefresh);
      if (!mounted) return;
      state = AsyncValue.data(accounts);
    } catch (e, st) {
      if (!mounted) return;
      if (!state.hasValue) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    await loadDashboard(forceRefresh: true);
  }
}

final dashboardAccountsProvider = StateNotifierProvider<DashboardController,
    AsyncValue<List<DashboardAccount>>>((ref) {
  return DashboardController(ref.watch(dashboardRepositoryProvider));
});
